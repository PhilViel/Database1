
CREATE VIEW [dbo].[vw_MontantCumulatifDemandePRA] AS
	SELECT DP.IdSouscripteur, DP.TypeDestination, --Co.ConventionOperTypeID, O.OperTypeID,
		   MontantBrutDecaisser = Sum(CASE WHEN CO.ConventionOperTypeID <> 'RTN' And O.OperTypeID = 'PRA' THEN -CO.ConventionOperAmount ELSE 0 END),
		   MontantNetRemis = Sum(CASE WHEN O.OperTypeID = 'PRA' THEN -CO.ConventionOperAmount ELSE 0 END)
	FROM dbo.Un_ConventionOper CO
		JOIN (
			SELECT OperID, O.OperDate, O.OperTypeID
				FROM dbo.Un_Oper O
				WHERE O.OperTypeID IN ('PRA', 'RIF', 'RIP')
		) O ON O.OperID = CO.OperID
		JOIN dbo.DemandePRA DP ON DP.IdOper = O.OperID
		JOIN dbo.Demande D ON D.Id = DP.Id
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = DP.IdSouscripteur
	GROUP BY DP.IdSouscripteur, DP.TypeDestination --, Co.ConventionOperTypeID, O.OperTypeID
	--ORDER BY DP.IdSouscripteur
