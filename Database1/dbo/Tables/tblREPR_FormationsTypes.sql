CREATE TABLE [dbo].[tblREPR_FormationsTypes] (
    [iID_TypeFormation]    INT           IDENTITY (1, 1) NOT NULL,
    [vcType_Formation]     VARCHAR (25)  NOT NULL,
    [vcDescription]        VARCHAR (250) NULL,
    [iCatagorie_Formation] INT           NOT NULL,
    CONSTRAINT [PK_REPR_FormationsTypes] PRIMARY KEY CLUSTERED ([iID_TypeFormation] ASC) WITH (FILLFACTOR = 90)
);

