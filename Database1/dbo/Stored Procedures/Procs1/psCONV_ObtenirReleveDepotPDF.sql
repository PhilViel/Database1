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
Code de service		:		psCONV_ObtenirReleveDepotPDF
Nom du service		:		
But					:		Obtenir les données par intervalle ou non pour générer les PDF du relevé de dépôt    
Facette				:		P171U
Reférence			:		Relevé de dépôt

Parametres d'entrée :	Parametres					Description										Obligatoire
                        ----------                  ----------------								--------------                       
                        @iSubscriberIdDebut         Numéro du souscripteur débutant l'intervalle    Non
						@iNbreSouscripteur			Nombre de souscripteur que l'on veut retourner	Non

Exemples d'appel:
			EXEC psCONV_ObtenirReleveDepotPDF 198358, 500,2											-- : retourne tous les enregistrements pour les 500 souscripteurs partant de 198358 (inclus)
			EXEC psCONV_ObtenirReleveDepotPDF 196964, 1, 2,'2010-01-01','2010-12-31',1, 50			-- : retourne tous les enregistrements


Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
						tblCONV_DonneeReleveDepot	Tous les champs
													CodeReleveDepot								Code de relevé de dépôt provenant des paramètres applicatifs.

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-04-28					Jean-François Gauthier					Création de la procédure
						2009-04-30					Jean-François Gauthier					Modification pour appeler la 
																							procédure de suivi psGENE_EnregistrerTrace 																							
						2009-05-07					Jean-François Gauthier					Modification appeler psCONV_ObtenirDonneeReleveDepot_StartSSIS																	
						2009-07-09					Jean-François Gauthier					Ajout du champ bSouscripteur_Desire_Releve_Elect
						2009-09-14					Jean-François Gauthier					Ajout du champ mIQEEMaj
						2009-11-05					Jean-François Gauthier					Ajout des champ  : iNbGroupeUnite, nDiffAnneeIQEE, nDiffAnneeSCEE, bEntreeVigueurIQEE, bEntreeVigueurSCEE, dtEcheance
						2010-01-07					Jean-François Gauthier					Modification pour retourner le champ bSouscripteur_Desire_Releve_Elect
						2010-05-05					Jean-François Gauthier					Ajout de la gestion des erreurs
						2010-05-21					Jean-François Gauthier					Ajout du IsNull sur le champ mQuantiteUnite
						2010-05-28					Jean-François Gauthier					Ajout de la validation avec la date de dernière génération dans la table 
																							versus la date demandée, dans le cas où on ne veut pas générer les données
						2010-05-31					Jean-François Gauthier					Modification des numéros d'erreur afin qu'ils soient en haut de 70 000																							
																							Modification de la gestion des erreurs
						2010-06-04					Jean-François Gauthier					Modification pour la comparaison 	
						2010-01-11					Jean-François Gauthier					Ajout du champ CodeReleveDepot en sortie
						2011-02-21					Jean-François Gauthier					Modifier pour retourner le répertoire où sauvegarder le PDF (champ vcPathPDF) 		
						2011-03-01					Jean-François Gauthier					Ajout du champ vcTypeRIO	
						2011-03-08					Jean-François Gauthier					Ajout des ISNULL sur les montants retournés															
						2011-03-16					Jean-François Gauthier					Ajout des conventions à exclure à partir de la table tblCONV_RelDepConvExclu
						2011-08-24					Frédérick Thibault						Ajout RIM et TRI
						2013-02-07					Pierre-Luc Simard						Validation du consentement pour ceux du Portail
						2013-03-15					Pierre-Luc Simard						Retrait des régimes dans le champ vcPathPDF
                        2017-09-27                  Pierre-Luc Simard                       Deprecated - Cette procédure n'est plus utilisée

 ****************************************************************************************************/
/*
	sp_addmessage 70001, 11, 'Plusieurs dates de génération présente. Veuillez regénérer.'
	sp_addmessage 70002, 11, 'Date de génération NULL présente. Veuillez regénérer.'
	sp_addmessage 70003, 11, 'Date de génération ne correspond pas à celle passée en paramètre. Veuillez regénérer.'


	sp_dropmessage 70001
	sp_dropmessage 70002
	sp_dropmessage 70003

*/ 
CREATE PROCEDURE [dbo].[psCONV_ObtenirReleveDepotPDF]
@iIDSouscripteurDebut int = null, @iNbreSouscripteur int = null, @iConnectId int, @dtDateDebut datetime = null, @dtDateFin datetime = null, @bIsSave bit = null, @iNbPsPrep int = null
WITH EXEC AS CALLER
AS
BEGIN
		SELECT 1/0
        /*
        SET NOCOUNT ON
		
		DECLARE		 
			@iErrSeverite			INT
			,@iErrStatut			INT
			,@iErrNo				INT
			,@vcErrMsg				NVARCHAR(1024)
			,@dtDateFinGeneration	DATETIME
			,@CodeReleveDepot		VARCHAR(5)
				
		BEGIN TRY
			-- AJOUT DES MESSAGES PERSONNALISÉS
			EXECUTE sp_addmessage 70001, 11, 'Plusieurs dates de génération présente. Veuillez regénérer.'
			EXECUTE sp_addmessage 70002, 11, 'Date de génération NULL présente. Veuillez regénérer.'
			EXECUTE sp_addmessage 70003, 11, 'Date de génération ne correspond pas à celle passée en paramètre. Veuillez regénérer.'
			
			IF @bIsSave = 0 -- On prend les données existantes
				BEGIN
					-- 2010-05-28 : Vérification si plusieurs dates de fin distinctes
					IF (SELECT COUNT(DISTINCT dtDateFinGeneration) FROM dbo.tblCONV_DonneeReleveDepot) > 1
						BEGIN							
							SELECT
								@iErrNo			= 70001 -- 'Plusieurs dates de génération présente. Veuillez regénérer.'
								,@iErrStatut	= 1
								,@iErrSeverite	= 11
		
							RAISERROR	(@iErrNo, @iErrSeverite, @iErrStatut) WITH LOG
						END
					
					-- 2010-05-28 : Vérification si certaines dates sont NULL
					IF EXISTS(SELECT 1 FROM dbo.tblCONV_DonneeReleveDepot WHERE dtDateFinGeneration IS NULL)
						BEGIN
							SELECT
								@iErrNo			= 70002 -- 'Date de génération NULL présente. Veuillez regénérer.'
								,@iErrStatut	= 1
								,@iErrSeverite	= 11
		
							RAISERROR	(@iErrNo, @iErrSeverite, @iErrStatut) WITH LOG
						END
						
					SET @dtDateFinGeneration = (SELECT TOP 1 dtDateFinGeneration FROM dbo.tblCONV_DonneeReleveDepot)
					
					-- 2010-05-28 : Validation de la date de fin demandée	
					IF	((@dtDateFin IS NULL) 
						OR 
						(DATEDIFF(dd, @dtDateFinGeneration, @dtDateFin) <> 0))
						BEGIN
							SELECT
								@iErrNo			= 70003 -- 'Date de génération ne correspond pas à celle passée en paramètre. Veuillez regénérer.'
								,@iErrStatut	= 1
								,@iErrSeverite	= 11
		
							RAISERROR	(@iErrNo, @iErrSeverite, @iErrStatut) WITH LOG
						END
				END
			
			-- INSERTION DU PARAMÈTRE DE GÉNÉRATION		
			TRUNCATE TABLE dbo.tblCONV_NbPsPrep

			IF @iNbPsPrep IS NULL
				BEGIN
					SET @iNbPsPrep = -1
				END

			INSERT INTO dbo.tblCONV_NbPsPrep
			(iNbPsPrep)
			VALUES
			(@iNbPsPrep)

			DECLARE
				@iType				INTEGER,
				@fDuration			FLOAT,	
				@dtStart			DATETIME,
				@dtEnd				DATETIME,
				@vcDescription		VARCHAR(500),
				@vcStoredProcedure	VARCHAR(200),
				@vcExecutionString	VARCHAR(2000)

			SET @dtStart = GETDATE()

			-- VÉRIFICATION SI ON DOIT GÉNÉRER LES DONNÉES
			IF @bIsSave = 1 
				BEGIN
					EXECUTE dbo.psCONV_ObtenirDonneeReleveDepot_StartSSIS
																@dtDateDebut,			-- Date début du relevé
																@dtDateFin,				-- Date fin du relevé
																NULL,					-- Identifiant unique du souscripteur
																1,						-- Indicateur si création tbl... ou seulement lecture
																@iConnectId				-- Connection ID
				END
			
			-- SI PAS DE NUMÉRO, ON PART DU DÉBUT (1er NUMÉRO DE SOUSCRIPTEUR)
			IF (@iIDSouscripteurDebut IS NULL) 
				BEGIN
					SET	@iIDSouscripteurDebut = 0
				END

			-- SI PAS DE NOMBRE, ON PREND TOUS LES ENREGISTREMENT
			IF (@iNbreSouscripteur IS NULL) 
				BEGIN
					SET	@iNbreSouscripteur = 99999999
				END
				
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
									SELECT 
										DISTINCT 
											rr.vcDescription + '_'
									FROM 
										dbo.tblCONV_DonneeReleveDepot t2
										left outer JOIN dbo.Un_Plan p
											ON t2.vcRegime = p.PlanDesc
										left outer JOIN dbo.tblCONV_RegroupementsRegimes rr
											ON p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
									WHERE 
										t2.iIDSouscripteur = t1.iIDSouscripteur
									ORDER BY
										rr.vcDescription + '_' DESC
								 FOR XML PATH('') 
								) 
			FROM 
				dbo.tblCONV_DonneeReleveDepot t1
			GROUP BY 
				t1.iIDSouscripteur

			-- 2010-01-10 : JFG : Recherche du code de relevé de dépôt dans les paramètres applicatifs
			SET @CodeReleveDepot = dbo.fnGENE_ObtenirParametre('CONV_RDEP_CODE_RELEVE', NULL, NULL, NULL, NULL, NULL, NULL)

			SELECT
				iIDConvention, iIDSouscripteur, iIDBeneficiaire, vcNumeroConvention, 
				mQuantiteUnite = ISNULL(mQuantiteUnite,0), 
				vcTypeOperation, mFraisCotisation = ISNULL(mFraisCotisation,0), mFrais = ISNULL(mFrais,0), mSCEE = ISNULL(mSCEE,0), mIntSCEE = ISNULL(mIntSCEE,0), 
				mSCEESup = ISNULL(mSCEESup,0), mIntSCEESup = ISNULL(mIntSCEESup,0), 
				mIQEE = ISNULL(mIQEE,0), mIntIQEE = ISNULL(mIntIQEE,0), mBec = ISNULL(mBec,0), mIntBEC = ISNULL(mIntBEC,0), 
				mPAE = CASE	WHEN ((vcTypeOperation = 'RIO' OR vcTypeOperation = 'RIM' OR vcTypeOperation = 'TRI') AND EXISTS(SELECT 1 FROM dbo.tblCONV_DonneeReleveDepot t2 
																				WHERE 
																						t2.iIDSouscripteur = t1.iIDSouscripteur 
																						AND 
																						t2.iIDConvention = t1.iIDConvention 
																						AND 
																						t2.vcTypeOperation = 'PAE'))  THEN 0
									ELSE ISNULL(mPAE,0)
							   END, 
				mIntPAE = CASE	WHEN ((vcTypeOperation = 'RIO' OR vcTypeOperation = 'RIM' OR vcTypeOperation = 'TRI') AND EXISTS(SELECT 1 FROM dbo.tblCONV_DonneeReleveDepot t2 
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
				dtDateFin, t1.bSouscripteur_Desire_Releve_Elect, mIQEEMaj = ISNULL(mIQEEMaj,0),iNbGroupeUnite,nDiffAnneeIQEE, 
				nDiffAnneeSCEE, bEntreeVigueurIQEE, bEntreeVigueurSCEE, dtEcheance, t1.bSouscripteur_Desire_Releve_Elect
				,CodeReleveDepot = @CodeReleveDepot
				,vcPathPDF		=  
									CASE WHEN ISNULL(S.AddressLost,0) = 1  THEN
														'ADRINVALID'
									--WHEN ISNULL(t1.bSouscripteur_Desire_Releve_Elect,0) = 1 AND LEN(LTRIM(RTRIM(ISNULL(t1.vcCourrielSouscripteur,'')))) > 0 THEN
									--					'XPORTAIL'
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
														FROM
															@tSouscripteurPath tmp
														WHERE
															t1.iIDSouscripteur = tmp.iIDSouscripteur
														)
											END
				,vcTypeRIO =
							CASE 
								WHEN (t1.vcTypeOperation = 'RIO' OR t1.vcTypeOperation = 'RIM' OR t1.vcTypeOperation = 'TRI') THEN 
									CASE
                  WHEN (    -- MBD 20120326: GERER LE CAS DE RETOUR DE PLUSIEURS VALEURS CAS DOUCET, MARIO (I-20111011002)
                             -- SELECT DISTINCT rr.vcCode_Regroupement
                              SELECT count(DISTINCT  rr.vcCode_Regroupement)
      												FROM
      													dbo.tblOPER_OperationsRIO rio
      													INNER JOIN dbo.Un_Convention c
      														ON rio.iID_Convention_Source = c.ConventionID
      													INNER JOIN dbo.Un_Plan p
      														ON p.PlanId = c.PlanId
      													INNER JOIN dbo.Un_Oper o
      														ON o.OperID = rio.iID_Oper_RIO
      													INNER JOIN dbo.tblCONV_RegroupementsRegimes rr
      														ON rr.iID_Regroupement_Regime = p.iID_Regroupement_Regime
      												WHERE
      													o.OperDate BETWEEN @dtDateDebut AND @dtDateFin
      													AND
      													rio.iID_Convention_Destination = t1.iIDConvention) > 1 THEN '' -- si il y a plus d'un transfert de régime different
                  ELSE
                        --
                        CASE	
      										WHEN (
                               -- MBD 20120326: GERER LE CAS DE RETOUR DE PLUSIEURS VALEURS CAS DOUCET, MARIO (I-20111011002)
                             -- SELECT DISTINCT rr.vcCode_Regroupement
                              SELECT TOP 1  rr.vcCode_Regroupement
      												FROM
      													dbo.tblOPER_OperationsRIO rio
      													INNER JOIN dbo.Un_Convention c
      														ON rio.iID_Convention_Source = c.ConventionID
      													INNER JOIN dbo.Un_Plan p
      														ON p.PlanId = c.PlanId
      													INNER JOIN dbo.Un_Oper o
      														ON o.OperID = rio.iID_Oper_RIO
      													INNER JOIN dbo.tblCONV_RegroupementsRegimes rr
      														ON rr.iID_Regroupement_Regime = p.iID_Regroupement_Regime
      												WHERE
      													o.OperDate BETWEEN @dtDateDebut AND @dtDateFin
      													AND
      													rio.iID_Convention_Destination = t1.iIDConvention) = 'UNI' THEN 'RioUniversitas'
      										ELSE
      											'RioReeeflex'
      									END
                       --
                 END
								ELSE
									''
							END
			,mIntAutreRevTINDiffere
			,mIntIQEETIN
			FROM 
				dbo.tblCONV_DonneeReleveDepot t1
				INNER JOIN dbo.Un_Subscriber S 
								ON t1.iIDSouscripteur = S.SubscriberID
				LEFT JOIN tblGENE_PortailAuthentification P 
								ON t1.iIDSouscripteur = P.iUserId
			WHERE 
				iIDSouscripteur IN ( 
									 SELECT 
										DISTINCT TOP (@iNbreSouscripteur) iIDSouscripteur 
									 FROM 
										dbo.tblCONV_DonneeReleveDepot
									 WHERE 
										iIDSouscripteur > @iIDSouscripteurDebut
                    -- MBD 20120326: GERER LES EXCLUS
                    and iIDSouscripteur NOT IN (SELECT SubscriberId   FROM dbo.tblCONV_RelDepConvExclu te WHERE te.SubscriberId = iIDSouscripteur AND te.ConventionId = iIDConvention)
										and iIDConvention NOT IN (SELECT ConventionId   FROM dbo.tblCONV_RelDepConvExclu te WHERE te.SubscriberId = iIDSouscripteur AND te.ConventionId = iIDConvention)

                    
									  ORDER BY 
										iIDSouscripteur
									 )
  -- MBD 20120326: GERER LES EXCLUS                  
	--			AND
	--				NOT EXISTS(SELECT 1 FROM dbo.tblCONV_RelDepConvExclu te WHERE te.SubscriberId = t1.iIDSouscripteur AND te.ConventionId = t1.iIDConvention)
			ORDER BY 
				iIDSouscripteur,
				iIDBeneficiaire,
				iIDConvention,
				vcRegime,
				vcTypeDonnee DESC, 
				dtDateOperation ASC


			SET @dtEnd = GETDATE()

			SELECT
				@iType				= 3,
				@fDuration			= DATEDIFF(ms,@dtStart, @dtEnd),
				@vcDescription		= 'Retourne les données liés au relevé de dépôt pour généer les PDF',
				@vcStoredProcedure	= 'psCONV_ObtenirReleveDepotPDF',
				@vcExecutionString	= 'EXEC [dbo].[psCONV_ObtenirReleveDepotPDF] @iIDSouscripteurDebut = '	+ CAST(@iIDSouscripteurDebut AS VARCHAR(15)) + ',  @iNbreSouscripteur = ' + CAST(@iNbreSouscripteur AS VARCHAR(15)) + ', @iConnectId = ' + CAST(@iConnectId AS VARCHAR(15))


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
		END TRY
		BEGIN CATCH
			SELECT
				@iErrNo				= ERROR_NUMBER()
				,@vcErrMsg			= REPLACE(ERROR_MESSAGE(),'%',' ')
				,@iErrStatut		= ERROR_STATE()
				,@iErrSeverite		= ERROR_SEVERITY()				
	
			RAISERROR	(@iErrNo, @iErrSeverite, @iErrStatut) WITH LOG
		END CATCH
		
		-- ON VIDE LES MESSAGES PERSONNALISÉS
		EXECUTE sp_dropmessage 70001
		EXECUTE sp_dropmessage 70002
		EXECUTE sp_dropmessage 70003
        */
	END