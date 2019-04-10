CREATE TABLE [dbo].[tblOPER_OperationsRIO] (
    [iID_Operation_RIO]          INT      IDENTITY (1, 1) NOT NULL,
    [dtDate_Enregistrement]      DATETIME NOT NULL,
    [iID_Oper_RIO]               INT      NOT NULL,
    [iID_Convention_Source]      INT      NOT NULL,
    [iID_Unite_Source]           INT      NOT NULL,
    [iID_Convention_Destination] INT      NOT NULL,
    [iID_Unite_Destination]      INT      NOT NULL,
    [bRIO_Annulee]               BIT      NOT NULL,
    [bRIO_QuiAnnule]             BIT      NOT NULL,
    [OperTypeID]                 CHAR (3) CONSTRAINT [DF_OPER_OperationsRIO_OperTypeID] DEFAULT ('RIO') NOT NULL,
    CONSTRAINT [PK_OPER_OperationsRIO] PRIMARY KEY CLUSTERED ([iID_Operation_RIO] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_OPER_OperationsRIO_Un_Oper__iIDOperRIO] FOREIGN KEY ([iID_Oper_RIO]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
CREATE NONCLUSTERED INDEX [IX_OPER_OperationsRIO_iIDConventionDestination]
    ON [dbo].[tblOPER_OperationsRIO]([iID_Convention_Destination] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_OPER_OperationsRIO_iIDConventionSource]
    ON [dbo].[tblOPER_OperationsRIO]([iID_Convention_Source] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_OPER_OperationsRIO_iIDOperRIO]
    ON [dbo].[tblOPER_OperationsRIO]([iID_Oper_RIO] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_OPER_OperationsRIO_iIDUniteDestination]
    ON [dbo].[tblOPER_OperationsRIO]([iID_Unite_Destination] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_OPER_OperationsRIO_iIDUniteSource]
    ON [dbo].[tblOPER_OperationsRIO]([iID_Unite_Source] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index par convention individuelle de destination du transfert RIO.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'INDEX', @level2name = N'IX_OPER_OperationsRIO_iIDConventionDestination';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index par convention Universitas source du transfert RIO.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'INDEX', @level2name = N'IX_OPER_OperationsRIO_iIDConventionSource';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index par identifiant unique de l''opération RIO (Un_Oper).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'INDEX', @level2name = N'IX_OPER_OperationsRIO_iIDOperRIO';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index par unité de la convention individuelle de destination du transfert RIO.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'INDEX', @level2name = N'IX_OPER_OperationsRIO_iIDUniteDestination';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index par unité de convention Universitas source du transfert RIO.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'INDEX', @level2name = N'IX_OPER_OperationsRIO_iIDUniteSource';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de la clé primaire des opérations RIO.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'CONSTRAINT', @level2name = N'PK_OPER_OperationsRIO';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Informations supplémentaires pour chaque opération de type RIO.  Il y a une opération RIO pour chaque groupe d''unités Universitas transféré à un régime individuel.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du détail d''une opération RIO.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'COLUMN', @level2name = N'iID_Operation_RIO';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date du jour de l''enregistrement de l''opération RIO.  Sera souvent différent de la date de l''opération RIO qui sera pré daté à la date de la période de traitement des rembousements intégraux.  La date sera la même si l''opération est faite après la date de la période des RI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'COLUMN', @level2name = N'dtDate_Enregistrement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''opération RIO (Un_Oper).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'COLUMN', @level2name = N'iID_Oper_RIO';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la convention Universitas source de l''opération RIO (Un_Convention).  Dans le cas d''une opération RIO d''annulation, la destination et la source sont inversées par rapport à une opération RIO.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'COLUMN', @level2name = N'iID_Convention_Source';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''unité de la convention Universitas source de l''opération RIO (Un_Unit).  Dans le cas d''une opération RIO d''annulation, la destination et la source sont inversées par rapport à une opération RIO.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'COLUMN', @level2name = N'iID_Unite_Source';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la convention individuelle de destination de l''opération RIO (Un_Convention).  Dans le cas d''une opération RIO d''annulation, la destination et la source sont inversées par rapport à une opération RIO.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'COLUMN', @level2name = N'iID_Convention_Destination';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''unité de la convention individuelle de destination de l''opération RIO (Un_Unit).  S''il y a plusieurs conventions ou groupes d''unités Universitas, ils seront transférés dans un seul groupe d''unités de la convention individuelle.  Dans le cas d''une opération RIO d''annulation, la destination et la source sont inversées par rapport à une opération RIO.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'COLUMN', @level2name = N'iID_Unite_Destination';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur pour savoir si l''opération RIO a été annulée (0=Opération en vigueur, 1=Opération annulée).  L''opération RIO qui annule l''opération RIO en cours est présente dans la table "Un_OperCancelation".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'COLUMN', @level2name = N'bRIO_Annulee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur pour savoir si l''opération RIO en cours annule une autre opération RIO (0=Opération RIO, 1=Opération qui annule une autre RIO).  L''opération RIO qui est annulée est présente dans la table "Un_OperCancelation".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'COLUMN', @level2name = N'bRIO_QuiAnnule';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type d''opération relié à l''opération de conversion de régime', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsRIO', @level2type = N'COLUMN', @level2name = N'OperTypeID';

