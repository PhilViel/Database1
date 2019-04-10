/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psCONV_CreerChangementBeneficiaire
Nom du service		: Créer un changement de bénéficiaire
But 				: Créer un changement de bénéficiaire 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Convention				Identifiant de la convention qui fait l’objet d’un changement de
													bénéficiaire.
						iID_Nouveau_Beneficiaire	Identifiant du nouveau bénéficiaire.
						vcCode_Raison				Code de la raison du changement de bénéficiaire.
						vcAutre_Raison_Changement_	Description de la raison du changement de bénéficiaire si la raison
							Beneficiaire			est autre.
						bLien_Frere_Soeur_Avec_Anc	Indicateur de lien frère/sœur entre l’ancien et le nouveau
							ien_Beneficiaire		bénéficiaire.
						bLien_Sang_Avec_Souscripte	Indicateur de lien de sang entre le nouveau bénéficiaire et le
							ur_Initial				souscripteur initial.
						tiID_Type_Relation_Souscri	Identifiant de la relation entre le souscripteur et le nouveau
							pteur_Nouveau_Benefici	bénéficiaire.
							aire
						tiID_Type_Relation_CoSousc	Identifiant de la relation entre le co-souscripteur et le nouveau
							ripteur_Nouveau_Benefi	bénéficiaire.
							ciaire
						dDateDeces					Date de décès du bénéficiaire			
						dDateChangementBeneficiaire Date du changement de bénéficiaire
						iID_Utilisateur_Creation	Identifiant de l’utilisateur qui réalise le changement de bénéficiaire.
													S’il n’est pas spécifié, le service considère l’utilisateur système.

Exemple d’appel		:	exec [dbo].[psCONV_CreerChangementBeneficiaire] 159756, 296133, 'PEP', 'Accident le 25 janvier', 1, 1, 1, 1, NULL, '2010-02-02', 546658
						exec dbo.psCONV_CreerChangementBeneficiaire 239117,538229,'AUT','blabla',0,0,1,NULL,NULL,'2010-03-08',2 , 0

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					> 0 = Identifiant du nouveau
																						  changement de bénéficiaire en
																						  cas de réussite du traitement
																						  (tblCONV_ChangementsBeneficiaire.
																						  iID_Changement_Beneficiaire)
																					-1 = Erreur dans les paramètres
																					-2 = Erreur de traitement

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-02-18		Pierre Paquet						Création du service							
		2010-02-18		Jean-François Gauthier				Ajout de la gestion des erreurs et des transactions.
		2010-03-04		Jean-François Gauthier				Correction pour régler le problème de "Insert exec cannot be nested" 
																lors de l'appel à VL_UN_Convention_IU
		2010-03-05		Jean-François Gauthier				Modification pour appeller VL_UN_Convention_IU avec l'identifiant
																du nouveau bénéficiaire	
		2010-03-08		Jean-François Gauthier				Intégration des validations de VL_UN_Convention_IU directement
																dans la procédure			
		2010-03-15		Pierre Paquet						Correction: Insérer les bonnes valeurs des liens dans un_convention.											
		2010-03-17		Pierre Paquet						Ajout du paramètre @iID_Connexion pour l'utilisation sur IU_UN_Convention
		2010-04-28		Pierre Paquet						Ajout d'une validation: il ne doit pas y avoir de changement de bénéficiaire en attente d'envoi.
		2010-04-29		Pierre Paquet						Ajout de la validation CONVE0024
		2010-04-29		Pierre Paquet						Ajout de la journalisation de deathdate
		2010-05-11		Pierre Paquet						S'assurer qu'il n'y a plus de BEC dans la convention. CONVE0003.
																Vérifier si une convention suggérée est tiCESPState 2 ou 4. 
		2010-05-13		Pierre Paquet						Correction validation CONVE0023
		2010-05-14		Pierre Paquet						Ajout de la gestion du iCESPState de la convention.
		2010-06-03		Pierre Paquet						Ajout du call à TT_UN_ConventionStateForUnit
																Ajout de la validation CONV0025.
		2010-06-08		Pierre Paquet						Ajout de la validation CONVE0003
		2010-06-14		Pierre Paquet						Correction sur la 2ème validation de CONVE0003.
		2010-06-22		Pierre Paquet						Utilisation de fntCONV_RechercherChangementsBeneficiaire.
		2010-11-18		Jean-Francois Arial					Ajout du champ bRISansPreuve lors de l'appel à SL_UN_CONVENTION
		2012-02-22		Eric Michaud						Ajout de dtDateRQ,dtDateFinRegime,dtDateFinRegimeOriginale,dtDateEntreeVigueur pour SL_UN_CONVENTION
		2014-11-07		Pierre-Luc Simard					Ne plus enregistrer la valeur du champs tiCESPState, qui est maintenant géré par la procédure psCONV_EnregistrerPrevalidationPCEE
		2015-07-29		Steve Picard						Utilisation du "Un_Convention.TexteDiplome" au lieu de la table UN_DiplomaText
        2017-03-20  Steeve Bélanger         Ajout du champ tiMaximisationREEE
        2017-06-16  Pierre-Luc Simard       Ne pas ajouter le champ tiMaximisationREEE pour l'instant suite à des problèmes avec les changements de bénéficiaire
        2017-06-19      Steeve Picard                       Ajout du champ tiMaximisationREEE dans la procédure « dbo.SL_UN_Convention » qui est appelée
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_CreerChangementBeneficiaire]
(
	@iID_Convention INT,
	@iID_Nouveau_Beneficiaire INT,
	@vcCode_Raison VARCHAR(3),
	@vcAutre_Raison_Changement_Beneficiaire VARCHAR(150),
	@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire BIT,
	@bLien_Sang_Avec_Souscripteur_Initial BIT,
	@tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire TINYINT,
	@tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire TINYINT,
	@dDateDeces DATETIME,
	@dDateChangementBeneficiaire DATETIME,
	@iID_Utilisateur_Creation INT,
	@iID_Connexion INT
)
AS
	BEGIN
		SET	NOCOUNT ON	
		
		DECLARE	@iID_Beneficiaire_Cedant			INT
				,@iErrno							INT
				,@iErrSeverity						INT
				,@iErrState							INT
				,@vErrmsg							NVARCHAR(1024)
				,@iID_CodeErreur					INT
				,@iRetour							INT
				,@iID_Connect						INT
				,@iID_Oper							INT
				,@iID_Cotisation					INT
				,@iID_CESP400						INT
				,@iID_Subscriber					INT
				,@iID_CoSubscriber					INT
				,@iID_Beneficiary					INT
				,@iID_Plan							INT
				,@vcConventionNo					VARCHAR(15)
				,@dtPmtDate							DATETIME
				,@cID_PmtType						CHAR(3)
				,@dtGovernmentRegDate				DATETIME
				,@iID_DiplomaText					INT	= -1	-- 2015-07-29
				,@bSendToCESP						BIT 				
				,@bCESGRequested					BIT 			
				,@bACESGRequested					BIT 			
				,@bCLBRequested						BIT 			
				,@tiCESPState						TINYINT 			
				,@tiID_RelationshipType				TINYINT  
				,@vcDiplomaText						VARCHAR(150)		
				,@iID_DestinationRemboursement		INT
				,@vcDestinationRemboursementAutre	VARCHAR(50)
				,@dtDateduProspectus				DATETIME
				,@bSouscripteurDesireIQEE			BIT
				,@tiLienCoSouscripteur				TINYINT
				,@bTuteurDesireReleveElect			BIT
				,@iSous_Cat_ID_Resp_Prelevement		INT
				,@bFormulaireRecu					BIT
				,@iCode_Retour						INT
				,@vcSQL								VARCHAR(4000)
				,@iResultat							INT
				,@vcNomBeneficiaire					VARCHAR(100)
				,@vcPrenomBeneficiaire				VARCHAR(100)
				,@dVieilleDateDeces					DATETIME
				,@LogDesc							MoNoteDescOption
				,@HeaderLog							MoNoteDescOption
				,@cSep								CHAR(1) -- Variable du caractère s‚parateur de valeur du blob
				,@UnitIDs							VARCHAR(MAX)
				,@UnitID							INT
				,@dDateJour							DATETIME
				,@vcEtatBEC							VARCHAR(10)
				,@iID_Beneficiaire_Actuel			INT
				
		DECLARE @tConvention TABLE
							(
							iSubscriberID			INT,
							iBeneficiaryID			INT,
							vcConventionNo			VARCHAR(15),
							iYearQualif				INT,
                            tiMaximisationREEE      tinyint,
							dtPmtDate				DATETIME,
							cPmtTypeID				CHAR(3),
							tiRelationshipTypeID	TINYINT,
							vcRelationshipType		VARCHAR(25),
							iPlanID					INT,
							dtGovernmentRegDate		DATETIME,
							siScholarshipYear		SMALLINT,
							cScholarshipEntryID		CHAR(1),
							vcPlanDesc				VARCHAR(75),
							cPlanTypeID				CHAR(3),
							iBankID					INT,
							vcAccountName			VARCHAR(75),
							vcTransitNo				VARCHAR(75),
							vcBankName				VARCHAR(75),
							vcBankTransit			VARCHAR(75),
							vcBankTypeCode			VARCHAR(75),
							vcBankTypeName			VARCHAR(75),
							dtFirstPmtDate			DATETIME,
							iConventionBreaking		INT,
							mCapitalINTerestAmount	MONEY,
							mGrantINTerestAmount	MONEY,
							dtRegEndDateAdjust		DATETIME,
							dtInforceDateTIN		DATETIME,
							mAvailableFeeAmount		MONEY,
							iCoSubscriberID			INT,
							vcCoSubscriberName		VARCHAR(87),
							iNbNSF					INT,
							dtCESGInForceDate		DATETIME,
							cConventionStateID		CHAR(3),
							vcConventionStateName	VARCHAR(75),
							dAutoMonthTheoricAmount	DECIMAL(38, 8),
							iDiplomaTextID			INT,
							vcDiplomaText			VARCHAR(150),
							bSendToCESP				BIT,
							mCESG					MONEY,
							mACESG					MONEY,
							mCLB					MONEY,
							bCESGRequested			BIT,
							bACESGRequested			BIT,
							bCLBRequested			BIT,
							tiCESPState				TINYINT,
							tiSubsCESPState			TINYINT,
							tiCoSubsCESPState		TINYINT,
							tiBenefCESPState		TINYINT,
							mAvailableUnitQty		MONEY,
							iDestinationRemboursementID		INT,
							vcDestinationRemboursementAutre	VARCHAR(50),
							dtDateduProspectus				DATETIME,
							bSouscripteurDesireIQEE			BIT,
							tiID_Lien_CoSouscripteur		TINYINT,
							vcLienCoSouscripteur			VARCHAR(25),
							bTuteur_Desire_Releve_Elect		BIT,
							iSous_Cat_ID_Resp_Prelevement	INT,
							bFormulaireRecu					BIT,
							dtRegStartDate					DATETIME, 
							bSouscripteur_Desire_IQEE		BIT, 
							IQEE							MONEY,	
							IQEEMaj							MONEY,
							bRISansPreuve					BIT,
							dtDateRQ						DATETIME, 
  							dtDateFinRegime					DATETIME, 
							dtDateFinRegimeOriginale		DATETIME,
							dtDateEntreeVigueur				DATETIME
							)
							
		DECLARE  @tConventionNo TABLE
									(
										vcConventionNo VARCHAR(75)
									)	

		BEGIN TRY

				------------------
				BEGIN TRANSACTION
				------------------
				SET @dDateJour = (GETDATE())

				-- S'assurer que la convention n'est pas au statut 'FRM'.
				IF (dbo.fnCONV_ObtenirStatutConventionEnDate (@iID_Convention, @dDateJour)) = 'FRM'
				BEGIN
						SELECT					
							@vErrmsg			= ('CONVE0025')
							,@iErrState			= 1
							,@iErrSeverity		= 11
							,@iID_CodeErreur	= -1
							,@iCode_Retour		= -1
						
						RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
				END		

				-- S'assurer qu'il n'y a pas de demande de BEC en attente ou de montant de BEC.
				-- Récupérer le bénéficiaire actuel de la convention
				SET @iID_Beneficiaire_Actuel = (SELECT BeneficiaryID FROM dbo.UN_Convention WHERE ConventionID = @iID_Convention)
				-- Obtenir l'état actuel de la convention.
				SET @vcEtatBEC = (SELECT dbo.fnCONV_ObtenirEtatBEC (@iID_Beneficiaire_Actuel))
				
				-- Si le BEC est actif sur la convention, alors on afficher l'erreur.
				IF (@vcEtatBEC = 'CONVM003' OR @vcEtatBEC = 'CONVM005' OR @vcEtatBEC = 'CONVM008')
					AND EXISTS (SELECT 1 FROM dbo.UN_Convention WHERE ConventionID = @iID_Convention AND bCLBRequested = 1)
				BEGIN
						SELECT					
							@vErrmsg			= ('CONVE0003')
							,@iErrState			= 1
							,@iErrSeverity		= 11
							,@iID_CodeErreur	= -1
							,@iCode_Retour		= -1
						
						RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
				END		

				-- S'assurer qu'il n'y a pas un changement de bénéficiare en attente d'envoi au PCEE.
				-- Autre que le bénéficiaire actuel.
				IF EXISTS (SELECT 1 FROM dbo.UN_CESP200 
									WHERE HumanID <> @iID_Nouveau_Beneficiaire 
									AND iCESPSendFileID IS NULL
									AND tiType = 3
									AND ConventionID = @iID_Convention
									AND HumanID <> (SELECT BeneficiaryID FROM dbo.UN_convention where conventionId = @iID_Convention))
				BEGIN
						SELECT					
							@vErrmsg			= ('CONVE0023')
							,@iErrState			= 1
							,@iErrSeverity		= 11
							,@iID_CodeErreur	= -1
							,@iCode_Retour		= -1
						
						RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
				END
							
				-- S'assurer qu'il n'y a pas de montant BEC dans la convention.
				DECLARE @mMontantBECRembourser MONEY
				SELECT @mMontantBECRembourser = SUM(C4.fCLB) -- Solde de BEC à rembourser
										FROM Un_CESP400 C4 
										LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
										LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
										WHERE C9.iCESP900ID IS NULL
											AND C4.iCESP800ID IS NULL
											AND CE.iCESPID IS NULL
											AND C4.ConventionID = @iID_Convention
										GROUP BY C4.ConventionID

				IF (SELECT SUM(fCLB) FROM dbo.fntPCEE_ObtenirSubventionBons(@iID_Convention, null, null)) + ISNULL(@mMontantBECRembourser,0) > 0 
					AND (@vcEtatBEC = 'CONVM003' OR @vcEtatBEC = 'CONVM005' OR @vcEtatBEC = 'CONVM008')
				BEGIN
						SELECT					
							@vErrmsg			= ('CONVE0003')
							,@iErrState			= 1
							,@iErrSeverity		= 11
							,@iID_CodeErreur	= -1
							,@iCode_Retour		= -1
						
						RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
				END
							
				-- Récupérer l'identifiant du bénéficiaire cédant
				--@iID_Beneficiaire_Cedant = dbo.fnGENE_beneficiaireEnDate (@iID_Convention, @dDateChangementBeneficiaire)
				SET @iID_Beneficiaire_Cedant = (SELECT iID_Nouveau_Beneficiaire FROM [dbo].[fntCONV_RechercherChangementsBeneficiaire](NULL, NULL, @iID_Convention, NULL, @dDateChangementBeneficiaire, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL))

				-- Vérifier si le bénéficiaire cédant à un NAS et que le nouveau bénéficiaire n'a pas de NAS, si oui alors erreur!
				IF EXISTS (SELECT 1 FROM dbo.Mo_Human WHERE HumanID = @iID_Beneficiaire_Cedant AND SocialNumber IS NOT NULL)
				BEGIN
					IF EXISTS (SELECT 1 FROM dbo.Mo_Human WHERE HumanID = @iID_Nouveau_Beneficiaire AND SocialNumber IS NULL)
					BEGIN
						SELECT					
							@vErrmsg			= ('CONVE0024')
							,@iErrState			= 1
							,@iErrSeverity		= 11
							,@iID_CodeErreur	= -1
							,@iCode_Retour		= -1
						
						RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
					END
				END
				
				-- Ajouter le changement de bénéficiaire dans l'historique
				EXECUTE @iRetour = dbo.psCONV_AjouterChangementBeneficiaire @iID_Convention, @iID_Nouveau_Beneficiaire, @vcCode_Raison, @vcAutre_Raison_Changement_Beneficiaire, @bLien_Frere_Soeur_Avec_Ancien_Beneficiaire, @bLien_Sang_Avec_Souscripteur_Initial, @tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire, @tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire, @iID_Utilisateur_Creation
				
				IF @iRetour < 0
					BEGIN
						SELECT					
							@vErrmsg			= ('Erreur lors de l''appel à psCONV_AjouterChangementBeneficiaire')
							,@iErrState			= 1
							,@iErrSeverity		= 11
							,@iID_CodeErreur	= -1
							,@iCode_Retour		= -1
						
						RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
					END

				-- Si une date de décès est passé en paramètre ET que la raison est 'DEC', alors on mets à jour les informations du défunt.
				IF (@dDateDeces IS NOT NULL) AND (@vcCode_Raison = 'DEC')
					BEGIN
						-- Récupérer l'ancienne date de décès.
						SELECT @dVieilleDateDeces=DeathDate, @vcNomBeneficiaire = LastName, @vcPrenomBeneficiaire=FirstName 
						FROM dbo.mo_human 
						WHERE HumanID = @iID_Beneficiaire_Cedant

				-- Insère un log de l'objet de journalisation.
				SET @cSep = CHAR(30)
	
				INSERT INTO CRQ_Log (
					ConnectID,
					LogTableName,
					LogCodeID,
					LogTime,
					LogActionID,
					LogDesc,
					LogText)
					SELECT
						@iID_Connexion,
						'Un_Beneficiary',
						@iID_Beneficiaire_Cedant,
						GETDATE(),
						LA.LogActionID,
						LogDesc = 'Bénéficiaire : '+@vcNomBeneficiaire+', '+@vcPrenomBeneficiaire,
						LogText = 
									'DeathDate'+@cSep+
									CASE 
										WHEN ISNULL(@dVieilleDateDeces,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), @dVieilleDateDeces, 20)
									END+@cSep+
									CONVERT(CHAR(10), @dDateDeces, 20)
									+@cSep+CHAR(13)+CHAR(10)
						FROM CRQ_LogAction LA 
						WHERE LA.LogActionShortName = 'U'
						
						-- Mise à jour de la date de décès.
						-- Il est à noter que l'on n'utilise pas IMO_Human pour une question de performance.	
						UPDATE	dbo.Mo_Human 
						SET		DeathDate = @dDateDeces 
						WHERE	HumanID = @iID_Beneficiaire_Cedant
	
				END

				-- Récupérer les informations de la convention
				INSERT INTO	@tConvention
				(
					iSubscriberID,iBeneficiaryID,vcConventionNo,iYearQualif,tiMaximisationREEE,dtPmtDate,cPmtTypeID						
					,tiRelationshipTypeID,vcRelationshipType,iPlanID,dtGovernmentRegDate				
					,siScholarshipYear,cScholarshipEntryID,vcPlanDesc,cPlanTypeID,iBankID							
					,vcAccountName,vcTransitNo,vcBankName,vcBankTransit,vcBankTypeCode,vcBankTypeName
					,dtFirstPmtDate,iConventionBreaking,mCapitalINTerestAmount,mGrantINTerestAmount	
					,dtRegEndDateAdjust,dtInforceDateTIN,mAvailableFeeAmount,iCoSubscriberID	
					,vcCoSubscriberName,iNbNSF,dtCESGInForceDate,cConventionStateID,vcConventionStateName
					,dAutoMonthTheoricAmount,iDiplomaTextID,vcDiplomaText,bSendToCESP			
					,mCESG,mACESG,mCLB,bCESGRequested,bACESGRequested,bCLBRequested,tiCESPState			
					,tiSubsCESPState,tiCoSubsCESPState,tiBenefCESPState,mAvailableUnitQty				
					,iDestinationRemboursementID,vcDestinationRemboursementAutre,dtDateduProspectus				
					,bSouscripteurDesireIQEE,tiID_Lien_CoSouscripteur,vcLienCoSouscripteur				
					,bTuteur_Desire_Releve_Elect,iSous_Cat_ID_Resp_Prelevement, bFormulaireRecu	
					,dtRegStartDate, bSouscripteur_Desire_IQEE, IQEE, IQEEMaj, bRISansPreuve
					,dtDateRQ,dtDateFinRegime,dtDateFinRegimeOriginale,dtDateEntreeVigueur
				)	
				EXECUTE dbo.SL_UN_CONVENTION @iID_Convention

				SELECT
					@iID_Subscriber						= t.iSubscriberID
					,@iID_CoSubscriber					= t.iCoSubscriberID 
					,@iID_Plan							= t.iPlanID
					,@vcConventionNo					= t.vcConventionNo
					,@dtPmtDate							= t.dtPmtDate
					,@cID_PmtType						= t.cPmtTypeID
					,@dtGovernmentRegDate				= t.dtGovernmentRegDate
					--,@iID_DiplomaText					= t.iDiplomaTextID		-- 2015-07-29
					,@bSendToCESP						= t.bSendToCESP
					,@bCESGRequested					= t.bCLBRequested
					,@bACESGRequested					= t.bACESGRequested
					,@bCLBRequested						= t.bCLBRequested
					,@tiCESPState						= t.tiCESPState
					,@tiID_RelationshipType				= t.tiRelationshipTypeID
					,@vcDiplomaText						= t.vcDiplomaText
					,@iID_DestinationRemboursement		= t.iDestinationRemboursementID
					,@vcDestinationRemboursementAutre	= t.vcDestinationRemboursementAutre
					,@dtDateduProspectus				= t.dtDateduProspectus
					,@bSouscripteurDesireIQEE			= t.bSouscripteurDesireIQEE
					,@tiLienCoSouscripteur				= t.tiID_Lien_CoSouscripteur
					,@bTuteurDesireReleveElect			= t.bTuteur_Desire_Releve_Elect
					,@iSous_Cat_ID_Resp_Prelevement		= t.iSous_Cat_ID_Resp_Prelevement
					,@bFormulaireRecu					= t.bFormulaireRecu
				FROM
					@tConvention t

				-- Mise à jour de la convention
				EXECUTE @iRetour = dbo.IU_UN_CONVENTION 
													@ConnectID							= @iID_Connexion 
													,@ConventionID						= @iID_Convention
													,@SubscriberID						= @iID_Subscriber
													,@CoSubscriberID					= @iID_CoSubscriber
													,@BeneficiaryID						= @iID_Nouveau_Beneficiaire
													,@PlanID							= @iID_Plan
													,@ConventionNo						= @vcConventionNo
													,@PmtDate							= @dtPmtDate 
													,@PmtTypeID							= @cID_PmtType
													,@GovernmentRegDate					= @dtGovernmentRegDate
													,@DiplomaTextID						= @iID_DiplomaText
													,@bSendToCESP						= @bSendToCESP
													,@bCESGRequested					= @bCESGRequested
													,@bACESGRequested					= @bACESGRequested
													,@bCLBRequested						= @bCLBRequested --0
													,@tiCESPState						= @tiCESPState
													--,@tiRelationshipTypeID			= @tiID_RelationshipType
													,@tiRelationshipTypeID				= @tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire
													,@DiplomaText						= @vcDiplomaText
													,@iDestinationRemboursementID		= @iID_DestinationRemboursement
													,@vcDestinationRemboursementAutre	= @vcDestinationRemboursementAutre
													,@dtDateduProspectus				= @dtDateduProspectus
													,@bSouscripteurDesireIQEE			= @bSouscripteurDesireIQEE
													--,@tiLienCoSouscripteur				= @tiLienCoSouscripteur
													,@tiLienCoSouscripteur				= @tiID_Type_Relation_CoSouscripteur_Nouveau_Beneficiaire
													,@bTuteurDesireReleveElect			= @bTuteurDesireReleveElect
													,@iSous_Cat_ID_Resp_Prelevement		= @iSous_Cat_ID_Resp_Prelevement  
													--,@bFormulaireRecu					= @bFormulaireRecu

				-- Mettre à jour l'état des prévalidations de la convention
				EXEC @iRetour = psCONV_EnregistrerPrevalidationPCEE @iID_Connexion, @iID_Convention, NULL, NULL, NULL

				/*
				-- Gérer le iCESPState de la convention.
				UPDATE dbo.Un_Convention 
				SET tiCESPState = 
						CASE 
							WHEN ISNULL(CS.tiCESPState,1) = 0 
								OR S.tiCESPState = 0 
								OR B.tiCESPState = 0 THEN 0
						ELSE B.tiCESPState
						END
				FROM dbo.Un_Convention 
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = Un_Convention.BeneficiaryID
				JOIN dbo.Un_Subscriber S ON S.SubscriberID = Un_Convention.SubscriberID
				LEFT JOIN dbo.Un_Subscriber CS ON CS.SubscriberID = Un_Convention.CoSubscriberID
				WHERE B.BeneficiaryID = @iID_Nouveau_Beneficiaire
					AND Un_Convention.ConventionId = @iID_Convention
					AND Un_Convention.tiCESPState <> 
								CASE 
									WHEN ISNULL(CS.tiCESPState,1) = 0 
										OR S.tiCESPState = 0 
										OR B.tiCESPState = 0 THEN 0
								ELSE B.tiCESPState
								END
				*/

				-- Crée une chaîne de caractère avec tout les groupes d'unités affectés
				DECLARE UnitIDs CURSOR FOR
					SELECT
						U.UnitID
					FROM dbo.Un_Unit U
					WHERE U.ConventionID = @iID_Convention

				OPEN UnitIDs

				FETCH NEXT FROM UnitIDs
				INTO
					@UnitID

				SET @UnitIDs = ''

				WHILE (@@FETCH_STATUS = 0)
				BEGIN
					SET @UnitIDs = @UnitIDs + CAST(@UnitID AS VARCHAR(30)) + ','
				
					FETCH NEXT FROM UnitIDs
					INTO
						@UnitID
				END

				CLOSE UnitIDs
				DEALLOCATE UnitIDs

				-- Appelle la procédure qui met à jour les états des groupes d'unités et des conventions
				IF @UnitID <> ''
					EXECUTE TT_UN_ConventionAndUnitStateForUnit @UnitIDs 

				-- Vérifier si le nouveau bénéficiaire a déjà un BEC, sinon créer une nouvelle demande.
				DECLARE @iID_ConventionBEC INT
				SET @iID_ConventionBEC = (SELECT dbo.fnCONV_ObtenirConventionBEC (@iID_Nouveau_Beneficiaire, 0, NULL))
				
				-- Si le bénéficiaire n'a pas de convention BEC, alors on en crée une.
				IF @iID_ConventionBEC IS NULL
				BEGIN
					-- Convension suggérée
					SET @iID_ConventionBEC = (SELECT dbo.fnCONV_ObtenirConventionBEC (@iID_Nouveau_Beneficiaire, 1, NULL))
					IF @iID_ConventionBEC > 0 
						AND EXISTS (SELECT 1 FROM dbo.UN_Convention WHERE ConventionID = @iID_ConventionBEC AND tiCESPState IN (2,4))
					BEGIN
						EXECUTE dbo.psPCEE_CreerDemandeBEC @iID_ConventionBEC
					END
				END

				IF @iRetour < 0
					BEGIN
						SELECT					
							@vErrmsg			= ('Erreur lors de l''appel à IU_UN_CONVENTION')
							,@iErrState			= 1
							,@iErrSeverity		= 11
							,@iID_CodeErreur	= -1
							,@iCode_Retour		= -1

						RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
					END
													
				SET @iCode_Retour = 1
				------------------
				COMMIT TRANSACTION
				------------------
		END TRY
		BEGIN CATCH
				
				SELECT					
					@vErrmsg			= REPLACE(ERROR_MESSAGE(),'%',' ')
					,@iErrState			= ERROR_STATE()
					,@iErrSeverity		= ERROR_SEVERITY()
					,@iID_CodeErreur	= ERROR_NUMBER()
					,@iCode_Retour		= -1
						
				--------------------
				ROLLBACK TRANSACTION
				--------------------
						
				RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
		END CATCH

		RETURN @iCode_Retour
	END