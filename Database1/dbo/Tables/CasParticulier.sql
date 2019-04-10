CREATE TABLE [dbo].[CasParticulier] (
    [ID]                   INT           IDENTITY (1, 1) NOT NULL,
    [IDObjetLie]           INT           NOT NULL,
    [IDTypeObjetLie]       INT           NOT NULL,
    [IDTypeCasParticulier] INT           NOT NULL,
    [DateDebut]            DATE          NOT NULL,
    [DateFin]              DATE          NULL,
    [Info]                 VARCHAR (MAX) NULL,
    [DateCreation]         DATETIME      CONSTRAINT [DF_CasParticulier_DateCreation] DEFAULT (getdate()) NOT NULL,
    [LoginName]            VARCHAR (50)  NULL,
    CONSTRAINT [PK_CasParticulier] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);


GO

CREATE TRIGGER [dbo].[CasParticulier_Ins] ON [dbo].[CasParticulier]
	FOR INSERT
AS BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	UPDATE L
	   SET LoginName = dbo.GetUserContext()
	  FROM dbo.CasParticulier L JOIN inserted I ON I.ID = L.ID
	 WHERE L.LoginName IS NULL
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TtblGENE_Adresse
But					: Effectue un SOFT DELETE des enregistrements dans tblCasParticulier lorsqu'on tente de les détruire

Historique des modifications:
		Date				Programmeur				Description										
		------------		-----------------------	-----------------------------------------	
		2015-06-01			Steve Picard			Création du service			

*********************************************************************************************************************/
CREATE TRIGGER dbo.TRG_CasParticulier_Historisation_D ON dbo.CasParticulier FOR DELETE
AS
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	DECLARE @Today date = GetDate()

	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger
	IF object_id('tempdb..#DisableTrigger') is null 
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
	ELSE
	BEGIN
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	END

	--	Bloque le trigger des DELETEs
	INSERT INTO #DisableTrigger VALUES('TRG_CasParticulier_Historisation_I')	

	SET IDENTITY_INSERT dbo.CasParticulier ON

	INSERT INTO dbo.CasParticulier (
            ID, IDObjetLie, IDTypeObjetLie, IDTypeCasParticulier, DateDebut, 
			DateFin, Info, DateCreation, LoginName
		)
	SELECT 	ID, IDObjetLie, IDTypeObjetLie, IDTypeCasParticulier, DateDebut, 
			@Today, Info, DateCreation, LoginName
	FROM	deleted D
	WHERE	DateDebut < @Today and DateFin is null

	SET IDENTITY_INSERT dbo.CasParticulier OFF
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type d''objet lié (0 = Convention, 1 = Souscripteur, 2 = Bénéficiaire)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CasParticulier', @level2type = N'COLUMN', @level2name = N'IDTypeObjetLie';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CasParticulier', @level2type = N'COLUMN', @level2name = N'IDTypeCasParticulier';

