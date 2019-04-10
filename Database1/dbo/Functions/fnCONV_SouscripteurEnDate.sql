/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnCONV_SouscripteurEnDate
Nom du service		: Déterminer le souscripteur d’une convention à une date
But 				: Retourner le souscripteur d’une convention à une date donnée.
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Convention				Identifiant de la convention.
						dtDate						Date pour laquelle le souscripteur doit être déterminé.  Si la 
													date n’est pas fournie, on considère que c’est pour la date du jour.

Exemple d’appel		:	exec [dbo].[fnCONV_SouscripteurEnDate] 305515, NULL

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
		2008-11-06		Josée Parent						Création du service							
		2011-01-27		Éric Deshaies						Prendre le souscripteur en cours à la date
															du jour dans la table Un_Convention lorsque
															la date en paramètre d'entrée est NULL.
															Cela afin de ne pas lire le log inutilement.

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_SouscripteurEnDate]
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
		@iID_Souscripteur INT,
		@dtDate_TMP DATETIME
		
	-- Si la date n'est pas spécifié en paramètre, retourner le souscripteur en cours de la convention sans passer par le log
	IF @dtDate IS NULL
		BEGIN
			SELECT @iID_Souscripteur = C.SubscriberID
			FROM dbo.Un_Convention C
			WHERE C.ConventionID = @iID_Convention

			RETURN @iID_Souscripteur
		END
	ELSE
		SET @dtDate_TMP = dbo.fnGENE_DateDeFinAvecHeure(@dtDate)

	-- Rechercher l'historique des changements de souscripteur
	DECLARE curHistoriqueSouscripteur CURSOR FOR
	-- Changements de souscripteur
	SELECT l.LogTime AS dtDate,
	CASE CHARINDEX('SubscriberID',REPLACE(CAST(LogText AS VARCHAR(8000)),'CoSubscriberID',''))
		WHEN 0 THEN
			0
		ELSE
		   ISNULL(CAST(SUBSTRING(LogText,CHARINDEX('SubscriberID',LogText)+13+
		   LEN(SUBSTRING(LogText,CHARINDEX('SubscriberID',LogText)+13,
		   CHARINDEX(CHAR(30),SUBSTRING(LogText,CHARINDEX('SubscriberID',LogText)+13,
		   250))-1))+1,CHARINDEX(CHAR(30),SUBSTRING(LogText,CHARINDEX('SubscriberID',
		   LogText)+13+LEN(SUBSTRING(LogText,CHARINDEX('SubscriberID',LogText)+13,
		   CHARINDEX(CHAR(30),SUBSTRING(LogText,CHARINDEX('SubscriberID',LogText)+13,
		   250))-1))+1,250))-1) as int),0)
	END AS iID_Souscripteur
	FROM CRQ_Log l 
		 JOIN CRQ_LogAction la ON la.LogActionID = l.LogActionID AND
								  la.LogActionShortName = 'U'
	WHERE l.LogTableName = 'Un_Convention' AND
						   l.LogCodeID = @iID_Convention AND
						   REPLACE(CAST(LogText AS VARCHAR(8000)),'CoSubscriberID','') LIKE '%SubscriberID%'
	UNION ALL
	-- Tout premier souscripteur
	SELECT CAST(0 AS DATETIME) AS dtDate,  -- Date la plus éloigné
		CASE CHARINDEX('SubscriberID',REPLACE(CAST(LogText AS VARCHAR(8000)),'CoSubscriberID',''))
		WHEN 0 THEN
			0
		ELSE
		   ISNULL(CAST(SUBSTRING(LogText,CHARINDEX('SubscriberID',LogText)+13,
		   CHARINDEX(CHAR(30),SUBSTRING(LogText,CHARINDEX('SubscriberID',LogText)+13,250))-1) AS INT),0)
		END AS iID_Souscripteur
	FROM CRQ_Log l 
		 JOIN CRQ_LogAction la ON la.LogActionID = l.LogActionID AND
								  la.LogActionShortName = 'U'
	WHERE l.LogTableName = 'Un_Convention' AND
						   l.LogCodeID = @iID_Convention AND
						   l.LogText LIKE '%SubscriberID%' AND
		  l.LogTime = (SELECT MIN(LogTime)
					   FROM CRQ_Log l2
							JOIN CRQ_LogAction la2 ON la2.LogActionID = l2.LogActionID
					   WHERE l2.LogTableName = l.LogTableName
							 AND l2.LogCodeID = l.LogCodeID
							 AND REPLACE(CAST(l2.LogText AS VARCHAR(8000)),'CoSubscriberID','') LIKE '%SubscriberID%'
							 AND la2.LogActionShortName = la.LogActionShortName)
	ORDER BY dtDate Desc

	OPEN curHistoriqueSouscripteur
	FETCH NEXT FROM curHistoriqueSouscripteur
			   INTO @dtDate_Modif,@iID_Souscripteur

	-- S'il n'y a jamais eu de modification au souscripteur, retourner celui en cours
	-- qui a toujours été en vigueur peut importe la date (majorité des cas).
	-- S'il y a eu des modifications, trouver le souscripteur à la date demandée
	IF @@FETCH_STATUS <> 0 OR @iID_Souscripteur = 0
		BEGIN
			CLOSE curHistoriqueSouscripteur
			DEALLOCATE curHistoriqueSouscripteur

			-- Rechercher le souscripteur en cours
			SELECT @iID_Souscripteur = co.SubscriberID
			FROM dbo.Un_Convention co
				 JOIN dbo.Un_Subscriber B ON B.SubscriberID = co.SubscriberID
			WHERE co.ConventionID = @iID_Convention

			-- Retourner le souscripteur en cours
			RETURN @iID_Souscripteur
		END
	ELSE
		BEGIN
			-- Rouler dans l'historique des changements de souscripteur jusqu'à la date demandée
			-- en autant que le souscripteur existe encore dans la BD
			WHILE @@FETCH_STATUS = 0 AND
				  (@dtDate_Modif > @dtDate_TMP OR @iID_Souscripteur = 0)
			BEGIN
				FETCH NEXT FROM curHistoriqueSouscripteur
						   INTO @dtDate_Modif,@iID_Souscripteur
				IF @@FETCH_STATUS = 0 AND @iID_Souscripteur IS NOT NULL
					-- Vérifier que le souscripteur existe toujours dans la BD
					SELECT @iID_Souscripteur = ISNULL(B.SubscriberID,0)
					FROM dbo.Un_Subscriber B
					WHERE B.SubscriberID = @iID_Souscripteur
			END
			IF @iID_Souscripteur IS NULL
				SET @iID_Souscripteur = 0
		END

	CLOSE curHistoriqueSouscripteur
	DEALLOCATE curHistoriqueSouscripteur
	
	-- Retourner le souscripteur à la date demandée
	RETURN @iID_Souscripteur
END


