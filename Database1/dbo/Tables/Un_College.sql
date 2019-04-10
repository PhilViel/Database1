CREATE TABLE [dbo].[Un_College] (
    [CollegeID]                                        [dbo].[MoID]                   NOT NULL,
    [CollegeTypeID]                                    [dbo].[UnCollegeType]          NOT NULL,
    [EligibilityConditionID]                           [dbo].[UnEligibilityCondition] NOT NULL,
    [CollegeCode]                                      [dbo].[MoDescoption]           NULL,
    [iSectorID]                                        INT                            NULL,
    [iRegionID]                                        INT                            NULL,
    [cCollegeTypeExceptionInFirstScholarshipStatistic] CHAR (2)                       NULL,
    [tiSpecialInFirstScholarshipStatistic]             TINYINT                        CONSTRAINT [DF_Un_College_tiSpecialInFirstScholarshipStatistic] DEFAULT (0) NULL,
    [bActif]                                           BIT                            CONSTRAINT [DF_Un_College_bActif] DEFAULT ((1)) NULL,
    CONSTRAINT [PK_Un_College] PRIMARY KEY CLUSTERED ([CollegeID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_College_Mo_Company__CollegeID] FOREIGN KEY ([CollegeID]) REFERENCES [dbo].[Mo_Company] ([CompanyID]),
    CONSTRAINT [FK_Un_College_Un_Region__iRegionID] FOREIGN KEY ([iRegionID]) REFERENCES [dbo].[Un_Region] ([iRegionID]),
    CONSTRAINT [FK_Un_College_Un_Sector__iSectorID] FOREIGN KEY ([iSectorID]) REFERENCES [dbo].[Un_Sector] ([iSectorID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les établissements d''enseignements.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_College';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''établissement d''enseignement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_College', @level2type = N'COLUMN', @level2name = N'CollegeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''établissement d''enseignement. (01 = Universitas, 02 = Cégep/Collège communautaire, 03 = Établissement privé, 04 = Autres)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_College', @level2type = N'COLUMN', @level2name = N'CollegeTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Conditions de réussite. (UNK = Inconnu, YEA = Années, CRS = Cours, CDT = Crédits, SES = Sessions, 3MT = Trimestre/Cours)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_College', @level2type = N'COLUMN', @level2name = N'EligibilityConditionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro d''enregistrement du college.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_College', @level2type = N'COLUMN', @level2name = N'CollegeCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du secteur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_College', @level2type = N'COLUMN', @level2name = N'iSectorID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la région', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_College', @level2type = N'COLUMN', @level2name = N'iRegionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Gère les colleges, et établissement privé qui doivent se retrouver dans la section universié du le rapport de statistic de bourse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_College', @level2type = N'COLUMN', @level2name = N'cCollegeTypeExceptionInFirstScholarshipStatistic';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Regroupement spécial dans la section universié du le rapport de statistic de bourse. (0=pas regroupé, 1=VARIA QC, 2=Université du Québec à Montréal (UQAM), 3=Université Ottawa, 4=Université de Moncton )', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_College', @level2type = N'COLUMN', @level2name = N'tiSpecialInFirstScholarshipStatistic';

