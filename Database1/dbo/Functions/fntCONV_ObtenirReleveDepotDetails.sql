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
Code de service		:		dbo.fnCONV_ObtenirReleveDepotDetails
Nom du service		:		Obtenir le détails du relevé de dépôt
But					:		Récupérer le détails du relevé de dépôt
Facette				:		P171U
Reférence			:		Relevé de dépôt
Parametres d'entrée :	Parametres					Description                              Obligatoir
                        ----------                  ----------------                         --------------                       
                        iIdConvention	            Identifiant unique de la convention      Oui
						dtDateDebut	                Date du début du relevé des cotisations
						dtDateFin	                Date de fin du relevé des cotisations

Exemple d'appel:
				SELECT * FROM dbo.fntCONV_ObtenirReleveDepotDetails(350510,'2010-01-01','2010-12-31')
				
Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
                       
Historique des modifications :
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-01-20					Fatiha Araar							Création de la fonction           
						2009-02-19					Jean-Francois Arial						Détailler le SCEE, SCEE+ et le BEC par transaction
						2009-02-24					Dan Trifan								Regrupemment par nb payements (1 ou plus que 1 par année)
																							Détailler le SCEE, SCEE+ et le BEC par transaction pour PAE, OUT, TIN
						2008-03-05					Dan Trifan								Somme NFS avec CPA non conditionnel
						2008-03-11					Dan Trifan								Somme TFR dans TIN avec noconvention pour le TIN au lieu de vcCompanie
						2009-04-21					Jean-François Gauthier					Modif. pour la sommarisation des TRA annuels
						2009-04-22					Jean-François Gauthier					Modif. pour la somme des TRA : 
																										si TRA annuels seulement, ils sont sommées à part sur la ligne L80
																										si TRA mensuels, alors on les sommes avec les CPA en incluant les TRA Annuels
						2009-05-02					Jean-François Gauthier					Modif. pour traiter les PAE	à part dans un select ajouter en UNION
						2009-05-05					Jean-François Gauthier					Refonte de la requête concernant les PAE afin de les afficher sur 2 lignes					
						2009-09-10					Jean-François Gauthier					Élimination d'une SUM sur iNombrePayement
						2009-10-02					Jean-François Gauthier					Correction d'un paramètre de code d'opération
						2009-11-05					Jean-François Gauthier					Appel de la fonction fntOPER_ObtenirCotisationFraisConvention avec le paramètre 'E'
																							Retour de la date effective au lieu de la date d'opération
						2009-11-16					Jean-François Gauthier					Remise en place d'un MAX en remplace du SUM sur iNombrePayement enlevé le 2009-09-10
						2010-03-12					Jean-François Gauthier					Modification de l'appel à fntOPER_ObtenirCotisationFraisConvention
						2010-07-07					Jean-François Gauthier					Ajout de la transaction RDI qui doit apparaître sur la ligne L01 comme le CPA, PRD ou CHQ
						2011-03-04					Jean-François Gauthier					Ajout du champ Iid_Oper en retour pour les opérations annuelles
						2011-03-08					Jean-François Gauthier					Ajout des intérêts TIN ITR dans les autres revenus
						2011-03-11					Jean-François Gauthier					Correction du calcul du montant @mIntPCEETIN (une valeur NULL causait un bug)
						2011-03-29					Jean-François Gauthier					Ajout de la variable @mIntPCEETINSansTFR pour calculer les intérêts TIN correctement
						2011-07-14					Frederick Thibault						Ajout RIM et TRI
						2011-09-30					Christian Chénard						Ajout de ALL à UNION dans la requête "WITH DepotDetails AS" afin d'inclure tous les enregistrements retournés par les sous-requêtes
						2011-11-17					Radu Trandafir							Corrections 
						2011-12-09                  Mbaye Diakhate                          Ajout de la variable @mIntPCEETINDiffere pour les interêts TIN dont le transfert est anti-daté (effectiveDate < OperDate)
						2013-02-22					Pierre-Luc Simard						Correction au niveau du ISNULL du champ @mIntAutreRev
																							Correction au niveau du PAE pour le champ mIntAutreRev
																							Correction au niveau du champ mPAE pour les OUT (T-20090501041)
                        2017-09-27                  Pierre-Luc Simard                       Deprecated - Cette procédure n'est plus utilisée
																			
  ****************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirReleveDepotDetails] 
(
    @iIdConvention int, 
    @dtDateDebut datetime, 
    @dtDateFin datetime
)
RETURNS @tReleveDepotDetails table
(
    iIDConvention int NULL, 
    mQuantiteUnite money NULL, 
    mFraisCotisation money NULL, 
    mFrais money NULL, 
    mSCEE money NULL, 
    mIntSCEE money NULL, 
    mSCEESup money NULL, 
    mIntSCEESup money NULL, 
    mBec money NULL, 
    mIntBEC money NULL, 
    mIQEERio money NULL, 
    mPAE money NULL, 
    mIntPAE money NULL, 
    dtDateOperation datetime NULL, 
    vcTypeOperation char(3) NULL, 
    vcCompagnie varchar(200) NULL, 
    mAutreRev money NULL, 
    mIntAutreRev money NULL, 
    vcTypeDonnee char(1) NULL, 
    iPayementParAnnee int NULL, 
    iNombrePayement int NULL, 
    iIDOper int NULL
)
AS
BEGIN

    INSERT INTO @tReleveDepotDetails
            (iIDConvention ,
             mQuantiteUnite ,
             mFraisCotisation ,
             mFrais ,
             mSCEE ,
             mIntSCEE ,
             mSCEESup ,
             mIntSCEESup ,
             mBec ,
             mIntBEC ,
             mIQEERio ,
             mPAE ,
             mIntPAE ,
             dtDateOperation ,
             vcTypeOperation ,
             vcCompagnie ,
             mAutreRev ,
             mIntAutreRev ,
             vcTypeDonnee ,
             iPayementParAnnee ,
             iNombrePayement ,
             iIDOper
            )
    VALUES
            (0 , -- iIDConvention - int
             NULL , -- mQuantiteUnite - money
             NULL , -- mFraisCotisation - money
             NULL , -- mFrais - money
             NULL , -- mSCEE - money
             NULL , -- mIntSCEE - money
             NULL , -- mSCEESup - money
             NULL , -- mIntSCEESup - money
             NULL , -- mBec - money
             NULL , -- mIntBEC - money
             NULL , -- mIQEERio - money
             NULL , -- mPAE - money
             NULL , -- mIntPAE - money
             GETDATE() , -- dtDateOperation - datetime
             '' , -- vcTypeOperation - char(3)
             '' , -- vcCompagnie - varchar(200)
             NULL , -- mAutreRev - money
             NULL , -- mIntAutreRev - money
             '' , -- vcTypeDonnee - char(1)
             0 , -- iPayementParAnnee - int
             0 , -- iNombrePayement - int
             0  -- iIDOper - int
            )
    
    RETURN 
    /*
    DECLARE @mQuantiteUnite		MONEY,
			@mSCEE				MONEY,
			@mSCEESup			MONEY,
			@mBec				MONEY,
			@mAutreRev			MONEY,
			@mIntAutreRev		MONEY,
			@mIntAutreRevTINDiffere MONEY, -- 2010-12-09: Mbaye Diakhate - Calcul des interets TIN dans le cas de transfert anti-daté (effectiveDate < OperDate)
			@mIntBEC			MONEY,
			@mIntSCEE			MONEY,
			@mIntSCEESup		MONEY,
			@mPAE				MONEY,
			@mIntPAE			MONEY,
			@iCount				INTEGER,
			@mIntPCEETIN		MONEY,
			@mIntPCEETINSansTFR	MONEY
		
	IF @dtDateDebut IS NULL 
		BEGIN
			SET @dtDateDebut = '1900/01/01'
		END

	--Radu Trandafir
	--SET @dtDateDebut = DATEADD(dd, 1, @dtDateDebut)

	IF @dtDateFin IS NULL 
		BEGIN
			SET @dtDateFin = GETDATE()
		END

	-- Montants des subventions
	-- JFA, DT Envoyé dans le détail pour PAE, OUT, TIN, Global pour le reste
	SELECT 
		@mSCEE		= SUM(fCESG + fCESGINT) ,
		@mSCEESup	= SUM(fACESG + fACESGINT),
		@mBec		= SUM(fCLB)

	FROM fntPCEE_ObtenirSubventionBons (@iIdConvention,@dtDateDebut,@dtDateFin) fOSB
	JOIN Un_Oper OP ON OP.OperID = fOSB.OperID
	WHERE OP.OperTypeID NOT IN ('RIO', 'RIM', 'TRI')
	
	SELECT 
		@mSCEE		= ISNULL(@mSCEE,0), 
		@mSCEESup	= ISNULL(@mSCEESup,0),  
		@mBec		= ISNULL(@mBec,0)

	-- Le nombre d'unité
	SELECT 
		@mQuantiteUnite  = ISNULL(SUM(UnitQty),0)
	FROM 
		dbo.fntCONV_ObtenirUnitesConvention(@iIdConvention,@dtDateDebut,@dtDateFin);

	-- Montant des intrêts PCEE TIN
	SELECT 
		@mIntPCEETIN = ISNULL(SUM(conventionOperAmount),0)
	FROM 
		fntOPER_ObtenirMontantConvention(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_PCEE_TIN');

	SELECT 
		@mIntPCEETIN = ISNULL(@mIntPCEETIN + ISNULL(SUM(conventionOperAmount),0),0)
	FROM 
		fntOPER_ObtenirMontantConvention(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_PCEE_TIN_TFR');

	-- Montant des intrêts mSCEE et mSCEE+
	SELECT 
		@mIntSCEE = ISNULL(SUM(conventionOperAmount),0)
	FROM 
		fntOPER_ObtenirMontantConvention(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_SCEE') f
	WHERE	NOT EXISTS(SELECT 1 FROM dbo.Un_CESP c WHERE f.iID_Oper = c.OperID)		-- 2011-03-04 : JFG
	AND		f.OperTypeID NOT IN ('RIO', 'RIM', 'TRI')
	--Radu Trandafir cas Bernard Légère(interets RIO compris dans incitatifs)
	--AND		f.OperTypeID NOT IN ('RIO', 'RIM', 'TRI')

	-- Montant des intrêts mSCEE et mSCEE+
	--SELECT 
	--	@mIntSCEESup = ISNULL(SUM(conventionOperAmount),0)
	--FROM  
	--	fntOPER_ObtenirMontantConvention(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_SCEE_SUP') f
	--WHERE	NOT EXISTS(SELECT 1 FROM dbo.Un_CESP c WHERE f.iID_Oper = c.OperID)		-- 2011-03-04 : JFG
	--Radu Trandafir
	--AND		f.OperTypeID NOT IN ('RIO', 'RIM', 'TRI')
	--Radu Trandafir
	SELECT 
		@mIntSCEESup = ISNULL(SUM(conventionOperAmount),0)
	FROM  
		dbo.fntOPER_ObtenirMontantConventionAvecRIO(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_SCEE_SUP') f
	WHERE	NOT EXISTS(SELECT 1 FROM dbo.Un_CESP c WHERE f.iID_Oper = c.OperID)		-- 2011-03-04 : JFG
	AND		f.OperTypeID NOT IN ('RIO', 'RIM', 'TRI')
	--Radu Trandafir cas Bernard Légère(interets RIO compris dans incitatifs)
	--AND		f.OperTypeID NOT IN ('RIO', 'RIM', 'TRI')

	-- Montant des intrêts BEC
	SELECT 
		@mIntBEC = ISNULL(SUM(conventionOperAmount),0)
	FROM
		fntOPER_ObtenirMontantConvention(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_BEC') f
	--Radu Trandafir
	--WHERE	f.OperTypeID NOT IN ('RIO', 'RIM', 'TRI')
	--Mbaye Diakhate  cas Isabelle Girard (I-20110617001)
	WHERE	f.OperTypeID NOT IN ('TRI')
	
	-- Montant PAE
	SELECT 
		@mPAE = ISNULL(SUM(conventionOperAmount),0)
	FROM 
		fntOPER_ObtenirMontantConvention(@iIdConvention,@dtDateDebut,@dtDateFin,'PAE');

	-- Interets sur le PAE
	SELECT 
		@mIntPAE = ISNULL(SUM(conventionOperAmount),0)
	FROM 
		fntOPER_ObtenirMontantConvention(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_PAE');

	-- Montant des intrêts Autres Revenus
	SELECT 
		@mIntAutreRev = ISNULL(SUM(conventionOperAmount),0)
	FROM 
		fntOPER_ObtenirMontantConvention(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_AUTREREV');

	-- 2011-03-08 : JFG : Ajout des intérêt TIN_ITR aux autres revenus
	SELECT 
		@mIntAutreRev = @mIntAutreRev + ISNULL(SUM(conventionOperAmount),0)
	FROM 
		fntOPER_ObtenirMontantConvention(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_PCEE_TIN_ITR');
		
	---- 2010-12-09: Mbaye Diakhate - Calcul des interets TIN dans le cas de transfert anti-daté (effectiveDate < OperDate)
 --   SELECT 
	--	@mIntAutreRevTINDiffere = ISNULL(SUM(ConventionOperAmount),0) 
	--FROM 
	--	fntOPER_ObtenirMontantConventionTINDiffere(@iIDConvention,@dtDateDebut,@dtDateFin);

	-- 2011-03-29 : JFG : Calcul des intérêt TIN sans TFR
	SELECT 
		@mIntPCEETINSansTFR = ISNULL(SUM(ConventionOperAmount),0) 
	FROM 
		fntOPER_ObtenirMontantConvention(@iIDConvention,@dtDateDebut,@dtDateFin,'INT_PCEE_TIN');
		
	-- 2011-07-22 - FT - Va chercher les montants totaux des des transfert (RIO - RIM - TRI) des subventions et leurs intérêts
	DECLARE  @CESG			MONEY
			,@CESGInt		MONEY
			,@ACESG			MONEY
			,@ACESGInt		MONEY
			,@CLB			MONEY
			,@CLBInt		MONEY
			,@IQEERio		MONEY
			,@AutreRev		MONEY
			--Mbaye Diakhate: pour corriger le cas s'il n'existe pas de cotisation dans le transfert cas Carl Tremblay T-20101101278
			,@CountCotRio   int 
			,@tmpOperTypeId Char(3)
			
	--Mbaye Diakhate: pour corriger le cas s'il n'existe pas de cotisation dans le transfert cas Carl Tremblay T-20101101278		
	Declare @tmpCotisationRio table (ConventionID		INTEGER
								,iIDConvention		INTEGER
								,Iid_Oper			INTEGER
								,vcTypeOperation	CHAR(3)
								,mCotisation		MONEY
								,mFrais				MONEY
								,dtDateOperation	DATETIME
								,vcCompagnie		VARCHAR(200)
								,mAutreRev			MONEY
								,iPayementParAnnee	INTEGER
								,iNombrePayement	INTEGER   
								 )
			
	SELECT	 @CESG	= SUM(CE.fCESG)
			,@ACESG	= SUM(CE.fACESG)
			,@CLB	= SUM(CE.fCLB)
	FROM Un_CESP CE
	JOIN Un_Oper OP ON OP.OperID = CE.OperID
	WHERE	OP.OperTypeID IN ('RIO', 'RIM', 'TRI')
	AND		CE.ConventionID = @iIDConvention
	AND		OP.OperDate BETWEEN @dtDateDebut AND @dtDateFin

	SELECT	 @CESGInt =	SUM(ISNULL(ConventionOperAmount, 0))
	FROM Un_ConventionOper CO
	JOIN Un_Oper OP ON OP.OperID = CO.OperID	
	WHERE	CO.ConventionID = @iIDConvention
	AND		OP.OperTypeID IN ('RIO', 'RIM', 'TRI')
	AND		OP.OperDate BETWEEN @dtDateDebut AND @dtDateFin
	AND		CO.ConventionOperTypeID = 'INS'

	SELECT	 @ACESGInt =	SUM(ISNULL(ConventionOperAmount, 0))
	FROM Un_ConventionOper CO
	JOIN Un_Oper OP ON OP.OperID = CO.OperID	
	WHERE	CO.ConventionID = @iIDConvention
	AND		OP.OperTypeID IN ('RIO', 'RIM', 'TRI')
	AND		OP.OperDate BETWEEN @dtDateDebut AND @dtDateFin
	AND		CO.ConventionOperTypeID = 'IS+' 

	SELECT	 @CLBInt =	SUM(ISNULL(ConventionOperAmount, 0))
	FROM Un_ConventionOper CO
	JOIN Un_Oper OP ON OP.OperID = CO.OperID	
	WHERE	CO.ConventionID = @iIDConvention
	AND		OP.OperTypeID IN ('RIO', 'RIM', 'TRI')
	AND		OP.OperDate BETWEEN @dtDateDebut AND @dtDateFin
	AND		CO.ConventionOperTypeID = 'IBC'
	
	-- IQEE RIO
	SELECT	 @IQEERio = SUM(ConventionOperAmount)
	
	FROM	Un_ConventionOPER		CO
	JOIN	Un_OPER					OP	ON CO.OperID = OP.OperID
	JOIN	tblOPER_OperationsRIO	RIO	ON	RIO.iID_Oper_RIO = OP.OperID 
	
	WHERE	CO.ConventionID = @iIDConvention
	AND		(OP.OperTypeID = 'RIO' OR OP.OperTypeID = 'RIM' OR OP.OperTypeID = 'TRI')
	AND		OP.OperDate BETWEEN @dtDateDebut AND @dtDateFin
	AND		CO.ConventionOperTypeId IN (SELECT cID_Type_Oper_Convention FROM fntOPER_ObtenirOperationsCategorie('OPER_RENDEMENTS_IQEE')
										UNION
										SELECT cID_Type_Oper_Convention FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_CREDITBASE')
										UNION
										SELECT cID_Type_Oper_Convention FROM fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_MAJORATION')
										)
	
	-- Autres Revenus RIO
	SELECT	@AutreRev = SUM(ConventionOperAmount)
	
	FROM	Un_ConventionOPER		CO
	JOIN	Un_OPER					OP	ON CO.OperID = OP.OperID
	JOIN	tblOPER_OperationsRIO	RIO	ON	RIO.iID_Oper_RIO = OP.OperID 
	
	WHERE	CO.ConventionID = @iIDConvention
	AND		(OP.OperTypeID = 'RIO' OR OP.OperTypeID = 'RIM' OR OP.OperTypeID = 'TRI')
	AND		OP.OperDate BETWEEN @dtDateDebut AND @dtDateFin
	AND		CO.ConventionOperTypeId IN ('ITR', 'IST', 'III');
	
	SELECT  @CountCotRio=count(*) 	
	FROM Un_Cotisation CT
	JOIN dbo.Un_Unit UN ON UN.UnitID = CT.UnitID
	JOIN Un_Oper OP ON OP.OperID = CT.OperID
	WHERE	UN.ConventionID = @iIdConvention
	AND		OP.OperDate BETWEEN @dtDateDebut AND @dtDateFin
	AND		OP.OperTypeID IN ('RIO', 'RIM', 'TRI');
	
	SELECT @tmpOperTypeId=(	SELECT	 DISTINCT opertypeid
							 FROM Un_CESP CE
							JOIN Un_Oper OP ON OP.OperID = CE.OperID
							WHERE	OP.OperTypeID IN ('RIO', 'RIM', 'TRI')
							AND		CE.ConventionID = @iIDConvention
							AND		OP.OperDate BETWEEN @dtDateDebut AND @dtDateFin
						UNION   
						   SELECT	 DISTINCT opertypeid
							FROM Un_ConventionOper CO
							JOIN Un_Oper OP ON OP.OperID = CO.OperID	
							WHERE	CO.ConventionID = @iIDConvention
							AND		OP.OperTypeID IN ('RIO', 'RIM', 'TRI')
							AND		OP.OperDate BETWEEN @dtDateDebut AND @dtDateFin
							AND		CO.ConventionOperTypeID in ('INS','IS+','IBC'))

    --Mbaye Diakhate: pour corriger le cas s'il n'existe pas de cotisation dans le transfert cas Carl Tremblay T-20101101278
    IF  @CountCotRio <> 0
    BEGIN
    INSERT INTO @tmpCotisationRio
    SELECT	 ConventionID		= UN.ConventionID
		    ,iIDConvention		= UN.ConventionID
		    ,Iid_Oper			= OP.OperID
		    ,vcTypeOperation	= OP.OperTypeId
		    ,mCotisation		= CT.Cotisation
		    ,mFrais				= CT.Fee
		    ,dtDateOperation	= OP.OperDate
		    ,vcCompagnie		= ''
		    ,mAutreRev			= 0
		    ,iPayementParAnnee	= 1
		    ,iNombrePayement	= 0
	    FROM Un_Cotisation CT
	    JOIN dbo.Un_Unit UN ON UN.UnitID = CT.UnitID
	    JOIN Un_Oper OP ON OP.OperID = CT.OperID
    	
	    WHERE	UN.ConventionID = @iIdConvention
	    AND		OP.OperDate BETWEEN @dtDateDebut AND @dtDateFin
	    AND		OP.OperTypeID IN ('RIO', 'RIM', 'TRI')
    END			
    ELSE IF  @CESG<>0 OR @CESGInt<>0 OR @ACESG<>0 OR @ACESGInt<>0  OR @CLB<>0 OR @CLBInt<>0	OR @IQEERio<>0
    BEGIN
    INSERT INTO @tmpCotisationRio
    SELECT	 ConventionID		= @iIdConvention
								    ,iIDConvention		= @iIdConvention
								    ,Iid_Oper			= NULL
								    ,vcTypeOperation	= @tmpOperTypeId
								    ,mCotisation		= 0
								    ,mFrais				= 0
								    ,dtDateOperation	= '1900-01-01'
								    ,vcCompagnie		= ''
								    ,mAutreRev			= 0
								    ,iPayementParAnnee	= 1
								    ,iNombrePayement	= 0				
    END;

	-- Using a CTE (Common table expression) pour preparer les critères de sommatization 
	WITH DepotDetails 
		(Iid_Oper, iIDConvention,
		mQuantiteUnite ,
		mFraisCotisation ,
		mFrais ,
		mSCEE ,
		mIntSCEE ,
		mSCEESup ,
		mIntSCEESup ,
		mBec ,
		mIntBEC ,
		mIQEERio,
		mPAE ,
	    mIntPAE,
		dtDateOperation ,
		vcTypeOperation ,
		vcCompagnie,
		mAutreRev ,
		mIntAutreRev ,
		vcTypeDonnee,
		iPayementParAnnee,
		iNombrePayement,
		vcLigneSommaire,
		iNbOper,
		iNbOperTRA12,
		iNbOperTRA12L1,
		iNbOperCPA12,
		UnBranch
		)
	AS
	(
		-- pour la non TIN,OUT: SCEE,SCEE+,BEC au noveau global
		SELECT CT.Iid_Oper, iIDConvention = @iIdConvention,
			mQuantiteUnite = @mQuantiteUnite,
			mFraisCotisation = ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0),
			mFrais = ISNULL(CT.mFrais,0),
			mSCEE = @mSCEE + @mIntPCEETIN,			
			mIntSCEE = @mIntSCEE,
			mSCEESup = @mSCEESup,
			mIntSCEESup = @mIntSCEESup,
			mBec = @mBec,
			mIntBEC =@mIntBEC,-- isnull(S1.fCLBFee,0) --Proposition Mbaye: pour le bon montant de l'interet		
			0, -- mIQEERio
			mPAE = @mPAE,
			mIntPAE = @mIntPAE,
			dtDateOperation = CT.dtDateEffective,
			vcTypeOperation = CT.vcTypeOperation,
			vcCompagnie =	CASE	WHEN vcTypeOperation = 'TIN' and io.iTINOperID IS NOT NULL THEN COALESCE(tin.vcOtherConventionNo,CT.vcCompagnie) 
									WHEN vcTypeOperation = 'TFR' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) < 0 THEN COALESCE(out.vcOtherConventionNo,CT.vcCompagnie) 
									WHEN vcTypeOperation = 'TFR' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) > 0 THEN COALESCE(tin.vcOtherConventionNo,CT.vcCompagnie) 
									WHEN vcTypeOperation = 'OUT' and io.iOUTOperID IS NOT NULL THEN COALESCE(out.vcOtherConventionNo,CT.vcCompagnie) 
									ELSE CT.vcCompagnie 
							END,
			mAutreRev = CT.mAutreRev,
			mIntAutreRev = @mIntAutreRev,
			'D' as vcTypeDonnee,
			iPayementParAnnee,
			MAX(iNombrePayement) OVER(PARTITION BY iIDConvention, vcTypeOperation, vcCompagnie) AS iNombrePayement,
		-- Determiner le code de sommaire
		CASE WHEN vcTypeOperation = 'CPA' THEN 'L01'
			 WHEN vcTypeOperation = 'PRD' AND iPayementParAnnee > 1 THEN 'L01'
			 WHEN vcTypeOperation = 'PRD' AND iPayementParAnnee = 1 THEN 'L02'
			 WHEN vcTypeOperation = 'CHQ' AND iPayementParAnnee > 1 THEN 'L01'
			 WHEN vcTypeOperation = 'CHQ' AND iPayementParAnnee = 1 THEN 'L03'
			 WHEN vcTypeOperation = 'RDI' AND iPayementParAnnee > 1 THEN 'L01'
			 WHEN vcTypeOperation = 'RDI' AND iPayementParAnnee = 1 THEN 'L04'
			 WHEN vcTypeOperation = 'RET' THEN 'L10'
			 WHEN vcTypeOperation = 'TFR' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) >=0 THEN 'L20'
			 WHEN vcTypeOperation = 'TFR' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) < 0 OR vcTypeOperation = 'RES' THEN 'L30'
			 WHEN vcTypeOperation = 'TIN' THEN 'L40'
			 WHEN vcTypeOperation = 'TIO' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) >=0 THEN 'L50' 
			 WHEN vcTypeOperation = 'TIO' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) < 0 THEN 'L60' 
			 WHEN vcTypeOperation = 'NSF' THEN 'L01'
			 WHEN (vcTypeOperation = 'TRA' OR vcTypeOperation = 'AJU') AND iPayementParAnnee > 1 THEN 'L01'
			 WHEN (vcTypeOperation = 'TRA' OR vcTypeOperation = 'AJU') AND iPayementParAnnee = 1 THEN 'L80'
			 ELSE 'L90'
		END AS vcLigneSommaire,
		-- compte le nombre effectiv de payements 
		COUNT(CT.Iid_Oper) OVER(PARTITION BY iIDConvention, vcTypeOperation, vcCompagnie) AS iNbOper,
		-- determiner pour la TRA et AJU arnuels si on les aditionne our non 
		SUM(CASE WHEN (vcTypeOperation = 'TRA' OR vcTypeOperation = 'AJU')
					  OR (vcTypeOperation = 'CPA' and iPayementParAnnee > 1 OR vcTypeOperation = 'NSF')
					THEN 1
					ELSE 0
			  END) OVER(PARTITION BY iIDConvention, vcTypeOperation, vcCompagnie) AS iNbOperTRA12,
		SUM(CASE WHEN (vcTypeOperation = 'TRA' OR vcTypeOperation = 'AJU' and iPayementParAnnee > 1)
					THEN 1
					ELSE 0
			  END) OVER(PARTITION BY iIDConvention, vcTypeOperation, vcCompagnie) AS iNbOperTRA12L1,
		SUM(CASE WHEN (vcTypeOperation = 'CPA' AND iPayementParAnnee > 1)
					THEN 1
					ELSE 0
			  END) OVER(PARTITION BY iIDConvention, vcCompagnie) AS iNbOperCPA12,
		'p1' as UnBranch
		FROM fntOPER_ObtenirCotisationFraisConvention (@iIdConvention,NULL,@dtDateDebut,@dtDateFin,'E',null,'D') CT
		LEFT JOIN (SELECT fCESG = SUM(CE.fCESG),	-- SCEE reçue (+), versée (-) ou remboursée (-)
						   fACESG = SUM(CE.fACESG),	-- SCEE+ reçue (+), versée (-) ou remboursée (-)
						   fCLB = SUM(CE.fCLB),		-- BEC reçu (+), versé (-) ou remboursé (-)	
						   --fCLBFee = isnull(SUM(CE.fCLBFee),0), --Proposition Mbaye: pour le bon montant de l'interet						   
						   ConventionID = C.ConventionID,
						 O.OperTypeID, o.OperID
					  FROM dbo.Un_Convention C
					  JOIN Un_CESP CE ON C.ConventionID = CE.ConventionID
					  JOIN Un_Oper O ON O.OperID = CE.OperID
					  WHERE C.ConventionID = @iIdConvention 
					  AND O.OperDate BETWEEN @dtDateDebut AND @dtDateFin
					  GROUP BY C.ConventionID, O.OperTypeID, o.OperID
					) AS S1 
			ON (S1.OPERID = CT.Iid_Oper)
		LEFT JOIN un_tio io ON	 CT.Iid_Oper = io.iTFROperID 	AND CT.vcTypeOperation ='TFR'
							  OR CT.Iid_Oper = io.iTINOperID 	AND CT.vcTypeOperation ='TIN'
							  OR CT.Iid_Oper = io.iOUTOperID 	AND CT.vcTypeOperation ='OUT'
		LEFT JOIN dbo.Un_TIN tin ON (io.iTINOperID = tin.OperID AND CT.vcTypeOperation = 'TFR'
										OR
									 CT.Iid_Oper = tin.OperID AND CT.vcTypeOperation = 'TIN')
		LEFT JOIN dbo.Un_OUT out ON (io.iOUTOperID = out.OperID AND CT.vcTypeOperation = 'TFR'
										OR
									 CT.Iid_Oper = out.OperID AND CT.vcTypeOperation = 'OUT')
		WHERE CT.vcTypeOperation <> 'TIN' AND CT.vcTypeOperation <> 'OUT' AND CT.vcTypeOperation <> 'RIO' AND CT.vcTypeOperation <> 'RIM' AND CT.vcTypeOperation <> 'TRI'
				AND CT.vcTypeOperation <> 'FCB'AND CT.vcTypeOperation <> 'RCB'
			  AND NOT (CT.vcTypeOperation = 'TFR' AND EXISTS (SELECT 1 
																FROM un_tio io		
																INNER JOIN Un_CESP CE ON CE.OperID = io.iTINOperID
																WHERE CT.Iid_Oper = io.iTFROperID
																		AND CE.ConventionID = @iIdConvention
																	UNION
																	SELECT 1 
																FROM un_tio io		
																INNER JOIN Un_CESP CE ON CE.OperID = io.iOUTOperID
																WHERE CT.Iid_Oper = io.iTFROperID
																		AND CE.ConventionID = @iIdConvention
															  )
					  )
    UNION ALL

		-- pour la non TIN,OUT: SCEE,SCEE+,BEC au niveaux detail
		SELECT CT.Iid_Oper, 
			iIDConvention = @iIdConvention,
			mQuantiteUnite = @mQuantiteUnite,
			mFraisCotisation = ISNULL(CT.mCotisation,0)+ ISNULL(CT.mFrais,0),
			mFrais = ISNULL(CT.mFrais,0),									
			--mSCEE = ISNULL(s2.fCESG,0) + ISNULL([INS],0) 
			--												+ ISNULL((	SELECT SUM(ConventionOperAmount) 
			--															FROM fntOPER_ObtenirMontantConvention(@iIDConvention,@dtDateDebut,@dtDateFin,'INT_PCEE_TIN_TFR') 
			--															WHERE iID_Oper=CT.IID_Oper) ,0) , 	
			mSCEE = CASE WHEN vcTypeOperation='TIN' THEN ISNULL(s2.fCESG,0) + ISNULL([INS],0) 
						 ELSE ISNULL(s2.fCESG,0) + ISNULL([INS],0) 
															+ ISNULL((	SELECT SUM(ConventionOperAmount) 
																		FROM fntOPER_ObtenirMontantConvention(@iIDConvention,@dtDateDebut,@dtDateFin,'INT_PCEE_TIN_TFR') 
																		WHERE iID_Oper=CT.IID_Oper) ,0) 
					 END, 												  
											  
			--Radu Trandafir 
			--mSCEE = ISNULL(s2.fCESG,0) + ISNULL([INS],0) 
			--												+ ISNULL((	SELECT SUM(ConventionOperAmount) 
			--															FROM fntOPER_ObtenirMontantConvention(@iIDConvention,@dtDateDebut,@dtDateFin,'INT_PCEE_TIN_TFR') 
			--															WHERE iID_Oper=CT.IID_Oper) + @mIntPCEETINSansTFR ,0)  
															
			mIntSCEE = ISNULL([INS],0),
			mSCEESup = ISNULL(s2.fACESG,0)+ISNULL([IS+],0),
			mIntSCEESup = ISNULL([IS+],0),
			--mBec = 0,
			mBec = ISNULL(S2.fCLB, 0),
			mIntBEC =  @mIntBEC, ---isnull(S2.fCLBFee,0)Proposition Mbaye: pour le bon montant de l'interet		
			mIQEERio = 0,
			mPAE = 0,--@mPAE,
			mIntPAE = @mIntPAE,
			dtDateOperation = CT.dtDateEffective,
			vcTypeOperation = CT.vcTypeOperation,
			vcCompagnie =	CASE	WHEN vcTypeOperation = 'TIN' and io.iTINOperID IS NOT NULL THEN COALESCE(tin.vcOtherConventionNo,CT.vcCompagnie) 
									WHEN vcTypeOperation = 'TFR' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) < 0 THEN COALESCE(out.vcOtherConventionNo,CT.vcCompagnie) 
									WHEN vcTypeOperation = 'TFR' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) > 0 THEN COALESCE(tin.vcOtherConventionNo,CT.vcCompagnie) 
									WHEN vcTypeOperation = 'OUT' and io.iOUTOperID IS NOT NULL THEN COALESCE(out.vcOtherConventionNo,CT.vcCompagnie) 
									ELSE CT.vcCompagnie 
							END,
			mAutreRev = CT.mAutreRev ,
			--mIntAutreRev = @mIntAutreRev,
			--mIntAutreRev = CASE WHEN vcTypeOperation = 'TIN' THEN @mIntAutreRev + ISNULL((	SELECT SUM(ConventionOperAmount) 
      	mIntAutreRev = CASE WHEN vcTypeOperation = 'TIN' THEN  ISNULL((	SELECT SUM(ConventionOperAmount) 
																		FROM fntOPER_ObtenirMontantConvention(@iIDConvention,@dtDateDebut,@dtDateFin,'INT_PCEE_TIN_TFR') 
																		WHERE iID_Oper=CT.IID_Oper) ,0) 
							    ELSE @mIntAutreRev											
							END,
			'D' as vcTypeDonnee,
			iPayementParAnnee,
			iNombrePayement,
		-- Determiner le code de sommaire
		CASE WHEN vcTypeOperation = 'CPA' THEN 'L01'
			 WHEN vcTypeOperation = 'PRD' AND iPayementParAnnee > 1 THEN 'L01'
			 WHEN vcTypeOperation = 'PRD' AND iPayementParAnnee = 1 THEN 'L02'
			 WHEN vcTypeOperation = 'CHQ' AND iPayementParAnnee > 1 THEN 'L01'
			 WHEN vcTypeOperation = 'CHQ' AND iPayementParAnnee = 1 THEN 'L03'
			 WHEN vcTypeOperation = 'RDI' AND iPayementParAnnee > 1 THEN 'L01'
			 WHEN vcTypeOperation = 'RDI' AND iPayementParAnnee = 1 THEN 'L04'
			 WHEN vcTypeOperation = 'RET' THEN 'L10'
			 WHEN vcTypeOperation = 'TFR' AND io.iTFROperID IS NOT NULL THEN 'L40'
			 WHEN vcTypeOperation = 'TFR' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) >=0 THEN 'L20'
			 WHEN vcTypeOperation = 'TFR' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) < 0 OR vcTypeOperation = 'RES' THEN 'L30'
			 WHEN vcTypeOperation = 'TIN' THEN 'L40'
			 WHEN vcTypeOperation = 'TIO' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) >=0 THEN 'L50' 
			 WHEN vcTypeOperation = 'TIO' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) < 0 THEN 'L60' 
			 WHEN vcTypeOperation = 'NSF' THEN 'L01'
			 WHEN (vcTypeOperation = 'TRA' OR vcTypeOperation = 'AJU') AND iPayementParAnnee > 1 THEN 'L01'
			 WHEN (vcTypeOperation = 'TRA' OR vcTypeOperation = 'AJU') AND iPayementParAnnee = 1 THEN 'L80'
			 ELSE 'L90'
		END AS vcLigneSommaire,
		-- compte le nombre effectiv de payements 
		COUNT(CT.Iid_Oper) OVER(PARTITION BY iIDConvention, vcTypeOperation, vcCompagnie) AS iNbOper,
		-- force 0 pour iNbOperTRA12
		0 as iNbOperTRA12,
		0 as iNbOperTRA12L1,
		0 as iNbOperCPA12,
		'p2' as UnBranch
		FROM fntOPER_ObtenirCotisationFraisConvention (@iIdConvention,NULL,@dtDateDebut,@dtDateFin,'E',null,'D') CT
		LEFT JOIN (select ConventionID, OperTypeID, 
							SUM(CASE ConventionOperTypeID WHEN 'INM' THEN ConventionOperAmount ELSE 0 END) AS "INM",
							SUM(CASE ConventionOperTypeID WHEN 'INS' THEN ConventionOperAmount ELSE 0 END) AS [INS],
							SUM(CASE ConventionOperTypeID WHEN 'IS+' THEN ConventionOperAmount ELSE 0 END) AS [IS+],
							CO.OperID
						FROM dbo.Un_ConventionOper CO
						JOIN dbo.Un_Oper O ON O.OperID=CO.OperID
							and O.OperDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())
						WHERE ConventionID=@iIdConvention 
						GROUP BY ConventionID,OperTypeID, CO.OperID
					) AS S1 
			ON (S1.OPERID = CT.Iid_Oper)
		LEFT JOIN (SELECT  fCESG = SUM(CE.fCESG),	-- SCEE reçue (+), versée (-) ou remboursée (-)
						   fACESG = SUM(CE.fACESG),	-- SCEE+ reçue (+), versée (-) ou remboursée (-)
						   fCLB = SUM(CE.fCLB),		-- BEC reçu (+), versé (-) ou remboursé (-)	
						--   fCLBFee=	isnull(SUM(CE.fCLBFee),0),	Proposition Mbaye: pour le bon montant de l'interet				   
						   ConventionID = C.ConventionID,
						 O.OperTypeID, o.OperID
					  FROM dbo.Un_Convention C
					  JOIN Un_CESP CE ON C.ConventionID = CE.ConventionID
					  JOIN Un_Oper O ON O.OperID = CE.OperID
					  WHERE C.ConventionID = @iIdConvention 
					  AND O.OperDate BETWEEN @dtDateDebut AND @dtDateFin
					  GROUP BY C.ConventionID, O.OperTypeID, o.OperID
					) AS S2 
			ON (S2.OPERID = CT.Iid_Oper)
		LEFT JOIN un_tio io ON	 CT.Iid_Oper = io.iTFROperID 	AND CT.vcTypeOperation ='TFR'
							  OR CT.Iid_Oper = io.iTINOperID 	AND CT.vcTypeOperation ='TIN'
							  OR CT.Iid_Oper = io.iOUTOperID 	AND CT.vcTypeOperation ='OUT'
		LEFT JOIN dbo.Un_TIN tin ON (io.iTINOperID = tin.OperID AND CT.vcTypeOperation = 'TFR'
										OR
									 CT.Iid_Oper = tin.OperID AND CT.vcTypeOperation = 'TIN')
		LEFT JOIN dbo.Un_OUT out ON (io.iOUTOperID = out.OperID AND CT.vcTypeOperation = 'TFR'
										OR
									 CT.Iid_Oper = out.OperID AND CT.vcTypeOperation = 'OUT')
		--WHERE	(CT.vcTypeOperation = 'TIN' OR CT.vcTypeOperation = 'OUT' OR CT.vcTypeOperation = 'RIO' OR CT.vcTypeOperation = 'RIM' OR CT.vcTypeOperation = 'TRI' OR
		WHERE	(CT.vcTypeOperation = 'TIN' OR CT.vcTypeOperation = 'OUT' OR
					(CT.vcTypeOperation = 'TFR' AND io.iTFROperID IS NOT NULL )
				)
			AND NOT
				(
					--CT.vcTypeOperation <> 'TIN' AND CT.vcTypeOperation <> 'OUT' AND CT.vcTypeOperation <> 'RIO' AND CT.vcTypeOperation <> 'RIM' AND CT.vcTypeOperation <> 'TRI' AND CT.vcTypeOperation <> 'PAE'
					CT.vcTypeOperation <> 'TIN' AND CT.vcTypeOperation <> 'OUT' AND CT.vcTypeOperation <> 'PAE'
					AND CT.vcTypeOperation <> 'FCB'AND CT.vcTypeOperation <> 'RCB'
					AND NOT (CT.vcTypeOperation = 'TFR' AND EXISTS (SELECT 1 
																FROM un_tio io		
																INNER JOIN Un_CESP CE ON CE.OperID = io.iTINOperID
																WHERE CT.Iid_Oper = io.iTFROperID
																		AND CE.ConventionID = @iIdConvention
																	UNION
																	SELECT 1 
																FROM un_tio io		
																INNER JOIN Un_CESP CE ON CE.OperID = io.iOUTOperID
																WHERE CT.Iid_Oper = io.iTFROperID
																		AND CE.ConventionID = @iIdConvention
															  )
							)
				)
    UNION ALL				

		SELECT		
				x.Iid_Oper, 
				iIDConvention		= @iIdConvention,
				mQuantiteUnite		= @mQuantiteUnite,
				mFraisCotisation	= SUM(x.mCotisation + x.mFrais),
				mFrais				= SUM(x.mFrais),
				mSCEE				= SUM(x.fCESG),
				mIntSCEE			= SUM(x.[INS]),
				mSCEESup			= SUM(x.fACESG + x.[IS+]),
				mIntSCEESup			= SUM(x.[IS+]),
				mBec				= 0,
				mIQEERio			= 0,
				mIntBEC				= @mIntBEC,--isnull(sum(x.fCLBFee),0), Proposition Mbaye: pour le bon montant de l'interet		
				mPAE				= (SELECT sum(fnt.ConventionOperAmount) FROM fntOPER_ObtenirMontantConvention(@iIdConvention, @dtDateDebut, @dtDateFin, 'PAE') fnt WHERE fnt.iID_OPER = x.Iid_Oper),
				mIntPAE				= (SELECT sum(fnt.ConventionOperAmount) FROM fntOPER_ObtenirMontantConvention(@iIdConvention, @dtDateDebut, @dtDateFin, 'INT_PAE') fnt WHERE fnt.iID_OPER = x.Iid_Oper),
				dtDateOperation		= x.dtDateOperation,
				vcTypeOperation		= x.vcTypeOperation,
				vcCompagnie			= x.vcCompagnie,
				mAutreRev			= SUM(x.mAutreRev),
				--mIntAutreRev		= @mIntAutreRev,
				--mIntAutreRev		= CASE WHEN vcTypeOperation='TIN' AND COTIS.EffectDate <> x.dtDateOperation then 0
        mIntAutreRev		= CASE WHEN vcTypeOperation='TIN' AND COTIS.EffectDate <> x.dtDateOperation then (SELECT ISNULL( ISNULL(SUM(conventionOperAmount),0),0) FROM fntOPER_ObtenirMontantConvention(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_PCEE_TIN_TFR')fnt WHERE fnt.iID_OPER = x.Iid_Oper)
								   WHEN vcTypeOperation='PAE' THEN (
																	SELECT ISNULL(fnt.IST,0) 
																	FROM (
																		SELECT iID_OPER = O.OperID, IST = SUM(CO.ConventionOperAmount) 
																		FROM Un_ConventionOper CO
																		JOIN Un_Oper O ON O.OperID = CO.OperID
																		WHERE O.OperTypeID = 'PAE' 
																			AND CO.conventionOperTypeID = 'IST'
																			AND (O.OperDate >= @dtDateDebut AND O.OperDate <= @dtDateFin)
																			AND CO.ConventionID  = @iIdConvention
																		GROUP BY O.OperID 
																	) fnt 
																	WHERE fnt.iID_OPER = x.Iid_Oper)
				                   ELSE @mIntAutreRev END,
				vcTypeDonnee		= 'D',
				iPayementParAnnee	= SUM(iPayementParAnnee),
				iNombrePayement		= SUM(iNombrePayement),
				vcLigneSommaire		= 'L90',
				iNbOper				= COUNT(x.Iid_Oper) OVER(PARTITION BY x.iIDConvention, x.vcTypeOperation, x.vcCompagnie), -- compte le nombre effectiv de payements 
				iNbOperTRA12		= 0,
				iNbOperTRA12L1		= 0,
				iNbOperCPA12		= 0,
				UnBranch			= 'p2'
		FROM
				(	SELECT  
							fCESG				= SUM(ISNULL(CE.fCESG,0)),	
							mPAE				= 0 ,
							fACESG				= SUM(ISNULL(CE.fACESG,0)),	
							fCLB				= SUM(ISNULL(CE.fCLB,0)),
							--fCLBFee             = SUM(ISNULL(CE.fCLBFee,0)),Proposition Mbaye: pour le bon montant de l'interet		
							fPG					= SUM(ISNULL(CE.fPG,0)),
							ConventionID		= C.ConventionID,
							iIDConvention		= C.ConventionID,
							Iid_Oper			= O.OperID,		
							vcTypeOperation		= O.OperTypeId,	
							mCotisation			= 0,
							mFrais				= 0,
							dtDateOperation		= O.OperDate,		
							[INS]				= 0,
							[IS+]				= 0,
							vcCompagnie			= '',
							mAutreRev			= 0,
							iPayementParAnnee	= 1,--(SELECT fnt.iPayementParAnnee	FROM fntOPER_ObtenirCotisationFraisConvention(C.ConventionID,NULL,@dtDateDebut,@dtDateFin,'O',NULL) fnt WHERE fnt.iID_Oper = O.OperID),
							iNombrePayement		= 0 --(SELECT fnt.iNombrePayement	FROM fntOPER_ObtenirCotisationFraisConvention(C.ConventionID,NULL,@dtDateDebut,@dtDateFin,'O',NULL) fnt WHERE fnt.iID_Oper = O.OperID)
					FROM 
						dbo.Un_Convention C
						INNER JOIN Un_CESP CE 
							ON C.ConventionID = CE.ConventionID
						INNER JOIN Un_Oper O 
							ON O.OperID = CE.OperID
					WHERE 
						C.ConventionID = @iIdConvention 
						AND 
						O.OperDate BETWEEN @dtDateDebut AND @dtDateFin
						AND  
						O.OperTypeID = 'PAE'
					GROUP BY 
						C.ConventionID, 
						O.OperTypeID, 
						O.OperID,
						O.OperDate
					
					UNION 
					
					SELECT	
							fCESG				= 0,
							mPAE				= SUM(CASE CO.ConventionOperTypeID WHEN 'INM' THEN CO.ConventionOperAmount ELSE 0 END),
							fACESG				= 0,
							fCLB				= 0,
							--fCLBFee             = 0,Proposition Mbaye: pour le bon montant de l'interet		
							fPG					= 0,
							ConventionID		= CO.ConventionID,
							iIDConvention		= CO.ConventionID,
							Iid_Oper			= CO.OperID,
							vcTypeOperation		= O.OperTypeId,	
							mCotisation			= 0,
							mFrais				= 0,
							dtDateOperation		= O.OperDate,
							[INS]				= SUM(CASE CO.ConventionOperTypeID WHEN 'INS' THEN CO.ConventionOperAmount ELSE 0 END),
							[IS+]				= SUM(CASE CO.ConventionOperTypeID WHEN 'IS+' THEN CO.ConventionOperAmount ELSE 0 END),
							vcCompagnie			= '',
							mAutreRev			= 0,
							iPayementParAnnee	= 1,--(SELECT fnt.iPayementParAnnee	FROM fntOPER_ObtenirCotisationFraisConvention(CO.ConventionID,NULL,@dtDateDebut,@dtDateFin,'O',NULL) fnt WHERE fnt.iID_Oper = CO.OperID),
							iNombrePayement		= 0 --(SELECT fnt.iNombrePayement	FROM fntOPER_ObtenirCotisationFraisConvention(CO.ConventionID,NULL,@dtDateDebut,@dtDateFin,'O',NULL) fnt WHERE fnt.iID_Oper = CO.OperID)
					FROM 
						dbo.Un_ConventionOper CO
						INNER JOIN dbo.Un_Oper O ON O.OperID=CO.OperID AND O.OperDate BETWEEN @dtDateDebut AND @dtDateFin
					WHERE 
						CO.ConventionID = @iIdConvention 
						AND
						O.OperTypeID = 'PAE'
					GROUP BY 
						CO.ConventionID,
						O.OperTypeID, 
						CO.OperID,
						O.OperDate
				
			-----@@@@@@@@@@@@		Bourgeois, Alain
			UNION 
		
					SELECT  
							fCESG				= SUM(ISNULL(CE.fCESG,0)),	
							mPAE				= 0 ,
							fACESG				= SUM(ISNULL(CE.fACESG,0)),	
							fCLB				= SUM(ISNULL(CE.fCLB,0)),
							--fCLBFee             = SUM(ISNULL(CE.fCLBFee,0)),Proposition Mbaye: pour le bon montant de l'interet		
							fPG					= SUM(ISNULL(CE.fPG,0)),
							ConventionID		= C.ConventionID,
							iIDConvention		= C.ConventionID,
							Iid_Oper			= O.OperID,		
							vcTypeOperation		= O.OperTypeId,	
							mCotisation			= 0,
							mFrais				= 0,
							dtDateOperation		= O.OperDate,		
							[INS]				= 0,
							[IS+]				= 0,
							vcCompagnie			= ISNULL(Comp.CompanyName,''),
							mAutreRev			= 0,
							iPayementParAnnee	= 1,--(SELECT fnt.iPayementParAnnee	FROM fntOPER_ObtenirCotisationFraisConvention(C.ConventionID,NULL,@dtDateDebut,@dtDateFin,'O',NULL) fnt WHERE fnt.iID_Oper = O.OperID),
							iNombrePayement		= 0 --(SELECT fnt.iNombrePayement	FROM fntOPER_ObtenirCotisationFraisConvention(C.ConventionID,NULL,@dtDateDebut,@dtDateFin,'O',NULL) fnt WHERE fnt.iID_Oper = O.OperID)
					FROM 
						dbo.Un_Convention C
						INNER JOIN Un_CESP CE 
							ON C.ConventionID = CE.ConventionID
						INNER JOIN Un_Oper O 
							ON O.OperID = CE.OperID
						INNER JOIN dbo.Un_Cotisation CTS ON CTS.OperID = O.OperID
						LEFT JOIN dbo.Un_TIN tin ON O.OperID = tin.OperID AND O.OperTypeId = 'TIN'
						LEFT OUTER JOIN dbo.Un_ExternalPlan EP ON EP.ExternalPlanID = tin.ExternalPlanID
						LEFT OUTER JOIN dbo.Mo_Company Comp ON Comp.CompanyID = EP.ExternalPromoID
										
					WHERE 
						C.ConventionID = @iIdConvention 
						AND 
						O.OperDate BETWEEN @dtDateDebut AND @dtDateFin
						AND  
						O.OperTypeID = 'TIN'
						AND O.OperDate<>CTS.EffectDate
					GROUP BY 
						C.ConventionID, 
						O.OperTypeID, 
						O.OperID,
						O.OperDate
						,tin.vcOtherConventionNo
						,Comp.CompanyName
			--@@@@@@@@@@@@@@@@@@@@@	
				) AS x
		-- cas d'auteuil monique (i-20101223004)
		--	INNER JOIN dbo.Un_Cotisation COTIS ON COTIS.OperID = x.Iid_Oper
		LEFT JOIN dbo.Un_Cotisation COTIS ON COTIS.OperID = x.Iid_Oper
		GROUP BY
				x.Iid_Oper,
				x.iIDConvention,
				x.dtDateOperation,
				x.vcTypeOperation,
				x.vcCompagnie
				,COTIS.EffectDate				
    ----Cas KENNEDY, Todd david TIN qui ne correspond aucune cotisation
    UNION ALL				

		SELECT		
				x.Iid_Oper, 
				iIDConvention		= @iIdConvention,
				mQuantiteUnite		= @mQuantiteUnite,
				mFraisCotisation	= SUM(x.mCotisation + x.mFrais),
				mFrais				= SUM(x.mFrais),
				mSCEE				= SUM(x.fCESG),
				mIntSCEE			= SUM(x.[INS]),
				mSCEESup			= SUM(x.fACESG + x.[IS+]),
				mIntSCEESup			= SUM(x.[IS+]),
				mBec				= 0,
				mIQEERio			= 0,
				mIntBEC				= @mIntBEC,--isnull(sum(x.fCLBFee),0), Proposition Mbaye: pour le bon montant de l'interet		
				mPAE				= (SELECT sum(fnt.ConventionOperAmount) FROM fntOPER_ObtenirMontantConvention(@iIdConvention, @dtDateDebut, @dtDateFin, 'PAE') fnt WHERE fnt.iID_OPER = x.Iid_Oper),
				mIntPAE				= (SELECT sum(fnt.ConventionOperAmount) FROM fntOPER_ObtenirMontantConvention(@iIdConvention, @dtDateDebut, @dtDateFin, 'INT_PAE') fnt WHERE fnt.iID_OPER = x.Iid_Oper),
				dtDateOperation		= x.dtDateOperation,
				vcTypeOperation		= x.vcTypeOperation,
				vcCompagnie			= x.vcCompagnie,
			    mAutreRev			= SUM(x.mAutreRev),
				mIntAutreRev		= (SELECT ISNULL( ISNULL(SUM(conventionOperAmount),0),0) FROM fntOPER_ObtenirMontantConvention(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_PCEE_TIN_TFR')fnt WHERE fnt.iID_OPER = x.Iid_Oper),
				vcTypeDonnee		= 'D',
				iPayementParAnnee	= SUM(iPayementParAnnee),
				iNombrePayement		= SUM(iNombrePayement),
				vcLigneSommaire		= 'L90',
				iNbOper				= COUNT(x.Iid_Oper) OVER(PARTITION BY x.iIDConvention, x.vcTypeOperation, x.vcCompagnie), -- compte le nombre effectiv de payements 
				iNbOperTRA12		= 0,
				iNbOperTRA12L1		= 0,
				iNbOperCPA12		= 0,
				UnBranch			= 'p2'
		FROM
				(	
      	-----@@@@@@@@@@@@		cas Kennedy Todd	
									SELECT  
							fCESG				= SUM(ISNULL(CE.fCESG,0)),	
							mPAE				= 0 ,
							fACESG				= SUM(ISNULL(CE.fACESG,0)),	
							fCLB				= SUM(ISNULL(CE.fCLB,0)),
							--fCLBFee             = SUM(ISNULL(CE.fCLBFee,0)),Proposition Mbaye: pour le bon montant de l'interet		
							fPG					= SUM(ISNULL(CE.fPG,0)),
							ConventionID		= C.ConventionID,
							iIDConvention		= C.ConventionID,
							Iid_Oper			= O.OperID,		
							vcTypeOperation		= O.OperTypeId,	
							mCotisation			= 0,
							mFrais				= 0,
							dtDateOperation		= O.OperDate,		
							[INS]				= 0,
							[IS+]				= 0,
							vcCompagnie			= ISNULL(Comp.CompanyName,''),
							mAutreRev			= 0,
							iPayementParAnnee	= 1,--(SELECT fnt.iPayementParAnnee	FROM fntOPER_ObtenirCotisationFraisConvention(C.ConventionID,NULL,@dtDateDebut,@dtDateFin,'O',NULL) fnt WHERE fnt.iID_Oper = O.OperID),
							iNombrePayement		= 0 --(SELECT fnt.iNombrePayement	FROM fntOPER_ObtenirCotisationFraisConvention(C.ConventionID,NULL,@dtDateDebut,@dtDateFin,'O',NULL) fnt WHERE fnt.iID_Oper = O.OperID)
					FROM 
						dbo.Un_Convention C
						INNER JOIN Un_CESP CE 
							ON C.ConventionID = CE.ConventionID
						INNER JOIN Un_Oper O 
							ON O.OperID = CE.OperID
					--INNER JOIN dbo.Un_Cotisation CTS ON CTS.OperID = O.OperID
						LEFT JOIN dbo.Un_TIN tin ON O.OperID = tin.OperID AND O.OperTypeId = 'TIN'
						LEFT OUTER JOIN dbo.Un_ExternalPlan EP ON EP.ExternalPlanID = tin.ExternalPlanID
						LEFT OUTER JOIN dbo.Mo_Company Comp ON Comp.CompanyID = EP.ExternalPromoID
										
					WHERE 
						C.ConventionID = @iIdConvention 
						AND 
						O.OperDate BETWEEN @dtDateDebut AND @dtDateFin
						AND  
						O.OperTypeID = 'TIN'
				    AND NOT EXISTS(select 1  from un_cotisation where un_cotisation.OperID =O.OperID)
					GROUP BY 
						C.ConventionID, 
						O.OperTypeID, 
						O.OperID,
						O.OperDate
						,tin.vcOtherConventionNo
						,Comp.CompanyName
					) AS x
			
		GROUP BY
				x.Iid_Oper,
				x.iIDConvention,
				x.dtDateOperation,
				x.vcTypeOperation,
				x.vcCompagnie	
		
    UNION ALL	-- RIO - RIM - TRI

		SELECT	 NULL
				,iIDConvention		= @iIdConvention
				,mQuantiteUnite		= NULL
				,mFraisCotisation	= SUM(Z.mCotisation + Z.mFrais)
				,mFrais				= SUM(Z.mFrais)
				
				,mSCEE				= ISNULL(@CESG,0) + ISNULL(@CESGInt,0)
				,mIntSCEE			= 0
				
				,mSCEESup			= ISNULL(@ACESG,0) + ISNULL(@ACESGInt,0)
				,mIntSCEESup		= 0
				
				,mBec				= ISNULL(@CLB,0) + ISNULL(@CLBInt,0)
				,mIntBEC			= 0
				
				,mIQEERio			= ISNULL(@IQEERio,0)
				
				,mPAE				= 0
				,mIntPAE			= 0
				--,dtDateOperation	= Z.dtDateOperation
				--Radu Trandafir
				,dtDateOperation	= ''
				,vcTypeOperation	= Z.vcTypeOperation
				,vcCompagnie		= Z.vcCompagnie
				,mAutreRev			= ISNULL(@AutreRev,0)
				,mIntAutreRev		= 0
				,vcTypeDonnee		= 'D'
				,iPayementParAnnee	= SUM(iPayementParAnnee)
				,iNombrePayement	= SUM(iNombrePayement)
				,vcLigneSommaire	= 'L90'
				,iNbOper			= NULL
				,iNbOperTRA12		= 0
				,iNbOperTRA12L1		= 0
				,iNbOperCPA12		= 0
				,UnBranch			= 'p2'
--Mbaye Diakhate: pour corriger le cas s'il n'existe pas de cotisation dans le transfert cas Carl Tremblay T-20101101278
		FROM	@tmpCotisationRio AS Z
			-- FROM (	SELECT	 ConventionID		= UN.ConventionID
		--					,iIDConvention		= UN.ConventionID
		--					,Iid_Oper			= OP.OperID
		--					,vcTypeOperation	= OP.OperTypeId
		--					,mCotisation		= CT.Cotisation
		--					,mFrais				= CT.Fee
		--					,dtDateOperation	= OP.OperDate
		--					,vcCompagnie		= ''
		--					,mAutreRev			= 0
		--					,iPayementParAnnee	= 1
		--					,iNombrePayement	= 0
					
		--			FROM Un_Cotisation CT
		--			JOIN dbo.Un_Unit UN ON UN.UnitID = CT.UnitID
		--			JOIN Un_Oper OP ON OP.OperID = CT.OperID
					
		--			WHERE	UN.ConventionID = @iIdConvention
		--			AND		OP.OperDate BETWEEN @dtDateDebut AND @dtDateFin
		--			AND		OP.OperTypeID IN ('RIO', 'RIM', 'TRI')

		--			GROUP BY UN.ConventionID
		--					,OP.OperTypeID
		--					,OP.OperID
		--					,OP.OperDate
		--					,CT.Cotisation
		--					,CT.Fee
		--		) AS Z
			
		GROUP BY	 Z.iIDConvention
					--Radu Trandafir
					--,Z.dtDateOperation
					,Z.vcTypeOperation
					,Z.vcCompagnie
		)
		
		-- Insertion d'enregistrement
		INSERT INTO @tReleveDepotDetails
		--On veut ajouter une ligne pour chaque transaction au payement annuel (non sommairise)
		SELECT iIDConvention,
				mQuantiteUnite ,
				mFraisCotisation ,
				mFrais ,
				mSCEE ,
				mIntSCEE ,
				mSCEESup ,
				mIntSCEESup ,
				mBec ,
				mIntBEC ,
				mIQEERio,
				mPAE ,
				mIntPAE ,
				dtDateOperation ,
				vcTypeOperation ,
				vcCompagnie,
				mAutreRev ,
				mIntAutreRev ,
				vcTypeDonnee,
				iPayementParAnnee,
				iNombrePayement,
				Iid_Oper	
		FROM DepotDetails
		WHERE iPayementParAnnee = 1 AND iNbOperTra12 = 0
		UNION ALL
		-- On ajoute la somme des transactions à payements pluriannuels (sommairise)
		 SELECT  iIDConvention,
				mQuantiteUnite ,
				SUM(mFraisCotisation) ,
				SUM(mFrais) ,
				--Radu Trandafir cas Ferland Annie OUT mSCEE
				--max(mSCEE) ,
				CASE WHEN MAX(mSCEE) = 0 and MIN(mSCEE) <> 0 THEN
				  MIN(mSCEE)
				ELSE
				  MAX(mSCEE) 
				END,
				max(mIntSCEE) ,
				max(mSCEESup) ,
				max(mIntSCEESup) ,
				mBec ,
				mIntBEC ,
				mIQEERio,
				mPAE ,
				mIntPAE ,
				MAX(dtDateOperation) ,
				-- pour les TRANSFERS qui ont au moins un a pluriannuel, on les sommairise ('L01') donc la titre devienne CPA
				CASE WHEN	(CASE WHEN iNbOperTra12 > 0 AND vcTypeOperation <> 'TRA' 
									   OR 
									   iNbOperTra12 > 0 AND vcTypeOperation = 'TRA' AND (iPayementParAnnee > 1 OR iNbOperTra12L1 > 0 AND iNbOperCPA12 = 0)
									   OR
									   iNbOperTra12 > 0 AND vcTypeOperation = 'TRA' AND (iPayementParAnnee = 1 OR iNbOperTra12L1 > 0 AND iNbOperCPA12 > 0) 
									THEN 'L01'
								 ELSE vcLigneSommaire 
							 END) = 'L01'  AND (
													CASE 
														WHEN  iNbOperTra12 > 0 THEN 12 
														ELSE iPayementParAnnee 
												END) <> 1 AND iNbOperCPA12 > 0
							THEN 'CPA'
					 ELSE  vcTypeOperation
				END  AS vcTypeOperation ,
				max(vcCompagnie),
				max(mAutreRev) ,
				max(mIntAutreRev) ,
				vcTypeDonnee,
				CASE WHEN  iNbOperTra12 > 0 THEN 12
					 ELSE iPayementParAnnee
				END AS iPayementParAnnee,
				MAX(iNombrePayement) AS iNombrePayement,
				NULL
			FROM DepotDetails
			WHERE  NOT (iPayementParAnnee = 1 AND iNbOperTra12 = 0)
			--Radu Trandafir cas Ferland Annie OUT mSCEE
			--GROUP BY iIDConvention,mQuantiteUnite, mBec, 
			GROUP BY iIDConvention,mQuantiteUnite, mBec,  
				CASE WHEN  iNbOperTra12 > 0 THEN 12
					 ELSE iPayementParAnnee
				END,
				-- pour les TRANSFERS qui ont au moins un a pluriannuel, on les sommarize
				CASE WHEN	(CASE WHEN iNbOperTra12 > 0 AND vcTypeOperation <> 'TRA' 
									   OR 
									   iNbOperTra12 > 0 AND vcTypeOperation = 'TRA' AND (iPayementParAnnee > 1 OR iNbOperTra12L1 > 0 AND iNbOperCPA12 = 0) 
									   OR
									   iNbOperTra12 > 0 AND vcTypeOperation = 'TRA' AND (iPayementParAnnee = 1 OR iNbOperTra12L1 > 0 AND iNbOperCPA12 > 0)
									THEN 'L01'
								 ELSE vcLigneSommaire 
							 END) = 'L01'  AND (CASE
													 WHEN  iNbOperTra12 > 0 THEN 12 
													 ELSE iPayementParAnnee END) <> 1 AND iNbOperCPA12 > 0 THEN 'CPA'
					 ELSE  vcTypeOperation
				END, 
				CASE WHEN iNbOperTra12 > 0  AND vcTypeOperation NOT IN ('TIN','TFR','OUT')
						THEN 'L01'
						ELSE vcLigneSommaire 
				END,
				mIntBEC, mIQEERio, mPAE, mIntPAE,  vcTypeDonnee, iNombrePayement, vcCompagnie
				 --Radu Trandafir ajout de vcCompagnie dans le group by (Allard Christian)
	--Ajouter les montants d'intéret pour la convention
		UNION
			SELECT    @iIdConvention,
					  @mQuantiteUnite,
					  0 as mFraisCotisation,
					  0 as mFrais,
					  @mSCEE + @mIntPCEETIN - @mIntPCEETINSansTFR,
					  @mIntSCEE,
					  @mSCEESup,
					  @mIntSCEESup,
					  @mBec,
					  @mIntBEC,
					  0,
					  @mPAE,
					  @mIntPAE,
					  NULL,
					  'REV',
					  NULL,
					  0,
					  --@mIntAutreRev,
					  @mIntAutreRev + @mIntPCEETINSansTFR,					  
					  'R',
					  0,
					  0,
					 NULL 
	RETURN
    */    
END