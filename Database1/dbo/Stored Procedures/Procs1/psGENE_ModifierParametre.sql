/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_ModifierParametre
Nom du service		: Modifier un paramètre
But 				: Ajouter un paramètre et sa valeur dans l’historique des paramètres applicatifs ou modifier la valeur du paramètre s’il ne permet pas l’historisation.
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				vcCode_Type_Parametre		Identifiant unique du type de paramètre à mettre à jour.
						dtDate_Debut_Application	Date de début du paramètre.
						vcDimension1				Valeur de la dimension1 du paramètre.
						vcDimension2				Valeur de la dimension2 du paramètre.
						vcDimension3				Valeur de la dimension3 du paramètre.
						vcDimension4				Valeur de la dimension4 du paramètre.
						vcDimension5				Valeur de la dimension5 du paramètre.
						vcValeur_Parametre			Valeur du paramètre à ajouter ou à modifier.

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					iID_Parametre_Applicatif = Traitement réussi
																					-1 = Type de paramètre inexistant
																					-2 = Erreur de traitement
Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-09-12		Josée Parent						Création du service							
		2009-09-04		Jean-François Gauthier				Modification du paramètre @vcValeur_Parametre à varchar(MAX)
		2009-09-24		Jean-François Gauthier				Remplacement du @@Identity par Scope_Identity()
		2010-01-27		Jean-François Gauthier				Ajout de commentaires
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ModifierParametre]
	@vcCode_Type_Parametre		VARCHAR(100),
	@dtDate_Debut_Application	DATETIME,
	@vcDimension1				VARCHAR(100),
	@vcDimension2				VARCHAR(100),
	@vcDimension3				VARCHAR(100),
	@vcDimension4				VARCHAR(100),
	@vcDimension5				VARCHAR(100),
	@vcValeur_Parametre			VARCHAR(2000)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @iID_Type_Parametre INT;
	DECLARE @iID_Parametre_Applicatif INT;
	DECLARE @bConserver_Historique BIT;
	DECLARE @iCode_Retour INT,
			@dtPlus_Haute_Date_Debut DATETIME;

	BEGIN TRANSACTION

	BEGIN TRY
		-- INITIALISATION DES PARAMÈTRES
		SET @iID_Parametre_Applicatif = NULL;

		-- VALIDATION DE LA DATE PASSÉE EN PARAMÈTRE
		IF @dtDate_Debut_Application IS NULL
			BEGIN
				SET @dtDate_Debut_Application = GetDate();
			END
		
		-- RÉCUPÉRATION DES INFORMATIONS DU TYPE DE PARAMÈTRE EN FONCTION DU CODE
		-- PASSÉ À LA PROCÉDURE
		-- INDIQUERA SI ON DOIT CONSERVER UN HISTORIQUE OU NON DES VALEURS DU PARAMÈTRE
		SELECT  @iID_Type_Parametre = iID_Type_Parametre,
				@bConserver_Historique = bConserver_Historique
		FROM	tblGENE_TypesParametre 
		WHERE	vcCode_Type_Parametre = @vcCode_Type_Parametre;


		-- SI LE TYPE DE PARAMÈTRE EST PRÉSENT DANS LA TABLE, ON DOIT CONSERVER UN HISTORIQUE DES MODIFICATIONS
		IF @iID_Type_Parametre IS NOT NULL
			BEGIN
				IF @bConserver_Historique = 1	-- ON DOIT CONSERVER L'HISTORIQUE DES VALEURS
					BEGIN
						-- RECHERCHE DE LA VALEUR "ACTIVE" DU PARAMÈTRE
						SELECT 
								@iID_Parametre_Applicatif = iID_Parametre_Applicatif,
								@dtPlus_Haute_Date_Debut = dtDate_Debut_Application
						FROM 
							tblGENE_Parametres
						WHERE  
								tblGENE_Parametres.iID_Type_parametre = @iID_Type_Parametre
								AND ISNULL(tblGENE_Parametres.vcDimension1,'PAS DE DIMENSION') = ISNULL(@vcDimension1,'PAS DE DIMENSION')
								AND ISNULL(tblGENE_Parametres.vcDimension2,'PAS DE DIMENSION') = ISNULL(@vcDimension2,'PAS DE DIMENSION')
								AND ISNULL(tblGENE_Parametres.vcDimension3,'PAS DE DIMENSION') = ISNULL(@vcDimension3,'PAS DE DIMENSION')
								AND ISNULL(tblGENE_Parametres.vcDimension4,'PAS DE DIMENSION') = ISNULL(@vcDimension4,'PAS DE DIMENSION')
								AND ISNULL(tblGENE_Parametres.vcDimension5,'PAS DE DIMENSION') = ISNULL(@vcDimension5,'PAS DE DIMENSION')
								AND dtDate_Fin_Application IS NULL;

						-- SI UNE VALEUR EST TROUVÉ, ON DOIT LA DÉSACTIVER AVANT L'INSERTION
						-- DE LA NOUVELLE VALEUR
						IF @iID_Parametre_Applicatif IS NOT NULL
							BEGIN
								IF @dtDate_Debut_Application < DATEADD(ms,2,@dtPlus_Haute_Date_Debut)
									SET @dtDate_Debut_Application = DATEADD(ms,2,@dtPlus_Haute_Date_Debut);

								UPDATE tblGENE_Parametres 
								SET dtDate_Fin_Application = DATEADD(ms,-2,@dtDate_Debut_Application)
								WHERE iID_Parametre_Applicatif = @iID_Parametre_Applicatif;
							END

						-- INSERTION DE LA NOUVELLE VALEUR DU PARAMÈTRE
						INSERT INTO tblGENE_Parametres 
									(iID_Type_Parametre, 
									vcDimension1,
									vcDimension2, 
									vcDimension3, 
									vcDimension4, 
									vcDimension5, 
									dtDate_Debut_Application, 
									vcValeur_Parametre)
						VALUES 
									(@iID_Type_Parametre,
									@vcDimension1,
									@vcDimension2,
									@vcDimension3,
									@vcDimension4,
									@vcDimension5,
									@dtDate_Debut_Application,
									@vcValeur_Parametre);

						SET @iCode_Retour = (SELECT SCOPE_IDENTITY());
					END --IF @bConserver_Historique = 1
				ELSE	-- INSERTION / MISE À JOUR SANS CONSERVATION DE L'HISTORIQUE DES VALEURS
					BEGIN
						-- RÉCUPÈRE LE ID DU PARAMÈTRE "ACTIF" (DATE DE FIN D'APPLICATION NULL)
						SELECT 
							@iID_Parametre_Applicatif = iID_Parametre_Applicatif
						FROM 
							tblGENE_Parametres
						WHERE  
							tblGENE_Parametres.iID_Type_parametre = @iID_Type_Parametre
							AND ISNULL(tblGENE_Parametres.vcDimension1,'PAS DE DIMENSION') = ISNULL(@vcDimension1,'PAS DE DIMENSION')
							AND ISNULL(tblGENE_Parametres.vcDimension2,'PAS DE DIMENSION') = ISNULL(@vcDimension2,'PAS DE DIMENSION')
							AND ISNULL(tblGENE_Parametres.vcDimension3,'PAS DE DIMENSION') = ISNULL(@vcDimension3,'PAS DE DIMENSION')
							AND ISNULL(tblGENE_Parametres.vcDimension4,'PAS DE DIMENSION') = ISNULL(@vcDimension4,'PAS DE DIMENSION')
							AND ISNULL(tblGENE_Parametres.vcDimension5,'PAS DE DIMENSION') = ISNULL(@vcDimension5,'PAS DE DIMENSION')
							AND dtDate_Fin_Application IS NULL;

						-- SI LE PARAMÈTRE EST EXISTANT, ON MET UNIQUEMENT À JOUR SA VALEUR
						IF @iID_Parametre_Applicatif IS NOT NULL
							BEGIN
								UPDATE tblGENE_Parametres 
								SET vcValeur_Parametre = @vcValeur_Parametre
								WHERE iID_Parametre_Applicatif = @iID_Parametre_Applicatif;

								-- RETOURNE L'IDENTIFIANT DU PARAMÈTRE MIS À JOUR
								SET @iCode_Retour = @iID_Parametre_Applicatif;
							END
						ELSE	-- PARAMÈTRE INEXISTANT, ON DOIT ALORS LE CRÉER
							BEGIN
								INSERT INTO tblGENE_Parametres 
										(iID_Type_Parametre, 
										vcDimension1,
										vcDimension2, 
										vcDimension3, 
										vcDimension4, 
										vcDimension5, 
										dtDate_Debut_Application, 
										vcValeur_Parametre)
								VALUES (@iID_Type_Parametre,
										@vcDimension1,
										@vcDimension2,
										@vcDimension3,
										@vcDimension4,
										@vcDimension5,
										@dtDate_Debut_Application,
										@vcValeur_Parametre);
								
								-- RETOURNE L'IDENTIFIANT DU PARAMÈTRE CRÉÉ
								SET @iCode_Retour = (SELECT SCOPE_IDENTITY());
							END
					END
			END
		ELSE
			BEGIN
				-- LE CODE DE PARAMÈTRE REÇU N'EST PAS PRÉSENT DANS LA BASE DE DONNÉES
				-- ON RETOURNE LE CODE D'ERREUR -1
				SET @iCode_Retour = -1;
			END

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		-- UNE ERREUR TECHNIQUE S'EST PRODUITE. LA TRANSACTION EST ANNULÉE
		-- ET ON RETOURNE LE CODE D'ERREUR -2
		ROLLBACK TRANSACTION
		SET @iCode_Retour = -2;
	END CATCH

	-- RETOURNE LE CODE DE TRAITEMENT 
	SELECT @iCode_Retour AS iCode_Retour;
END
