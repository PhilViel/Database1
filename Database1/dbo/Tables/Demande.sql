CREATE TABLE [dbo].[Demande] (
    [Id]                       INT           IDENTITY (1, 1) NOT NULL,
    [IdPreDemande]             INT           NOT NULL,
    [NumeroSequencePreDemande] INT           NOT NULL,
    [IdAgent]                  VARCHAR (MAX) NULL,
    [Etat]                     INT           NOT NULL,
    [Type]                     INT           NOT NULL,
    [DateCreation]             DATETIME      NULL,
    [DateAssignation]          DATETIME      NULL,
    [DateTraitee]              DATETIME      NULL,
    [vcLogin_Creation]         VARCHAR (50)  NULL,
    CONSTRAINT [PK_Demande] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Demande_PreDemande__IdPreDemande] FOREIGN KEY ([IdPreDemande]) REFERENCES [dbo].[PreDemande] ([Id])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de demande (0 = PAE, 1 = RIN, 2 = ARI, 3 = DND, 4 = DDD, 5 = PRA, 6 = Ajout de cotisation Portail)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Demande', @level2type = N'COLUMN', @level2name = N'Type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de l''utilisateur ayant créé la demande manuellement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Demande', @level2type = N'COLUMN', @level2name = N'vcLogin_Creation';

