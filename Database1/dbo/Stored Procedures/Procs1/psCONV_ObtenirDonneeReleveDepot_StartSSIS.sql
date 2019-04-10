/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Code de service		:		psCONV_ObtenirDonneeReleveDepot_StartSSIS
Nom du service		:		Démare la job pour le SSIS 
							Obtenir toutes les données nécessaire pour l'impression du relevé de dépôt    
But					:		Récupérer toutes les données nécessaire pour l'impression du relevé de dépôt
Facette				:		P171U
Reférence			:		Relevé de dépôt
Action				:		Demare le calcul du relevé de depôt par l'execution du SSIS

Parametres d'entrée :	Parametres					Description                                 Obligatoir
                        ----------                  ----------------                            --------------                       
                        dtDateDebut                 Date début du relevé de dépôt               Non
						dtDateFin                   Date fin du relevé de dépôt                 Oui
                        iSubscriberID               Identifiant unique du souscripteur          Non
                        @bIsSave                    Indique si on doit sauvegarder les données
                                                    dans une table physique
À AJUSTER LORS DU DEPLOYEMENT !! (ligne 75)

						SET @vPackageName	= 'CalculReleveDepot'
						SET @vServerName	= 'srv-sql-2'
						SET @vDatabase		= 'UnivBase_RelDepot'
						SET @job_name		= 'runDTSXcalculRelevDepot'


Exemple d'appel:
				-- 431902, 197524, 392932,571028, 575262
				EXECUTE dbo.psCONV_ObtenirDonneeReleveDepot_StartSSIS	'2010-01-01', '2010-12-31', 197524, 1, 2
				EXECUTE dbo.psCONV_ObtenirDonneeReleveDepot_StartSSIS	'2009-01-01', '2009-12-31', 154627, 1, 2
				EXECUTE dbo.psCONV_ObtenirDonneeReleveDepot_StartSSIS	'2009-01-01', '2009-12-31', 575262, 1, 2
				EXECUTE dbo.psCONV_ObtenirDonneeReleveDepot_StartSSIS	'2010-01-01', '2010-12-31', 501618, 1, 2
				EXECUTE dbo.psCONV_ObtenirDonneeReleveDepot_StartSSIS	'2010-01-01', '2010-12-31', 196964, 1, 2
				EXECUTE dbo.psCONV_ObtenirDonneeReleveDepot_StartSSIS	'2010-01-01', '2010-12-31', 175890, 1, 2
				EXECUTE dbo.psCONV_ObtenirDonneeReleveDepot_StartSSIS	'2010-01-01', '2010-12-31', 443563, 1, 2

				EXECUTE dbo.psCONV_ObtenirDonneeReleveDepot_StartSSIS	'2010-01-01', '2010-12-31', 156853, 1, 2
				EXECUTE dbo.psCONV_ObtenirDonneeReleveDepot_StartSSIS	'2010-01-01', '2010-12-31', 182183, 1, 2
				
				EXECUTE dbo.psCONV_ObtenirDonneeReleveDepot_StartSSIS	'2010-01-01', '2010-12-31', 479255, 1, 2
				EXECUTE dbo.psCONV_ObtenirDonneeReleveDepot_StartSSIS	'2010-01-01', '2010-12-31', NULL, 1, 2
				
				
				
Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
						tblCONV_DonneeReleveDepot	Tous
													CodeReleveDepot								Code du relevé de dépôt provenant des paramètres applicatifs

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-03-12					Dan Trifan								Création de la fonction 
						2009-04-24					Jean-François Gauthier					Modification du RaiseError dans le CATCH
						2009-04-30					Jean-François Gauthier					Modification pour l'appel à la procédure 
						2009-05-07					Jean-François Gauthier					Modification pour synchronisation avec 
																							avec l'appel provenant de [psCONV_ObtenirReleveDepotPDF]
						2009-05-15					Jean-François Gauthier					Ajout de la vérification de la présence des données pour le souscripteur demandé
						2009-07-09					Jean-François Gauthier					Ajout du champ bSouscripteur_Desire_Releve_Elect Si aucune donnée présente, on génère																
						2009-09-14					Jean-François Gauthier					Ajout du champ mIQEEMaj
						2009-10-07					Jean-François Gauthier					Ajout du champ iNbGroupeUnite en retour
						2009-10-23					Jean-François Gauthier					Ajout des 4 champs :dDiffMoisIQEE
																												dDiffMoisSCEE
																												bEntreeVigueurIQEE
																												bEntreeVigueurSCEE
						2009-10-29					Jean-François Gauthier					Correction d'un bug avec le traçage
						2009-11-05					Jean-François Gauthier					Ajout du champ dtEcheance																	
						2010-01-07					Jean-François Gauthier					Modification pour retourner le champ bSouscripteur_Desire_Releve_Elect
						2010-01-08					Jean-François Gauthier					Ajout la variable @vcSSISConnexion servant à préciser
																							le nom de la connexion à la BD à l'intérieur-même du package SSIS
						2010-05-21					Jean-François Gauthier					Ajout du IsNull sur le champ mQuantiteUnite
						2010-06-01					Jean-François Gauthier					Élimination de la condition sur les frais de cotisation <> 0
						2010-12-14					Jean-François Gauthier					Ajout du Execute As Owner
						2010-01-11					Jean-François Gauthier					Ajout du champ CodeReleveDepot en sortie
						2010-01-20					Jean-François Gauthier					Modification de la dimension du champ message de la table @tmp_sp_help_jobhistory,
																							car en sur SQL Server 2008, il est plus grand.
						2011-02-10					Jean-François Gauthier					Enlever le 	WITH EXECUTE AS OWNER, car il ne fonctionne pas sur SQL-1
																							-- IL FAUDRA SANS DOUTE LE RAJOUTER EN PRODUCTION																						
						2011-02-21					Jean-François Gauthier					Modifier pour retourner le répertoire où sauvegarder le PDF (champ vcPathPDF) 																							
						2011-03-01					Jean-François Gauthier					Ajout de la colonne vcTypeRio		
						2011-03-08					Jean-François Gauthier					Ajout des ISNULL sur les montants retournées														
						2011-03-16					Jean-François Gauthier					Ajour des conventions à exclure à partir de la table tblCONV_RelDepConvExclu
						2011-06-30					Corentin Menthonnex						2010-25 : Ajout de la prise en charge des RIM et TRI
						2011-07-14					Frederick Thibault						Corrections RIM et TRI
						2012-04-18                  Mbaye Diakhate							initialiser  @vSSIScmdStr en fonction de version du serveur 2005 ou 2008
						2013-01-31					Pierre-Luc Simard						Correction pour l'appel d'un seul souscripteur sans générer les données.
						2013-02-07					Pierre-Luc Simard						Validation du consentement pour ceux du Portail
						2013-03-15					Pierre-Luc Simard						Retrait des régimes dans le champ vcPathPDF
						2016-05-25                  Steeve Picard                           Standardisation des vieux RaisError
						2017-09-27                  Pierre-Luc Simard                       Deprecated - Cette procédure n'est plus utilisée

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirDonneeReleveDepot_StartSSIS]
	@dtDateDebut datetime, 
	@dtDateFin datetime, 
	@iSubscriberID int, 
	@bIsSave bit, 
	@iConnectId int
WITH EXEC AS CALLER
AS
BEGIN
    SELECT 1/0
    /*
	DECLARE 
		@vSSIScmdStr			VARCHAR(8000)
		,@vPackageName			VARCHAR(200)
		,@vServerName			sysname
		,@vDatabase				sysname
		,@vParams				VARCHAR(8000)
		,@iErrno				INTEGER
		,@iErrSeverity			INTEGER
		,@iErrState				INTEGER
		,@vErrmsg				NVARCHAR(1024)
		,@ReturnCode			INTEGER
		,@job_name				sysname
		,@job_id				uniqueidentifier 
		,@is_sysadmin			INTEGER
		,@job_owner				sysname
		,@iLastRunDate			INTEGER
		,@iLastRunTime			INTEGER
		,@iRunStatus			INTEGER
		,@vMessage				NVARCHAR(1024)	
		,@execution_status		INTEGER
		,@vDateDebut			CHAR(10) 
		,@vDateFin				CHAR(10)
		,@vSubscriberID			CHAR(18)
		,@bIsReturn				BIT	-- 1 si recordset à retourner
		,@nbSouscripteurs		INTEGER
		,@nbEnregistrements		INTEGER
		,@nbConventions			INTEGER
		,@dtDtHrsStart			DATETIME
		,@iType					INTEGER
		,@fDuration				FLOAT	
		,@dtStart				DATETIME
		,@dtEnd					DATETIME
		,@vcDescription			VARCHAR(500)
		,@vcStoredProcedure		VARCHAR(200)
		,@vcExecutionString		VARCHAR(2000)
		,@vcSSISConnexion		VARCHAR(255)
		,@CodeReleveDepot		VARCHAR(5)
		,@versionServer			VARCHAR(5)

	SET NOCOUNT ON

	SELECT 
		@dtDtHrsStart	= GETDATE(),
		@dtStart		= GETDATE()

	INSERT INTO tblCONV_MessagesDonneeReleveDepot(
		dtDtTime,
		vfacette,
		vmodule,
		vmess)
	SELECT 
		@dtDtHrsStart,
		'CONV',
		'Calcul relevé de depôt', 
		'-------------- Job runDTSXcalculRelevDepot: START -------------------------' 

	BEGIN TRY	

		IF @bIsSave IS NULL
			SET @bIsSave = 0

		-- VÉRIFICATION SI LE SOUSCRIPTEUR A DES DONNÉES DE GÉNÉRÉES DANS LA TABLE
		-- POUR LA DATE DE FIN DEMANDÉE
		IF NOT EXISTS(	SELECT 1 FROM	dbo.tblCONV_DonneeReleveDepot WHERE iIDSouscripteur  = @iSubscriberID AND dtDateFin = @dtDateFin) 
			BEGIN
				SET @bIsSave = 1
			END

		IF (@iSubscriberID IS NULL) AND (@bIsSave = 1)	-- ON VEUT GÉNÉRER TOUTES LES DONNÉES, ALORS IL NE FAUT PAS 
			BEGIN										-- LES RETOURNER, CAR C'EST LA PROCÉDURE [psCONV_ObtenirReleveDepotPDF] QUI LE FERA
				SET @bIsReturn = 0
			END
		ELSE
			BEGIN
				SET @bIsReturn = 1
			END

		-- prepare les paramètres pour les passer aux dtsx
		IF @dtDateDebut		IS NULL SET @vDateDebut = '1900-01-01' ELSE SET @vDateDebut = convert(char(10),@dtDateDebut,120)
		IF @dtDateFin		IS NULL SET @vDateFin = convert(char(10),getdate(),120) ELSE SET @vDateFin = convert(char(10),@dtDateFin,120)
		IF @iSubscriberID	IS NULL SET @vSubscriberID = '-1' ELSE SET @vSubscriberID = rtrim(CAST(@iSubscriberID as VARCHAR(18)))
		
		-- 2010-01-10 : JFG : Recherche du code de relevé de dépôt dans les paramètres applicatifs
		SET @CodeReleveDepot = dbo.fnGENE_ObtenirParametre('CONV_RDEP_CODE_RELEVE', NULL, NULL, NULL, NULL, NULL, NULL)


		IF @bIsSave = 1
			BEGIN
				-- package name -  stored in msdb !!
				SET @vPackageName	= N'CalculReleveDepot'
				-- SSIS server name, databasename, job name, connection name
				SET @vServerName		= @@servername
				SET @vDatabase			= dbo.fnGENE_ObtenirParametre('CONV_RDEP_BD_SSIS',NULL,NULL,NULL,NULL,NULL,NULL)
				SET @job_name			= N'runDTSXcalculRelevDepot'
				SET @vcSSISConnexion 	= dbo.fnGENE_ObtenirParametre('CONV_RDEP_CONNEXION_SSIS',NULL,NULL,NULL,NULL,NULL,NULL)
	
				DECLARE @tblOut	TABLE (vligne NVARCHAR(255))

				DECLARE @xp_results TABLE  
						(
						job_id				  uniqueidentifier NOT NULL,
						last_run_date         INTEGER          NOT NULL,
						last_run_time         INTEGER          NOT NULL,
						next_run_date         INTEGER          NOT NULL,
						next_run_time         INTEGER          NOT NULL,
						next_run_schedule_id  INTEGER          NOT NULL,
						requested_to_run      INTEGER          NOT NULL, -- BOOL
						request_source        INTEGER          NOT NULL,
						request_source_id     sysname          COLLATE database_default NULL,
						running               INTEGER          NOT NULL, -- BOOL
						current_step          INTEGER          NOT NULL,
						current_retry_attempt INTEGER          NOT NULL,
						job_state             INTEGER          NOT NULL
						)

				DECLARE @tmp_sp_help_jobhistory TABLE
					(
						instance_id			INTEGER				NULL, 
						job_id				uniqueidentifier	NULL, 
						job_name			sysname				NULL, 
						step_id				INTEGER				NULL, 
						step_name			sysname				NULL, 
						sql_message_id		INTEGER				NULL, 
						sql_severity		INTEGER				NULL, 
						message				NVARCHAR(MAX)		NULL, 
						run_status			INTEGER				NULL, 
						run_date			INTEGER				NULL, 
						run_time			INTEGER				NULL, 
						run_duration		INTEGER				NULL, 
						operator_emailed	sysname				NULL, 
						operator_netsent	sysname				NULL, 
						operator_paged		sysname				NULL, 
						retries_attempted	INTEGER				NULL, 
						server				sysname				NULL  
					)
				/*
					Is the execution status for the jobs. 
					Value Description 
					0 Returns only those jobs that are not idle or suspended.  
					1 Executing. 
					2 Waiting for thread. 
					3 Between retries. 
					4 Idle. 
					5 Suspended. 
					7 Performing completion actions 

				*/
				-- set variables 
				SELECT @job_id = job_id FROM msdb..sysjobs_view WHERE name = @job_name 
				SELECT @is_sysadmin = 1 -- ISNULL(IS_SRVROLEMEMBER(N'sysadmin'), 0)
				SELECT @job_owner = NULL -- SUSER_SNAME()

				-- due to article format.
				-- package variables, which we are passing in SSIS Package.
				SET @vParams = '/set \package.variables[dtDateDebut].Value;"'+@vDateDebut
							+'" /set \package.variables[dtDateFin].Value;"'+@vDateFin
							+'" /set \package.variables[iSubscriberID].Value;"'+@vSubscriberID+'"'			

				-- now making "dtexec" SQL from dynamic values
				SET @vSSIScmdStr = 'dtexec /sq ' + @vPackageName + ' /ser ' + @vServerName + ' '
				SET @vSSIScmdStr = @vSSIScmdStr + @vParams
				-- print line for verification 
				-- print @vSSIScmdStr

				----
			/*
				-- version avec execution directe du SSIS - replacé par execution de la job qui fait démarer la SSIS
				-- executer xp_cmdshell qui lance à sont tour dtexec
				DECLARE @ReturnCode int
				INSERT INTO @tblOut EXEC @ReturnCode = xp_cmdshell @vSSIScmdStr
				IF @ReturnCode > 0
					BEGIN
					   SELECT @iErrno  = 50006,
							  @vErrmsg = 'Erreur lors de l''execution du package SSIS'
					   RAISERROR (@vErrmsg, -- Message text.
									16, -- Severity.
									1 -- State.
								   );
					END
				SELECT * FROM @tblOut
				RETURN @ReturnCode
		*/
				-- voir si la job n'est pas dèjà en exécution
				INSERT INTO @xp_results
				EXECUTE master.dbo.xp_sqlagent_enum_jobs @is_sysadmin, @job_owner, @job_id 
		
				SELECT @execution_status = job_state FROM @xp_results
				IF @execution_status = 1 
					BEGIN
 					   SELECT @iErrno  = 50006,
   							  @vErrmsg = '50006:Job runDTSXcalculRelevDepot déjà en exécution'
 					   RAISERROR (@vErrmsg, 10, 1) ;
					END		
	        
				-- MBD: RECUPERATION DE LA VERSION DU SERVER (9. => 2005 OU 10=>2008)
				SELECT @versionServer = left( cast(SERVERPROPERTY('productversion') as VARCHAR),2)       

				-- ligne de commande a mettre à jour dans la job pour passer les bons paramèters
				IF @versionServer='10' --SQL SERVER 2008
					SET @vSSIScmdStr = N'/DTS "\MSDB\'+@vPackageName+'" /SERVER "'+@vServerName
								+'" /CONNECTION "' + @vcSSISConnexion + '";"\"Data Source='+@vServerName+';Initial Catalog='+@vDatabase
								+';Provider=SQLNCLI10.1;Integrated Security=SSPI;Auto Translate=False;\""  /MAXCONCURRENT " -1 " /CHECKPOINTING OFF  /REPORTING V '
								+ @vParams
				ELSE --
					SET @vSSIScmdStr = N'/DTS "\MSDB\'+@vPackageName+'" /SERVER "'+@vServerName
								+'" /CONNECTION "' + @vcSSISConnexion + '";"\"Data Source='+@vServerName+';Initial Catalog='+@vDatabase
								+';Provider=SQLNCLI.1;Integrated Security=SSPI;Auto Translate=False;\""  /MAXCONCURRENT " -1 " /CHECKPOINTING OFF  /REPORTING V '
								+ @vParams
				
				-- mise à jour de la ligne de commande dans la job
				EXEC msdb.dbo.sp_update_jobstep 
								@job_name = @job_name  
								,@step_id = 1
								,@command = @vSSIScmdStr

				-- demarer la job
				EXEC @ReturnCode=msdb.dbo.sp_start_job @job_name = @job_name
				IF @ReturnCode > 0
					BEGIN
					   SELECT @iErrno  = 50007,
							  @vErrmsg = '50007:Erreur lors du démarage JOB SSIS runDTSXcalculRelevDepot'
 					   RAISERROR (@vErrmsg, 10, 2) ;
					END		
				
				-- attendre que l'execution finisse
				SET @execution_status = 1
				WHILE @execution_status = 1
					BEGIN
						DELETE FROM @xp_results
						WAITFOR DELAY '00:00:05';		 
						INSERT INTO @xp_results
							EXECUTE master.dbo.xp_sqlagent_enum_jobs @is_sysadmin, @job_owner, @job_id
						SELECT @iLastRunDate = last_run_date, @iLastRunTime = last_run_time, @execution_status = job_state FROM @xp_results
			--			PRINT CAST(getdate() as varchar(28))
					END

				-- fait voir comment que la job est finie
				INSERT INTO @tmp_sp_help_jobhistory  
					EXEC msdb.dbo.sp_help_jobhistory @job_id = @job_id,@mode='FULL' 
					
				SELECT @iRunStatus	= run_status, @vMessage	= [message]
				FROM @tmp_sp_help_jobhistory 
				WHERE run_date = @iLastRunDate and run_time= @iLastRunTime and step_id=1
				
				IF @iRunStatus <> 1
							/*
							0  Failed 
							1  Succeeded 
							2  Retry (step only) 
							3  Canceled
							4  In-progress message 
							5  Unknown
							*/
					BEGIN
						-- Job en problème - erreur 
					   SELECT @iErrno  = 50008,
							  @vErrmsg = '50008:Job failed !'+ @vMessage
					   RAISERROR (@vErrmsg, 10, 3) ;		
					END
				ELSE
					BEGIN
						-- job ok, retourne le contenu de la table de résultats
						INSERT INTO tblCONV_MessagesDonneeReleveDepot (dtDtTime,vfacette,vmodule,vmess)
						SELECT 
							GETDATE(),'CONV','Calcul relevé de depôt', '-------------- Job runDTSXcalculRelevDepot: Nb.Souscripteurs:' 
							+ cast( count (DISTINCT iIDSouscripteur) AS VARCHAR(18))
							+ ' nb. conventions ' + 
							+ cast( count (DISTINCT iIDConvention) AS VARCHAR(18))
							+ ' nb. enregistr. total ' +
							+ cast( count (*) AS VARCHAR(18))
						FROM 
							dbo.tblCONV_DonneeReleveDepot
						Insert into tblCONV_MessagesDonneeReleveDepot (dtDtTime,vfacette,vmodule,vmess)
						select getdate(),'CONV','Calcul relevé de depôt', '-------------- Job runDTSXcalculRelevDepot: ' 
							+ ' durée : '
							+ cast (datediff(mi,@dtDtHrsStart,getdate())/60 as varchar(3))
							+ ' heures '
							+ cast (datediff(mi,@dtDtHrsStart,getdate()) - 	60*(datediff(mi,@dtDtHrsStart,getdate())/60) as varchar(3))
							+ ' minutes '

						Insert into tblCONV_MessagesDonneeReleveDepot (dtDtTime,vfacette,vmodule,vmess)
						select getdate(),'CONV','Calcul relevé de depôt', '-------------- Job runDTSXcalculRelevDepot: END -------------------------' 
					END
			END
		ELSE
			BEGIN
				SET @ReturnCode = 0
			END
			
		IF @bIsReturn = 1
			BEGIN						
				-- 2011-02-21 : JFG : Recherche des différents régimes du souscripteur concaténés sous la bonne forme
				DECLARE 
						@tSouscripteurPath TABLE
											(
											iIDSouscripteur		INT PRIMARY KEY,
											vcPathPDF			VARCHAR(500)
											)

				INSERT INTO @tSouscripteurPath
				(
					iIDSouscripteur
					,vcPathPDF
				)
				SELECT 
					t1.iIDSouscripteur,
					vcPathPDF = 	( 
										SELECT DISTINCT 
											rr.vcDescription + '_'
										FROM tblCONV_DonneeReleveDepot t2
										INNER JOIN Un_Plan p ON t2.vcRegime = p.PlanDesc
										INNER JOIN tblCONV_RegroupementsRegimes rr ON p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
										WHERE t2.iIDSouscripteur = t1.iIDSouscripteur
										ORDER BY rr.vcDescription + '_' DESC
									 FOR XML PATH('') 
									) 
				FROM tblCONV_DonneeReleveDepot t1
				WHERE (t1.iIDSouscripteur = @iSubscriberID OR @iSubscriberID IS NULL)
				GROUP BY t1.iIDSouscripteur
		
				SELECT 
					iIDConvention, iIDSouscripteur, iIDBeneficiaire, vcNumeroConvention, 
					mQuantiteUnite = ISNULL(mQuantiteUnite,0), 
					vcTypeOperation, 
					mFraisCotisation = ISNULL(mFraisCotisation,0), 
					mFrais = ISNULL(mFrais,0), 
					mSCEE = ISNULL(mSCEE,0), 
					mIntSCEE = ISNULL(mIntSCEE,0), 
					mSCEESup = ISNULL(mSCEESup,0), 
					mIntSCEESup = ISNULL(mIntSCEESup,0), 
					mIQEE = ISNULL(mIQEE,0), 
					mIntIQEE = ISNULL(mIntIQEE,0), 
					mBec = ISNULL(mBec,0), 
					mIntBEC = ISNULL(mIntBEC,0), 
					mPAE = CASE	WHEN ((vcTypeOperation = 'RIO' OR vcTypeOperation = 'RIM' OR vcTypeOperation = 'TRI') AND EXISTS(SELECT 1 FROM dbo.tblCONV_DonneeReleveDepot t2 
																			WHERE 
																					t2.iIDSouscripteur = t1.iIDSouscripteur 
																					AND 
																					t2.iIDConvention = t1.iIDConvention 
																					AND 
																					t2.vcTypeOperation = 'PAE')) THEN 0
								ELSE ISNULL(mPAE,0)
						   END, 
					mIntPAE = CASE	WHEN ((vcTypeOperation = 'RIO' OR vcTypeOperation = 'RIM' OR vcTypeOperation = 'TRI')  AND EXISTS(SELECT 1 FROM dbo.tblCONV_DonneeReleveDepot t2 
																				WHERE 
																						t2.iIDSouscripteur = t1.iIDSouscripteur 
																						AND 
																						t2.iIDConvention = t1.iIDConvention 
																						AND 
																						t2.vcTypeOperation = 'PAE')) THEN 0
									ELSE ISNULL(mIntPAE,0)
						   END, 
					mAutreRev = ISNULL(mAutreRev,0), mIntAutreRev = ISNULL(mIntAutreRev,0), vcAnneeQualif, 
					mBourse = ISNULL(mBourse,0), mMntSouscrit = ISNULL(mMntSouscrit,0), mMntTheoMens = ISNULL(mMntTheoMens,0), dtEntreeVigueur, dtRembEstime, dtFinCotisation, 
					dtFinRegime, vcPrenomRep, vcNomRep, vcTelRep, vcPrenomDir, vcNomDir, vcTelDir, mCoutEtude, 
					vcPrenomSouscripteur, vcNomSouscripteur, vcAdresseSouscripteur, vcVilleSouscripteur, 
					vcProvinceSouscripteur, vcPaysSouscripteur, vcCodePostSouscripteur, 
					bPrincipalResponsableErreur, bPrincipalResponsableManquant, vcLangue, vcPrenomBenef, 
					vcNomBenef, vcNASBenef, dtDateOperation, vcCompagnie, vcRegime, vcTypeDonnee, 
					vcTexteDiplome, iIDRegime, vcDerniereAnnee, vcAvantDernAnnee, vcCourrielSouscripteur, 
					vcTypeContact, cSexeSouscripteur, iPayementParAnnee, iNombrePayement, dtDateCalcul, 
					dtDateFin, mIQEEMaj = ISNULL(mIQEEMaj,0), iNbGroupeUnite,
					nDiffAnneeIQEE, nDiffAnneeSCEE, bEntreeVigueurIQEE, bEntreeVigueurSCEE, dtEcheance,
					t1.bSouscripteur_Desire_Releve_Elect,
					CodeReleveDepot = @CodeReleveDepot,
					vcPathPDF		= 
								CASE WHEN ISNULL(S.AddressLost,0) = 1  THEN
													'ADRINVALID'
								WHEN ISNULL(P.iUserId,0) > 0 AND S.bConsentement = 1 THEN
													'XPORTAIL'
											 ELSE													
												 (
													SELECT
															CASE WHEN t1.vcPaysSouscripteur = 'Canada' THEN
																CASE WHEN t1.vcProvinceSouscripteur = 'QC' THEN			-- Québec
																		'CQC_' 
																		--'CQC_' + tmp.vcPathPDF + '_' 
																	 WHEN t1.vcProvinceSouscripteur = 'NB' THEN			-- Nouveau-Brunswick
																		'CNB_'
																		--'CNB_' + tmp.vcPathPDF + '_'
																	 ELSE												-- Reste du Canada (National = Nat)
																		'NAT_' 
																		--'NAT_' + tmp.vcPathPDF + '_'
																END
															ELSE
																'INT_'
																--'INT_' + tmp.vcPathPDF + '_'
															END	+ t1.vcLangue	
													FROM @tSouscripteurPath tmp
													WHERE t1.iIDSouscripteur = tmp.iIDSouscripteur
													)
									END,
					vcTypeRIO =
							CASE 
							WHEN (t1.vcTypeOperation = 'RIO' OR t1.vcTypeOperation = 'RIM' OR t1.vcTypeOperation = 'TRI') THEN 
								CASE
									WHEN (    -- MBD 20120326: GERER LE CAS DE RETOUR DE PLUSIEURS VALEURS CAS DOUCET, MARIO (I-20111011002)
												SELECT count(DISTINCT  rr.vcCode_Regroupement)
												FROM
													dbo.tblOPER_OperationsRIO rio
													INNER JOIN dbo.Un_Convention c ON rio.iID_Convention_Source = c.ConventionID
													INNER JOIN dbo.Un_Plan p ON p.PlanId = c.PlanId
													INNER JOIN dbo.Un_Oper o ON o.OperID = rio.iID_Oper_RIO
													INNER JOIN dbo.tblCONV_RegroupementsRegimes rr ON rr.iID_Regroupement_Regime = p.iID_Regroupement_Regime
												WHERE o.OperDate BETWEEN @dtDateDebut AND @dtDateFin
													AND	rio.iID_Convention_Destination = t1.iIDConvention) > 1 THEN '' -- si il y a plus d'un transfert de régime different
								ELSE
								CASE	
									WHEN (
												-- MBD 20120326: GERER LE CAS DE RETOUR DE PLUSIEURS VALEURS CAS DOUCET, MARIO (I-20111011002)
												SELECT TOP 1  rr.vcCode_Regroupement
												FROM tblOPER_OperationsRIO rio
												INNER JOIN dbo.Un_Convention c ON rio.iID_Convention_Source = c.ConventionID
												INNER JOIN dbo.Un_Plan p ON p.PlanId = c.PlanId
												INNER JOIN dbo.Un_Oper o ON o.OperID = rio.iID_Oper_RIO
												INNER JOIN dbo.tblCONV_RegroupementsRegimes rr ON rr.iID_Regroupement_Regime = p.iID_Regroupement_Regime
												WHERE o.OperDate BETWEEN @dtDateDebut AND @dtDateFin
													AND	rio.iID_Convention_Destination = t1.iIDConvention) = 'UNI' THEN 'RioUniversitas'
									ELSE
										'RioReeeflex'
								END
				   
							END
							ELSE
								''
							END
					, mIntAutreRevTINDiffere
					, mIntIQEETIN
				FROM tblCONV_DonneeReleveDepot t1
				INNER JOIN dbo.Un_Subscriber S ON t1.iIDSouscripteur = S.SubscriberID
				LEFT JOIN tblGENE_PortailAuthentification P ON t1.iIDSouscripteur = P.iUserId
				WHERE --(iIDSouscripteur = @iSubscriberID OR @iSubscriberID IS NULL)
						iIDSouscripteur IN ( 
								SELECT DISTINCT TOP (1) iIDSouscripteur 
								FROM dbo.tblCONV_DonneeReleveDepot
								WHERE (iIDSouscripteur = @iSubscriberID OR @iSubscriberID IS NULL)
									--iIDSouscripteur = @iSubscriberID
									-- MBD 20120326: GERER LES EXCLUS
									AND iIDSouscripteur NOT IN (SELECT SubscriberId FROM dbo.tblCONV_RelDepConvExclu te WHERE te.SubscriberId = iIDSouscripteur AND te.ConventionId = iIDConvention)
									AND iIDConvention NOT IN (SELECT ConventionId FROM dbo.tblCONV_RelDepConvExclu te WHERE te.SubscriberId = iIDSouscripteur AND te.ConventionId = iIDConvention)
								--AND iIDSouscripteur = 601617
								ORDER BY iIDSouscripteur
								)
			ORDER BY 
			iIDSouscripteur,
			iIDBeneficiaire,
			iIDConvention,
			vcRegime,
			vcTypeDonnee DESC, 
			dtDateOperation ASC	
		END
		
	END TRY
	BEGIN CATCH

		SELECT	@vErrmsg		= REPLACE(ERROR_MESSAGE(),'%',' '),
				@iErrState		= ERROR_STATE(),
				@iErrSeverity	= ERROR_SEVERITY(),
				@iErrno			= ERROR_NUMBER();

		-- SELECT * FROM @tblOut  -- pour la version avec activation directe de la SSIS

		INSERT INTO tblCONV_MessagesDonneeReleveDepot (dtDtTime,vfacette,vmodule,vmess)
		SELECT GETDATE(),'CONV','Calcul relevé de depôt','-------------- '+@vErrmsg+' -------------------------' 

		INSERT INTO tblCONV_MessagesDonneeReleveDepot (dtDtTime,vfacette,vmodule,vmess)
		SELECT GETDATE(),'CONV','Calcul relevé de depôt', '-------------- Job runDTSXcalculRelevDepot: ERROR -------------------------' 

		IF @iErrno >= 50000					-- RETOURNE L'ERREUR UTILISATEUR SELON P171
			BEGIN
				RAISERROR (@vErrmsg, 10, 4)
			END
		ELSE								-- RETOURNE L'ERREUR SYSTÈME
			BEGIN			
				RAISERROR	(		
							@vErrmsg,		-- Message text.
							@iErrSeverity,	-- Severity.
							@iErrState		-- State.
							)
			END
	
	END CATCH

	SET @dtEnd = GETDATE()

	SELECT
		@iType				= 3,
		@fDuration			= DATEDIFF(ms,@dtStart, @dtEnd),
		@vcDescription		= 'Génère et retourne les données liés au relevé de dépôt pour généer les PDF',
		@vcStoredProcedure	= 'psCONV_ObtenirDonneeReleveDepot_StartSSIS',
		@vcExecutionString	= 'EXEC dbo.psCONV_ObtenirDonneeReleveDepot_StartSSIS @dtDateDebut	= '		+ @vDateDebut + ', @dtDateFin		= ' +  @vDateFin	+ ', @iSubscriberID	= ' + @vSubscriberID + ', @bIsSave		= ' + CAST(@bIsSave AS VARCHAR(1)) + ', @iConnectId = '	+ CAST(@iConnectId AS VARCHAR(15))

	-- INSERTION DU SUIVI DANS la table Un_Trace
	EXEC dbo.psGENE_EnregistrerTrace
	 	@iConnectID,
	  	@iType,
	 	@fDuration,
	 	@dtStart,
	 	@dtEnd,
	 	@vcDescription,
	 	@vcStoredProcedure,
	 	@vcExecutionString	

	RETURN @ReturnCode
    */
END