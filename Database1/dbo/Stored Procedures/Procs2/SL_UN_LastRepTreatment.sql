/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_LastRepTreatment
Description         :	Procédure qui retournera l’ID et la date du dernier traitement de commissions.
Valeurs de retours  :	Dataset :
									RepTreatmentID		INTEGER		ID unique du dernier traitement.
									RepTreatmentDate	DATETIME		Date du dernier traitement.
Note                :	ADX0000697	IA	2005-05-05	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_LastRepTreatment] 
AS
BEGIN
	SELECT
		RepTreatmentID,
		RepTreatmentDate
	FROM Un_RepTreatment
	WHERE RepTreatmentDate IN 
			(
			SELECT 
				MAX(RepTreatmentDate)
			FROM Un_RepTreatment
			)
END

