CREATE TABLE [dbo].[Un_CESP800] (
    [iCESP800ID]         INT          IDENTITY (1, 1) NOT NULL,
    [iCESPReceiveFileID] INT          NOT NULL,
    [vcTransID]          VARCHAR (15) NULL,
    [vcErrFieldName]     VARCHAR (30) NOT NULL,
    [siCESP800ErrorID]   SMALLINT     NULL,
    [tyCESP800SINID]     TINYINT      NOT NULL,
    [bFirstName]         BIT          NOT NULL,
    [bLastName]          BIT          NOT NULL,
    [bBirthDate]         BIT          NOT NULL,
    [bSex]               BIT          NOT NULL,
    CONSTRAINT [PK_Un_CESP800] PRIMARY KEY CLUSTERED ([iCESP800ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESP800_Un_CESP800Error__siCESP800ErrorID] FOREIGN KEY ([siCESP800ErrorID]) REFERENCES [dbo].[Un_CESP800Error] ([siCESP800ErrorID]),
    CONSTRAINT [FK_Un_CESP800_Un_CESP800SIN__tyCESP800SINID] FOREIGN KEY ([tyCESP800SINID]) REFERENCES [dbo].[Un_CESP800SIN] ([tyCESP800SINID]),
    CONSTRAINT [FK_Un_CESP800_Un_CESPReceiveFile__iCESPReceiveFileID] FOREIGN KEY ([iCESPReceiveFileID]) REFERENCES [dbo].[Un_CESPReceiveFile] ([iCESPReceiveFileID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP800_iCESPReceiveFileID]
    ON [dbo].[Un_CESP800]([iCESPReceiveFileID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table PCEE dans enregistrement 800 (Erreur)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l''enregistrement 800', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800', @level2type = N'COLUMN', @level2name = N'iCESP800ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du fichier reçu', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800', @level2type = N'COLUMN', @level2name = N'iCESPReceiveFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de transaction unique expédié à la SCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800', @level2type = N'COLUMN', @level2name = N'vcTransID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du champ en erreur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800', @level2type = N'COLUMN', @level2name = N'vcErrFieldName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code d’erreur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800', @level2type = N'COLUMN', @level2name = N'siCESP800ErrorID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Validité du NAS auprès du RAS (0 = Invalide, 1=Valide, etc.)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800', @level2type = N'COLUMN', @level2name = N'tyCESP800SINID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Validité du prénom auprès du RAS (0 = Invalide, 1=Valide)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800', @level2type = N'COLUMN', @level2name = N'bFirstName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Validité du nom auprès du RAS (0 = Invalide, 1=Valide)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800', @level2type = N'COLUMN', @level2name = N'bLastName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Validité de la date de naissance auprès du RAS (0 = Invalide, 1=Valide)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800', @level2type = N'COLUMN', @level2name = N'bBirthDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Validité du sexe auprès du RAS (0 = Invalide, 1=Valide)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP800', @level2type = N'COLUMN', @level2name = N'bSex';

