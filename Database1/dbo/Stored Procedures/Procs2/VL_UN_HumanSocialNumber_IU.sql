/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_HumanSocialNumber_IU
Description         :	Validation du NAS
Valeurs de retours  :	Dataset :
							vcErrorCode	CHAR(3)			Code d’erreur
							vcErrorText	VARCHAR(1000)	Texte de l’erreur
							
						Code d’erreur		Erreur
						HS1					Le NAS saisi appartient à un souscripteur existant.
						
Note                :	ADX0001235	IA	2007-02-13	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE dbo.VL_UN_HumanSocialNumber_IU (
	@ConnectID INTEGER, -- Identificateur de la connection de l'usager
	@HumanSocialNumberID INTEGER, -- Id unique de l'historique
	@HumanID INTEGER, -- Id unique de l'humain à qui appartient l'historique du NAS
	@EffectDate DATETIME, -- Date d'effectivité du NAS
	@SocialNumber VARCHAR(75)) -- Numéro d'assurance sociale (NAS)	
AS
BEGIN	
	SELECT DISTINCT vcErrorCode = 'HS1',
			vcErrorText = 'Le NAS saisi appartient à un souscripteur existant.'
	WHERE EXISTS(	SELECT H.HumanID
					FROM dbo.Mo_Human H
					JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
					WHERE SocialNumber = @SocialNumber
						AND H.HumanID <> @HumanID)
	-----
	UNION
	-----
	SELECT DISTINCT vcErrorCode = 'HB1',
			vcErrorText = 'Le NAS saisi appartient à un bénéficiaire existant.'
	WHERE EXISTS(	SELECT H.HumanID
					FROM dbo.Mo_Human H
					JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
					WHERE SocialNumber = @SocialNumber
						AND H.HumanID <> @HumanID)
END


