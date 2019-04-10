/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 : SP_RP_CRQ_LogOfActivities
Description         : Rapport "Journal des activités"
Valeurs de retours  : 
Note                : ADX0000591 IA 2004-11-22 Bruno Lapointe	Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_RP_CRQ_LogOfActivities] (
	@StartDate DATETIME, -- Date de début de la période d'activités
	@EndDate DATETIME, -- Date de fin de la période d'activités
	@UserID INTEGER) -- ID Unique de l'usager (0=Tous)
AS
BEGIN
	SELECT
		C.UserID,
		UserName = U.LastName+', '+U.FirstName,
		C.ConnectStart,
		C.ConnectEnd,
		C.StationName,
		C.IPAddress,
		L.LogID,
		LA.LogActionLongName,
		L.LogTime,
		L.LogDesc
	FROM CRQ_Log L
	JOIN Mo_Connect C ON C.ConnectID = L.ConnectID
	JOIN dbo.Mo_Human U ON U.HumanID = C.UserID
	JOIN CRQ_LogAction LA ON LA.LogActionID = L.LogActionID
	WHERE (	C.UserID = @UserID
			OR @UserID = 0)
		AND	L.LogTime >= @StartDate
		AND	L.LogTime <	@EndDate + 1
	ORDER BY 
		U.LastName, 
		U.FirstName, 
		C.UserID, 
		C.ConnectStart, 
		C.ConnectEnd, 
		C.ConnectID, 
		L.LogTime, 
		L.LogID
END


