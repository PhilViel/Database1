/****************************************************************************************************
	Procédure retournant l'information d'un représentant
 ******************************************************************************
	Exemple d'appel :
			EXECUTE dbo.SL_UN_Rep 149462
-- ****************************************************************************
	2004-05-31	Bruno Lapointe			Création
	2009-02-12	Patrick Robitaille		Ajout du champ vcNIP dans la table Mo_Human
	2010-02-22	Jean-François Gauthier	Ajout du champ iNumeroBDNI en retour
	2012-11-14	Donald Huppé			Dans la recherche du directeur, enlever join sur Un_RepLevel et suivant car inutile dans ce contexte
										Et le directeur ne sortait pas s'il n'avait pas d'historique de niveau
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_Rep] (
	@RepID 		INTEGER) -- ID Unique de représentant
AS
BEGIN
	DECLARE 
		@Today DATETIME

	SET @Today = GetDate()

	SELECT
		R.RepCode,
		R.RepLicenseNo,
		R.BusinessStart,
		R.BusinessEnd,
		R.HistVerifConnectID,
		R.StopRepComConnectID,
		H.FirstName,
		H.OrigName,
		H.Initial,
		H.LastName,
		H.BirthDate,
		H.DeathDate,
		H.SexID,
		H.LangID,
		H.CivilID,
		H.SocialNumber,
		H.ResidID,
		H.DriverLicenseNo,
		H.WebSite,
		H.CompanyName,
		H.CourtesyTitle,
		H.UsingSocialNumber,
		H.SharePersonalInfo,
		H.MarketingMaterial,
		H.IsCompany,
		vcNIP = ISNULL(H.vcNIP, ''),
		A.InForce,
		A.Address,
		A.City,
		A.StateName,
		A.CountryID,
		A.ZipCode,
		Phone1 = dbo.fn_Mo_FormatPhoneNo(A.Phone1,A.CountryID),
		Phone2 = dbo.fn_Mo_FormatPhoneNo(A.Phone2,A.CountryID),
		Fax = dbo.fn_Mo_FormatPhoneNo(A.Fax,A.CountryID),
		Mobile = dbo.fn_Mo_FormatPhoneNo(A.Mobile,A.CountryID),
		WattLine = dbo.fn_Mo_FormatPhoneNo(A.WattLine,A.CountryID),
		OtherTel = dbo.fn_Mo_FormatPhoneNo(A.OtherTel,A.CountryID),
		Pager = dbo.fn_Mo_FormatPhoneNo(A.Pager,A.CountryID),
		A.EMail,
		ResidCountryName = ISNULL(RC.CountryName,''),
		CountryName = ISNULL(C.CountryName,''),
		DirName = CASE ISNULL(RDIR.BossID,0) WHEN 0 THEN '' ELSE HRDIR.LastName + ', ' + HRDIR.FirstName END,
		R.iNumeroBDNI
	FROM Un_Rep R
	JOIN dbo.Mo_Human H ON (H.HumanID = R.RepID)
	LEFT JOIN dbo.Mo_Adr A ON (A.AdrID = H.AdrID)
	LEFT JOIN Mo_Country RC ON (RC.CountryID = H.ResidID)
	LEFT JOIN Mo_Country C ON (C.CountryID = A.CountryID)
	LEFT JOIN (
		SELECT
			M.RepID,
			BossID = MAX(RBH.BossID)
		FROM (
			SELECT
				R.RepID,
				RepBossPct = MAX(RBH.RepBossPct)
			FROM Un_Rep R
			JOIN Un_RepBossHist RBH ON (RBH.RepID = R.RepID) AND (@Today >= RBH.StartDate) AND (@Today <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
			-- 2012-11-14-------------------------
			--JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
			--JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (@Today >= BRLH.StartDate)  AND (@Today <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
			--JOIN Un_RepBusinessBonusCfg RBB ON (RBB.RepRoleID = RBH.RepRoleID) AND (@Today >= RBB.StartDate) AND (@Today <= RBB.EndDate OR RBB.EndDate IS NULL)
			---------------------------------------
			WHERE R.RepID = @RepID
			GROUP BY R.RepID
			) M
		JOIN Un_Rep R ON (R.RepID = M.RepID)
		JOIN Un_RepBossHist RBH ON (RBH.RepID = M.RepID) AND (RBH.RepBossPct = M.RepBossPct) AND (@Today >= RBH.StartDate) AND (@Today <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
		WHERE R.RepID = @RepID
		GROUP BY M.RepID
		) RDIR ON (RDIR.RepID = R.RepID)
	LEFT JOIN dbo.Mo_Human HRDIR ON (HRDIR.HumanID = RDIR.BossID)
	WHERE (@RepID = R.RepID);
 
END;


