CREATE TABLE [dbo].[Un_PlanValuesOld] (
    [PlanID]                 INT      NOT NULL,
    [ScholarshipYear]        INT      NOT NULL,
    [ScholarshipNo]          SMALLINT NOT NULL,
    [EligibleUnit]           MONEY    NOT NULL,
    [PlanValue]              MONEY    NOT NULL,
    [UnitValue]              MONEY    NOT NULL,
    [Rest]                   MONEY    NOT NULL,
    [ScholarshipGrantAmount] MONEY    NOT NULL,
    [CollectiveGrantAmount]  MONEY    NOT NULL
);

