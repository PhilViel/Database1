/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_CESPErrorsSumary
Description         :	Renvoi les données pour le rapport : Sommaire des erreurs du PCEE
Valeurs de retours  :	Dataset :
				siRecordType	TINYINT		Type d’enregistrements (Tous les enregistrements, 100, 200 ou 400)
				siYear		TINYINT		Année
				tiMonth		TINYINT		Mois
				iStartNbr	INTEGER		Solde d’ouverture
				iDeclaredNbr	INTEGER		Nb. erreurs
				iCorrectedNbr	INTEGER		Nb. erreurs corrigées et renvoyés
				iNotResendNbr	INTEGER		Nb. erreurs corrigées et non renvoyés
				
Note                :	ADX0001153	IA	2006-11-10	Alain Quirion		Création
						ADX0001223	UP	2007-08-14	Bruno Lapointe		Solde de départ changeait dans le temps.
                                        2008-12-15  Fatiha Araar        Ajouter les erreurs liée aus enregistrements 511
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_CESPErrorsSumary](
	@dtStart DATETIME,	-- Date de début
	@dtEnd DATETIME)	-- Date de fin
AS
BEGIN
	DECLARE 
		@iCurrentYear INTEGER,
		@iCurrentMonth INTEGER

	DECLARE @DateTable TABLE(		
		siYear SMALLINT,
		tiMonth TINYINT)

	DECLARE @ErrorSummaryTable TABLE(
		siRecordType  SMALLINT,
		siYear SMALLINT,
		tiMonth TINYINT)

	DECLARE @StartNbrTable TABLE(
		siRecordType  SMALLINT,
		siYear SMALLINT,
		tiMonth TINYINT,
		iStartNbr INTEGER
		)	

	DECLARE @DeclareNbrTable TABLE(
		siRecordType  SMALLINT,
		siYear SMALLINT,
		tiMonth TINYINT,
		iDeclaredNbr INTEGER
		)

	DECLARE @CorrectedNbrTable TABLE(
		siRecordType  SMALLINT,
		siYear SMALLINT,
		tiMonth TINYINT,
		iCorrectedNbr INTEGER,
		iNotResendNbr INTEGER
		)		

	SET @iCurrentYear = YEAR(@dtStart)
	SET @iCurrentMonth = MONTH(@dtStart)

	
	-- Création des la liste des dates entre la date de début et de fin
	WHILE @iCurrentYear < YEAR(@dtEnd)
		OR (@iCurrentYear = YEAR(@dtEnd) 
			AND @iCurrentMonth <= MONTH(@dtEnd))
	BEGIN
		INSERT INTO @DateTable(siYear, tiMonth)
		VALUES (@iCurrentYear, @iCurrentMonth)

		INSERT INTO @ErrorSummaryTable(siRecordType, siYear, tiMonth)
		VALUES (0, @iCurrentYear, @iCurrentMonth)
	
		INSERT INTO @ErrorSummaryTable(siRecordType, siYear, tiMonth)
		VALUES (100, @iCurrentYear, @iCurrentMonth)

		INSERT INTO @ErrorSummaryTable(siRecordType, siYear, tiMonth)
		VALUES (200, @iCurrentYear, @iCurrentMonth)

		INSERT INTO @ErrorSummaryTable(siRecordType, siYear, tiMonth)
		VALUES (400, @iCurrentYear, @iCurrentMonth)
        
        --Ajouter les 511
        INSERT INTO @ErrorSummaryTable(siRecordType, siYear, tiMonth)
		VALUES (511, @iCurrentYear, @iCurrentMonth)			

		IF @iCurrentMonth = 12
		BEGIN
			SET @iCurrentYear = @iCurrentYear + 1
			SET @iCurrentMonth = 1
		END
		ELSE
		BEGIN			
			SET @iCurrentMonth = @iCurrentMonth + 1
		END
	END

	-- Insertion des erreurs déclarés
	INSERT INTO @DeclareNbrTable(	siRecordType,
					siYear,
					tiMonth,
					iDeclaredNbr)
	SELECT
		siRecordType = 100,
		siYear = YEAR(CRF.dtRead),
		tiMonth = MONTH(CRF.dtRead),
		iDeclaredNbr = COUNT(*)
	FROM Un_CESP800 C8
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID	
	WHERE CRF.dtRead BETWEEN @dtStart AND @dtEnd
		AND C8.iCESP800ID IN (SELECT iCESP800ID FROM Un_CESP100)
	GROUP BY YEAR(CRF.dtRead), MONTH(CRF.dtRead)
	---------
	UNION ALL
	---------
	SELECT
		siRecordType = 200,
		siYear = YEAR(CRF.dtRead),
		tiMonth = MONTH(CRF.dtRead),
		iDeclaredNbr = COUNT(*)
	FROM Un_CESP800 C8
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID	
	WHERE CRF.dtRead BETWEEN @dtStart AND @dtEnd
		AND C8.iCESP800ID IN (SELECT iCESP800ID FROM Un_CESP200)
	GROUP BY YEAR(CRF.dtRead), MONTH(CRF.dtRead)
	---------
	UNION ALL
	---------
	SELECT
		siRecordType = 400,
		siYear = YEAR(CRF.dtRead),
		tiMonth = MONTH(CRF.dtRead),
		iDeclaredNbr = COUNT(*)
	FROM Un_CESP800 C8
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID	
	WHERE CRF.dtRead BETWEEN @dtStart AND @dtEnd
		AND C8.iCESP800ID IN (SELECT iCESP800ID FROM Un_CESP400)
	GROUP BY YEAR(CRF.dtRead), MONTH(CRF.dtRead)

    --Ajouter les ereurs sur les enregistrements 511
    ---------
	UNION ALL
	---------
	SELECT
		siRecordType = 511,
		siYear = YEAR(CRF.dtRead),
		tiMonth = MONTH(CRF.dtRead),
		iDeclaredNbr = COUNT(*)
	FROM Un_CESP800 C8
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID	
	WHERE CRF.dtRead BETWEEN @dtStart AND @dtEnd
		AND C8.iCESP800ID IN (SELECT iCESP800ID FROM Un_CESP511)
	GROUP BY YEAR(CRF.dtRead), MONTH(CRF.dtRead)

	---------
	UNION ALL
	---------
	SELECT
		siRecordType = 0,
		siYear = YEAR(CRF.dtRead),
		tiMonth = MONTH(CRF.dtRead),
		iDeclaredNbr = COUNT(*)
	FROM Un_CESP800 C8
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID	
	WHERE CRF.dtRead BETWEEN @dtStart AND @dtEnd
		AND C8.iCESP800ID IN (
			SELECT iCESP800ID 
			FROM Un_CESP100
			-----
			UNION
			-----
			SELECT iCESP800ID 
			FROM Un_CESP200
			-----
			UNION
			-----
			SELECT iCESP800ID 
			FROM Un_CESP400
            --Ajouter les erreurs 511
            -----
			UNION
			-----
			SELECT iCESP800ID 
			FROM Un_CESP511
			)
	GROUP BY YEAR(CRF.dtRead), MONTH(CRF.dtRead)

	-- Insertion des erreurs corrigés
	INSERT INTO @CorrectedNbrTable(	siRecordType,
					siYear,
					tiMonth,
					iCorrectedNbr,
					iNotResendNbr)
	SELECT siRecordType = 100,
		siYear = YEAR(C8C.dtCorrected),
		tiMonth = MONTH(C8C.dtCorrected),
		iCorrectedNbr = -1 * SUM(CASE
					WHEN C8C.bCESP400Resend = 0 THEN 0
					ELSE 1
					END),
		iNotResendNbr = -1 * SUM(CASE
					WHEN C8C.bCESP400Resend = 0 THEN 1
					ELSE 0
					END)
	FROM Un_CESP800Corrected C8C
	JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8C.iCESP800ID
	WHERE C8.iCESP800ID IN (SELECT iCESP800ID FROM Un_CESP100)
	GROUP BY YEAR(C8C.dtCorrected), MONTH(C8C.dtCorrected)
	---------
	UNION ALL
	---------
	SELECT siRecordType = 200,
		siYear = YEAR(C8C.dtCorrected),
		tiMonth = MONTH(C8C.dtCorrected),
		iCorrectedNbr = -1 * SUM(CASE
					WHEN C8C.bCESP400Resend = 0 THEN 0
					ELSE 1
					END),
		iNotResendNbr = -1 * SUM(CASE
					WHEN C8C.bCESP400Resend = 0 THEN 1
					ELSE 0
					END)
	FROM Un_CESP800Corrected C8C
	JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8C.iCESP800ID
	WHERE C8.iCESP800ID IN (SELECT iCESP800ID FROM Un_CESP200)
	GROUP BY YEAR(C8C.dtCorrected), MONTH(C8C.dtCorrected)
	---------
	UNION ALL
	---------
	SELECT siRecordType = 400,
		siYear = YEAR(C8C.dtCorrected),
		tiMonth = MONTH(C8C.dtCorrected),
		iCorrectedNbr = -1 * SUM(CASE
					WHEN C8C.bCESP400Resend = 0 THEN 0
					ELSE 1
					END),
		iNotResendNbr = -1 * SUM(CASE
					WHEN C8C.bCESP400Resend = 0 THEN 1
					ELSE 0
					END)
	FROM Un_CESP800Corrected C8C
	JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8C.iCESP800ID
	WHERE C8.iCESP800ID IN (SELECT iCESP800ID FROM Un_CESP400)
	GROUP BY YEAR(C8C.dtCorrected), MONTH(C8C.dtCorrected)
    
    --Ajouter les erreurs 511 corigées
    UNION ALL
	---------
	SELECT siRecordType = 511,
		siYear = YEAR(C8C.dtCorrected),
		tiMonth = MONTH(C8C.dtCorrected),
		iCorrectedNbr = -1 * SUM(CASE
					WHEN C8C.bCESP400Resend = 0 THEN 0
					ELSE 1
					END),
		iNotResendNbr = -1 * SUM(CASE
					WHEN C8C.bCESP400Resend = 0 THEN 1
					ELSE 0
					END)
	FROM Un_CESP800Corrected C8C
	JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8C.iCESP800ID
	WHERE C8.iCESP800ID IN (SELECT iCESP800ID FROM Un_CESP511)
	GROUP BY YEAR(C8C.dtCorrected), MONTH(C8C.dtCorrected)
	---------
	UNION ALL
	---------
	SELECT siRecordType = 0,
		siYear = YEAR(C8C.dtCorrected),
		tiMonth = MONTH(C8C.dtCorrected),
		iCorrectedNbr = -1 * SUM(CASE
					WHEN C8C.bCESP400Resend = 0 THEN 0
					ELSE 1
					END),
		iNotResendNbr = -1 * SUM(CASE
					WHEN C8C.bCESP400Resend = 0 THEN 1
					ELSE 0
					END)
	FROM Un_CESP800Corrected C8C
	JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8C.iCESP800ID
	WHERE C8.iCESP800ID IN (
		SELECT iCESP800ID 
		FROM Un_CESP100
		-----
		UNION
		-----
		SELECT iCESP800ID 
		FROM Un_CESP200
		-----
		UNION
		-----
		SELECT iCESP800ID 
		FROM Un_CESP400
        
        --Ajouter les erreurs 511
        -----
        UNION
		-----
		SELECT iCESP800ID 
		FROM Un_CESP511
		)
	GROUP BY YEAR(C8C.dtCorrected), MONTH(C8C.dtCorrected)

	-- Insertion des soldes de départ avant chaque date
	INSERT INTO @StartNbrTable(
					siRecordType,
					siYear,
					tiMonth,
					iStartNbr)
	SELECT 
		siRecordType = 100,
		siYear = DT.siYear,
		tiMonth = DT.tiMonth,
		iStartNbr = COUNT(*) -- + la somme des corrigés précédent cette date (mois/année)
	FROM Un_CESP800 C8
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID
	JOIN @DateTable DT ON YEAR(CRF.dtRead) < DT.siYear OR ( YEAR(CRF.dtRead) = DT.siYear AND MONTH(CRF.dtRead) < DT.tiMonth )
	WHERE C8.iCESP800ID IN (SELECT iCESP800ID FROM Un_CESP100)
	GROUP BY DT.siYear, DT.tiMonth
	---------
	UNION ALL
	---------
	SELECT 
		siRecordType = 200,
		siYear = DT.siYear,
		tiMonth = DT.tiMonth,
		iStartNbr = COUNT(*) -- + la somme des corrigés précédent cette date (mois/année)
	FROM Un_CESP800 C8
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID
	JOIN @DateTable DT ON YEAR(CRF.dtRead) < DT.siYear OR ( YEAR(CRF.dtRead) = DT.siYear AND MONTH(CRF.dtRead) < DT.tiMonth )
	WHERE C8.iCESP800ID IN (SELECT iCESP800ID FROM Un_CESP200)
	GROUP BY DT.siYear, DT.tiMonth
	---------
	UNION ALL
	---------
	SELECT 
		siRecordType = 400,
		siYear = DT.siYear,
		tiMonth = DT.tiMonth,
		iStartNbr = COUNT(*) -- + la somme des corrigés précédent cette date (mois/année)
	FROM Un_CESP800 C8
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID
	JOIN @DateTable DT ON YEAR(CRF.dtRead) < DT.siYear OR ( YEAR(CRF.dtRead) = DT.siYear AND MONTH(CRF.dtRead) < DT.tiMonth )
	WHERE C8.iCESP800ID IN (SELECT iCESP800ID FROM Un_CESP400)
	GROUP BY DT.siYear, DT.tiMonth
   
    --Ajouter les corrections 511
    ---------
	UNION ALL
	---------
	SELECT 
		siRecordType = 511,
		siYear = DT.siYear,
		tiMonth = DT.tiMonth,
		iStartNbr = COUNT(*) -- + la somme des corrigés précédent cette date (mois/année)
	FROM Un_CESP800 C8
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID
	JOIN @DateTable DT ON YEAR(CRF.dtRead) < DT.siYear OR ( YEAR(CRF.dtRead) = DT.siYear AND MONTH(CRF.dtRead) < DT.tiMonth )
	WHERE C8.iCESP800ID IN (SELECT iCESP800ID FROM Un_CESP511)
	GROUP BY DT.siYear, DT.tiMonth
	---------
	UNION ALL
	---------
	SELECT 
		siRecordType = 0,
		siYear = DT.siYear,
		tiMonth = DT.tiMonth,
		iStartNbr = COUNT(*) -- + la somme des corrigés précédent cette date (mois/année)
	FROM Un_CESP800 C8
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID
	JOIN @DateTable DT ON YEAR(CRF.dtRead) < DT.siYear OR ( YEAR(CRF.dtRead) = DT.siYear AND MONTH(CRF.dtRead) < DT.tiMonth )
	WHERE C8.iCESP800ID IN (
		SELECT iCESP800ID 
		FROM Un_CESP100
		-----
		UNION
		-----
		SELECT iCESP800ID 
		FROM Un_CESP200
		-----
		UNION
		-----
		SELECT iCESP800ID 
		FROM Un_CESP400
    
        --Ajouter les corrections 511
        -----
		UNION
		-----
		SELECT iCESP800ID 
		FROM Un_CESP511
		)
	GROUP BY DT.siYear, DT.tiMonth

	-- Insertion des solde de départ pour ceux qui n'Exitent pas
	INSERT INTO @StartNbrTable
		SELECT 
			EST.siRecordType,
			EST.siYear,
			EST.tiMonth,
			0
		FROM @ErrorSummaryTable EST
		LEFT JOIN @StartNbrTable SNT ON SNT.siRecordType = EST.siRecordType AND SNT.siYear = EST.siYear AND SNT.tiMonth = EST.tiMonth
		WHERE SNT.siRecordType IS NULL	

	--Ajoute au solde de départ les erreurs corrigés précédemment
	UPDATE @StartNbrTable
	SET iStartNbr = iStartNbr + CorrectedNbr
	FROM @StartNbrTable S
	JOIN (
		SELECT 
			EST.siRecordType, 
			EST.siYear, 
			EST.tiMonth, 
			CorrectedNbr = SUM(CNT2.iCorrectedNbr+CNT2.iNotResendNbr)
		FROM @StartNbrTable EST
		JOIN @CorrectedNbrTable CNT2 ON CNT2.siRecordType = EST.siRecordType AND (CNT2.siYear < EST.siYear OR (CNT2.siYear = EST.siYear AND CNT2.tiMonth < EST.tiMonth))
		GROUP BY EST.siRecordType, EST.siYear, EST.tiMonth) V ON V.siRecordType = S.siRecordType AND V.siYear = S.siYear AND V.tiMonth = S.tiMonth

	-- Renvoit le dataset final
	SELECT 
		EST.*, 
		iStartNbr = ISNULL(SNT.iStartNbr,0),
		iDeclaredNbr = ISNULL(DNT.iDeclaredNbr,0),
		iCorrectedNbr = ISNULL(CNT.iCorrectedNbr,0),
		iNotResendNbr = ISNULL(CNT.iNotResendNbr,0),
		iTotal = ISNULL(SNT.iStartNbr,0) + ISNULL(DNT.iDeclaredNbr,0) + ISNULL(CNT.iCorrectedNbr,0) + ISNULL(CNT.iNotResendNbr,0)		
	FROM @ErrorSummaryTable EST
	LEFT JOIN @DeclareNbrTable DNT ON DNT.siRecordType = EST.siRecordType AND DNT.siYear = EST.siYear AND DNT.tiMonth = EST.tiMonth		
	LEFT JOIN @CorrectedNbrTable CNT ON CNT.siRecordType = EST.siRecordType AND CNT.siYear = EST.siYear AND CNT.tiMonth = EST.tiMonth
	LEFT JOIN @StartNbrTable SNT ON SNT.siRecordType = EST.siRecordType AND SNT.siYear = EST.siYear AND SNT.tiMonth = EST.tiMonth
	ORDER BY EST.siRecordType, EST.siYear, EST.tiMonth	
END
