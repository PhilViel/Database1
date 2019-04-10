/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CESPReceivedFiles
Description         :	Retourne la liste des fichiers reçus du PCEE.
Valeurs de retours  :	Dataset :
									iCESPReceiveFileID	INTEGER		ID du fichier reçu du PCEE.
									dtRead					DATETIME		Date d’importation du fichier.
									dtPeriodStart			DATETIME		Date de début de la période couverte.
									dtPeriodEnd				DATETIME		Date de fin de la période couverte.
									fPayment					MONEY			Montant total des subventions reçus.
									fSumary					MONEY			Montant de subvention selon le sommaire.
									fTotal					MONEY			Montant total de subvention reçu, doit être identique au sommaire.
									vcPaymentReqID			VARCHAR(10)	ID de la demande de paiement au PCEE.
									iConvRegistration		INTEGER		Nombre de convention enregistrée.
									fCESGTotal				MONEY			Total des subventions reçues
									fACESGTotal				MONEY			Total des subventions supplémentaires reçues.
									fCLBTotal				MONEY			Total de BEC reçus.
									iRecordErrors			INTEGER		Nombre d’erreurs aux dossiers.
									iTransacErrors			INTEGER		Nombre d’erreurs aux transactions financières.
									iCriticalErrors		INTEGER		Nombre d’erreurs graves.
Note                :			
								ADX0000811	IA	2006-04-17	Bruno Lapointe		Création
								ADX0002426	BR	2007-05-23	Bruno Lapointe		Gestion de la table Un_CESP.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESPReceivedFiles]
AS
BEGIN
	SELECT
		R.iCESPReceiveFileID, -- ID du fichier reçu du PCEE.
		R.dtRead, -- Date d’importation du fichier.
		R.dtPeriodStart, -- Date de début de la période couverte.
		R.dtPeriodEnd, -- Date de fin de la période couverte.
		R.fPayment, -- Montant total des subventions reçus.
		R.fSumary, -- Montant de subvention selon le sommaire.
		fTotal = ISNULL(CE.fCESGTotal+CE.fACESGTotal+CE.fCLBTotal,0), -- Montant total de subvention reçu, doit être identique au sommaire.
		R.vcPaymentReqID, -- ID de la demande de paiement au PCEE.
		iConvRegistration = ISNULL(C950.iConvRegistration,0), -- Nombre de convention enregistrée.
		fCESGTotal = ISNULL(CE.fCESGTotal,0), -- Total des subventions reçues
		fACESGTotal = ISNULL(CE.fACESGTotal,0), -- Total des subventions supplémentaires reçues.
		fCLBTotal = ISNULL(CE.fCLBTotal,0), -- Total de BEC reçus.
		iRecordErrors = ISNULL(C800.iRecordErrors,0), -- Nombre d’erreurs aux dossiers.
		iTransacErrors = ISNULL(C800.iTransacErrors,0), -- Nombre d’erreurs aux transactions financières.
		iCriticalErrors = ISNULL(C850.iCriticalErrors,0),-- Nombre d’erreurs graves.
		fCLBFeeTotal = ISNULL(CE.fCLBFeeTotal,0), --Total des frais de BEC
		iCLBFeeCount = ISNULL(CE.iCLBFeeCount,0) --Nouvelle conventions admissibles au BEC
	FROM Un_CESPReceiveFile R
	LEFT JOIN ( -- Statistique des enregistrements de conventions
		SELECT 
			iCESPReceiveFileID,
			iConvRegistration = COUNT(iCESP950ID)
		FROM Un_CESP950
		WHERE tiCESP950ReasonID IS NULL
		GROUP BY iCESPReceiveFileID
		) C950 ON C950.iCESPReceiveFileID = R.iCESPReceiveFileID
	LEFT JOIN ( -- Statistique des enregistrements des erreurs
		SELECT 
			C8.iCESPReceiveFileID,
			iRecordErrors = 
				SUM(
					CASE 
						WHEN C4.iCESP400ID IS NULL THEN 1
					ELSE 0 
					END),
			iTransacErrors = 
				SUM(
					CASE 
						WHEN C4.iCESP400ID IS NOT NULL THEN 1
					ELSE 0 
					END)
		FROM Un_CESP800 C8
		LEFT JOIN Un_CESP400 C4 ON C4.iCESP800ID = C8.iCESP800ID
		GROUP BY C8.iCESPReceiveFileID
		) C800 ON C800.iCESPReceiveFileID = R.iCESPReceiveFileID
	LEFT JOIN ( -- Statistique des enregistrements des erreurs graves
		SELECT 
			iCESPReceiveFileID,
			iCriticalErrors = COUNT(iCESP850ID)
		FROM Un_CESP850 
		GROUP BY iCESPReceiveFileID
		) C850 ON C850.iCESPReceiveFileID = R.iCESPReceiveFileID
	LEFT JOIN ( -- Montant de subventions reçus
		SELECT 
			R.iCESPReceiveFileID,
			fCESGTotal = SUM(CE.fCESG), -- Total des subventions reçues
			fACESGTotal = SUM(CE.fACESG), -- Total des subventions supplémentaires reçues.
			fCLBTotal = SUM(CE.fCLB), -- Total de BEC reçus.
			fCLBFeeTotal = SUM(CE.fCLBFee), -- Total de Frais BEC reçus.
			iCLBFeeCount = SUM(CASE
								WHEN CE.fCLBFee > 0 THEN 1
								ELSE 0
							END)
		FROM UN_CESP CE
		JOIN Un_CESPReceiveFile R ON R.OperID = CE.OperID
		GROUP BY
			R.iCESPReceiveFileID
		) CE ON CE.iCESPReceiveFileID = R.iCESPReceiveFileID
	WHERE R.iCESPReceiveFileID > 0
	ORDER BY
		R.dtRead DESC,
		R.iCESPReceiveFileID DESC
END

