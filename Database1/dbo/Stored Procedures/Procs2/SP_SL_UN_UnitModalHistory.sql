/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_SL_UN_UnitModalHistory
Description         :	Renvoi l'historique des modalité d'un groupe d'unités.
Valeurs de retours  :	Dataset de données contenant l'historique
Note                :	ADX0000652	IA	2005-02-03	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_UnitModalHistory] (
	@UnitID MoID ) -- Id unique du groupe d'unités
AS
BEGIN
	SELECT 
		MH.UnitModalHistoryID,
		MH.UnitID,
		MH.ModalID,
		MH.ConnectID,
		MH.StartDate,
		M.ModalDate,
		M.PmtByYearID,
		M.PmtQty,
		M.PmtRate,
		M.BenefAgeOnBegining,
		M.PlanID,
		P.PlanDesc,
		UserFirstName = ISNULL(U.FirstName,''),
		UserLastName = ISNULL(U.LastName,'')
	FROM Un_UnitModalHistory MH
	JOIN Un_Modal M ON M.ModalID = MH.ModalID
	JOIN Un_Plan P ON P.PlanID = M.PlanID
	LEFT JOIN Mo_Connect C ON C.ConnectID = MH.ConnectID
	LEFT JOIN dbo.Mo_Human U ON U.HumanID = C.UserID
	WHERE MH.UnitID = @UnitID 
	ORDER BY MH.StartDate DESC 
END


