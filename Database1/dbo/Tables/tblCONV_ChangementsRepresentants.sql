CREATE TABLE [dbo].[tblCONV_ChangementsRepresentants] (
    [iID_ChangementRepresentant] INT           IDENTITY (1, 1) NOT NULL,
    [iID_DirecteurAgence]        INT           NOT NULL,
    [iID_Statut]                 INT           NOT NULL,
    [dDate_Statut]               DATETIME      NOT NULL,
    [vcJustification]            VARCHAR (100) NULL,
    [iID_UtilisateurCreation]    INT           NOT NULL,
    [iID_UtilisateurApprobation] INT           NULL,
    CONSTRAINT [PK_CONV_ChangementsRepresentants] PRIMARY KEY NONCLUSTERED ([iID_ChangementRepresentant] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CONV_ChangementsRepresentants_Mo_User__iIDUtilisateurApprobation] FOREIGN KEY ([iID_UtilisateurApprobation]) REFERENCES [dbo].[Mo_User] ([UserID]),
    CONSTRAINT [FK_CONV_ChangementsRepresentants_Mo_User__iIDUtilisateurCreation] FOREIGN KEY ([iID_UtilisateurCreation]) REFERENCES [dbo].[Mo_User] ([UserID]),
    CONSTRAINT [FK_CONV_ChangementsRepresentants_Un_Rep__iIDDirecteurAgence] FOREIGN KEY ([iID_DirecteurAgence]) REFERENCES [dbo].[Un_Rep] ([RepID])
);


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TtblCONV_ChangementsRepresentants_Log

Historique des modifications:
		Date				Programmeur				Description										
		------------		-------------------------	-----------------------------------------	
		2013-10-16	Pierre-Luc Simard		Création du trigger pour la mise en production des scénarios de transfert clients
		
****************************************************************************************************/
CREATE TRIGGER dbo.TtblCONV_ChangementsRepresentants_Log ON dbo.tblCONV_ChangementsRepresentants 
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
	
	-- Création du log lors de l'ajout d'un scénario ayant le statut 3 (Exécuté) ou lorsqu'un scénario existant passe au statut 3.
	IF EXISTS ( -- Ajout d'un scénario ayant déjà le statut 3 (Exécuté)
			SELECT I.iID_ChangementRepresentant
			FROM INSERTED I
			LEFT JOIN DELETED D ON D.iID_ChangementRepresentant = I.iID_ChangementRepresentant
			WHERE D.iID_ChangementRepresentant IS NULL  -- Ajout
				OR (I.iID_Statut = 3 AND D.iID_Statut <> 3) -- Modification
			)
	BEGIN
		-- Créer une table temporaire qui contiendra les scénarios qui ont été ajoutés ou modifiés
		DECLARE 
			@tblCONV_ChangementsRepresentants TABLE (
				iID_ChangementRepresentant INT PRIMARY KEY)
			
		INSERT INTO @tblCONV_ChangementsRepresentants
			SELECT 
				I.iID_ChangementRepresentant
			FROM INSERTED I
			LEFT JOIN DELETED D ON D.iID_ChangementRepresentant = I.iID_ChangementRepresentant
			WHERE D.iID_ChangementRepresentant IS NULL  -- Ajout
				OR (I.iID_Statut = 3 AND D.iID_Statut <> 3) -- Modification
		
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
			CRCS.iID_Souscripteur,
			CR.dDate_Statut,
			LA.LogActionID,
			LogDesc = 'Souscripteur : '+H.LastName+', '+H.FirstName,
			LogText =
				CASE 
					WHEN ISNULL(CRCS.iID_RepresentantOriginal,0) <> ISNULL(CRC.iID_RepresentantCible,0) THEN
						'RepID'+@cSep+
						CASE 
							WHEN ISNULL(CRCS.iID_RepresentantOriginal,0) <= 0 THEN ''
						ELSE CAST(CRCS.iID_RepresentantOriginal AS VARCHAR)
						END+@cSep+
						CASE 
							WHEN ISNULL(CRC.iID_RepresentantCible,0) <= 0 THEN ''
						ELSE CAST(CRC.iID_RepresentantCible AS VARCHAR)
						END+@cSep+
						ISNULL(OHR.LastName+', '+OHR.FirstName,'')+@cSep+
						ISNULL(HR.LastName+', '+HR.FirstName,'')+@cSep+
						CHAR(13)+CHAR(10)
				ELSE ''
				END
			FROM @tblCONV_ChangementsRepresentants C
			JOIN tblCONV_ChangementsRepresentants CR ON CR.iID_ChangementRepresentant = C.iID_ChangementRepresentant
			JOIN tblCONV_ChangementsRepresentantsCibles CRC ON CRC.iID_ChangementRepresentant = CR.iID_ChangementRepresentant
			JOIN tblCONV_ChangementsRepresentantsCiblesSouscripteurs CRCS ON CRCS.iID_ChangementRepresentantCible = CRC.iID_ChangementRepresentantCible
			JOIN dbo.Un_Subscriber S ON S.SubscriberID = CRCS.iID_Souscripteur
			JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
			LEFT JOIN dbo.Mo_Human HR ON HR.HumanID = CRC.iID_RepresentantCible
			LEFT JOIN dbo.Mo_Human OHR ON OHR.HumanID = CRCS.iID_RepresentantOriginal
			JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
			WHERE ISNULL(CRCS.iID_RepresentantOriginal,0) <> 0
	END
	
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Statut du changement (1 = En conception, 2 = Soumis pour approbation, 3 = Exécuté).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ChangementsRepresentants', @level2type = N'COLUMN', @level2name = N'iID_Statut';

