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
Code de service		:		fnCONV_ObtenirReleveDepotDetailsAvecGroupeUnite
Nom du service		:		fnCONV_ObtenirReleveDepotDetailsAvecGroupeUnite
But					:		Récupérer le détails du relevé de dépôt avec les unités associées à la convention
Facette				:		P171U
Reférence			:		Relevé de dépôt
Parametres d'entrée :	Parametres					Description                              Obligatoir
                        ----------                  ----------------                         --------------                       
                        iIdConvention	            Identifiant unique de la convention      Oui
						dtDateDebut	                Date du début du relevé des cotisations
						dtDateFin	                Date de fin du relevé des cotisations

Exemple d'appel:
			SELECT * FROM dbo.fntCONV_ObtenirReleveDepotDetailsAvecGroupeUnite(257755,'1900-01-01','2008-12-31')

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
                       
Historique des modifications :
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-10-01					Jean-François Gauthier					Création de la procédure
						2009-10-09					Jean-François Gauthier					Modification pour ajouter Un_Cotisation lorsque Un_CESP est utilisé
						2009-11-05					Jean-François Gauthier					Appel de la fonction fntOPER_ObtenirCotisationFraisConvention avec le paramètre 'E'
																							Retour de la date effective au lieu de la date d'opération
						2010-03-12					Jean-François Gauthier					Modification de l'appel à fntOPER_ObtenirCotisationFraisConvention
						2010-07-07					Jean-François Gauthier					Ajout de la transaction RDI qui doit apparaître sur la ligne L01 comme le CPA, PRD ou CHQ
						2011-07-19					Frédérick Thibault						Ajout RIM et TRI
						2011-12-07					Radu Trandafir							Corrections sur la date de debut
                        2017-09-27                  Pierre-Luc Simard                       Deprecated - Cette procédure n'est plus utilisée

  ****************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirReleveDepotDetailsAvecGroupeUnite]
	( 
	@iIdConvention	INT,
	@dtDateDebut	DATETIME,
	@dtDateFin		DATETIME 
	)
RETURNS  
		@tReleveDepotDetails TABLE 
		( 
			iIDConvention		INT,
            fQuantiteUnite		FLOAT,
			mFraisCotisation	MONEY,
			mFrais				MONEY,
			mSCEE				MONEY,
			mIntSCEE			MONEY,
			mSCEESup			MONEY,
			mIntSCEESup			MONEY,
			mBec				MONEY,
			mIntBEC				MONEY,
			mPAE				MONEY,
			mIntPAE				MONEY,
            dtDateOperation		DATETIME,
            vcTypeOperation		CHAR(3),
            vcCompagnie			VARCHAR(200),
			mAutreRev			MONEY,
			mIntAutreRev		MONEY,
            vcTypeDonnee		CHAR(1),
			iPayementParAnnee	INT,
			iNombrePayement		INT,
			iIDUnite			INT
		)
BEGIN

    INSERT INTO @tReleveDepotDetails
            (iIDConvention ,
             fQuantiteUnite ,
             mFraisCotisation ,
             mFrais ,
             mSCEE ,
             mIntSCEE ,
             mSCEESup ,
             mIntSCEESup ,
             mBec ,
             mIntBEC ,
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
             iIDUnite
            )
    VALUES
            (0 , -- iIDConvention - int
             0.0 , -- fQuantiteUnite - float
             NULL , -- mFraisCotisation - money
             NULL , -- mFrais - money
             NULL , -- mSCEE - money
             NULL , -- mIntSCEE - money
             NULL , -- mSCEESup - money
             NULL , -- mIntSCEESup - money
             NULL , -- mBec - money
             NULL , -- mIntBEC - money
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
             0  -- iIDUnite - int
            )
    RETURN
/*
	IF @dtDateDebut IS NULL 
		BEGIN
			SET @dtDateDebut = '1900/01/01'
		END

	-- Radu Trandafir
	--SET @dtDateDebut = DATEADD(dd, 1, @dtDateDebut)

	IF @dtDateFin IS NULL 
		BEGIN
			SET @dtDateFin = GETDATE()
		END;

	-- Using a CTE (Common table expression) pour preparer les critères de sommatization 
	WITH DepotDetails 
		(
		Iid_Oper, 
		iIDConvention,
		fQuantiteUnite ,
		mFraisCotisation ,
		mFrais ,
		mSCEE ,
		mIntSCEE ,
		mSCEESup ,
		mIntSCEESup ,
		Bec ,
		IntBEC ,
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
		UnBranch,
		iIDUnite
		)
	AS
	(
		-- pour la non TIN,OUT: SCEE,SCEE+,BEC au noveau global
		SELECT 
			DISTINCT
			CT.Iid_Oper, 
			iIDConvention = @iIdConvention,
			fQuantiteUnite = CT.fQteUnite,
			mFraisCotisation = ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0),
			mFrais = ISNULL(CT.mFrais,0),
			mSCEE = ISNULL((SELECT SUM(sbu.fCESG) FROM dbo.fntPCEE_ObtenirSubventionBonsParUnite (@iIdConvention,@dtDateDebut,@dtDateFin) sbu WHERE CT.iIDGroupeUnite = sbu.UnitID),0),
			mIntSCEE = ISNULL((SELECT SUM(cpu.conventionOperAmount) FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_SCEE') cpu WHERE cpu.iIDUnit = CT.iIDGroupeUnite),0),
			mSCEESup =	ISNULL((SELECT SUM(sbu.fACESG) FROM dbo.fntPCEE_ObtenirSubventionBonsParUnite (@iIdConvention,@dtDateDebut,@dtDateFin) sbu WHERE CT.iIDGroupeUnite = sbu.UnitID),0) + ISNULL((SELECT SUM(sbu.fACESGINT) FROM dbo.fntPCEE_ObtenirSubventionBonsParUnite (@iIdConvention,@dtDateDebut,@dtDateFin) sbu WHERE CT.iIDGroupeUnite = sbu.UnitID),0),
			mIntSCEESup = ISNULL((SELECT SUM(cpu.conventionOperAmount) FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_SCEE_SUP') cpu WHERE cpu.iIDUnit = CT.iIDGroupeUnite),0),
			Bec = ISNULL((SELECT SUM(sbu.fCLB) FROM dbo.fntPCEE_ObtenirSubventionBonsParUnite (@iIdConvention,@dtDateDebut,@dtDateFin) sbu WHERE CT.iIDGroupeUnite = sbu.UnitID),0),
			IntBEC = ISNULL((SELECT SUM(cpu.conventionOperAmount) FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_BEC') cpu WHERE cpu.iIDUnit = CT.iIDGroupeUnite),0),
			mPAE = ISNULL((SELECT SUM(cpu.conventionOperAmount) FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention,@dtDateDebut,@dtDateFin,'PAE') cpu WHERE cpu.iIDUnit = CT.iIDGroupeUnite),0),
			mIntPAE = ISNULL((SELECT SUM(cpu.conventionOperAmount) FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_PAE') cpu WHERE cpu.iIDUnit = CT.iIDGroupeUnite),0),
			dtDateOperation = CT.dtDateEffective,
			vcTypeOperation = CT.vcTypeOperation,
			vcCompagnie =	CASE	WHEN vcTypeOperation = 'TIN' and io.iTINOperID IS NOT NULL THEN COALESCE(tin.vcOtherConventionNo,CT.vcCompagnie) 
									WHEN vcTypeOperation = 'TFR' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) < 0 THEN COALESCE(out.vcOtherConventionNo,CT.vcCompagnie) 
									WHEN vcTypeOperation = 'TFR' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) > 0 THEN COALESCE(tin.vcOtherConventionNo,CT.vcCompagnie) 
									WHEN vcTypeOperation = 'OUT' and io.iOUTOperID IS NOT NULL THEN COALESCE(out.vcOtherConventionNo,CT.vcCompagnie) 
									ELSE CT.vcCompagnie 
							END,
			mAutreRev = ISNULL(CT.mAutreRev,0),
			mIntAutreRev = ISNULL((SELECT SUM(cpu.conventionOperAmount) FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_AUTREREV') cpu WHERE cpu.iIDUnit = CT.iIDGroupeUnite),0),
			--Radu Trandafir
			--mIntAutreRev = ISNULL((SELECT SUM(cpu.conventionOperAmount) FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_AUTREREV') cpu WHERE cpu.iIDUnit = CT.iIDGroupeUnite),0)+
			--               ISNULL((SELECT SUM(cpu.conventionOperAmount) FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_PCEE_TIN_ITR') cpu WHERE cpu.iIDUnit = CT.iIDGroupeUnite),0),
			'D' as vcTypeDonnee,
			iPayementParAnnee,
			iNombrePayement,
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
		COUNT(CT.Iid_Oper) OVER(PARTITION BY iIDGroupeUnite, iIDConvention, vcTypeOperation, vcCompagnie) AS iNbOper,
		SUM(CASE WHEN (vcTypeOperation = 'TRA' OR vcTypeOperation = 'AJU')
					  OR (vcTypeOperation = 'CPA' and iPayementParAnnee > 1 OR vcTypeOperation = 'NSF')
					THEN 1
					ELSE 0
			  END) OVER(PARTITION BY iIDGroupeUnite, iIDConvention, vcTypeOperation, vcCompagnie) AS iNbOperTRA12,
		SUM(CASE WHEN (vcTypeOperation = 'TRA' OR vcTypeOperation = 'AJU' and iPayementParAnnee > 1)
					THEN 1
					ELSE 0
			  END) OVER(PARTITION BY iIDGroupeUnite, iIDConvention, vcTypeOperation, vcCompagnie) AS iNbOperTRA12L1,
		SUM(CASE WHEN (vcTypeOperation = 'CPA' AND iPayementParAnnee > 1)
					THEN 1
					ELSE 0
			  END) OVER(PARTITION BY iIDGroupeUnite, iIDConvention, vcCompagnie) AS iNbOperCPA12,
		'p1' as UnBranch,
		CT.iIDGroupeUnite
		FROM 
			dbo.fntOPER_ObtenirCotisationFraisConvention (@iIdConvention,NULL,@dtDateDebut,@dtDateFin,'E',null,'D') CT
			LEFT OUTER JOIN (
						SELECT 
							fCESG = SUM(CE.fCESG),		-- SCEE reçue (+), versée (-) ou remboursée (-)
							fACESG = SUM(CE.fACESG),	-- SCEE+ reçue (+), versée (-) ou remboursée (-)
							fCLB = SUM(CE.fCLB),		-- BEC reçu (+), versé (-) ou remboursé (-)						   
							ConventionID = C.ConventionID,
							O.OperTypeID, 
							O.OperID,
							u.UnitID
						FROM 
							dbo.Un_Unit u
							INNER JOIN dbo.Un_Cotisation co
								ON u.UnitID = co.UnitID
							INNER JOIN dbo.Un_Convention C
								ON u.ConventionID = C.ConventionID
							INNER JOIN dbo.Un_CESP CE 
								ON C.ConventionID = CE.ConventionID	AND CE.CotisationID = co.CotisationID
							INNER JOIN dbo.Un_Oper O 
								ON O.OperID = CE.OperID
						WHERE 
							C.ConventionID = @iIdConvention 
							AND 
							O.OperDate BETWEEN @dtDateDebut AND @dtDateFin
						GROUP BY 
							u.UnitID, C.ConventionID, O.OperTypeID, o.OperID
						) AS S1 
				ON (S1.OPERID = CT.Iid_Oper AND CT.iIDGroupeUnite = S1.UnitID)
			LEFT OUTER JOIN dbo.un_tio io 
				ON CT.Iid_Oper = io.iTFROperID 	AND CT.vcTypeOperation ='TFR' OR CT.Iid_Oper = io.iTINOperID AND CT.vcTypeOperation ='TIN' OR CT.Iid_Oper = io.iOUTOperID 	AND CT.vcTypeOperation ='OUT'
			LEFT OUTER JOIN dbo.Un_TIN tin 
				ON (io.iTINOperID = tin.OperID AND CT.vcTypeOperation = 'TFR' OR CT.Iid_Oper = tin.OperID AND CT.vcTypeOperation = 'TIN')
			LEFT OUTER JOIN dbo.Un_OUT out 
				ON (io.iOUTOperID = out.OperID AND CT.vcTypeOperation = 'TFR' OR CT.Iid_Oper = out.OperID AND CT.vcTypeOperation = 'OUT')
		WHERE 
			CT.vcTypeOperation <> 'TIN' AND CT.vcTypeOperation <> 'OUT' AND CT.vcTypeOperation <> 'RIO' AND CT.vcTypeOperation <> 'RIM' AND CT.vcTypeOperation <> 'TRI' AND CT.vcTypeOperation <> 'TRI'
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
		SELECT 
			DISTINCT
			CT.Iid_Oper, 
			iIDConvention = @iIdConvention,
			fQuantiteUnite = CT.fQteUnite,
			mFraisCotisation = ISNULL(CT.mCotisation,0)+ ISNULL(CT.mFrais,0),
			mFrais = ISNULL(CT.mFrais,0),
			mSCEE = ISNULL(s2.fCESG,0)+ISNULL([INS],0)+isnull((	SELECT 
																	SUM(ConventionOperAmount) 
																FROM 
																	dbo.fntOPER_ObtenirMontantConventionParUnite(@iIDConvention,@dtDateDebut,@dtDateFin,'INT_PCEE_TIN_TFR') f 
																WHERE 
																	f.iID_Oper=CT.IID_Oper AND f.iIDUnit = CT.iIDGroupeUnite),0),
			mIntSCEE = ISNULL([INS],0),
			mSCEESup = ISNULL(s2.fACESG,0)+ISNULL([IS+],0),
			mIntSCEESup = ISNULL([IS+],0),
			Bec = 0,
			IntBEC = ISNULL((SELECT SUM(cpu.conventionOperAmount) FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_BEC') cpu WHERE cpu.iIDUnit = CT.iIDGroupeUnite),0),
			mPAE = ISNULL((SELECT SUM(cpu.conventionOperAmount) FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention,@dtDateDebut,@dtDateFin,'PAE') cpu WHERE cpu.iIDUnit = CT.iIDGroupeUnite),0),
			mIntPAE = ISNULL((SELECT SUM(cpu.conventionOperAmount) FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_PAE') cpu WHERE cpu.iIDUnit = CT.iIDGroupeUnite),0),
			dtDateOperation = CT.dtDateEffective,
			vcTypeOperation = CT.vcTypeOperation,
			vcCompagnie =	CASE	WHEN vcTypeOperation = 'TIN' and io.iTINOperID IS NOT NULL THEN COALESCE(tin.vcOtherConventionNo,CT.vcCompagnie) 
									WHEN vcTypeOperation = 'TFR' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) < 0 THEN COALESCE(out.vcOtherConventionNo,CT.vcCompagnie) 
									WHEN vcTypeOperation = 'TFR' AND ISNULL(CT.mCotisation,0) + ISNULL(CT.mFrais,0) > 0 THEN COALESCE(tin.vcOtherConventionNo,CT.vcCompagnie) 
									WHEN vcTypeOperation = 'OUT' and io.iOUTOperID IS NOT NULL THEN COALESCE(out.vcOtherConventionNo,CT.vcCompagnie) 
									ELSE CT.vcCompagnie 
							END,
			mAutreRev = ISNULL(CT.mAutreRev,0),
			mIntAutreRev = ISNULL((SELECT SUM(cpu.conventionOperAmount) FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_AUTREREV') cpu WHERE cpu.iIDUnit = CT.iIDGroupeUnite),0),
			--Radu Trandafir
			--mIntAutreRev = ISNULL((SELECT SUM(cpu.conventionOperAmount) FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_AUTREREV') cpu WHERE cpu.iIDUnit = CT.iIDGroupeUnite),0) +
			--               ISNULL((SELECT SUM(cpu.conventionOperAmount) FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention,@dtDateDebut,@dtDateFin,'INT_PCEE_TIN_ITR') cpu WHERE cpu.iIDUnit = CT.iIDGroupeUnite),0),			
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
			'p2' as UnBranch,
			CT.iIDGroupeUnite
		FROM 
			dbo.fntOPER_ObtenirCotisationFraisConvention (@iIdConvention,NULL,@dtDateDebut,@dtDateFin,'E',NULL,'D') CT
			LEFT OUTER JOIN (
						SELECT 
							CO.ConventionID, 
							OperTypeID, 
							SUM(CASE ConventionOperTypeID WHEN 'INM' THEN ConventionOperAmount ELSE 0 END) AS "INM",
							SUM(CASE ConventionOperTypeID WHEN 'INS' THEN ConventionOperAmount ELSE 0 END) AS [INS],
							SUM(CASE ConventionOperTypeID WHEN 'IS+' THEN ConventionOperAmount ELSE 0 END) AS [IS+],
							CO.OperID,
							u.UnitID
						FROM 
							dbo.Un_Unit u
							INNER JOIN dbo.Un_ConventionOper CO
								ON CO.ConventionID = u.ConventionID
							INNER JOIN dbo.Un_Oper O 
								ON O.OperID=CO.OperID AND O.OperDate BETWEEN ISNULL(@dtDateDebut,'1900/01/01') AND ISNULL(@dtDateFin,GETDATE())
						WHERE 
							CO.ConventionID=@iIdConvention 
						GROUP BY 
							u.UnitID,
							CO.ConventionID,
							O.OperTypeID,
							CO.OperID
					) AS S1 
				ON (S1.OPERID = CT.Iid_Oper AND CT.iIDGroupeUnite = S1.UnitID)
			LEFT OUTER JOIN (
						SELECT  
								fCESG = SUM(CE.fCESG),	-- SCEE reçue (+), versée (-) ou remboursée (-)
								fACESG = SUM(CE.fACESG),	-- SCEE+ reçue (+), versée (-) ou remboursée (-)
								fCLB = SUM(CE.fCLB),		-- BEC reçu (+), versé (-) ou remboursé (-)						   
								ConventionID = C.ConventionID,
								O.OperTypeID, o.OperID,
								u.UnitID
						FROM
							dbo.Un_Unit u
							INNER JOIN dbo.Un_Convention C
								ON u.ConventionID = C.ConventionID
							INNER JOIN dbo.Un_CESP CE 
								ON C.ConventionID = CE.ConventionID
							INNER JOIN dbo.Un_Oper O 
								ON O.OperID = CE.OperID
						WHERE 
							C.ConventionID = @iIdConvention 
							AND O.OperDate BETWEEN @dtDateDebut AND @dtDateFin
						GROUP BY 
							u.UnitID, 
							C.ConventionID,
							O.OperTypeID, 
							O.OperID
						) AS S2 
				ON (S2.OPERID = CT.Iid_Oper AND	CT.iIDGroupeUnite = S2.UnitID)
			LEFT OUTER JOIN dbo.un_tio io 
				ON CT.Iid_Oper = io.iTFROperID 	AND CT.vcTypeOperation ='TFR' OR CT.Iid_Oper = io.iTINOperID 	AND CT.vcTypeOperation ='TIN' OR CT.Iid_Oper = io.iOUTOperID 	AND CT.vcTypeOperation ='OUT'
			LEFT OUTER JOIN dbo.Un_TIN tin 
				ON (io.iTINOperID = tin.OperID AND CT.vcTypeOperation = 'TFR' OR CT.Iid_Oper = tin.OperID AND CT.vcTypeOperation = 'TIN')
			LEFT OUTER JOIN dbo.Un_OUT out 
				ON (io.iOUTOperID = out.OperID AND CT.vcTypeOperation = 'TFR' OR CT.Iid_Oper = out.OperID AND CT.vcTypeOperation = 'OUT')
		WHERE	
			(CT.vcTypeOperation = 'TIN' OR CT.vcTypeOperation = 'OUT' OR CT.vcTypeOperation = 'RIO' OR CT.vcTypeOperation = 'RIM' OR CT.vcTypeOperation = 'TRI' OR
			(CT.vcTypeOperation = 'TFR' AND io.iTFROperID IS NOT NULL )
				)
			AND NOT
				(
					CT.vcTypeOperation <> 'TIN' AND CT.vcTypeOperation <> 'OUT' AND CT.vcTypeOperation <> 'RIO' AND CT.vcTypeOperation <> 'RIM' AND CT.vcTypeOperation <> 'TRI' AND CT.vcTypeOperation <> 'PAE'
					AND CT.vcTypeOperation <> 'FCB'AND CT.vcTypeOperation <> 'RCB'
					AND NOT (CT.vcTypeOperation = 'TFR' AND EXISTS (
																SELECT 1 
																FROM 
																	dbo.un_tio io		
																	INNER JOIN dbo.Un_CESP CE 
																		ON CE.OperID = io.iTINOperID
																WHERE 
																	CT.Iid_Oper = io.iTFROperID
																	AND CE.ConventionID = @iIdConvention
																UNION
																SELECT 1 
																FROM 
																	dbo.un_tio io		
																	INNER JOIN Un_CESP CE ON CE.OperID = io.iOUTOperID
																WHERE 
																	CT.Iid_Oper = io.iTFROperID
																	AND CE.ConventionID = @iIdConvention
															  )
							)
				)
		UNION				
			SELECT		
				DISTINCT 
				x.Iid_Oper, 
				iIDConvention		= @iIdConvention,
				fQuantiteUnite		= SUM(fQteUnite),
				mFraisCotisation	= SUM(x.mCotisation + x.mFrais),
				mFrais				= SUM(x.mFrais),
				mSCEE				= SUM(x.fCESG),
				mIntSCEE			= SUM(x.[INS]),
				mSCEESup			= SUM(x.fACESG + x.[IS+]),
				mIntSCEESup			= SUM(x.[IS+]),
				Bec					= 0,
				IntBEC				= ISNULL((SELECT fnt.ConventionOperAmount FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention, @dtDateDebut, @dtDateFin, 'INT_BEC') fnt WHERE fnt.iID_OPER = x.Iid_Oper AND fnt.iIDUnit = x.UnitID),0),
				mPAE				= ISNULL((SELECT fnt.ConventionOperAmount FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention, @dtDateDebut, @dtDateFin, 'PAE') fnt WHERE fnt.iID_OPER = x.Iid_Oper AND fnt.iIDUnit = x.UnitID),0),
				mIntPAE				= ISNULL((SELECT fnt.ConventionOperAmount FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention, @dtDateDebut, @dtDateFin, 'INT_PAE') fnt WHERE fnt.iID_OPER = x.Iid_Oper AND fnt.iIDUnit = x.UnitID),0),
				dtDateOperation		= x.dtDateOperation,
				vcTypeOperation		= x.vcTypeOperation,
				vcCompagnie			= x.vcCompagnie,
				mAutreRev			= SUM(x.mAutreRev),
				mIntAutreRev		= ISNULL((SELECT fnt.ConventionOperAmount FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention, @dtDateDebut, @dtDateFin, 'INT_AUTREREV') fnt WHERE fnt.iID_OPER = x.Iid_Oper AND fnt.iIDUnit = x.UnitID),0),
				-- Radu Trandafir
				--mIntAutreRev		= ISNULL((SELECT fnt.ConventionOperAmount FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention, @dtDateDebut, @dtDateFin, 'INT_AUTREREV') fnt WHERE fnt.iID_OPER = x.Iid_Oper AND fnt.iIDUnit = x.UnitID),0) +
				--       				  ISNULL((SELECT fnt.ConventionOperAmount FROM fntOPER_ObtenirMontantConventionParUnite(@iIdConvention, @dtDateDebut, @dtDateFin, 'INT_PCEE_TIN_ITR') fnt WHERE fnt.iID_OPER = x.Iid_Oper AND fnt.iIDUnit = x.UnitID),0),	
				vcTypeDonnee		= 'D',
				iPayementParAnnee	= SUM(iPayementParAnnee),
				iNombrePayement		= SUM(iNombrePayement),
				vcLigneSommaire		= 'L90',
				iNbOper				= COUNT(x.Iid_Oper) OVER(PARTITION BY x.UnitID, x.iIDConvention, x.vcTypeOperation, x.vcCompagnie), -- compte le nombre effectiv de payements 
				iNbOperTRA12		= 0,
				iNbOperTRA12L1		= 0,
				iNbOperCPA12		= 0,
				UnBranch			= 'p2',
				x.UnitID
			FROM
				(
					SELECT  
							fCESG				= SUM(ISNULL(CE.fCESG,0)),	
							mPAE				= 0 ,
							fACESG				= SUM(ISNULL(CE.fACESG,0)),	
							fCLB				= SUM(ISNULL(CE.fCLB,0)),
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
							iPayementParAnnee	= 1,
							iNombrePayement		= 0,
							fQteUnite			= SUM(u.UnitQty),
							u.UnitID
					FROM
						dbo.Un_Unit u
						INNER JOIN dbo.Un_Cotisation co
							ON u.UnitID = co.UnitID
						INNER JOIN dbo.Un_Convention C
							ON u.ConventionID = C.ConventionID
						INNER JOIN dbo.Un_CESP CE 
							ON C.ConventionID = CE.ConventionID AND CE.CotisationID = co.CotisationID
						INNER JOIN dbo.Un_Oper O 
							ON O.OperID = CE.OperID
					WHERE 
						C.ConventionID = @iIdConvention 
						AND 
						O.OperDate BETWEEN @dtDateDebut AND @dtDateFin
						AND  
						O.OperTypeID = 'PAE'
					GROUP BY 
						u.UnitID,
						C.ConventionID, 
						O.OperTypeID, 
						O.OperID,
						O.OperDate
					UNION 
					SELECT	
							fCESG				= 0,
							mPAE				= ISNULL(SUM(CASE CO.ConventionOperTypeID WHEN 'INM' THEN CO.ConventionOperAmount ELSE 0 END),0),
							fACESG				= 0,
							fCLB				= 0,
							fPG					= 0,
							ConventionID		= CO.ConventionID,
							iIDConvention		= CO.ConventionID,
							Iid_Oper			= CO.OperID,
							vcTypeOperation		= O.OperTypeId,	
							mCotisation			= 0,
							mFrais				= 0,
							dtDateOperation		= O.OperDate,
							[INS]				= ISNULL(SUM(CASE CO.ConventionOperTypeID WHEN 'INS' THEN CO.ConventionOperAmount ELSE 0 END),0),
							[IS+]				= ISNULL(SUM(CASE CO.ConventionOperTypeID WHEN 'IS+' THEN CO.ConventionOperAmount ELSE 0 END),0),
							vcCompagnie			= '',
							mAutreRev			= 0,
							iPayementParAnnee	= 1,
							iNombrePayement		= 0,
							fQteUnite			= ISNULL(SUM(u.UnitQty),0),
							u.UnitID
					FROM 
						dbo.Un_Unit u
						INNER JOIN dbo.Un_ConventionOper CO
							ON u.ConventionID = CO.ConventionID
						INNER JOIN dbo.Un_Oper O 
							ON O.OperID=CO.OperID AND O.OperDate BETWEEN @dtDateDebut AND @dtDateFin
					WHERE 
						CO.ConventionID = @iIdConvention 
						AND
						O.OperTypeID = 'PAE'
					GROUP BY 
						u.UnitID,
						CO.ConventionID,
						O.OperTypeID, 
						CO.OperID,
						O.OperDate
				) AS x
			GROUP BY
				x.UnitID,
				x.Iid_Oper,
				x.iIDConvention,
				x.dtDateOperation,
				x.vcTypeOperation,
				x.vcCompagnie			
		)

		-- Insertion d'enregistrement
		INSERT INTO @tReleveDepotDetails
		(
			iIDConvention,
            fQuantiteUnite,
			mFraisCotisation,
			mFrais,
			mSCEE,
			mIntSCEE,
			mSCEESup,
			mIntSCEESup,
			mBec,
			mIntBEC,
			mPAE,
			mIntPAE,
            dtDateOperation,
            vcTypeOperation,
            vcCompagnie,
			mAutreRev,
			mIntAutreRev,
            vcTypeDonnee,
			iPayementParAnnee,
			iNombrePayement,
			iIDUnite
		)
		SELECT	
			DISTINCT
				iIDConvention,
				fQuantiteUnite ,
				mFraisCotisation ,
				mFrais ,
				mSCEE ,
				mIntSCEE ,
				mSCEESup ,
				mIntSCEESup ,
				Bec ,
				IntBEC ,
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
				iIDUnite	
		FROM 
			DepotDetails	-- CTE
	RETURN
    */
END