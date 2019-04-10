/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntCONV_RechercherChangementsBeneficiaire
Nom du service		: Rechercher les changements de bénéficiaire 
But 				: Rechercher à travers les changements de bénéficiaire des conventions.
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.
						iID_Changement_Beneficiaire	Identifiant unique du changement de bénéficiaire.  S’il est vide,
													tous les identifiants uniques sont considérés.
						iID_Convention				Identifiant unique de la convention.  S’il est vide, toutes les
													conventions sont considérées.
						vcNo_Convention				Numéro de la convention.  S’il est vide, toutes les conventions
													sont considérées.
						dtDate_Changement_Benefi	Date de début de changement de bénéficiaire.  Si elle est vide,
							ciaire_Debut			toutes les dates de changement de bénéficiaire sont considérées
													ou jusqu’à la date de fin si elle est présente.
						dtDate_Changement_Benefi	Date de fin de changement de bénéficiaire.  Si elle est vide,
							ciaire_Fin				toutes les dates de changement de bénéficiaire sont considérées
													ou à partir de la date de début si elle est présente.
						bTrouver_BeneficiaireEn		Indicateur si oui ou non, le service doit trouver le bénéficiaire
							DateDeDebut				à une date précise.  Si le paramètre « dtDate_Changement_Beneficiaire_Debut »
													est présent, la recherche retournera le bénéficiaire en vigueur à
													cette date. Si le paramètre n’est pas là, la date du jour est considérée.
													Lorsque qu’utilisé, le paramètre « dtDate_Changement_Beneficiaire_Fin »
													n’est pas pris en compte.  Si cet indicateur est vide, il n’est pas
													considéré.
						vcCode_Raison				Code de raison du changement de bénéficiaire.  Plusieurs codes
													peuvent être transmis dans le paramètre s’ils sont séparés par une
													virgule.  S’il est vide, toutes les raisons sont considérées.
						vcAutre_Raison_Change		Autre raison du changement de bénéficiaire.  S’il est vide, toutes les
							ment_Beneficiaire		raisons sont considérées.
						bLien_Frere_Soeur_Avec_		Indicateur de lien frère/sœur entre l’ancien et le nouveau bénéficiaire.
							Ancien_Beneficiaire		S’il est vide, la recherche ne tient pas compte de cette information.
						bLien_Sang_Avec_Sousc		Indicateur de lien de sang entre le nouveau bénéficiaire et le
							ripteur_Initial			souscripteur initial.
						iID_Utilisateur_Creation	Identifiant unique de l’utilisateur qui a réalisé le changement de
													bénéficiaire.  S’il est vide, tous les utilisateurs sont considérés.
						iID_Beneficiaire			Identifiant du bénéficiaire impliqué dans le changement de bénéficiaire.
													S’il est vide, tous les bénéficiaires sont considérés.

Exemple d’appel		:	SELECT * FROM [dbo].[fntCONV_RechercherChangementsBeneficiaire](NULL, NULL, NULL, NULL, NULL, NULL,
								 NULL, NULL, NULL, NULL, NULL, NULL, NULL)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Tous les champs de la table « tblCONV_ChangementsBeneficiaire » en plus des champs suivants.

						Un_Convention				ConventionNo					Numéro de convention.
						tblCONV_ChangementsBenefi	iID_Nouveau_Beneficiaire		Identifiant de l’ancien bénéficiaire.
							ciaire 													Vide s’il n’y en a pas.
						tblCONV_RaisonsChangement	vcCode_Raison					Code de raison du changement de 
							Beneficiaire											bénéficiaire.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-12-18		Éric Deshaies						Création du service							
		2009-10-02		Éric Deshaies						Ajout d'un paramètre par bénéficiaire
		2012-06-20		Donald	Huppé						glpi 7338 : modification pour améliorer vitesse dans le cas d'un appel pour conventionID seulement

*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_RechercherChangementsBeneficiaire]
(
	@cID_Langue CHAR(3),
	@iID_Changement_Beneficiaire INT,
	@iID_Convention INT,
	@vcNo_Convention VARCHAR(15),
	@dtDate_Changement_Beneficiaire_Debut DATETIME = NULL,
	@dtDate_Changement_Beneficiaire_Fin DATETIME = NULL,
	@bTrouver_BeneficiaireEnDateDeDebut BIT,
	@vcCode_Raison VARCHAR(30),
	@vcAutre_Raison_Changement_Beneficiaire VARCHAR(150),
	@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire BIT,
	@bLien_Sang_Avec_Souscripteur_Initial BIT,
	@iID_Utilisateur_Creation INT,
	@iID_Beneficiaire INT
)
RETURNS @tblCONV_ChangementsBeneficiaire TABLE
(
	iID_Changement_Beneficiaire INT NOT NULL,
	iID_Convention INT NOT NULL,
	dtDate_Changement_Beneficiaire DATETIME NOT NULL,
	iID_Nouveau_Beneficiaire INT NOT NULL,
	tiID_Raison_Changement_Beneficiaire TINYINT NOT NULL,
	vcAutre_Raison_Changement_Beneficiaire VARCHAR(150) NULL,
	bLien_Frere_Soeur_Avec_Ancien_Beneficiaire BIT NULL,
	bLien_Sang_Avec_Souscripteur_Initial BIT NULL,
	tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire TINYINT NULL,
	tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire TINYINT NULL,
	iID_Utilisateur_Creation INT NOT NULL,	
	vcNo_Convention VARCHAR(15) NOT NULL,
	iID_Ancien_Beneficiaire INT NULL,
	vcCode_Raison VARCHAR(3) NOT NULL
)
AS
BEGIN
	-- Considérer le français comme la langue par défaut
	IF @cID_Langue IS NULL
		SET @cID_Langue = 'FRA'

	-- Si un identifiant est égal à 0, c'est comme s'il n'est pas là
	IF @iID_Changement_Beneficiaire = 0
		SET @iID_Changement_Beneficiaire = NULL

	IF @iID_Convention = 0
		SET @iID_Convention = NULL

	IF @iID_Utilisateur_Creation = 0
		SET @iID_Utilisateur_Creation = NULL

	IF @bTrouver_BeneficiaireEnDateDeDebut IS NULL
		SET @bTrouver_BeneficiaireEnDateDeDebut = 0

	IF @iID_Beneficiaire = 0
		SET @iID_Beneficiaire = NULL

	-- Si le service doit rechercher un bénéficiaire à une date précise et que la date n'est pas spécifié,
	-- considérer la date du jour.
	IF @bTrouver_BeneficiaireEnDateDeDebut = 1 AND @dtDate_Changement_Beneficiaire_Debut IS NULL
		SET @dtDate_Changement_Beneficiaire_Debut = GETDATE()

	-- Rechercher les changements de bénéficiaire selon les critères de recherche
    IF (@iID_Convention IS NOT NULL 
         AND @iID_Changement_Beneficiaire IS NULL 
          AND @iID_Utilisateur_Creation IS NULL
           AND @bTrouver_BeneficiaireEnDateDeDebut = 0
            AND @iID_Beneficiaire IS NULL
             AND @vcNo_Convention IS NULL
              AND @dtDate_Changement_Beneficiaire_Debut IS NULL
               AND @dtDate_Changement_Beneficiaire_Fin IS NULL
                AND @vcAutre_Raison_Changement_Beneficiaire IS NULL
                 AND @bLien_Frere_Soeur_Avec_Ancien_Beneficiaire IS NULL
                  AND @bLien_Sang_Avec_Souscripteur_Initial IS NULL)
       BEGIN
           INSERT INTO @tblCONV_ChangementsBeneficiaire
           SELECT	CB.iID_Changement_Beneficiaire,
        			CB.iID_Convention,
		 			CB.dtDate_Changement_Beneficiaire,
					CB.iID_Nouveau_Beneficiaire,
					CB.tiID_Raison_Changement_Beneficiaire,
					CB.vcAutre_Raison_Changement_Beneficiaire,
					CB.bLien_Frere_Soeur_Avec_Ancien_Beneficiaire,
					CB.bLien_Sang_Avec_Souscripteur_Initial,
					CB.tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire,
					CB.tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire,
					CB.iID_Utilisateur_Creation,
					C.ConventionNo,
					(SELECT TOP (1) 
							AB.iID_Nouveau_Beneficiaire
					   FROM tblCONV_ChangementsBeneficiaire AB
					  WHERE AB.iID_Convention = CB.iID_Convention
						AND AB.dtDate_Changement_Beneficiaire < CB.dtDate_Changement_Beneficiaire
					 ORDER BY AB.dtDate_Changement_Beneficiaire DESC )
		/*
						AND AB.dtDate_Changement_Beneficiaire = (SELECT MAX(CB3.dtDate_Changement_Beneficiaire)
																 FROM tblCONV_ChangementsBeneficiaire CB3
																 WHERE CB3.iID_Convention = CB.iID_Convention
																  AND  CB3.dtDate_Changement_Beneficiaire < CB.dtDate_Changement_Beneficiaire))*/
					,
					RC.vcCode_Raison
			FROM tblCONV_ChangementsBeneficiaire CB 
				 INNER JOIN dbo.Un_Convention C ON C.ConventionID = CB.iID_Convention 
				 INNER  JOIN tblCONV_RaisonsChangementBeneficiaire RC ON RC.tiID_Raison_Changement_Beneficiaire = CB.tiID_Raison_Changement_Beneficiaire
																	 AND (@vcCode_Raison IS NULL OR CHARINDEX(RC.vcCode_Raison,@vcCode_Raison) > 0)
			WHERE CB.iID_Convention = @iID_Convention
			ORDER BY C.ConventionNo, CB.dtDate_Changement_Beneficiaire
		    OPTION (KEEP PLAN)
       END
    ELSE
       BEGIN
			INSERT INTO @tblCONV_ChangementsBeneficiaire
			SELECT	CB.iID_Changement_Beneficiaire,
					CB.iID_Convention,
					CB.dtDate_Changement_Beneficiaire,
					CB.iID_Nouveau_Beneficiaire,
					CB.tiID_Raison_Changement_Beneficiaire,
					CB.vcAutre_Raison_Changement_Beneficiaire,
					CB.bLien_Frere_Soeur_Avec_Ancien_Beneficiaire,
					CB.bLien_Sang_Avec_Souscripteur_Initial,
					CB.tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire,
					CB.tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire,
					CB.iID_Utilisateur_Creation,
					C.ConventionNo,
					(SELECT TOP (1) 
							AB.iID_Nouveau_Beneficiaire
					   FROM tblCONV_ChangementsBeneficiaire AB
					  WHERE AB.iID_Convention = CB.iID_Convention
						AND AB.dtDate_Changement_Beneficiaire < CB.dtDate_Changement_Beneficiaire
					 ORDER BY AB.dtDate_Changement_Beneficiaire DESC )
		/*
						AND AB.dtDate_Changement_Beneficiaire = (SELECT MAX(CB3.dtDate_Changement_Beneficiaire)
																 FROM tblCONV_ChangementsBeneficiaire CB3
																 WHERE CB3.iID_Convention = CB.iID_Convention
																  AND  CB3.dtDate_Changement_Beneficiaire < CB.dtDate_Changement_Beneficiaire))*/
					,
					RC.vcCode_Raison
			FROM tblCONV_ChangementsBeneficiaire CB
				 JOIN dbo.Un_Convention C ON C.ConventionID = CB.iID_Convention 
				 JOIN tblCONV_RaisonsChangementBeneficiaire RC ON RC.tiID_Raison_Changement_Beneficiaire = CB.tiID_Raison_Changement_Beneficiaire
															  AND (@vcCode_Raison IS NULL OR CHARINDEX(RC.vcCode_Raison,@vcCode_Raison) > 0)
			WHERE (@iID_Changement_Beneficiaire IS NULL OR CB.iID_Changement_Beneficiaire = @iID_Changement_Beneficiaire) 
				AND	(@iID_Convention IS NULL OR CB.iID_Convention = @iID_Convention) 
				AND (@vcNo_Convention IS NULL OR C.ConventionNo = @vcNo_Convention)
				--AND (@vcCode_Raison IS NULL OR CHARINDEX(RC.vcCode_Raison,@vcCode_Raison) > 0)
				AND (@vcAutre_Raison_Changement_Beneficiaire IS NULL
					OR CB.vcAutre_Raison_Changement_Beneficiaire LIKE '%'+@vcAutre_Raison_Changement_Beneficiaire+'%')
				AND (@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire IS NULL 
					OR CB.bLien_Frere_Soeur_Avec_Ancien_Beneficiaire = @bLien_Frere_Soeur_Avec_Ancien_Beneficiaire)
				AND (@bLien_Sang_Avec_Souscripteur_Initial IS NULL
					OR CB.bLien_Sang_Avec_Souscripteur_Initial = @bLien_Sang_Avec_Souscripteur_Initial)
				AND (@iID_Utilisateur_Creation IS NULL OR CB.iID_Utilisateur_Creation = @iID_Utilisateur_Creation)
				AND CB.iID_Nouveau_Beneficiaire = ISNULL(@iID_Beneficiaire,CB.iID_Nouveau_Beneficiaire)
				AND (
					  (@bTrouver_BeneficiaireEnDateDeDebut = 1
						AND CB.dtDate_Changement_Beneficiaire = (SELECT MAX(CB2.dtDate_Changement_Beneficiaire)
																 FROM tblCONV_ChangementsBeneficiaire CB2
																 WHERE CB2.iID_Convention = CB.iID_Convention
																  AND  CB2.dtDate_Changement_Beneficiaire <= 
																								@dtDate_Changement_Beneficiaire_Debut))
					 OR
					  (@bTrouver_BeneficiaireEnDateDeDebut = 0
						AND (@dtDate_Changement_Beneficiaire_Debut IS NULL
							 OR CB.dtDate_Changement_Beneficiaire >= @dtDate_Changement_Beneficiaire_Debut) 
						AND (@dtDate_Changement_Beneficiaire_Fin IS NULL
							 OR CB.dtDate_Changement_Beneficiaire <= @dtDate_Changement_Beneficiaire_Fin))
					 )
			ORDER BY C.ConventionNo, CB.dtDate_Changement_Beneficiaire
		OPTION (KEEP PLAN)
       END
	
	-- Retourner les informations
	RETURN 
END


