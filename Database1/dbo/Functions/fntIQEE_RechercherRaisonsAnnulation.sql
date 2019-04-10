/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntIQEE_RechercherRaisonsAnnulation
Nom du service		: Rechercher les raisons d'annulation
But 				: Rechercher parmis les raisons d'annulation
Facette				: IQEE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.
						iID_Raison_Annulation		Identifiant de la raison d'annulation.
						vcCode_Raison				Code de raison d'annulation.
						bActif						Indicateur de raison d'annulation actif ou non.
						iID_Type_Annulation			Identifiant unique du type d'annulation.
						vcCode_Type					Code du type d'annulation de la raison d'annulation.
						tiID_Type_Enregistrement	Identifiant du type d'enregistrement de la raison d'annulation.
						iID_Sous_Type				Identifiant du sous-type d'enregistrement de la raison d'annulation.
						bAccessible_Utilisateur		Indicateur d'accessibilité de la raison d'annulation pour
													l'utilisateur.
						bApplicable_Aux_			Indicateur d'applicabilité de la raison d'annulation aux simulations.
							Simulations

Exemple d’appel		:	SELECT * FROM [dbo].[fntIQEE_RechercherRaisonsAnnulation](NULL, NULL, NULL, NULL, NULL, NULL,
																				  NULL, NULL, NULL, NULL)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Tous les champs de la table « tblIQEE_RaisonsAnnulation » en plus des champs suivants.

						tblIQEE_TypesAnnulation		vcCode_Type						Code du type d'annulation.
						tblIQEE_TypesAnnulation		vcDescription					Description du type d'annulation.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-09-14		Éric Deshaies						Création du service
		2010-08-03		Éric Deshaies						Mise à niveau sur la traduction des champs
		2010-09-10		Éric Deshaies						Modifier la description

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntIQEE_RechercherRaisonsAnnulation]
(
	@cID_Langue CHAR(3),
	@iID_Raison_Annulation INT,
	@vcCode_Raison VARCHAR(50),
	@bActif BIT,
	@iID_Type_Annulation INT,
	@vcCode_Type VARCHAR(3),
	@tiID_Type_Enregistrement TINYINT,
	@iID_Sous_Type INT,
	@bAccessible_Utilisateur BIT,
	@bApplicable_Aux_Simulations BIT
)
RETURNS @tblIQEE_RaisonsAnnulation TABLE
(
	iID_Raison_Annulation INT NOT NULL,
	vcCode_Raison VARCHAR(50) NOT NULL,
	vcDescription VARCHAR(200) NOT NULL,
	bActif BIT NOT NULL,
	iID_Type_Annulation INT NOT NULL,
	tiID_Type_Enregistrement TINYINT NOT NULL,
	iID_Sous_Type INT NULL,
	dtDate_Debut_Application DATETIME NOT NULL,
	dtDate_Fin_Application DATETIME NULL,
	bAffecte_Infos_Pas_Amendable BIT NOT NULL,
	bAnnuler_Transactions_Depuis_Debut BIT NOT NULL,
	bAnnuler_Transactions_Subsequentes BIT NOT NULL,
	bAnnuler_Annulation_Transactions_Identiques BIT NOT NULL,
	bAccessible_Utilisateur BIT NOT NULL,
	bApplicable_Aux_Simulations BIT NOT NULL,
	bObligation_Reprendre_Transaction BIT NOT NULL,
	bProgrammation_Force_Informations BIT NOT NULL,
	tCommentaires_Utilisateur TEXT NULL,
	tCommentaires_TI TEXT NULL,
	vcCode_Type VARCHAR(3) NOT NULL,
	vcDescription_Type_Annulation VARCHAR(50) NOT NULL
)
AS
BEGIN
	-- Considérer le français comme la langue par défaut
	IF @cID_Langue IS NULL
		SET @cID_Langue = 'FRA'

	-- Considérer NULL les paramètres numérique à 0
	IF @iID_Raison_Annulation = 0
		SET @iID_Raison_Annulation = NULL

	IF @iID_Type_Annulation = 0
		SET @iID_Type_Annulation = NULL

	IF @tiID_Type_Enregistrement = 0
		SET @tiID_Type_Enregistrement = NULL

	IF @iID_Sous_Type = 0
		SET @iID_Sous_Type = NULL

	DECLARE @dtDate_Jour DATETIME
	SET @dtDate_Jour = GETDATE()

	-- Rechercher les raisons d'annulation
	INSERT INTO @tblIQEE_RaisonsAnnulation
	SELECT  RA.iID_Raison_Annulation,
			RA.vcCode_Raison,
			ISNULL(T1.vcTraduction,RA.vcDescription) AS vcDescription,
			RA.bActif,
			RA.iID_Type_Annulation,
			RA.tiID_Type_Enregistrement,
			RA.iID_Sous_Type,
			RA.dtDate_Debut_Application,
			RA.dtDate_Fin_Application,
			RA.bAffecte_Infos_Pas_Amendable,
			RA.bAnnuler_Transactions_Depuis_Debut,
			RA.bAnnuler_Transactions_Subsequentes,
			RA.bAnnuler_Annulation_Transactions_Identiques,
			RA.bAccessible_Utilisateur,
			RA.bApplicable_Aux_Simulations,
			RA.bObligation_Reprendre_Transaction,
			RA.bProgrammation_Force_Informations,
			ISNULL(T2.vcTraduction,RA.tCommentaires_Utilisateur) AS tCommentaires_Utilisateur,
			RA.tCommentaires_TI,
			TA.vcCode_Type,
			ISNULL(T3.vcTraduction,TA.vcDescription) AS vcDescription_Type_Annulation
	FROM tblIQEE_RaisonsAnnulation RA
		 JOIN tblIQEE_TypesAnnulation TA ON TA.iID_Type_Annulation = RA.iID_Type_Annulation
		 LEFT JOIN tblGENE_Traductions T1 ON T1.vcNom_Table = 'tblIQEE_RaisonsAnnulation'
										 AND T1.vcNom_Champ = 'vcDescription'
										 AND T1.iID_Enregistrement = RA.iID_Raison_Annulation
										 AND T1.vcID_Langue = @cID_Langue
		 LEFT JOIN tblGENE_Traductions T2 ON T2.vcNom_Table = 'tblIQEE_RaisonsAnnulation'
										 AND T2.vcNom_Champ = 'tCommentaires_Utilisateur'
										 AND T2.iID_Enregistrement = RA.iID_Raison_Annulation
										 AND T2.vcID_Langue = @cID_Langue
		 LEFT JOIN tblGENE_Traductions T3 ON T3.vcNom_Table = 'tblIQEE_TypesAnnulation'
										 AND T3.vcNom_Champ = 'vcDescription'
										 AND T3.iID_Enregistrement = TA.iID_Type_Annulation
										 AND T3.vcID_Langue = @cID_Langue
	WHERE RA.iID_Raison_Annulation = COALESCE(@iID_Raison_Annulation,RA.iID_Raison_Annulation)
	  AND RA.vcCode_Raison = COALESCE(@vcCode_Raison,RA.vcCode_Raison)
	  AND (@bActif IS NULL 
		   OR (@bActif = 1
					AND RA.bActif = 1
					AND @dtDate_Jour BETWEEN RA.dtDate_Debut_Application AND ISNULL(RA.dtDate_Fin_Application,@dtDate_Jour))
		   OR (@bActif = 0
					AND (RA.bActif = 0
						OR @dtDate_Jour NOT BETWEEN RA.dtDate_Debut_Application AND ISNULL(RA.dtDate_Fin_Application,@dtDate_Jour))))
	  AND RA.iID_Type_Annulation = COALESCE(@iID_Type_Annulation,RA.iID_Type_Annulation)
	  AND TA.vcCode_Type = COALESCE(@vcCode_Type,TA.vcCode_Type)
	  AND RA.tiID_Type_Enregistrement = COALESCE(@tiID_Type_Enregistrement,RA.tiID_Type_Enregistrement)
	  AND (@iID_Sous_Type IS NULL OR RA.iID_Sous_Type = @iID_Sous_Type)
	  AND RA.bAccessible_Utilisateur = COALESCE(@bAccessible_Utilisateur,RA.bAccessible_Utilisateur)
	  AND RA.bApplicable_Aux_Simulations = COALESCE(@bApplicable_Aux_Simulations,RA.bApplicable_Aux_Simulations)
	ORDER BY RA.iOrdre_Presentation

	-- Retourner les informations
	RETURN 
END

