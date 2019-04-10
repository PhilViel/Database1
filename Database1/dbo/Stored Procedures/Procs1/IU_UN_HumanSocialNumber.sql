/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_HumanSocialNumber
Description         :	Création ou modification d'un historique de NAS
Valeurs de retours  :	
						@iResultID
							>0  :	Tout à fonctionné (HumanSocialNumberID du nouvel enregistrement
                     		<=0 :	Erreur SQL

Note                :	
						ADX0000492	IA	2005-02-03	Bruno Lapointe		Création
						ADX0001602	BR	2005-10-11	Bruno Lapointe		SCOPE_IDENTITY au lieu de IDENT_CURRENT
						ADX0001971	BR	2006-06-12	Bruno Lapointe		Renommer SP_RP_UN_ConventionBourseEtudeRUI pour 
																		RP_UN_ConventionBourseEtudeRUI
						ADX0001235	IA	2007-02-13	Alain Quirion		Renommer SP_IU_UN_HumanSocialNumber pour IU_UN_HumanSocialNumber et renvoi de code d'erreur si NAS déjà utilisé
						ADX0001355	IA	2007-06-06	Alain Quirion		Utilisation de RP_UN_ConventionBourseEtudeIndividuel au lieu de SP_RP_UN_ConventionBourseEtudeIndividuel
										2009-03-06	Pierre-Luc Simard	Commander des lettres uniquement pour les conventions qui ne sont pas résiliées
										2011-02-23	Donald Huppé			Ne plus produire le CertificatAssuranceVie (GLPI 5075)
										2011-06-03	Donald Huppé			GLPI 5624 : Correction de l'enregistrement du NAS par rapprot à l'historique des NAS.  
																						Il ne prenait pas le bon NAS quand il y en avait plus qu'un à la même date (effecDate)
																						Maintenant on prend le max(id) à cette date
										2014-10-03	Pierre-Luc Simard	Ne pas générer les documents lorsque le groupe d'unités provient de la proposition électronique
										2015-09-03	Pierre-Luc Simard	Ne plus générer les documents, maintenant fait par Proacces ou le trigger sur Un_ConventionConventionState
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_HumanSocialNumber (
	@ConnectID INTEGER, -- Identificateur de la connection de l'usager
	@HumanSocialNumberID INTEGER, -- Id unique de l'historique
	@HumanID INTEGER, -- Id unique de l'humain à qui appartient l'historique du NAS
	@EffectDate DATETIME, -- Date d'effectivité du NAS
	@SocialNumber VARCHAR(75)) -- Numéro d'assurance sociale (NAS)
AS
BEGIN
	DECLARE
		@iResultID INTEGER,
		@iUnitID INTEGER,
		@iConventionID INTEGER,
		@iHaveInsurance INTEGER,
		@vcPlanTypeID VARCHAR(3),
		@isBeneficiary BIT,
		@isSubscriber BIT,
		@isCompany BIT

	SET @isBeneficiary = 0
	SET @isSubscriber = 0
	SET @isCompany = 0

	IF EXISTS (	SELECT BeneficiaryID
				FROM dbo.Un_Beneficiary 
				WHERE BeneficiaryID = @HumanID)
		SET @isBeneficiary = 1
	ELSE IF EXISTS (	SELECT S.SubscriberID
						FROM dbo.Un_Subscriber S
						JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
						WHERE S.SubscriberID = @HumanID
								AND H.isCompany = 0)
		SET @isSubscriber = 1				
	ELSE IF EXISTS (	SELECT S.SubscriberID
						FROM dbo.Un_Subscriber S
						JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
						WHERE S.SubscriberID = @HumanID
								AND H.isCompany = 1)
	BEGIN
		SET @isSubscriber = 1	
		SET @isCompany = 1
	END

	BEGIN TRANSACTION

	IF (@isBeneficiary = 1
			AND EXISTS(	SELECT H.HumanID
						FROM dbo.Mo_Human H
						JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
						WHERE H.SocialNumber = @SocialNumber
							AND H.HumanID <> @HumanID))
		OR (@isSubscriber = 1
			AND EXISTS(	SELECT H.HumanID
						FROM dbo.Mo_Human H
						JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
						WHERE H.SocialNumber = @SocialNumber
							AND H.HumanID <> @HumanID
							AND H.isCompany = @isCompany))
	BEGIN
		SET @iResultID = -1
	END
	ELSE 
	BEGIN 
		IF @HumanSocialNumberID = 0
		BEGIN

			INSERT INTO Un_HumanSocialNumber (
				HumanID,
				ConnectID,
				EffectDate,
				SocialNumber )
			VALUES (
				@HumanID,
				@ConnectID,
				@EffectDate,
				@SocialNumber )

			IF @@ERROR = 0
				SET @iResultID = SCOPE_IDENTITY()
			ELSE
				SET @iResultID = -2

		END
		ELSE
		BEGIN
			UPDATE Un_HumanSocialNumber 
			SET
				HumanID = @HumanID,
				EffectDate = @EffectDate,
				SocialNumber = @SocialNumber
			WHERE HumanSocialNumberID = @HumanSocialNumberID

			IF @@ERROR = 0
				SET @iResultID = @HumanSocialNumberID
			ELSE
				SET @iResultID = -3
		END

		-- S'assure que le plus récent NAS de l'historique soit sur l'humain
		IF @iResultID > 0
		BEGIN		
			UPDATE dbo.Mo_Human 
			SET SocialNumber = SN.SocialNumber
			FROM dbo.Mo_Human
			JOIN (-- Max EffectDate
				SELECT 
					HumanID,
					MaxEffectDate = MAX(EffectDate)
				FROM Un_HumanSocialNumber
				WHERE HumanID = @HumanID 
				GROUP BY HumanID  
				) V ON V.HumanID = Mo_Human.HumanID
			JOIN (-- Max HumanSocialNumberID par EffectDate
				SELECT 
					HumanID,
					EffectDate,
					MaxHumanSocialNumberID = MAX(HumanSocialNumberID)
				FROM Un_HumanSocialNumber
				WHERE HumanID = @HumanID 
				GROUP BY HumanID,
					EffectDate  
				) V2 ON V.HumanID = Mo_Human.HumanID
			JOIN Un_HumanSocialNumber SN ON SN.HumanID = Mo_Human.HumanID AND V.MaxEffectDate = V2.EffectDate and SN.HumanSocialNumberID = V2.MaxHumanSocialNumberID
			/*
			FROM dbo.Mo_Human
			JOIN (
				SELECT 
					HumanID,
					EffectDate = MAX(EffectDate)
				FROM Un_HumanSocialNumber
				WHERE HumanID = @HumanID 
				GROUP BY HumanID  
				) V ON V.HumanID = Mo_Human.HumanID
			JOIN Un_HumanSocialNumber SN ON SN.HumanID = Mo_Human.HumanID AND SN.EffectDate = V.EffectDate 
			*/
			IF @@ERROR <> 0
				SET @iResultID = -4		
		END

		-- Met à jour l'enregistrement 200 du souscripteur ou du bénéficiaire
		IF @iResultID > 0
		BEGIN
			IF EXISTS(	SELECT *
						FROM dbo.Un_Subscriber 
						WHERE SubscriberID = @HumanID)
			BEGIN
				EXEC @iResultID = TT_UN_CESPOfConventions @ConnectID, 0, @HumanID, 0	
			END
			ELSE IF EXISTS(	SELECT *
							FROM dbo.Un_Beneficiary 
							WHERE BeneficiaryID = @HumanID)
			BEGIN
				EXEC @iResultID = TT_UN_CESPOfConventions @ConnectID, @HumanID, 0, 0	
			END	
		END 
	END

	IF @iResultID > 0
		COMMIT TRANSACTION
	ELSE
		ROLLBACK TRANSACTION

	RETURN @iResultID
END


