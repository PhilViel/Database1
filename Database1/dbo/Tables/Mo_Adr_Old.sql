CREATE TABLE [dbo].[Mo_Adr_Old] (
    [AdrID]            [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [CountryID]        [dbo].[MoCountry]    NULL,
    [AdrTypeID]        [dbo].[MoAdrType]    NOT NULL,
    [InForce]          [dbo].[MoGetDate]    NOT NULL,
    [SourceID]         [dbo].[MoID]         NOT NULL,
    [Address]          [dbo].[MoAdress]     NULL,
    [City]             [dbo].[MoCity]       NULL,
    [StateName]        [dbo].[MoDescoption] NULL,
    [ZipCode]          [dbo].[MoZipCode]    NULL,
    [Phone1]           [dbo].[MoPhoneExt]   NULL,
    [Phone2]           [dbo].[MoPhoneExt]   NULL,
    [Fax]              [dbo].[MoPhone]      NULL,
    [Mobile]           VARCHAR (27)         NULL,
    [WattLine]         [dbo].[MoPhoneExt]   NULL,
    [OtherTel]         [dbo].[MoPhoneExt]   NULL,
    [Pager]            [dbo].[MoPhone]      NULL,
    [EMail]            [dbo].[MoEmail]      NULL,
    [ConnectID]        INT                  NULL,
    [InsertTime]       [dbo].[MoGetDate]    NOT NULL,
    [iCheckSum]        INT                  NULL,
    [iStateId]         INT                  NULL,
    [vcEmailPersonnel] [dbo].[MoEmail]      NULL,
    [bIndAdrResidence] BIT                  NULL,
    [iCityId]          INT                  NULL,
    [iAdrTypeId]       INT                  NULL,
    CONSTRAINT [PK_Mo_Adr_Old] PRIMARY KEY CLUSTERED ([AdrID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_Adr_Old_Mo_City__iCityId] FOREIGN KEY ([iCityId]) REFERENCES [dbo].[Mo_City] ([CityID]),
    CONSTRAINT [FK_Mo_Adr_Old_Mo_Country__CountryID] FOREIGN KEY ([CountryID]) REFERENCES [dbo].[Mo_Country] ([CountryID]),
    CONSTRAINT [FK_Mo_Adr_Old_Mo_State__iStateId] FOREIGN KEY ([iStateId]) REFERENCES [dbo].[Mo_State] ([StateID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Adr_Old_StateName]
    ON [dbo].[Mo_Adr_Old]([StateName] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Adr_Old_Phone1]
    ON [dbo].[Mo_Adr_Old]([Phone1] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Adr_Old_ZipCode]
    ON [dbo].[Mo_Adr_Old]([ZipCode] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Adr_Old_SourceID]
    ON [dbo].[Mo_Adr_Old]([SourceID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Adr_Old_City]
    ON [dbo].[Mo_Adr_Old]([City] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Adr_Old_Phone2]
    ON [dbo].[Mo_Adr_Old]([Phone2] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Adr_Old_Mobile]
    ON [dbo].[Mo_Adr_Old]([Mobile] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Adr_Old_OtherTel]
    ON [dbo].[Mo_Adr_Old]([OtherTel] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Adr_Old_Pager]
    ON [dbo].[Mo_Adr_Old]([Pager] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Adr_Old_WattLine]
    ON [dbo].[Mo_Adr_Old]([WattLine] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Adr_Old_Fax]
    ON [dbo].[Mo_Adr_Old]([Fax] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Adr_Old_AdrID]
    ON [dbo].[Mo_Adr_Old]([AdrID] ASC) WITH (FILLFACTOR = 90);


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TMo_Adr
Nom du service		: ?
But 				: ?
Facette				: ?

Historique des modifications:
		Date				Programmeur							Description									Référence
		------------		----------------------------------	-----------------------------------------	------------
		2009-09-04	?											Création du service							
		2010-10-01	Steve Gouin							Gestion #DisableTrigger
		2012-12-17	Pierre-Luc Simard					Retrait des caractères non-affichables
		2013-10-17	Pierre-Luc Simard					Modification du trigger pour la gestion des changements apportés dans Proacces
		2013-10-25	Pierre-Luc Simard					Ne pas modifier le iAdrTypeID lorsqu'il contient une valeur dans la nouvel enregistrement
		2013-11-22	Donald Huppé						Ajouter le type H pour le insert dans Mo_HumanAdr
*********************************************************************************************************************/
CREATE TRIGGER dbo.TMo_Adr ON dbo.Mo_Adr_Old FOR INSERT, UPDATE
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
	
	-- Va mettre à jour les champs qui ne sont pas géré par Uniacces vs Proacces
	UPDATE dbo.Mo_Adr SET
		Inforce = dbo.fn_Mo_DateNoTime(i.Inforce),
		Address = dbo.fnGENE_RetirerCaracteresNonAffichable(dbo.fn_Mo_IsStrNull(i.Address)),
		ZipCode = dbo.fnGENE_RetirerCaracteresNonAffichable(dbo.fn_Mo_IsStrNull(i.ZipCode)),
		Fax = dbo.fn_Mo_ClearEmptyPhoneNo(i.Fax),
		Phone1 = dbo.fn_Mo_ClearEmptyPhoneNo(i.Phone1),
		Phone2 = dbo.fn_Mo_ClearEmptyPhoneNo(i.Phone2),
		Mobile = dbo.fn_Mo_ClearEmptyPhoneNo(i.Mobile),
		WattLine = dbo.fn_Mo_ClearEmptyPhoneNo(i.WattLine),
		OtherTel = dbo.fn_Mo_ClearEmptyPhoneNo(i.OtherTel),
		Pager = dbo.fn_Mo_ClearEmptyPhoneNo(i.Pager),
		Email = dbo.fnGENE_RetirerCaracteresNonAffichable(dbo.fn_Mo_IsStrNull(i.Email)),
		ConnectID = ISNULL(i.ConnectID,2), -- 2 = ID de la connexion Uniacces
		City = CASE WHEN ISNULL(i.City,'') <> ISNULL(d.City,'') THEN dbo.fn_Mo_IsStrNull(i.City) ELSE CASE WHEN ISNULL(i.iCityId,0) <> ISNULL(d.iCityId,0) THEN ISNULL(C_ID.CityName,'') ELSE dbo.fn_Mo_IsStrNull(i.City) END END,
		StateName = CASE WHEN ISNULL(i.StateName,'') <> ISNULL(d.StateName,'') THEN dbo.fn_Mo_IsStrNull(i.StateName) ELSE CASE WHEN ISNULL(i.iStateID,0) <> ISNULL(d.iStateID,0) THEN ISNULL(S_ID.StateName,'') ELSE dbo.fn_Mo_IsStrNull(i.StateName) END END,
		iCityId = CASE WHEN  ISNULL(i.iCityId,0) <> ISNULL(d.iCityId,0) THEN i.iCityId ELSE CASE WHEN  ISNULL(i.City,'') <> ISNULL(d.City,'') THEN C.CityID ELSE i.iCityId END END,
		iStateId = CASE WHEN  ISNULL(i.iStateID,0) <> ISNULL(d.iStateID,0) THEN i.iStateID ELSE CASE WHEN  ISNULL(i.StateName,'') <> ISNULL(d.StateName,'') THEN S.StateID ELSE i.iStateID END END,
		iAdrTypeID = CASE WHEN i.iAdrTypeID IS NULL THEN CASE WHEN COALESCE(R.RepID, RHA.RepID) IS NULL THEN 1 ELSE 0 END ELSE i.iAdrTypeID END-- 0 = Adresse d'affaire, 1 = Adresse résidentielle
	FROM dbo.Mo_Adr M
	JOIN INSERTED i ON i.AdrID = M.AdrID
	LEFT JOIN DELETED d ON d.AdrID = M.AdrID
	LEFT JOIN Mo_State S_ID ON S_ID.StateID = i.iStateID
	LEFT JOIN Mo_City C_ID ON C_ID.CityID = i.iCityID
	LEFT JOIN Mo_State S ON S.StateName = i.StateName
	LEFT JOIN Mo_City C ON C.CityName = i.City
	LEFT JOIN Un_Rep R ON R.RepID = i.SourceID
	LEFT JOIN Mo_HumanAdr HA ON HA.AdrID = i.AdrID
	LEFT JOIN Un_Rep RHA ON RHA.RepID = HA.HumanID
	
	-- Remplir la table de jointure pour Proacces pour les nouvelles adresses
	IF EXISTS (
			SELECT 
				i.SourceID,
				i.AdrID			
			FROM INSERTED i 
			LEFT JOIN DELETED d ON d.AdrID = i.AdrID
			WHERE d.AdrID IS NULL
				AND ISNULL(i.SourceID,0) <> 0
				and ISNULL(i.AdrTypeID,'') = 'H'
			)
	BEGIN
		-- Désactivation du trigger
		IF object_id('tempdb..#DisableTrigger') is null
					CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
		INSERT INTO #DisableTrigger VALUES('TMo_HumanAdr_TMPProacces')				

		INSERT INTO Mo_HumanAdr (
			HumanId, 
			AdrId)
		SELECT 
			i.SourceID,
			i.AdrID			
		FROM INSERTED i 
		LEFT JOIN DELETED d ON d.AdrID = i.AdrID
		WHERE d.AdrID IS NULL
			AND ISNULL(i.SourceID,0) <> 0

		-- Réactivation du trigger
		Delete #DisableTrigger where vcTriggerName = 'TMo_HumanAdr_TMPProacces'
	
	END
	
	/* -- Ancienne version Uniacces
	UPDATE dbo.Mo_Adr SET
		Inforce = dbo.fn_Mo_DateNoTime(i.Inforce),
		Address = dbo.fnGENE_RetirerCaracteresNonAffichable(dbo.fn_Mo_IsStrNull(i.Address)),
		City = dbo.fn_Mo_IsStrNull(i.City),
		StateName =dbo.fn_Mo_IsStrNull(i.StateName),
		ZipCode = dbo.fnGENE_RetirerCaracteresNonAffichable(dbo.fn_Mo_IsStrNull(i.ZipCode)),
		Fax = dbo.fn_Mo_ClearEmptyPhoneNo(i.Fax),
		Phone1 = dbo.fn_Mo_ClearEmptyPhoneNo(i.Phone1),
		Phone2 = dbo.fn_Mo_ClearEmptyPhoneNo(i.Phone2),
		Mobile = dbo.fn_Mo_ClearEmptyPhoneNo(i.Mobile),
		WattLine = dbo.fn_Mo_ClearEmptyPhoneNo(i.WattLine),
		OtherTel = dbo.fn_Mo_ClearEmptyPhoneNo(i.OtherTel),
		Pager = dbo.fn_Mo_ClearEmptyPhoneNo(i.Pager),
		Email = dbo.fnGENE_RetirerCaracteresNonAffichable(dbo.fn_Mo_IsStrNull(i.Email))
	FROM dbo.Mo_Adr M, inserted i
	WHERE M.AdrID = i.AdrID
	*/
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_Adr_Old] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Cette table contient les adresses.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''adresse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'AdrID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du pays (Mo_Country).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'CountryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type d''objet auquel appartient l''adresse (''C''=Adresse de compagnie, ''H''=Adresse d''individu).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'AdrTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entré en vigueur de l''adresse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'InForce';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''objet auquel appartient l''adresse. Si AdrTypeID = ''C'' c''est le Mo_Company.CompanyID, si AdrTypeID = ''H'' c''est le Mo_Human.HumanID.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'SourceID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'No civique, numéro de rue et no d''appartement d''il y a lieu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'Address';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la ville.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'City';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la province s''il y a lieu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'StateName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code postal.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'ZipCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Premier numéro de téléphone.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'Phone1';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Deuxième numéro de téléphone.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'Phone2';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de fax.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'Fax';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de téléphone mobile.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'Mobile';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de téléphone sans frais.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'WattLine';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Autre numéro de téléphone.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'OtherTel';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de pagette.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'Pager';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Adresse courriel.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'EMail';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion de l''usager qui a fait l''insertion  de l''adresse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure à laquelle l''adresse fut insérée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'InsertTime';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contient le ID (RowVersion) de l''enregistrement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'iCheckSum';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Adresse courriel personnelle', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'vcEmailPersonnel';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur permettant de savoir si l''adresse d''affaire est la même que l''adresse résidentielle', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Adr_Old', @level2type = N'COLUMN', @level2name = N'bIndAdrResidence';

