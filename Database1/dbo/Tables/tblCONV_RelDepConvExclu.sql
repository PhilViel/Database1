CREATE TABLE [dbo].[tblCONV_RelDepConvExclu] (
    [SubscriberId] INT          NOT NULL,
    [ConventionId] INT          NOT NULL,
    [Raison]       VARCHAR (50) NULL,
    CONSTRAINT [PK_CONV_RelDepConvExclu] PRIMARY KEY CLUSTERED ([SubscriberId] ASC, [ConventionId] ASC) WITH (FILLFACTOR = 90)
);

