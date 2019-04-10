CREATE TABLE [dbo].[tblGENE_MessagesTraductions] (
    [iIdMessagesTraductions]           INT           IDENTITY (1, 1) NOT NULL,
    [iIdMessages]                      INT           NULL,
    [LangId]                           CHAR (3)      NULL,
    [vcTitreMessagesTraductions]       VARCHAR (MAX) NULL,
    [vcDescriptionMessagesTraductions] VARCHAR (MAX) NULL,
    [vcInstructionMessagesTraductions] VARCHAR (MAX) NULL,
    CONSTRAINT [PK_GENE_MessagesTraductions] PRIMARY KEY CLUSTERED ([iIdMessagesTraductions] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_GENE_MessagesTraductions_Mo_Lang__LangId] FOREIGN KEY ([LangId]) REFERENCES [dbo].[Mo_Lang] ([LangID])
);

