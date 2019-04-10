/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	psOPER_RapportSommaireFiducieRegimeIndividuel
Description         :	Rapprot des solde d'épargne, subvention et rendement des convention individuelles
Valeurs de retours  :	Dataset de données

Note                :	
					2013-01-23	Donald Huppé	Création :  GLPI 8974
					2013-11-28	Donald Huppé	Demande de C. Huppé : modification de la l'attribution du TypeConvention :
													Total RIO = Conventions « T » (RIO) + Convention « M » (RIM)
													Total autre = Conventions « I » d’origine + convention « I » issue d’un TRI
					2013-11-29	Donald Huppé	Ajout des compte d'IQEE suivant : MIM et IQI (oublié lors de la création du rapport)
					2014-03-04	Donald Huppé	glpi 11092 : ajouter (and o.OperDate <= @dtDateTo) dans le join "r" afin de pouvoir remonter dans le passé
					2018-10-16	Donald Huppé	CORRECTION BUG : IL MANQUAIT IMQ, MIM, IQI <> 0 DANS LE WHERE À LA FIN
			
exec psOPER_RapportSommaireFiducieRegimeIndividuel '2018-09-01'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportSommaireFiducieRegimeIndividuel] (
	@dtDateTo DATETIME -- Date de fin de l'intervalle des opérations
	)
AS
BEGIN

	SELECT
		U.ConventionID,
		Épargne = SUM(Ct.Cotisation /*+ Ct.Fee*/)
	INTO #tCotisation
	FROM dbo.Un_Unit U 
	JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
	WHERE Ct.OperID IN (
		SELECT O.OperID
		FROM Un_Oper O 
		JOIN Un_OperType  OT ON OT.OperTypeID = O.OperTypeID
		WHERE O.OperDate <= @dtDateTo -- Opération de la période sélectionnée.
			AND( OT.TotalZero = 0 -- Exclu les opérations de type BEC ou TFR
				OR O.OperTypeID = 'TRA' -- Inclus les TRA
				)
		)
	GROUP BY
		U.ConventionID

	SELECT 
		TypeConvention = CASE WHEN r.iID_Convention_Destination IS NOT NULL 
						AND (c.ConventionNo LIKE 'T%' or c.ConventionNo LIKE 'M%' ) THEN 'RIO' ELSE 'Autre' end,
		C.conventionno,
		DateOuverture,
		Épargne = isnull(Épargne,0),
		RendInd = isnull(RendInd,0),
		SCEE = ISNULL(SCEE,0) + ISNULL(SCEEPlus,0),
		RendSCEE = ISNULL(INS,0) + ISNULL(IST,0) + ISNULL(ISPlus,0),
		BEC = ISNULL(BEC,0),
		RendBEC = ISNULL(IBC,0),
		IQEE = ISNULL(IQEEBase,0) + ISNULL(IQEEMajore,0),
		RendIQEE = ISNULL(ICQ,0) + ISNULL(III,0) + ISNULL(IIQ,0) + ISNULL(IMQ,0) + ISNULL(MIM,0) + ISNULL(IQI,0)
		
	FROM dbo.Un_Convention c
	JOIN Un_Plan P ON c.PlanID = P.PlanID AND p.PlanTypeID = 'IND'
	LEFT JOIN (
		SELECT 
			CONVENTIONID,
			DateOuverture  = min(InForceDate)
		FROM dbo.Un_Unit 
		GROUP BY ConventionID
		)V2 ON c.ConventionID = V2.ConventionID
	left JOIN (
		select 
			c.ConventionID,			

			IQEEBase = sum(case when co.conventionopertypeid = 'CBQ' then ConventionOperAmount else 0 end ),
			IQEEMajore = sum(case when co.conventionopertypeid = 'MMQ' then ConventionOperAmount else 0 end ),
			
			RendInd = sum(case when co.conventionopertypeid IN ( 'INM','ITR') then ConventionOperAmount else 0 end ),
			IBC = sum(case when co.conventionopertypeid = 'IBC' then ConventionOperAmount else 0 end ),
			ICQ = sum(case when co.conventionopertypeid = 'ICQ' then ConventionOperAmount else 0 end ),
			III = sum(case when co.conventionopertypeid = 'III' then ConventionOperAmount else 0 end ),
			IIQ = sum(case when co.conventionopertypeid = 'IIQ' then ConventionOperAmount else 0 end ),
			IMQ = sum(case when co.conventionopertypeid = 'IMQ' then ConventionOperAmount else 0 end ),
			MIM = sum(case when co.conventionopertypeid = 'MIM' then ConventionOperAmount else 0 end ),
			IQI = sum(case when co.conventionopertypeid = 'IQI' then ConventionOperAmount else 0 end ),
			INS = sum(case when co.conventionopertypeid = 'INS' then ConventionOperAmount else 0 end ),
			ISPlus = sum(case when co.conventionopertypeid = 'IS+' then ConventionOperAmount else 0 end ),
			IST = sum(case when co.conventionopertypeid = 'IST' then ConventionOperAmount else 0 end )
		from 
			un_conventionoper co
			join Un_Oper o ON co.OperID = o.OperID
			JOIN dbo.Un_Convention c on co.conventionid = c.conventionid
			JOIN Un_Plan P ON c.PlanID = P.PlanID
		where 1=1
		and p.PlanTypeID = 'IND'
		and LEFT(CONVERT(VARCHAR, o.operdate, 120), 10) <= @dtDateTo
		and co.conventionopertypeid in( 'CBQ','MMQ','IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','ITR','MIM','IQI')
		GROUP BY c.ConventionID
		) v on c.ConventionID = v.ConventionID
	left join (
		select 
			ce.conventionid,
			SCEE = sum(fcesg),
			SCEEPlus = sum(facesg),
			BEC = sum(fCLB)
		from un_cesp ce
		JOIN dbo.Un_Convention c on ce.conventionid = c.conventionid
		JOIN Un_Plan P ON c.PlanID = P.PlanID
		join un_oper op on ce.operid = op.operid
		where op.operdate <= @dtDateTo
		and p.PlanTypeID = 'IND'
		group by ce.conventionid
		)scee on c.conventionid = scee.conventionid
	left JOIN #tCotisation ct ON c.ConventionID = ct.conventionid
	left join (
		SELECT DISTINCT rio.iID_Convention_Destination, c.ConventionNo
		from tblOPER_OperationsRIO rio
		join Un_Oper o ON rio.iID_Oper_RIO = o.OperID
		JOIN dbo.Un_Convention c ON rio.iID_Convention_Destination = c.ConventionID
		where rio.OperTypeID IN ( 'RIO','RIM')
		--AND rio.bRIO_Annulee = 0
		and rio.bRIO_QuiAnnule = 0
		and o.OperDate <= @dtDateTo
			) r on v.conventionid = r.iID_Convention_Destination
	WHERE 1=1 
	
	AND (
		Isnull(Épargne,0) <> 0
		OR isnull(RendInd,0) <> 0
		OR ISNULL(SCEE,0) <> 0
		OR ISNULL(SCEEPlus,0) <> 0
		OR ISNULL(INS,0) <>0
		OR ISNULL(IST,0) <> 0
		OR ISNULL(ISPlus,0) <> 0
		OR ISNULL(BEC,0) <> 0
		OR ISNULL(IBC,0) <> 0
		OR ISNULL(IQEEBase,0) <> 0
		OR ISNULL(IQEEMajore,0) <> 0
		OR ISNULL(ICQ,0) <>0
		OR ISNULL(III,0) <> 0
		OR ISNULL(IIQ,0) <> 0 
		OR ISNULL(IMQ,0) <> 0
		OR ISNULL(MIM,0) <> 0
		OR ISNULL(IQI,0) <> 0
		)
		
	ORDER by 
		CASE WHEN r.iID_Convention_Destination IS NOT NULL THEN 'RIO' ELSE 'Autre' end,
		C.conventionno

END


