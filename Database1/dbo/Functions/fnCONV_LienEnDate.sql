/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnCONV_LienEnDate
Nom du service		: Déterminer le lien d’une convention à une date
But 				: Retourner le lien d’une convention à une date donnée.
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Convention				Identifiant de la convention.
						dtDate						Date pour laquelle le souscripteur doit être déterminé.  Si la 
													date n’est pas fournie, on considère que c’est pour la date du jour.

Exemple d’appel		:	exec [dbo].[fnCONV_LienEnDate] 305515, NULL

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iID_Souscripteur				Identifiant du souscripteur à la
																					date demandée.  La valeur de
																					retour 0 indique que le
																					souscripteur n’existe plus
																					dans la base de données.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-11-24		Josée Parent						Création du service							

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_LienEnDate]
(
	@iID_Convention INT,
	@dtDate DATETIME
)
RETURNS INT
AS
BEGIN
	-- Si l'identifiant de la convention est vide, retourner 0
	IF @iID_Convention IS NULL or @iID_Convention = 0
		RETURN 0

	DECLARE
		@dtDate_Modif DATETIME,
		@iID_Lien INT,
		@dtDate_TMP DATETIME
		
	-- Utiliser la date du jour si la date n'est pas spécifié en paramètre
	IF @dtDate IS NULL
		SET @dtDate_TMP = GETDATE()
	ELSE
		SET @dtDate_TMP = dbo.fnGENE_DateDeFinAvecHeure(@dtDate)

	-- Rechercher l'historique des changements de lien
	DECLARE curHistoriqueLien CURSOR FOR
	-- Changements de Lien
	SELECT l.LogTime AS dtDate,
	CASE CHARINDEX('UnBenefLinkTypeID',LogText)
		WHEN 0 THEN
			0
		ELSE
			ISNULL(CAST(SUBSTRING(LogText,CHARINDEX('UnBenefLinkTypeID',LogText)+18+
			LEN(SUBSTRING(LogText,CHARINDEX('UnBenefLinkTypeID',LogText)+18,
			CHARINDEX(CHAR(30),SUBSTRING(LogText,CHARINDEX('UnBenefLinkTypeID',LogText)+18,
			250))-1))+1,CHARINDEX(CHAR(30),SUBSTRING(LogText,CHARINDEX('UnBenefLinkTypeID',
			LogText)+18+LEN(SUBSTRING(LogText,CHARINDEX('UnBenefLinkTypeID',LogText)+18,
			CHARINDEX(CHAR(30),SUBSTRING(LogText,CHARINDEX('UnBenefLinkTypeID',LogText)+18,
			250))-1))+1,250))-1) as int),0)
	END AS iID_Lien
	FROM CRQ_Log l 
		 JOIN CRQ_LogAction la ON la.LogActionID = l.LogActionID AND
								  la.LogActionShortName = 'U'
	WHERE l.LogTableName = 'Un_Convention' AND
						   l.LogCodeID = @iID_Convention AND
						   LogText LIKE '%UnBenefLinkTypeID%'
	UNION ALL
	-- Tout premier lien
	SELECT CAST(0 AS DATETIME) AS dtDate,  -- Date la plus éloigné
		CASE CHARINDEX('UnBenefLinkTypeID',LogText)
		WHEN 0 THEN
			0
		ELSE
		   ISNULL(CAST(SUBSTRING(LogText,CHARINDEX('UnBenefLinkTypeID',LogText)+18,
			CHARINDEX(CHAR(30),SUBSTRING(LogText,CHARINDEX('UnBenefLinkTypeID',LogText)+18,250))-1) AS INT),0)
		END AS iID_Lien
	FROM CRQ_Log l 
		 JOIN CRQ_LogAction la ON la.LogActionID = l.LogActionID AND
								  la.LogActionShortName = 'U'
	WHERE l.LogTableName = 'Un_Convention' AND
						   l.LogCodeID = @iID_Convention AND
						   l.LogText LIKE '%UnBenefLinkTypeID%' AND
		  l.LogTime = (SELECT MIN(LogTime)
					   FROM CRQ_Log l2
							JOIN CRQ_LogAction la2 ON la2.LogActionID = l2.LogActionID
					   WHERE l2.LogTableName = l.LogTableName
							 AND l2.LogCodeID = l.LogCodeID
							 AND l2.LogText LIKE '%UnBenefLinkTypeID%'
							 AND la2.LogActionShortName = la.LogActionShortName)
	UNION ALL
	SELECT l.LogTime AS dtDate,
	CASE CHARINDEX('tiRelationshipTypeID',LogText)
		WHEN 0 THEN
			0
		ELSE
			ISNULL(CAST(SUBSTRING(LogText,CHARINDEX('tiRelationshipTypeID',LogText)+21+
			LEN(SUBSTRING(LogText,CHARINDEX('tiRelationshipTypeID',LogText)+21,
			CHARINDEX(CHAR(30),SUBSTRING(LogText,CHARINDEX('tiRelationshipTypeID',LogText)+21,
			250))-1))+1,CHARINDEX(CHAR(30),SUBSTRING(LogText,CHARINDEX('tiRelationshipTypeID',
			LogText)+21+LEN(SUBSTRING(LogText,CHARINDEX('tiRelationshipTypeID',LogText)+21,
			CHARINDEX(CHAR(30),SUBSTRING(LogText,CHARINDEX('tiRelationshipTypeID',LogText)+21,
			250))-1))+1,250))-1) as int),0)
	END AS iID_Lien
	FROM CRQ_Log l 
		 JOIN CRQ_LogAction la ON la.LogActionID = l.LogActionID AND
								  la.LogActionShortName = 'U'
	WHERE l.LogTableName = 'Un_Convention' AND
						   l.LogCodeID = @iID_Convention AND
						   LogText LIKE '%tiRelationshipTypeID%'
	UNION ALL
	-- Tout premier lien
	SELECT CAST('2006-07-05 08:38:58.217' AS DATETIME) AS dtDate,  -- Date la plus éloigné
		CASE CHARINDEX('tiRelationshipTypeID',LogText)
		WHEN 0 THEN
			0
		ELSE
		   ISNULL(CAST(SUBSTRING(LogText,CHARINDEX('tiRelationshipTypeID',LogText)+21,
			CHARINDEX(CHAR(30),SUBSTRING(LogText,CHARINDEX('tiRelationshipTypeID',LogText)+21,250))-1) AS INT),0)
		END AS iID_Lien
	FROM CRQ_Log l 
		 JOIN CRQ_LogAction la ON la.LogActionID = l.LogActionID AND
								  la.LogActionShortName = 'U'
	WHERE l.LogTableName = 'Un_Convention' AND
						   l.LogCodeID = @iID_Convention AND
						   l.LogText LIKE '%tiRelationshipTypeID%' AND
		  l.LogTime = (SELECT MIN(LogTime)
					   FROM CRQ_Log l2
							JOIN CRQ_LogAction la2 ON la2.LogActionID = l2.LogActionID
					   WHERE l2.LogTableName = l.LogTableName
							 AND l2.LogCodeID = l.LogCodeID
							 AND l2.LogText LIKE '%tiRelationshipTypeID%'
							 AND la2.LogActionShortName = la.LogActionShortName)
	ORDER BY dtDate Desc

	OPEN curHistoriqueLien
	FETCH NEXT FROM curHistoriqueLien
			   INTO @dtDate_Modif,@iID_Lien

	-- S'il n'y a jamais eu de modification au lien, retourner celui en cours
	-- qui a toujours été en vigueur peut importe la date (majorité des cas).
	-- S'il y a eu des modifications, trouver le lien à la date demandée
	IF @@FETCH_STATUS <> 0 OR @iID_lien = 0
		BEGIN
			CLOSE curHistoriqueLien
			DEALLOCATE curHistoriqueLien

			-- Rechercher le lien en cours
			SELECT @iID_lien = co.tiRelationshipTypeID
			FROM dbo.Un_Convention co
			WHERE co.ConventionID = @iID_Convention

			-- Retourner le lien en cours
			RETURN @iID_lien
		END
	ELSE
		BEGIN
			-- Rouler dans l'historique des changements de lien jusqu'à la date demandée
			WHILE @@FETCH_STATUS = 0 AND
				  (@dtDate_Modif > @dtDate_TMP OR @iID_lien = 0)
			BEGIN
				FETCH NEXT FROM curHistoriqueLien
						   INTO @dtDate_Modif,@iID_lien
			END

			IF @iID_lien IS NULL
				SET @iID_lien = 0
		END

	CLOSE curHistoriqueLien
	DEALLOCATE curHistoriqueLien
	
	-- Retourner le lien à la date demandée
	RETURN @iID_lien
END


