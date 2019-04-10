CREATE TABLE [dbo].[tblTEMP_RapportStats_S120_EvolutionDesSouscripteursEpargnants] (
    [Du]                               DATE          NULL,
    [Au]                               DATE          NULL,
    [RegimeSelectionne]                VARCHAR (100) NULL,
    [Regime]                           VARCHAR (50)  NOT NULL,
    [SubscriberID]                     INT           NOT NULL,
    [SubscriberPrenom]                 VARCHAR (35)  NULL,
    [SubscriberNom]                    VARCHAR (50)  NULL,
    [EstSouscripteurEpargnantDebut]    INT           NULL,
    [NbPlansActifsDebut]               INT           NULL,
    [NbPlansAvantEcheanceDebut]        INT           NULL,
    [NbPlansApresEcheanceDebut]        INT           NULL,
    [NbPlansActifsDepuisDebut]         INT           NULL,
    [NbPlansResOUTCompleteDepuisDebut] INT           NULL,
    [NbPlansFermeAutreDepuisDebut]     INT           NULL,
    [NbPlansRinCompletDepuisDebut]     INT           NULL,
    [EstSouscripteurEpargnantFin]      INT           NULL,
    [NbPlansActifsFin]                 INT           NULL,
    [NbPlansAvantEcheanceFin]          INT           NULL,
    [NbPlansApresEcheanceFin]          INT           NULL
);

