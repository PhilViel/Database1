/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_UN_RepLevelHistory
Description         :	Rapport d'historique des niveaux
Valeurs de retours  :	Dataset du rapport
Note                :	Donald Huppé	2009-11-10	Création

exec GU_RP_UN_RepLevelHistory  0 

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_UN_RepLevelHistory] (
	@iRepID INTEGER ) -- ID unique du représentant pour lequel on veut le rapport (0=Tous, -1=Actif, -2=Inactif)
AS
BEGIN

	SELECT
		R.RepID,
		R.RepCode,
		Hu.Firstname,
		Hu.lastname,
		StartDate = dbo.fn_Mo_DateNoTime(H.StartDate),
		EndDate = dbo.fn_Mo_DateNoTime(H.EndDate),
		L.RepRoleID,
		Ro.RepRoleDesc,
		L.RepLevelID,
		L.LevelDesc,
		FullLevelDesc = case when PATINDEX ( '%'+LevelDesc+'%' , RepRoleDesc ) > 0 then RepRoleDesc else RepRoleDesc + ' ' + LevelDesc end,
		Statut = case when isnull(R.BusinessEnd,'3000-01-01') > GETDATE() then 'Actif' else 'Inactif' end
	into #tmp1
	FROM Un_Rep R
	JOIN Un_RepLevelHist H ON R.RepID = H.RepID
	JOIN Un_RepLevel L ON L.RepLevelID = H.RepLevelID
	JOIN Un_RepRole Ro ON Ro.RepRoleID = L.RepRoleID
	JOIN dbo.MO_Human hu on R.repid = Hu.Humanid
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
		L.RepLevelID

-- Pour mettre les role REP ensemble au début
update #tmp1 set RepLevelID = RepLevelID + 100 where reproleID = 'REP'
update #tmp1 set RepLevelID = RepLevelID + 200 where reproleID <> 'REP'

select * from #tmp1

End

-- select * from Un_RepLevel


