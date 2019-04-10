
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 				:	SL_UN_LastAutomaticDepositTreatmentDate
Description 		:	Renvoi la date du dernier traitement des CPA
Valeurs de retour	:	DataSet : 
							LastAutomaticDepositTreatmentDate	DATETIME	Date du dernier traitement des CPA

Notes				:	ADX0001270	IA	2007-03-26	Alain Quirion		Création
*********************************************************************************/
CREATE PROCEDURE dbo.SL_UN_LastAutomaticDepositTreatmentDate
AS
BEGIN
	SELECT 
		LastAutomaticDepositTreatmentDate =  MAX(BankFileEndDate)
	FROM Un_BankFile
END

