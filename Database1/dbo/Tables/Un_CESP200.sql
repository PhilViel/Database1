CREATE TABLE [dbo].[Un_CESP200] (
    [iCESP200ID]           INT           IDENTITY (1, 1) NOT NULL,
    [iCESPSendFileID]      INT           NULL,
    [ConventionID]         INT           NOT NULL,
    [HumanID]              INT           NOT NULL,
    [iCESP800ID]           INT           NULL,
    [tiRelationshipTypeID] TINYINT       NULL,
    [vcTransID]            VARCHAR (15)  NOT NULL,
    [tiType]               TINYINT       NOT NULL,
    [dtTransaction]        DATETIME      NOT NULL,
    [iPlanGovRegNumber]    VARCHAR (10)  NOT NULL,
    [ConventionNo]         VARCHAR (15)  NOT NULL,
    [vcSINorEN]            VARCHAR (75)  NOT NULL,
    [vcFirstName]          VARCHAR (35)  NOT NULL,
    [vcLastName]           VARCHAR (50)  NOT NULL,
    [dtBirthdate]          DATETIME      NULL,
    [cSex]                 CHAR (1)      NULL,
    [vcAddress1]           VARCHAR (75)  NOT NULL,
    [vcAddress2]           VARCHAR (75)  NOT NULL,
    [vcAddress3]           VARCHAR (75)  NOT NULL,
    [vcCity]               VARCHAR (100) NOT NULL,
    [vcStateCode]          CHAR (2)      NULL,
    [CountryID]            CHAR (4)      NOT NULL,
    [vcZipCode]            VARCHAR (10)  NULL,
    [cLang]                CHAR (3)      NOT NULL,
    [vcTutorName]          VARCHAR (86)  NULL,
    [bIsCompany]           BIT           NOT NULL,
    CONSTRAINT [PK_Un_CESP200] PRIMARY KEY CLUSTERED ([iCESP200ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESP200_Mo_Country__CountryID] FOREIGN KEY ([CountryID]) REFERENCES [dbo].[Mo_Country] ([CountryID]),
    CONSTRAINT [FK_Un_CESP200_Mo_Human__HumanID] FOREIGN KEY ([HumanID]) REFERENCES [dbo].[Mo_Human] ([HumanID]),
    CONSTRAINT [FK_Un_CESP200_Un_CESP800__iCESP800ID] FOREIGN KEY ([iCESP800ID]) REFERENCES [dbo].[Un_CESP800] ([iCESP800ID]),
    CONSTRAINT [FK_Un_CESP200_Un_CESPSendFile__iCESPSendFileID] FOREIGN KEY ([iCESPSendFileID]) REFERENCES [dbo].[Un_CESPSendFile] ([iCESPSendFileID]),
    CONSTRAINT [FK_Un_CESP200_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_Un_CESP200_Un_RelationshipType__tiRelationshipTypeID] FOREIGN KEY ([tiRelationshipTypeID]) REFERENCES [dbo].[Un_RelationshipType] ([tiRelationshipTypeID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP200_iCESPSendFileID]
    ON [dbo].[Un_CESP200]([iCESPSendFileID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP200_ConventionID]
    ON [dbo].[Un_CESP200]([ConventionID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP200_HumanID]
    ON [dbo].[Un_CESP200]([HumanID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP200_iCESP800ID]
    ON [dbo].[Un_CESP200]([iCESP800ID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP200_vcTransID]
    ON [dbo].[Un_CESP200]([vcTransID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table PCEE dans enregistrement 200 (Souscripteur et bénéficiaire)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’enregistrement 200', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'iCESP200ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du fichier d’envoi', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'iCESPSendFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’humain', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'HumanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’enregistrement 800 d’erreur s’il y en a un', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'iCESP800ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du lien de parenté en le souscripteur et le bénéficiaire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'tiRelationshipTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de transaction unique expédié à la SCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'vcTransID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type de transaction (3 = bénéficiaire, 4 = souscripteur)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'tiType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de la transaction', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'dtTransaction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro d’enregistrement du régime au gouvernement (ARC)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'iPlanGovRegNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'ConventionNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'NAS du bénéficiaire ou du souscripteur ou NE du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'vcSINorEN';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Prénom', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'vcFirstName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'vcLastName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de naissance', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'dtBirthdate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Sexe (1= Féminin, 2 = Masculin, Espace s’il s’agit d’une entreprise)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'cSex';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Ligne d’adresse 1', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'vcAddress1';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Ligne d’adresse 2', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'vcAddress2';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Ligne d’adresse 3', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'vcAddress3';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Ville', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'vcCity';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code de la province', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'vcStateCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code du pays', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'CountryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code postal', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'vcZipCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Langue (''ENU'' = Anglais, ''FRA'' = Français, etc.)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'cLang';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Prénom + espace + nom du tuteur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'vcTutorName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = '0 = Personne, 1 = Compagnie', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP200', @level2type = N'COLUMN', @level2name = N'bIsCompany';

