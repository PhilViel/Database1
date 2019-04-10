/****************************************************************************************************
Code de service		:		psPCEE_CreerDemandeBec
Nom du service		:		
But					:		Créer une nouvelle demande de BEC pour un bénéficiare sur la convention passée en paramètre
Description			:		Ce service crée une nouvelle demande de BEC pour un bénéficiare. Les enregistrements de type 'opération' et 'cotisation'
							sont créés uniquement si le bénéficiaire n'a jamais fait de demande de BEC. Lors d'une mise à jour du principal responsable,
							l'enregistrement 400-24 de le nouvelle demande sera relié à l'opération BEC déjà existante. Une demande de BEC non-envoyée
							est automatiquement supprimée avant la création de la nouvelle demande. Ce service est utilisé dans l'outil de gestion du
							BEC et lors d'un changement au niveau du principal responsable.

Facette				:		PCEE
Reférence			:		Document P171U - 1.1.1 Créer une nouvelle demande de BEC

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						iID_Convention				Identifiant unique de la convention

Exemple d'appel:
					DECLARE @i INT
					EXECUTE @i = dbo.psPCEE_CreerDemandeBec 176111		-- avec BEC cochée (BeneficiaryID = 530363)
					PRINT @i

					DECLARE @i INT
					EXECUTE @i = dbo.psPCEE_CreerDemandeBec 99324		-- avec BEC non cochée
					PRINT @i

					DECLARE @i INT
					EXECUTE @i = dbo.psPCEE_CreerDemandeBec 231706		-- avec BEC non cochée
					PRINT @i		
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       S/O                          @iStatut                                    = 0		si traitement réussi
																								< 0		si une erreur est survenue
                    
Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2009-10-08					Jean-François Gauthier					Création de la procédure
		2009-10-15					Jean-François Gauthier					Correction au niveau de la définition d'un convention ACTIVE
		2009-11-12					Jean-François Gauthier					Éliminination de la section concernant la création des 
																			enregistrements 511
		2009-12-03					Jean-François Gauthier					Ajout de la mise à jour du champ bCLBRequested 
																			et appel de TT_UN_CESPOfConvention	
		2009-12-11					Jean-François Gauthier					Correction d'une double négation lors de la validation 2
		2009-12-15					Jean-François Gauthier					Correction pour la validation 1
		2010-01-12					Jean-François Gauthier					Ajout de l'appel à la procédure TT_UN_CLB
		2010-01-13					Jean-François Gauthier					Remplacement de l'appel à fnPCEE_ValiderPresenceBEC par fnCONV_ObtenirEtatBEC
		2010-01-14					Pierre Paquet							Ajustement au niveau de la vérificaiton de la case à cocher.
		2010-01-21					Pierre Paquet							Ajout des codes d'erreurs pour les messages.
																			et utilisation des sp SL_UN_Convention et IU_UN_Convention
		2010-02-04					Jean-François Gauthier					Ajout des champs dtRegStartDate, bSouscripteur_Desire_IQEE, IQEE, IQEEMaj
 		2010-02-04					Pierre Paquet							Suppression du SET = @Errmsg
 		2010-04-21					Jean-François Gauthier					Remplacement de l'appel à IU_UN_Convention qui vient interféré avec le
 																			traitement de TT_UN_CLB subséquent
		2010-04-21					Pierre Paquet							Ajout de la validation PCEEE013
		2010-05-03					Pierre Paquet							Ajout de la vérification de l'état du BEC.
		2010-05-05					Pierre Paquet							Ajout de la gestion 'erreur corrected' 800.
		2010-05-06					Pierre Paquet							Correction: Rollback de 800 dans un_cesp800ToTreat.
		2010-08-16					Pierre Paquet							Correction: il manquait le M avec CONVM006
		2010-09-17					Pierre Paquet							Correction: Vérifier si le 800 est déjà corrigé. FK erreur.
		2010-11-18					Jean-Francois Arial						Ajout du champ bRISansPreuve lors de l'appel à SL_UN_CONVENTION
		2012-02-22					Eric Michaud							Ajout de dtDateRQ,dtDateFinRegime,dtDateFinRegimeOriginale,dtDateEntreeVigueur pour SL_UN_CONVENTION
		2013-06-18					Donald Huppé							Sur la validation "PCEEE005", ajout du critère pour rechercher dans les convention REE
		2014-11-07					Pierre-Luc Simard						Ne plus enregistrer la valeur du champs bCLBRequested, qui est maintenant géré par la procédure psCONV_EnregistrerPrevalidationPCEE
		2015-07-29					Steeve Picard							Utilisation du "Un_Convention.TexteDiplome" au lieu de la table UN_DiplomaText
        2017-06-19                  Steeve Picard                           Ajout du champ tiMaximisationREEE dans la procédure « dbo.SL_UN_Convention » qui est appelée
        2017-09-12                  Steeve Picard                           Gestion des transactions
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psPCEE_CreerDemandeBec]
(
	@iID_Convention INT									
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON		

	-----------------
    DECLARE @TranCount INT = @@TRANCOUNT
    IF @TranCount = 0 
	    BEGIN TRANSACTION
	-----------------

	DECLARE	@iStatut							INT
	        ,@iIDBeneficiaire					INT 
	        ,@dtMaxDatePCEEFichier				DATETIME
	        ,@iIdentite							INT
	        ,@iIDSouscripteur					INT
	        ,@iIDConnect						INT
	        ,@iErrno							INT
	        ,@iErrSeverity						INT = 11
	        ,@iErrState							INT = 1
	        ,@vErrmsg							NVARCHAR(1024)
	        ,@iID_CodeErreur					INT
	        ,@iRetour							INT
	        ,@iID_CESPSendFile					INT
	        ,@tiID_CESP400Type					INT
	        ,@bCESPDemande						BIT
	        ,@mCLB								MONEY
	        ,@mCESG								MONEY
	        ,@iID_Oper							INT
	        ,@iID_Cotisation					INT
	        ,@iID_Subscriber					INT
	        ,@iID_CoSubscriber					INT
	        ,@iID_Beneficiary					INT
	        ,@iID_Plan							INT
	        ,@vcConventionNo					VARCHAR(15)
	        ,@dtPmtDate							DATETIME
	        ,@cID_PmtType						CHAR(3)
	        ,@dtGovernmentRegDate				DATETIME
	        ,@iID_DiplomaText					INT	
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
	        ,@iID_Oper1923						INT
	        ,@vcID_Oper							VARCHAR(25)
	        ,@bFormulaireRecu					BIT
	        ,@vcEtatBEC							VARCHAR(30)


	-- Création de la table temporaire nécessaire à l'utilisation de SL_UN_Convention
	DECLARE @tConvention TABLE (
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

		SET @iStatut = 0
		
		-- Recherche du ConnectID système
		SELECT
			@iIDConnect = iID_Utilisateur_Systeme
		FROM
			dbo.Un_Def


		-- Récupération des informations de la convention avec SL_UN_Convention
		INSERT INTO	@tConvention (
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
			,dtRegStartDate, bSouscripteur_Desire_IQEE
			,IQEE, IQEEMaj, bRISansPreuve
			,dtDateRQ,dtDateFinRegime,dtDateFinRegimeOriginale,dtDateEntreeVigueur
		)
		EXECUTE dbo.SL_UN_CONVENTION @iID_Convention

		SELECT
			@iIDSouscripteur					= t.iSubscriberID
			,@iID_CoSubscriber					= t.iCoSubscriberID 
			,@iIDBeneficiaire					= t.iBeneficiaryID
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

		-- VALIDATION:
		-- On s'assure qu'aucune autre convention n'a la case 'BEC' cochée car c'est ce service qui va la cocher. 
		-- On exclus la convention passé en paramètre car il est possible que l'on veule simplement recréer une nouvelle 400-24.
		
        BEGIN TRY
        	
			SET @vcEtatBEC = (dbo.fnCONV_ObtenirEtatBEC(@iIDBeneficiaire))
			
			IF EXISTS(SELECT 1 
						FROM	dbo.Un_Convention c	
						join (
							select 
								Cs.conventionid ,
								ccs.startdate,
								cs.ConventionStateID
							from 
								un_conventionconventionstate cs
								join (
									select 
									conventionid,
									startdate = max(startDate)
									from un_conventionconventionstate
									group by conventionid
									) ccs on ccs.conventionid = cs.conventionid 
										and ccs.startdate = cs.startdate 
										and cs.ConventionStateID in ('REE')
							) css on C.conventionid = css.conventionid
						WHERE c.BeneficiaryID = @iIDBeneficiaire AND c.bCLBRequested = 1 
					AND c.ConventionID <> @iID_Convention
					AND @vcEtatBEC <> 'CONVM002' AND @vcEtatBEC <> 'CONVM004' AND @vcEtatBEC <> 'CONVM006')
				BEGIN
					SELECT																-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
						@vErrmsg		= 'PCEEE005'
						,@iStatut		= -1
				END

			-- VALIDATION:
			-- 2. VÉRIFIER LES PRÉVALIDATIONS SUR LA CONVENTION.
            -- Il faut s'assurer que le tiCESPState de la convention soit 2 ou 4. (BEC passe)
			IF @iStatut >= 0 AND NOT EXISTS (SELECT 1 FROM dbo.Un_Convention c WHERE c.ConventionID = @iID_Convention AND c.tiCESPState IN (2,4))
				BEGIN
					SELECT																-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
						@vErrmsg		= 'PCEEE006'
						,@iStatut		= -2
				END

			-- VALIDATION: La convention ne doit pas être résiliée.
			IF @iStatut >= 0 AND dbo.fnCONV_ObtenirStatutConventionEnDate(@iID_Convention,GETDATE()) = 'FRM'
				BEGIN
					SELECT																-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
						@vErrmsg		= 'PCEEE0013'
						,@iStatut		= -3
				END

	
			-- Si l'état est 'Erreur technique'.
			IF @iStatut >= 0 AND @vcEtatBEC = 'CONVM004'
			BEGIN
				DECLARE @iCESP800IDErreur INT
				
				-- Récupérer l'enregistrement 400-24 en erreur
				SELECT TOP 1 @iCESP800IDErreur=C4.iCESP800ID
				FROM dbo.UN_CESP400 C4			
					LEFT JOIN dbo.UN_Convention C on C4.ConventionID = C.ConventionID
					LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID
				WHERE C4.tiCESP400TypeID = 24
				AND C4.bCESPDemand = 1
				AND C4.iCESP800ID IS NOT NULL -- En erreur!
				AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
				AND R4.iCESP400ID IS NULL -- Pas annulé
				AND C.BeneficiaryID = @iIDBeneficiaire
				ORDER BY C4.iCESP400ID DESC
			
				-- Ajouter l'enregistrement à la table des UN_CESP800Corrected
				IF NOT EXISTS (SELECT 1 FROM dbo.UN_CESP800Corrected WHERE iCESP800ID = @iCESP800IDErreur)
				BEGIN
					INSERT INTO dbo.UN_CESP800Corrected (iCESP800ID, iCorrectedConnectID, dtCorrected, bCESP400ReSend)
						VALUES (@iCESP800IDErreur, @iIDConnect, getdate(), 1)
				END
				-- On retire la transaction 
				DELETE FROM dbo.UN_CESP800ToTreat WHERE iCESP800ID = @iCESP800IDErreur
			END

            IF @iStatut >= 0
            BEGIN
			    -- Mettre à jour l'état des prévalidations du bénéficiaire
    		    EXEC @iRetour = psCONV_EnregistrerPrevalidationPCEE @iIDConnect, NULL, @iIDBeneficiaire, NULL, NULL

			    /*
			    -- 2010-04-21 : JFG : Mise à jour direct au lieu de faire appel à IU_UN_Convention
			    UPDATE	dbo.Un_Convention
			    SET		bCLBRequested		= 1
			    WHERE	ConventionID		= @iID_Convention

			    -- Remise à zéro des autres bcLBREquested des autres conventions du Beneficiaire.
			    UPDATE	dbo.Un_Convention
			    SET		bCLBRequested		= 0
			    WHERE	BeneficiaryID		= @iIDBeneficiaire
			    AND     ConventionID		<> @iID_Convention
			    */

			
		
			    -- 2010-01-12 : Appel de TT_UN_CLB de façon unitaire afin de créer les enregistrements 400.
			    IF @iRetour >= 0
				    EXECUTE @iRetour = TT_UN_CLB @iID_Convention

			    IF @iRetour < 0		-- Une erreur s'est produite avec TT_UN_CLB
				    BEGIN
					    SELECT																-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
							    @vErrmsg		= 'PCEEE007'
							    ,@iStatut		= -5
				    END
			    ELSE
				    BEGIN
					    SET @iStatut = @iRetour
				    END
            END
		END TRY
		BEGIN CATCH
			SELECT																-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
				@vErrmsg		= REPLACE(ERROR_MESSAGE(),'%',' ')
				,@iErrState		= ERROR_STATE()
				,@iErrSeverity	= ERROR_SEVERITY()
				,@iErrno		= ERROR_NUMBER()

				IF @iStatut IS NULL			-- IL S'AGIT D'UNE ERREUR TECHNIQUE, ON RETOURNE LE CODE -1
					BEGIN
						SET @iStatut = -1
					END
		END CATCH
				
        IF @iStatut > 0
        BEGIN
			------------------
            IF @TranCount = 0 
                COMMIT TRANSACTION
			------------------
    		PRINT 'Successful'
        END
        ELSE
        BEGIN
			--------------------
            IF @TranCount = 0
			    ROLLBACK TRANSACTION
			--------------------

			RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
        END

        RETURN @iStatut
	END