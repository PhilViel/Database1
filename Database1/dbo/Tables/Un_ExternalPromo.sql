CREATE TABLE [dbo].[Un_ExternalPromo] (
    [ExternalPromoID] [dbo].[MoID] NOT NULL,
    [bOffre_IQEE]     INT          NULL,
    [vcNEQ]           VARCHAR (10) NULL,
    CONSTRAINT [PK_Un_ExternalPromo] PRIMARY KEY CLUSTERED ([ExternalPromoID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_ExternalPromo_Mo_Company__ExternalPromoID] FOREIGN KEY ([ExternalPromoID]) REFERENCES [dbo].[Mo_Company] ([CompanyID])
);


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: decGENE_Un_ExternalPromo_SuiviModifications
Nom du service		: Suivi des modifications à Un_ExternalPromo
But 				: Suivre les modifications aux enregistrements de la table "Un_ExternalPromo".
Facette				: GENE
Déclenchement		: Après la mise à jour d'un enregistrement de la table

Historique des modifications:
		Date			Programmeur							Description										Référence
		------------	----------------------------------	-----------------------------------------		------------
		2009-09-04		Éric Deshaies						Création du service							
		2010-05-05		Jean-François Gauthier				Correction, car la table @Tinserted reste vide
		2010-10-01		Steve Gouin							Gestion #DisableTrigger
****************************************************************************************************/
CREATE TRIGGER dbo.decGENE_Un_ExternalPromo_SuiviModifications ON dbo.Un_ExternalPromo 
	AFTER INSERT, UPDATE
AS 
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	SET NOCOUNT ON;

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

	------------------------------------------------------------------------------
	-- Suivre les modifications aux enregistrements de la table "Un_ExternalPromo"
	------------------------------------------------------------------------------

	DECLARE @iID_Nouveau_Enregistrement INT,
			@iID_Ancien_Enregistrement INT,
			@NbOfRecord int,
			@i int

	DECLARE @Tinserted TABLE (
		Id INT IDENTITY (1,1),  
		ID_Nouveau_Enregistrement INT, 
		ID_Ancien_Enregistrement INT)

	SELECT @NbOfRecord = COUNT(*) FROM inserted
	
	-- 2010-05-05 : JFG : Ajout afin de remplir la table temporaire
	INSERT INTO @Tinserted
	(
		ID_Nouveau_Enregistrement
		,ID_Ancien_Enregistrement 
	)
	SELECT	
		I.ExternalPromoID, 
		D.ExternalPromoID
	FROM	
		Inserted I
		LEFT OUTER JOIN Deleted D 
			ON D.ExternalPromoID = I.ExternalPromoID

	SET @i = 1

	WHILE @i <= @NbOfRecord
	BEGIN
		SELECT 
			@iID_Nouveau_Enregistrement = ID_Nouveau_Enregistrement, 
			@iID_Ancien_Enregistrement = ID_Ancien_Enregistrement 
		FROM @Tinserted 
		WHERE id = @i

		-- Ajouter la modification dans le suivi des modifications
		EXECUTE psGENE_AjouterSuiviModification 8, @iID_Nouveau_Enregistrement, @iID_Ancien_Enregistrement

		SET @i = @i + 1
	END

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les promoteurs externes.  Cette table est utilisé par les transferts IN/OUT.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalPromo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du promoteur externe qui correspond à une ID unique de compagny (Mo_Company).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalPromo', @level2type = N'COLUMN', @level2name = N'ExternalPromoID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si le promoteur externe offre l''IQÉÉ à ses souscripteurs.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalPromo', @level2type = N'COLUMN', @level2name = N'bOffre_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro d''entreprise du Québec (NEQ) qui identifie soit le fiduciaire ou le mandataire du promoteur externe de façon unique au Québec.  Il est utilisé dans les transactions de transfert entre régimes des fichiers de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalPromo', @level2type = N'COLUMN', @level2name = N'vcNEQ';

