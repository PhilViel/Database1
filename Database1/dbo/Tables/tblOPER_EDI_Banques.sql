CREATE TABLE [dbo].[tblOPER_EDI_Banques] (
    [tiID_EDI_Banque]     TINYINT       IDENTITY (1, 1) NOT NULL,
    [vcCode_Banque]       VARCHAR (3)   NOT NULL,
    [vcDescription_Court] VARCHAR (35)  NOT NULL,
    [vcDescription_Long]  VARCHAR (100) NULL,
    CONSTRAINT [PK_OPER_EDI_Banques] PRIMARY KEY CLUSTERED ([tiID_EDI_Banque] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table de référence contenant les descriptions des institutions financières', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_Banques';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une banque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_Banques', @level2type = N'COLUMN', @level2name = N'tiID_EDI_Banque';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique de la banque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_Banques', @level2type = N'COLUMN', @level2name = N'vcCode_Banque';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description courte de la banque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_Banques', @level2type = N'COLUMN', @level2name = N'vcDescription_Court';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description longue de la banque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_EDI_Banques', @level2type = N'COLUMN', @level2name = N'vcDescription_Long';

