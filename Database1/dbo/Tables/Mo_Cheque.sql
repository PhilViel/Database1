CREATE TABLE [dbo].[Mo_Cheque] (
    [ChequeID]                    [dbo].[MoID]             IDENTITY (1, 1) NOT NULL,
    [FirmID]                      [dbo].[MoID]             NOT NULL,
    [ChequeOrderID]               [dbo].[MoIDoption]       NULL,
    [ChequeTypeID]                [dbo].[MoOptionCode]     NOT NULL,
    [ChequeTableName]             [dbo].[MoDesc]           NOT NULL,
    [ChequeCodeID]                [dbo].[MoID]             NOT NULL,
    [ChequeDate]                  [dbo].[MoDateoption]     NULL,
    [ChequeName]                  [dbo].[MoCompanyName]    NOT NULL,
    [ChequeAmount]                [dbo].[MoMoney]          NOT NULL,
    [ChequeDesc]                  [dbo].[MoLongDescoption] NULL,
    [ChequeText]                  [dbo].[MoTextoption]     NULL,
    [LangID]                      [dbo].[MoLang]           NOT NULL,
    [SexID]                       [dbo].[MoSex]            NOT NULL,
    [Address]                     [dbo].[MoAdress]         NULL,
    [City]                        [dbo].[MoCity]           NULL,
    [StateName]                   [dbo].[MoDescoption]     NULL,
    [CountryID]                   [dbo].[MoCountry]        NULL,
    [ZipCode]                     [dbo].[MoZipCode]        NULL,
    [ChequeCancellationConnectID] [dbo].[MoIDoption]       NULL,
    CONSTRAINT [PK_Mo_Cheque] PRIMARY KEY CLUSTERED ([ChequeID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_Cheque_Mo_ChequeOrder__ChequeOrderID] FOREIGN KEY ([ChequeOrderID]) REFERENCES [dbo].[Mo_ChequeOrder] ([ChequeOrderID]),
    CONSTRAINT [FK_Mo_Cheque_Mo_ChequeType__ChequeTypeID] FOREIGN KEY ([ChequeTypeID]) REFERENCES [dbo].[Mo_ChequeType] ([ChequeTypeID]),
    CONSTRAINT [FK_Mo_Cheque_Mo_Firm__FirmID] FOREIGN KEY ([FirmID]) REFERENCES [dbo].[Mo_Firm] ([FirmID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Cheque_ChequeTableName]
    ON [dbo].[Mo_Cheque]([ChequeTableName] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Cheque_ChequeCodeID]
    ON [dbo].[Mo_Cheque]([ChequeCodeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Cheque_ChequeDate]
    ON [dbo].[Mo_Cheque]([ChequeDate] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Cheque_ChequeOrderID]
    ON [dbo].[Mo_Cheque]([ChequeOrderID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Cheque_ChequeTypeID]
    ON [dbo].[Mo_Cheque]([ChequeTypeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Cheque_FirmID]
    ON [dbo].[Mo_Cheque]([FirmID] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[TMo_Cheque] ON [dbo].[Mo_Cheque] FOR INSERT, UPDATE
AS
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
  	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

	-- Si la table #DisableTrigger est présente, il se pourrait que le trigger
	-- ne soit pas à exécuter
	IF object_id('tempdb..#DisableTrigger') is not null 
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	-- *** FIN AVERTISSEMENT *** 
	
  UPDATE Mo_Cheque SET
    ChequeDate = dbo.fn_Mo_DateNoTime( i.ChequeDate),
    ChequeAmount = ROUND(ISNULL(i.ChequeAmount, 0), 2)
  FROM Mo_Cheque M, inserted i
  WHERE M.ChequeID = i.ChequeID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_Cheque] TO PUBLIC
    AS [dbo];


GO
GRANT UPDATE
    ON [dbo].[Mo_Cheque] ([ChequeText]) TO PUBLIC
    AS [dbo];


GO
GRANT UPDATE
    ON [dbo].[Mo_Cheque] ([SexID]) TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des chèques.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'ChequeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la firme (Mo_Firm) à laquel appartient le chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'FirmID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la liasse de chèques (Mo_ChequeOrder) à laquel appartient le chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'ChequeOrderID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type de chèque (Mo_ChequeType).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'ChequeTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de l''objet auquel le chèque est lié. (Ex:Un_Oper, Un_Convention, etc.)  Avec le champ ChequeCodeID, on peut faire un lien unique avec l''objet lié au chèque.  Dans le cas de Gestion Universitas, on ce sert de ces champs pour faire le lien avec l''opération qui a créé le chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'ChequeTableName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''objet auquel le chèque est lié.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'ChequeCodeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date du chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'ChequeDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du destinataire du chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'ChequeName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant du chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'ChequeAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Notes du chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'ChequeDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne de 3 caractères désignant la langue (Mo_Lang) du destinataire du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'LangID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = '1 caractère désignant le sexe (Mo_Sex) du destinataire du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'SexID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro civique, rue et numéro d''appartement ou le chèque a été, est ou sera posté s''il y a lieu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'Address';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Ville de l''adresse ou le chèque a été, est ou sera posté s''il y a lieu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'City';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Province de l''adresse ou le chèque a été, est ou sera posté s''il y a lieu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'StateName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de 3 caractères du pays (Mo_Country) de l''adresse ou le chèque a été, est ou sera posté s''il y a lieu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'CountryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code postal de l''adresse ou le chèque a été, est ou sera posté s''il y a lieu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'ZipCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion (Mo_Connect) de l''usager qui a annulé le chèque.  Null = le chèque n''est pas annulé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Cheque', @level2type = N'COLUMN', @level2name = N'ChequeCancellationConnectID';

