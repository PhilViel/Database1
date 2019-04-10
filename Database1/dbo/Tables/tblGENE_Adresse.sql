CREATE TABLE [dbo].[tblGENE_Adresse] (
    [iID_Adresse]          [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [iID_Source]           [dbo].[MoID]         NOT NULL,
    [cType_Source]         CHAR (1)             CONSTRAINT [DF_GENE_Adresse_cTypeSource] DEFAULT ('H') NOT NULL,
    [iID_Type]             INT                  NOT NULL,
    [dtDate_Debut]         DATE                 NOT NULL,
    [bInvalide]            BIT                  CONSTRAINT [DF_GENE_Adresse_bInvalide] DEFAULT ((0)) NOT NULL,
    [dtDate_Creation]      DATETIME             NOT NULL,
    [vcLogin_Creation]     VARCHAR (50)         NULL,
    [vcNumero_Civique]     VARCHAR (10)         NULL,
    [vcNom_Rue]            VARCHAR (75)         NULL,
    [vcUnite]              VARCHAR (10)         NULL,
    [vcCodePostal]         [dbo].[MoZipCode]    NULL,
    [vcBoite]              VARCHAR (50)         NULL,
    [iID_TypeBoite]        INT                  CONSTRAINT [DF_GENE_Adresse_iIDTypeBoite] DEFAULT ((0)) NOT NULL,
    [iID_Ville]            INT                  NULL,
    [vcVille]              [dbo].[MoCity]       NULL,
    [iID_Province]         INT                  NULL,
    [vcProvince]           [dbo].[MoDescoption] NULL,
    [cID_Pays]             CHAR (4)             NULL,
    [vcPays]               VARCHAR (75)         NULL,
    [bNouveau_Format]      BIT                  CONSTRAINT [DF_GENE_Adresse_bNouveauFormat] DEFAULT ((0)) NOT NULL,
    [bResidenceFaitQuebec] BIT                  CONSTRAINT [DF_GENE_Adresse_bResidenceFaitQuebec] DEFAULT ((0)) NOT NULL,
    [bResidenceFaitCanada] BIT                  CONSTRAINT [DF_GENE_Adresse_bResidenceFaitCanada] DEFAULT ((0)) NOT NULL,
    [vcInternationale1]    VARCHAR (175)        NULL,
    [vcInternationale2]    VARCHAR (175)        NULL,
    [vcInternationale3]    VARCHAR (175)        NULL,
    CONSTRAINT [PK_GENE_Adresse] PRIMARY KEY CLUSTERED ([iID_Adresse] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_GENE_Adresse_Mo_City__iIDVille] FOREIGN KEY ([iID_Ville]) REFERENCES [dbo].[Mo_City] ([CityID]),
    CONSTRAINT [FK_GENE_Adresse_Mo_Country__cIDPays] FOREIGN KEY ([cID_Pays]) REFERENCES [dbo].[Mo_Country] ([CountryID]),
    CONSTRAINT [FK_GENE_Adresse_Mo_State__iIDProvince] FOREIGN KEY ([iID_Province]) REFERENCES [dbo].[Mo_State] ([StateID])
);


GO
CREATE NONCLUSTERED INDEX [IX_GENE_Adresse_iIDSource_cType_Source_iID_Type_dtDateDebut]
    ON [dbo].[tblGENE_Adresse]([iID_Source] ASC, [cType_Source] ASC, [iID_Type] ASC, [dtDate_Debut] ASC);


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TtblGENE_Adresse
But					: Historiser les Adresses dans tblGENE_AdresseHistorique lors d'un effacement du record							

Historique des modifications:
		Date				Programmeur				Description										
		------------		-----------------------	-----------------------------------------	
		2015-05-27			Steve Picard			Création du service			

*********************************************************************************************************************/
CREATE TRIGGER dbo.TRG_GENE_Adresse_Historisation_D ON dbo.tblGENE_Adresse FOR DELETE
AS
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	DECLARE @Today date = GetDate()

	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger
	IF object_id('tempdb..#DisableTrigger') is not null 
	BEGIN
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	END

	INSERT INTO dbo.tblGENE_AdresseHistorique (
			iID_Source, cType_Source, iID_Type, dtDate_Debut, dtDate_Fin,
            bInvalide, dtDate_Creation, vcLogin_Creation, 
			vcNumero_Civique, vcNom_Rue, vcUnite, vcCodePostal, vcBoite, iID_TypeBoite, 
			iID_Ville, vcVille, iID_Province, vcProvince, cID_Pays, vcPays,
			bNouveau_Format, bResidenceFaitQuebec, bResidenceFaitCanada, 
			vcInternationale1, vcInternationale2,vcInternationale3
		)
	SELECT 	D.iID_Source, D.cType_Source, D.iID_Type, D.dtDate_Debut, @Today,
            D.bInvalide, D.dtDate_Creation, D.vcLogin_Creation, 
			D.vcNumero_Civique, D.vcNom_Rue, D.vcUnite, D.vcCodePostal, D.vcBoite, D.iID_TypeBoite, 
			D.iID_Ville, D.vcVille, D.iID_Province, D.vcProvince, D.cID_Pays, D.vcPays,
			D.bNouveau_Format, D.bResidenceFaitQuebec, D.bResidenceFaitCanada, 
			D.vcInternationale1, D.vcInternationale2, D.vcInternationale3
	FROM	deleted D LEFT JOIN inserted I ON D.iID_Adresse = I.iID_Adresse
	WHERE	D.dtDate_Debut < @Today
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TtblGENE_Adresse
But					: Historiser les Adresses dans tblGENE_AdresseHistorique lors d'un changement sur le record							

Historique des modifications:
		Date				Programmeur				Description										
		------------		-----------------------	-----------------------------------------	
		2015-05-27		Steve Picard			Création du service			
          2016-09-13          Steve Picard             Correction des doublons dans historique
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TRG_GENE_Adresse_Historisation_U] ON [dbo].[tblGENE_Adresse] FOR UPDATE
AS
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	DECLARE @Now datetime = GetDate()
     DECLARE @Today date = @Now

	IF object_id('tempdb..#DisableTrigger') is null 
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
	ELSE
	BEGIN
		-- Si la table #DisableTrigger est présente, il se pourrait que le trigger
		-- ne soit pas à exécuter
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	END
	
	--	Bloque les triggers
	INSERT INTO #DisableTrigger VALUES('TRG_GENE_Adresse_Historisation_U')	
	INSERT INTO #DisableTrigger VALUES('TRG_GENE_Adresse_Historisation_D')	
	INSERT INTO #DisableTrigger VALUES('TtblGENE_Adresse')	

	SELECT I.iID_Adresse, CASE WHEN I.dtDate_Debut < @Today THEN @Today ELSE I.dtDate_Debut END as dtNew_Debut, D.dtDate_Debut As dtOld_Debut
	  INTO #Tbl_Adresse
	  FROM inserted I JOIN deleted D ON D.iID_Adresse = I.iID_Adresse
	 WHERE I.iID_Source <> D.iID_Source
	    OR I.cType_Source <> D.cType_Source
		OR I.iID_Type <> D.iID_Type
		OR I.dtDate_Debut <> D.dtDate_Debut
		OR I.bInvalide <> D.bInvalide
		OR I.dtDate_Creation <> D.dtDate_Creation
		OR IsNull(I.vcLogin_Creation, '') <> IsNull(D.vcLogin_Creation, '')
		OR IsNull(I.vcNumero_Civique, '') <> IsNull(D.vcNumero_Civique, '')
		OR IsNull(I.vcNom_Rue, '') <> IsNull(D.vcNom_Rue, '')
		OR IsNull(I.vcUnite, '') <> IsNull(D.vcUnite, '')
		OR IsNull(I.vcCodePostal, '') <> IsNull(D.vcCodePostal, '')
		OR IsNull(I.vcBoite, '') <> IsNull(D.vcBoite, '')
		OR I.iID_TypeBoite <> D.iID_TypeBoite
		OR IsNull(I.iID_Ville, 0) <> IsNull(D.iID_Ville, 0)
		OR IsNull(I.vcVille, '') <> IsNull(D.vcVille, '')
		OR IsNull(I.iID_Province, 0) <> IsNull(D.iID_Province, 0)
		OR IsNull(I.vcProvince, '') <> IsNull(D.vcProvince, '')
		OR IsNull(I.cID_Pays, '') <> IsNull(D.cID_Pays, '')
		OR IsNull(I.vcPays, '') <> IsNull(D.vcPays, '')
		OR I.bNouveau_Format <> D.bNouveau_Format
		OR I.bResidenceFaitQuebec <> D.bResidenceFaitQuebec
		OR I.bResidenceFaitCanada <> D.bResidenceFaitCanada
		OR IsNull(I.vcInternationale1, '') <> IsNull(D.vcInternationale1, '')
		OR IsNull(I.vcInternationale2, '') <> IsNull(D.vcInternationale2, '')
		OR IsNull(I.vcInternationale3, '') <> IsNull(D.vcInternationale3, '')

	--	S'il y a des adresses courantes
	IF EXISTS(SELECT TOP 1 * FROM #Tbl_Adresse WHERE dtNew_Debut <= @Today) BEGIN
		--	Historise si la nouvelle est la courante (non post-daté)

        INSERT INTO dbo.tblGENE_AdresseHistorique (
				iID_Source, cType_Source, iID_Type, dtDate_Debut, dtDate_Fin, bInvalide, dtDate_Creation, vcLogin_Creation, vcNumero_Civique,
                    vcNom_Rue, vcUnite, vcCodePostal, vcBoite, iID_TypeBoite, iID_Ville, vcVille, iID_Province, vcProvince, cID_Pays, vcPays, 
				bNouveau_Format, bResidenceFaitQuebec, bResidenceFaitCanada, vcInternationale1, vcInternationale2, vcInternationale3
			)
        SELECT
            D.iID_Source, D.cType_Source, D.iID_Type, D.dtDate_Debut,
            CASE WHEN I.dtNew_Debut > @Today THEN I.dtNew_Debut ELSE @Today END,
            D.bInvalide, D.dtDate_Creation, D.vcLogin_Creation , D.vcNumero_Civique, D.vcNom_Rue, D.vcUnite, D.vcCodePostal,  D.vcBoite, 
		  D.iID_TypeBoite, D.iID_Ville, D.vcVille, D.iID_Province, D.vcProvince, D.cID_Pays, D.vcPays, D.bNouveau_Format, 
		  D.bResidenceFaitQuebec, D.bResidenceFaitCanada, D.vcInternationale1, D.vcInternationale2, D.vcInternationale3
        FROM
            #Tbl_Adresse I
			INNER JOIN deleted D ON D.iID_Adresse = I.iID_Adresse
        WHERE
            D.dtDate_Debut < @Today
            AND I.dtNew_Debut >= @Today
/*
        INSERT INTO dbo.tblGENE_Adresse (
				iID_Source, cType_Source, iID_Type, dtDate_Debut, bInvalide, dtDate_Creation, vcLogin_Creation, vcNumero_Civique,
                    vcNom_Rue, vcUnite, vcCodePostal, vcBoite, iID_TypeBoite, iID_Ville, vcVille, iID_Province, vcProvince, cID_Pays, vcPays, 
				bNouveau_Format, bResidenceFaitQuebec, bResidenceFaitCanada, vcInternationale1, vcInternationale2, vcInternationale3
			)
        SELECT
            I.iID_Source, I.cType_Source, I.iID_Type, I.dtDate_Debut,
            I.bInvalide, GetDate(), dbo.GetUserContext() , I.vcNumero_Civique, I.vcNom_Rue, I.vcUnite, I.vcCodePostal,  I.vcBoite, 
		  I.iID_TypeBoite, I.iID_Ville, I.vcVille, I.iID_Province, I.vcProvince, I.cID_Pays, I.vcPays, I.bNouveau_Format, 
		  I.bResidenceFaitQuebec, I.bResidenceFaitCanada, I.vcInternationale1, I.vcInternationale2, I.vcInternationale3
	   FROM
            dbo.tblGENE_Adresse A
		  INNER JOIN #Tbl_Adresse TB ON TB.iID_Adresse = A.iID_Adresse
		  INNER JOIN inserted I ON I.iID_Adresse = TB.iID_Adresse
		  INNER JOIN deleted D ON D.iID_Adresse = TB.iID_Adresse
	   WHERE
            (D.dtDate_Debut < @Today And TB.dtNew_Debut >= @Today)
		  OR (D.dtDate_Debut = @Today And TB.dtNew_Debut = @Today)

        DELETE FROM A
	   FROM
            dbo.tblGENE_Adresse A
		  INNER JOIN #Tbl_Adresse TB ON TB.iID_Adresse = A.iID_Adresse
		  INNER JOIN inserted I ON I.iID_Adresse = TB.iID_Adresse
		  INNER JOIN deleted D ON D.iID_Adresse = TB.iID_Adresse
	   WHERE
            (D.dtDate_Debut < @Today And TB.dtNew_Debut >= @Today)
		  OR (D.dtDate_Debut = @Today And TB.dtNew_Debut = @Today)
*/
		UPDATE  A
		SET		iID_Source = I.iID_Source, 
				cType_Source = I.cType_Source,
				iID_Type = I.iID_Type, 
				dtDate_Debut = CASE WHEN TB.dtNew_Debut > @Today THEN TB.dtNew_Debut ELSE @Today END,
				bInvalide = I.bInvalide, 
				dtDate_Creation = I.dtDate_Creation, --GETDATE(),
				--vcLogin_Creation = dbo.GetUserContext(),
				vcNumero_Civique = I.vcNumero_Civique, 
				vcNom_Rue = I.vcNom_Rue, 
				vcUnite = I.vcUnite, 
				vcCodePostal = I.vcCodePostal, 
				vcBoite = I.vcBoite, 
				iID_TypeBoite = I.iID_TypeBoite, 
				iID_Ville = I.iID_Ville, 
				vcVille = I.vcVille, 
				iID_Province = I.iID_Province, 
				vcProvince = I.vcProvince, 
				cID_Pays = I.cID_Pays, 
				vcPays = I.vcPays,
				bNouveau_Format = I.bNouveau_Format, 
				bResidenceFaitQuebec = I.bResidenceFaitQuebec, 
				bResidenceFaitCanada = I.bResidenceFaitCanada, 
				vcInternationale1 = I.vcInternationale1, 
				vcInternationale2 = I.vcInternationale2,
				vcInternationale3 = I.vcInternationale3
		FROM	dbo.tblGENE_Adresse A
				INNER JOIN #Tbl_Adresse TB ON TB.iID_Adresse = A.iID_Adresse
				INNER JOIN inserted I ON I.iID_Adresse = TB.iID_Adresse
				INNER JOIN deleted D ON D.iID_Adresse = TB.iID_Adresse
		WHERE	(D.dtDate_Debut < @Today And TB.dtNew_Debut >= @Today)
		        OR (D.dtDate_Debut = @Today And TB.dtNew_Debut = @Today)

	END

	--IF EXISTS(SELECT TOP 1 * FROM #Tbl_Adresse WHERE CAST(dtNew_Debut as date) = @Today) BEGIN
	--	UPDATE  A
	--	SET		vcLogin_Creation = dbo.GetUserContext(),
	--			dtDate_Creation = GETDATE()
	--	FROM	dbo.tblGENE_Adresse A
	--			INNER JOIN #Tbl_Adresse I ON I.iID_Adresse = A.iID_Adresse
	--			INNER JOIN deleted D ON D.iID_Adresse = I.iID_Adresse
	--	WHERE	D.dtDate_Debut = @Today And I.dtNew_Debut = @Today
	--END

	IF EXISTS(SELECT TOP 1 * FROM #Tbl_Adresse WHERE dtOld_Debut > @Today and dtNew_Debut > @Today) BEGIN
		UPDATE	A
		SET		iID_Source = I.iID_Source, 
				cType_Source = I.cType_Source,
				iID_Type = I.iID_Type, 
				dtDate_Debut = CASE WHEN TB.dtNew_Debut > @Today THEN CAST(TB.dtNew_Debut as date) 
                                        ELSE @Today 
                                   END,
				bInvalide = I.bInvalide, 
				--dtDate_Creation = GETDATE(),
				--vcLogin_Creation = dbo.GetUserContext(),
				vcNumero_Civique = I.vcNumero_Civique, 
				vcNom_Rue = I.vcNom_Rue, 
				vcUnite = I.vcUnite, 
				vcCodePostal = I.vcCodePostal, 
				vcBoite = I.vcBoite, 
				iID_TypeBoite = I.iID_TypeBoite, 
				iID_Ville = I.iID_Ville, 
				vcVille = I.vcVille, 
				iID_Province = I.iID_Province, 
				vcProvince = I.vcProvince, 
				cID_Pays = I.cID_Pays, 
				vcPays = I.vcPays,
				bNouveau_Format = I.bNouveau_Format, 
				bResidenceFaitQuebec = I.bResidenceFaitQuebec, 
				bResidenceFaitCanada = I.bResidenceFaitCanada, 
				vcInternationale1 = I.vcInternationale1, 
				vcInternationale2 = I.vcInternationale2,
				vcInternationale3 = I.vcInternationale3
		  FROM	dbo.tblGENE_Adresse A
				INNER JOIN #Tbl_Adresse TB ON TB.iID_Adresse = A.iID_Adresse 
				INNER JOIN inserted I ON I.iID_Adresse = TB.iID_Adresse
		 WHERE	TB.dtOld_Debut > @Today And TB.dtNew_Debut > @Today

	END

	--	S'il y a des adresses post-datées
	IF EXISTS(SELECT TOP 1 * FROM #Tbl_Adresse WHERE dtOld_Debut <= @Today and dtNew_Debut > @Today) BEGIN

		--	Recrée la nouvelle  dans dbo.tblGENE_Adresse si post-daté'
		INSERT INTO dbo.tblGENE_Adresse (
				iID_Source, cType_Source, iID_Type, dtDate_Debut,
				bInvalide, dtDate_Creation, vcLogin_Creation, 
				vcNumero_Civique, vcNom_Rue, vcUnite, vcCodePostal, vcBoite, iID_TypeBoite, 
				iID_Ville, vcVille, iID_Province, vcProvince, cID_Pays, vcPays,
				bNouveau_Format, bResidenceFaitQuebec, bResidenceFaitCanada, 
				vcInternationale1, vcInternationale2,vcInternationale3
			)
		SELECT 	I.iID_Source, I.cType_Source, I.iID_Type, CAST(I.dtDate_Debut as date),
				--I.bInvalide, IsNull(I.dtDate_Creation, @Today), IsNull(I.vcLogin_Creation, dbo.GetUserContext()), 
				I.bInvalide, GetDate(), dbo.GetUserContext(), 
				I.vcNumero_Civique, I.vcNom_Rue, I.vcUnite, I.vcCodePostal, I.vcBoite, I.iID_TypeBoite, 
				I.iID_Ville, I.vcVille, I.iID_Province, I.vcProvince, I.cID_Pays, I.vcPays,
				I.bNouveau_Format, I.bResidenceFaitQuebec, I.bResidenceFaitCanada, 
				I.vcInternationale1, I.vcInternationale2, I.vcInternationale3
		FROM	#Tbl_Adresse D INNER JOIN inserted I ON I.iID_Adresse = D.iID_Adresse
		WHERE	D.dtOld_Debut <= @Today And D.dtNew_Debut > @Today

		--PRINT 'Ramène la veille adresse into dbo.tblGENE_Adresse si post-daté'
		UPDATE  A
		SET		iID_Source = D.iID_Source, 
				cType_Source = D.cType_Source,
				iID_Type = D.iID_Type, 
				dtDate_Debut = CAST(D.dtDate_Debut as date), 
				bInvalide = D.bInvalide, 
				dtDate_Creation = D.dtDate_Creation, 
				vcLogin_Creation = D.vcLogin_Creation, 
				vcNumero_Civique = D.vcNumero_Civique, 
				vcNom_Rue = D.vcNom_Rue, 
				vcUnite = D.vcUnite, 
				vcCodePostal = D.vcCodePostal, 
				vcBoite = D.vcBoite, 
				iID_TypeBoite = D.iID_TypeBoite, 
				iID_Ville = D.iID_Ville, 
				vcVille = D.vcVille, 
				iID_Province = D.iID_Province, 
				vcProvince = D.vcProvince, 
				cID_Pays = D.cID_Pays, 
				vcPays = D.vcPays,
				bNouveau_Format = D.bNouveau_Format, 
				bResidenceFaitQuebec = D.bResidenceFaitQuebec, 
				bResidenceFaitCanada = D.bResidenceFaitCanada, 
				vcInternationale1 = D.vcInternationale1, 
				vcInternationale2 = D.vcInternationale2,
				vcInternationale3 = D.vcInternationale3
		FROM	dbo.tblGENE_Adresse A
				INNER JOIN #Tbl_Adresse I ON I.iID_Adresse = A.iID_Adresse
				INNER JOIN deleted D ON D.iID_Adresse = I.iID_Adresse
		WHERE	(D.dtDate_Debut <= @Today And I.dtNew_Debut > @Today)
                    OR D.dtDate_Debut > @Today

	END

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TtblGENE_Adresse'
	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TRG_GENE_Adresse_Historisation_D'
	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TRG_GENE_Adresse_Historisation_U'
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
EXECUTE sp_settriggerorder @triggername = N'[dbo].[TRG_GENE_Adresse_Historisation_U]', @order = N'last', @stmttype = N'update';


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TtblGENE_Adresse
But						: Mettre à jour les AdrID dans mo_Human et Mo_Dep lorsqu'une nouvelle adresse est saise.							

Historique des modifications:
		Date				Programmeur				Description										
		------------		-----------------------	-----------------------------------------	
		2014-04-08	Pierre-Luc Simard		Création du service			
		2014-06-05	Pierre-Luc Simard		Synchronisation de la province dans Un_Subscriber		
		2015-01-07	Pierre-Luc Simard		Gestion des prévalidations suite à un changement d'adresse sur un bénéficiaire
		2015-12-18	Pierre-Luc Simard		Mettre à jour les données uniquement si elles sont différentes des valeurs actuelles
		   
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TtblGENE_Adresse] ON [dbo].[tblGENE_Adresse] AFTER UPDATE, INSERT
AS
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

	-- Si la table #DisableTrigger est présente, il se pourrait que le trigger
	-- ne soit pas à exécuter
	IF object_id('tempdb..#DisableTrigger') is not null 
	BEGIN
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	END
	ELSE
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

	INSERT INTO #DisableTrigger VALUES('TUn_Beneficiary')	
	INSERT INTO #DisableTrigger VALUES('TUn_Subscriber')
	INSERT INTO #DisableTrigger VALUES('TUn_Convention')	
	INSERT INTO #DisableTrigger VALUES('TUn_Convention_State')	
	INSERT INTO #DisableTrigger VALUES('TUn_Convention_YearQualif')	
	INSERT INTO #DisableTrigger VALUES('TR_I_Un_Convention_F_dtRegStartDate')	
	INSERT INTO #DisableTrigger VALUES('TR_U_Un_Convention_F_dtRegStartDate')	
	INSERT INTO #DisableTrigger VALUES('TR_D_Un_Convention_F_dtRegStartDate')	
	INSERT INTO #DisableTrigger VALUES('TRG_GENE_Adresse_Historisation_U')
	-- *** FIN AVERTISSEMENT *** 

	DECLARE @iMaxBeneficiaryID INT

	UPDATE dbo.tblGENE_Adresse SET
		dtDate_Debut = dbo.fn_Mo_DateNoTime(i.dtDate_Debut),
		vcNom_Rue = dbo.fnGENE_RetirerCaracteresNonAffichable(dbo.fn_Mo_IsStrNull(i.vcNom_Rue)),
		--City = dbo.fn_Mo_IsStrNull(i.City),
		--StateName =dbo.fn_Mo_IsStrNull(i.StateName),
		vcCodePostal = dbo.fnGENE_RetirerCaracteresNonAffichable(dbo.fn_Mo_IsStrNull(i.vcCodePostal)),
		vcLogin_Creation = dbo.GetUserContext(),
		dtDate_Creation = GetDate()
	FROM tblGENE_Adresse M JOIN inserted i ON M.iID_Adresse = i.iID_Adresse

	-- Va mettre à jour l'AdrID de la table Mo_Human (Affaire si représentant, Résidence pour les autres)
	UPDATE M
	SET AdrID = i.iID_Adresse
	FROM dbo.Mo_Human M
	JOIN inserted i ON i.iID_Source = M.HumanID
	LEFT JOIN dbo.Un_Rep R ON R.RepID = M.HumanID
	WHERE i.dtDate_Debut <= GETDATE()
		AND ((i.iID_Type = 1 AND R.RepID IS NULL) -- Adresse de résidence pour les non représentants
			OR (i.iID_Type = 4 AND R.RepID IS NOT NULL)) -- Adresse d'affaire pour les représentants
		AND ISNULL(M.AdrID, 0) <> ISNULL(i.iID_Adresse, 0)
			
	-- Va mettre à jour le champ AddressLost dans Un_Subscriber
	UPDATE S
	SET AddressLost = ISNULL(i.bInvalide,0),
		StateID = i.iID_Province
	FROM dbo.Un_Subscriber S
	JOIN inserted i ON i.iID_Source = S.SubscriberID  
	JOIN dbo.Mo_Human H ON H.HumanID = i.iID_Source and H.AdrID = i.iID_Adresse
	WHERE i.dtDate_Debut <= GETDATE()
		AND (ISNULL(S.AddressLost, 0) <> ISNULL(i.bInvalide,0)
			OR ISNULL(S.StateID, 0) <> ISNULL(i.iID_Province, 0))
	
	-- Va mettre à jour le champ bAddressLost dans Un_Beneficiary
	UPDATE B
	SET bAddressLost = ISNULL(i.bInvalide,0)
	FROM dbo.Un_Beneficiary B
	JOIN inserted i ON i.iID_Source = B.BeneficiaryID
	JOIN dbo.Mo_Human H ON H.HumanID = i.iID_Source and H.AdrID = i.iID_Adresse
	WHERE i.dtDate_Debut <= GETDATE()
		AND ISNULL(bAddressLost, 0) <> ISNULL(i.bInvalide,0)
	
	-- Boucler sur les changements de pays afin de mettre à jour les prévalidations et le BEC
	SELECT @iMaxBeneficiaryID = MAX(B.BeneficiaryID) 
	FROM dbo.Un_Beneficiary B
	JOIN inserted i ON i.iID_Source = B.BeneficiaryID
	WHERE i.dtDate_Debut <= GETDATE()
	
	--CASE WHEN A.cID_Pays = 'CAN' OR A.bResidenceFaitCanada = 1 THEN 1 ELSE 0 END,

	WHILE @iMaxBeneficiaryID	IS NOT NULL
		BEGIN
			EXEC dbo.psCONV_EnregistrerPrevalidationPCEE 2, NULL, @iMaxBeneficiaryID, NULL, NULL

			SELECT 
				@iMaxBeneficiaryID = MAX(B.BeneficiaryID) 
			FROM dbo.Un_Beneficiary B
			JOIN inserted i ON i.iID_Source = B.BeneficiaryID
			WHERE B.BeneficiaryID < @iMaxBeneficiaryID
				AND i.dtDate_Debut <= GETDATE()
				
		END
			
	/*
	-- Va mettre à jour l'AdrID de la table Mo_Dep
	UPDATE Mo_Dep 
	SET AdrID = i.iID_Adresse
	FROM Mo_Dep M, inserted i
	WHERE M.DepID = i.iID_Source
		AND i.dtDate_Debut >= GETDATE()
	*/
	/*
	SELECT '[tblGENE_Adresse]', * FROM tblGENE_Adresse M, inserted i
	WHERE M.iID_Adresse = i.iID_Adresse
	*/
	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    BEGIN
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Beneficiary'
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Subscriber'
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Convention'
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Convention_State'
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Convention_YearQualif'
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_I_Un_Convention_F_dtRegStartDate'
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_U_Un_Convention_F_dtRegStartDate'
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_D_Un_Convention_F_dtRegStartDate'	
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TRG_GENE_Adresse_Historisation_U'
    END
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Cette table contient les adresses courantes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique de l''adresse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'iID_Adresse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique de l''objet auquel appartient l''adresse. Si cType_Source = ''C'' c''est le Mo_Company.CompanyID, si cType_Source = ''H'' c''est le Mo_Human.HumanID.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'iID_Source';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type d''objet auquel appartient l''adresse (''C''=Adresse de compagnie, ''H''=Adresse d''individu).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'cType_Source';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type d''adresse (1 = Résidentielle, 2= Livraison, 4 = Affaire).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'iID_Type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date d''entré en vigueur de l''adresse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'dtDate_Debut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si l''adresse est invalide.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'bInvalide';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure à laquelle l''adresse fut insérée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'dtDate_Creation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Login de l''utilisateur ayant créé cette adresse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'vcLogin_Creation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro civique de l''adresse postale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'vcNumero_Civique';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom de rue de l''adresse postale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'vcNom_Rue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Unité de l''adresse postale (Numéro d''appartement, de bureau, de local, etc.)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'vcUnite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code postal.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'vcCodePostal';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de boîte postal (Casier, Route rurale, etc.).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'vcBoite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de boîte (1 = Casier postal, 2 = Route rurale).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'iID_TypeBoite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de la ville.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'iID_Ville';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom de la ville.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'vcVille';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de la province.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'iID_Province';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom de la province.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'vcProvince';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du pays. (3 lettres)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'cID_Pays';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du pays.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'vcPays';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si l''adresse est enregistré selon le nouveau format (No, rue et appartement séparés).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'bNouveau_Format';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si la citoyenneté québecoise est conservée même si l''adresse est hors Québec.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'bResidenceFaitQuebec';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si la citoyenneté canadienne est conservée même si l''adresse est hors Canada.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'bResidenceFaitCanada';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne 1 de l''adresse internationale', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'vcInternationale1';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne 2 de l''adresse internationale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'vcInternationale2';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne 3 de l''adresse internationale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_Adresse', @level2type = N'COLUMN', @level2name = N'vcInternationale3';

