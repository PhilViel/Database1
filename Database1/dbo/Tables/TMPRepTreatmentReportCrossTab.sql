CREATE TABLE [dbo].[TMPRepTreatmentReportCrossTab] (
    [KindOfAmount]  VARCHAR (30)         NULL,
    [RepID]         [dbo].[MoID]         NOT NULL,
    [RepCode]       [dbo].[MoDescoption] NULL,
    [RepName]       [dbo].[MoDesc]       NULL,
    [BusinessStart] [dbo].[MoDateoption] NULL,
    [BusinessEnd]   [dbo].[MoDateoption] NULL,
    [TotalAmount]   [dbo].[MoMoney]      NOT NULL,
    [20071231]      [dbo].[MoMoney]      NOT NULL,
    [20080105]      [dbo].[MoMoney]      NOT NULL,
    [20080112]      [dbo].[MoMoney]      NOT NULL,
    [20080119]      [dbo].[MoMoney]      NOT NULL,
    [20080126]      [dbo].[MoMoney]      NOT NULL,
    [20080202]      [dbo].[MoMoney]      NOT NULL,
    [20080209]      [dbo].[MoMoney]      NOT NULL,
    [20080216]      [dbo].[MoMoney]      NOT NULL,
    [20080223]      [dbo].[MoMoney]      NOT NULL,
    [20080301]      [dbo].[MoMoney]      NOT NULL,
    [20080308]      [dbo].[MoMoney]      NOT NULL,
    [20080315]      [dbo].[MoMoney]      NOT NULL,
    [20080322]      [dbo].[MoMoney]      NOT NULL,
    [20080329]      [dbo].[MoMoney]      NOT NULL,
    [20080405]      [dbo].[MoMoney]      NOT NULL,
    [20080412]      [dbo].[MoMoney]      NOT NULL,
    [20080419]      [dbo].[MoMoney]      NOT NULL,
    [20080426]      [dbo].[MoMoney]      NOT NULL,
    [20080503]      [dbo].[MoMoney]      NOT NULL,
    [20080510]      [dbo].[MoMoney]      NOT NULL,
    [20080517]      [dbo].[MoMoney]      NOT NULL,
    [20080524]      [dbo].[MoMoney]      NOT NULL,
    [20080531]      [dbo].[MoMoney]      NOT NULL,
    [20080607]      [dbo].[MoMoney]      NOT NULL,
    [20080614]      [dbo].[MoMoney]      NOT NULL,
    [20080621]      [dbo].[MoMoney]      NOT NULL,
    [20080628]      [dbo].[MoMoney]      NOT NULL,
    [20080705]      [dbo].[MoMoney]      NOT NULL,
    [20080712]      [dbo].[MoMoney]      NOT NULL,
    [20080719]      [dbo].[MoMoney]      NOT NULL,
    [20080726]      [dbo].[MoMoney]      NOT NULL,
    [20080802]      [dbo].[MoMoney]      NOT NULL,
    [20080809]      [dbo].[MoMoney]      NOT NULL,
    [20080816]      [dbo].[MoMoney]      NOT NULL,
    [20080823]      [dbo].[MoMoney]      NOT NULL,
    [20080830]      [dbo].[MoMoney]      NOT NULL,
    [20080906]      [dbo].[MoMoney]      NOT NULL,
    [20080913]      [dbo].[MoMoney]      NOT NULL,
    [20080920]      [dbo].[MoMoney]      NOT NULL,
    [20080927]      [dbo].[MoMoney]      NOT NULL,
    [20081004]      [dbo].[MoMoney]      NOT NULL,
    [20081011]      [dbo].[MoMoney]      NOT NULL,
    [20081018]      [dbo].[MoMoney]      NOT NULL,
    [20081025]      [dbo].[MoMoney]      NOT NULL,
    [20081101]      [dbo].[MoMoney]      NOT NULL,
    [20081108]      [dbo].[MoMoney]      NOT NULL,
    [20081115]      [dbo].[MoMoney]      NOT NULL,
    [20081122]      [dbo].[MoMoney]      NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_TMPRepTreatmentReportCrossTab_KindOfAmount]
    ON [dbo].[TMPRepTreatmentReportCrossTab]([KindOfAmount] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_TMPRepTreatmentReportCrossTab_RepID]
    ON [dbo].[TMPRepTreatmentReportCrossTab]([RepID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table de travail pour les rapports de traitement croisé dynamique', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'TMPRepTreatmentReportCrossTab';

