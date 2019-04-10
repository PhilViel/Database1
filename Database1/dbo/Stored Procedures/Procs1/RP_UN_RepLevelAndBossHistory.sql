/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_RepLevelAndBossHistory
Description         :	Rapport d'historique des niveaux et supérieurs
Valeurs de retours  :	Dataset du rapport
Exemple d'appel		:	Execute dbo.RP_UN_RepLevelAndBossHistory 'REP',0
Note                :	ADX0001395	BR	2005-04-19	Bruno Lapointe			Création
										2010-03-03	Jean-François Gauthier	Ajout du champ iNumeroBDNI
****************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepLevelAndBossHistory] (
	@cSection CHAR(3), -- REP = Maitre de représentant, BOS = Détail supérieur, LVL = Détail des niveaux
	@iRepID INTEGER ) -- ID unique du représentant pour lequel on veut le rapport (0=Tous, -1=Actif, -2=Inactif)
AS
BEGIN
	IF @cSection = 'REP'
		SELECT
			R.RepID, 
			R.RepCode,
			R.RepLicenseNo,
			R.BusinessStart,
			R.BusinessEnd,
			RepName = HR.LastName + ', ' + HR.FirstName,
			HR.BirthDate,
			HR.SexID,
			HR.LangID,
			HR.CivilID,
			HR.SocialNumber,
			ResidCountryName = ISNULL(HRC.CountryName,''),
			AR.Address,
			AR.City,
			AR.StateName,
			AR.ZipCode,
			AR.Phone1,
			AR.Phone2,
			AR.Fax,
			AR.Mobile,
			AR.Pager,
			AR.EMail,
			CountryName = ISNULL(ARC.CountryName,''),
			R.iNumeroBDNI
		FROM Un_Rep R
		JOIN dbo.Mo_Human HR ON HR.HumanID = R.RepID
		JOIN dbo.Mo_Adr AR ON AR.AdrID = HR.AdrID
		LEFT JOIN Mo_Country HRC ON HRC.CountryID = HR.ResidID
		LEFT JOIN Mo_Country ARC ON ARC.CountryID = AR.CountryID
		WHERE @iRepID = R.RepID
			OR	@iRepID = 0
			OR	( @iRepID = -1
				AND ISNULL(R.BusinessEnd,GETDATE()+1) > GETDATE()
				)
			OR	( @iRepID = -2
				AND ISNULL(R.BusinessEnd,GETDATE()+1) <= GETDATE()
				)
		ORDER BY
			HR.LastName,
			HR.FirstName,
			R.RepID
	ELSE IF @cSection = 'BOS'
		SELECT
			R.RepID,
			RepBossPct = ISNULL(B.RepBossPct, 0),
			StartDate = dbo.fn_Mo_DateNoTime(B.StartDate),
			EndDate = dbo.fn_Mo_DateNoTime(B.EndDate),
			Ro.RepRoleDesc,
			BossName = H.LastName + ', ' + H.FirstName,
			R.iNumeroBDNI
		FROM Un_Rep R
		JOIN Un_RepBossHist B ON R.RepID = B.RepID
		JOIN Un_RepRole Ro ON Ro.RepRoleID = B.RepRoleID
		JOIN dbo.Mo_Human H ON H.HumanID = B.BossID
		WHERE @iRepID = R.RepID
			OR	@iRepID = 0
			OR	( @iRepID = -1
				AND ISNULL(R.BusinessEnd,GETDATE()+1) > GETDATE()
				)
			OR	( @iRepID = -2
				AND ISNULL(R.BusinessEnd,GETDATE()+1) <= GETDATE()
				)
		ORDER BY
			R.RepID,
			B.StartDate,
			B.RepBossPct
	ELSE IF @cSection = 'LVL'
		SELECT
			R.RepID,
			StartDate = dbo.fn_Mo_DateNoTime(H.StartDate),
			EndDate = dbo.fn_Mo_DateNoTime(H.EndDate),
			L.RepRoleID,
			L.LevelDesc,
			TargetUnit = ISNULL(L.TargetUnit, 0),
			ConservationRate = ISNULL(L.ConservationRate, 0),
			Ro.RepRoleDesc,
			R.iNumeroBDNI
		FROM Un_Rep R
		JOIN Un_RepLevelHist H ON R.RepID = H.RepID
		JOIN Un_RepLevel L ON L.RepLevelID = H.RepLevelID
		JOIN Un_RepRole Ro ON Ro.RepRoleID = L.RepRoleID
		WHERE @iRepID = R.RepID
			OR	@iRepID = 0
			OR	( @iRepID = -1
				AND ISNULL(R.BusinessEnd,GETDATE()+1) > GETDATE()
				)
			OR	( @iRepID = -2
				AND ISNULL(R.BusinessEnd,GETDATE()+1) <= GETDATE()
				)
		ORDER BY
			R.RepID,
			H.StartDate
END

/*  Sequence de test - par: PLS - 09-05-2008
	exec [dbo].[RP_UN_RepLevelAndBossHistory] 
	@cSection = 'REP', -- REP = Maitre de représentant, BOS = Détail supérieur, LVL = Détail des niveaux
	@iRepID = 0 -- ID unique du représentant pour lequel on veut le rapport (0=Tous, -1=Actif, -2=Inactif)
*/


