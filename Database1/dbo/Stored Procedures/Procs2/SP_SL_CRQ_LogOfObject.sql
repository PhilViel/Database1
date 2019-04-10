/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 : SP_SL_CRQ_LogOfObject
Description         : Journal des modifications d'un objet.
Valeurs de retours  : >0  : Tout à fonctionné
                      <=0 : Erreur SQL 
Note                : ADX0000591 IA 2004-11-22	Bruno Lapointe		Création
									2008-12-19	Pierre-Luc Simard	Supprimer les blobs temporaires
									2014-10-27	Pierre-Luc Simard	Ajouts des changements de représentant au niveua des unités
									2015-02-02	Donald Huppé		Si CRQ_Log.loginName est non NULL, alors le mettre dans UserName, au lieu de l'humain du connectID
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_CRQ_LogOfObject](
	@LogTableName VARCHAR(75), -- Type d'objet (Un_Convention, Un_Beneficiairy, Un_Subscriber, CRQ_User)
	@LogCodeID INTEGER) -- ID de l'objet
AS
BEGIN

	DECLARE
		@iLogID INTEGER,
		@vcLogTableName VARCHAR(75),
		@cLogActionShortName CHAR(1),
		@iBlobID INTEGER

	SET @iBlobID = 0

	-- Table temporaire pour formatage des blobs
	CREATE TABLE #Log (
		LogID INTEGER PRIMARY KEY,
		BlobID INTEGER)
		
	INSERT INTO #Log
		SELECT
			L.LogID, -- ID du log
			0
		FROM CRQ_Log L
		WHERE L.LogTableName = @LogTableName
		  AND L.LogCodeID = @LogCodeID
		  AND L.LogText IS NOT NULL

	DECLARE crLog CURSOR FOR
		SELECT 
			L.LogID,
			L.LogTableName,
			LA.LogActionShortName
		FROM #Log T
		JOIN CRQ_Log L ON L.LogID = T.LogID
		JOIN CRQ_LogAction LA ON LA.LogActionID = L.LogActionID

	OPEN crLog

	-- Premier log
	FETCH NEXT FROM crLog INTO 
		@iLogID,
		@vcLogTableName,
		@cLogActionShortName

	WHILE @@FETCH_STATUS = 0
		AND @iBlobID >= 0
	BEGIN
		-- Appelle la fonction qui format le blob temporaire
		EXECUTE @iBlobID = SP_TT_CRQ_FormatTextOfLog @iLogID, @cLogActionShortName, @vcLogTableName, 'FRA'

		IF @iBlobID > 0
		BEGIN
			-- Inscrit le ID du blob dans la table temporaire
			UPDATE #Log
			SET BlobID = @iBlobID 
			WHERE LogID = @iLogID
		END

		-- Dernier log
		FETCH NEXT FROM crLog INTO 
			@iLogID,
			@vcLogTableName,
			@cLogActionShortName
	END

	-- Ferme et libère le curseur
	CLOSE crLog
	DEALLOCATE crLog

	-- Fait la sélection final des enregistrements nécessaire au journal des modifications
	SELECT
		L.LogID, -- ID du log
		L.LogTime, -- Date et l’heure à laquelle l’usager a sauvegardé la modification.
		UserName = isnull(l.LoginName, U.LastName + ', ' + U.FirstName), -- Nom de l'usager
		LA.LogActionLongName,
		C.StationName, -- Station
		C.IPAddress, -- Adresse IP
		B.BlobID, -- ID unique du blob
		B.Blob -- Le log des modifications
	FROM #Log T
	JOIN CRQ_Log L ON T.LogID = L.LogID
	JOIN Mo_Connect C ON C.ConnectID = L.ConnectID
	JOIN CRQ_LogAction LA ON LA.LogActionID = L.LogActionID
	JOIN dbo.Mo_Human U ON U.HumanID = C.UserID
	JOIN CRQ_Blob B ON B.BlobID = T.BlobID
	WHERE L.LogTableName = @LogTableName
	  AND L.LogCodeID = @LogCodeID

	UNION ALL
	
	SELECT 
		L.LogID,
		L.LogTime,
		UserName = HU.LastName + ', ' + HU.FirstName, -- Nom de l'usager
		'Modif. - Unités', --L.LogActionID,
		C.StationName,
		C.IPAddress, 
		L.LogID, -- Pas de blob...
		LogText = 'Groupe d''unités: ' 
						+ CAST(YEAR(U.InForceDate) AS VARCHAR(4)) + '-' 
						+ CASE WHEN MONTH(U.InforceDate) < 10 THEN '0' ELSE '' END + CAST(MONTH(U.InForceDate) AS VARCHAR(2)) + '-' 
						+ CASE WHEN DAY(U.InforceDate) < 10 THEN '0' ELSE '' END + CAST(DAY(U.InForceDate) AS VARCHAR(2)) + ' (' + CAST(U.UnitQty AS VARCHAR(10)) + ')'
						+ CHAR(13)+CHAR(10) --+ CAST(' ' AS CHAR(37)) 
						+ CAST(L.LogText AS VARCHAR(8000))
	FROM Mo_Log L
	JOIN dbo.Un_Unit U ON U.UnitID = L.LogCodeID
	JOIN Mo_Connect C ON C.ConnectID = L.ConnectID
	JOIN dbo.Mo_Human HU ON HU.HumanID = C.UserID
	WHERE @LogTableName = 'Un_Convention'
		AND L.LogTableName = 'Un_Unit'
		AND L.LogActionID = 'U'
		AND U.ConventionID = @LogCodeID
	
	ORDER BY L.LogTime DESC, L.LogID DESC

	-- Supprime les blobs temporaires
	DELETE CRQ_Blob
	FROM CRQ_Blob
	JOIN #Log T ON T.BlobID = CRQ_Blob.BlobID

	-- Supprime la table temporaire
	DROP TABLE #Log

	RETURN @iBlobID
END


