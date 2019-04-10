CREATE TABLE [dbo].[Un_Scholarship_Archive_Projet_Critere] (
    [ScholarshipID]       [dbo].[MoID]                IDENTITY (1, 1) NOT NULL,
    [ConventionID]        [dbo].[MoID]                NOT NULL,
    [ScholarshipNo]       [dbo].[MoOrder]             NOT NULL,
    [ScholarshipStatusID] [dbo].[UnScholarshipStatus] NOT NULL,
    [ScholarshipAmount]   [dbo].[MoMoney]             NOT NULL,
    [YearDeleted]         [dbo].[MoID]                NOT NULL,
    [iIDBeneficiaire]     INT                         NULL
);

