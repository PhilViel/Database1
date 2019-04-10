/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntIQEE_RechercherParametres
Nom du service		: Rechercher des paramètres
But 				: Rechercher à travers l’historique des paramètres de l’IQÉÉ et obtenir les informations des 
					  séries de paramètres.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				siAnnee_Fiscale				Rechercher les séries de paramètres de l’IQÉÉ selon une année 
													fiscale en particulier.  S’il est vide, toutes les années
													sont considérées.
						bSeulementParamVigueur		Indicateur qui permet de rechercher oui ou non uniquement les
													séries de paramètres en vigueur à la date du jour
													(dtDate_Fin_Application est nul).

Exemple d’appel		:	SELECT * FROM [dbo].[fntIQEE_RechercherParametres](2007, 1)

Paramètres de sortie:	Tous les champs de l’historique des paramètres de l’IQÉÉ (tblIQEE_Parametres) en plus des champs
						suivants.

						Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Mo_Human					FirstName et LastName			Nom de l’utilisateur qui a fait la
																					création des paramètres.
						Mo_Human					FirstName et LastName			Nom de l’utilisateur qui a fait la
																					dernière modification des paramètres.
						S/O							bUtilise_Par_Fichier			Indicateur si la série de paramètres
																					a été utilisée dans la production
																					d’un fichier de l’IQÉÉ.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-05-30		Éric Deshaies						Création du service							
		2008-09-17		Éric Deshaies						Ajout du paramètre de sortie
															"bUtilise_Par_Fichier"
		2009-03-18		Éric Deshaies						Changer le préfixe du service
		2009-04-03		Éric Deshaies						Prendre les noms au complet au lieu des
															noms de login

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntIQEE_RechercherParametres]
(
	@siAnnee_Fiscale SMALLINT,
	@bSeulementParamVigueur BIT
)
RETURNS @tblIQEE_Parametres TABLE
(
	iID_Parametres_IQEE INT NOT NULL,
	siAnnee_Fiscale SMALLINT NOT NULL,
	dtDate_Debut_Application DATETIME NOT NULL,
	dtDate_Fin_Application DATETIME NULL,
	dtDate_Debut_Cotisation DATETIME NOT NULL,
	dtDate_Fin_Cotisation DATETIME NOT NULL,
	siNb_Jour_Limite_Demande SMALLINT NOT NULL,
	tiNb_Maximum_Annee_Fiscale_Anterieur TINYINT NOT NULL,
	iID_Utilisateur_Creation INT NOT NULL,
	iID_Utilisateur_Modification INT NULL,
	dtDate_Modification DATETIME NULL,
	vcNom_Utilisateur_Creation VARCHAR(24) NULL,
	vcNom_Utilisateur_Modification VARCHAR(24) NULL,
	bUtilise_Par_Fichier BIT NOT NULL
)
AS
BEGIN
	-- Si l'année fiscale est 0, c'est comme si elle n'est pas là
	IF @siAnnee_Fiscale = 0
		SET @siAnnee_Fiscale = NULL

	-- Si pas spécifié, on sort tous les enregistrements
	IF @bSeulementParamVigueur IS NULL
		SET @bSeulementParamVigueur = 0
	
	-- Rechercher les séries de paramètres selon les critères de recherche
	INSERT INTO @tblIQEE_Parametres
	SELECT  P.iID_Parametres_IQEE,
			P.siAnnee_Fiscale,
			P.dtDate_Debut_Application,
			P.dtDate_Fin_Application,
			P.dtDate_Debut_Cotisation,
			P.dtDate_Fin_Cotisation,
			P.siNb_Jour_Limite_Demande,
			P.tiNb_Maximum_Annee_Fiscale_Anterieur,
			P.iID_Utilisateur_Creation,
			P.iID_Utilisateur_Modification,
			P.dtDate_Modification,
			U1.FirstName + ' ' + U1.LastName,
			U2.FirstName + ' ' + U1.LastName,
		   CASE WHEN
				(SELECT COUNT(*) FROM tblIQEE_Fichiers F WHERE F.iID_Parametres_IQEE = P.iID_Parametres_IQEE) = 0 THEN 0 ELSE 1
		   END
	FROM tblIQEE_Parametres P
		 JOIN dbo.Mo_Human U1 ON U1.HumanID = P.iID_Utilisateur_Creation
		 LEFT JOIN dbo.Mo_Human U2 ON U2.HumanID = P.iID_Utilisateur_Modification
	WHERE (@siAnnee_Fiscale IS NULL OR P.siAnnee_Fiscale = @siAnnee_Fiscale) AND
		  (@bSeulementParamVigueur = 0 OR P.dtDate_Fin_Application IS NULL)
	ORDER BY P.siAnnee_Fiscale DESC, P.dtDate_Debut_Application DESC
	
	-- Retourner les informations
	RETURN 
END

