/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_DL_UN_HumanSocialNumber
Description         :	Suppression d'un historique de NAS.  Elle s'assure aussi que le NAS de l'humain est le plus 
								récent de l'historique après la suppression.  Elle empêche la suppression si l'historique est 
								le seul de l'humain.
Valeurs de retours  : 	>0 : Tout à fonctionné
                      	<=0 : Erreur SQL
Note                :	ADX0000492	IA	2005-02-03	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE dbo.SP_DL_UN_HumanSocialNumber (
	@ConnectID MoID, -- Id unique de la connection de l'usager
	@HumanSocialNumberID MoID) -- Id unique de l'historique de NAS à supprimer
AS
BEGIN
	DECLARE
		@iResultID MoIDOption,
		@iHumanID MoID

	SET @iResultID = 1

	-----------------
	BEGIN TRANSACTION
	-----------------

	SELECT
		@iHumanID = HumanID
	FROM Un_HumanSocialNumber
	WHERE HumanSocialNumberID = @HumanSocialNumberID

	IF @iHumanID > 0
	BEGIN
		DELETE
		FROM Un_HumanSocialNumber
		WHERE HumanSocialNumberID = @HumanSocialNumberID

		IF @@ERROR <> 0
			SET @iResultID = -1 -- Erreur lors de la suppression
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
				SET @iResultID = -2 -- Erreur lors de la mise à jour du NAS sur l'humain
		END
	END
	ELSE
		SET @iResultID = -4 -- Pas réussi de retrouver l'humain

	IF @iResultID = 1
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @iResultID
END


