
/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_InjecterMontantsConventions
Nom du service		: Injecter les montants dans les conventions
But 				: Injecter les montants d'IQÉÉ dans les conventions à partir des réponses aux transactions d'IQÉÉ.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						bExecution_Differee			Indicateur si l'exécution de la procédure est faite dans le
													contexte de la procédure "psIQEE_ImporterFichierReponses".  C'est
													habituellement le cas ("1").  On passe "0" si elle est exécutée
													manuellement.  La différence réside dans la création ou non de
													messages pour le rapport d'importation.
						iID_Utilisateur_Creation	Identifiant de l’utilisateur qui demande l'importation du fichier.
													S’il est absent, considérer l’utilisateur système.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_InjecterMontantsConventions] 1, 519626

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					1 = Exécution sans erreur.  Des
																					    montants ont été injectés.
																					0 = Exécution sans erreur, mais
																						pas de nouvelle opération de
																						subvention IQÉÉ.
																					-1 = Erreur non prévue

Historique des modifications:
		Date			Programmeur							Description								
		------------	----------------------------------	-----------------------------------------
		2009-11-18		Éric Deshaies						Création du service							
		2014-10-22		Stéphane Barbeau					Ajout de variable statique @iID_OperationStatique afin de régler le problème 
															de perte de données de la variable de curseur @iID_Operation.
*********************************************************************************************************************/

CREATE PROCEDURE [dbo].[psIQEE_InjecterMontantsConventions] 
(
	@bExecution_Differee BIT,
	@iID_Utilisateur_Creation INT
)
AS
BEGIN
	DECLARE @iID_Operation INT,
			@iID_Connexion INT,
			@dtDate_Operation DATETIME,
			@iID_Transaction_Convention INT,
			@iID_Reponse_Demande INT,
			@cID_Type_Operation_Convention CHAR(3),
			@cID_Type_Operation CHAR(3),
			@mMontant MONEY,
			@iID_Convention INT,
			@dtDate_Barrure_Operation DATETIME,
			@vcOPER_MONTANTS_IQEE VARCHAR(100),
			@vcOPER_MONTANTS_CREDITBASE VARCHAR(100),
			@vcOPER_MONTANTS_MAJORATION VARCHAR(100),
			@mMontant_CBQ MONEY,
			@mMontant_MMQ MONEY,
			@mMontant_Correction_CBQ MONEY,
			@mMontant_Correction_MMQ MONEY,
			@vcNo_Convention VARCHAR(15)
			declare @iID_OperationStatique int
	BEGIN TRY
		-- Prendre l'utilisateur du système s'il est absent en paramètre ou inexistant
		IF @iID_Utilisateur_Creation IS NULL OR
		   NOT EXISTS (SELECT * FROM Mo_User WHERE UserID = @iID_Utilisateur_Creation) 
			SELECT TOP 1 @iID_Utilisateur_Creation = iID_Utilisateur_Systeme
			FROM Un_Def

		--------------------------------------------------------------------------------------------------
		-- Injecter les montants d'IQÉÉ dans les conventions à partir des réponses aux transactions d'IQÉÉ 
		--------------------------------------------------------------------------------------------------
		--IF @bExecution_Differee = 1
		--	INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
		--	VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_InjecterMontantsConventions - '+
		--			'Injecter les montants d''IQÉÉ dans les conventions')

		-- Annuler l'injection s'il n'y a pas des montants d'IQÉÉ à injecter aux conventions
		IF NOT EXISTS(SELECT *
					  FROM tblIQEE_ReponsesDemande RD
						   JOIN tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
													   AND TR.cID_Type_Operation_Convention IS NOT NULL
						   JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = RD.iID_Fichier_IQEE
												  AND F.bFichier_Test = 0
					  WHERE RD.iID_Operation IS NULL
						AND RD.iID_Transaction_Convention IS NULL
						AND RD.mMontant <> 0)
			RETURN 0

		SET XACT_ABORT ON 

		BEGIN TRANSACTION

		-- Retenir la date de barrure des opérations et la remplacer par une plus ancienne date.  Elle sera remise en place à
		-- la fin du traitement.
		-- Note: Ce tour de passe-passe est requis pour conserver les fonctionnalités des triggers tout en injectant les montants
		-- dans le passé si nécessaire.
		SELECT TOP 1 @dtDate_Barrure_Operation = D.LastVerifDate
		FROM Un_Def D

		UPDATE Un_Def
		SET LastVerifDate = '2007-02-21'  -- Date de début de l'IQÉÉ

		-- Trouver la dernière connection de l'utilisateur
		SELECT @iID_Connexion = MAX(CO.ConnectID)
		FROM Mo_Connect CO
		WHERE CO.UserID = @iID_Utilisateur_Creation

		-- Déterminer le code d'opération
		SET @cID_Type_Operation = [dbo].[fnOPER_ObtenirTypesOperationCategorie]('IQEE_CODE_INJECTION_MONTANT_CONVENTION')

		-- Rechercher les dépots de RQ applicable à l'injection ce qui déterminer la date de de l'opération de subvention
		DECLARE curDepotsIQEE CURSOR LOCAL FAST_FORWARD FOR
			SELECT DISTINCT COALESCE(F.dtDate_Paiement,F.dtDate_Production_Paiement)
			FROM tblIQEE_ReponsesDemande RD
			     JOIN tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
										     AND TR.cID_Type_Operation_Convention IS NOT NULL
				 JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = RD.iID_Fichier_IQEE
										AND F.bFichier_Test = 0
		    WHERE RD.iID_Operation IS NULL
			  AND RD.iID_Transaction_Convention IS NULL
			  AND RD.mMontant <> 0

		-- Boucler parmis les dépôts de RQ
		OPEN curDepotsIQEE
		FETCH NEXT FROM curDepotsIQEE INTO @dtDate_Operation
		WHILE @@FETCH_STATUS = 0
			BEGIN
				-- Créer une nouvelle opération de subvention
				
                PRINT 'Debug @iID_Connexion : ' + Str(@iID_Connexion)
                PRINT 'Debug @cID_Type_Operation : ' + @cID_Type_Operation
                PRINT 'Debug @dtDate_Operation : ' + Convert(varchar, @dtDate_Operation, 120)
				EXECUTE @iID_Operation = [dbo].[SP_IU_UN_Oper] @iID_Connexion, 0, @cID_Type_Operation, @dtDate_Operation
				
                PRINT 'Debug @iID_Operation : ' + Str(@iID_Operation)
				set @iID_OperationStatique = @iID_Operation
				-- Rechercher les montants injectables
				DECLARE curReponsesIQEE CURSOR LOCAL FAST_FORWARD FOR
					SELECT RD.iID_Reponse_Demande, RD.iID_Convention, TR.cID_Type_Operation_Convention,
						   CASE WHEN TR.bInverser_Signe_Pour_Injection = 0 THEN RD.mMontant ELSE RD.mMontant*-1 END
					FROM tblIQEE_ReponsesDemande RD
						 JOIN tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
													 AND TR.cID_Type_Operation_Convention IS NOT NULL
						 JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = RD.iID_Fichier_IQEE
												AND F.bFichier_Test = 0
												AND COALESCE(F.dtDate_Paiement,F.dtDate_Production_Paiement) = @dtDate_Operation
					WHERE RD.iID_Operation IS NULL
					  AND RD.iID_Transaction_Convention IS NULL
					  AND RD.mMontant <> 0

				-- Boucler parmis les montants injectables
				OPEN curReponsesIQEE
				FETCH NEXT FROM curReponsesIQEE INTO @iID_Reponse_Demande, @iID_Convention, @cID_Type_Operation_Convention, @mMontant
				WHILE @@FETCH_STATUS = 0
					BEGIN
						-- Injecter le montant dans la convention
						INSERT INTO [dbo].[Un_ConventionOper]
								   ([OperID]
								   ,[ConventionID]
								   ,[ConventionOperTypeID]
								   ,[ConventionOperAmount])
							 VALUES
								   (@iID_OperationStatique--@iID_Operation
								   ,@iID_Convention
								   ,@cID_Type_Operation_Convention
								   ,@mMontant)
						SET @iID_Transaction_Convention = SCOPE_IDENTITY()

						-- Mettre à jour les identifiants de l'injection dans la réponse
						UPDATE tblIQEE_ReponsesDemande
						SET iID_Operation = @iID_Operation,
							iID_Transaction_Convention = @iID_Transaction_Convention
						WHERE iID_Reponse_Demande = @iID_Reponse_Demande

						FETCH NEXT FROM curReponsesIQEE INTO @iID_Reponse_Demande, @iID_Convention, @cID_Type_Operation_Convention, @mMontant
					END
				CLOSE curReponsesIQEE
				DEALLOCATE curReponsesIQEE

				FETCH NEXT FROM curDepotsIQEE INTO @dtDate_Operation
			END
		CLOSE curDepotsIQEE
		DEALLOCATE curDepotsIQEE

		--------------------------------------------------------------------------------------------------------------------
		-- Ajustement pour répartir les montants négatif de crédit de base et de majoration suite à des injections négatives
		--------------------------------------------------------------------------------------------------------------------
		--IF @bExecution_Differee = 1
			--INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
			--VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_InjecterMontantsConventions - '+
			--		'Répartir montants négatif de crédit de base et majoration suite aux injections négatives')

		SET @vcOPER_MONTANTS_IQEE = [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('OPER_MONTANTS_IQEE')
		SET @vcOPER_MONTANTS_CREDITBASE = [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('OPER_MONTANTS_CREDITBASE')
		SET @vcOPER_MONTANTS_MAJORATION = [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('OPER_MONTANTS_MAJORATION')

		-- Rechercher les conventions qui ont un des comptes d'IQÉÉ en négatif
		DECLARE curRepartirIQEE CURSOR LOCAL FAST_FORWARD FOR
			SELECT C.ConventionID,C.ConventionNo,
				  (SELECT MAX(O.OperID)
				   FROM Un_ConventionOper CO
						JOIN Un_Oper O ON O.OperID = CO.OperID
									  AND O.OperTypeID = @cID_Type_Operation
				   WHERE CO.ConventionID = C.ConventionID
					 AND CHARINDEX(CO.ConventionOperTypeID,@vcOPER_MONTANTS_IQEE) > 0),
				  (SELECT SUM(CO.ConventionOperAmount)
				   FROM Un_ConventionOper CO
				   WHERE CO.ConventionID = C.ConventionID
					 AND CHARINDEX(CO.ConventionOperTypeID,@vcOPER_MONTANTS_CREDITBASE) > 0),
				  (SELECT SUM(CO.ConventionOperAmount)
				   FROM Un_ConventionOper CO
				   WHERE CO.ConventionID = C.ConventionID
					 AND CHARINDEX(CO.ConventionOperTypeID,@vcOPER_MONTANTS_MAJORATION) > 0),
				  (SELECT MAX(RD.iID_Reponse_Demande)
				   FROM tblIQEE_ReponsesDemande RD
				   WHERE RD.iID_Convention = C.ConventionID
					 AND RD.iID_Operation IS NOT NULL)
			FROM dbo.Un_Convention C
			WHERE EXISTS (SELECT CO.ConventionOperTypeID,SUM(CO.ConventionOperAmount)
						  FROM Un_ConventionOper CO
						  WHERE CO.ConventionID = C.ConventionID
							AND CHARINDEX(CO.ConventionOperTypeID,@vcOPER_MONTANTS_IQEE) > 0
						  GROUP BY CO.ConventionOperTypeID
						  HAVING SUM(CO.ConventionOperAmount) < 0)

		-- Boucler parmis les conventions
		OPEN curRepartirIQEE
		FETCH NEXT FROM curRepartirIQEE INTO @iID_Convention, @vcNo_Convention, @iID_Operation, @mMontant_CBQ, @mMontant_MMQ, @iID_Reponse_Demande
		WHILE @@FETCH_STATUS = 0
			BEGIN
				-- Si le solde d'IQÉÉ n'est pas négatif...
				IF @mMontant_CBQ + @mMontant_MMQ >= 0
					BEGIN
						IF @mMontant_MMQ < 0
							BEGIN
								SET @mMontant_Correction_CBQ = @mMontant_MMQ
								SET @mMontant_Correction_MMQ = @mMontant_MMQ*-1
							END
						ELSE
							BEGIN
								SET @mMontant_Correction_CBQ = @mMontant_CBQ*-1
								SET @mMontant_Correction_MMQ = @mMontant_CBQ
							END

						-- Injecter les montants de correction dans la convention
						
                        --PRINT 'Debug @iID_Operation : ' + Str(@iID_Operation)
                        --PRINT 'Debug @iID_Convention : ' + Str(@iID_Convention)
                        --PRINT 'Debug @vcOPER_MONTANTS_CREDITBASE : ' + @vcOPER_MONTANTS_CREDITBASE
                        --PRINT 'Debug @mMontant_Correction_CBQ : ' + Str(@mMontant_Correction_CBQ, 10, 2)
						
						INSERT INTO [dbo].[Un_ConventionOper]
								   ([OperID]
								   ,[ConventionID]
								   ,[ConventionOperTypeID]
								   ,[ConventionOperAmount])
							 VALUES
								   (@iID_OperationStatique--@iID_Operation
								   ,@iID_Convention
								   ,@vcOPER_MONTANTS_CREDITBASE
								   ,@mMontant_Correction_CBQ)
						SET @iID_Transaction_Convention = SCOPE_IDENTITY()

						-- Mettre à jour l'identifiant de l'ajustement de crédit de base dans la dernière réponse injectée
						UPDATE tblIQEE_ReponsesDemande
						SET iID_Transaction_Convention_Ajustement_CBQ = @iID_Transaction_Convention
						WHERE iID_Reponse_Demande = @iID_Reponse_Demande

						-- Injecter les montants de correction dans la convention
						
                        --PRINT 'Debug @iID_Operation : ' + Str(@iID_Operation)
                        --PRINT 'Debug @iID_Convention : ' + Str(@iID_Convention)
                        PRINT '@mMontant_Correction_MMQ : ' + str(@mMontant_Correction_MMQ, 10, 2)
						
						INSERT INTO [dbo].[Un_ConventionOper]
								   ([OperID]
								   ,[ConventionID]
								   ,[ConventionOperTypeID]
								   ,[ConventionOperAmount])
							 VALUES
								   (@iID_OperationStatique--@iID_Operation
								   ,@iID_Convention
								   ,@vcOPER_MONTANTS_MAJORATION
								   ,@mMontant_Correction_MMQ)
						SET @iID_Transaction_Convention = SCOPE_IDENTITY()

						-- Mettre à jour l'identifiant de l'ajustement de majoration dans la dernière réponse injectée
						UPDATE tblIQEE_ReponsesDemande
						SET iID_Transaction_Convention_Ajustement_MMQ = @iID_Transaction_Convention
						WHERE iID_Reponse_Demande = @iID_Reponse_Demande
					END
				-- Sinon le compte d'IQÉÉ est négatif
				--ELSE
				--	BEGIN
						--IF @bExecution_Differee = 1
				--			Select 'INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)'
							--INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
							--VALUES ('2',10,'       Avertissement: La convention '+@vcNo_Convention+
							--			   ' a un solde négatif d''IQÉÉ suite à une injection négative.')
				--	END

				FETCH NEXT FROM curRepartirIQEE INTO @iID_Convention, @vcNo_Convention, @iID_Operation, @mMontant_CBQ, @mMontant_MMQ, @iID_Reponse_Demande
			END
		CLOSE curRepartirIQEE
		DEALLOCATE curRepartirIQEE

-- TODO: Importer aussi les réponses aux impôts spéciaux.
--		 Diminuer les comptes de crédit de base et de majoration en proportion autant que possible. Par après, retirer la majoration et par la suite le crédit de base
-- TODO: Vérifier soldes dans les subventions et rendements suite aux retraits via un fichier COT
-- TODO: Avertissement sur les pénalités

		-- Remettre la date de barrure des opérations comme elle était avant le début du traitement
		UPDATE Un_Def
		SET LastVerifDate = @dtDate_Barrure_Operation

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		-- Lever l'erreur et faire le rollback
		DECLARE @ErrorMessage NVARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT

		SET @ErrorMessage = ERROR_MESSAGE()
		SET @ErrorSeverity = ERROR_SEVERITY()
		SET @ErrorState = ERROR_STATE()

		IF (XACT_STATE()) = -1 AND @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG;

		-- Retourner -1 en cas d'erreur de traitement
		RETURN -1
	END CATCH

	-- Retourner 1 en cas d'injection de montants
	RETURN 1
END
