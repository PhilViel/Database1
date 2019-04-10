/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_UnitIntReimbStep
Description         :	Procédure retournant l’historique des étapes du RIN pour un groupe d’unités.
Valeurs de retours  :	Dataset :
									iIntReimbStepID		ID unique de l’historique.
									UnitID					ID unique du groupe d’unités.
									iIntReimbStep			Étape du RIN.
									dtIntReimbStepTime	Date et heure à laquelle on a passé à cette étape.
									ConnectID				ID unique de la connexion de l’usager qui a fait avancer le RIN à cette étape.
									UserLastName			Nom de l’usager en question.
									UserFirstName			Prénom du l’usager.
Note                :	ADX0000694	IA	2005-06-08	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_UnitIntReimbStep] (
	@UnitID INTEGER )			-- ID du groupe d’unités.
AS
BEGIN
	SELECT
		IRS.iIntReimbStepID, -- ID unique de l’historique.
		IRS.UnitID, -- ID unique du groupe d’unités.
		IRS.iIntReimbStep, -- Étape du RIN.
		IRS.dtIntReimbStepTime, -- Date et heure à laquelle on a passé à cette étape.
		IRS.ConnectID, -- ID unique de la connexion de l’usager qui a fait avancer le RIN à cette étape.
		UserLastName = H.LastName, -- Nom de l’usager en question.
		UserFirstName = H.FirstName -- Prénom du l’usager.
	FROM Un_IntReimbStep IRS
	JOIN Mo_Connect C ON C.ConnectID = IRS.ConnectID
	JOIN dbo.Mo_Human H ON H.HumanID = C.UserID
	WHERE IRS.UnitID = @UnitID
	ORDER BY IRS.dtIntReimbStepTime DESC
END


