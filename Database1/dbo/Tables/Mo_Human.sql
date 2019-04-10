CREATE TABLE [dbo].[Mo_Human] (
    [HumanID]                      [dbo].[MoID]              IDENTITY (1, 1) NOT NULL,
    [AdrID]                        [dbo].[MoIDoption]        NULL,
    [ResidID]                      [dbo].[MoCountry]         NULL,
    [SexID]                        [dbo].[MoSex]             NOT NULL,
    [LangID]                       CHAR (3)                  NOT NULL,
    [CivilID]                      [dbo].[MoCivil]           NOT NULL,
    [CourtesyTitle]                [dbo].[MoFirstNameoption] NULL,
    [FirstName]                    [dbo].[MoFirstNameoption] NULL,
    [OrigName]                     [dbo].[MoDescoption]      NULL,
    [Initial]                      [dbo].[MoInitial]         NULL,
    [LastName]                     [dbo].[MoLastNameoption]  NULL,
    [CompanyName]                  [dbo].[MoDescoption]      NULL,
    [BirthDate]                    [dbo].[MoDateoption]      NULL,
    [DeathDate]                    [dbo].[MoDateoption]      NULL,
    [SocialNumber]                 [dbo].[MoDescoption]      NULL,
    [DriverLicenseNo]              [dbo].[MoDescoption]      NULL,
    [WebSite]                      [dbo].[MoDescoption]      NULL,
    [UsingSocialNumber]            [dbo].[MoBitTrue]         NULL,
    [SharePersonalInfo]            [dbo].[MoBitTrue]         NULL,
    [MarketingMaterial]            [dbo].[MoBitTrue]         NULL,
    [IsCompany]                    [dbo].[MoBitFalse]        NULL,
    [StateCompanyNo]               [dbo].[MoDescoption]      NULL,
    [CountryCompanyNo]             [dbo].[MoDescoption]      NULL,
    [InsertConnectID]              INT                       NULL,
    [LastUpdateConnectID]          INT                       NULL,
    [cID_Pays_Origine]             CHAR (4)                  NULL,
    [vcNIP]                        VARCHAR (8)               NULL,
    [bHumain_Accepte_Publipostage] BIT                       CONSTRAINT [DF_Mo_Human_bHumainAcceptePublipostage] DEFAULT ((1)) NULL,
    [iCheckSum]                    INT                       NULL,
    [vcOccupation]                 VARCHAR (50)              NULL,
    [vcEmployeur]                  VARCHAR (50)              NULL,
    [tiNbAnneesService]            TINYINT                   NULL,
    [bIsAdrsInvald]                BIT                       NULL,
    [bLangUsageEcrit]              BIT                       NULL,
    [bLangSecondeEcrit]            BIT                       NULL,
    [bLangAutreEcrit]              BIT                       NULL,
    [LivraisonAdrId]               INT                       NULL,
    [AdrIdAnticipe]                INT                       NULL,
    [vcLangSecondaireId]           CHAR (3)                  NULL,
    [vcLangAutreId]                CHAR (3)                  NULL,
    [vcPrononciation]              VARCHAR (50)              NULL,
    [iRaison_AucunCourriel]        INT                       CONSTRAINT [DF_Mo_Human_iRaisonAucunCourriel] DEFAULT ((0)) NOT NULL,
    [dDateEmbauche]                DATE                      NULL,
    [LoginName]                    VARCHAR (50)              NULL,
    CONSTRAINT [PK_Mo_Human] PRIMARY KEY CLUSTERED ([HumanID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_Human_Mo_Connect__InsertConnectID] FOREIGN KEY ([InsertConnectID]) REFERENCES [dbo].[Mo_Connect] ([ConnectID]),
    CONSTRAINT [FK_Mo_Human_Mo_Connect__LastUpdateConnectID] FOREIGN KEY ([LastUpdateConnectID]) REFERENCES [dbo].[Mo_Connect] ([ConnectID]),
    CONSTRAINT [FK_Mo_Human_Mo_Country__cIDPaysOrigine] FOREIGN KEY ([cID_Pays_Origine]) REFERENCES [dbo].[Mo_Country] ([CountryID]),
    CONSTRAINT [FK_Mo_Human_Mo_Country__ResidID] FOREIGN KEY ([ResidID]) REFERENCES [dbo].[Mo_Country] ([CountryID]),
    CONSTRAINT [FK_Mo_Human_Mo_Lang__LangID] FOREIGN KEY ([LangID]) REFERENCES [dbo].[Mo_Lang] ([LangID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Human_FirstName_LastName]
    ON [dbo].[Mo_Human]([FirstName] ASC, [LastName] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Human_LastName_FirstName]
    ON [dbo].[Mo_Human]([LastName] ASC, [FirstName] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Human_SocialNumber]
    ON [dbo].[Mo_Human]([SocialNumber] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Human_AdrID]
    ON [dbo].[Mo_Human]([AdrID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Human_BirthDate]
    ON [dbo].[Mo_Human]([BirthDate] DESC) WITH (FILLFACTOR = 90);


GO
CREATE TRIGGER [dbo].[TMo_Human_Log] ON [dbo].[Mo_Human] AFTER INSERT, UPDATE
AS
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

	-- Si la table #DisableTrigger est présente, il se pourrait que le trigger
	-- ne soit pas à exécuter
	IF object_id('tempdb..#DisableTrigger') is null 
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
	ELSE BEGIN
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	END

	-- *** FIN AVERTISSEMENT *** 

	DECLARE @RecSep CHAR(1) = CHAR(30)
			,	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
			,	@ConnectID int = 2
			,	@ActionID int
			,	@Now datetime = GetDate()

	IF (Select Count(*) From deleted) > 0
		SET @ActionID = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'U')
	ELSE
		SET @ActionID = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'I')

	;WITH CTE_HumanNew As (
		SELECT	H.HumanID, FirstName, LastName, SexID, LangID, SocialNumber, cID_Pays_Origine, BirthDate, DeathDate
		FROM	inserted H
				INNER JOIN dbo.Un_Rep R ON R.RepID = H.HumanID
	),
	CTE_HumanOld As (
		SELECT	H.HumanID, FirstName, LastName, SexID, LangID, SocialNumber, cID_Pays_Origine, BirthDate, DeathDate
		FROM	deleted H
				INNER JOIN dbo.Un_Rep R ON R.RepID = H.HumanID
	)
	INSERT INTO CRQ_Log (ConnectID, LogCodeID, LogTime, LogActionID, LogTableName, LogDesc, LogText)
		SELECT
			@ConnectID, New.HumanID, @Now, @ActionID, 
			LogTableName = 'Un_Rep', 
			LogDesc = 'Représentant : ' + New.LastName + ', ' + New.FirstName, 
			LogText =				
				CASE WHEN IsNull(New.FirstName, '') = IsNull(Old.FirstName, '') THEN ''
						ELSE 'FirstName' + @RecSep + IsNull(Old.FirstName, '')
											+ @RecSep +IsNull(New.FirstName, '')
											+ @RecSep + @CrLf
				END + 
				CASE WHEN IsNull(New.LastName, '') = IsNull(Old.LastName, '') THEN ''
						ELSE 'LastName' + @RecSep + IsNull(Old.LastName, '') 
										+ @RecSep + IsNull(New.LastName, '') 
										+ @RecSep + @CrLf
				END + 
				CASE WHEN IsNull(New.BirthDate, 0) = IsNull(Old.BirthDate, 0) THEN ''
						ELSE 'BirthDate' + @RecSep + CASE WHEN IsNull(Old.BirthDate, 0) <= 0 THEN ''
														ELSE CONVERT(CHAR(10), IsNull(Old.BirthDate, 0), 20)
													END + @RecSep
												+ CASE WHEN IsNull(New.BirthDate, 0) <= 0 THEN ''
														ELSE CONVERT(CHAR(10), IsNull(New.BirthDate, 0), 20)
													END 
												+ @RecSep + @CrLf
				END + 
				CASE WHEN IsNull(New.DeathDate, 0) = IsNull(Old.DeathDate, 0) THEN ''
						ELSE 'DeathDate' + @RecSep + CASE WHEN IsNull(Old.DeathDate, 0) <= 0 THEN ''
														ELSE CONVERT(CHAR(10), IsNull(Old.DeathDate, 0), 20)
													END + @RecSep
												+ CASE WHEN IsNull(New.DeathDate, 0) <= 0 THEN ''
														ELSE CONVERT(CHAR(10), IsNull(New.DeathDate, 0), 20)
													END 
												+ @RecSep + @CrLf
				END + 
				CASE WHEN RTrim(IsNull(New.LangID, '')) = RTrim(IsNull(Old.LangID, '')) THEN ''
						ELSE 'LangID' + @RecSep + Old.LangID + @RecSep + New.LangID
 										+ @RecSep + IsNull((Select LangName From  dbo.Mo_Lang Where LangID = Old.LangID), '')
 										+ @RecSep + IsNull((Select LangName From  dbo.Mo_Lang Where LangID = New.LangID), '')
										+ @RecSep + @CrLf
				END + 
				CASE WHEN RTrim(IsNull(New.SexID, '')) = RTrim(IsNull(Old.SexID, '')) THEN ''
						ELSE 'SexID' + @RecSep + Old.SexID + @RecSep + New.SexID
										+ @RecSep + IsNull((Select SexName From  dbo.Mo_Sex Where LangID = 'FRA' AND SexID = Old.SexID), '')
										+ @RecSep + IsNull((Select SexName From  dbo.Mo_Sex Where LangID = 'FRA' AND SexID = New.SexID), '')
										+ @RecSep + @CrLf
				END + 
				CASE WHEN RTrim(IsNull(Old.SocialNumber, '')) = RTrim(IsNull(New.SocialNumber, '')) THEN ''
						ELSE 'SocialNumber' + @RecSep + Old.SocialNumber + @RecSep + New.SocialNumber 
											+ @RecSep + @CrLf
				END + 
				CASE WHEN RTrim(IsNull(Old.cID_Pays_Origine, '')) = RTrim(IsNull(New.cID_Pays_Origine, '')) THEN ''
						ELSE 'cID_Pays_Origine' + @RecSep + Old.cID_Pays_Origine + @RecSep + New.cID_Pays_Origine 
											+ @RecSep + IsNull((Select CountryName From Mo_Country WHERE CountryID = Old.cID_Pays_Origine), '')
											+ @RecSep + IsNull((Select CountryName From Mo_Country WHERE CountryID = new.cID_Pays_Origine), '')
											+ @RecSep + @CrLf
				END + 
				''
		FROM	CTE_HumanNew New
				JOIN CTE_HumanOld Old ON Old.HumanID = New.HumanID
		WHERE	(	IsNull(Old.FirstName, '') <> IsNull(New.FirstName, '')
					OR IsNull(Old.LastName, '') <> IsNull(New.LastName, '')
					OR IsNull(Old.BirthDate, 0) <> IsNull(New.BirthDate, 0)
					OR IsNull(Old.DeathDate, 0) <> IsNull(New.DeathDate, 0)
					OR RTrim(Old.LangID) <> RTrim(New.LangID)
					OR RTrim(Old.SexID) <> RTrim(New.SexID)
					OR RTrim(IsNull(Old.SocialNumber, '')) <> RTrim(IsNull(New.SocialNumber, ''))
					OR RTrim(IsNull(Old.cID_Pays_Origine, '')) <> RTrim(IsNull(New.cID_Pays_Origine, ''))
				)
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_settriggerorder @triggername = N'[dbo].[TMo_Human_Log]', @order = N'last', @stmttype = N'insert';


GO
EXECUTE sp_settriggerorder @triggername = N'[dbo].[TMo_Human_Log]', @order = N'last', @stmttype = N'update';


GO
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc.
Nom                 :	TMo_Human_YearQualif
Description         :	Trigger mettant … jour automatiquement le champ d'ann‚e de qualification
Valeurs de retours  :	N/A
Note                :	ADX0001337	IA	2007-06-04	Bruno Lapointe		Creation
										2010-10-01	Steve Gouin			Gestion #DisableTrigger
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TMo_Human_YearQualif] ON [dbo].[Mo_Human] FOR UPDATE 
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
		@GetDate DATETIME,
		@ConnectID INT
		
	SET @GetDate = GETDATE()
	
	SELECT @ConnectID = MAX(ConnectID)
	FROM Mo_Connect C
	JOIN Mo_User U ON U.UserID = C.UserID
	WHERE U.LoginNameID = 'Compurangers'

	IF EXISTS ( -- Valide si une modification affecte une ann‚e de qualification
			SELECT I.HumanID
			FROM INSERTED I
			JOIN DELETED D ON D.HumanID = I.HumanID
			JOIN dbo.Un_Convention C ON C.BeneficiaryID = I.HumanID
			WHERE D.BirthDate <> I.BirthDate -- Modification de la date de naissance
			)
	BEGIN
		-- Cr‚e un table temporaire qui contiendra les ann‚es de qualifications calcul‚es
		-- des conventions dont la date de naissance du b‚n‚ficiaire a chang‚e.
		DECLARE @tYearQualif_Upd TABLE (
			ConventionID INT PRIMARY KEY,
			YearQualif INT NOT NULL )
			
		-- Calul les ann‚es de qualifications des conventions affect‚es
		INSERT INTO @tYearQualif_Upd
			SELECT 
				C.ConventionID,
				YearQualif = 
					CASE 
						WHEN P.PlanTypeID = 'IND' THEN 0 -- Si individuel = 0
					ELSE YEAR(HB.BirthDate) + P.tiAgeQualif -- Si collectif Ann‚e de la date de naissance du b‚n‚ficiaire + Age de qualification du r‚gime.
					END
			FROM dbo.Un_Convention C
			JOIN INSERTED I ON C.BeneficiaryID = I.HumanID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID 
			JOIN DELETED D ON D.HumanID = I.HumanID
			WHERE D.BirthDate <> I.BirthDate -- Modification de la date de naissance
				AND	CASE 
							WHEN P.PlanTypeID = 'IND' THEN 0 -- Si individuel = 0
						ELSE YEAR(HB.BirthDate) + P.tiAgeQualif -- Si collectif Ann‚e de la date de naissance du b‚n‚ficiaire + Age de qualification du r‚gime.
						END <> C.YearQualif -- L'ann‚e de qualification a chang‚e
			
		-- Inscrit l'ann‚e de qualification calcul‚e sur les conventions
		UPDATE C
		SET YearQualif = Y.YearQualif
		FROM dbo.Un_Convention C
		JOIN @tYearQualif_Upd Y ON Y.ConventionID = C.ConventionID
		
		-- Met la date de fin sur le pr‚c‚dent historique de changement d'ann‚e de qualification
		UPDATE Un_ConventionYearQualif
		SET TerminatedDate = DATEADD(ms,-2,@GetDate)
		FROM Un_ConventionYearQualif C
		JOIN @tYearQualif_Upd Y ON Y.ConventionID = C.ConventionID
		WHERE C.TerminatedDate IS NULL

		-- InsŠre un historique d'ann‚e de qualification sur les conventions
		INSERT INTO Un_ConventionYearQualif (
				ConventionID, 
				ConnectID, 
				EffectDate, 
				YearQualif)
			SELECT
				C.ConventionID, 
				ISNULL(HB.LastUpdateConnectID,@ConnectID), 
				@GetDate, 
				Y.YearQualif
			FROM dbo.Un_Convention C
			JOIN @tYearQualif_Upd Y ON Y.ConventionID = C.ConventionID
			JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
	END

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
CREATE TRIGGER [dbo].[TMo_Human] ON [dbo].[Mo_Human]
AFTER INSERT, UPDATE
AS
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

	-- Si la table #DisableTrigger est présente, il se pourrait que le trigger
	-- ne soit pas à exécuter
	IF object_id('tempdb..#DisableTrigger') is null 
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
	ELSE BEGIN
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	END

	-- Empêche le trigger de exécuter à nouveau
	INSERT INTO #DisableTrigger VALUES('TMo_Human')		

	-- *** FIN AVERTISSEMENT *** 

	IF	NOT APP_NAME() LIKE 'ProAcces%' AND 
		(UPDATE(LastName) OR UPDATE(FirstName) OR UPDATE(BirthDate) OR UPDATE(DeathDate) OR UPDATE(ResidID))
	BEGIN
		UPDATE dbo.Mo_Human SET
			LastName = CASE WHEN (i.LastName = '.') and (i.CompanyName <> '') and (i.CompanyName IS NOT NULL) THEN NULL
								ELSE i.LastName
								END,
			FirstName = CASE WHEN (i.FirstName = '.') and (i.CompanyName <> '') and (i.CompanyName IS NOT NULL) THEN NULL
								ELSE i.FirstName
								END,
			BirthDate = dbo.fn_Mo_DateNoTime( i.BirthDate),
			DeathDate = dbo.fn_Mo_DateNoTime( i.DeathDate),
			ResidID = ISNULL(i.ResidID, 'CAN') 
		FROM dbo.Mo_Human M JOIN inserted i ON M.HumanID = i.HumanID
	END

	----------------------------------------------------------------------
	-- Suivre les modifications aux enregistrements de la table "Mo_Human"
	----------------------------------------------------------------------
	DECLARE @iID_Nouveau_Enregistrement INT,
			@iID_Ancien_Enregistrement INT,
			@NbOfRecord int,
			@i int

	DECLARE @Tinserted TABLE (
		Id INT IDENTITY (1,1),  
		ID_Nouveau_Enregistrement INT, 
		ID_Ancien_Enregistrement INT)

	SELECT @NbOfRecord = COUNT(*) FROM inserted

	INSERT INTO @Tinserted (ID_Nouveau_Enregistrement,ID_Ancien_Enregistrement)
		SELECT I.HumanID, D.HumanID
		FROM Inserted I
			 LEFT JOIN Deleted D ON D.HumanID = I.HumanID

	SET @i = 1

	WHILE @i <= @NbOfRecord
	BEGIN
		SELECT 
			@iID_Nouveau_Enregistrement = ID_Nouveau_Enregistrement, 
			@iID_Ancien_Enregistrement = ID_Ancien_Enregistrement 
		FROM @Tinserted 
		WHERE id = @i

		-- Ajouter la modification dans le suivi des modifications
		EXECUTE psGENE_AjouterSuiviModification 7, @iID_Nouveau_Enregistrement, @iID_Ancien_Enregistrement
		
		SET @i = @i + 1
	END

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TMo_Human'		

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;

GO
EXECUTE sp_settriggerorder @triggername = N'[dbo].[TMo_Human]', @order = N'first', @stmttype = N'insert';


GO
EXECUTE sp_settriggerorder @triggername = N'[dbo].[TMo_Human]', @order = N'first', @stmttype = N'update';


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_Human] TO [svc-portailmigrationprod]
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des humains.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''humain.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'HumanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''adresse (Mo_Adr) de cette personne.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'AdrID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de 3 caractères identifiant le pays de résidence (Mo_Country.CountryID) de cette personne.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'ResidID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Un caractère identifiant le sexe (Mo_Sex) de cette personne. (''U''=Inconnu, ''F''=Féminin, ''M''=Masculin)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'SexID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne de 3 caractères identifiant la langue de cette personne. (''UNK''=Inconnu, ''FRA''=Français, ''ENU''=Anglais)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'LangID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Un caractère identifiant l''état civil de la personne. (''D''=Divorcé, ''J''=Conjoint de fait, ''M''=Marié, ''P''=Séparé, ''S''=Célibataire, ''U''=Inconnu, ''W''=Veuf)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'CivilID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Titre de courtoisie. (Ex: Docteur)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'CourtesyTitle';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Prénom', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'FirstName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom à la naissance', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'OrigName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Initiales qui sont après le prénom (Ex: Jr pour junior)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'Initial';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de famille', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'LastName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la compagnie', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'CompanyName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de naissance', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'BirthDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de décès', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'DeathDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro d''assurance social', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'SocialNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de permis de conduire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'DriverLicenseNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Site internet', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'WebSite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si on a l''autorisation utiliser le numéro d''assurance social. (=0:Non, <>0:Oui)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'UsingSocialNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant si on a l''autorisation de partager les informations personnelles avec d''autres comagnies. (=0:Non, <>0:Oui)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'SharePersonalInfo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant s''il nous autorise à lui envoyer de la publicité. (=0:Non, <>0:Oui)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'MarketingMaterial';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Inutitilé (Toujours 0)- Champs boolean indiquant s''il s''agit d''une compagnie ou d''un individu. (=0:Individu, <>0:Compagnie)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'IsCompany';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de compagnie provincial.  Correspond au NEQ de Revenu Québec.  Utilisé dans l''IQÉÉ pour représenter les souscripteurs et principaux responsables qui sont des entreprises.  Utilisé dans peu de cas.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'StateCompanyNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Inutitilé - Numéro de compagnie fédéral.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'CountryCompanyNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de connexion de l''usager qui a inséré l''humain', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'InsertConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de connexion de l''usager qui a effectué la dernière modification à l''humain', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'LastUpdateConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro d''identification personnelle pour le service à la clientèle', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'vcNIP';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contient le ID (RowVersion) de l''enregistrement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'iCheckSum';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Emploi occupé par l''humain', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'vcOccupation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Employeur de l''humain', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'vcEmployeur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre d''années de service pour son employeur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'tiNbAnneesService';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur permettant de savoir si la personne possède une adresse valide', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'bIsAdrsInvald';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur pour savoir si la langue d''usage est utilisée pour l''écriture. Non coché (0) ou cochée (1)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'bLangUsageEcrit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur pour savoir si la langue seconde est utilisée pour l''écriture. Non coché (0) ou cochée (1)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'bLangSecondeEcrit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur pour savoir si l''autre langue est utilisée pour l''écriture. Non coché (0) ou cochée (1)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'bLangAutreEcrit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique de l''adresse de livraison', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'LivraisonAdrId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Prononciation du nom et du prénom', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'vcPrononciation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique la ou les raisons pour une absence d’adresse courriel pour un humain (0 = NonDefini, 1 = RefusCommuniquer, 2 = AucuneAdresse, 3 = Tous).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'iRaison_AucunCourriel';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Login de l''utilisateur ayant effectué la dernière modification.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Human', @level2type = N'COLUMN', @level2name = N'LoginName';

