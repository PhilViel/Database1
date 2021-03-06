﻿/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	psOPER_ObtenirRapportTRI
Description         :	Rapport : Détails des RIM faits sur les groupes d'unités entre deux dates sélectionnées 
Valeurs de retours  :	Dataset :
					iID_Operation			INTEGER		ID de l'opération TRI			
					dtDate_Enregistrement	DATETIME	Date de l'enregistrement du TRI
					vcNomSouscripteur		VARCHAR(50)	Nom de famille du souscripteur
					vcPrenomSouscripteur	VARCHAR(35)	Prénom du souscripteur
					vcConventionNoSource	VARCHAR(15)	Numéro de la convention source
					dtDateEntreeVigueur		DATETIME	Date d'entrée en vigeur du groupe d'unité source
					mNbUnite				MONEY		Nombre d'unité du groupe d'unité source	
					mCotisationSource		MONEY		Montant de cotisations transféré
					mFraisSource			MONEY		Montant de frais transféré
					mEAFBSource				MONEY		Montant des revenus accumulés sur l’épargne calculé au moment du transfert,  soustréé à la source
					mSSCEESource 			MONEY		Montant de SCEE transféré
					mSCEEPlusSource 		MONEY		Montant de SCEE+ transféré
					mBECSource				MONEY		Montant de BEC transféré
					mIntSource				MONEY		Montant d'intérêts transféré
					mIQEESource				MONEY		Montant d'IQEE transféré
					mRendIQEESource			MONEY		Montant des rendements sur l'IQEE transféré
					mIQEEMajSource			MONEY		Montant d'IQEE Majoré transféré
					mRendIQEEMajSource		MONEY		Montant des rendements sur l'IQEE majoré transféré
					mRendIQEETinSource		MONEY		Montant des rendements sur l'IQEE Tin transféré
					vcConventionNoDest		VARCHAR(15)	Numéro de la convention créée lors du TRI
					mCotisationDest			MONEY		Montant de cotisations reçu
					mFraisDest				MONEY		Montant de frais reçu
					mSCEEDest				MONEY		Montant de SCEE reçu
					mSCEEPlusDest			MONEY		Montant de SCEE+ reçu
					mBECDest				MONEY		Montant de BEC reçu
					mIntDest				MONEY		Montant d'intérêt reçu
					mIQEEDest				MONEY		Montant d'IQEE reçu
					mRendIQEEDest			MONEY		Montant des rendements sur l'IQEE reçu
					mIQEEMajDest			MONEY		Montant d'IQEE majoré reçu
					mRendIQEEMajDest		MONEY		Montant des rendements sur l'IQEE majoré reçu
					mRendIQEETinDest		MONEY		Montant des rendements sur l'IQEE Tin reçu
					mSomme					MONEY		Somme de tous les montants du TRI pour vérifier que tout balanc
					mRendIndDest			MONEY		Montant des revenus accumulés sur l’épargne calculé au moment du transfert, ajouté à la destination

Note                :	2011-04-04	Corentin Menthonnex		Création, basée sur RP_UN_RIOConvention
						20123-02-26	Donald Huppé			GLPI 9201

exec psOPER_ObtenirRapportTRI '1950-01-01', '2012-12-31'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_ObtenirRapportTRI] (	
	@dtDebut DATETIME, -- Date de début saisie
	@dtFin DATETIME) -- Date de fin saisie
AS
BEGIN
	--Récupération des groupes de régimes	
	DECLARE @tblTEMP_Regroupements TABLE (
		iID_Regroupement_Regime INT ,
		vcDescription varchar(50)
	)
	INSERT INTO @tblTEMP_Regroupements EXEC dbo.psCONV_ObtenirRegroupementsRegimesPourParametreDeRapport @cID_Langue = 'FRA'

	SELECT 
		--bRIO_QuiAnnule,
		iID_Operation = R.iID_Oper_RIO, -- ID de l'opération TRI		
		dtDate_Enregistrement = convert(varchar(10),O.OperDate,120), -- Date de l'enregistrement du TRI
		vcNomSouscripteur = HS.LastName, -- Nom de famille du souscripteur
		vcPrenomSouscripteur = HS.FirstName, -- Prénom du souscripteur
		
		vcRegime = case when bRIO_QuiAnnule = 0 then PS.PlanDesc else PD.PlanDesc end,
		vcGroupeRegime = case when bRIO_QuiAnnule = 0 then RRS.vcDescription else RRD.vcDescription end,
		iOrdreAffichage = case when bRIO_QuiAnnule = 0 then PS.OrderOfPlanInReport else PD.OrderOfPlanInReport end,			
		
		vcConventionNoSource = case when bRIO_QuiAnnule = 0 then CS.ConventionNo else CD.ConventionNo end, -- Numéro de la convention source
		dtDateEntreeVigueur = convert(varchar(10),US.InForceDate,120), -- Date d'entrée en vigeur du groupe d'unité source
		mNbUnite = US.UnitQty, -- Nombre d'unité du groupe d'unité source	
		mCotisationSource = case when bRIO_QuiAnnule = 0 then ISNULL(CO1.Cotisation,0) else ISNULL(CO2.Cotisation,0) end, -- Montant de cotisations transféré
		mFraisSource = case when bRIO_QuiAnnule = 0 then ISNULL(CO1.Fee,0) else ISNULL(CO2.Fee,0) end, -- Montant de frais transféré
        mEAFBSource = case when bRIO_QuiAnnule = 0 then ISNULL(INMD.mRendInd,0)*-1 ELSE ISNULL(INMS.mRendInd,0)*-1 END, -- Montant EAFB (mRendInd * -1)
		mSCEESource = case when bRIO_QuiAnnule = 0 then ISNULL(CES.fCESG,0) else ISNULL(CED.fCESG,0) end, -- Montant de SCEE transféré
		mSCEEPlusSource = case when bRIO_QuiAnnule = 0 then ISNULL(CES.fACESG,0) else ISNULL(CED.fACESG,0) end, -- Montant de SCEE+ transféré
		mBECSource = case when bRIO_QuiAnnule = 0 then ISNULL(CES.fCLB,0) else ISNULL(CED.fCLB,0) end, -- Montant de BEC transféré
		mIntSource = case when bRIO_QuiAnnule = 0 then ISNULL(OC.SInt,0) else ISNULL(OCD.DInt,0) end, -- Montant d'intérêts transféré
		
		mIQEESource =	case when bRIO_QuiAnnule = 0 then ISNULL(IQEES.IQEE,0) ELSE ISNULL(IQEED.IQEE,0) END,
        mRendIQEESource = case when bRIO_QuiAnnule = 0 then ISNULL(IQEES.RendIQEE,0) ELSE ISNULL(IQEED.RendIQEE,0) END,
        mIQEEMajSource = case when bRIO_QuiAnnule = 0 then ISNULL(IQEES.IQEEMaj,0) ELSE ISNULL(IQEED.IQEEMaj,0) END,
        mRendIQEEMajSource = case when bRIO_QuiAnnule = 0 then ISNULL(IQEES.RendIQEEMaj,0) ELSE ISNULL(IQEED.RendIQEEMaj,0) END,
        mRendIQEETinSource = case when bRIO_QuiAnnule = 0 then ISNULL(IQEES.RendIQEETin,0) ELSE ISNULL(IQEED.RendIQEETin,0) END,
        
        SITR = case when bRIO_QuiAnnule = 0 then ISNULL(RTS.ITR,0) ELSE ISNULL(RTD.ITR,0) END,
		SINM = case when bRIO_QuiAnnule = 0 then ISNULL(RTS.INM,0) ELSE ISNULL(RTD.INM,0) END,
        
		vcConventionNoDest = case when bRIO_QuiAnnule = 0 then CD.ConventionNo ELSE CS.ConventionNo END, -- Numéro de la convention créée lors du TRI
		mCotisationDest = case when bRIO_QuiAnnule = 0 then ISNULL(CO2.Cotisation,0) ELSE ISNULL(CO1.Cotisation,0) END, -- Montant de cotisations reçu
		mFraisDest = case when bRIO_QuiAnnule = 0 then ISNULL(CO2.Fee,0) ELSE ISNULL(CO1.Fee,0) END, -- Montant de frais reçu
		mSCEEDest = case when bRIO_QuiAnnule = 0 then ISNULL(CED.fCESG,0) ELSE ISNULL(CES.fCESG,0) END, -- Montant de SCEE reçu
		mSCEEPlusDest = case when bRIO_QuiAnnule = 0 then ISNULL(CED.fACESG,0) ELSE ISNULL(CES.fACESG,0) END, -- Montant de SCEE+ reçu
		mBECDest = case when bRIO_QuiAnnule = 0 then ISNULL(CED.fCLB,0) ELSE ISNULL(CES.fCLB,0) END, -- Montant de BEC reçu
		mIntDest = case when bRIO_QuiAnnule = 0 then ISNULL(OCD.DInt,0) ELSE ISNULL(OC.SInt,0) END, -- Montant d'intérêt reçu

		mIQEEDest =	case when bRIO_QuiAnnule = 0 then ISNULL(IQEED.IQEE,0) ELSE ISNULL(IQEES.IQEE,0) END,
        mRendIQEEDest = case when bRIO_QuiAnnule = 0 then ISNULL(IQEED.RendIQEE,0) ELSE ISNULL(IQEES.RendIQEE,0) END,
        mIQEEMajDest = case when bRIO_QuiAnnule = 0 then ISNULL(IQEED.IQEEMaj,0) ELSE ISNULL(IQEES.IQEEMaj,0) END,
        mRendIQEEMajDest = case when bRIO_QuiAnnule = 0 then ISNULL(IQEED.RendIQEEMaj,0) ELSE ISNULL(IQEES.RendIQEEMaj,0) END,
        mRendIQEETinDest = case when bRIO_QuiAnnule = 0 then ISNULL(IQEED.RendIQEETin,0) ELSE ISNULL(IQEES.RendIQEETin,0) END,

		mSomme =  -- Somme de tous les montants du TRI pour vérifier que tout balance
			ISNULL(CO1.Cotisation,0) 
			+ ISNULL(CO1.Fee,0) 
			+ ISNULL(CES.fCESG,0) 
			+ ISNULL(CES.fACESG,0) 
			+ ISNULL(CES.fCLB,0) 
			+ ISNULL(OC.SInt,0) 
			+ ISNULL(CO2.Cotisation,0) 
			+ ISNULL(CO2.Fee,0)
			+ ISNULL(CED.fCESG,0) 
			+ ISNULL(CED.fACESG,0) 
			+ ISNULL(CED.fCLB,0) 
			+ ISNULL(OCD.DInt,0),
			
		mRendIndDest = case when bRIO_QuiAnnule = 0 then ISNULL(INMD.mRendInd,0) ELSE ISNULL(INMS.mRendInd,0) END  --Montant des revenus accumulés sur l’épargne calculé au moment du transfert
				
	FROM tblOPER_OperationsRIO R
	JOIN Un_Oper O ON O.OperID = R.iID_Oper_RIO
	
	JOIN dbo.Un_Convention CS ON CS.ConventionID = R.iID_Convention_Source
	JOIN UN_PLAN PS ON PS.PlanID = CS.PlanID
	JOIN @tblTEMP_Regroupements RRS ON RRS.iID_Regroupement_Regime = PS.iID_Regroupement_Regime
	JOIN dbo.Un_Unit US ON US.UnitID = R.iID_Unite_Source
	JOIN dbo.Mo_Human HS ON HS.HumanID = CS.SubscriberID

	JOIN dbo.Un_Convention CD ON CD.ConventionID = R.iID_Convention_Destination
	JOIN UN_PLAN PD ON PD.PlanID = CD.PlanID
	JOIN @tblTEMP_Regroupements RRD ON RRD.iID_Regroupement_Regime = PD.iID_Regroupement_Regime
	JOIN dbo.Un_Unit UD ON UD.UnitID = R.iID_Unite_Destination
	
	LEFT JOIN Un_Cotisation CO1 ON CO1.UnitID = R.iID_Unite_Source AND CO1.OperID = O.OperID
	LEFT JOIN Un_Cotisation CO2 ON CO2.UnitID = R.iID_Unite_Destination AND CO2.OperID = O.OperID
	LEFT JOIN Un_CESP CES ON CES.ConventionID = R.iID_Convention_Source AND CES.OperID = O.OperID
	LEFT JOIN Un_CESP CED ON CED.ConventionID = R.iID_Convention_Destination AND CED.OperID = O.OperID
	LEFT JOIN ( -- Intérêts PCEE transférés pour chaque opération TRI
		SELECT 
			ConventionID, 
			OperID,
			SInt = ISNULL(SUM(ConventionOperAmount),0)
		FROM Un_ConventionOper
		WHERE ConventionOperTypeID IN ('INS','IS+','IBC','IST')
		GROUP BY 
			ConventionID, 
			OperID
		) OC ON OC.ConventionID = R.iID_Convention_Source AND OC.OperID = O.OperID
	LEFT JOIN ( -- Intérêts reçus pour chaque opération TRI
		SELECT 
			ConventionID, 
			OperID,
			DInt = ISNULL(SUM(ConventionOperAmount),0)
		FROM Un_ConventionOper  
		WHERE ConventionOperTypeID IN ('INS','IS+','IBC','IST')
		GROUP BY 
			ConventionID, 
			OperID
		) OCD ON OCD.ConventionID = R.iID_Convention_Destination AND OCD.OperID = O.OperID	
	LEFT JOIN (
		select
			conventionid,
			operid, --
            IQEE = SUM ( -- IQEE
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') = 'CBQ' THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            RendIQEE = SUM ( -- Rendement d'IQEE
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') IN ('ICQ', 'MIM', 'IIQ') THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            IQEEMaj = SUM ( -- Majoration (IQEE +)
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') = 'MMQ' THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            RendIQEEMaj = SUM ( -- Rendement de majoration (IQEE+)
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') = 'IMQ' THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            RendIQEETin = SUM ( -- Rendement IQEE provenant d'un TIN
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') IN ('III', 'IQI') THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            OperInt     = SUM ( -- Tous sauf l'IQEEE
                 CASE
						WHEN ISNULL(UCO.ConventionOperTypeID,'') NOT IN ('CBQ', 'ICQ', 'MIM', 'IIQ', 'MMQ', 'IMQ', 'III', 'IQI') THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 )
        from Un_ConventionOper UCO
		group by conventionid,operid 
		) IQEES ON O.operid = IQEES.operid and CS.Conventionid = IQEES.conventionID
	LEFT JOIN (
		select
			conventionid,
			operid, --
            IQEE = SUM (
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') = 'CBQ' THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
   END
                 ),
            RendIQEE = SUM (
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') IN ('ICQ', 'MIM', 'IIQ') THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            IQEEMaj = SUM (
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') = 'MMQ' THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            RendIQEEMaj = SUM (
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') = 'IMQ' THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            RendIQEETin = SUM (
                 CASE
                       WHEN ISNULL(UCO.ConventionOperTypeID,'') IN ('III', 'IQI') THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 ),
            OperInt     = SUM ( -- Tous sauf l'IQEEE
                 CASE
						WHEN ISNULL(UCO.ConventionOperTypeID,'') NOT IN ('CBQ', 'ICQ', 'MIM', 'IIQ', 'MMQ', 'IMQ', 'III', 'IQI') THEN ISNULL(UCO.ConventionOperAmount,0)
                 ELSE 0
                 END
                 )
        from Un_ConventionOper UCO
		group by conventionid,operid 
		) IQEED ON O.operid = IQEED.operid and CD.Conventionid = IQEED.conventionID
		
	LEFT JOIN ( -- Montant des revenus accumulés sur l’épargne calculé au moment du transfert
		SELECT 
			COP.ConventionID,
			AO.iID_Operation_Parent,
            mRendInd     = SUM ( 
                 CASE
						WHEN ISNULL(COP.ConventionOperTypeID,'')  = 'INM' THEN ISNULL(COP.ConventionOperAmount,0)
                 ELSE 0
                 END
                 )
		FROM tblOPER_AssociationOperations AO
		JOIN Un_ConventionOper COP ON COP.OperID = AO.iID_Operation_Enfant
		WHERE COP.ConventionOperTypeID IN ('INM')
		GROUP BY 
			COP.ConventionID, 
			AO.iID_Operation_Parent
		) INMS ON INMS.ConventionID = R.iID_Convention_Source AND INMS.iID_Operation_Parent = O.OperID
	LEFT JOIN ( -- Montant des revenus accumulés sur l’épargne calculé au moment du transfert
		SELECT 
			COP.ConventionID,
			AO.iID_Operation_Parent,
            mRendInd     = SUM ( 
                 CASE
						WHEN ISNULL(COP.ConventionOperTypeID,'')  = 'INM' THEN ISNULL(COP.ConventionOperAmount,0)
                 ELSE 0
                 END
                 )
		FROM tblOPER_AssociationOperations AO
		JOIN Un_ConventionOper COP ON COP.OperID = AO.iID_Operation_Enfant
		WHERE COP.ConventionOperTypeID IN ('INM')
		GROUP BY 
			COP.ConventionID, 
			AO.iID_Operation_Parent
		) INMD ON INMD.ConventionID = R.iID_Convention_Destination AND INMD.iID_Operation_Parent = O.OperID
	
	LEFT JOIN (
		SELECT 
			ConventionID, 
			O.OperID,
			ITR = ISNULL(SUM( case when ConventionOperTypeID = 'ITR' THEN ConventionOperAmount ELSE 0 END ),0),
			INM = ISNULL(SUM( case when ConventionOperTypeID = 'INM' THEN ConventionOperAmount ELSE 0 END ),0)
		FROM 
			Un_Oper O 
			JOIN Un_ConventionOper CO ON CO.OperID = O.OperID
		WHERE 
			LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) BETWEEN @dtDebut AND @dtFin
			AND ConventionOperTypeID IN ('ITR','INM')
			AND O.OperTypeID = 'TRI'
		GROUP BY 
			ConventionID, 
			O.OperID
		)RTS ON RTS.ConventionID = R.iID_Convention_Source AND RTS.OperID = O.OperID
	
	LEFT JOIN (
		SELECT 
			ConventionID, 
			O.OperID,
			ITR = ISNULL(SUM( case when ConventionOperTypeID = 'ITR' THEN ConventionOperAmount ELSE 0 END ),0),
			INM = ISNULL(SUM( case when ConventionOperTypeID = 'INM' THEN ConventionOperAmount ELSE 0 END ),0)
		FROM 
			Un_Oper O 
			JOIN Un_ConventionOper CO ON CO.OperID = O.OperID
		WHERE 
			LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) BETWEEN @dtDebut AND @dtFin
			AND ConventionOperTypeID IN ('ITR','INM')
			AND O.OperTypeID = 'TRI'
		GROUP BY 
			ConventionID, 
			O.OperID
		)RTD ON RTD.ConventionID = R.iID_Convention_Destination AND RTD.OperID = O.OperID
	
	WHERE 
		LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) BETWEEN @dtDebut AND @dtFin -- Date de l'opération RIM dans la période choisie
		AND O.OperTypeID = 'TRI' -- On ne veut que les opération TRI (PAS RIM ni RIO)

		AND (
			ISNULL(CO2.Cotisation,0) <> 0 OR
			ISNULL(CO2.Fee,0) <> 0 OR
			ISNULL(CED.fCESG,0) <> 0 OR
			ISNULL(CED.fACESG,0) <> 0 OR
			ISNULL(CED.fCLB,0) <> 0 OR
			ISNULL(OCD.DInt,0) <> 0 OR
			ISNULL(IQEED.IQEE,0) <> 0 OR
			ISNULL(IQEED.RendIQEE,0) <> 0 OR
			ISNULL(IQEED.IQEEMaj,0) <> 0 OR
			ISNULL(IQEED.RendIQEEMaj,0) <> 0 OR
			ISNULL(IQEED.RendIQEETin,0) <> 0
			OR ISNULL(RTS.ITR,0) <> 0
			OR ISNULL(RTD.ITR,0) <> 0
			OR ISNULL(RTS.INM,0) <> 0
			OR ISNULL(RTD.INM,0) <> 0
			
			)

	ORDER BY 
		convert(varchar(10),O.OperDate,120),
		HS.LastName,
		HS.FirstName,
		CS.ConventionNo
END

-- EXEC psOPER_ObtenirRapportTRI '2008-07-01', '2008-07-31'
/*  Sequence de test - par: PLS - 2008-08-20
	EXEC psOPER_ObtenirRapportTRI
		@dtDebut = '2008-07-01', -- Date de début saisie
		@dtFin = '2008-07-31' -- Date de fin saisie
*/


