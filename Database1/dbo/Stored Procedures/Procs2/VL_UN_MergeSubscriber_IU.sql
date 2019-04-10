/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	VL_UN_MergeSubscriber_IU
Description 		:	Validation de la fusion des souscripteurs
Valeurs de retour	:	Dataset :
						vcErrorCode		CHAR(3)			Code d’erreur
						vcErrorText		VARCHAR(1000)	Texte de l’erreur
						
						Code d’erreur		Erreur
						MS1					Le souscripteur avec l’historique de NAS le plus ancien est dans la position du souscripteur remplacé
						MB2					Un ajustement à la date de fin de régime a été saisi pour au moins une des conventions du bénéficiaire qui sera supprimé

Note			:	ADX0001235	IA	2007-02-13	Alain Quirion		Création
*************************************************************************************************/
CREATE PROCEDURE dbo.VL_UN_MergeSubscriber_IU (
	@iNewSubscriberID INTEGER,			--Identifiant unique du souscripteur remplaçant.
	@iOldSubscriberID INTEGER)			--Identifiant unique du souscripteur remplacé
AS
BEGIN
	DECLARE @dtNewSubscriberDate DATETIME,
			@dtOldSubscriberDate DATETIME

	SELECT
			@dtNewSubscriberDate = MIN(EffectDate)
	FROM Un_HumanSocialNumber SSN
	WHERE SSN.HumanID = @iNewSubscriberID

	SELECT
			@dtOldSubscriberDate = MIN(EffectDate)
	FROM Un_HumanSocialNumber SSN
	WHERE SSN.HumanID = @iOldSubscriberID

	SELECT  vcErrorCode = 'MS1',
			vcErrorText = 'Le souscripteur avec l’historique de NAS le plus ancien est dans la position du souscripteur remplacé'
	WHERE ISNULL(@dtOldSubscriberDate, '9999-12-31') < ISNULL(@dtNewSubscriberDate, '9999-12-31')
	-----
	UNION
	-----
	SELECT  DISTINCT
			vcErrorCode = 'MS2',
			vcErrorText = 'Un ajustement à la date de fin de régime a été saisi pour au moins une des conventions du souscripteur qui sera supprimé'
	FROM dbo.Un_Subscriber S
	JOIN dbo.Un_Convention C ON C.SubscriberID = S.SubscriberID
	WHERE C.SubscriberID = @iOldSubscriberID
			AND C.dtRegEndDateAdjust IS NOT NULL
END


