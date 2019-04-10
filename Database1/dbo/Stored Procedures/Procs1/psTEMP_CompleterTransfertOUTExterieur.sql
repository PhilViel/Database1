/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEMP_CompleterTransfertOUTExterieur
Nom du service		: Compléter un transfert OUT vers l'extérieur d'Universitas
But 				: Mesure temporaire pour vider les comptes d'IQÉÉ lors d'un transfert OUT total vers un autre
					  promoteur
Facette				: IQÉÉ

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-01-07		Éric Deshaies						Création du service à partir de 
															"psTEMP_AjouterTransactionManuelleIQEEPourOUT.sql"
		2010-07-29		Éric Deshaies						Permettre de créer une opération OUT juste
															pour un montant d'IQÉÉ comme quand par exemple
															un formulaire de transfert d'IQÉÉ est reçus
															après un premier transfert OUT.  Le chèque
															doit quand même être fait manuellement.
															Il doit y avoir un transfert OUT avec un
															autre promoteur dans la convention.
		2010-09-30		Éric Deshaies						Correction pour empêcher la création inutile
															de l'opération en cas d'une perte dans un compte.
		2010-10-04		Steve Gouin							Gestion des disable trigger par #DisableTrigger
		2016-04-27		Steeve Picard						Forcer le «OtherConventionNo» en majuscule dans les tables «Un_TIN & Un_OUT»
		2017-08-15		Donald Huppé						Vérifier la présence d'un OUT existant dans UN_CESP, au lieu de seulement dans Un_ConventionOper
															Car si le OUT ne contient pas de rendement (dans Un_ConventionOper), alors on ne trouve pas l'opératon OUT,
															car elle est seulement dans UN_CESP
*********************************************************************************************************************/
CREATE PROCEDURE dbo.psTEMP_CompleterTransfertOUTExterieur
(
	@vConventionNo VARCHAR(15),
	@bActiveDebug BIT = 0
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE
		@iErrno				INT
		,@iErrSeverity		INT
		,@iErrState			INT
		,@vErrmsg			VARCHAR(1024)
		,@iCode_Retour		INT

	DECLARE
		@IidTransacManuelleIQEE			INT
		,@dtDateTransfert				datetime
		,@ConventionID					INT
		,@iConnectId					INT
		,@vOUTExistant					varchar(3)
		,@mDiffRendIQEETrsfRecu			money
		,@iID_OPER						INT,
		@iID_OPERDate					datetime,
		@mSolde_Credit_Base MONEY,
		@mSolde_Majoration MONEY,
		@mSolde_Interets_RQ MONEY,
		@mSolde_Interets_IQI MONEY,
		@mSolde_Interets_ICQ MONEY,
		@mSolde_Interets_IMQ MONEY,
		@mSolde_Interets_IIQ MONEY,
		@mSolde_Interets_III MONEY
		,@ExternalPlanID				int
		,@tiBnfRelationWithOtherConvBnf tinyint
		,@vcOtherConventionNo			varchar(15)
		,@dtOtherConvention				datetime
		,@tiOtherConvBnfRelation		tinyint
		,@bAIP							bit
		,@bACESGPaid					bit
		,@bBECInclud					bit
		,@bPGInclud						bit
		,@fYearBnfCot					money
		,@fBnfCot						money
		,@fNoCESGCotBefore98			money
		,@fNoCESGCot98AndAfter			money
		,@fCESGCot						money
		,@fCESG							money
		,@fCLB							money
		,@fAIP							money
		,@fMarketValue					money
		,@tiREEEType					TINYINT
		,@bEligibleForCESG				BIT
		,@bEligibleForCLB				BIT
		,@bOtherContratBnfAreBrothers	BIT
		,@vOUTCreer						VARCHAR(3)
		,@vcGestionPerte				VARCHAR(20)

	DECLARE @tblResultatDebug			TABLE(
											vNoConvention			VARCHAR(15)			
											,vIdConvention			INT
											,vIdTransac				INT
											,vOUTExistant			varchar(3)
											,vOUTCreer				varchar(3)
											,vcGestionPerte			VARCHAR(20)
											,vOperId				INT
											,mSolde_Credit_Base		MONEY
											,mSolde_Majoration		MONEY
											,mSolde_Interets_RQ		MONEY
											,mSolde_Interets_IQI		MONEY
											,mSolde_Interets_ICQ		MONEY
											,mSolde_Interets_IMQ		MONEY
											,mSolde_Interets_IIQ		MONEY
											,mSolde_Interets_III		MONEY
											)

	/* Obtenir les transactions manuelle dans la table temporaire pour les transferts OUT */
	DECLARE curTransacManuIQEE CURSOR LOCAL FAST_FORWARD
	FOR
		SELECT 
			tmi.IidTransacManuelleIQEE
			,tmi.vConventionNo
			,tmi.dtDateTransfert
			,c.ConventionID
		FROM 
			tblTEMP_TransacManuelleIQEE tmi
			INNER JOIN dbo.Un_Convention c ON c.ConventionNo = tmi.vConventionNo
		WHERE tmi.vcTypeTransfert = 'OUT'
			AND tmi.cTraiter = 'N'
			AND c.ConventionNo = ISNULL(@vConventionNo, c.ConventionNo)
			AND dtDateTransfert >= '2010-01-01'
			
	-- ARRÊT DU TRIGGER
	--ALTER TABLE dbo.Un_ConventionOper	DISABLE TRIGGER TUn_ConventionOper
	--ALTER TABLE dbo.Un_Oper				DISABLE TRIGGER TUn_Oper
	--ALTER TABLE dbo.Un_Oper				DISABLE TRIGGER TUn_Oper_dtFirstDeposit

	IF object_id('tempdb..#DisableTrigger') is null
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

	INSERT INTO #DisableTrigger VALUES('TUn_ConventionOper')				
	INSERT INTO #DisableTrigger VALUES('TUn_Oper')				
	INSERT INTO #DisableTrigger VALUES('TUn_Oper_dtFirstDeposit')				

BEGIN TRY
	-----------------
	BEGIN TRANSACTION
	-----------------
	
	OPEN curTransacManuIQEE
	FETCH NEXT FROM curTransacManuIQEE INTO
		@IidTransacManuelleIQEE	
		,@vConventionNo	
		,@dtDateTransfert
		,@ConventionID

	WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @iID_OPER = NULL

			/* Obtenir l'identifant d'opération correspondant au transfert OUT pour la convention et la date de transfert */

			--@iID_OPER = O.OperId

			SELECT @iID_OPER = MAX(V.OperId)
			FROM (
				-- OperID de rendement
				SELECT 
					O.OperId
				FROM
					Un_Convention C	 	  
					JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID 		
					JOIN Un_Oper O ON O.OperID = CO.OperID	 
					LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
					LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
				WHERE O.OperTypeID = 'OUT'
					AND O.OperDate = @dtDateTransfert
					AND C.ConventionNO = @vConventionNo
					AND OC1.OperSourceID IS NULL
					AND OC2.OperSourceID IS NULL

				UNION ALL

				-- OperID de SCEE
				SELECT
					CE.OperID
				FROM	
					Un_CESP CE
					JOIN Un_Convention C ON C.ConventionID = CE.ConventionID
					JOIN UN_OPER O ON O.OperID = CE.OperID
					LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
					LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
				WHERE O.OperTypeID = 'OUT'
					AND O.OperDate = @dtDateTransfert
					AND C.ConventionNO = @vConventionNo
					AND OC1.OperSourceID IS NULL
					AND OC2.OperSourceID IS NULL
					)V


			/* L'opération Transfert OUT n'a pas été trouvée */
			SET @vOUTCreer = 'NON'
			IF @iID_OPER IS NULL
				BEGIN
					set @vOUTExistant = 'NON'

					-- Trouver le transfert OUT à promoteur Externe d'Universitas
					SELECT TOP 1					
						@iID_OPER = O.OperId, 
						@iID_OPERDate = O.OperDate
					FROM         
						Un_Cotisation C
						INNER JOIN Un_Oper O ON C.OperID = O.OperID 
						INNER JOIN dbo.Un_Unit U ON C.UnitID = U.UnitID 
						INNER JOIN dbo.Un_Convention CO ON U.ConventionID = CO.ConventionID
						INNER JOIN Un_OUT ON O.OperId = Un_OUT.OperId
						INNER JOIN Un_ExternalPlan ON Un_ExternalPlan.ExternalPlanID = Un_OUT.ExternalPlanID
						INNER JOIN Un_ExternalPromo ON Un_ExternalPromo.ExternalPromoID = Un_ExternalPlan.ExternalPromoID
						INNER JOIN Mo_Company ON Mo_Company.CompanyID = Un_ExternalPromo.ExternalPromoID
					WHERE
						CO.ConventionNo = @vConventionNo 
						AND
						O.OperTypeID = 'OUT'
						AND
						Un_OUT.ExternalPlanID NOT IN (86,87,88) -- Id correspondant au promoteur Universitas
					ORDER BY
						O.OperDate DESC

					/* La transaction Transfert OUT d'origine a été trouvé pour cette convention */
					IF @iID_OPER IS NOT NULL
						BEGIN
							SET @vOUTCreer = 'OUI'
							--- RÉCUPÉRATION DU CONNECTID SYSTÈME À PARTIR DE LA TABLE UN_DEF
							SELECT @iConnectId = MAX(CO.ConnectID)
							FROM Mo_Connect CO
							WHERE CO.UserID = 519626

							/* Obtenir la transaction OUT originale */
							SELECT 
								@ExternalPlanID = ExternalPlanID
								,@tiBnfRelationWithOtherConvBnf = tiBnfRelationWithOtherConvBnf
								,@vcOtherConventionNo = vcOtherConventionNo
								,@tiREEEType = tiREEEType
								,@bEligibleForCESG = bEligibleForCESG
								,@bEligibleForCLB = bEligibleForCLB
								,@bOtherContratBnfAreBrothers = bOtherContratBnfAreBrothers
								,@fYearBnfCot = fYearBnfCot
								,@fNoCESGCotBefore98 = fNoCESGCotBefore98
								,@fNoCESGCot98AndAfter = fNoCESGCot98AndAfter
								,@fCESGCot = fCESGCot
								,@fCESG = fCESG
								,@fCLB = fCLB
								,@fAIP = fAIP
								,@fMarketValue = fMarketValue
							FROM dbo.Un_OUT
							WHERE OperId = @iID_OPER

							/* Création d'une nouvelle opération OUT */
							EXECUTE @iID_OPER = dbo.SP_IU_UN_OPER @iConnectId, 0, 'OUT', @dtDateTransfert

							/* Insérer une nouvelle transaction OUT basé sur la transaction originale */
							INSERT INTO dbo.Un_OUT (
                                OperID, ExternalPlanID, tiBnfRelationWithOtherConvBnf, vcOtherConventionNo, tiREEEType,
                                bEligibleForCESG, bEligibleForCLB, bOtherContratBnfAreBrothers, fYearBnfCot, fBnfCot,
                                fNoCESGCotBefore98, fNoCESGCot98AndAfter, fCESGCot, fCESG, fCLB, fAIP, fMarketValue
                            )
							VALUES (@iID_OPER
									,@ExternalPlanID
									,@tiBnfRelationWithOtherConvBnf
									,Upper(@vcOtherConventionNo)
									,@tiREEEType
									,@bEligibleForCESG
									,@bEligibleForCLB
									,@bOtherContratBnfAreBrothers
									,0
									,0
									,0
									,0
									,0
									,0
									,0
									,0
									,0)
						END		
				END
			ELSE
				set @vOUTExistant = 'OUI'

			SET @mSolde_Credit_Base = 0
			SET @mSolde_Majoration = 0
			SET @mSolde_Interets_RQ = 0
			SET @mSolde_Interets_IQI = 0
			SET @mSolde_Interets_ICQ = 0
			SET @mSolde_Interets_IMQ = 0
			SET @mSolde_Interets_IIQ = 0
			SET @mSolde_Interets_III = 0
			SET @vcGestionPerte = ''

			IF (@iId_Oper IS NOT NULL)
				BEGIN
					-- Calculer les soldes en vigueur de l'IQÉÉ
					-------------------------------------------
					SELECT @mSolde_Credit_Base = ISNULL(SUM(CO.ConventionOperAmount),0)
					FROM Un_ConventionOper CO
					WHERE CO.ConventionID = @ConventionID
					  AND CO.ConventionOperTypeID = 'CBQ'

					SELECT @mSolde_Majoration = ISNULL(SUM(CO.ConventionOperAmount),0)
					FROM Un_ConventionOper CO
					WHERE CO.ConventionID = @ConventionID
					  AND CO.ConventionOperTypeID = 'MMQ'

					SELECT @mSolde_Interets_RQ = ISNULL(SUM(CO.ConventionOperAmount),0)
					FROM Un_ConventionOper CO
					WHERE CO.ConventionID = @ConventionID
					  AND CO.ConventionOperTypeID = 'MIM'

					SELECT @mSolde_Interets_IQI = ISNULL(SUM(CO.ConventionOperAmount),0)
					FROM Un_ConventionOper CO
					WHERE CO.ConventionID = @ConventionID
					  AND CO.ConventionOperTypeID = 'IQI'

					SELECT @mSolde_Interets_ICQ = ISNULL(SUM(CO.ConventionOperAmount),0)
					FROM Un_ConventionOper CO
					WHERE CO.ConventionID = @ConventionID
					  AND CO.ConventionOperTypeID = 'ICQ'

					SELECT @mSolde_Interets_IMQ = ISNULL(SUM(CO.ConventionOperAmount),0)
					FROM Un_ConventionOper CO
					WHERE CO.ConventionID = @ConventionID
					  AND CO.ConventionOperTypeID = 'IMQ'

					SELECT @mSolde_Interets_IIQ = ISNULL(SUM(CO.ConventionOperAmount),0)
					FROM Un_ConventionOper CO
					WHERE CO.ConventionID = @ConventionID
					  AND CO.ConventionOperTypeID = 'IIQ'

					SELECT @mSolde_Interets_III = ISNULL(SUM(CO.ConventionOperAmount),0)
					FROM Un_ConventionOper CO
					WHERE CO.ConventionID = @ConventionID
					  AND CO.ConventionOperTypeID = 'III'

					IF @mSolde_Credit_Base < 0 OR
						@mSolde_Majoration < 0 OR
						@mSolde_Interets_RQ < 0 OR
						@mSolde_Interets_IQI < 0 OR
						@mSolde_Interets_ICQ < 0 OR
						@mSolde_Interets_IMQ < 0 OR
						@mSolde_Interets_IIQ < 0 OR
						@mSolde_Interets_III < 0
						BEGIN
						/*
						select '@mSolde_Credit_Base',@mSolde_Credit_Base
						select '@mSolde_Majoration',@mSolde_Majoration
						select '@mSolde_Interets_RQ',@mSolde_Interets_RQ
						select '@mSolde_Interets_IQI',@mSolde_Interets_IQI
						select '@mSolde_Interets_ICQ',@mSolde_Interets_ICQ
						select '@mSolde_Interets_IMQ',@mSolde_Interets_IMQ
						select '@mSolde_Interets_IIQ', @mSolde_Interets_IIQ
						select '@mSolde_Interets_III', @mSolde_Interets_III
						
						select '@ConventionID',@ConventionID
						select '@iId_Oper', @iId_Oper
						*/	
							DELETE FROM Un_OUT WHERE OperID = @iId_Oper
							DELETE FROM Un_Oper WHERE OperID = @iId_Oper
							SET @iId_Oper = NULL
							SET @vOUTCreer = 'NON'
							SET @vcGestionPerte = 'ARI à faire'
							SET @mSolde_Credit_Base = 0
							SET @mSolde_Majoration = 0
							SET @mSolde_Interets_RQ = 0
							SET @mSolde_Interets_IQI = 0
							SET @mSolde_Interets_ICQ = 0
							SET @mSolde_Interets_IMQ = 0
							SET @mSolde_Interets_IIQ = 0
							SET @mSolde_Interets_III = 0
						END
					ELSE
						BEGIN						
							-- Insérer les transactions dans l'opération de OUT
							IF @mSolde_Credit_Base <> 0
								INSERT INTO dbo.Un_ConventionOper
										   (OperID
										   ,ConventionID
										   ,ConventionOperTypeID
										   ,ConventionOperAmount)
								 VALUES
									   (@iID_OPER
									   ,@ConventionID
									   ,'CBQ'
									   ,@mSolde_Credit_Base*-1)

							IF @mSolde_Majoration <> 0
								INSERT INTO dbo.Un_ConventionOper
										   (OperID
										   ,ConventionID
										   ,ConventionOperTypeID
										   ,ConventionOperAmount)
								 VALUES
									   (@iID_OPER
									   ,@ConventionID
									   ,'MMQ'
									   ,@mSolde_Majoration*-1)

							IF @mSolde_Interets_RQ <> 0
								INSERT INTO dbo.Un_ConventionOper
										   (OperID
										   ,ConventionID
										   ,ConventionOperTypeID
										   ,ConventionOperAmount)
								 VALUES
									   (@iID_OPER
									   ,@ConventionID
									   ,'MIM'
									   ,@mSolde_Interets_RQ*-1)

							IF @mSolde_Interets_IQI <> 0
								INSERT INTO dbo.Un_ConventionOper
										   (OperID
										   ,ConventionID
										   ,ConventionOperTypeID
										   ,ConventionOperAmount)
								 VALUES
									   (@iID_OPER
									   ,@ConventionID
									   ,'IQI'
									   ,@mSolde_Interets_IQI*-1)

							IF @mSolde_Interets_ICQ <> 0
								INSERT INTO dbo.Un_ConventionOper
										   (OperID
										   ,ConventionID
										   ,ConventionOperTypeID
										   ,ConventionOperAmount)
								 VALUES
									   (@iID_OPER
									   ,@ConventionID
									   ,'ICQ'
									   ,@mSolde_Interets_ICQ*-1)

							IF @mSolde_Interets_IMQ <> 0
								INSERT INTO dbo.Un_ConventionOper
										   (OperID
										   ,ConventionID
										   ,ConventionOperTypeID
										   ,ConventionOperAmount)
								 VALUES
									   (@iID_OPER
									   ,@ConventionID
									   ,'IMQ'
									   ,@mSolde_Interets_IMQ*-1)

							IF @mSolde_Interets_IIQ <> 0
								INSERT INTO dbo.Un_ConventionOper
										   (OperID
										   ,ConventionID
										   ,ConventionOperTypeID
										   ,ConventionOperAmount)
								 VALUES
									   (@iID_OPER
									   ,@ConventionID
									   ,'IIQ'
									   ,@mSolde_Interets_IIQ*-1)

							IF @mSolde_Interets_III <> 0
								INSERT INTO dbo.Un_ConventionOper
										   (OperID
										   ,ConventionID
										   ,ConventionOperTypeID
										   ,ConventionOperAmount)
								 VALUES
									   (@iID_OPER
									   ,@ConventionID
									   ,'III'
									   ,@mSolde_Interets_III*-1)

							IF @vOUTCreer = 'OUI'
								UPDATE Un_OUT
								SET fAIP = @mSolde_Interets_RQ+@mSolde_Interets_IQI+@mSolde_Interets_ICQ+@mSolde_Interets_IMQ+@mSolde_Interets_IIQ+
											@mSolde_Interets_III,
									fMarketValue = @mSolde_Credit_Base+@mSolde_Majoration+@mSolde_Interets_RQ+@mSolde_Interets_IQI+@mSolde_Interets_ICQ+
													@mSolde_Interets_IMQ+@mSolde_Interets_IIQ+@mSolde_Interets_III
								WHERE OperID = @iID_OPER

							/* Mise à jour de la table temporaire pour dire que la transaction a été traitée */
							UPDATE tblTEMP_TransacManuelleIQEE
							SET cTraiter = 'O'
							WHERE IidTransacManuelleIQEE = @IidTransacManuelleIQEE
						END
				END 

			IF @bActiveDebug = 1
				INSERT INTO	@tblResultatDebug
				VALUES (@vConventionNo,@ConventionID,@IidTransacManuelleIQEE,@vOUTExistant,@vOUTCreer,@vcGestionPerte,@iID_OPER,
						@mSolde_Credit_Base,@mSolde_Majoration,@mSolde_Interets_RQ,@mSolde_Interets_IQI,@mSolde_Interets_ICQ,
						@mSolde_Interets_IMQ,@mSolde_Interets_IIQ,@mSolde_Interets_III)
	
			FETCH NEXT FROM curTransacManuIQEE INTO
				@IidTransacManuelleIQEE	
				,@vConventionNo	
				,@dtDateTransfert
				,@ConventionID
		END

		CLOSE curTransacManuIQEE
		DEALLOCATE curTransacManuIQEE

		IF @bActiveDebug = 1
			SELECT *
			FROM @tblResultatDebug

	------------------
	COMMIT TRANSACTION
	------------------
	SET @iCode_Retour = 0

END TRY
BEGIN CATCH
	-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
	SELECT										
			@vErrmsg		= REPLACE(ERROR_MESSAGE(),'%',' '),
			@iErrState		= ERROR_STATE(),
			@iErrSeverity	= ERROR_SEVERITY(),
			@iErrno			= ERROR_NUMBER();

	-- LA TRANSACTION EST TOUJOURS ACTIVE, ON PEUT FAIRE UN ROLLBACK
	IF (XACT_STATE()) = -1	
		BEGIN
			-----------------------
			ROLLBACK TRANSACTION
			-----------------------						
		END

	-- CONCATÉNATION DU NUMÉRO D'ERREUR INTERNE À SQL SERVEUR
	SET @vErrmsg = CAST(@iErrno AS VARCHAR(6)) + ' : ' + @vErrmsg
	RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState)	

	SET @iCode_Retour = -1
END CATCH

	-- RÉACTIVATION DU TRIGGER
	--ALTER TABLE dbo.Un_ConventionOper		ENABLE TRIGGER TUn_ConventionOper
	--ALTER TABLE dbo.Un_Oper				ENABLE TRIGGER TUn_Oper
	--ALTER TABLE dbo.Un_Oper				ENABLE TRIGGER TUn_Oper_dtFirstDeposit
	Delete #DisableTrigger where vcTriggerName = 'TUn_ConventionOper'
	Delete #DisableTrigger where vcTriggerName = 'TUn_Oper'
	Delete #DisableTrigger where vcTriggerName = 'TUn_Oper_dtFirstDeposit'

	RETURN @iCode_Retour
END


