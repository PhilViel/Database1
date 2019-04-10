/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntCONV_RechercherConvSousBenef
Nom du service		: Rechercher les conventions, souscripteurs et bénéficiaires
But 				: Rechercher les conventions, souscripteurs et bénéficiaires selon les identifiants.
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.
						iID_Convention				Identifiant unique de la convention.  S’il est vide, toutes les
													conventions sont considérées.
						iID_Beneficiaire			Identifiant unique du bénéficiaire.  S'il est vide, tous les
													bénéficiaires sont considérés.
						iID_Souscripteur			Identifiant unique du souscripteur.  S'il est vide, tous les
													souscripteurs sont considérés.

Exemple d’appel		:	SELECT * FROM [dbo].[fntCONV_RechercherConvSousBenef]('FRA', 214276, NULL, NULL)
						SELECT * FROM [dbo].[fntCONV_RechercherConvSousBenef]('FRA', NULL, 380490, NULL)
						SELECT * FROM [dbo].[fntCONV_RechercherConvSousBenef]('FRA', NULL, NULL, 380489)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Un_Convention				iID_Convention					Identifiant de la convention
						Un_Convention				vcNo_Convention					Numéro de la convention
						Un_Convention				iID_Beneficiaire				Identifiant du bénéficiaire
						Mo_Human					vcPrenom_Beneficiaire			Prénom du bénéficiaire
						Mo_Human					vcNom_Beneficiaire				Nom du bénéficiaire
						Un_Convention				iID_Souscripteur				Identifiant du souscripteur
						Mo_Human					vcPrenom_Souscripteur			Prénom du souscripteur
						Mo_Human					vcNom_Souscripteur				Nom du souscripteur

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-05-11		Éric Deshaies						Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_RechercherConvSousBenef]
(
	@cID_Langue CHAR(3),
	@iID_Convention INT = NULL,
	@iID_Beneficiaire INT = NULL,
	@iID_Souscripteur INT = NULL
)
RETURNS @tblCONV_RechercherConvSousBenef TABLE
(
	iID_Convention INT NOT NULL,
	vcNo_Convention VARCHAR(15),
	iID_Beneficiaire INT NOT NULL,
	vcPrenom_Beneficiaire VARCHAR(35),
	vcNom_Beneficiaire VARCHAR(50),
	iID_Souscripteur INT NOT NULL,
	vcPrenom_Souscripteur VARCHAR(35),
	vcNom_Souscripteur VARCHAR(50)
)
AS
BEGIN
	-- Considérer le français comme la langue par défaut
	IF @cID_Langue IS NULL
		SET @cID_Langue = 'FRA'

	-- Rechercher les changements de bénéficiaire selon les critères de recherche
	INSERT INTO @tblCONV_RechercherConvSousBenef
	SELECT	C.ConventionID,
			C.ConventionNo,
			C.BeneficiaryID,
			HB.FirstName,
			HB.LastName,
			C.SubscriberID,
			HS.FirstName,
			HS.LastName
	FROM dbo.Un_Convention C
		 LEFT JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
		 LEFT JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	WHERE C.ConventionID = COALESCE(@iID_Convention,C.ConventionID)
	  AND C.BeneficiaryID = COALESCE(@iID_Beneficiaire,C.BeneficiaryID)
	  AND C.SubscriberID = COALESCE(@iID_Souscripteur,C.SubscriberID)
	ORDER BY C.ConventionNo
	
	-- Retourner les informations
	RETURN 
END


