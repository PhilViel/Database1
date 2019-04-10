CREATE TABLE [dbo].[tblPCEE_ActionBEC] (
    [iIDActionBEC]    INT           IDENTITY (1, 1) NOT NULL,
    [cCodeActionBEC]  CHAR (6)      NOT NULL,
    [vcDescActionBEC] VARCHAR (255) NOT NULL,
    CONSTRAINT [PK_PCEE_ActionBEC] PRIMARY KEY CLUSTERED ([iIDActionBEC] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les codes des actions du BEC', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblPCEE_ActionBEC';

