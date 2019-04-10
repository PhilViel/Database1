/****************************************************************************************************
Code de service		:		psPCEE_DesactiverBec
Nom du service		:		1.1.1 Désactiver le BEC
But					:		Désactiver le BEC sur une convention
Description			:		Ce service est utilisé afin de désactiver le BEC d'une convention d'un bénéficiaire.
							Aucun remboursement n'est effectué. Le service reçoit en paramètre l'identifiant du 
							bénéficiaire. Par la suite, il y a récupération de la convention dont le BEC est actif
							puis il y a création de la transaction 400-24 qui sera envoyée au PCEE afin de désactiver
							le BEC.

Facette				:		PCEE
Reférence			:		Document P171U - psPCEE_DesactiverBEC.DOCX

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iID_Beneficiaire			Identifiant unique du bénéficiaire			
						@iIdConnect					Identifiant de connexion de l'utilisateur

Exemple d'appel:
					DECLARE @i INT
					EXECUTE @i = dbo.psPCEE_DesactiverBec 556346, 2
					PRINT @i
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       S/O                          @iID_CodeErreur                             = 0		si traitement réussi
																								<> 0	si une erreur est survenue
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-10-23					Jean-François Gauthier					Création de la procédure
						2010-02-05					Jean-François Gauthier					Ajout des champs dtRegStartDate, bSouscripteur_Desire_IQEE, IQEE, IQEEMaj
						2010-02-09					Pierre Paquet							Ajout du code d'erreur PCEEE0009
						2010-05-11					Pierre Paquet							Correction: PCEEE0009.
						2010-08-05					Pierre Paquet							Correction: Utilisation des valeurs de UN_Beneficiary plutôt que mo_human pour le principal responsable.
						2010-08-19					Pierre Paquet							Correction: Remplacement de bCLBRequested par bCESGRequested...erreur!
						2010-11-18					Jean-Francois Arial					Ajout du champ bRISansPreuve lors de l'appel à SL_UN_CONVENTION
						2011-01-31					Frederick Thibault					Ajout du champ fACESGPart pour régler le problème de remboursement SCEE+
						2012-02-22					Eric Michaud							Ajout de dtDateRQ,dtDateFinRegime,dtDateFinRegimeOriginale,dtDateEntreeVigueur pour SL_UN_CONVENTION
						2014-11-13					Pierre-Luc Simard					Ne plus mettre à jour le champs bCLBRequest 
																										Supprimer les demandes en cours
																										Ajout du paramètre pour appeler la procédure pour une convention même si elle ne gère pas le BEC actuellement
																										Ne plus utiliser les procédures SL_Un_Convention et IU_UN_convention
																										Cocher la case BEC refusé si ça provient de l'outil de gestion du BEC

N.B.

Optimisations SQL

CREATE NONCLUSTERED INDEX [_dta_index_Un_CESP400_5_1672549192__K5_K8_K17_K6_K7_K1_2_3] ON [dbo].[Un_CESP400] 
(
	[ConventionID] ASC,
	[tiCESP400TypeID] ASC,
	[bCESPDemand] ASC,
	[iCESP800ID] ASC,
	[iReversedCESP400ID] ASC,
	[iCESP400ID] ASC
)
INCLUDE ( [iCESPSendFileID],
[OperID]) WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF)
go

CREATE STATISTICS [_dta_stat_165015769_3_4] ON [dbo].[Un_Convention]([SubscriberID], [BeneficiaryID])
go

CREATE STATISTICS [_dta_stat_165015769_1_3_4] ON [dbo].[Un_Convention]([ConventionID], [SubscriberID], [BeneficiaryID])
go

CREATE STATISTICS [_dta_stat_165015769_2_4_3] ON [dbo].[Un_Convention]([PlanID], [BeneficiaryID], [SubscriberID])
go

CREATE STATISTICS [_dta_stat_165015769_1_2_4_3] ON [dbo].[Un_Convention]([ConventionID], [PlanID], [BeneficiaryID], [SubscriberID])
go

 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psPCEE_DesactiverBec]
								(
								@iID_Beneficiaire	INT = NULL	-- Utilisé si aucune convention spécifique n'est pas passée en paramètre
								,@iID_Connect		INT
								,@ConventionID INT = NULL		-- Convention spécifique passée en paramètre. Utiliser celle-ci au lieu de celle du bénéficiaire.		 					
								,@RefusBEC BIT = 1					-- cocher la case SCEEFormulaire93BECRefuse pour refuser le BEC (Uniquement lorsque ça provient de l'outil de gestion du BEC) 
								)
AS
	BEGIN
		SET NOCOUNT ON
		SET XACT_ABORT ON		

        DECLARE
            @iErrno INT,
            @iErrSeverity INT,
            @iErrState INT,
            @vErrmsg NVARCHAR(1024),
            @iID_CodeErreur INT,
            @iRetour INT,
            @iID_Convention INT,
            @iID_Oper INT,
            @iID_Cotisation INT,
            @iID_CESP400 INT
   
		BEGIN TRY
			-----------------
			BEGIN TRANSACTION
			-----------------
				SET @iID_CodeErreur = NULL
				
				-- 1. Récupéré la convention à traiter
				IF @ConventionID IS NOT NULL  -- On utilise la convention en paramètre
					SELECT 
						@iID_Convention = @ConventionID
					FROM dbo.Un_Convention C
					WHERE C.ConventionID = @ConventionID
				ELSE
					BEGIN -- Récupérer la convention du bénéficiaire dont le BEC est actif
						SET @iID_Convention = (SELECT dbo.fnCONV_ObtenirConventionBEC(@iID_Beneficiaire, 0, NULL))
	
						IF (@iID_Convention < 0 OR @iID_Convention IS NULL) 
                			BEGIN
								SELECT					
									@vErrmsg		= 'PCEEE0009'
									,@iErrState		= 1
									,@iErrSeverity	= 11
									,@iID_CodeErreur		= -2

								RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
							END
					END
                    
				-- 2. Mettre à jour les cases du BEC dans la convention
				UPDATE dbo.Un_Convention SET 
					bCLBRequested = 0,
					SCEEFormulaire93BECRefuse = CASE WHEN @RefusBEC = 1 THEN 1 ELSE SCEEFormulaire93BECRefuse END
				WHERE ConventionID = @iID_Convention
					AND (ISNULL(bCLBRequested, 0) <> 0
						OR SCEEFormulaire93BECRefuse <> CASE WHEN @RefusBEC = 1 THEN 1 ELSE SCEEFormulaire93BECRefuse END)
				
				-- 3. Récupérer l'opération de la demande de 'BEC' dans l'historique de la convention
				--	  du bénéficiaire et conserver l'identifiant de l'opération.
				--	  Récupérer ensuite, l'identifiant de la cotisation lié l'identifiant de l'opération
				SET @iID_Oper = (	
									SELECT TOP 1 ce.OperID
									FROM dbo.Un_CESP400 ce
									WHERE ce.ConventionID = @iID_Convention
										AND ce.iCESPSendFileID IS NOT NULL
										AND ce.tiCESP400TypeID = 24
										AND ce.bCESPDemand = 1
										AND ce.iCESP800ID	 IS NULL
										AND NOT EXISTS (SELECT 1 FROM dbo.Un_CESP400 u2 WHERE ce.iCESP400ID = u2.iReversedCESP400ID AND u2.iCESP800ID IS NULL)	-- NON RENVERSÉ
									ORDER BY ce.iCESP400ID DESC)

				SET @iID_Cotisation = (	SELECT	c.CotisationID
													FROM Un_Cotisation c
													WHERE	c.OperID = @iID_Oper)

				-- 4. Supprimer les 424 en attente d'être envoyées
				DELETE FROM Un_CESP400
				WHERE ConventionID = @iID_Convention
					AND iCESPSendFileID IS NULL
					AND tiCESP400TypeID = 24
									
				-- 5. Créer une nouvelle transaction 400-24 afin de désactiver le BEC sur la convention
				IF ISNULL(@iID_Cotisation, 0) <> 0 
					BEGIN 
						INSERT INTO dbo.Un_CESP400
						(
							iCESPSendFileID
							,OperID
							,CotisationID
							,ConventionID
							,iCESP800ID
							,iReversedCESP400ID
							,tiCESP400TypeID
							,tiCESP400WithdrawReasonID
							,vcTransID
							,dtTransaction
							,iPlanGovRegNumber
							,ConventionNo
							,vcSubscriberSINorEN
							,vcBeneficiarySIN
							,fCotisation
							,bCESPDemand
							,dtStudyStart
							,tiStudyYearWeek
							,fCESG
							,fACESGPart
							,fEAPCESG
							,fEAP
							,fPSECotisation
							,iOtherPlanGovRegNumber
							,vcOtherConventionNo
							,tiProgramLength
							,cCollegeTypeID
							,vcCollegeCode
							,siProgramYear
							,vcPCGSINorEN
							,vcPCGFirstName
							,vcPCGLastName
							,tiPCGType
							,fCLB
							,fEAPCLB
							,fPG
							,fEAPPG
							,vcPGProv
							,fCotisationGranted
						)
						SELECT
							 NULL
							,@iID_Oper
							,@iID_Cotisation
							,@iID_Convention
							,NULL
							,NULL
							,24
							,NULL
							,'FIN'
							,GETDATE()
							,CAST(p.PlanGovernmentRegNo AS INT)
							,C.ConventionNo
							,h1.SocialNumber
							,h2.SocialNumber
							,0
							,0
							,NULL
							,NULL
							,0
							,0
							,0
							,0
							,0
							,NULL
							,NULL
							,NULL
							,NULL
							,NULL
							,NULL
							--,h3.SocialNumber	
							,b.vcPCGSINorEN
							,b.vcPCGFirstName
							,b.vcPCGLastName
							,b.tiPCGType
							,0
							--,h3.FirstName		,h3.LastName		,b.tiPCGType						,0
							,0
							,0
							,0
							,NULL
							,0
						FROM dbo.Un_Convention c
						INNER JOIN Un_Plan p ON c.PlanID = p.PlanID
						INNER JOIN dbo.Mo_Human h1 ON c.SubscriberID = h1.HumanID
						INNER JOIN dbo.Mo_Human h2 ON c.BeneficiaryID = h2.HumanID
						INNER JOIN dbo.Un_Beneficiary b ON c.BeneficiaryID = b.BeneficiaryID
						INNER JOIN dbo.Mo_Human h3 ON b.iTutorID = h3.HumanID
						WHERE	c.ConventionID = @iID_Convention
				
						SET @iID_CESP400 = SCOPE_IDENTITY()		-- RÉCUPÈRE L'IDENTIFIANT UNIQUE GÉNÉRÉ

						-- 6. Mettre à jour la valeur de vcTransID de l'enregistrement créé
						UPDATE	dbo.Un_CESP400
						SET vcTransID = 'FIN' + CAST(@iID_CESP400 AS VARCHAR(12))
						WHERE	iCESP400ID = @iID_CESP400

				END

				SET @iID_CodeErreur = 0
			------------------
			COMMIT TRANSACTION
			------------------
		END TRY
		BEGIN CATCH
				IF (XACT_STATE()) = -1												-- LA TRANSACTION EST TOUJOURS ACTIVE, ON PEUT FAIRE UN ROLLBACK
					BEGIN
						--------------------
						ROLLBACK TRANSACTION
						--------------------
					END
				
				SELECT																-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
					@vErrmsg		= REPLACE(ERROR_MESSAGE(),'%',' ')
					,@iErrState		= ERROR_STATE()
					,@iErrSeverity	= ERROR_SEVERITY()
					,@iErrno		= ERROR_NUMBER()

				IF @iID_CodeErreur IS NULL			-- IL S'AGIT D'UNE ERREUR TECHNIQUE, ON RETOURNE LE CODE -1
					BEGIN
						SET @iID_CodeErreur = -1
					END

				RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
		END CATCH

		RETURN @iID_CodeErreur
	END


