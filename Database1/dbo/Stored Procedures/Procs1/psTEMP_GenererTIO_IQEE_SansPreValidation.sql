

/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEMP_GenererTIO_IQEE
Nom du service		: Création de TIO des compte d'iqee
But 				: Créer des TIO des comptes d'iqee
Facette				: TEMP

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2012-12-11		Donald Huppé						Création du service		
		2013-01-14		Donald Huppé						Ajout des validations que les conventions existent
		2012-01-21		Donald Huppé						mettre des left join dans le dernier select sur @vcConventionNoCession car si pas d'oper alors pas de donnée affiché du soucrripteur
		2013-02-20		Donald Huppé						ajout de mgobeil dans les utilisateurs autorisés	
		2013-05-30		Donald Huppé						ajout de bjeannotte dans les utilisateurs autorisés
		2016-04-27		Steeve Picard						Forcer le «OtherConventionNo» en majuscule dans les tables «Un_TIN & Un_OUT»
		
exec psTEMP_GenererTIO_IQEE 
	@UserID = 'DHUPPE', 
	@vcConventionNoCedant = 'x-20101013044',
	@vcConventionNoCession = 'x-20121212042',
	@bTransfererTotal  = 0,

	@CBQ_c  = 0.0,
	@MMQ_c  = 0.0,	
	@MIM_c  = 0.0,
	@ICQ_c  = 0.0,
	@IMQ_c  = 0.0,
	@III_c  = 0.0,
	@IIQ_c  = 0.0,
	@IQI_c  = 0.0

*********************************************************************************************************************/

CREATE PROCEDURE [dbo].[psTEMP_GenererTIO_IQEE_SansPreValidation] 
(
	@UserID varchar(255),
	@vcConventionNoCedant VARCHAR(15),
	@vcConventionNoCession VARCHAR(15),
	@bTransfererTotal bit = 0,

	@CBQ_c MONEY = 0.0,
	@MMQ_c MONEY = 0.0,	
	@MIM_c MONEY = 0.0,
	@ICQ_c MONEY = 0.0,
	@IMQ_c MONEY = 0.0,
	@III_c MONEY = 0.0,
	@IIQ_c MONEY = 0.0,
	@IQI_c MONEY = 0.0
)
AS
BEGIN
	declare
	
	@FaireTIO int,
	
	@CBQ MONEY,	
	@MMQ MONEY,
	@MIM MONEY,
	@ICQ MONEY,
	@IMQ MONEY,
	@III MONEY,
	@IIQ MONEY,
	@IQI MONEY,

	@iID_OPER_OUT INT,
	@iID_OPER_TIN INT,
	@iConnectId INT,
	@dtDateTransfert DATETIME,
	@iID_Convention_Cedant INT,
	@iID_Convention_Cession INT,
	@dtDateVigueur_Cedant datetime,
	@dtDateVigueur_Cession datetime,
	@ExternalPlanID_Cedant int,
	@ExternalPlanID_Cession int,
	@vcSousc_Cedant varchar(80),
	@vcSousc_Cession varchar(80),
	@cMessage varchar(500)
	
	set @vcConventionNoCedant = ltrim(rtrim(@vcConventionNoCedant))
	set @vcConventionNoCession = ltrim(rtrim(@vcConventionNoCession))	

	if not exists (select 1 from sysobjects where Name = 'tblTEMP_TIOIQEE')
		begin
		create table tblTEMP_TIOIQEE (conventionno varchar(20), DateInsert datetime) --drop table tblTEMP_TIOIQEE
		end

	-- On laisse un trace dans une table lors d'une demande sans montant de TIO. Afin de vérifier ultérieurement, lors d'une demande avec montant de TIO, 
	-- qu'une demande de rapport a déjà été faite sans montant de TIO
	IF 	(@CBQ_c=0 and @MMQ_c=0 and @MIM_c=0 and @ICQ_c=0 and @IMQ_c=0 and @III_c=0 and @IIQ_c=0 and @IQI_c= 0 and @bTransfererTotal = 0)
		begin
		delete from tblTEMP_TIOIQEE where conventionno <> @vcConventionNoCedant -- select * from tblTEMP_TIOIQEE
		insert into tblTEMP_TIOIQEE VALUES (@vcConventionNoCedant, getdate())
		end

	set @cMessage = ''
	set @FaireTIO = 0

	-- AU CAS OU ON SAISIT UNE VALEUR NÉGATIVE, ON MET TOUT POSITIF
	SET @CBQ_c = ABS(@CBQ_c)
	SET @MMQ_c = ABS(@MMQ_c)	
	SET @MIM_c = ABS(@MIM_c)	
	SET @ICQ_c = ABS(@ICQ_c)
	SET @IMQ_c = ABS(@IMQ_c)
	SET @III_c = ABS(@III_c)
	SET @IIQ_c = ABS(@IIQ_c)
	SET @IQI_c = ABS(@IQI_c)

	SELECT 
		@iID_Convention_Cedant = C.ConventionID, 
		@vcSousc_Cedant = hs.LastName + ' ' + hs.FirstName,
		@ExternalPlanID_Cedant = EP.ExternalPlanID,
		@dtDateVigueur_Cedant = min(u.InForceDate)
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Unit u ON C.ConventionID = u.ConventionID
	JOIN dbo.Mo_Human hs ON C.SubscriberID = hs.HumanID
	join Un_Plan p ON C.PlanID = p.PlanID
	join Un_ExternalPlan EP ON p.PlanGovernmentRegNo = EP.ExternalPlanGovernmentRegNo
	WHERE C.ConventionNo = @vcConventionNoCedant
	group by C.ConventionID, EP.ExternalPlanID, hs.LastName + ' ' + hs.FirstName

	SELECT 
		@iID_Convention_Cession = C.ConventionID, 
		@vcSousc_Cession = hs.LastName + ' ' + hs.FirstName,
		@ExternalPlanID_Cession = EP.ExternalPlanID,
		@dtDateVigueur_Cession = min(u.InForceDate)
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Unit u ON C.ConventionID = u.ConventionID
	JOIN dbo.Mo_Human hs ON C.SubscriberID = hs.HumanID
	join Un_Plan p ON C.PlanID = p.PlanID
	join Un_ExternalPlan EP ON p.PlanGovernmentRegNo = EP.ExternalPlanGovernmentRegNo
	WHERE C.ConventionNo = @vcConventionNoCession
	group by C.ConventionID, EP.ExternalPlanID, hs.LastName + ' ' + hs.FirstName

	SET @dtDateTransfert = GETDATE()

	SELECT @iConnectId = isnull(MAX(CO.ConnectID),1)
	FROM Mo_Connect CO
	join Mo_User u ON CO.UserID = u.UserID
	WHERE  CHARINDEX ( u.LoginNameID, @UserID,1) > 1

	SELECT 
		--c.ConventionNo,
		@CBQ = sum(CASE WHEN co.ConventionOperTypeID = 'CBQ' THEN co.ConventionOperAmount ELSE 0 END),
		@MMQ = sum(CASE WHEN co.ConventionOperTypeID = 'MMQ' THEN co.ConventionOperAmount ELSE 0 END),
		@MIM = sum(CASE WHEN co.ConventionOperTypeID = 'MIM' THEN co.ConventionOperAmount ELSE 0 END),
		@ICQ = sum(CASE WHEN co.ConventionOperTypeID = 'ICQ' THEN co.ConventionOperAmount ELSE 0 END),
		@IMQ = sum(CASE WHEN co.ConventionOperTypeID = 'IMQ' THEN co.ConventionOperAmount ELSE 0 END),
		@III = sum(CASE WHEN co.ConventionOperTypeID = 'III' THEN co.ConventionOperAmount ELSE 0 END),
		@IIQ = sum(CASE WHEN co.ConventionOperTypeID = 'IIQ' THEN co.ConventionOperAmount ELSE 0 END),
		@IQI = sum(CASE WHEN co.ConventionOperTypeID = 'IQI' THEN co.ConventionOperAmount ELSE 0 END)
	from 
		Un_Convention c
		JOIN Un_ConventionOper co ON c.Conventionid = co.ConventionID
		JOIN Un_Oper o ON co.OperID = o.OperID
	WHERE 
		c.ConventionNo = @vcConventionNoCedant
	GROUP by 
		c.ConventionNo
		
	IF @bTransfererTotal <> 0
		BEGIN
		SELECT 
			--c.ConventionNo,
			@CBQ_C = sum(CASE WHEN co.ConventionOperTypeID = 'CBQ' THEN co.ConventionOperAmount ELSE 0 END),
			@MMQ_C = sum(CASE WHEN co.ConventionOperTypeID = 'MMQ' THEN co.ConventionOperAmount ELSE 0 END),
			@MIM_C = sum(CASE WHEN co.ConventionOperTypeID = 'MIM' THEN co.ConventionOperAmount ELSE 0 END),
			@ICQ_C = sum(CASE WHEN co.ConventionOperTypeID = 'ICQ' THEN co.ConventionOperAmount ELSE 0 END),
			@IMQ_C = sum(CASE WHEN co.ConventionOperTypeID = 'IMQ' THEN co.ConventionOperAmount ELSE 0 END),
			@III_C = sum(CASE WHEN co.ConventionOperTypeID = 'III' THEN co.ConventionOperAmount ELSE 0 END),
			@IIQ_C = sum(CASE WHEN co.ConventionOperTypeID = 'IIQ' THEN co.ConventionOperAmount ELSE 0 END),
			@IQI_C = sum(CASE WHEN co.ConventionOperTypeID = 'IQI' THEN co.ConventionOperAmount ELSE 0 END)
		from 
			Un_Convention c
			JOIN Un_ConventionOper co ON c.Conventionid = co.ConventionID
			JOIN Un_Oper o ON co.OperID = o.OperID
		WHERE 
			c.ConventionNo = @vcConventionNoCedant
		GROUP by 
			c.ConventionNo
		END			
		
	IF  (@CBQ_c<>0 OR @MMQ_c<>0 OR @MIM_c<>0 OR @ICQ_c<>0 OR @IMQ_c<>0 OR @III_c<>0 OR @IIQ_c<>0 OR @IQI_c	<> 0) 
		OR (@bTransfererTotal <> 0 AND (@CBQ<>0 OR @MMQ<>0 OR @MIM<>0 OR @ICQ<>0 OR @IMQ<>0 OR @III<>0 OR @IIQ<>0 OR @IQI <> 0))
		BEGIN
		set @FaireTIO = 1
		END

	if  isnull(@iID_Convention_Cedant,0) = 0 
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Convention cédante non trouvée.'
		set @FaireTIO = 0
		END

	if isnull(@iID_Convention_Cession,0) = 0
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Convention cessionaire non trouvée.'
		set @FaireTIO = 0
		END

		-- si une demande de montant à transférer,  On s'assure que le user a demandé le rapport sans montant à transférer en premier (il y a une trace dans la table). 
		-- Afin d'éviter de générer un TIO par erreur (avec des valeur de montant à transférer d'une demande précédante)
/*
	IF  ((@CBQ_c<>0 OR @MMQ_c<>0 OR @MIM_c<>0 OR @ICQ_c<>0 OR @IMQ_c<>0 OR @III_c<>0 OR @IIQ_c<>0 OR @IQI_c	<> 0) or @bTransfererTotal <> 0)
		AND not exists (SELECT 1 from tblTEMP_TIOIQEE where conventionno = @vcConventionNoCedant) 
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Attention. Demandez d''abord les soldes sans montant à transférer !'
		set @FaireTIO = 0
		END
*/
	IF  (@CBQ<0 OR @MMQ<0 OR @MIM<0 OR @ICQ<0 OR @IMQ<0 OR @III<0 OR @IIQ<0 OR @IQI	< 0) 
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Solde(s) négatif(s). faire d''abord un ARI.'
		set @FaireTIO = 0
		END

	IF  (@vcConventionNoCedant = @vcConventionNoCession) 
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Choisir 2 conventions différentes.'
		set @FaireTIO = 0
		END

	IF isnull(@CBQ_C,0) <> 0 and isnull(@CBQ_C,0) > @CBQ
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Trop de $ puisé dans CBQ.'
		set @FaireTIO = 0
		END	
	
	IF isnull(@MMQ_C,0) <> 0 and isnull(@MMQ_C,0) > @MMQ
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Trop de $ puisé dans MMQ.'
		set @FaireTIO = 0
		END	
	
	IF isnull(@MIM_C,0) <> 0 and isnull(@MIM_C,0) > @MIM
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Trop de $ puisé dans MIM.'
		set @FaireTIO = 0
		END	
	
	IF isnull(@ICQ_C,0) <> 0 and isnull(@ICQ_C,0) > @ICQ
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Trop de $ puisé dans ICQ.'
		set @FaireTIO = 0
		END	
	
	IF isnull(@IMQ_C,0) <> 0 and isnull(@IMQ_C,0) > @IMQ
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Trop de $ puisé dans IMQ.'
		set @FaireTIO = 0
		END	
	
	IF isnull(@III_C,0) <> 0 and isnull(@III_C,0) > @III
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Trop de $ puisé dans III.'
		set @FaireTIO = 0
		END	
	
	IF isnull(@IIQ_C,0) <> 0 and isnull(@IIQ_C,0) > @IIQ
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Trop de $ puisé dans IIQ.'
		set @FaireTIO = 0
		END	
	
	IF isnull(@IQI_C,0) <> 0 and isnull(@IQI_C,0) > @IQI
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Trop de $ puisé dans IQI.'
		set @FaireTIO = 0
		END	

	if @UserID not like '%dhuppe%' and @UserID not like '%fmenard%'  and @UserID not like '%mgobeil%' and @UserID not like '%bjeannotte%'
		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Usager non autorisé : ' + @UserID
		set @FaireTIO = 0
		end

	IF @FaireTIO = 1
		BEGIN	

		EXECUTE @iID_OPER_OUT = dbo.SP_IU_UN_OPER 1, 0, 'OUT', @dtDateTransfert

		INSERT INTO dbo.Un_OUT (
            OperID, ExternalPlanID, tiBnfRelationWithOtherConvBnf, vcOtherConventionNo, tiREEEType,
            bEligibleForCESG, bEligibleForCLB, bOtherContratBnfAreBrothers, fYearBnfCot, fBnfCot,
            fNoCESGCotBefore98, fNoCESGCot98AndAfter, fCESGCot, fCESG, fCLB, fAIP, fMarketValue
        )
		VALUES (@iID_OPER_OUT
				,@ExternalPlanID_Cession
				,1
				,@vcConventionNoCession
				,1
				,1
				,1
				,1
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,@CBQ_c+ @MMQ_c+@MIM_c+@ICQ_c+@IMQ_c+@III_c+@IIQ_c+@IQI_c
				)

		IF @CBQ_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_OUT
			,@iID_Convention_Cedant
			,'CBQ'
			,@CBQ_c * -1)	
			END

		IF @MMQ_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_OUT
			,@iID_Convention_Cedant
			,'MMQ'
			,@MMQ_c * -1)	
			END

		IF @MIM_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_OUT
			,@iID_Convention_Cedant
			,'MIM'
			,@MIM_c * -1)	
			END

		IF @ICQ_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_OUT
			,@iID_Convention_Cedant
			,'ICQ'
			,@ICQ_c * -1)	
			END

		IF @IMQ_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_OUT
			,@iID_Convention_Cedant
			,'IMQ'
			,@IMQ_c * -1)	
			END

		IF @III_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_OUT
			,@iID_Convention_Cedant
			,'III'
			,@III_c * -1)	
			END

		IF @IIQ_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_OUT
			,@iID_Convention_Cedant
			,'IIQ'
			,@IIQ_c * -1)	
			END

		IF @IQI_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_OUT
			,@iID_Convention_Cedant
			,'IQI'
			,@IQI_c * -1)	
			END

		EXECUTE @iID_OPER_TIN = dbo.SP_IU_UN_OPER 1, 0, 'TIN', @dtDateTransfert

		INSERT INTO [dbo].[Un_TIN]
				   ([OperID]
				   ,[ExternalPlanID]
				   ,[tiBnfRelationWithOtherConvBnf]
				   ,[vcOtherConventionNo]
				   ,[dtOtherConvention]
				   ,[tiOtherConvBnfRelation]
				   ,[bAIP]
				   ,[bACESGPaid]
				   ,[bBECInclud]
				   ,[bPGInclud]
				   ,[fYearBnfCot]
				   ,[fBnfCot]
				   ,[fNoCESGCotBefore98]
				   ,[fNoCESGCot98AndAfter]
				   ,[fCESGCot]
				   ,[fCESG]
				   ,[fCLB]
				   ,[fAIP]
				   ,[fMarketValue]
				   ,[bPendingApplication])
			 VALUES
				   (@iID_OPER_TIN
				   ,@ExternalPlanID_Cedant
				   ,1
				   ,Upper(@vcConventionNoCedant)
				   ,@dtDateVigueur_Cedant
				   ,4
				   ,0
				   ,1
				   ,0
				   ,0
				   ,0
				   ,0
				   ,0
				   ,0
				   ,0
				   ,0
				   ,0
				   ,0
				   ,@CBQ_c+ @MMQ_c+@MIM_c+@ICQ_c+@IMQ_c+@III_c+@IIQ_c+@IQI_c
				   ,0)
		
		IF @CBQ_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_TIN
			,@iID_Convention_Cession
			,'CBQ'
			,@CBQ_c)	
			END

		IF @MMQ_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_TIN
			,@iID_Convention_Cession
			,'MMQ'
			,@MMQ_c)	
			END

		IF @MIM_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_TIN
			,@iID_Convention_Cession
			,'MIM'
			,@MIM_c)	
			END

		IF @ICQ_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_TIN
			,@iID_Convention_Cession
			,'ICQ'
			,@ICQ_c)	
			END

		IF @IMQ_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_TIN
			,@iID_Convention_Cession
			,'IMQ'
			,@IMQ_c)	
			END

		IF @III_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_TIN
			,@iID_Convention_Cession
			,'III'
			,@III_c)	
			END

		IF @IIQ_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_TIN
			,@iID_Convention_Cession
			,'IIQ'
			,@IIQ_c)	
			END

		IF @IQI_c <> 0
			BEGIN
			INSERT INTO [dbo].[Un_ConventionOper]
			([OperID]
			,[ConventionID]
			,[ConventionOperTypeID]
			,[ConventionOperAmount])
			VALUES
			(@iID_OPER_TIN
			,@iID_Convention_Cession
			,'IQI'
			,@IQI_c)	
			END
		
		INSERT INTO [dbo].[Un_TIO]
				   ([iOUTOperID]
				   ,[iTINOperID]
				   ,[iTFROperID])
			 VALUES
				   (@iID_OPER_OUT
				   ,@iID_OPER_TIN
				   ,NULL)
			
		delete from tblTEMP_TIOIQEE	
			
		set @cMessage = @cMessage +  'TIO créé.'
			
		END

	IF ltrim(rtrim(@cMessage)) = ''
		begin
		set @cMessage = @cMessage + 'Pour faire un TIO, inscrire des montants à transférer OU cocher "tous les soldes".'
		end

	return

	SELECT 
		cMessage = max(cMessage),
		ConventionNoCedant = max(ConventionNoCedant),
		ConventionNoCession = max(ConventionNoCession),
		SouscCedant = max(SouscCedant),
		SouscCession = max(SouscCession),
		CBQ_CD = sum(CBQ_CD),
		MMQ_CD = sum(MMQ_CD),
		MIM_CD = sum(MIM_CD),
		ICQ_CD = sum(ICQ_CD),
		IMQ_CD = sum(IMQ_CD),
		III_CD = sum(III_CD),
		IIQ_CD = sum(IIQ_CD),
		IQI_CD = sum(IQI_CD),
		
		CBQ_CS = sum(CBQ_CS),
		MMQ_CS = sum(MMQ_CS),
		MIM_CS = sum(MIM_CS),
		ICQ_CS = sum(ICQ_CS),
		IMQ_CS = sum(IMQ_CS),
		III_CS = sum(III_CS),
		IIQ_CS = sum(IIQ_CS),
		IQI_CS = sum(IQI_CS)
	FROM (

		SELECT 
			cMessage = NULL,
			ConventionNoCedant = c.ConventionNo,
			ConventionNoCession = NULL,
			SouscCedant = @vcSousc_Cedant,
			SouscCession = NULL,
			CBQ_CD = sum(CASE WHEN co.ConventionOperTypeID = 'CBQ' THEN co.ConventionOperAmount ELSE 0 END),
			MMQ_CD = sum(CASE WHEN co.ConventionOperTypeID = 'MMQ' THEN co.ConventionOperAmount ELSE 0 END),
			MIM_CD = sum(CASE WHEN co.ConventionOperTypeID = 'MIM' THEN co.ConventionOperAmount ELSE 0 END),
			ICQ_CD = sum(CASE WHEN co.ConventionOperTypeID = 'ICQ' THEN co.ConventionOperAmount ELSE 0 END),
			IMQ_CD = sum(CASE WHEN co.ConventionOperTypeID = 'IMQ' THEN co.ConventionOperAmount ELSE 0 END),
			III_CD = sum(CASE WHEN co.ConventionOperTypeID = 'III' THEN co.ConventionOperAmount ELSE 0 END),
			IIQ_CD = sum(CASE WHEN co.ConventionOperTypeID = 'IIQ' THEN co.ConventionOperAmount ELSE 0 END),
			IQI_CD = sum(CASE WHEN co.ConventionOperTypeID = 'IQI' THEN co.ConventionOperAmount ELSE 0 END),
			
			CBQ_CS = 0,
			MMQ_CS = 0,
			MIM_CS = 0,
			ICQ_CS = 0,
			IMQ_CS = 0,
			III_CS = 0,
			IIQ_CS = 0,
			IQI_CS = 0
			
		from 
			Un_Convention c
			JOIN Un_ConventionOper co ON c.Conventionid = co.ConventionID
			JOIN Un_Oper o ON co.OperID = o.OperID
		WHERE 
			c.ConventionNo = @vcConventionNoCedant
		GROUP by 
			c.ConventionNo

		UNION ALL
		
		SELECT 
			cMessage = NULL,
			ConventionNoCedant = null,
			ConventionNoCession = c.ConventionNo,
			SouscCedant = null,
			SouscCession = @vcSousc_Cession,
			
			CBQ_CD = 0,
			MMQ_CD = 0,
			MIM_CD = 0,
			ICQ_CD = 0,
			IMQ_CD = 0,
			III_CD = 0,
			IIQ_CD = 0,
			IQI_CD = 0,		
			
			CBQ_CS = sum(CASE WHEN co.ConventionOperTypeID = 'CBQ' THEN co.ConventionOperAmount ELSE 0 END),
			MMQ_CS = sum(CASE WHEN co.ConventionOperTypeID = 'MMQ' THEN co.ConventionOperAmount ELSE 0 END),
			MIM_CS = sum(CASE WHEN co.ConventionOperTypeID = 'MIM' THEN co.ConventionOperAmount ELSE 0 END),
			ICQ_CS = sum(CASE WHEN co.ConventionOperTypeID = 'ICQ' THEN co.ConventionOperAmount ELSE 0 END),
			IMQ_CS = sum(CASE WHEN co.ConventionOperTypeID = 'IMQ' THEN co.ConventionOperAmount ELSE 0 END),
			III_CS = sum(CASE WHEN co.ConventionOperTypeID = 'III' THEN co.ConventionOperAmount ELSE 0 END),
			IIQ_CS = sum(CASE WHEN co.ConventionOperTypeID = 'IIQ' THEN co.ConventionOperAmount ELSE 0 END),
			IQI_CS = sum(CASE WHEN co.ConventionOperTypeID = 'IQI' THEN co.ConventionOperAmount ELSE 0 END)
		from 
			Un_Convention c
			LEFT JOIN Un_ConventionOper co ON c.Conventionid = co.ConventionID
			LEFT JOIN Un_Oper o ON co.OperID = o.OperID
		WHERE 
			c.ConventionNo = @vcConventionNoCession
		GROUP by 
			c.ConventionNo

		union ALL
		
		SELECT 
			cMessage = @cMessage,
			ConventionNoCedant = NULL,
			ConventionNoCession = NULL,
			SouscCedant = NULL,
			SouscCession = NULL,
			CBQ_CD = 0,
			MMQ_CD = 0,
			MIM_CD = 0,
			ICQ_CD = 0,
			IMQ_CD = 0,
			III_CD = 0,
			IIQ_CD = 0,
			IQI_CD = 0,
			
			CBQ_CS = 0,
			MMQ_CS = 0,
			MIM_CS = 0,
			ICQ_CS = 0,
			IMQ_CS = 0,
			III_CS = 0,
			IIQ_CS = 0,
			IQI_CS = 0

		)V
	
END



