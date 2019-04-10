

/****************************************************************************************************
Code de service		:		psPCEE_CreerTransfertBEC
Nom du service		:		psPCEE_CreerTransfertBEC
But					:		Effectuer une transfert de BEC d'une convention à une autre
Facette				:		PCEE
Reférence			:		Gestion du BEC

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iID_ConventionOUT    		Identifiant de la convention OUT
						@iID_ConventionTIN			Identifiant de la convention TIN
						@dTransfert					Date du transfert
						@iID_Connect				Identifiant de la connexion
Exemple d'appel:
				 DECLARE @i INT
				 EXECUTE @i = dbo.psPCEE_CreerTransfertBEC	287491, 292242, '2010-01-28', 2
				 SELECT  @i
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       S/O                          @iStatut                                    1  si traitement réussi
																								-1 si traitement non réussi
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2010-01-26					Pierre Paquet							Création de la procédure
						2010-01-28					Jean-François Gauthier					Mise en forme GUI
						2010-02-03					Pierre Paquet							Ajout des ISNULL dans le case d'intérêt à zéro.
						2010-02-03					Pierre Paquet							Ajout de la gestion des TFR.
						2010-04-23					Pierre Paquet							Ajout d'une validation pour le transfert. PCEE0002.
						2010-04-26					Pierre Paquet							Vérifier si les cases sont déjà cochées pour le update.
						2010-05-18					Pierre Paquet							Ajout d'un ISNULL(fCLB, 0).
						2016-04-27					Steeve Picard							Forcer le «OtherConventionNo» en majuscule dans les tables «Un_TIN & Un_OUT»
 ***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psPCEE_CreerTransfertBEC]
	
								(
								@iID_ConventionOUT    			INT -- unité départ
								,@iID_ConventionTIN				INT -- unité arrivé
								,@dTransfert					DATETIME -- Date du transfert
								,@iID_Connect					INT
								)
AS
	BEGIN
		SET NOCOUNT ON		-- ÉLIMINE LE MESSAGE RETOURNANT LE NOMBRE D'ENREGISTREMENT AFFECTÉ 
		SET XACT_ABORT ON	-- REND LA TRANSACTION UNCOMMITABLE EN CAS D'ERREUR CRITIQUE 

		DECLARE @fCLB						FLOAT		-- Montant du BEC à transférer
				,@fCLBInt					FLOAT		-- Montant des intérêts du BEC à transférer
				,@iID_OperOUT				INT			-- Id de l'opération OUT
				,@iID_OperTIN				INT			-- Id de l'opération TIN
				,@iID_OperTFR				INT			-- Id de l'opération TFR
				,@iID_CotisationOUT			INT			-- Id de la cotisation OUT
				,@iID_CotisationTIN			INT			-- Id de la nouvelle cotisation dans le TIN
				,@iID_UniteOUT				INT			-- Id de l'unité OUT contenant le BEC
				,@iID_UniteTIN				INT			-- Id de l'unité TIN pour le BEC
				,@vcConventionNo			VARCHAR(15) -- Numéro de convention
				,@iID_ExternalPlanIDOUT		INT			-- Numéro du plan de la convention OUT
				,@iID_ExternalPlanIDTIN		INT			-- Numéro du plan de la convention TIN
				,@tiID_ReeeTypeOUT			TINYINT		-- 1=Individuel 4=Collectif
				,@tiID_ReeeTypeTIN			TINYINT		-- 1=Individuel 4=Collectif
				,@iStatut					INT			-- Statut d'exécution de la procédure 
				,@iNoErr					INT			-- Numéro de l'erreur 
				,@iSeveriteErr				INT			-- Sévérité de l'erreur
				,@vcMsgErr					NVARCHAR(1024) -- Message d'erreur
				,@iStatutErr				INT			-- Statur de l'erreur
				,@iErrno					INT
				,@iErrSeverity				INT
				,@iErrState					INT
				,@vErrmsg					NVARCHAR(1024)
		
		-------------------------
		BEGIN TRANSACTION
		-------------------------
			BEGIN TRY
				-----------------------------------------------------------------------------------
				-- VALIDATIONS
					-- Validation: iID_ConventionOUT doit avoir un montant de BEC OU être cochée sinon erreur.
				
			-- Si la convention OUT n'a pas la case 'BEC' cochée.
			IF NOT EXISTS (SELECT 1 FROM dbo.UN_Convention c WHERE c.conventionID = @iID_ConventionOUT AND c.bCLBRequested = 1)
				BEGIN
					-- Vérifier s'il y a un montant BEC dans la convention.
					IF 	(SELECT SUM(fCLB) FROM dbo.Un_CESP CE WHERE CE.ConventionID = @iID_ConventionOUT) = 0
						BEGIN
								SELECT																-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
									@vErrmsg		= 'PCEEE002'
									,@iErrState		= 1
									,@iErrSeverity	= 11
									,@iStatut		= -1

								RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
						END
				END

					-- Validation: iID_ConventionTIN doit être 'REE' et tiStateCESG IN (2,4) sinon erreur.
				--TO DO

				-----------------------------------------------------------------------------------
				-- Calcul des sommes à transférer

				-- Calculer le montant BEC reçu.
				SELECT 
					@fCLB = SUM(fCLB)
				FROM 
					dbo.Un_CESP CE
				WHERE 
					CE.ConventionID = @iID_ConventionOUT

				-- Calcul des intérêts du BEC
				SELECT 
					@fCLBInt = SUM(CO.ConventionOperAmount)
				FROM 
					dbo.Un_ConventionOper CO
					INNER JOIN dbo.Un_Oper O 
						ON O.OperID = CO.OperID
				WHERE 
					CO.ConventionID = @iID_ConventionOUT
					AND 
					O.OperDate <= @dTransfert
					AND 
					CO.ConventionOperTypeID = 'IBC'

				-----------------------------------------------------------------------------------
				
				-- UN_OPER
				-- Création de l'opération OUT (un_oper) (type OUT).
				INSERT INTO dbo.Un_Oper 
				(
					ConnectID
					,OperTypeID
					,OperDate
				)
				VALUES
				( 
					@iID_Connect
					,'OUT'
					,@dTransfert
				)
				-- Récupérer la valeur de la nouvelle opération @iID_OperOUT
				SET @iID_OperOUT = SCOPE_IDENTITY()	
								
				-- Création de l'opération TIN (un_oper) (type TIN).  
				INSERT INTO dbo.Un_Oper 
				(
					ConnectID
					,OperTypeID
					,OperDate
				)
				VALUES
				( 
					@iID_Connect
					,'TIN'
					,@dTransfert
				)
				-- Récupérer la valeur de la nouvelle opération @iID_OperTIN
				SET @iID_OperTIN = SCOPE_IDENTITY( )

				-- Création de l'opération TFR (un_oper).  
				INSERT INTO dbo.Un_Oper 
				(
					ConnectID
					,OperTypeID
					,OperDate
				)
				VALUES
				( 
					@iID_Connect
					,'TFR'
					,@dTransfert
				)
				-- Récupérer la valeur de la nouvelle opération @iID_OperTIN
				SET @iID_OperTFR = SCOPE_IDENTITY( )

				-----------------------------------------------------------------------------------
				-- UN_ConventionOper (Intérêts)
				-- Créer un ConventionOperTypeID 'IBC' avec un montant négatif sur le OUT.
				INSERT INTO dbo.Un_ConventionOper 
				(
					ConventionID
					,OperID
					,ConventionOperTypeID
					,ConventionOperAmount
				)
				VALUES 
				( 
					@iID_ConventionOUT
					,@iID_OperOUT
					,'IBC'
					,ISNULL(-@fCLBInt, 0)
				)

				-- Créer un ConventionOperTypeID 'BEC' avec un montant positif sur le IN.
				INSERT INTO dbo.Un_ConventionOper 
				(
					ConventionID
					,OperID
					,ConventionOperTypeID
					,ConventionOperAmount
				)
				VALUES 
				( 
					@iID_ConventionTIN
					,@iID_OperTIN
					,'IST'
					,ISNULL(@fCLBInt,0)
				)

				-----------------------------------------------------------------------------------
				-- UN_Cotisation
				-- Obtenir l'unité pour la convention TIN.
				SELECT 
					@iID_UniteTIN = Min(UnitID) 
				FROM 
					dbo.UN_Unit U 
					INNER JOIN dbo.Un_Convention C 
						ON C.ConventionID = U.ConventionID
				WHERE 
					C.ConventionID = @iID_ConventionTIN
					
				-- Création d'une nouvelle cotisation à zéro pour le TIN.
				INSERT INTO dbo.Un_Cotisation 
				(
					UnitID
					,OperID
					,EffectDate
					,Cotisation
					,Fee
					,BenefInsur
					,SubscInsur
					,TaxOnInsur
				)
				VALUES
				( 
					@iID_UniteTIN
					,@iID_OperTIN
					,@dTransfert
					,0
					,0
					,0
					,0
					,0
				)

				-- Obtenir l'unité pour la convention OUT.
				SELECT 
					@iID_UniteOUT = Min(UnitID) 
				FROM 
					dbo.UN_Unit U 
					INNER JOIN dbo.Un_Convention C 
						ON C.ConventionID = U.ConventionID
				WHERE 
					C.ConventionID = @iID_ConventionOUT

				-- Création d'une nouvelle cotisation à zéro pour le OUT.
				INSERT INTO dbo.Un_Cotisation 
				(
					UnitID
					,OperID
					,EffectDate
					,Cotisation
					,Fee
					,BenefInsur
					,SubscInsur
					,TaxOnInsur
				)
				VALUES
				( 
					@iID_UniteOUT	-- Le MAX(UnitID) de la convention (iID_ConventionTIN)
					,@iID_OperOUT	-- La nouvelle opération 'OUT' créée
					,@dTransfert
					,0
					,0
					,0 
					,0 
					,0 
				)

				-- Récupérer la valeur de la nouvelle de CotisationID
				SET @iID_CotisationOUT = SCOPE_IDENTITY()
				-----------------------------------------------------------------------------------

				-- Mise à jour de UN_CESP afin de réduire à zéro le montant BEC de UniteOUT.
				--Création d'un enregistrement de subvention CESP pour le OUT	
				INSERT INTO dbo.Un_CESP 
				(						
					ConventionID
					,OperID
					,CotisationID
					,fCESG
					,fACESG
					,fCLB
					,fCLBFee
					,fPG
					,fCotisationGranted
					,OperSourceID
				)
				VALUES
				( 						
					@iID_ConventionOUT
					,@iID_OperOUT
					,@iID_CotisationOUT
					,0
					,0
					,ISNULL(-@fCLB,0)
					,0
					,0
					,0	
					,@iID_OperOUT
				)

				-- Mise à jour de UN_CESP afin d'inscrire le montant BEC dans UniteIN.
				INSERT INTO dbo.Un_CESP 
				(						
					ConventionID
					,OperID
					,CotisationID
					,fCESG
					,fACESG
					,fCLB
					,fCLBFee
					,fPG
					,fCotisationGranted
					,OperSourceID
				)
				VALUES 
				( 						
					@iID_ConventionTIN
					,@iID_OperTIN
					,@iID_CotisationTIN
					,0
					,0
					,ISNULL(@fCLB, 0)
					,0
					,0
					,0	
					,@iID_OperTIN
				)
						
				-----------------------------------------------------------------------------------
				-- UN_OUT
				-- UN_TIN
				-- UN_TIO
				-- UN_TFR

				-- Récupérer le numéro de la convention IN
				SELECT 
					@vcConventionNo=ConventionNo 
				FROM 
					dbo.UN_Convention 
				WHERE 
					ConventionID = @iID_ConventionTIN
				
				-- Récupérer le PlanGovernmentRegNo pour la convention TIN  
				SELECT 
					@iID_ExternalPlanIDTIN=ExternalPlanId 
				FROM 
					dbo.UN_Convention C
					INNER JOIN dbo.UN_Plan P
						ON C.PlanID=P.PlanID
					INNER JOIN dbo.UN_ExternalPlan E
						ON P.PlanGovernmentRegNo = E.ExternalPlanGovernmentRegNo
				WHERE 
					C.ConventionID =  @iID_ConventionTIN

				-- Récupérer le type de REEE de la convention OUT
				SELECT 
					@tiID_ReeeTypeOUT = CASE PlanTypeID
											WHEN 'IND' THEN 1
											WHEN 'COL' THEN 4 
										END
						FROM dbo.Un_Convention C LEFT JOIN UN_Plan P ON C.PlanID=P.PlanID WHERE ConventionID = @iID_ConventionOUT

				-- Création de l'opération OUT (un_oper) liée à la cotisation BEC.
				INSERT INTO dbo.Un_OUT 
				(
					OperID
					,ExternalPlanID
					,tiBnfRelationWithOtherConvBnf
					,vcOtherConventionNo
					,tiREEEType
					,bEligibleForCESG
					,bEligibleForCLB
					,bOtherContratBnfAreBrothers
					,fYearBnfCot
					,fBnfCot
					,fNoCESGCotBefore98
					,fNoCESGCot98AndAfter
					,fCESGCot
					,fCESG
					,fCLB
					,fAIP
					,fMarketValue
				)
				VALUES
				( 
					@iID_OperOUT
					,@iID_ExternalPlanIDTIN
					,1
					,Upper(@vcConventionNo)
					,@tiID_ReeeTypeOUT
					,1
					,1
					,1
					,0
					,0
					,0
					,0
					,0
					,0
					,ISNULL(@fCLB, 0)
					,ISNULL(-@fCLBInt,0) -- Montant intérêt du BEC
					,ISNULL(-(@fCLB+@fCLBInt), 0) -- Montant BEC + intérêt (négatif)
				)
						
				-- Récupérer le numéro de la convention IN
				SELECT 
					@vcConventionNo=ConventionNo 
				FROM 
					dbo.UN_Convention 
				WHERE 
					ConventionID = @iID_ConventionOUT

				-- Récupérer le PlanGovernmentRegNo pour la convention OUT  
				SELECT 
					@iID_ExternalPlanIDOUT=ExternalPlanId 
				FROM 
					dbo.UN_ExternalPlan E, UN_Convention C, UN_Plan P
				WHERE 
					C.PlanID=P.PlanID
					AND 
					P.PlanGovernmentRegNo = E.ExternalPlanGovernmentRegNo
					AND 
					C.ConventionID =  @iID_ConventionOUT

				-- Récupérer le type de REEE de la convention TIN
				SELECT 
					@tiID_ReeeTypeTIN=	CASE PlanTypeID
											WHEN 'IND' THEN 1
											WHEN 'COL' THEN 4 
										END
				FROM 
					dbo.UN_Convention C 
					LEFT OUTER JOIN dbo.UN_Plan P 
						ON C.PlanID=P.PlanID 
				WHERE 
					ConventionID = @iID_ConventionTIN

				-- Création de l'opération TIN (un_oper) liée à la cotisation créée précédemment.
				INSERT INTO dbo.Un_TIN 
				(
					OperID
					,ExternalPlanID
					,tiBnfRelationWithOtherConvBnf
					,vcOtherConventionNo
					,dtOtherConvention
					,tiOtherConvBnfRelation
					,bAIP
					,bACESGPaid
					,bBECInclud
					,bPGInclud		
					,fYearBnfCot
					,fBnfCot
					,fNoCESGCotBefore98
					,fNoCESGCot98AndAfter
					,fCESGCot
					,fCESG		
					,fCLB
					,fAIP
					,fMarketValue
					,bPendingApplication
				)
				VALUES
				( 
					@iID_OperTIN,
					@iID_ExternalPlanIDOUT,
					1,							-- Même bénéficiaire
					Upper(@vcConventionNo),
					getdate(),					--dtOtherConvention  A REVOIR!
					1,							--tiOtherConvBnfRelation
					0,							--bAIP,
					0,							--bACESGPaid,
					1,							--bBECInclud,
					0,							--bPGInclud,
					0,							--fYearBnfCot,
					0,							--fBnfCot,
					0,							--fNoCESGCotBefore98,
					0,							--fNoCESGCot98AndAfter,
					0,							--fCESGCot,
					0,							--fCESG,
					ISNULL(@fCLB,0),
					ISNULL(@fCLBInt, 0),					--Montant d'intérêt du BEC,
					ISNULL(@fCLB+@fCLBInt,0),				--Montant BEC + Intérêt (positif),
					0							--bPendingApplication
				)

				-- Insère les nouvelles transactions d'opération TIO
				INSERT INTO dbo.Un_TFR 
				(
					OperID 
					,bSendToPCEE
				)
				VALUES 
				(
					@iID_OperTFR
					,0			
				)

				-- Insère les nouvelles transactions d'opération TIO
				INSERT INTO dbo.Un_TIO 
				(
					iOUTOperID 
					,iTINOperID
					,iTFROperID
				)
				VALUES 
				(
					@iID_OperOUT
					,@iID_OperTIN
					,@iID_OperTFR
				)

				-----------------------------------------------------------------------------------
				-- Mise à jour de la case 'BEC' (coche le TIN)
				IF NOT EXISTS (SELECT 1 FROM dbo.UN_Convention WHERE ConventionID = @iID_ConventionTIN AND bCLBRequested = 1)
				BEGIN
					UPDATE	dbo.Un_Convention 
					SET		bCLBRequested = 1 
					WHERE	ConventionID = @iID_ConventionTIN

					-- Création d'une nouvelle 400-24 (Demande de BEC) pour la convention TIN
					EXECUTE dbo.TT_UN_CLB @iID_ConventionTIN
				END

				-- Mise à jour de la case 'BEC' (décoche le OUT)
				IF NOT EXISTS (SELECT 1 FROM dbo.UN_Convention WHERE ConventionID = @iID_ConventionOUT AND bCLBRequested = 0)			
				BEGIN
					UPDATE	dbo.Un_Convention 
					SET		bCLBRequested = 0 
					WHERE ConventionID = @iID_ConventionOUT
				END
				
				-----------------------------------------------------------------------------------
				-- Création des transaction 19 et 23 (un_cesp400)
				-- Insère les enregistrements 400 de type 23 sur l'opération OUT	
				EXECUTE dbo.IU_UN_CESP400ForOper @iID_Connect, @iID_OperOUT, 23, 0

				-- Insère les enregistrements 400 de type 19 sur l'opération TIN
				EXECUTE dbo.IU_UN_CESP400ForOper @iID_Connect, @iID_OperTIN, 19, 0

				-----------------------------------------------------------------------------------

				SET @iStatut = 1
				-----------------------
				COMMIT TRANSACTION
				-----------------------
		END TRY

/*
		BEGIN CATCH
			SELECT -- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR 
				@vcMsgErr		= REPLACE(ERROR_MESSAGE(),'%',' ')
				,@iSeveriteErr	= ERROR_SEVERITY() 
				,@iNoErr			= ERROR_NUMBER()
				,@iStatutErr		= ERROR_STATE()
				,@iStatut		= -1

			IF (XACT_STATE()) = -1 -- LA TRANSACTION EST TOUJOURS ACTIVE, ON PEUT FAIRE UN ROLLBACK 
				BEGIN 
					-----------------------
					ROLLBACK TRANSACTION
					-----------------------
					/*
					IF @iNoErr >= 50000 -- RETOURNE L'ERREUR UTILISATEUR SELON P171 (TOUT CE QUI EST SUPÉRIEUR À 50000 CONSTITUE UN MESSAGE PERSONNALISÉ) 
						BEGIN 
							RAISERROR 50001 'PCEE0030 Erreur lors du transfert BEC' 
						END 
					ELSE				-- RETOURNE L'ERREUR SYSTÈME 
						BEGIN  */
					SET @vcMsgErr = CAST(@iNoErr AS VARCHAR(6)) + ' : ' + @vcMsgErr -- CONCATÉNATION DU NUMÉRO D'ERREUR INTERNE À SQL SERVEUR 
					RAISERROR (@vcMsgErr, @iSeveriteErr, @iStatutErr ) 
					/*	END */
				END 
			ELSE 
				BEGIN 
					SET @vcMsgErr = 'AUCUNE TRANSACTION ACTIVE POUR LA SESSION : ' + CAST ( @iNoErr AS VARCHAR ( 6 )) + @vcMsgErr 
					RAISERROR 50001 @vcMsgErr 
				END 
		END CATCH
*/
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

				IF @iStatut IS NULL			-- IL S'AGIT D'UNE ERREUR TECHNIQUE, ON RETOURNE LE CODE -1
					BEGIN
						SET @iStatut = -1
					END

				RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
		END CATCH

		RETURN @iStatut
	END


