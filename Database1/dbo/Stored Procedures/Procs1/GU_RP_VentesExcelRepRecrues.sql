/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	GU_RP_VentesExcelRepRecrues
Description         :	Liste des recrues selon les dates fournies pour fichier Excel
Valeurs de retours  :	Dataset 
Note                :	Pierre-Luc Simard	2008-01-30 	
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_VentesExcelRepRecrues]
	(
	@StartDate DATETIME, 	-- Date de début de la période
	@EndDate DATETIME  	-- Date de fin de la période
	)
AS
BEGIN
	SET NOCOUNT ON
	SELECT 
		H.LastName,
		H.FirstName,
		R.RepCode,
		R.BusinessStart,
		R.BusinessEnd,
		R.RepLicenseNo
	FROM Un_Rep R
	JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
	WHERE R.BusinessStart BETWEEN @StartDate AND @EndDate
	ORDER BY R.BusinessStart, H.LastName, H.FirstName
END



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GU_RP_VentesExcelRepRecrues] TO [Rapport]
    AS [dbo];

