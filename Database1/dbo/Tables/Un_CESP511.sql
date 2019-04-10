CREATE TABLE [dbo].[Un_CESP511] (
    [iCESP511ID]         INT               IDENTITY (1, 1) NOT NULL,
    [iCESPSendFileID]    INT               NULL,
    [iCESP800ID]         INT               NULL,
    [iBeneficiaryID]     INT               NOT NULL,
    [ConventionID]       INT               NOT NULL,
    [iOriginalCESP400ID] INT               NOT NULL,
    [vcTransID]          VARCHAR (15)      NOT NULL,
    [dtTransaction]      DATETIME          NOT NULL,
    [iPlanGovRegNumber]  INT               NOT NULL,
    [ConventionNo]       VARCHAR (15)      NOT NULL,
    [vcOriginalTransID]  VARCHAR (15)      NOT NULL,
    [vcPCGSINorEN]       VARCHAR (15)      NOT NULL,
    [vcPCGFirstName]     VARCHAR (35)      NULL,
    [vcPCGLastName]      VARCHAR (50)      NOT NULL,
    [tiPCGType]          [dbo].[UnPCGType] NOT NULL,
    CONSTRAINT [PK_Un_CESP511] PRIMARY KEY CLUSTERED ([iCESP511ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESP511_Un_Beneficiary__iBeneficiaryID] FOREIGN KEY ([iBeneficiaryID]) REFERENCES [dbo].[Un_Beneficiary] ([BeneficiaryID]),
    CONSTRAINT [FK_Un_CESP511_Un_CESP400__iOriginalCESP400ID] FOREIGN KEY ([iOriginalCESP400ID]) REFERENCES [dbo].[Un_CESP400] ([iCESP400ID]),
    CONSTRAINT [FK_Un_CESP511_Un_CESPSendFile__iCESPSendFileID] FOREIGN KEY ([iCESPSendFileID]) REFERENCES [dbo].[Un_CESPSendFile] ([iCESPSendFileID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP511_ConventionID]
    ON [dbo].[Un_CESP511]([ConventionID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP511_iCESPSendFileID]
    ON [dbo].[Un_CESP511]([iCESPSendFileID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP511_iOriginalCESP400ID]
    ON [dbo].[Un_CESP511]([iOriginalCESP400ID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP511_vcTransID]
    ON [dbo].[Un_CESP511]([vcTransID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les données sur les transactions 511', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP511';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de l’enregistrement 511', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP511', @level2type = N'COLUMN', @level2name = N'iCESP511ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du fichier d’envoi', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP511', @level2type = N'COLUMN', @level2name = N'iCESPSendFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du bénéficiaire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP511', @level2type = N'COLUMN', @level2name = N'iBeneficiaryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP511', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de l’enregistrement 400 correspondant à la transaction à modifier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP511', @level2type = N'COLUMN', @level2name = N'iOriginalCESP400ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de transaction unique expédiée à la SCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP511', @level2type = N'COLUMN', @level2name = N'vcTransID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de la transaction', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP511', @level2type = N'COLUMN', @level2name = N'dtTransaction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro d’enregistrement du régime au gouvernement (ARC)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP511', @level2type = N'COLUMN', @level2name = N'iPlanGovRegNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP511', @level2type = N'COLUMN', @level2name = N'ConventionNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de transaction unique expédiée à la SCEE à partir de laquelle la modification doit s''appliquer', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP511', @level2type = N'COLUMN', @level2name = N'vcOriginalTransID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NAS ou NE du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP511', @level2type = N'COLUMN', @level2name = N'vcPCGSINorEN';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Prénom du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP511', @level2type = N'COLUMN', @level2name = N'vcPCGFirstName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP511', @level2type = N'COLUMN', @level2name = N'vcPCGLastName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de principal responsable (1 = Personne avec un NAS, 2 = Compagnie avec un NE).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP511', @level2type = N'COLUMN', @level2name = N'tiPCGType';

