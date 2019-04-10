CREATE TABLE [dbo].[Un_CESP900] (
    [iCESP900ID]            INT          IDENTITY (1, 1) NOT NULL,
    [iCESP400ID]            INT          NULL,
    [iCESPReceiveFileID]    INT          NOT NULL,
    [ConventionID]          INT          NOT NULL,
    [tiCESP900OriginID]     TINYINT      NOT NULL,
    [cCESP900CESGReasonID]  CHAR (1)     NOT NULL,
    [cCESP900ACESGReasonID] CHAR (1)     NOT NULL,
    [vcTransID]             VARCHAR (15) NOT NULL,
    [vcBeneficiarySIN]      VARCHAR (9)  NOT NULL,
    [fCESG]                 MONEY        NOT NULL,
    [fACESG]                MONEY        NOT NULL,
    [fCLB]                  MONEY        NOT NULL,
    [fCLBFee]               MONEY        NOT NULL,
    [fPG]                   MONEY        NOT NULL,
    [vcPGProv]              VARCHAR (2)  NULL,
    [fCotisationGranted]    MONEY        NOT NULL,
    [iCESPID]               INT          NULL,
    [iCESP511ID]            INT          NULL,
    CONSTRAINT [PK_Un_CESP900] PRIMARY KEY CLUSTERED ([iCESP900ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESP900_Un_CESP__iCESPID] FOREIGN KEY ([iCESPID]) REFERENCES [dbo].[Un_CESP] ([iCESPID]),
    CONSTRAINT [FK_Un_CESP900_Un_CESP400__iCESP400ID] FOREIGN KEY ([iCESP400ID]) REFERENCES [dbo].[Un_CESP400] ([iCESP400ID]),
    CONSTRAINT [FK_Un_CESP900_Un_CESP511__iCESP511ID] FOREIGN KEY ([iCESP511ID]) REFERENCES [dbo].[Un_CESP511] ([iCESP511ID]),
    CONSTRAINT [FK_Un_CESP900_Un_CESP900ACESGReason__cCESP900ACESGReasonID] FOREIGN KEY ([cCESP900ACESGReasonID]) REFERENCES [dbo].[Un_CESP900ACESGReason] ([cCESP900ACESGReasonID]),
    CONSTRAINT [FK_Un_CESP900_Un_CESP900CESGReason__cCESP900CESGReasonID] FOREIGN KEY ([cCESP900CESGReasonID]) REFERENCES [dbo].[Un_CESP900CESGReason] ([cCESP900CESGReasonID]),
    CONSTRAINT [FK_Un_CESP900_Un_CESP900Origin__tiCESP900OriginID] FOREIGN KEY ([tiCESP900OriginID]) REFERENCES [dbo].[Un_CESP900Origin] ([tiCESP900OriginID]),
    CONSTRAINT [FK_Un_CESP900_Un_CESPReceiveFile__iCESPReceiveFileID] FOREIGN KEY ([iCESPReceiveFileID]) REFERENCES [dbo].[Un_CESPReceiveFile] ([iCESPReceiveFileID]),
    CONSTRAINT [FK_Un_CESP900_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP900_iCESPID]
    ON [dbo].[Un_CESP900]([iCESPID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP900_cCESP900ACESGReasonID]
    ON [dbo].[Un_CESP900]([cCESP900ACESGReasonID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP900_cCESP900CESGReasonID]
    ON [dbo].[Un_CESP900]([cCESP900CESGReasonID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP900_ConventionID]
    ON [dbo].[Un_CESP900]([ConventionID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP900_iCESP400ID]
    ON [dbo].[Un_CESP900]([iCESP400ID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP900_iCESPReceiveFileID]
    ON [dbo].[Un_CESP900]([iCESPReceiveFileID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP900_tiCESP900OriginID]
    ON [dbo].[Un_CESP900]([tiCESP900OriginID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP900_iCESP400ID_cCESP900CESGReasonID_iCESP900ID]
    ON [dbo].[Un_CESP900]([iCESP400ID] ASC, [cCESP900CESGReasonID] ASC, [iCESP900ID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP900_iCESP400ID_iCESP900ID_iCESPReceiveFileID]
    ON [dbo].[Un_CESP900]([iCESP400ID] ASC, [iCESP900ID] ASC, [iCESPReceiveFileID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE STATISTICS [_dta_stat_1912550047_4_1]
    ON [dbo].[Un_CESP900]([iCESP900ID], [iCESPReceiveFileID]);


GO
CREATE STATISTICS [_dta_stat_1912550047_4_2]
    ON [dbo].[Un_CESP900]([iCESP400ID], [iCESPReceiveFileID]);


GO
CREATE STATISTICS [_dta_stat_1912550047_6_2]
    ON [dbo].[Un_CESP900]([iCESP400ID], [tiCESP900OriginID]);


GO
CREATE STATISTICS [_dta_stat_1912550047_7_1]
    ON [dbo].[Un_CESP900]([cCESP900CESGReasonID], [iCESP900ID]);


GO
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc.
Nom                 :	TUn_CESP
Description         :	Trigger empˆchant de modifier les donn‚es des enregistrements 900
Valeurs de retours  :	N/A
Note                :	ADX0002426	BR		2007-05-24	Bruno Lapointe		Cr‚ation
											2010-10-04	Steve Gouin			Gestion du #DisableTrigger
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TUn_CESP900] ON [dbo].[Un_CESP900] FOR INSERT, UPDATE, DELETE 
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
	
	ROLLBACK TRANSACTION
	RAISERROR('Aucune opération n''est permise sur la table des enregistrements 900 autre que par le traitement de lecture du fichier de retour',16,1)
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table PCEE dans enregistrement 900 (Réponse aux demandes financières)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’enregistrement 900', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'iCESP900ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’enregistrement 400', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'iCESP400ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du fichier reçu', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'iCESPReceiveFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’origine', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'tiCESP900OriginID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la raison SCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'cCESP900CESGReasonID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la raison SCEE+', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'cCESP900ACESGReasonID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la transaction du promoteur ou du PCEE dans initié par eux (tiCESP900OriginID = 2)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'vcTransID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'NAS du bénéficiaire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'vcBeneficiarySIN';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de SCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'fCESG';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de SCEE+', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'fACESG';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant du BEC', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'fCLB';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Frais reçu pour la gestion du BEC', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'fCLBFee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de la subvention provincial', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'fPG';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Province de la subvention provinciale', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'vcPGProv';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de cotisation subventionnée', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'fCotisationGranted';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique d''un enregistrement de montant PCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'iCESPID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de l''enregistrement 511', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP900', @level2type = N'COLUMN', @level2name = N'iCESP511ID';

