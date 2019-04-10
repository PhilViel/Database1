CREATE TABLE [dbo].[tblCONV_ContributionFinanciereParent] (
    [iIDContributionFinanciereParent] INT         IDENTITY (1, 1) NOT NULL,
    [vcContributionFinanciereParent]  VARCHAR (5) NOT NULL,
    CONSTRAINT [PK_CONV_ContributionFinanciereParent] PRIMARY KEY CLUSTERED ([iIDContributionFinanciereParent] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table des pourcentages de contribution financière des parenets', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ContributionFinanciereParent';

