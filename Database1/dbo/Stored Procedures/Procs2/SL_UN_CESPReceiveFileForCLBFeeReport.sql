
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 					:	SL_UN_CESPReceiveFileForCLBFeeReport
Description 		:	Liste les fichiers reçus en ordre décroissant de date de fin de période pour
							le rapport de frais de BEC
Valeurs de retour	:	iCESPReceiveFileID	INTEGER	ID du fichier reçu
							dtPeriodEnd				DATETIME	Date de fin de période
Notes :	ADX0003051	UR	2007-08-30	Bruno Lapointe		Création
*************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESPReceiveFileForCLBFeeReport]
AS
BEGIN
	SELECT
		R.iCESPReceiveFileID,
		R.dtPeriodEnd
	FROM Un_CESPReceiveFile R
	WHERE R.dtPeriodEnd IS NOT NULL
	ORDER BY dtPeriodEnd DESC
END

