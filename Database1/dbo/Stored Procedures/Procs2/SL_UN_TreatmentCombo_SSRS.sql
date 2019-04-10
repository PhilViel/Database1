/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas Inc.
Nom                 :	SL_UN_TreatmentCombo_SSRS
Description         :	Procédure de recherche des numéros de traitements pour les paramètres de traitement dans SSRS.
Valeurs de retours  :	Dataset :
Note                :	2009-11-18	Donald Huppé	Création

exec SL_UN_TreatmentCombo_SSRS

****************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_TreatmentCombo_SSRS] 
AS
BEGIN

	SELECT 
		RepTreatmentID, 
		Descr = cast(RepTreatmentID as varchar(4)) + ' (' + convert(char(10),RepTreatmentDate,121) + ')'
	FROM Un_RepTreatment 
	ORDER BY RepTreatmentID DESC

End
