

/********************************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	psCONV_ReleveDeCompte_FraisDispo
Description         :	retourne les frais disponible à une convention ou un souscripteur.
						Pour le relevé de compte
Valeurs de retours  :	Dataset de données


exec psCONV_ReleveDeCompte_FraisDispo  @SubscriberID = 575993
exec psCONV_ReleveDeCompte_FraisDispo  @conventionNO ='u-20080529038' 'U-20040226011'  'R-20100111011' 'X-20110504007' 'X-20110418028'  'U-20040521042' -- 'R-20061017031'




Note                :
	
					2015-02-18	Donald Huppé	Création 

*********************************************************************************************************************/

CREATE PROCEDURE [dbo].[psCONV_ReleveDeCompte_FraisDispo] (
		@SubscriberID int = null
		,@conventionNO varchar(30) = NULL -- '2025720'

	)
AS
BEGIN

declare
	@dtDateTo datetime = '2015-12-31'
	 


	-- échantillon de conventions
	
	SELECT Distinct c.ConventionID
	INTO #ConventionRC
	FROM Un_Convention c
	WHERE 
		(@SubscriberID is NOT null AND c.SubscriberID = @SubscriberID)
		or (@conventionNO IS not null AND c.ConventionNo = @conventionNO)


	select 
		c.ConventionNo
		,QteUniteResiliee = sr.UnitRes
		,QteUniteDispo = ISNULL(SR.UnitRes,0) - ISNULL(SU.UnitUse,0)
		,FraisDispoParUnite = sr.FeeSumByUnit
		,FraisDispo = (ISNULL(SR.UnitRes,0) - ISNULL(SU.UnitUse,0)) * sr.FeeSumByUnit
		,FraisDispoTotalConv = isnull(AvailableFeeAmount,0)
		,DateExpiration
		,hs.LangID
		--,sr.UnitReductionID
		--,FeeByUnit =  isnull(AvailableFeeAmount / (ISNULL(SR.UnitRes,0) - ISNULL(SU.UnitUse,0)),0)
		--,QteUniteUtilisee = ISNULL(su.UnitUse,0)
	from Un_Convention c
	join Mo_Human hs on c.SubscriberID = hs.HumanID
	join #ConventionRC RC on c.ConventionID = rc.ConventionID
	JOIN ( -- Unité résiliés
			SELECT DISTINCT
				C.ConventionID, 
				ur.UnitReductionID,
				ur.FeeSumByUnit,
				UnitRes = UR.UnitQty,
				DateExpiration = DATEADD(MONTH,A.MonthAvailable,isnull(TRI.OperDateTRI,O.OperDate))
				--,TRI.OperDateTRI,O.OperDate
			FROM Un_UnitReduction UR
			JOIN Un_Unit U ON U.UnitID = UR.UnitID
			JOIN Un_Convention C ON C.ConventionID = U.ConventionID
			join #ConventionRC RC on c.ConventionID = rc.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN Un_UnitReductionCotisation URC ON URC.UnitReductionID = UR.UnitReductionID
			JOIN Un_Cotisation CT ON CT.CotisationID = URC.CotisationID
			JOIN Un_Oper O ON O.OperID = CT.OperID
			left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
			left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
			JOIN (
				SELECT 
					A1.AvailableFeeExpirationCfgID, 
					A1.StartDate, 
					A1.MonthAvailable, 
					EndDate = DATEADD(DAY, -1,MIN(ISNULL(A2.StartDate,DATEADD(DAY, 1, @dtDateTo))))
				FROM Un_AvailableFeeExpirationCfg  A1
				LEFT JOIN Un_AvailableFeeExpirationCfg A2 ON (A1.StartDate < A2.StartDate) OR ((A1.StartDate = A2.StartDate) AND (A1.AvailableFeeExpirationCfgID < A2.AvailableFeeExpirationCfgID))
				GROUP BY 
					A1.AvailableFeeExpirationCfgID, 
					A1.StartDate, 
					A1.MonthAvailable
				HAVING ISNULL(MIN(ISNULL(A2.StartDate,DATEADD(DAY, 1, @dtDateTo))),0) <> A1.StartDate
				) A ON (A.StartDate <= O.OperDate) AND (ISNULL(A.EndDate,@dtDateTo) > O.OperDate)		
		
			------------------ glpi 10583 ------------------------------
			LEFT JOIN (
				SELECT r.iID_Convention_Source, OperDateTRI = min(o.OperDate)
				FROM tblOPER_OperationsRIO r
				JOIN Un_Oper o ON r.iID_Oper_RIO = o.OperID
				WHERE bRIO_Annulee = 0
				AND bRIO_QuiAnnule = 0
				AND o.OperTypeID = 'TRI'
				GROUP BY r.iID_Convention_Source
				)TRI ON C.ConventionID = TRI.iID_Convention_Source

			WHERE ur.ReductionDate <= @dtDateTo
			AND oc1.OperSourceID is NULL
			and oc2.OperID is null
			and ur.UnitQty <> 0
			

			) SR ON SR.ConventionID = C.ConventionID
	LEFT JOIN ( -- Unité utilisés
			SELECT 
				C.ConventionID, 
				ur.UnitReductionID,
				ur.FeeSumByUnit ,
				UnitUse = SUM(A.fUnitQtyUse)
			FROM Un_UnitReduction UR
			JOIN Un_AvailableFeeUse A ON A.UnitReductionID = UR.UnitReductionID
			JOIN Un_Oper O on O.OperID = A.OperID
			JOIN Un_Unit U ON U.UnitID = UR.UnitID			
			JOIN Un_Convention C ON C.ConventionID = U.ConventionID
			join #ConventionRC RC on c.ConventionID = rc.ConventionID
			WHERE O.OperDate <= @dtDateTo
			--WHERE C.ConventionNo = 'X-20101115017'
			GROUP BY C.ConventionID, 
				ur.UnitReductionID,
				ur.FeeSumByUnit

			) SU ON SR.UnitReductionID = SU.UnitReductionID
	LEFT JOIN (-- Retourne la somme des frais disponibles par convention
		SELECT
			CO.ConventionID,
			--o.OperTypeID,
			AvailableFeeAmount = SUM(CO.ConventionOperAmount)
		FROM Un_ConventionOper CO
		JOIN Un_Oper O ON O.OperID = CO.OperID
		JOIN Un_Convention C ON C.ConventionID = CO.ConventionID
		join #ConventionRC RC on c.ConventionID = rc.ConventionID
		--WHERE C.ConventionNo = 'X-20101115017'
		WHERE CO.ConventionOperTypeID = 'FDI'
		AND O.OperDate <= @dtDateTo
		GROUP BY CO.ConventionID--,OperTypeID
		) CF ON CF.ConventionID = C.ConventionID


	where 
		(ISNULL(SR.UnitRes,0) - ISNULL(SU.UnitUse,0)) * sr.FeeSumByUnit > 0





end