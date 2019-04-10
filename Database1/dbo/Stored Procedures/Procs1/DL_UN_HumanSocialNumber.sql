/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_HumanSocialNumber
Description         :	Suppression d'un historique de NAS.  Elle s'assure aussi que le NAS de l'humain est le plus 
						récent de l'historique après la suppression.  Elle empêche la suppression si l'historique est 
						le seul de l'humain.

Valeurs de retours  : 	>0 : Tout à fonctionné
                      	<=0 : Erreur SQL

Note                :	ADX0000492	IA	2005-02-03	Bruno Lapointe		Création
						ADX0001235	IA	2007-02-13	Alain Quirion		Renommer SP_DL_UN_HumanSocialNumber pour DL_UN_HumanSocialNumber et renvoi de code d'erreur si dernier NAS avec une convention en RÉÉÉ
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_HumanSocialNumber] (
	@ConnectID INTEGER,				-- ID unique de la connection de l'usager
	@HumanSocialNumberID INTEGER,	-- ID unique de l'historique de NAS à supprimer
	@cHumanType CHAR(3))			--Type d'humain (BNF = bénéficaire SUB = souscripteur, TUT = tuteur
AS
BEGIN
	DECLARE
		@iResultID INTEGER,
		@iHumanID INTEGER,
		@NbSocialNUmber INTEGER

	DECLARE @tConventions TABLE(
			ConventionID INTEGER PRIMARY KEY)

	DECLARE @tSocialNumber TABLE(
			HumanID INTEGER,
			SocialNumber VARCHAR(75))

	SET @iResultID = 1
	
	SELECT
		@iHumanID = HumanID
	FROM Un_HumanSocialNumber
	WHERE HumanSocialNumberID = @HumanSocialNumberID

	IF @iHumanID > 0
	BEGIN
		INSERT INTO @tConventions
			SELECT DISTINCT ConventionID
			FROM dbo.Un_Convention 
			WHERE (SubscriberID = @iHumanID
						OR BeneficiaryID = @iHumanID)

		SELECT
			@NbSocialNumber = COUNT(*)
		FROM Un_HumanSocialNumber
		WHERE HumanID = @iHumanID	

		IF EXISTS ( SELECT * 
					FROM dbo.Un_Convention C
					JOIN @tConventions CI ON CI.ConventionID = C.ConventionID
					JOIN (	SELECT  C.ConventionID,
									ConventionConventionStateID = MAX(CCS.ConventionConventionStateID)
							FROM Un_ConventionConventionState CCS
							JOIN dbo.Un_Convention C ON C.ConventionID = CCS.ConventionID
							JOIN @tConventions CI ON CI.ConventionID = C.ConventionID						
							GROUP BY C.ConventionID) V ON V.ConventionID = CI.ConventionID						
					JOIN Un_ConventionConventionState CCS ON CCS.ConventionConventionStateID = V.ConventionConventionStateID
					JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID
					WHERE CS.ConventionStateName = 'RÉÉÉ')
			 AND @NbSocialNumber < 2				
				SET @iResultID = -1	

		IF @iResultID > 0
		BEGIN
			IF @cHumanType = 'BNF'
			BEGIN
				INSERT INTO @tSocialNumber(
						HumanID,
						SocialNumber)
					SELECT TOP 1 HumanID, SocialNumber
					FROM Un_HumanSocialNumber				
					WHERE HumanID = @iHumanID
							AND HumanSocialNumberID <> @HumanSocialNumberID
					ORDER BY EffectDate DESC

				IF EXISTS ( SELECT *
							FROM @tSocialNumber HSN
							JOIN dbo.Mo_Human H ON H.SocialNumber = HSN.SocialNumber 
							JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
							WHERE H.HumanID <> @iHumanID)
						SET @iResultID = -2
			END
			ELSE IF @cHumanType = 'SUB'
			BEGIN
				INSERT INTO @tSocialNumber(
						HumanID,
						SocialNumber)
					SELECT TOP 1 HumanID, SocialNumber
					FROM Un_HumanSocialNumber				
					WHERE HumanID = @iHumanID
							AND HumanSocialNumberID <> @HumanSocialNumberID
					ORDER BY EffectDate DESC

				IF EXISTS ( SELECT *
							FROM @tSocialNumber HSN
							JOIN dbo.Mo_Human H ON H.SocialNumber = HSN.SocialNumber
							JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID 
							WHERE H.HumanID <> @iHumanID)
						SET @iResultID = -2
			END
		END			

		IF @iResultID > 0
		BEGIN
			-----------------
			BEGIN TRANSACTION
			-----------------		
			
			DELETE
			FROM Un_HumanSocialNumber
			WHERE HumanSocialNumberID = @HumanSocialNumberID

			IF @@ERROR <> 0
				SET @iResultID = -3 -- Erreur lors de la suppression
			ELSE
			BEGIN
				IF NOT EXISTS
						(
						SELECT
						HumanSocialNumberID
						FROM Un_HumanSocialNumber
						WHERE HumanID = @iHumanID
						)
					UPDATE dbo.Mo_Human
					SET
						SocialNumber = ''
					WHERE HumanID = @iHumanID 
				ELSE
					UPDATE dbo.Mo_Human
					SET
						SocialNumber = SN.SocialNumber
					FROM dbo.Mo_Human
					JOIN (
						SELECT
							HumanID,
							EffectDate = MAX(EffectDate)
						FROM Un_HumanSocialNumber
						WHERE HumanID = @iHumanID
						GROUP BY HumanID
						) V ON V.HumanID = Mo_Human.HumanID
					JOIN Un_HumanSocialNumber SN ON SN.HumanID = Mo_Human.HumanID AND SN.EffectDate = V.EffectDate

				IF @@ERROR <> 0
					SET @iResultID = -4 -- Erreur lors de la mise à jour du NAS sur l'humain
			END

			-- Met à jour l'enregistrement 200 du souscripteur ou du bénéficiaire
			IF @iResultID > 0
			BEGIN
				IF EXISTS(	SELECT *
							FROM dbo.Un_Subscriber 
							WHERE SubscriberID = @iHumanID)
				BEGIN
					EXEC @iResultID = TT_UN_CESPOfConventions @ConnectID, 0, @iHumanID, 0	
				END
				ELSE IF EXISTS(	SELECT *
								FROM dbo.Un_Beneficiary 
								WHERE BeneficiaryID = @iHumanID)
				BEGIN
					EXEC @iResultID = TT_UN_CESPOfConventions @ConnectID, @iHumanID, 0, 0	
				END	
			END 
			
			IF @iResultID = 1
				------------------
				COMMIT TRANSACTION
				------------------
			ELSE
				--------------------
				ROLLBACK TRANSACTION
				--------------------
		END
	END
	ELSE
		SET @iResultID = -5 -- Pas réussit à trouver l'humain

	RETURN @iResultID
END


