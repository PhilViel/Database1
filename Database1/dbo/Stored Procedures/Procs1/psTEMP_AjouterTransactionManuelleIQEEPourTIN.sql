/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEMP_AjouterTransactionManuelleIQEEPourTIN
Nom du service		: Ajouter les transactions manuelles d'IQÉÉ pour les transfert OUT.
But 				: Mesure temporaire qui a pour objectif d'ajouter les transactions manuelles d'IQÉÉ pour les transfert TIN					  			
Facette				: IQÉÉ

Historique des modifications:
    Date		 Programmeur			Description
    ----------  --------------------    -----------------------------------------------------
    2009-12-09	 Rémy Rouillard		Création du service
    2010-04-23	 Éric Deshaies			Ne pas insérer les montants à 0
    2010-10-04	 Steve Gouin			Gestion des disable trigger par #DisableTrigger
    2013-02-27	 Donald Huppé			Ajout de @vTINCree
    2016-04-26	 Patrice Côté			Ajout des montants d'IQEE dans Un_TIN
    2016-05-05  Steeve Picard           Correction de la valeur marchande
    2016-05-05	 Maxime Martel			ajout de l'update du champ fBnfCot
    2016-08-11	 Donald Huppé			ajout paramètre @ConnectId
    2017-12-04  Steeve Picard           Tenir compte des cotisations de l'année en cours aussi
***********************************************************************************************************************/
CREATE PROCEDURE dbo.psTEMP_AjouterTransactionManuelleIQEEPourTIN
(	
	@vConventionNo		varchar(15)
	,@bActiveDebug		int	= 0
	,@ConnectId			int = 2
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
		,@iID_OPER			INT

	DECLARE
		@IidTransacManuelleIQEE			INT
		,@dtDateTransfert				datetime
		,@mTotalTransfert               money
		,@mIQEE							money
		,@mRendIQEE						money
		,@mIQEE_Plus					money
		,@mRendIQEE_Plus				money
		,@cTraiter						char(1)
		,@vcTypeTransfert				varchar(3)
		,@iID_OPERDate					datetime
		,@ConventionID					INT
		,@iConnectId					INT
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
		,@bPendingApplication			bit
		,@vTINExistant					varchar(3)
		,@vTINCree						varchar(3)
		,@mCotisations_AyantDroit_IQEE	money
		,@mCotisations_NonDroit_IQEE	money
		,@mCotisations_Avant_IQEE		money
		,@bIsDebug bit = CASE @@Servername WHEN 'SRVSQL13' THEN 1 ELSE 0 END
		

	DECLARE @tblResultatDebug			TABLE	
											(
											vNoConvention			VARCHAR(15)			
											,vIdConvention			VARCHAR(15)
											,vOperId				VARCHAR(10)
											,vIdTransac				VARCHAR(10)
											,vCBQ					VARCHAR(10)
											,vMMQ					VARCHAR(10)
											,vICQ					VARCHAR(10)
											,vIMQ					VARCHAR(10)
											,dtDateCreation			DateTime
											,vTINExistant			varchar(3)
											,vTINCree				varchar(3)
											)

	/* Obtenir les transactions manuelle dans la table temporaire pour les transferts IN */
	DECLARE curTransacManuIQEE CURSOR LOCAL FAST_FORWARD
	FOR
		SELECT 
			tmi.IidTransacManuelleIQEE
			,tmi.vConventionNo
			,tmi.dtDateTransfert
			,tmi.mTotal_Transfert
			,tmi.mIQEE
			,tmi.mRendIQEE
			,tmi.mIQEE_Plus
			,tmi.mRendIQEE_Plus
			,tmi.mCotisations_AyantDroit_IQEE
			,tmi.mCotisations_NonDroit_IQEE
			,tmi.mCotisations_Avant_IQEE
			,tmi.cTraiter
			,tmi.vcTypeTransfert
			,c.ConventionID
		FROM 
			tblTEMP_TransacManuelleIQEE tmi
			INNER JOIN dbo.Un_Convention c ON c.ConventionNo = tmi.vConventionNo
		WHERE 
			tmi.vcTypeTransfert = 'TIN'
			AND
			tmi.cTraiter = 'N'
			AND
			c.ConventionNo = ISNULL(@vConventionNo, c.ConventionNo)
			
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
	
	IF @bIsDebug <> 0
	    PRINT 'psTEMP_AjouterTransactionManuelleIQEEPourTIN - BEGIN TRANSACTION'
	
	OPEN curTransacManuIQEE
	FETCH NEXT FROM curTransacManuIQEE INTO
		@IidTransacManuelleIQEE	
		,@vConventionNo	
		,@dtDateTransfert
		,@mTotalTransfert
		,@mIQEE	
		,@mRendIQEE	
		,@mIQEE_Plus
		,@mRendIQEE_Plus
		,@mCotisations_AyantDroit_IQEE
		,@mCotisations_NonDroit_IQEE
		,@mCotisations_Avant_IQEE
		,@cTraiter
		,@vcTypeTransfert
		,@ConventionID

	WHILE @@FETCH_STATUS = 0
		BEGIN
		
			IF @bIsDebug <> 0 BEGIN
			    PRINT 'psTEMP_AjouterTransactionManuelleIQEEPourTIN - FETCH curTransacManuIQEE'
			    PRINT '@IidTransacManuelleIQEE =		' + STR(@IidTransacManuelleIQEE)
			    PRINT '@vConventionNo =					' + @vConventionNo
			    PRINT '@dtDateTransfert =				' + CONVERT(VARCHAR(25), @dtDateTransfert)
			    PRINT '@mTotalTransfert =               ' + Str(@mTotalTransfert)
			    PRINT '@mIQEE =							' + STR(@mIQEE)
			    PRINT '@mRendIQEE =						' + STR(@mRendIQEE)
			    PRINT '@mIQEE_Plus =					' + STR(@mIQEE_Plus)
			    PRINT '@mRendIQEE_Plus =				' + STR(@mRendIQEE_Plus)
			    PRINT '@mCotisations_AyantDroit_IQEE =	' + STR(@mCotisations_AyantDroit_IQEE)
			    PRINT '@mCotisations_NonDroit_IQEE =	' + STR(@mCotisations_NonDroit_IQEE)
			    PRINT '@mCotisations_Avant_IQEE =		' + STR(@mCotisations_Avant_IQEE)
			END
		
			/* Obtenir l'identifant d'opération correspondant au transfert IN pour la convention et la date de transfert */
			SET @iID_OPER = Null

			SELECT     
				@iID_OPER = O.OperId, 
				@iID_OPERDate = O.OperDate
			FROM         
				Un_Cotisation C
				INNER JOIN Un_Oper O ON C.OperID = O.OperID 
				INNER JOIN dbo.Un_Unit U ON C.UnitID = U.UnitID 
				INNER JOIN dbo.Un_Convention CO ON U.ConventionID = CO.ConventionID
			WHERE
				CO.ConventionNo = @vConventionNo 
				AND
				O.OperDate = @dtDateTransfert
				AND
				O.OperTypeID = 'TIN'

			set @vTINExistant = 'OUI'
			set @vTINCree = 'NON'

			/* L'opération Transfert IN n'a pas été trouvée */
			IF @iId_Oper IS NULL
			BEGIN
				set @vTINExistant = 'NON'

				-- Trouver le transfert IN d'un promoteur Externe qui ne doit pas être Universitas
				SELECT TOP 1					
					@iID_OPER = O.OperId, 
					@iID_OPERDate = O.OperDate
				FROM         
					Un_Cotisation C
					INNER JOIN Un_Oper O ON C.OperID = O.OperID 
					INNER JOIN dbo.Un_Unit U ON C.UnitID = U.UnitID 
					INNER JOIN dbo.Un_Convention CO ON U.ConventionID = CO.ConventionID
					INNER JOIN Un_TIN ON O.OperId = Un_TIN.OperId
					INNER JOIN Un_ExternalPlan ON Un_ExternalPlan.ExternalPlanID = Un_TIN.ExternalPlanID
					INNER JOIN Un_ExternalPromo ON Un_ExternalPromo.ExternalPromoID = Un_ExternalPlan.ExternalPromoID
					INNER JOIN Mo_Company ON Mo_Company.CompanyID = Un_ExternalPromo.ExternalPromoID
				WHERE
					CO.ConventionNo = @vConventionNo 
					AND
					O.OperTypeID = 'TIN'
					AND
					Un_TIN.ExternalPlanID NOT IN (86,87,88) -- Id correspondant au promoteur Universitas
				ORDER BY
					O.OperDate DESC

				/* La transaction Transfert IN a été pour cette convention */
				IF @iId_Oper IS NOT NULL
					BEGIN
						set @vTINCree = 'OUI'

						/* Obtenir la transaction TIN originale */
						SELECT 
							@ExternalPlanID = ExternalPlanID
							,@tiBnfRelationWithOtherConvBnf = tiBnfRelationWithOtherConvBnf
							,@vcOtherConventionNo = vcOtherConventionNo
							,@dtOtherConvention = dtOtherConvention
							,@tiOtherConvBnfRelation = tiOtherConvBnfRelation
							,@bAIP = bAIP
							,@bACESGPaid = bACESGPaid
							,@bBECInclud = bBECInclud
							,@bPGInclud = bPGInclud
							,@fYearBnfCot = fYearBnfCot
							,@fBnfCot = fBnfCot
							,@fNoCESGCotBefore98 = fNoCESGCotBefore98
							,@fNoCESGCot98AndAfter = fNoCESGCot98AndAfter
							,@fCESGCot = fCESGCot
							,@fCESG = fCESG
							,@fCLB = fCLB
							,@fAIP = fAIP
							,@fMarketValue = fMarketValue
							,@bPendingApplication = bPendingApplication
						FROM dbo.Un_TIN
						WHERE OperId = @iID_OPER

						/* Création d'une nouvelle opération TIN */
						EXECUTE @iID_OPER = dbo.SP_IU_UN_OPER @ConnectId, 0, 'TIN', @dtDateTransfert

						/* Insérer une nouvelle transaction TIN basé sur la transaction originale */
						INSERT INTO dbo.Un_TIN (
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
							  ,mIQEE
							  ,mIQEE_Rendement
							  ,mIQEE_Plus
							  ,mIQEE_Plus_Rendement
							  ,mIQEE_CotisationsAyantDroit
							  ,mIQEE_CotisationsAyantPasDroit
						)
						VALUES (@iID_OPER
								,@ExternalPlanID
								,@tiBnfRelationWithOtherConvBnf
								,@vcOtherConventionNo
								,@dtOtherConvention
								,@tiOtherConvBnfRelation
								,@bAIP
								,@bACESGPaid
								,0
								,0
								,0
								,ISNULL(@mCotisations_AyantDroit_IQEE, 0) + ISNULL(@mCotisations_NonDroit_IQEE, 0) + ISNULL(@mCotisations_Avant_IQEE, 0)
								,0
								,0
								,0
								,0
								,0
								,ISNULL(@mRendIQEE,0) + ISNULL(@mRendIQEE_Plus,0)
								,ISNULL(@mTotalTransfert,0)
								,@bPendingApplication
								,ISNULL(@mIQEE, 0)
								,ISNULL(@mRendIQEE, 0)
								,ISNULL(@mIQEE_Plus, 0)
								,ISNULL(@mRendIQEE_Plus, 0)
								,ISNULL(@mCotisations_AyantDroit_IQEE, 0)
								,ISNULL(@mCotisations_NonDroit_IQEE, 0))

					END				
			END 

			IF @iId_Oper IS NOT NULL
			BEGIN
				/* Injecter les montants de crédit de base */ 
				IF @mIQEE IS NOT NULL AND @mIQEE <> 0
				BEGIN
					INSERT INTO	dbo.Un_ConventionOper
					VALUES (@iID_OPER, @ConventionID, 'CBQ', @mIQEE)	
				END

				/* Injecter les montants de majoration */ 
				IF @mIQEE_Plus IS NOT NULL AND @mIQEE_Plus <> 0
				BEGIN
					INSERT INTO	dbo.Un_ConventionOper
					VALUES (@iID_OPER, @ConventionID, 'MMQ', @mIQEE_Plus)
				END

				/* Injecter les montants du rendement IQEE */ 
				IF @mRendIQEE IS NOT NULL AND @mRendIQEE <> 0
				BEGIN
					INSERT INTO	dbo.Un_ConventionOper
					VALUES (@iID_OPER, @ConventionID, 'IQI', @mRendIQEE)
				END

				/* Injecter les montants du rendement IQEE+ */ 
				IF @mRendIQEE_Plus IS NOT NULL AND @mRendIQEE_Plus <> 0
				BEGIN
					INSERT INTO	dbo.Un_ConventionOper
					VALUES (@iID_OPER, @ConventionID, 'IQI', @mRendIQEE_Plus)
				END

				/* Mise à jour de la table temporaire pour dire que la transaction a été traitée */
				UPDATE tblTEMP_TransacManuelleIQEE
				SET cTraiter = 'O'
				WHERE IidTransacManuelleIQEE = @IidTransacManuelleIQEE
				
				/* Mise à jour des montants dans la table Un_TIN */
				UPDATE Un_TIN
				SET mIQEE = ISNULL(@mIQEE, 0),
					mIQEE_Rendement = ISNULL(@mRendIQEE, 0),
					mIQEE_Plus = ISNULL(@mIQEE_Plus, 0),
					mIQEE_Plus_Rendement = ISNULL(@mRendIQEE_Plus, 0),
					mIQEE_CotisationsAyantDroit = ISNULL(@mCotisations_AyantDroit_IQEE, 0),
					mIQEE_CotisationsAyantPasDroit = ISNULL(@mCotisations_NonDroit_IQEE, 0),
					fBnfCot = ISNULL(fYearBnfCot, 0) + ISNULL(@mCotisations_AyantDroit_IQEE, 0) + ISNULL(@mCotisations_NonDroit_IQEE, 0) + ISNULL(@mCotisations_Avant_IQEE, 0)
				WHERE OperID = @iId_Oper
				
			END

			IF @bActiveDebug <> 0
			BEGIN
				INSERT INTO	@tblResultatDebug
				VALUES (@vConventionNo
						,CAST(@ConventionID AS VARCHAR(15))
						,CAST(ISNULL(@iID_OPER,0) AS VARCHAR(10))
						,CAST(@IidTransacManuelleIQEE AS VARCHAR(10))
						,CAST(ISNULL(@mIQEE,0) AS VARCHAR(10))
						,CAST(ISNULL(@mIQEE_Plus,0) AS VARCHAR(10))
						,CAST(ISNULL(@mRendIQEE,0) AS VARCHAR(10))
						,CAST(ISNULL(@mRendIQEE_Plus,0) AS VARCHAR(10))
						,GETDATE()
						,@vTINExistant
						,@vTINCree)
			END

			FETCH NEXT FROM curTransacManuIQEE INTO
		        @IidTransacManuelleIQEE	
		        ,@vConventionNo	
		        ,@dtDateTransfert
		        ,@mTotalTransfert
		        ,@mIQEE	
		        ,@mRendIQEE	
		        ,@mIQEE_Plus
		        ,@mRendIQEE_Plus
		        ,@mCotisations_AyantDroit_IQEE
		        ,@mCotisations_NonDroit_IQEE
		        ,@mCotisations_Avant_IQEE
		        ,@cTraiter
		        ,@vcTypeTransfert
		        ,@ConventionID

		END

		CLOSE curTransacManuIQEE
		DEALLOCATE curTransacManuIQEE

		IF @bActiveDebug = 1
			BEGIN
				SELECT 
					'NOConvention : ' + vNoConvention
					,'IdConvention : ' + vIdConvention
					,'OperId = ' + vOperId
					,'IdTransacManuelleIQEE = ' + vIdTransac
					,'CBQ = ' + vCBQ
					,'MMQ = ' + vMMQ
					,'ICQ = ' + vICQ
					,'IMQ = ' + vIMQ
					,dtDateCreation
					,'TIN Existant = ' + vTINExistant
					,'TIN créé = ' + vTINCree
				FROM @tblResultatDebug

				SELECT 
					'Convention en erreur = ' + vConventionNo
					,dtDateTransfert
				FROM
					dbo.tblTEMP_TransacManuelleIQEE
				WHERE
					cTraiter = 'N'
					AND
					vcTypeTransfert = 'TIN'
			END

		IF @bActiveDebug = 2
			BEGIN
				SELECT 
					*
				FROM @tblResultatDebug

			END

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
	--ALTER TABLE dbo.Un_ConventionOper	ENABLE TRIGGER TUn_ConventionOper
	--ALTER TABLE dbo.Un_Oper				ENABLE TRIGGER TUn_Oper
	--ALTER TABLE dbo.Un_Oper				ENABLE TRIGGER TUn_Oper_dtFirstDeposit

	Delete #DisableTrigger where vcTriggerName = 'TUn_ConventionOper'
	Delete #DisableTrigger where vcTriggerName = 'TUn_Oper'
	Delete #DisableTrigger where vcTriggerName = 'TUn_Oper_dtFirstDeposit'

	RETURN @iCode_Retour

END--CREATE PROCEDURE


