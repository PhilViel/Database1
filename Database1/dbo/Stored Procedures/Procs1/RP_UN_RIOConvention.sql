/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_RIOConvention
Description         :	Rapport : Détails des RIO faits sur les groupes d'unités entre deux dates sélectionnées 
Valeurs de retours  :	Dataset :
					iID_Oper_RIO			INTEGER		ID de l'opération RIO			
					dtDate_Enregistrement	DATETIME	Date de l'enregistrement du RIO
					FirstName				VARCHAR(35)	Prénom du souscripteur
					LastName				VARCHAR(50)	Nom de famille du souscripteur
					ConventionNo			VARCHAR(15)	Numéro de la convention source
					InForceDate				DATETIME	Date d'entrée en vigeur du groupe d'unité source
					UnitQty					MONEY		Nombre d'unité du groupe d'unité source	
					SCotisation				MONEY		Montant de cotisations transféré
					SFrais					MONEY		Montant de frais transféré
					SSCEE					MONEY		Montant de SCEE transféré
					SSCEEPlus				MONEY		Montant de SCEE+ transféré
					SBEC					MONEY		Montant de BEC transféré
					SInt					MONEY		Montant d'intérêts transféré
					ConventionNo			VARCHAR(15)	Numéro de la convention créée lors du RIO
					DCotisation				MONEY		Montant de cotisations reçu
					DFrais					MONEY		Montant de frais reçu
					DSCEE					MONEY		Montant de SCEE reçu
					DSCEEPlus				MONEY		Montant de SCEE+ reçu
					DBEC					MONEY		Montant de BEC reçu
					DInt					MONEY		Montant d'intérêt reçu
					Somme					MONEY		Somme de tous les montants du RIO pour vérifier que tout balance
					mFraisServices			MONEY		Montant des frais de services (sans taxes) appliqués lors du transfert
					mTPS					MONEY		Montant de la TPS appliquée sur les frais de service
					mTVQ					MONEY		Montant de la TVQ appliquée sur les frais de services + TPS
					FraisTransfEpargne		MONEY		Montant des frais transférés à l'épargne

Note                :			2008-08-20	Pierre-Luc Simard		Création
								2009-12-17	Donald Huppé			Ajout de l'IQEE
								2010-03-31	Donald Huppé			Mettre un filtre pour que sorte seulement les transfert avec montant <> 0
																	car depusi ce mois, des opération avec montant à 0 apparaissent
								2010-04-27	Donald Huppé			Ajustement pour gérer les annulation etc.  Par terminé concernant bRio_QuiAnnule (dans quelle colonne on met  les annulation ? En attente de Anne.
								2010-06-10	Donald Huppé			Ajout des régime et groupe de régime
								2010-09-01	Donald Huppé			Dans la clause where : dbo.FN_CRQ_DateNoTime(O.operdate) au lieu de seulement O.operdate (GLPI 4149)
								2011-04-04	Corentin Menthonnex		2011-12 : Ajout des informations de frais de services + TPS + TVQ et inversion du tri Nom VS Prénom
								2011-05-11	Corentin Menthonnex		2011-12 : Modification du montant de l'épargne de destination qui ne doit pas inclure les frais de service.
								2011-09-02	Donald Huppé			On va chercher les frais qui ne sont pas annulés
								2011-09-27	Donald Huppé			Demande de Isabelle Ouellet : Correction de la modification précédente concernant les frais : On prend les frais qui ne sont pas "encore" annulé en date de fin
								2013-02-26	Donald Huppé			glpi 9201. Et modifs pour créer des table temporaire afin d'améliorer la performance.  
																	surtout pour l'utilisation de la fonction fnOPER_ObtenirMontantTaxeFrais
								2013-04-29	Pierre-Luc Simard	Ajout du SET NOCOUNT ON pour que ça fonctionne en Access
								
exec RP_UN_RIOConvention '1950-01-01', '2012-12-31'
select * from un_reptreatment
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RIOConvention] (	
	@dtStart DATETIME, -- Date de début saisie
	@dtEnd DATETIME) -- Date de fin saisie
AS
BEGIN

SET NOCOUNT ON

	select
		conventionid,
		UCO.operid, --
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
    INTO #IQEE
    from 
		Un_Oper O
		--JOIN tblOPER_OperationsRIO R ON R.iID_Oper_RIO = O.OperID
		JOIN Un_ConventionOper UCO ON UCO.OperID = O.OperID
	WHERE 
		LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd
		AND O.OperTypeID = 'RIO'
	group by conventionid,UCO.operid 

	SELECT 
		ConventionID, 
		O.OperID,
		ITR = ISNULL(SUM( case when ConventionOperTypeID = 'ITR' THEN ConventionOperAmount ELSE 0 END ),0),
		INM = ISNULL(SUM( case when ConventionOperTypeID = 'INM' THEN ConventionOperAmount ELSE 0 END ),0)
	INTO #RT
	FROM 
		Un_Oper O 
		JOIN Un_ConventionOper CO ON CO.OperID = O.OperID
	WHERE 
		LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd
		AND ConventionOperTypeID IN ('ITR','INM')
		AND O.OperTypeID = 'RIO'
	GROUP BY 
		ConventionID, 
		O.OperID

	-- Intérêts PCEE transférés pour chaque opération RIO
	SELECT 
		ConventionID, 
		CO.OperID,
		Interet = ISNULL(SUM(ConventionOperAmount),0)
	INTO #OC
	FROM 
		Un_Oper O 
		JOIN Un_ConventionOper CO ON CO.OperID = O.OperID
	WHERE 
		LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd
		AND ConventionOperTypeID IN ('INS','IS+','IBC','IST')
		AND O.OperTypeID = 'RIO'
	GROUP BY 
		ConventionID, 
		CO.OperID

	SELECT 
		iID_Operation_Parent = case when  isnull(LEFT(CONVERT(VARCHAR, Frais.dtDate_Annulation, 120), 10),'3000-01-01') <= @dtEnd THEN 0 ELSE AO.iID_Operation_Parent end,
        FRAIS.iID_Frais,
        FRAIS.mMontant_Frais,
        FraisTaxTPS = dbo.fnOPER_ObtenirMontantTaxeFrais(iID_Frais, 'OPER_TAXE_TPS'),
        FraisTaxTVQ = dbo.fnOPER_ObtenirMontantTaxeFrais(iID_Frais, 'OPER_TAXE_TVQ')
    into #FRS
	FROM tblOPER_AssociationOperations AO
	JOIN tblOPER_Frais FRAIS ON AO.iID_Operation_Enfant = FRAIS.iID_Oper

	SELECT --DISTINCT

		R.iID_Oper_RIO, -- ID de l'opération RIO			
		dtDate_Enregistrement = convert(varchar(10),O.OperDate,120), -- Date de l'enregistrement du RIO
		HS.LastName, -- Nom de famille du souscripteur
		HS.FirstName, -- Prénom du souscripteur
		
		Regime = case when bRIO_QuiAnnule = 0 then PS.PlanDesc else PD.PlanDesc end,
		GrRegime = case when bRIO_QuiAnnule = 0 then RRS.vcDescription else RRD.vcDescription end,
		OrderOfPlanInReport = case when bRIO_QuiAnnule = 0 then PS.OrderOfPlanInReport else PD.OrderOfPlanInReport end,			
		
		SConventionNo = case when bRIO_QuiAnnule = 0 then CS.ConventionNo else CD.ConventionNo end, -- Numéro de la convention source
		InForceDate = convert(varchar(10),US.InForceDate,120), -- Date d'entrée en vigeur du groupe d'unité source
		US.UnitQty, -- Nombre d'unité du groupe d'unité source	
		SCotisation = case when bRIO_QuiAnnule = 0 then ISNULL(CO1.Cotisation,0) else ISNULL(CO2.Cotisation,0) end, -- Montant de cotisations transféré
		SFrais = case when bRIO_QuiAnnule = 0 then ISNULL(CO1.Fee,0) else ISNULL(CO2.Fee,0) end, -- Montant de frais transféré
		SSCEE = case when bRIO_QuiAnnule = 0 then ISNULL(CES.fCESG,0) else ISNULL(CED.fCESG,0) end, -- Montant de SCEE transféré
		SSCEEPlus = case when bRIO_QuiAnnule = 0 then ISNULL(CES.fACESG,0) else ISNULL(CED.fACESG,0) end, -- Montant de SCEE+ transféré
		SBEC = case when bRIO_QuiAnnule = 0 then ISNULL(CES.fCLB,0) else ISNULL(CED.fCLB,0) end, -- Montant de BEC transféré
		SInt = case when bRIO_QuiAnnule = 0 then ISNULL(OC.Interet,0) else ISNULL(OCD.Interet,0) end, -- Montant d'intérêts transféré
		
		SIQEE =	case when bRIO_QuiAnnule = 0 then ISNULL(IQEES.IQEE,0) ELSE ISNULL(IQEED.IQEE,0) END,
        SRendIQEE = case when bRIO_QuiAnnule = 0 then ISNULL(IQEES.RendIQEE,0) ELSE ISNULL(IQEED.RendIQEE,0) END,
        SIQEEMaj = case when bRIO_QuiAnnule = 0 then ISNULL(IQEES.IQEEMaj,0) ELSE ISNULL(IQEED.IQEEMaj,0) END,
        SRendIQEEMaj = case when bRIO_QuiAnnule = 0 then ISNULL(IQEES.RendIQEEMaj,0) ELSE ISNULL(IQEED.RendIQEEMaj,0) END,
        SRendIQEETin = case when bRIO_QuiAnnule = 0 then ISNULL(IQEES.RendIQEETin,0) ELSE ISNULL(IQEED.RendIQEETin,0) END,
        
        SITR = case when bRIO_QuiAnnule = 0 then ISNULL(RTS.ITR,0) ELSE ISNULL(RTD.ITR,0) END,
		SINM = case when bRIO_QuiAnnule = 0 then ISNULL(RTS.INM,0) ELSE ISNULL(RTD.INM,0) END,
        
		DConventionNo = case when bRIO_QuiAnnule = 0 then CD.ConventionNo ELSE CS.ConventionNo END, -- Numéro de la convention créée lors du RIO
	
		DCotisation = case when bRIO_QuiAnnule = 0 
			then (ISNULL(CO2.Cotisation,0) - ISNULL(FRS.mMontant_Frais, 0) - ISNULL(FRS.FraisTaxTPS, 0) - ISNULL(FRS.FraisTaxTVQ, 0))
			ELSE (ISNULL(CO1.Cotisation,0) - ISNULL(FRS.mMontant_Frais, 0) - ISNULL(FRS.FraisTaxTPS, 0) - ISNULL(FRS.FraisTaxTVQ, 0))
			END, -- Montant de cotisations reçu ( moins les frais de service)
		
		DFrais = case when bRIO_QuiAnnule = 0 then ISNULL(CO2.Fee,0) ELSE ISNULL(CO1.Fee,0) END, -- Montant de frais reçu
		DSCEE = case when bRIO_QuiAnnule = 0 then ISNULL(CED.fCESG,0) ELSE ISNULL(CES.fCESG,0) END, -- Montant de SCEE reçu
		DSCEEPlus = case when bRIO_QuiAnnule = 0 then ISNULL(CED.fACESG,0) ELSE ISNULL(CES.fACESG,0) END, -- Montant de SCEE+ reçu
		DBEC = case when bRIO_QuiAnnule = 0 then ISNULL(CED.fCLB,0) ELSE ISNULL(CES.fCLB,0) END, -- Montant de BEC reçu
		DInt = case when bRIO_QuiAnnule = 0 then ISNULL(OCD.Interet,0) ELSE ISNULL(OC.Interet,0) END, -- Montant d'intérêt reçu

		DIQEE =	case when bRIO_QuiAnnule = 0 then ISNULL(IQEED.IQEE,0) ELSE ISNULL(IQEES.IQEE,0) END,
        DRendIQEE = case when bRIO_QuiAnnule = 0 then ISNULL(IQEED.RendIQEE,0) ELSE ISNULL(IQEES.RendIQEE,0) END,
        DIQEEMaj = case when bRIO_QuiAnnule = 0 then ISNULL(IQEED.IQEEMaj,0) ELSE ISNULL(IQEES.IQEEMaj,0) END,
        DRendIQEEMaj = case when bRIO_QuiAnnule = 0 then ISNULL(IQEED.RendIQEEMaj,0) ELSE ISNULL(IQEES.RendIQEEMaj,0) END,
        DRendIQEETin = case when bRIO_QuiAnnule = 0 then ISNULL(IQEED.RendIQEETin,0) ELSE ISNULL(IQEES.RendIQEETin,0) END,

		Somme =  -- Somme de tous les montants du RIO pour vérifier que tout balance
			ISNULL(CO1.Cotisation,0) 
			+ ISNULL(CO1.Fee,0) 
			+ ISNULL(CES.fCESG,0) 
			+ ISNULL(CES.fACESG,0) 
			+ ISNULL(CES.fCLB,0) 
			+ ISNULL(OC.Interet,0) 
			+ ISNULL(CO2.Cotisation,0) 
			+ ISNULL(CO2.Fee,0)
			+ ISNULL(CED.fCESG,0) 
			+ ISNULL(CED.fACESG,0) 
			+ ISNULL(CED.fCLB,0) 
			+ ISNULL(OCD.Interet,0),
			
		mFraisServices = ISNULL(FRS.mMontant_Frais, 0), -- Montant des frais de services
		
		mTPS = ISNULL(FRS.FraisTaxTPS, 0), -- Montant de la TPS applicable sur le montant des frais de services
		mTVQ = ISNULL(FRS.FraisTaxTVQ, 0), -- Montant de la TVQ applicable sur frais + TPS
		
		FraisTransfEpargne = ABS(ISNULL(CO1.Fee,0))-ISNULL(CO2.Fee,0) -- Montant des frais transférés à l'épargne
		
	FROM tblOPER_OperationsRIO R
	JOIN Un_Oper O ON O.OperID = R.iID_Oper_RIO 
	
	JOIN dbo.Un_Convention CS ON CS.ConventionID = R.iID_Convention_Source
	JOIN dbo.Un_Unit US ON  US.ConventionID = CS.ConventionID AND US.UnitID = R.iID_Unite_Source
	JOIN UN_PLAN PS ON PS.PlanID = CS.PlanID
	JOIN tblCONV_RegroupementsRegimes RRS ON RRS.iID_Regroupement_Regime = PS.iID_Regroupement_Regime
	JOIN dbo.Mo_Human HS ON HS.HumanID = CS.SubscriberID

	JOIN dbo.Un_Convention CD ON CD.ConventionID = R.iID_Convention_Destination
	JOIN dbo.Un_Unit UD ON UD.ConventionID = CD.ConventionID AND UD.UnitID = R.iID_Unite_Destination
	JOIN UN_PLAN PD ON PD.PlanID = CD.PlanID
	JOIN tblCONV_RegroupementsRegimes RRD ON RRD.iID_Regroupement_Regime = PD.iID_Regroupement_Regime

	LEFT JOIN Un_Cotisation CO1 ON CO1.UnitID = R.iID_Unite_Source AND CO1.OperID = O.OperID 
	LEFT JOIN Un_Cotisation CO2 ON CO2.UnitID = R.iID_Unite_Destination AND CO2.OperID = O.OperID

	LEFT JOIN Un_CESP CES ON CES.ConventionID = R.iID_Convention_Source AND CES.OperID = O.OperID
	LEFT JOIN Un_CESP CED ON CED.ConventionID = R.iID_Convention_Destination AND CED.OperID = O.OperID
	
	LEFT JOIN #OC OC ON OC.ConventionID = R.iID_Convention_Source AND OC.OperID = O.OperID
	LEFT JOIN #OC OCD ON OCD.ConventionID = R.iID_Convention_Destination AND OCD.OperID = O.OperID
		
	LEFT JOIN #IQEE IQEES ON O.operid = IQEES.operid and CS.Conventionid = IQEES.conventionID
	LEFT JOIN #IQEE IQEED ON O.operid = IQEED.operid and CD.Conventionid = IQEED.conventionID
		
	LEFT JOIN #FRS FRS ON FRS.iID_Operation_Parent = O.OperID -- Ajout des informations de frais de service s'il y en a
		
	LEFT JOIN #RT RTS ON RTS.ConventionID = R.iID_Convention_Source AND RTS.OperID = O.OperID
	LEFT JOIN #RT RTD ON RTD.ConventionID = R.iID_Convention_destination AND RTD.OperID = O.OperID
	
	WHERE 1=1
	
		AND O.OperTypeID = 'RIO' -- On ne veut que les opération RIO (PAS TRI ni RIM)
		AND LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) BETWEEN @dtStart AND @dtEnd -- Date de l'opération RIO dans la période choisie

		AND (
			ISNULL(CO2.Cotisation,0) <> 0 OR
			ISNULL(CO2.Fee,0) <> 0 OR
			ISNULL(CED.fCESG,0) <> 0 OR
			ISNULL(CED.fACESG,0) <> 0 OR
			ISNULL(CED.fCLB,0) <> 0 OR
			ISNULL(OCD.Interet,0) <> 0 OR
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


