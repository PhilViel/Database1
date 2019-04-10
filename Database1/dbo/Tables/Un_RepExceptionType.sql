CREATE TABLE [dbo].[Un_RepExceptionType] (
    [RepExceptionTypeID]      [dbo].[MoOptionCode]           NOT NULL,
    [RepExceptionTypeDesc]    [dbo].[MoDesc]                 NOT NULL,
    [RepExceptionTypeTypeID]  [dbo].[UnRepExceptionTypeType] NOT NULL,
    [RepExceptionTypeVisible] [dbo].[MoBitTrue]              NOT NULL,
    CONSTRAINT [PK_Un_RepExceptionType] PRIMARY KEY CLUSTERED ([RepExceptionTypeID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des types d''exceptions sur commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepExceptionType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de 3 caractères identifiant le type de l''exception.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepExceptionType', @level2type = N'COLUMN', @level2name = N'RepExceptionTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description du type d''exception.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepExceptionType', @level2type = N'COLUMN', @level2name = N'RepExceptionTypeDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne de 3 caractères décrivant sur quoi s''applique ce type d''exception. (''COM''= Commission de service, ''ADV''=Avances, ''CAD''=Avances couvertes, ''ISB''=Boni d''assurance souscripteur, ''IB5''=Boni d''assurance bénéficiaire avec indemnité 5 000$, ''IB1''=Boni d''assurance bénéficiaire avec indemnité 10 000$, ''IB2''=Boni d''assurance bénéficiaire avec indemnité 20 000$).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepExceptionType', @level2type = N'COLUMN', @level2name = N'RepExceptionTypeTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si le type d''exception est visible pour l''usager (=0:Pas visible, <>0:Visible).  C''est une protection pour que les types gérés automatiquement ne soient pas modifiés.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepExceptionType', @level2type = N'COLUMN', @level2name = N'RepExceptionTypeVisible';

