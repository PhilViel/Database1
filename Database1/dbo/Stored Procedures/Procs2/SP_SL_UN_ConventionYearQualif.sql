/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_SL_UN_ConventionYearQualif
Description         :	Retourne l'historique d'année de qualification d'une convention
Valeurs de retours  :	Dataset contenant l'historique
Note                :	ADX0000612	IA	2005-01-03	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_ConventionYearQualif] (
	@ConventionID INTEGER) -- ID unique de la convention dont on veut l'historique
AS
BEGIN
	SELECT
		YQ.ConventionYearQualifID,
		YQ.ConventionID,
		YQ.ConnectID,
		YQ.EffectDate,
		YQ.YearQualif,
		U.LastName,
		U.FirstName
	FROM Un_ConventionYearQualif YQ
	JOIN Mo_Connect C ON C.ConnectID = YQ.ConnectID
	JOIN dbo.Mo_Human U ON U.HumanID = C.UserID 
	WHERE	ConventionID = @ConventionID
	ORDER BY EffectDate DESC
END


