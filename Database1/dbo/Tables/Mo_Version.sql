CREATE TABLE [dbo].[Mo_Version] (
    [VersionID]          [dbo].[MoID]       IDENTITY (1, 1) NOT NULL,
    [ApplicationVersion] [dbo].[MoIDoption] NULL,
    [ModulexVersion]     [dbo].[MoIDoption] NULL,
    [PatchVersion]       [dbo].[MoIDoption] NULL,
    [VersionTypeID]      [dbo].[MoInitial]  NULL,
    [VersionDate]        [dbo].[MoDate]     NOT NULL,
    [EffectDate]         [dbo].[MoGetDate]  NOT NULL,
    CONSTRAINT [PK_Mo_Version] PRIMARY KEY CLUSTERED ([VersionID] ASC) WITH (FILLFACTOR = 90)
);


GO

CREATE TRIGGER [dbo].[TMo_Version] ON [dbo].[Mo_Version] FOR INSERT
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
	
  DECLARE
    @ModulexVersion        Int,
    @ApplicationVersion    Int,
    @PatchVersion          int,
    @VersionTypeID         VARCHAR(4),
    @VersionDate           DateTime;

  SELECT
    @ModulexVersion        = ModulexVersion,
    @ApplicationVersion    = ApplicationVersion,
    @PatchVersion          = PatchVersion,
    @VersionTypeID         = VersionTypeID,
    @VersionDate           = VersionDate
  FROM inserted

  IF ((@ApplicationVersion IS NOT NULL) AND (@ApplicationVersion <> 0))
  BEGIN
    IF EXISTS (SELECT *
               FROM Mo_Def
               WHERE (ApplicationVersion < @ApplicationVersion) )
      UPDATE Mo_Def SET
        ApplicationVersion = @ApplicationVersion,
        PatchVersion = @PatchVersion,
        VersionDate = @VersionDate;
  END
  ELSE
    IF (@ModulexVersion IS NOT NULL) AND (@ModulexVersion <> 0)
    BEGIN
      IF EXISTS (SELECT *
                 FROM Mo_Def
                 WHERE (ModulexVersion < @ModulexVersion) )
        UPDATE Mo_Def SET
          ModulexVersion = @ModulexVersion,
          PatchVersion = @PatchVersion,
          VersionDate = @VersionDate;
    END

  /* Pour le ou les patch des versions */
  IF EXISTS (SELECT *
             FROM Mo_Def
             WHERE (PatchVersion < @PatchVersion) )
    UPDATE Mo_Def SET
      PatchVersion = @PatchVersion,
      VersionDate = @VersionDate;
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des versions.  À chaque livraison de version on inscrit un enregistrement dans cette table.  Elle nous permet de s''assurer que la version de l''application qui ce connecte est la bonne pour la base de données.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Version';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la version.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Version', @level2type = N'COLUMN', @level2name = N'VersionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Version de UniSQL.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Version', @level2type = N'COLUMN', @level2name = N'ApplicationVersion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Version du module Modulex.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Version', @level2type = N'COLUMN', @level2name = N'ModulexVersion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de compilation de la version.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Version', @level2type = N'COLUMN', @level2name = N'PatchVersion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type de version (''Mo''=Modulex, ''Un''=UniSQL).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Version', @level2type = N'COLUMN', @level2name = N'VersionTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''implantation de la version dans la base de données.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Version', @level2type = N'COLUMN', @level2name = N'VersionDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Inutile - Date d''entrée en vigueur de la version.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Version', @level2type = N'COLUMN', @level2name = N'EffectDate';

