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
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_GU_VerifConventionResil
Description         :	Vérification des resiliations parmis la liste des convention fournit de l outil Access
***************************************************************************************************************************/

/*
    Date        Programmeur             Description
    ----------  --------------------    -----------------------------------------------------
    2017-08-29  Pierre-Luc Simard       Deprecated - Cette procédure n'est plus utilisée
*/
CREATE PROCEDURE [dbo].[TT_GU_VerifConventionResil] 
AS
BEGIN
    SELECT 0/0
/*
	-- Liste des conventions dont tous les groupes d'unités sont résiliés
	CREATE TABLE #tConvResil (
		ConventionID INTEGER PRIMARY KEY,	
		UnitQty MONEY,
		dResil DATETIME)
	INSERT INTO #tConvResil
		SELECT
			V.ConventionID,
			V.UnitQty,
			V.dResil		
		FROM	
			(SELECT
				C.ConventionID,
				UnitQty = SUM(U.UnitQty),
				NbGrpUnit = COUNT(U.UnitID),
				NbGrpUnitResil = SUM(CASE WHEN U.TerminatedDate IS NULL THEN 0 ELSE 1 END),
				dResil = MIN(CASE WHEN U.TerminatedDate IS NULL THEN '' ELSE U.TerminatedDate END)							
			FROM GUI.dbo.TGU_VerifConvention VC
			LEFT JOIN dbo.Un_Convention C ON C.ConventionNo = VC.ConventionNo
			LEFT JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			GROUP BY C.conventionID) V		
		WHERE V.NbGrpUnit = NbGrpUnitResil AND NbGrpUnitResil <> 0
	
	SELECT 
		VC.ConventionNo,
		C.ConventionNo,
		SLastName = HS.LastName,
		SFirstName = HS.FirstName,
		A.Address,
		A.City,
		A.StateName,
		A.ZipCode,
		A.Country,
		A.Phone1,
		UnitQty = ISNULL(CR.UnitQty,0) + ISNULL(R.UnitQtyResil,0),
		CR.dResil,
		FraisAPayer = (ISNULL(CR.UnitQty,0) + ISNULL(R.UnitQtyResil,0)) * 200,		
		Frais = ISNULL(F.Frais, 0),
		RLastName = HR.LastName,
		RFirstName = HS.FirstName,
		DLastName = HD.LastName,
		DFirstName = HD.FirstName
	FROM GUI.dbo.TGU_VerifConvention VC
	LEFT JOIN dbo.Un_Convention C ON C.ConventionNo = VC.ConventionNo
	LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	LEFT JOIN dbo.Mo_Human HS ON HS.HumanID = S.SubscriberID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = HS.AdrID
	LEFT JOIN dbo.Mo_Human HR ON HR.HumanID = S.RepID
	LEFT JOIN #tConvResil CR ON CR.ConventionID = C.ConventionID
	LEFT JOIN (-- Directeur du représentant
		SELECT 
			RB.RepID, 
			BossID = MAX(BossID)
		FROM Un_RepBossHist RB
		JOIN (
			SELECT 
				RB.RepID, 
				RepBossPct = MAX(RB.RepBossPct)
			FROM Un_RepBossHist RB
			WHERE RepRoleID = 'DIR'
				AND RB.StartDate <= GETDATE()
				AND ISNULL(RB.EndDate,GETDATE()) >= GETDATE()
			GROUP BY 
				RB.RepID
			) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		WHERE RB.RepRoleID = 'DIR'
			AND RB.StartDate <= GETDATE()
			AND ISNULL(RB.EndDate,GETDATE()) >= GETDATE()
		GROUP BY 
			RB.RepID
		) RD ON RD.RepID = HR.HumanID
	LEFT JOIN dbo.Mo_Human HD ON HD.HumanID = RD.BossID
	LEFT JOIN 
		(-- Frais payés	
		SELECT 
			C.ConventionID,
			Frais = SUM(CO.Fee)
		FROM #tConvResil C
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID	
		JOIN Un_Cotisation CO ON CO.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = CO.OperID
		WHERE O.OperTypeID IN ('PRD', 'CHQ', 'CPA', 'NSF') 
		GROUP BY C.ConventionID) F ON F.ConventionID = CR.ConventionID
	LEFT JOIN 
		(-- Unités résiliées par convention
		SELECT 
			C.ConventionID,
			UnitQtyResil = SUM(UR.UnitQty)
		FROM #tConvResil C
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_UnitReduction UR ON UR.UnitID = U.UnitID
		GROUP BY C.ConventionID) R ON R.ConventionID = CR.ConventionID
	ORDER BY VC.Ordre

	DROP TABLE #tConvResil
    */
END		

/* Appel de la procédure à partir de la base de données UnivBase
USE UnivBase;
GO
EXEC TT_GU_VerifConventionResil
*/