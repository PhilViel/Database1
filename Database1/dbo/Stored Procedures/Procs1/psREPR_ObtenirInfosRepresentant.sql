/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas Inc.
Nom                 :	psREPR_ObtenirInfosRepresentant
Description         :	Procédure de recherche de représentant par LoginNameID.
Valeurs de retours  :	Dataset : Info sur le représentant
Note                :	2009-12-01	Donald Huppé	        Création
                        2017-12-05  Pierre-Luc Simard       Ne plus valider la table Un_RepBusinessBonusCfg

exec psREPR_ObtenirInfosRepresentant  'ccossette'

******************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_ObtenirInfosRepresentant] (
	@LoginNameID 		Varchar(24)) -- LoginNameID du Rep
AS
BEGIN
	DECLARE @Today DATETIME

	SET @Today = GetDate()

	SELECT
		U.LoginNameID,
		R.RepId,
		R.RepCode,
		R.RepLicenseNo,
		R.BusinessStart,
		R.BusinessEnd,
		H.FirstName,
		NomNaissance = H.OrigName,
		H.Initial,
		H.LastName,
		H.BirthDate,
		H.DeathDate,
		Age  = dbo.fn_Mo_Age(H.BirthDate,getdate()),
		Sexe = S.SexName,
		Langue = L.LangName,
		EtatCivil = case 
						when H.CivilID= 'D' then 'Divorcé'
						when H.CivilID= 'J' then 'Conjoint de fait'
						when H.CivilID= 'M' then 'Marié'
						when H.CivilID= 'P' then 'Séparé'
						when H.CivilID= 'S' then 'Célibataire'
						when H.CivilID= 'U' then 'Inconnu'
						when H.CivilID= 'W' then 'Veuf'
					end,
		NAS = H.SocialNumber,
		Citoyennete = ISNULL(RC.CountryName,''), 
		NIP = ISNULL(H.vcNIP, ''),
		A.Address,
		A.City,
		A.StateName,
		Country = ISNULL(C.CountryName,''),
		A.ZipCode,
		Phone1 = dbo.fn_Mo_FormatPhoneNo(A.Phone1,A.CountryID),
		Phone2 = dbo.fn_Mo_FormatPhoneNo(A.Phone2,A.CountryID),
		Fax = dbo.fn_Mo_FormatPhoneNo(A.Fax,A.CountryID),
		Mobile = dbo.fn_Mo_FormatPhoneNo(A.Mobile,A.CountryID),
		WattLine = dbo.fn_Mo_FormatPhoneNo(A.WattLine,A.CountryID),
		OtherTel = dbo.fn_Mo_FormatPhoneNo(A.OtherTel,A.CountryID),
		Pager = dbo.fn_Mo_FormatPhoneNo(A.Pager,A.CountryID),
		A.EMail,
		DirLastName = CASE ISNULL(RDIR.BossID,0) WHEN 0 THEN '' ELSE HRDIR.LastName  END,
		DirFirstName = CASE ISNULL(RDIR.BossID,0) WHEN 0 THEN '' ELSE  HRDIR.FirstName END,
		DirRepCode = CASE ISNULL(RDIR.BossID,0) WHEN 0 THEN '' ELSE RepDir.RepCode END,
		DirEmail = ADir.EMail
	FROM Un_Rep R
	JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
	JOIN Mo_User U on U.userid = H.humanid
	JOIN MO_Lang L on H.langID = L.LangID -- select * from MO_Sex
	JOIN MO_Sex S on H.SexID = S.SexID and H.langID = S.langID
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
			JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
			JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (@Today >= BRLH.StartDate)  AND (@Today <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
			--JOIN Un_RepBusinessBonusCfg RBB ON (RBB.RepRoleID = RBH.RepRoleID) AND (@Today >= RBB.StartDate) AND (@Today <= RBB.EndDate OR RBB.EndDate IS NULL)
			GROUP BY R.RepID
			) M
		JOIN Un_Rep R ON (R.RepID = M.RepID)
		JOIN Un_RepBossHist RBH ON (RBH.RepID = M.RepID) AND (RBH.RepBossPct = M.RepBossPct) AND (@Today >= RBH.StartDate) AND (@Today <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
		GROUP BY M.RepID
		) RDIR ON (RDIR.RepID = R.RepID)
	LEFT JOIN dbo.Mo_Human HRDIR ON (HRDIR.HumanID = RDIR.BossID)
	LEFT JOIN UN_REP RepDir on RDIR.RepID = RepDir.RepID
	LEFT JOIN dbo.Mo_Adr ADir on HRDIR.adrID = ADir.adrID
	WHERE (U.LoginNameID = @LoginNameID)
 
END


