/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************    */

/****************************************************************************************************
Copyrights (c) 2013 Gestion Universitas inc.

Code du service		: psTEMP_GenererPAE_IQEE
Nom du service		: Création de PAE d'IQEE
But 				: Créer un PAE d'IQEE dans une convention individuelle. Car cela n'est pas prévu dans Uniaccès
Facette				: TEMP

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-08-19		Donald Huppé						Création du service		
		2014-03-26		Donald Huppé						Correction de l'appel : exec SL_UN_InfoForNewPAEInd @ConventionID --418113
		2014-05-28		Donald Huppé						Cet outil n''est plus autorisé
		2017-09-27      Pierre-Luc Simard                   Deprecated - Cette procédure n'est plus utilisée
   
exec psTEMP_GenererPAE_IQEE_Individuel 
	@vcUserID = 'DHUPPE', 
	@vcConventionNo= 'I-20121122002',
	@dtDatePAE = '2013-09-03',
	@bFaireLePAE  = 1
	
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_GenererPAE_IQEE_Individuel] 

(
	@vcUserID varchar(255),
	@vcConventionNo VARCHAR(15),
	@dtDatePAE datetime,
	@bFaireLePAE bit = 0
)
AS
BEGIN
    
    SELECT 1/0
    /*
	Declare 
		@ConnectID int,
		@ConventionID int,
		@ConventionNO varchar(15),
		@PlanID int,
		@Souscripteur varchar(150),
		@CBQ MONEY,	
		@MMQ MONEY,
		@MIM MONEY,
		@ICQ MONEY,
		@IMQ MONEY,
		@III MONEY,
		@IIQ MONEY,
		@IQI MONEY,
		@SoldeRendAutreIQEE money,
		@SoldePCEE money,
		@OperNewPAEValid int,
		@VL_UN_OperPAE_IU int,
		@cMessage varchar(500),
		@FairePAE int,
		
		@ScholarshipPmtID INT,
		@OperID INT,
		@ScholarshipID INT,
		@CollegeID INT,
		@ProgramID INT,
		@StudyStart DATETIME,
		@ProgramLength INT,
		@ProgramYear INT,
		@RegistrationProof BIT,
		@SchoolReport BIT,
		@EligibilityQty INT,
		@CaseOfJanuary BIT,
		@EligibilityConditionID varCHAR(3),
		@IDConditionEligibleBenef varCHAR(3)

	CREATE TABLE #WngAndErr(
		Code VARCHAR(5),
		Info1 VARCHAR(100),
		Info2 VARCHAR(100),
		Info3 VARCHAR(100)
	)

	create table #InfoForNewPAEInd (
			ConventionID INT,
			CollegeID INT,
			CollegeName varchar(75),
			EligibilityConditionID CHAR(3),
			ProgramID INT,
			ProgramDesc  varchar(75),
			StudyStart DATETIME,
			ProgramLength INT,
			ProgramYear INT,
			RegistrationProof BIT,
			SchoolReport BIT,
			EligibilityQty INT,
			CaseOfJanuary BIT,
			Interest money,
			fTINInt money,
			fCESGInt money,
			fTINPCEEInt money,
			fACESGInt money,
			fCLBInt money,
			fCESG money,
			fACESG money,
			fCLB money,
			IDConditionEligibleBenef CHAR(3))

	if not exists (select 1 from sysobjects where Name = 'tblTEMP_PAEIQEE')
		begin
		create table tblTEMP_PAEIQEE (conventionno varchar(20), DateInsert datetime) --drop table tblTEMP_PAEIQEE
		end

	-- On laisse un trace dans une table lors d'une demande de création de PAE. Afin de vérifier ultérieurement, lors d'une demande de création de PAE, 
	-- qu'une demande de rapport a déjà été faite sans demande.
	IF 	(@bFaireLePAE = 0)
		begin
		delete from tblTEMP_PAEIQEE where conventionno <> @vcConventionNo -- select * from tblTEMP_TIOIQEE
		insert into tblTEMP_PAEIQEE VALUES (@vcConventionNo, getdate())
		end

	set @cMessage = ''
	set @FairePAE = 0

	-- #1 Pour avoir les montants à mettre dans le PAE
	-- et vérifier les soldes négatif
	select 
		@ConventionID = C.conventionid,	
		@ConventionNO = C.ConventionNO,
		@PlanID = c.planID,	
		@Souscripteur = hs.FirstName + ' ' + hs.LastName,
		@CBQ = sum(case when co.conventionopertypeid = 'CBQ' then ConventionOperAmount else 0 end ),
		@MMQ = sum(case when co.conventionopertypeid = 'MMQ' then ConventionOperAmount else 0 end ),
		
		@ICQ = sum(case when co.conventionopertypeid = 'ICQ' then ConventionOperAmount else 0 end ),
		@III = sum(case when co.conventionopertypeid = 'III' then ConventionOperAmount else 0 end ),
		@IIQ = sum(case when co.conventionopertypeid = 'IIQ' then ConventionOperAmount else 0 end ),
		@IMQ = sum(case when co.conventionopertypeid = 'IMQ' then ConventionOperAmount else 0 end ),
		@MIM = sum(case when co.conventionopertypeid = 'MIM' then ConventionOperAmount else 0 end ),
		@IQI = sum(case when co.conventionopertypeid = 'IQI' then ConventionOperAmount else 0 end )
	from 
		un_conventionoper co
		join Un_Oper o ON co.OperID = o.OperID
		JOIN dbo.Un_Convention c on co.conventionid = c.conventionid
		JOIN dbo.Mo_Human hs ON c.SubscriberID = hs.humanID
		JOIN Un_Plan P ON c.PlanID = P.PlanID
	where c.ConventionNo = @vcConventionNo
	group by 
		C.conventionid,
		C.ConventionNO,
		c.planID,	
		hs.FirstName + ' ' + hs.LastName

--@SoldeAutreIQEE	
	
	select 
		@SoldeRendAutreIQEE = sum(ConventionOperAmount )
	from 
		un_conventionoper co
		join Un_Oper o ON co.OperID = o.OperID
		JOIN dbo.Un_Convention c on co.conventionid = c.conventionid
		JOIN dbo.Mo_Human hs ON c.SubscriberID = hs.humanID
		JOIN Un_Plan P ON c.PlanID = P.PlanID
	where c.ConventionNo = @vcConventionNo
	and co.ConventionOpertypeID NOT IN ('CBQ','MMQ','ICQ','III','IIQ','IMQ','MIM','IQI')
	
	select 
		@SoldePCEE = sum(fcesg) + sum(facesg) + sum(fCLB)
	from un_cesp ce
	JOIN dbo.Un_Convention c on ce.conventionid = c.conventionid
	where c.ConventionNo = @vcConventionNo

	-- #2 Pour avoir un connectID récent du user qui fait la demande.  à mettre dans le blob
	SELECT @ConnectID = MAX(ct.ConnectID)
	from Mo_User u
	join Mo_Connect ct ON u.UserID = ct.UserID
	WHERE u.LoginNameID = REPLACE(@vcUserID,'UNIVERSITAS\','')

	-- #3 valide si Preuve d’inscription incomplète
	-- valide si Le bénéficiaire de la convention sera sans NAS et citoyen canadien.

	exec @OperNewPAEValid =  Vl_UN_OperNewPAE @ConventionID -- 418113 -- conventionid

	IF  
		(@bFaireLePAE = 1  AND (@CBQ>=0 AND @MMQ>=0 AND @MIM>=0 AND @ICQ>=0 AND @IMQ>=0 AND @III>=0 AND @IIQ>=0 AND @IQI>=0))
		BEGIN
		set @FairePAE = 1
		END

	IF  (isnull(@ConventionID,0) = 0)
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Erreur : Convention inconnue.'
		set @FairePAE = 0
		END

	IF  (isnull(@PlanID,0) <> 4) and isnull(@ConventionID,0) <> 0
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Erreur : Le régime de la convention doit être INDIVIDUEL.'
		set @FairePAE = 0
		END

	IF  (LEFT(CONVERT(VARCHAR, @dtDatePAE, 120), 10) < LEFT(CONVERT(VARCHAR, getdate(), 120), 10))
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Erreur : La date du PAE doit être égale ou supérieure à la date du jour.'
		set @FairePAE = 0
		END

	IF  ((@CBQ<0 OR @MMQ<0 OR @MIM<0 OR @ICQ<0 OR @IMQ<0 OR @III<0 OR @IIQ<0 OR @IQI<0))
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Erreur : Soldes négatifs à régler d’abord.'
		set @FairePAE = 0
		END

	IF  
		(@CBQ + @MMQ + @MIM + @ICQ + @IMQ + @III + @IIQ + @IQI) = 0 
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Aucun montant disponible pour un PAE.'
		set @FairePAE = 0
		END

	IF  (@SoldeRendAutreIQEE > 0 OR @SoldePCEE > 0)
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Erreur : Il existe des soldes autres que IQEE dans la convention. Utilisez UniAcces pour faire le PAE.'
		set @FairePAE = 0
		END

	IF  (@ConnectID is NULL)
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Erreur : ConnectID non déterminé pour cet usager.'
		set @FairePAE = 0
		END

	IF  (@OperNewPAEValid < 0)
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Preuve d’inscription incomplète.'
		set @FairePAE = 0
		END

	IF  (@bFaireLePAE <> 0)
		AND not exists (SELECT 1 from tblTEMP_PAEIQEE where conventionno = @vcConventionNo) 
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Attention. Demandez d''abord les soldes sans demander un PAE.'
		set @FairePAE = 0
		END

	if @vcUserID not like '%dhuppe%' and @vcUserID not like '%bjeannotte%'  and @vcUserID not like '%mhpoirier%'
		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Usager non autorisé : ' + @vcUserID
		set @FairePAE = 0
		end

	if @bFaireLePAE = 0 and ltrim(rtrim(@cMessage)) = ''
		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Vous pouvez faire le PAE.'
		set @FairePAE = 0
		end

		----------- N'est plus autorisé depuis la refonte 
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Cet outil n''est plus autorisé.'
		set @FairePAE = 0

	if @bFaireLePAE = 1 and @FairePAE = 1
		begin

		-- texte à mettre dans le blob pour la ligne Un_ScholarshipPmt
		insert INTO #InfoForNewPAEInd
		exec SL_UN_InfoForNewPAEInd @ConventionID --418113
		select 
			@CollegeID = CollegeID ,
			@ProgramID = ProgramID ,
			@StudyStart = StudyStart ,
			@ProgramLength = ProgramLength ,
			@ProgramYear = ProgramYear ,
			@RegistrationProof = RegistrationProof ,
			@SchoolReport = SchoolReport ,
			@EligibilityQty = EligibilityQty ,
			@CaseOfJanuary = CaseOfJanuary ,
			@IDConditionEligibleBenef = replace(isnull(IDConditionEligibleBenef,''),' ','')
		from #InfoForNewPAEInd
		
		-- #4 construire le blob ----------------------------------------
		DECLARE 
		@BlobID int,
		@BlobParam varchar(2000),
		@iResult INTEGER
	
		-- texte du blob
		
		-- Ligne Un_Oper : mettre 0, 0, ConnectID, PAE, Date du PAE
		-- Ligne Un_ScholarshipPmt : mettre le résultat de SL_UN_InfoForNewPAEInd
		-- Ligne Un_ConventionOper : mettre 1, 0, 0, conventionid, ConventionOperTypeID, solde de ConventionOperAmount
				-- !!!!! Attention, mettre un point à la décimale du montant dans Un_ConventionOper !!!!!!!!!!!
/*
		SET @BlobParam = 'Un_Oper;0;0;1868060;PAE;2013-06-25;
		Un_ScholarshipPmt;0;0;0;4975;219;2013-09-01;2;1;1;1;0;0;;
		Un_ConventionOper;1;0;0;418113;CBQ;-446.80;' + CHAR(13)+CHAR(10) -- ajouter cette ligne pour chaque compte à mettre dans le PAE
*/
		--select @ConnectID
		--select '@IDConditionEligibleBenef',@IDConditionEligibleBenef

		SET @BlobParam = 
			'Un_Oper;0;0;' + 
					CAST(@ConnectID AS varchar) 
					+ ';PAE;' + LEFT(CONVERT(VARCHAR, @dtDatePAE, 120), 10) + ';' + CHAR(13)+CHAR(10) +
			'Un_ScholarshipPmt;0;0;0;' 
					+ CAST(@CollegeID AS varchar) + ';' 
					+ CAST(@ProgramID AS varchar) + ';' 
					+ LEFT(CONVERT(VARCHAR, @StudyStart, 120), 10) + ';'
					+ CAST(@ProgramLength  AS varchar) + ';' 
					+ CAST(@ProgramYear  AS varchar) + ';' 
					+ CAST(@RegistrationProof AS varchar) + ';' 
					+ CAST(@SchoolReport  AS varchar) + ';' 
					+ CAST(@EligibilityQty  AS varchar) + ';' 
					+ CAST(@CaseOfJanuary  AS varchar) + ';' 
					+ @IDConditionEligibleBenef + ';' + CHAR(13)+CHAR(10)

		IF @CBQ > 0 
			SET @BlobParam = @BlobParam + 'Un_ConventionOper;1;0;0;' + CAST(@ConventionID AS varchar) + ';CBQ;-' + CAST(@CBQ AS varchar) + ';' + CHAR(13)+CHAR(10) 

		IF @MMQ > 0 
			SET @BlobParam = @BlobParam + 'Un_ConventionOper;1;0;0;' + CAST(@ConventionID AS varchar) + ';MMQ;-' + CAST(@MMQ AS varchar) + ';' + CHAR(13)+CHAR(10) 
			
		IF @MIM > 0 
			SET @BlobParam = @BlobParam + 'Un_ConventionOper;1;0;0;' + CAST(@ConventionID AS varchar) + ';MIM;-' + CAST(@MIM AS varchar) + ';' + CHAR(13)+CHAR(10) 
			
		IF @ICQ > 0 
			SET @BlobParam = @BlobParam + 'Un_ConventionOper;1;0;0;' + CAST(@ConventionID AS varchar) + ';ICQ;-' + CAST(@ICQ AS varchar) + ';' + CHAR(13)+CHAR(10) 
			
		IF @IMQ > 0 
			SET @BlobParam = @BlobParam + 'Un_ConventionOper;1;0;0;' + CAST(@ConventionID AS varchar) + ';IMQ;-' + CAST(@IMQ AS varchar) + ';' + CHAR(13)+CHAR(10) 
		
		IF @III > 0 
			SET @BlobParam = @BlobParam + 'Un_ConventionOper;1;0;0;' + CAST(@ConventionID AS varchar) + ';III;-' + CAST(@III AS varchar) + ';' + CHAR(13)+CHAR(10) 

		IF @IIQ > 0 
			SET @BlobParam = @BlobParam + 'Un_ConventionOper;1;0;0;' + CAST(@ConventionID AS varchar) + ';IIQ;-' + CAST(@IIQ AS varchar) + ';' + CHAR(13)+CHAR(10) 

		IF @IQI > 0 
			SET @BlobParam = @BlobParam + 'Un_ConventionOper;1;0;0;' + CAST(@ConventionID AS varchar) + ';IQI;-' + CAST(@IQI AS varchar) + ';' + CHAR(13)+CHAR(10) 

		SET @BlobParam = ltrim(rtrim(@BlobParam)) + CHAR(13)+CHAR(10)

		--select @BlobParam
		--return

		exec @BlobID = IU_CRI_Blob 0,@BlobParam
		
		-- Fin #4 --------------------------------------------------

		-- #5 valider le pae avec le blob

		--select '@BlobID',@BlobID

		insert into #WngAndErr
		exec @VL_UN_OperPAE_IU =  VL_UN_OperPAE_IU @BlobID

		--select @VL_UN_OperPAE_IU
		
		--return

		IF  (@VL_UN_OperPAE_IU <= 0)
			BEGIN
			set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Erreur : blob de PAE invalide. (' + CAST(@VL_UN_OperPAE_IU AS varchar) + ')'
			set @FairePAE = 0
			END

		-- #6 créer le PAE
		IF  (@VL_UN_OperPAE_IU > 0)
			BEGIN
			EXEC @iResult = IU_UN_OperPAE 2, @BlobID
			end	

		IF  (@iResult <= 0)
			BEGIN
			set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Erreur : La création du PAE a échoué. (' + CAST(@VL_UN_OperPAE_IU AS varchar) + ')'
			END
		else
			BEGIN
			set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'PAE créé avec Succès.'
			END		
		
		END --if @FairePAE = 1
	
	-- On affiche les soldes et le message
	SELECT	
		cMessage = MAX(cMessage),
		ConventionNO = MAX(ConventionNO),
		Souscripteur = MAX(Souscripteur),
		CBQ = MAX(CBQ),
		MMQ = MAX(MMQ),
		
		ICQ = MAX(ICQ),
		III = MAX(III),
		IIQ = MAX(IIQ),
		IMQ = MAX(IMQ),
		MIM = MAX(MIM),
		IQI = MAX(IQI)
	FROM (
		-- Solde
		select 
			cMessage = null,
			C.ConventionNO,
			Souscripteur = hs.FirstName + ' ' + hs.LastName,
			CBQ = sum(case when co.conventionopertypeid = 'CBQ' then ConventionOperAmount else 0 end ),
			MMQ = sum(case when co.conventionopertypeid = 'MMQ' then ConventionOperAmount else 0 end ),
			
			ICQ = sum(case when co.conventionopertypeid = 'ICQ' then ConventionOperAmount else 0 end ),
			III = sum(case when co.conventionopertypeid = 'III' then ConventionOperAmount else 0 end ),
			IIQ = sum(case when co.conventionopertypeid = 'IIQ' then ConventionOperAmount else 0 end ),
			IMQ = sum(case when co.conventionopertypeid = 'IMQ' then ConventionOperAmount else 0 end ),
			MIM = sum(case when co.conventionopertypeid = 'MIM' then ConventionOperAmount else 0 end ),
			IQI = sum(case when co.conventionopertypeid = 'IQI' then ConventionOperAmount else 0 end )
		from 
			un_conventionoper co
			join Un_Oper o ON co.OperID = o.OperID
			JOIN dbo.Un_Convention c on co.conventionid = c.conventionid
			JOIN dbo.Mo_Human hs ON c.SubscriberID = hs.humanID
			JOIN Un_Plan P ON c.PlanID = P.PlanID
		where c.ConventionNo = @vcConventionNo
		group by 
			C.conventionNo,
			hs.FirstName + ' ' + hs.LastName
		
		UNION
		
		-- Message
		select 
			cMessage = @cMessage,
			ConventionNO = NULL,
			Souscripteur = NULL,
			CBQ = NULL,
			MMQ = NULL,
			
			ICQ = NULL,
			III = NULL,
			IIQ = NULL,
			IMQ = NULL,
			MIM = NULL,
			IQI = NULL
		) V
        */
end