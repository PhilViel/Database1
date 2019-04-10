CREATE TABLE [dbo].[Un_IntReimb] (
    [IntReimbID]       [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [UnitID]           [dbo].[MoID]         NOT NULL,
    [CollegeID]        [dbo].[MoIDoption]   NULL,
    [ProgramID]        [dbo].[MoIDoption]   NULL,
    [IntReimbDate]     [dbo].[MoDateoption] NULL,
    [StudyStart]       [dbo].[MoDateoption] NULL,
    [ProgramYear]      [dbo].[MoID]         NOT NULL,
    [ProgramLength]    [dbo].[MoID]         NOT NULL,
    [CESGRenonciation] [dbo].[MoBitFalse]   NULL,
    [FullRIN]          [dbo].[MoBitTrue]    NULL,
    [FeeRefund]        [dbo].[MoBitFalse]   NULL,
    CONSTRAINT [PK_Un_IntReimb] PRIMARY KEY CLUSTERED ([IntReimbID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_IntReimb_Un_Unit__UnitID] FOREIGN KEY ([UnitID]) REFERENCES [dbo].[Un_Unit] ([UnitID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_IntReimb_UnitID]
    ON [dbo].[Un_IntReimb]([UnitID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les données spécifiques au remboursement intégral.  Par défaut c''est une copie des preuves d''inscription inscrite dans le bénéficiaire, mais l''usager peut les modifier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimb';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du remboursement intégral.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimb', @level2type = N'COLUMN', @level2name = N'IntReimbID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe d''unités (Un_Unit) sur lequel le remboursement intégral a eu lieu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimb', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''établissement d''enseignement (Un_College) ou le bénéficiaire fesait ses études lors du remboursement intégral selon la preuve d''inscription qu''il a fourni.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimb', @level2type = N'COLUMN', @level2name = N'CollegeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du programme d''enseignement (Un_Program) auquel était inscrit le bénéficiaire lors du remboursement intégral selon la preuve d''inscription qu''il a fourni.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimb', @level2type = N'COLUMN', @level2name = N'ProgramID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date du remboursement intégral.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimb', @level2type = N'COLUMN', @level2name = N'IntReimbDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date du début des études selon la preuve d''inscription qu''il a fourni.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimb', @level2type = N'COLUMN', @level2name = N'StudyStart';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Qu''elle année du programme il débute selon la preuve d''inscription qu''il a fourni', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimb', @level2type = N'COLUMN', @level2name = N'ProgramYear';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre d''année que dure le programme selon la preuve d''inscription qu''il a fourni.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimb', @level2type = N'COLUMN', @level2name = N'ProgramLength';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Dit si le remboursement intégral était avec renonciation de la subvention ou non.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimb', @level2type = N'COLUMN', @level2name = N'CESGRenonciation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'DEPRECATED!! Description original: Dit si le remboursement intégral était total ou non.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimb', @level2type = N'COLUMN', @level2name = N'FullRIN';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si les frais ont été remboursés sur un convention individuelle ou non.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimb', @level2type = N'COLUMN', @level2name = N'FeeRefund';

