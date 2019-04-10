CREATE TABLE [dbo].[tblTEMP_SuiviRepUnit] (
    [UnitID_Ori]       INT        NULL,
    [UnitID]           INT        NULL,
    [RepID]            INT        NULL,
    [Recrue]           INT        NULL,
    [BossID]           INT        NULL,
    [RepTreatmentID]   INT        NULL,
    [RepTreatmentDate] DATETIME   NULL,
    [Brut]             FLOAT (53) NULL,
    [Retraits]         FLOAT (53) NULL,
    [Reinscriptions]   FLOAT (53) NULL,
    [Brut24]           FLOAT (53) NULL,
    [Retraits24]       FLOAT (53) NULL,
    [Reinscriptions24] FLOAT (53) NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table temporaire utilisé pour le rapport statistique des ventes et taux de conservation des 12 dernier mois (GU_RP_SuiviRep)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblTEMP_SuiviRepUnit';

