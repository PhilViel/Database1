/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service		: psPCEE_RapportRefusErreurM
Nom du service		: Obtenir les conventions qui ont des refus M sur plus de 7 dépôts consécutifs
But 				: Outil de vérification pour l'analyste du PCEE (ex : G Komenda, F Ménard)
Facette				: PCEE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE [dbo].[psPCEE_RapportRefusErreurM] 206  --(PARAM DONNÉS PAR exec SL_UN_CESPReceivedFilesInfo)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-12-13		Donald Huppé						Création du service	

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psPCEE_RapportRefusErreurM] 
(
	@iCESPReceiveFileID INT
)
AS

BEGIN

	SELECT 
		Convention = cv.ConventionNO,
		Modalite,
		NbRefus
	FROM (
		SELECT 
			ConventionID,
			Modalite,
			NbRefus = COUNT(*)
		FROM (
			SELECT 
				c9.iCESPReceiveFileID,
				c.ConventionID,
				modalite = CASE 
							WHEN m.PmtByYearID = 12 THEN 'Mensuel'
							WHEN m.PmtQty = 1 THEN 'Forfait'
							WHEN m.PmtQty > 1 and m.PmtByYearID = 1 THEN 'Annuel'
							END
			FROM 
				Un_CESP900 C9 
				JOIN Un_CESPReceiveFile CR ON C9.iCESPReceiveFileID = CR.iCESPReceiveFileID
				JOIN (
					SELECT TOP 7 iCESPReceiveFileID
					FROM Un_CESPReceiveFile 
					WHERE iCESPReceiveFileID <= @iCESPReceiveFileID
					ORDER BY iCESPReceiveFileID DESC
					) CRF ON CR.iCESPReceiveFileID = CRF.iCESPReceiveFileID
				JOIN Un_CESP C ON C9.iCESPID = C.iCESPID
				JOIN un_cotisation CT ON C.cotisationid = CT.cotisationID 
				JOIN dbo.Un_Unit U ON CT.unitid = U.unitid AND U.conventionid = C.conventionid
				JOIN un_modal M ON U.modalID = M.modalID
			WHERE 
				cCESP900ACESGReasonID = 'M' 
				AND CT.effectDate BETWEEN dtPeriodStart AND dtPeriodEnd
			GROUP BY
				C9.iCESPReceiveFileID,
				C.ConventionID,
				CASE 
					WHEN M.PmtByYearID = 12 THEN 'Mensuel'
					WHEN M.PmtQty = 1 THEN 'Forfait'
					WHEN M.PmtQty > 1 AND M.PmtByYearID = 1 THEN 'Annuel'
					End
			) V1
		GROUP BY 
			ConventionID,
			Modalite
		) V2
		JOIN dbo.Un_Convention CV ON V2.conventionid = CV.conventionid
		WHERE 
			(modalite = 'mensuel' AND NbRefus >= 7)
			OR
			(modalite <> 'mensuel')
	ORDER BY 
		Modalite,
		CV.ConventionNO

END


