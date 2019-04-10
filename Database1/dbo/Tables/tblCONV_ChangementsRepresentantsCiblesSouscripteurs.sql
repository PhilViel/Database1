CREATE TABLE [dbo].[tblCONV_ChangementsRepresentantsCiblesSouscripteurs] (
    [iID_ChangementRepresentantCible] INT NOT NULL,
    [iID_Souscripteur]                INT NOT NULL,
    [iID_RepresentantOriginal]        INT NULL,
    CONSTRAINT [PK_CONV_ChangementsRepresentantsCiblesSouscripteurs] PRIMARY KEY NONCLUSTERED ([iID_ChangementRepresentantCible] ASC, [iID_Souscripteur] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CONV_ChangementsRepresentantsCiblesSouscripteurs_CONV_ChangementsRepresentantsCibles__iIDChangementRepresentantCible] FOREIGN KEY ([iID_ChangementRepresentantCible]) REFERENCES [dbo].[tblCONV_ChangementsRepresentantsCibles] ([iID_ChangementRepresentantCible]),
    CONSTRAINT [FK_CONV_ChangementsRepresentantsCiblesSouscripteurs_Un_Subscriber__iIDSouscripteur] FOREIGN KEY ([iID_Souscripteur]) REFERENCES [dbo].[Un_Subscriber] ([SubscriberID])
);


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TtblCONV_ChangementsRepresentantsCiblesSouscripteurs_Log

Historique des modifications:
		Date				Programmeur				Description										
		------------		-------------------------	-----------------------------------------	
		2013-10-22	Pierre-Luc Simard		Création du trigger pour la mise en production des scénarios de transfert clients
		
****************************************************************************************************/
CREATE TRIGGER dbo.TtblCONV_ChangementsRepresentantsCiblesSouscripteurs_Log ON dbo.tblCONV_ChangementsRepresentantsCiblesSouscripteurs 
   AFTER INSERT, UPDATE
AS 
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

	-- Si la table #DisableTrigger est présente, il se pourrait que le trigger
	-- ne soit pas à exécuter
	IF object_id('tempdb..#DisableTrigger') is not null 
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	-- *** FIN AVERTISSEMENT *** 
	
	DECLARE @cSep CHAR(1)
	
	SET @cSep = CHAR(30)
	
	-- On exécute le trigger sur la table des souscritpeurs (tblCONV_ChangementsRepresentantsCiblesSouscripteurs) afin de récupérer l'ID de l'ancien représentant. 
	-- Proacces modifie le statut à 3 (Exécuté) avant d'enregistrer les ID des anciens représenant donc on ne peut pas mettre le trigger sur la table tblCONV_ChangementsRepresentants.
	
	-- Création du log lors de l'attibution d'un représentant via l'outil de transfert de Proacces, lorsque le scénario a le Statut 3 (Exécuté)
	IF EXISTS ( -- Ajout d'un scénario ayant déjà le statut 3 (Exécuté)
			SELECT I.iID_ChangementRepresentantCible
			FROM INSERTED I
			LEFT JOIN DELETED D ON D.iID_ChangementRepresentantCible = I.iID_ChangementRepresentantCible AND D.iID_Souscripteur = I.iID_Souscripteur
			WHERE D.iID_Souscripteur IS NULL  -- Ajout
				OR (ISNULL(I.iID_RepresentantOriginal,0) <> ISNULL(D.iID_RepresentantOriginal,0)) -- Modification du représentant original
			)
	BEGIN
		-- Créer une table temporaire qui contiendra les scénarios qui ont été ajoutés ou modifiés
		DECLARE 
			@tblCONV_ChangementsRepresentantsCiblesSouscripteurs TABLE (
				iID_Souscripteur INT PRIMARY KEY,
				iID_RepresentantOriginal INT,
				iID_RepresentantCible INT,
				dDate_Statut DATETIME)
	
		INSERT INTO @tblCONV_ChangementsRepresentantsCiblesSouscripteurs
			SELECT DISTINCT
				I.iID_Souscripteur,
				I.iID_RepresentantOriginal,
				CRC.iID_RepresentantCible,
				CR.dDate_Statut
			FROM INSERTED I
			LEFT JOIN DELETED D ON D.iID_ChangementRepresentantCible = I.iID_ChangementRepresentantCible AND D.iID_Souscripteur = I.iID_Souscripteur
			JOIN tblCONV_ChangementsRepresentantsCibles CRC ON CRC.iID_ChangementRepresentantCible = I.iID_ChangementRepresentantCible
			JOIN tblCONV_ChangementsRepresentants CR ON CR.iID_ChangementRepresentant = CRC.iID_ChangementRepresentant
			WHERE (D.iID_Souscripteur IS NULL  -- Ajout
				OR (ISNULL(I.iID_RepresentantOriginal,0) <> ISNULL(D.iID_RepresentantOriginal,0))) -- Modification
				AND iID_Statut = 3 -- Le Statut doit être à Exécuté
		
		INSERT INTO CRQ_Log (
			ConnectID,
			LogTableName,
			LogCodeID,
			LogTime,
			LogActionID,
			LogDesc,
			LogText)
		SELECT
			2,--@ConnectID,
			'Un_Subscriber',
			C.iID_Souscripteur,
			C.dDate_Statut,
			LA.LogActionID,
			LogDesc = 'Souscripteur : '+H.LastName+', '+H.FirstName,
			LogText =
				'RepID'+@cSep+
				CASE 
					WHEN ISNULL(C.iID_RepresentantOriginal,0) <= 0 THEN ''
				ELSE CAST(C.iID_RepresentantOriginal AS VARCHAR)
				END+@cSep+
				CASE 
					WHEN ISNULL(C.iID_RepresentantCible,0) <= 0 THEN ''
				ELSE CAST(C.iID_RepresentantCible AS VARCHAR)
				END+@cSep+
				ISNULL(OHR.LastName+', '+OHR.FirstName,'')+@cSep+
				ISNULL(HR.LastName+', '+HR.FirstName,'')+@cSep+
				CHAR(13)+CHAR(10)
			FROM @tblCONV_ChangementsRepresentantsCiblesSouscripteurs C
			JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.iID_Souscripteur
			JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
			LEFT JOIN dbo.Mo_Human HR ON HR.HumanID = C.iID_RepresentantCible
			LEFT JOIN dbo.Mo_Human OHR ON OHR.HumanID = C.iID_RepresentantOriginal
			JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
			WHERE ISNULL(C.iID_RepresentantOriginal,0) <> 0 -- L'ID de l'ancien représentant doit être enregistré
	END
	
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

