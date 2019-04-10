/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	psOPER_ObtenirRapportRIM
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
					mFraisServices			MONEY		Montant des frais de services (sans taxes) appliqués lors du transfert
					mTPS					MONEY		Montant de la TPS appliquée sur les frais de service
					mTVQ					MONEY		Montant de la TVQ appliquée sur les frais de services + TPS
					mRendIndDest			MONEY		Montant des revenus accumulés sur l’épargne calculé au moment du transfert, ajouté à la destination
					mFraisTransfEpargne		MONEY		Montant des frais transférés à l'épargne
					
Note                :	2011-04-04	Corentin Menthonnex		Création, basée sur RP_UN_RIOConvention
						2011-05-11	Corentin Menthonnex		2011-12 : Modification du montant de l'épargne de destination qui ne doit pas inclure les frais de service.
						2014-06-02	Donald Huppé		Suite au RIM dans M-20140501001, on enlève la condition des comptes <> 0, car il ne sortait pas car 
														on ne vérifiait pas mRendInd.  Pour être certain, on enlève toutes les conditions. On ajustera au besoin.

exec psOPER_ObtenirRapportRIM '2014-05-01', '2014-05-30'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_ObtenirRapportRIM] (	
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
		iID_Operation_Parent = case when  isnull(LEFT(CONVERT(VARCHAR, Frais.dtDate_Annulation, 120), 10),'3000-01-01') <= @dtFin THEN 0 ELSE AO.iID_Operation_Parent end,
        FRAIS.iID_Frais,
        FRAIS.mMontant_Frais,
        FraisTaxTPS = dbo.fnOPER_ObtenirMontantTaxeFrais(iID_Frais, 'OPER_TAXE_TPS'),
        FraisTaxTVQ = dbo.fnOPER_ObtenirMontantTaxeFrais(iID_Frais, 'OPER_TAXE_TVQ')
    into #FRS
	FROM tblOPER_AssociationOperations AO
	JOIN tblOPER_Frais FRAIS ON AO.iID_Operation_Enfant = FRAIS.iID_Oper
	
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
		mCotisationDest = case when bRIO_QuiAnnule = 0 
			then (ISNULL(CO2.Cotisation,0) - ISNULL(FRS.mMontant_Frais, 0) - ISNULL(FRS.FraisTaxTPS, 0) - ISNULL(FRS.FraisTaxTVQ, 0))
			ELSE (ISNULL(CO1.Cotisation,0) - ISNULL(FRS.mMontant_Frais, 0) - ISNULL(FRS.FraisTaxTPS, 0) - ISNULL(FRS.FraisTaxTVQ, 0))
			END, -- Montant de cotisations reçu ( moins les frais de service)
		--mFraisDest = case when bRIO_QuiAnnule = 0 then ISNULL(CO2.Fee,0) ELSE ISNULL(CO1.Fee,0) END, -- Montant de frais reçu
		mSCEEDest = case when bRIO_QuiAnnule = 0 then ISNULL(CED.fCESG,0) ELSE ISNULL(CES.fCESG,0) END, -- Montant de SCEE reçu
		mSCEEPlusDest = case when bRIO_QuiAnnule = 0 then ISNULL(CED.fACESG,0) ELSE ISNULL(CES.fACESG,0) END, -- Montant de SCEE+ reçu
		mBECDest = case when bRIO_QuiAnnule = 0 then ISNULL(CED.fCLB,0) ELSE ISNULL(CES.fCLB,0) END, -- Montant de BEC reçu
		mIntDest = case when bRIO_QuiAnnule = 0 then ISNULL(OCD.DInt,0) ELSE ISNULL(OC.SInt,0) END, -- Montant d'intérêt reçu

		mIQEEDest =	case when bRIO_QuiAnnule = 0 then ISNULL(IQEED.IQEE,0) ELSE ISNULL(IQEES.IQEE,0) END,
        mRendIQEEDest = case when bRIO_QuiAnnule = 0 then ISNULL(IQEED.RendIQEE,0) ELSE ISNULL(IQEES.RendIQEE,0) END,
        mIQEEMajDest = case when bRIO_QuiAnnule = 0 then ISNULL(IQEED.IQEEMaj,0) ELSE ISNULL(IQEES.IQEEMaj,0) END,
        mRendIQEEMajDest = case when bRIO_QuiAnnule = 0 then ISNULL(IQEED.RendIQEEMaj,0) ELSE ISNULL(IQEES.RendIQEEMaj,0) END,
        mRendIQEETinDest = case when bRIO_QuiAnnule = 0 then ISNULL(IQEED.RendIQEETin,0) ELSE ISNULL(IQEES.RendIQEETin,0) END,

		mSomme =  -- Somme de tous les montants du RIM pour vérifier que tout balance
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
			
		mFraisServices = ISNULL(FRS.mMontant_Frais, 0), -- Montant des frais de services
		mTPS = ISNULL(FRS.FraisTaxTPS, 0), -- Montant de la TPS applicable sur le montant des frais de services
		mTVQ = ISNULL(FRS.FraisTaxTVQ, 0), -- Montant de la TVQ applicable sur frais + TPS
        mRendIndDest = case when bRIO_QuiAnnule = 0 then ISNULL(INMD.mRendInd,0) ELSE ISNULL(INMS.mRendInd,0) END,  --Montant des revenus accumulés sur l’épargne calculé au moment du transfert

		mFraisTransfEpargne = ABS(ISNULL(CO1.Fee,0))-ISNULL(CO2.Fee,0) -- Montant des frais transférés à l'épargne
		
	FROM tblOPER_OperationsRIO R

	JOIN dbo.Un_Convention CS ON CS.ConventionID = R.iID_Convention_Source
	JOIN UN_PLAN PS ON PS.PlanID = CS.PlanID
	JOIN @tblTEMP_Regroupements RRS ON RRS.iID_Regroupement_Regime = PS.iID_Regroupement_Regime
	JOIN dbo.Un_Unit US ON US.UnitID = R.iID_Unite_Source
	JOIN dbo.Mo_Human HS ON HS.HumanID = CS.SubscriberID

	JOIN dbo.Un_Convention CD ON CD.ConventionID = R.iID_Convention_Destination
	JOIN UN_PLAN PD ON PD.PlanID = CD.PlanID
	JOIN @tblTEMP_Regroupements RRD ON RRD.iID_Regroupement_Regime = PD.iID_Regroupement_Regime
	JOIN dbo.Un_Unit UD ON UD.UnitID = R.iID_Unite_Destination
	JOIN Un_Oper O ON O.OperID = R.iID_Oper_RIO

	LEFT JOIN Un_Cotisation CO1 ON CO1.UnitID = R.iID_Unite_Source AND CO1.OperID = R.iID_Oper_RIO
	LEFT JOIN Un_Cotisation CO2 ON CO2.UnitID = R.iID_Unite_Destination AND CO2.OperID = R.iID_Oper_RIO
	LEFT JOIN Un_CESP CES ON CES.ConventionID = R.iID_Convention_Source AND CES.OperID = R.iID_Oper_RIO
	LEFT JOIN Un_CESP CED ON CED.ConventionID = R.iID_Convention_Destination AND CED.OperID = R.iID_Oper_RIO
	LEFT JOIN ( -- Intérêts PCEE transférés pour chaque opération RIM
		SELECT 
			ConventionID, 
			OperID,
			SInt = ISNULL(SUM(ConventionOperAmount),0)
		FROM Un_ConventionOper
		WHERE ConventionOperTypeID IN ('INS','IS+','IBC','IST')
		GROUP BY 
			ConventionID, 
			OperID
		) OC ON OC.ConventionID = R.iID_Convention_Source AND OC.OperID = R.iID_Oper_RIO
	LEFT JOIN ( -- Intérêts reçus pour chaque opération RIM
		SELECT 
			ConventionID, 
			OperID,
			DInt = ISNULL(SUM(ConventionOperAmount),0)
		FROM Un_ConventionOper  
		WHERE ConventionOperTypeID IN ('INS','IS+','IBC','IST')
		GROUP BY 
			ConventionID, 
			OperID
		) OCD ON OCD.ConventionID = R.iID_Convention_Destination AND OCD.OperID = R.iID_Oper_RIO	
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
		
	LEFT JOIN #FRS FRS ON FRS.iID_Operation_Parent = R.iID_Oper_RIO-- Ajout des informations de frais de service s'il y en a
		
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
		) INMS ON INMS.ConventionID = R.iID_Convention_Source AND INMS.iID_Operation_Parent = R.iID_Oper_RIO
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
		) INMD ON INMD.ConventionID = R.iID_Convention_Destination AND INMD.iID_Operation_Parent = R.iID_Oper_RIO
		
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
			AND O.OperTypeID = 'RIM'
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
			AND O.OperTypeID = 'RIM'
		GROUP BY 
			ConventionID, 
			O.OperID
		)RTD ON RTD.ConventionID = R.iID_Convention_Destination AND RTD.OperID = O.OperID
		
	WHERE 
		LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) BETWEEN @dtDebut AND @dtFin -- Date de l'opération RIM dans la période choisie
		AND O.OperTypeID = 'RIM' -- On ne veut que les opération RIM (PAS TRI ni RIO)

		-- ceci est une erreur
		--AND CancelRIO.OperSourceID is NULL -- exclure les cancelations postérieures à la date de fin

		--AND R.bRIO_Annulee = 0 -- Pas annulé
		--AND R.bRIO_QuiAnnule = 0 -- Pas une annulation
/* -- 2014-06-02
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
			ISNULL(IQEED.RendIQEETin,0) <> 0 OR
			ISNULL(INMD.mRendInd,0) <> 0
			)
*/
	ORDER BY 
		convert(varchar(10),O.OperDate,120),
		HS.LastName,
		HS.FirstName,
		CS.ConventionNo
END

-- EXEC psOPER_ObtenirRapportRIM '2008-07-01', '2008-07-31'
/*  Sequence de test - par: PLS - 2008-08-20
	EXEC psOPER_ObtenirRapportRIM
		@dtDebut = '2008-07-01', -- Date de début saisie
		dtFin = '2008-07-31' -- Date de fin saisie
*/


