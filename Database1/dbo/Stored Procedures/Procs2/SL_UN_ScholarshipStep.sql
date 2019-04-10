/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_ScholarshipStep
Description         :	Procédure retournant l’historique des étapes du PAE pour une bourse.
Valeurs de retours  :	Dataset :
									iScholarshipStepID		ID unique de l’historique des étapes.
									ScholarshipID				ID de la bourse à laquelle appartient l’historique.
									iScholarshipStep			Étape (1 à 5)
									dtScholarshipStepTime	Date et heure ou on a passé à cette étape.
									ConnectID					ID de l’usager qui a provoqué le changement d’étape.
									UserLastName				Nom de l’usager en question.
									UserFirstName				Prénom du l’usager.
Note                :	ADX0000704	IA	2005-07-05	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_ScholarshipStep] (
	@ScholarshipID INTEGER ) -- ID de la bourse.
AS
BEGIN
	SELECT
		SS.iScholarshipStepID, -- ID unique de l’historique des étapes.
		SS.ScholarshipID, -- ID de la bourse à laquelle appartient l’historique.
		SS.iScholarshipStep, -- Étape (1 à 5)
		SS.dtScholarshipStepTime, -- Date et heure ou on a passé à cette étape.
		SS.ConnectID, -- ID de l’usager qui a provoqué le changement d’étape.
		UserLastName = H.LastName, -- Nom de l’usager en question.
		UserFirstName = H.FirstName -- Prénom du l’usager.
	FROM Un_ScholarshipStep SS
	JOIN Mo_Connect C ON C.ConnectID = SS.ConnectID
	JOIN dbo.Mo_Human H ON H.HumanID = C.UserID
	WHERE SS.ScholarshipID = @ScholarshipID
		AND SS.bOldPAE = 0
	ORDER BY SS.dtScholarshipStepTime DESC
END


