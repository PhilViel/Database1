CREATE TABLE [dbo].[tblGENE_AdresseHistorique] (
    [iID_Adresse]          [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [iID_Source]           [dbo].[MoID]         NOT NULL,
    [cType_Source]         CHAR (1)             CONSTRAINT [DF_GENE_AdresseHistorique_cTypeSource] DEFAULT ('H') NOT NULL,
    [iID_Type]             INT                  NOT NULL,
    [dtDate_Debut]         DATE                 NOT NULL,
    [dtDate_Fin]           DATE                 NULL,
    [bInvalide]            BIT                  CONSTRAINT [DF_GENE_AdresseHistorique_bInvalide] DEFAULT ((0)) NOT NULL,
    [dtDate_Creation]      DATETIME             NOT NULL,
    [vcLogin_Creation]     VARCHAR (50)         NULL,
    [vcNumero_Civique]     VARCHAR (10)         NULL,
    [vcNom_Rue]            VARCHAR (75)         NULL,
    [vcUnite]              VARCHAR (10)         NULL,
    [vcCodePostal]         [dbo].[MoZipCode]    NULL,
    [vcBoite]              VARCHAR (50)         NULL,
    [iID_TypeBoite]        INT                  CONSTRAINT [DF_GENE_AdresseHistorique_iIDTypeBoite] DEFAULT ((0)) NOT NULL,
    [iID_Ville]            INT                  NULL,
    [vcVille]              [dbo].[MoCity]       NULL,
    [iID_Province]         INT                  NULL,
    [vcProvince]           [dbo].[MoDescoption] NULL,
    [cID_Pays]             CHAR (4)             NULL,
    [vcPays]               VARCHAR (75)         NULL,
    [bNouveau_Format]      BIT                  CONSTRAINT [DF_GENE_AdresseHistorique_bNouveauFormat] DEFAULT ((0)) NOT NULL,
    [bResidenceFaitQuebec] BIT                  CONSTRAINT [DF_GENE_AdresseHistorique_bResidenceFaitQuebec] DEFAULT ((0)) NOT NULL,
    [bResidenceFaitCanada] BIT                  CONSTRAINT [DF_GENE_AdresseHistorique_bResidenceFaitCanada] DEFAULT ((0)) NOT NULL,
    [vcInternationale1]    VARCHAR (175)        NULL,
    [vcInternationale2]    VARCHAR (175)        NULL,
    [vcInternationale3]    VARCHAR (175)        NULL,
    CONSTRAINT [PK_GENE_AdresseHistorique] PRIMARY KEY CLUSTERED ([iID_Adresse] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_GENE_AdresseHistorique_Mo_City__iIDVille] FOREIGN KEY ([iID_Ville]) REFERENCES [dbo].[Mo_City] ([CityID]),
    CONSTRAINT [FK_GENE_AdresseHistorique_Mo_Country__cIDPays] FOREIGN KEY ([cID_Pays]) REFERENCES [dbo].[Mo_Country] ([CountryID]),
    CONSTRAINT [FK_GENE_AdresseHistorique_Mo_State__iIDProvince] FOREIGN KEY ([iID_Province]) REFERENCES [dbo].[Mo_State] ([StateID])
);


GO
CREATE NONCLUSTERED INDEX [IX_GENE_AdresseHistorique_iIDSource_cType_Source_iID_Type_dtDateDebut]
    ON [dbo].[tblGENE_AdresseHistorique]([iID_Source] ASC, [cType_Source] ASC, [iID_Type] ASC, [dtDate_Debut] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Cette table contient les adresses courantes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique de l''adresse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'iID_Adresse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique de l''objet auquel appartient l''adresse. Si cType_Source = ''C'' c''est le Mo_Company.CompanyID, si cType_Source = ''H'' c''est le Mo_Human.HumanID.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'iID_Source';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type d''objet auquel appartient l''adresse (''C''=Adresse de compagnie, ''H''=Adresse d''individu).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'cType_Source';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type d''adresse (1 = Résidentielle, 2= Livraison, 4 = Affaire).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'iID_Type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date d''entré en vigueur de l''adresse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'dtDate_Debut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de fin de l''utilisation de l''adresse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'dtDate_Fin';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si l''adresse est invalide.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'bInvalide';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure à laquelle l''adresse fut insérée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'dtDate_Creation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Login de l''utilisateur ayant créé cette adresse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'vcLogin_Creation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro civique de l''adresse postale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'vcNumero_Civique';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom de rue de l''adresse postale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'vcNom_Rue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Unité de l''adresse postale (Numéro d''appartement, de bureau, de local, etc.)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'vcUnite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code postal.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'vcCodePostal';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de boîte postal (Casier, Route rurale, etc.).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'vcBoite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de boîte (1 = Casier postal, 2 = Route rurale).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'iID_TypeBoite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de la ville.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'iID_Ville';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom de la ville.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'vcVille';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de la province.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'iID_Province';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom de la province.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'vcProvince';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du pays. (3 lettres)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'cID_Pays';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du pays.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'vcPays';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si l''adresse est enregistré selon le nouveau format (No, rue et appartement séparés).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'bNouveau_Format';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si la citoyenneté québecoise est conservée même si l''adresse est hors Québec.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'bResidenceFaitQuebec';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si la citoyenneté canadienne est conservée même si l''adresse est hors Canada.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'bResidenceFaitCanada';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne 1 de l''adresse internationale', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'vcInternationale1';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne 2 de l''adresse internationale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'vcInternationale2';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne 3 de l''adresse internationale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_AdresseHistorique', @level2type = N'COLUMN', @level2name = N'vcInternationale3';

