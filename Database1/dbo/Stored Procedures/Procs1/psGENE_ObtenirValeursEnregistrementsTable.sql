/***********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_ObtenirValeursEnregistrementsTable
Nom du service		: Obtenir les valeurs des enregistrements d'une table
But 				: Rechercher et retourner les valeurs des enregistrements d'une table.  Cela sert principalement
					  pour construire des arbres d'informations.  Les informations sont présentées verticalement afin
					  de faciliter l'entretien de ces arbres.  C'est utilisé entre autre pour préparer l'historique
					  de l'IQÉÉ.

					  Comme pré requis, la table utilisée doit avoir une clé unique qui est représenté sur
					  1 seul champ.  Ce champ peut être numérique ou alpha-numérique.

					  Les informations sont accessibles pour une seule table à la fois même s'il est théoriquement 
					  possible de faire des joins et de présenter les champs de plus d'une table.  La conception du service est limité à une seule table.
					  Pour construire un arbre complexe, il suffit d'appeler la procédure plusieurs fois selon les besoins.
					  Le service ne doit pas être appeler d'une interface utilisateur.  Uniquement à partir d'un autre
					  service SQL.
					  Comme pré requis, la table temporaire #tblGENE_Valeurs doit être créer par le service appelant pour
					  ne pas 

					  Définition de la table temporaire à créer avant d'utiliser le service
							CREATE TABLE #tblGENE_Valeurs
								(iID_Session INT NOT NULL,
								iID_Valeur INT IDENTITY(1,1) NOT NULL, 
								vcNom_Table VARCHAR(150) NOT NULL,
								vcNom_Champ VARCHAR(150) NOT NULL,
								vcType VARCHAR(150) NULL,
								vcDescription VARCHAR(MAX) NULL,
								iID_Enregistrement INT NULL,
								vcID_Enregistrement VARCHAR(15) NULL,
								vcValeur VARCHAR(MAX) NULL)
							CREATE CLUSTERED INDEX ID_tblGENE_Valeurs ON #tblGENE_Valeurs (iID_Session)
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						vcNom_Table					Nom de la table de laquelle on désire obtenir les informations.
													L'information est requise.  La casse doit correspondre exactement
													à la casse de la BD.
						vcNom_Champ_ID				Nom du champ de la table qui correspond à l'ID unique de la table
													spécifié au paramètre "vcNom_Table".  L'information est requise.
													La casse doit correspondre exactement à la casse de la BD.
						vcNom_Champs_Retour			Liste des noms des champs que le service appelant désire obtenir.
													Les champs sont séparés par des virgules comme dans une requête SQL.
													Si le champ est NULL, vide ou contient une étoile, tous les champs
													de la table sont considérés.  Le nom du champ ID (paramètre 
													"vcNom_Champ_ID") ne doit pas faire partie de la liste des champs
													de retour.
						vcRequete					Le requête permet de faire des JOIN et une clause WHERE pour limiter
													la sélection des enregistrements de la table.  C'est tout ce qui
													suit par exemple la requête "SELECT * FROM tblIQEE_Demandes
													TABLE_PRINCIPALE".  Exemple: "WHERE iID_Demande_IQEE = 200000"
													permet de limiter à un seul enregistrement la sélection.  S'il y a
													des joins associés à la table principale (paramètre "vcNom_Table")
													dans la requête, l'alias "TABLE_PRINCIPALE" doit être utilisé parce
													qu'il est codé en dur dans le service SQL.  Lorsque ce paramètre est
													vide, c'est l'équivalent de faire un "SELECT * FROM [table]"
						vcNom_Champs_A_Traduire		Liste des noms des champs que le service appelant désire traduire.
													Les champs sont séparés par des virgules comme dans une requête SQL.
													Si le champ est NULL, il n'y a pas de traduction.
						cID_Langue					Identifiant unique de la langue de l'utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.

Exemple d’appel		:	EXECUTE [dbo].[psGENE_ObtenirValeursEnregistrementsTable] 'tblIQEE_Demandes',
														  'iID_Demande_IQEE',
														  '*',
														  'WHERE iID_Demande_IQEE IN (200000,200001)',
														  'vcNo_Convention',
														  NULL

						EXECUTE [dbo].[psGENE_ObtenirValeursEnregistrementsTable] 'Un_ConventionState',
																				  'ConventionStateID',
																				  'ConventionStateName',
																				  NULL,
																				  'ConventionStateName',
																				  'ENU'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iID_Valeur						Identifiant unique de la ligne
																					d'information.
						S/O							vcNom_Table						Nom de la table.  Comme le service
																					permet de sortir les informations
																					d'une seule table à la fois, la
																					valeur de ce champ correspond
																					toujours au paramètre "vcNom_Table".
						S/O							vcNom_Champ						Nom du champ de la table.
																					L'identifiant de la table sort
																					toujours dans la liste des champs
																					de sortie.
						S/O							vcType							Type du champ.
						S/O							vcDescription					Description du champ dans le
																					dictionnaire de données.
						S/O							iID_Enregistrement				Identifiant unique numérique de
																					l'enregistrement d'où provient le
																					champ.
						S/O							vcID_Enregistrement				Identifiant unique alpha-numérique de
																					l'enregistrement d'où provient le
																					champ.
						S/O							vcValeur						Valeur du champ d'un enregistrement.

Historique des modifications:
	Date		Programmeur				Description
	----------	--------------------	------------------------------------------------------------------------------
	2010-09-27	Éric Deshaies			Création du service
	2010-10-26	Éric Deshaies			Diverses modifications en cours du développement de l'historique de l'IQÉÉ
	2015-09-30	Stéphane Barbeau		Curseur curChamps: Ajustement de la requête avec Select DISTINCT pour régler 
                                        erreur technique de l'outil IQEE de type The column 'FirstName' was specified 
										multiple times for 'P' dont la variable C.Name contenait des doublons.
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
***********************************************************************************************************************/
CREATE PROCEDURE dbo.psGENE_ObtenirValeursEnregistrementsTable 
(
	@vcNom_Table VARCHAR(150),
	@vcNom_Champ_ID VARCHAR(150),
	@vcNom_Champs_Retour VARCHAR(MAX),
	@vcRequete VARCHAR(MAX),
	@vcNom_Champs_A_Traduire VARCHAR(MAX),
	@cID_Langue CHAR(3)
)
AS
BEGIN

	BEGIN TRY
		-----------------
		-- Initialisation
		-----------------
		DECLARE @Commande VARCHAR(MAX),
				@vcNom_Champs_TMP VARCHAR(MAX),
				@vcNom_Champ VARCHAR(150),
				@iID_Valeur INT,
				@vcValeur VARCHAR(MAX),
				@iID_Enregistrement INT,
				@vcID_Enregistrement VARCHAR(15),
				@vcType VARCHAR(150)

		-- Validation des paramètres
		IF @vcNom_Table IS NULL OR LTRIM(RTRIM(@vcNom_Table)) = '' OR
		   @vcNom_Champ_ID IS NULL OR LTRIM(RTRIM(@vcNom_Champ_ID)) = ''
			RETURN 1

		-- Considérer le français comme la langue par défaut
		IF @cID_Langue IS NULL
			SET @cID_Langue = 'FRA'

		-- Considérer tous les champs de la table s'il ne sont pas spécifiés
		IF @vcNom_Champs_Retour IS NULL OR
		   LTRIM(RTRIM(@vcNom_Champs_Retour)) = '' OR
		   LTRIM(RTRIM(@vcNom_Champs_Retour)) = '*'
			BEGIN
				-- Rechercher tous les champs de la table sauf l'ID de la table
				DECLARE curChamps CURSOR LOCAL FAST_FORWARD FOR
					SELECT DISTINCT C.Name
					FROM sys.all_objects O
						 JOIN sys.schemas S ON S.schema_id = O.schema_id
		                 JOIN sys.columns C ON C.Object_ID = O.Object_ID 
										   AND C.Name <> @vcNom_Champ_ID
					where O.NAME = @vcNom_Table AND S.name = 'dbo'

				-- Boucler les champs de la table
				SET @vcNom_Champs_Retour = ''
				OPEN curChamps
				FETCH NEXT FROM curChamps INTO @vcNom_Champ
				WHILE @@FETCH_STATUS = 0
					BEGIN
						IF @vcNom_Champs_Retour = ''
							SET @vcNom_Champs_Retour = @vcNom_Champ
						ELSE
							SET @vcNom_Champs_Retour = @vcNom_Champs_Retour + ','+@vcNom_Champ

						FETCH NEXT FROM curChamps INTO @vcNom_Champ
					END
				CLOSE curChamps
				DEALLOCATE curChamps
			END

		-- S'assurer que l'ID de la table est présent en premier dans la liste des champs pour application à chaque ligne retournée
		SET @vcNom_Champs_Retour = @vcNom_Champ_ID+','+@vcNom_Champs_Retour

		----------------------------------------------------------------------------------------
		-- Construire la requête qui va chercher les valeurs et fait le dépivot des informations
		----------------------------------------------------------------------------------------
		SET @Commande = 'SELECT @@spid,'''+@vcNom_Table+''',vcNom_Champ,vcValeur FROM (SELECT '
		SET @vcNom_Champs_TMP = @vcNom_Champs_Retour+','
		WHILE @vcNom_Champs_TMP IS NOT NULL AND @vcNom_Champs_TMP <> ''
			BEGIN
				SET @vcNom_Champ = SUBSTRING(@vcNom_Champs_TMP,1,CHARINDEX(',',@vcNom_Champs_TMP)-1)

				-- Déterminer le type du champ pour influencer la convention en alpha-numérique
				SELECT @vcType = UPPER(TYPE_NAME(C.User_Type_ID))
				FROM sys.all_objects O
					 JOIN sys.columns C ON C.Object_ID = O.Object_ID 
									   AND C.Name = LTRIM(RTRIM(@vcNom_Champ))
				WHERE O.NAME = @vcNom_Table

				IF CHARINDEX('DATE',@vcType) > 0
					SET @Commande = @Commande + 'ISNULL(CONVERT(VARCHAR(MAX),TABLE_PRINCIPALE.'+
												LTRIM(RTRIM(@vcNom_Champ))+',121),''VALEUR_NULL'') AS '+LTRIM(RTRIM(@vcNom_Champ))+','
				ELSE
					SET @Commande = @Commande + 'ISNULL(CAST(TABLE_PRINCIPALE.'+LTRIM(RTRIM(@vcNom_Champ))+
												' AS VARCHAR(MAX)),''VALEUR_NULL'') AS '+LTRIM(RTRIM(@vcNom_Champ))+','

				SET @vcNom_Champs_TMP = SUBSTRING(@vcNom_Champs_TMP,LEN(@vcNom_Champ)+2,8000)
			END
		SET @Commande = SUBSTRING(@Commande,1,LEN(@Commande)-1)
		IF @vcRequete IS NULL
			SET @vcRequete = ''
		SET @Commande = @Commande + ' FROM '+@vcNom_Table+' TABLE_PRINCIPALE '+@vcRequete+') P '
		SET @Commande = @Commande + 'UNPIVOT (vcValeur FOR vcNom_Champ IN ('+@vcNom_Champs_Retour+')) AS unpvt'

		------------------------------------
		-- Obtenir les valeurs de la requête
		------------------------------------
		INSERT INTO #tblGENE_Valeurs (iID_Session,vcNom_Table,vcNom_Champ,vcValeur) EXEC (@Commande) 
		

		-----------------------------------------------
		-- Remplir le type et la description des champs
		-----------------------------------------------
		UPDATE #tblGENE_Valeurs
		SET vcDescription = CAST(EP.Value AS VARCHAR(MAX)),
			vcType = TYPE_NAME(C.User_Type_ID)
		FROM #tblGENE_Valeurs
			 JOIN sys.all_objects O ON O.NAME = #tblGENE_Valeurs.vcNom_Table
			 JOIN sys.columns C ON C.Object_ID = O.Object_ID 
							   AND C.Name = #tblGENE_Valeurs.vcNom_Champ
			 JOIN sys.extended_properties EP ON EP.Major_ID = O.Object_ID
											AND EP.Minor_ID = C.Column_ID
											AND EP.Class_Desc = 'OBJECT_OR_COLUMN'
											AND EP.Name = 'MS_Description'
		WHERE iID_Session = @@spid
		  AND vcDescription IS NULL


		-------------------------------------------------------------------
		-- Remettre les valeurs NULL qui auraient été enlevé par le UNPIVOT
		-------------------------------------------------------------------
		UPDATE #tblGENE_Valeurs
		SET vcValeur = NULL
		WHERE vcValeur = 'VALEUR_NULL'
		  AND iID_Session = @@spid


		---------------------------------------------------
		-- Assigner l'ID de l'enregistrement à chaque champ
		---------------------------------------------------
		DECLARE curValeurs CURSOR LOCAL FAST_FORWARD FOR
			SELECT V.iID_Valeur,V.vcNom_Champ,V.vcValeur,V.vcType
			FROM #tblGENE_Valeurs V
		    WHERE V.iID_Session = @@spid
			  AND V.vcNom_Table = @vcNom_Table
			  AND V.iID_Enregistrement IS NULL
			  AND V.vcID_Enregistrement IS NULL

		OPEN curValeurs
		FETCH NEXT FROM curValeurs INTO @iID_Valeur,@vcNom_Champ,@vcValeur,@vcType
		WHILE @@FETCH_STATUS = 0
			BEGIN
				-- Retenir l'ID en cours
				IF @vcNom_Champ = @vcNom_Champ_ID
					IF UPPER(@vcType) IN ('INT','TINYINT','SMALLINT','BIT','MOID')
						BEGIN
							SET @iID_Enregistrement = CAST(@vcValeur AS INT)
							SET @vcID_Enregistrement = NULL
						END
					ELSE
						BEGIN
							SET @iID_Enregistrement = NULL
							SET @vcID_Enregistrement = CAST(@vcValeur AS VARCHAR(15))
						END

				-- Assigner l'ID
				UPDATE #tblGENE_Valeurs
				SET iID_Enregistrement = @iID_Enregistrement,
					vcID_Enregistrement = @vcID_Enregistrement
				WHERE iID_Valeur = @iID_Valeur
				  AND iID_Session = @@spid

				FETCH NEXT FROM curValeurs INTO @iID_Valeur,@vcNom_Champ,@vcValeur,@vcType
			END
		CLOSE curValeurs
		DEALLOCATE curValeurs


		----------------------
		-- Traduire les champs
		----------------------
		IF @cID_Langue <> 'FRA' AND @vcNom_Champs_A_Traduire IS NOT NULL
			UPDATE #tblGENE_Valeurs
			SET vcValeur = ISNULL((SELECT TOP 1 T.vcTraduction
								   FROM tblGENE_Traductions T
								   WHERE T.vcNom_Table = #tblGENE_Valeurs.vcNom_Table
									 AND T.vcNom_Champ = #tblGENE_Valeurs.vcNom_Champ
									 AND (T.iID_Enregistrement = #tblGENE_Valeurs.iID_Enregistrement
										  OR T.vcID_Enregistrement = #tblGENE_Valeurs.vcID_Enregistrement)
									 AND T.vcID_Langue = @cID_Langue),#tblGENE_Valeurs.vcValeur)
			WHERE CHARINDEX(vcNom_Champ,@vcNom_Champs_A_Traduire) > 0
			  AND iID_Session = @@spid
	END TRY
	BEGIN CATCH
		-- Lever l'erreur et faire le rollback
		DECLARE @ErrorMessage VARCHAR(max) = IsNull(ERROR_MESSAGE(), 'Error ???') + char(13) + char(10) + ' (Proc: ' + IsNull(ERROR_PROCEDURE(), OBJECT_NAME(@@PROCID)) + ' - Line: ' + LTrim(Str(IsNull(ERROR_LINE(), 0))) + ')',
				@ErrorSeverity INT = ERROR_SEVERITY(),
				@ErrorState INT  =ERROR_STATE(),
				@ErrorLine int = ERROR_LINE()

        SET @ErrorMessage = @ErrorMessage + CHAR(13) + CHAR(10) + '   Paramètres : @vcNom_Table         - ' + @vcNom_Table +
                                            CHAR(13) + CHAR(10) + '                @vcNom_Champ_ID      - ' + @vcNom_Champ_ID +
                                            CHAR(13) + CHAR(10) + '                @vcNom_Champs_Retour - ' + @vcNom_Champs_Retour +
                                            CHAR(13) + CHAR(10) + '                @vcRequete           - ' + @vcRequete +
                                            CHAR(13) + CHAR(10) + '                @vcChamps_A_Traduire - ' + @vcNom_Champs_A_Traduire +
                                            CHAR(13) + CHAR(10) + '                @cID_Langue          - ' + @cID_Langue

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG;

		-- Retourner -1 en cas d'erreur de traitement
		RETURN -1
	END CATCH

	-- Retourner 1 lorsque le traitement est réussi
	RETURN 1
END
