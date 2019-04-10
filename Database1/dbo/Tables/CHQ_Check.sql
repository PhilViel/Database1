CREATE TABLE [dbo].[CHQ_Check] (
    [iCheckID]            INT             IDENTITY (1, 1) NOT NULL,
    [iCheckNumber]        INT             NULL,
    [iCheckStatusID]      INT             NOT NULL,
    [iLangID]             INT             NULL,
    [iPayeeID]            INT             NULL,
    [iTemplateID]         INT             NULL,
    [dtEmission]          DATETIME        NOT NULL,
    [fAmount]             DECIMAL (18, 2) NOT NULL,
    [vcFirstName]         VARCHAR (35)    NULL,
    [vcLastName]          VARCHAR (50)    NULL,
    [vcAddress]           VARCHAR (75)    NULL,
    [vcCity]              VARCHAR (100)   NULL,
    [vcStateName]         VARCHAR (75)    NULL,
    [vcCountry]           CHAR (4)        NULL,
    [vcZipCode]           VARCHAR (10)    NULL,
    [bCheckStubDetailled] BIT             CONSTRAINT [DF_CHQ_Check_bCheckStubDetailled] DEFAULT (0) NOT NULL,
    [iCheckStubDtlLines]  INT             NULL,
    [iID_Regime]          INT             NULL,
    CONSTRAINT [PK_CHQ_Check] PRIMARY KEY CLUSTERED ([iCheckID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CHQ_Check_CHQ_CheckStatus__iCheckStatusID] FOREIGN KEY ([iCheckStatusID]) REFERENCES [dbo].[CHQ_CheckStatus] ([iCheckStatusID]),
    CONSTRAINT [FK_CHQ_Check_CHQ_Payee__iPayeeID] FOREIGN KEY ([iPayeeID]) REFERENCES [dbo].[CHQ_Payee] ([iPayeeID]),
    CONSTRAINT [FK_CHQ_Check_CHQ_Template__iTemplateID] FOREIGN KEY ([iTemplateID]) REFERENCES [dbo].[CHQ_Template] ([iTemplateID])
);


GO
CREATE NONCLUSTERED INDEX [IX_CHQ_Check_iPayeeID]
    ON [dbo].[CHQ_Check]([iPayeeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CHQ_Check_iCheckNumber]
    ON [dbo].[CHQ_Check]([iCheckNumber] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CHQ_Check_vcLastName_vcFirstName_iCheckStatusID_iCheckNumber]
    ON [dbo].[CHQ_Check]([vcLastName] ASC, [vcFirstName] ASC, [iCheckStatusID] ASC, [iCheckNumber] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La table des chèques', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'iCheckID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro tel qu''imprimé sur le chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'iCheckNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Statut de chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'iCheckStatusID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Language du destinataire du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'iLangID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du destinataire du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'iPayeeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du template du chèque à l''impression', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'iTemplateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date d''émission du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'dtEmission';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Le montant du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'fAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Prénom du destinataire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'vcFirstName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du destinataire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'vcLastName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Adresse du destinataire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'vcAddress';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La ville du destinataire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'vcCity';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'État ou province du destinataire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'vcStateName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Pays du destinataire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'vcCountry';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Zip ou code postale du destinataire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'vcZipCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Indicateur : il indique si le talon du chèque en est un détaillé', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'bCheckStubDetailled';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de ligne dans le talon du chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'iCheckStubDtlLines';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du régime (Un_Plan) duquel provient le chèque.  Il indique d''où provient le numéro de séquence du chèque et contribue à maintenir la connaissance du prochain numéro de chèque à imprimer.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Check', @level2type = N'COLUMN', @level2name = N'iID_Regime';

