/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                : 	RP_UN_CESPErrors
Description        : 	Rapport des erreurs (Fichier de retour de la SCÉÉ).
Valeurs de retours : 	>0  : Tout à fonctionné
                      	<=0 : Erreur SQL
Note                :	ADX0000497	IA	2004-09-13	Bruno Lapointe		Création
			ADX0000755	IA	2005-08-23	Bruno Lapointe		La valeur du champ SocialNumber sera calculée
											selon celle du champ iCESG800SINID.  Si la valeur de ce dernier est 0, 2 ou 3 alors
											on retournera 0 dans le champ SocialNumber si elle est 1 on retournera 1.
			ADX0000835	IA	2006-04-20	Bruno Lapointe		Adaptation pour PCEE 4.3
			ADX0001206	IA	2006-12-18	Alain Quirion		Optimisation
                            2008-12-15  Fatiha Araar        Ajouter les erreurs sur les enregistrements 511
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_CESPErrors](
	@ConnectID INTEGER,
	@iCESPReceiveFileID INTEGER ) -- ID unique du fichier de retour
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	SELECT 
		G8.iCESP800ID,
		ConventionNo = ISNULL(C1.ConventionNo, ISNULL(C2.ConventionNo, ISNULL(C4.ConventionNo,C5.ConventionNo))),
		GovernmentID = ISNULL(G1.vcTransID, ISNULL(G2.vcTransID, ISNULL(G4.vcTransID,G5.vcTransID))),
		TransDate = ISNULL(O4.OperDate, ISNULL(SF2.dtCESPSendFile,SF3.dtCESPSendFile)),
		TransTypeID = ISNULL(G2.tiType,ISNULL(G4.tiCESP400TypeID,CASE 
                                                                     WHEN G5.vcTransID IS NOT NULL THEN 12 --Type de transaction 511
                                                                     ELSE 2
                                                                  END)),
		TransTypeDesc = dbo.FN_UN_GetGovernmentTransTypeDesc(ISNULL(G2.tiType,ISNULL(G4.tiCESP400TypeID,CASE 
                                                                     WHEN G5.vcTransID IS NOT NULL THEN 12 --Type de transaction 511
                                                                     ELSE 2
                                                                  END))),
		ErrorFieldName = G8.vcErrFieldName,
		ErrorCode = G8.siCESP800ErrorID,
		SocialNumber = 
			CAST(
					CASE 
						WHEN G8.tyCESP800SINID = 1 THEN 1
					ELSE 0
					END AS BIT),
		FirstName = G8.bFirstName,
		LastName = G8.bLastName,
		BirthDate = G8.bBirthDate,
		SexID = G8.bSex,
		CS.ConventionStateName
	FROM Un_CESP800 G8
	LEFT JOIN Un_CESP100 G1 ON G1.iCESP800ID = G8.iCESP800ID
	LEFT JOIN dbo.Un_Convention C1 ON C1.ConventionID = G1.ConventionID
	LEFT JOIN Un_CESPSendFile SF1 ON SF1.iCESPSendFileID = G1.iCESPSendFileID
	LEFT JOIN Un_CESP200 G2 ON G2.iCESP800ID = G8.iCESP800ID  
	LEFT JOIN dbo.Un_Convention C2 ON C2.ConventionID = G2.ConventionID
	LEFT JOIN Un_CESPSendFile SF2 ON SF2.iCESPSendFileID = G2.iCESPSendFileID
	LEFT JOIN Un_CESP400 G4 ON G4.iCESP800ID = G8.iCESP800ID  
	LEFT JOIN Un_Oper O4 ON O4.OperID = G4.OperID
	LEFT JOIN dbo.Un_Convention C4 ON C4.ConventionID = G4.ConventionID
    LEFT JOIN Un_Cesp511 G5 ON G5.iCESP800ID = G8.iCESP800ID --Ajout des erreurs 511
    LEFT JOIN dbo.Un_Convention C5 ON C5.ConventionID = G5.ConventionID
    LEFT JOIN Un_CESPSendFile SF3 ON SF3.iCESPSendFileID = G5.iCESPSendFileID
  	LEFT JOIN (-- Retrouve l'état actuel d'une convention
		SELECT 
			T.ConventionID,
			CS.ConventionStateID,
			CS.ConventionStateName
		FROM (-- Retourne la plus grande date de début d'un état par convention
			SELECT 
				S.ConventionID,
				MaxDate = MAX(S.StartDate)
			FROM Un_ConventionConventionState S
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			WHERE S.StartDate <= GETDATE()
			GROUP BY S.ConventionID
			) T
		JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
		JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID -- Pour retrouver la description de l'état
		) CS ON CS.ConventionID = ISNULL(C1.ConventionID, ISNULL(C2.ConventionID, ISNULL(C4.ConventionID,C5.ConventionID)))
	WHERE G8.iCESPReceiveFileID = @iCESPReceiveFileID 
		OR @iCESPReceiveFileID = 0
	ORDER BY 
		ConventionNo, 
		TransDate, 
		TransTypeID, 
		GovernmentID

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = @siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
	BEGIN
		-- Insère un log de l'objet inséré.
		INSERT INTO Un_Trace (
				ConnectID, -- ID de connexion de l’usager
				iType, -- Type de trace (1 = recherche, 2 = rapport)
				fDuration, -- Temps d’exécution de la procédure
				dtStart, -- Date et heure du début de l’exécution.
				dtEnd, -- Date et heure de la fin de l’exécution.
				vcDescription, -- Description de l’exécution (en texte)
				vcStoredProcedure, -- Nom de la procédure stockée
				vcExecutionString ) -- Ligne d’exécution (inclus les paramètres)
			SELECT
				@ConnectID,
				2,				
				DATEDIFF(SECOND, @dtBegin, @dtEnd),
				@dtBegin,
				@dtEnd,
				'Rapport des erreurs',
				'RP_UN_CESPErrors',
				'EXECUTE RP_UN_CESPErrors @ConnectID ='+CAST(@ConnectID AS VARCHAR)+			
				', @iCESPReceiveFileID=' + CAST(@iCESPReceiveFileID AS VARCHAR)
	END	
END

