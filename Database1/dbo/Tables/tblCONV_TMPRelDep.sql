CREATE TABLE [dbo].[tblCONV_TMPRelDep] (
    [iID]                               INT           IDENTITY (1, 1) NOT NULL,
    [ConventionID]                      INT           NULL,
    [SubscriberID]                      INT           NULL,
    [BeneficiaryID]                     INT           NULL,
    [ConventionNo]                      VARCHAR (20)  NULL,
    [PlanDesc]                          VARCHAR (75)  NULL,
    [PlantypeID]                        CHAR (3)      NULL,
    [TextDiploma]                       VARCHAR (150) NULL,
    [Processed]                         INT           NULL,
    [dtDtHr]                            DATETIME      NULL,
    [bSouscripteur_Desire_Releve_Elect] BIT           NULL,
    CONSTRAINT [PK_CONV_TMPRelDep] PRIMARY KEY CLUSTERED ([iID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table de travail servant à la génération des relevés de dépôt', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_TMPRelDep';

