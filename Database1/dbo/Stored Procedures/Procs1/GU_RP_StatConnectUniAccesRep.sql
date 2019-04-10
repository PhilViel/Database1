/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_StatConnectUniAccesRep
Description         :	Rapport : Statistiques sur les connexions des représentants dans Uniacces 
Valeurs de retours  :	Dataset 
Note                :	2009-09-21	Donald Huppé	Créaton

exec GU_RP_StatConnectUniAccesRep '2008-01-01', '2008-12-31'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_StatConnectUniAccesRep] (
	@StartDate DATETIME,
	@EndDate DATETIME)
AS
BEGIN-- Nombre de représentants différents ayant utilisé l'application Uniacces pour chaque mois entre les dates demandées

	SELECT 
		An,
		Mois,
		NbRep = COUNT(RepCode)
	FROM (
		SELECT 
			H.LastName,
			H.FirstName,
			U.LoginNameID,
			R.RepCode,
			An = YEAR(C.ConnectStart),
			Mois = dbo.fn_Mo_TranslateIntMonthToStr(MONTH(C.ConnectStart), 'FRA'),
			iMois = MONTH(C.ConnectStart)
		FROM Mo_Connect C
		JOIN Mo_User U ON U.UserID = C.UserID
		JOIN Un_Rep R ON R.RepID = U.UserID
		JOIN dbo.Mo_Human H ON H.HumanID = U.UserID
		WHERE C.ConnectStart BETWEEN @StartDate AND @EndDate
			AND R.RepID NOT IN (
				SELECT	
					RepID
				FROM Un_RepLevelHist LH
				JOIN dbo.Un_RepLevel L ON L.RepLevelID = LH.RepLevelID
				WHERE L.RepRoleID <> 'REP'
				)
		GROUP BY 
			H.LastName,
			H.FirstName,
			U.LoginNameID,
			R.RepCode,
			YEAR(C.ConnectStart),
			Month(C.ConnectStart)
		) C
	GROUP BY 
		An,
		Mois,
		iMois
	ORDER BY
		An,
		iMois

End

