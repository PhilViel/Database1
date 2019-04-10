

CREATE VIEW [ProAcces].[Mo_Human] As
	SELECT	HumanID, FirstName, LastName, SocialNumber, SexID, LangID, cID_Pays_Origine, BirthDate, DeathDate, iRaison_AucunCourriel, LoginName
	FROM	dbo.Mo_Human H


GO
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc.
Nom                 :	TR_Mo_Human_ins
Description         :	Trigger traitant le nouvel enregistrement inséré
Valeurs de retours  :	N/A
Note                :	
*********************************************************************************************************************/
CREATE TRIGGER [ProAcces].[TR_Mo_Human_Ins] ON [ProAcces].[Mo_Human]
INSTEAD OF INSERT
AS BEGIN

	SET NoCount ON

	EXEC dbo.TT_PrintDebugMsg @@PROCID, 'Start'

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
			EXEC dbo.TT_PrintDebugMsg @@PROCID, 'Trigger Ignored'
			RETURN
		END
	END

	INSERT INTO #DisableTrigger VALUES('TR_Mo_Human_Ins')	

	-- *** FIN AVERTISSEMENT *** 

	INSERT INTO dbo.Mo_Human (
			FirstName, LastName, SocialNumber, SexID, LangID, cID_Pays_Origine, BirthDate, DeathDate, iRaison_AucunCourriel
			-- Follows not used with wrong default
			, ResidID, bHumain_Accepte_Publipostage
		)
	SELECT	FirstName, LastName, SocialNumber, SexID, LangID, cID_Pays_Origine, Cast(BirthDate as date), Cast(DeathDate as date), iRaison_AucunCourriel
			-- Follows not used with wrong default
			, 'CAN', 0
	FROM	inserted

	-- Ce SELECT est obligé et doit être immédiatement après l'insertion afin que Entity Framework puisse recevoir le Id du nouveau record
	DECLARE @Id int = IDENT_CURRENT('dbo.Mo_Human')
	SELECT @Id as HumanID

	DECLARE	@NbItems int = (SELECT COUNT(*) FROM inserted)

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_Mo_Human_Ins'		

	DECLARE	@LogDesc	VARCHAR(5000),
			@HeaderLog	VARCHAR(5000),
			@HumanID	INT,
			@SocialNumber VARCHAR(25)

	WHILE @NbItems > 0 BEGIN
		SET @NbItems = @NbItems - 1
		SET @HumanID = @Id - @NbItems

		-- Mettre à jour l'état des prévalidations du bénéficiaire
		IF EXISTS(Select Top 1 * From dbo.Un_Beneficiary Where BeneficiaryID = @HumanID)
			EXEC psCONV_EnregistrerPrevalidationPCEE 2, NULL, @HumanID, NULL, NULL			

		-- Mettre à jour l'état des prévalidations du souscripteur
		IF EXISTS(Select Top 1 * From dbo.Un_Subscriber Where SubscriberID = @HumanID)
			EXEC psCONV_EnregistrerPrevalidationPCEE 2, NULL, NULL, @HumanID, NULL			

		-- Mettre à jour l'état des prévalidations du tuteur
		IF EXISTS(Select Top 1 * From dbo.Un_Tutor Where iTutorID = @HumanID)
			EXEC psCONV_EnregistrerPrevalidationPCEE 2, NULL, NULL, NULL, @HumanID			

		SELECT	@SocialNumber = IsNull(SocialNumber, ''),
				@HeaderLog = dbo.fn_Mo_FormatLog ('MO_HUMAN', 'NEW', '', (LastName + ', '+ FirstName)),
				@LogDesc = dbo.fn_Mo_FormatLog ('MO_HUMAN', 'FIRSTNAME', '', FirstName)
				 		 + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'LASTNAME', '', LastName)
						 + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'BIRTHDATE', ' ', CAST(BirthDate AS CHAR))
						 + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'DEATHDATE', ' ', CAST(DeathDate AS CHAR))
						 + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'SEXID', '', dbo.fn_Mo_SexDesc(SexID))
						 + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'LANGID', '', dbo.fn_Mo_LangDesc(LangID))
						 + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'SOCIALNUMBER', '', SocialNumber)
		FROM	dbo.Mo_Human 
		WHERE	HumanID = @HumanID

		IF Len(@SocialNumber) > 0
			EXEC TT_UN_HumanSocialNumber 2, @HumanID, @SocialNumber 

		IF @LogDesc <> '' 
			SET @LogDesc = @HeaderLog + @LogDesc

		EXEC dbo.IMo_Log 2, 'Mo_Human', @HumanID, 'I', @LogDesc;

	END

	EXEC dbo.TT_PrintDebugMsg @@PROCID, 'End'

END

GO
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc.
Nom                 :	TR_Mo_Human_Upd
Description         :	Trigger traitant l'enregistrement mis èa jour
Valeurs de retours  :	N/A
Note                :	
*********************************************************************************************************************/
CREATE TRIGGER [ProAcces].[TR_Mo_Human_Upd] ON [ProAcces].[Mo_Human]
INSTEAD OF UPDATE
AS BEGIN
	EXEC dbo.TT_PrintDebugMsg @@PROCID, 'Start'

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
			EXEC dbo.TT_PrintDebugMsg @@PROCID, 'Trigger Ignored'
			RETURN
		END
	END

	INSERT INTO #DisableTrigger VALUES('TR_Mo_Human_Upd')	

	-- *** FIN AVERTISSEMENT *** 

	DECLARE @Now datetime = GetDate()

	-- Si juste le loginName qui change, on ne fait rien
	IF COLUMNS_UPDATED() = 256
		INSERT INTO #DisableTrigger VALUES('TMo_Human')	

	UPDATE	H
	SET		FirstName = I.FirstName, 
			LastName = I.LastName, 
			SocialNumber = I.SocialNumber, 
			SexID = I.SexID, 
			LangID = i.LangID, 
			cID_Pays_Origine = i.cID_Pays_Origine, 
			BirthDate = CAST(I.BirthDate AS Date), 
			DeathDate = CAST(i.DeathDate AS Date),
			iRaison_AucunCourriel = i.iRaison_AucunCourriel,
			LoginName = I.LoginName
	FROM	dbo.Mo_Human H INNER JOIN inserted I ON I.HumanID = H.HumanID

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TMo_Human'

	DECLARE	@LogDesc	VARCHAR(5000),
			@HeaderLog	VARCHAR(5000),
			@HumanID	INT = 0,
			@HumanType  char(1),
			@tiCESPState int,
			@ConventionID int, 
			@DateEntreeREEE date,
			@SocialNumber	varchar(25),
			@ErrorNo int,
			@MsgErr varchar(100)

	DECLARE @TB_Human TABLE (HumanID int, HumanType char(1), tiCESPStateOld int)

	INSERT INTO @TB_Human (HumanID, HumanType, tiCESPStateOld)
	SELECT H.HumanID, CASE WHEN B.BeneficiaryID IS NOT NULL THEN 'B'
							   WHEN S.SubscriberID IS NOT NULL THEN 'S'
							   WHEN T.iTutorID IS NOT NULL THEN 'T'
	                      END,
						  CASE WHEN B.BeneficiaryID IS NOT NULL THEN B.tiCESPState
							   WHEN S.SubscriberID IS NOT NULL THEN S.tiCESPState
							   WHEN T.iTutorID IS NOT NULL THEN 0
	                      END
	  FROM inserted H LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
					  LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
					  LEFT JOIN dbo.Un_Tutor T ON T.iTutorID = H.HumanID
	 WHERE Coalesce(B.BeneficiaryID, S.SubscriberID, T.iTutorID, 0) > 0

	SET @HumanID = 0
	WHILE EXISTS(SELECT TOP 1 HumanId FROM INSERTED WHERE HumanId > @HumanID) BEGIN
		SET @tiCESPState = 0
		SELECT @HumanID = Min(HumanId) FROM INSERTED WHERE HumanId > @HumanID
		SET @HumanType = IsNull((Select HumanType FROM @TB_Human WHERE HumanID = @HumanID), '')

		-- Mettre à jour l'état des prévalidations du bénéficiaire
		IF @HumanType = 'B' BEGIN
			EXEC @ErrorNo = psCONV_EnregistrerPrevalidationPCEE 2, NULL, @HumanID, NULL, NULL	

			SELECT @tiCESPState = tiCESPState FROM dbo.Un_Beneficiary WHERE BeneficiaryID = @HumanID
		END

		-- Mettre à jour l'état des prévalidations du souscripteur
		IF @HumanType = 'S' BEGIN
			EXEC @ErrorNo = psCONV_EnregistrerPrevalidationPCEE 2, NULL, NULL, @HumanID, NULL	
			
			SELECT @tiCESPState = tiCESPState FROM dbo.Un_Subscriber WHERE SubscriberID = @HumanID
		END

		-- Mettre à jour l'état des prévalidations du tuteur
		IF @HumanType = 'T' BEGIN
			EXEC @ErrorNo = psCONV_EnregistrerPrevalidationPCEE 2, NULL, NULL, NULL, @HumanID	
		END

		IF EXISTS(SELECT TOP 1 I.HumanID FROM inserted I JOIN deleted D ON D.HumanID = I.HumanID WHERE I.HumanId = @HumanID and IsNull(I.SocialNumber, '') <> IsNull(D.SocialNumber, '')) BEGIN

			SELECT @SocialNumber = IsNull(SocialNumber, '') FROM inserted WHERE HumanId = @HumanID

			EXEC @ErrorNo = dbo.TT_UN_HumanSocialNumber 2, @HumanID, @SocialNumber 
			If @ErrorNo < 0 BEGIN
				SET @MsgErr = 'Error in TT_UN_HumanSocialNumber (' + ltrim(str(@ErrorNo)) + ')'
				EXEC dbo.TT_PrintDebugMsg @@PROCID, @MsgErr
			END
		END
		
		IF @HumanType = 'B' BEGIN
			IF @tiCESPState IN (2,4) And EXISTS(Select Top 1 * From @TB_Human Where IsNull(tiCESPStateOld, 0) NOT IN (2,4))
			BEGIN
				-- Récupérer la bonne convention BEC.
				SET @ConventionID = dbo.fnCONV_ObtenirConventionBEC(@HumanID, 0, NULL)
				SET @DateEntreeREEE = (SELECT dtRegStartDate FROM dbo.UN_Convention WHERE ConventionID = @ConventionID)

				-- S'il y a une convention BEC et une date dtRegStartDAte, alors on génère la transaction 400.
				IF (@ConventionID > 0) AND (@DateEntreeREEE <= @Now) -- Ne pas créer de BEC avant la date d'entrée en REEE
					EXEC dbo.TT_UN_CLB @ConventionID
			END
		END

		IF @HumanType = 'B' Or @HumanType = 'S' BEGIN
			-- Appelle de la procédure stockée qui gère les enregistrements 100, 200, et 400 de toutes les conventions
			IF EXISTS(SELECT TOP 1 H.* FROM dbo.Mo_Human H JOIN deleted D ON D.HumanID = H.HumanID
					   WHERE H.HumanID = @HumanID 
						 and (	IsNull(H.LastName, '') <> IsNull(D.LastName, '') OR
								IsNull(H.FirstName, '')  <> IsNull(D.FirstName, '')  OR 
								IsNull(H.SocialNumber, '')  <> IsNull(D.SocialNumber, '')  OR 
								IsNull(H.SexID, '')  <> IsNull(D.SexID, '') OR
								IsNull(H.BirthDate, 0)  <> IsNull(D.BirthDate, 0)  OR 
								IsNull(H.LangID, '')  <> IsNull(D.LangID, '')
							  )
			) BEGIN
				IF @HumanType = 'B'
					EXECUTE @ErrorNo = TT_UN_CESPOfConventions 2, @HumanID, 0, 0
				IF @HumanType = 'S'
					EXECUTE @ErrorNo = TT_UN_CESPOfConventions 2, 0, @HumanID, 0

				If @ErrorNo <= 0 BEGIN
					SET @MsgErr = 'Error in TT_UN_CESPOfConventions (' + RTrim(Str(@ErrorNo)) + ')'
					EXEC dbo.TT_PrintDebugMsg @@PROCID, @MsgErr
				END
			END
		END	

		SELECT	@HeaderLog = dbo.fn_Mo_FormatLog ('MO_HUMAN', 'MODIF', '', (I.LastName + ', '+ I.FirstName)),
				@LogDesc = dbo.fn_Mo_FormatLog ('MO_HUMAN', 'FIRSTNAME', D.FirstName, I.FirstName)
				 		 + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'LASTNAME', D.LastName, I.LastName)
						 + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'BIRTHDATE', CAST(D.BirthDate AS CHAR), CAST(I.BirthDate AS CHAR))
						 + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'DEATHDATE', CAST(D.DeathDate AS CHAR), CAST(I.DeathDate AS CHAR))
						 + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'SEXID', dbo.fn_Mo_SexDesc(D.SexID), dbo.fn_Mo_SexDesc(I.SexID))
						 + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'LANGID', dbo.fn_Mo_LangDesc(D.LangID), dbo.fn_Mo_LangDesc(I.LangID))
						 + dbo.fn_Mo_FormatLog ('MO_HUMAN', 'SOCIALNUMBER', D.SocialNumber, I.SocialNumber)
		FROM	INSERTED I	JOIN DELETED D ON D.HumanID = I.HumanID 
		WHERE	I.HumanID = @HumanID

		IF @LogDesc <> '' BEGIN
			SET @LogDesc = @HeaderLog + @LogDesc

			EXEC @ErrorNo = dbo.IMo_Log 2, 'Mo_Human', @HumanID, 'U', @LogDesc
			If @ErrorNo = 0 BEGIN
				DECLARE @Msg varchar(100) = 'Error in dbo.IMo_Log : ' + Str(@ErrorNo)
				EXEC dbo.TT_PrintDebugMsg @@PROCID, @Msg
			END
		END
	END

	DECLARE @RecSep CHAR(1) = CHAR(30)
		,	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
		,	@ConnectID int = 2
		,	@ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'U')

	;WITH CTE_HumanNew As (
		SELECT	H.HumanID, H.FirstName, H.LastName, H.SexID, H.LangID, H.SocialNumber, H.cID_Pays_Origine, H.BirthDate, H.DeathDate
		FROM	ProAcces.Mo_Human H INNER JOIN inserted I ON I.HumanID = H.HumanID
	),
	CTE_HumanOld As (
		SELECT	H.HumanID, FirstName, LastName, SexID, LangID, SocialNumber, cID_Pays_Origine, BirthDate, DeathDate
		FROM	deleted H
	)
	INSERT INTO CRQ_Log (ConnectID, LogCodeID, LogTime, LogActionID, LogTableName, LogDesc, LogText)
		SELECT
			@ConnectID, New.HumanID, @Now, @ActionID, 
			LogTableName = CASE WHEN B.BeneficiaryID IS NOT NULL THEN 'Un_Beneficiary'
								WHEN S.SubscriberID IS NOT NULL THEN 'Un_Subscriber'
								WHEN T.iTutorID IS NOT NULL THEN 'Un_Tutor'
								WHEN R.RepID IS NOT NULL THEN 'Un_Rep'
							END, 
			LogDesc = CASE WHEN B.BeneficiaryID IS NOT NULL THEN 'Bénéficiaire'
							WHEN S.SubscriberID IS NOT NULL THEN 'Souscripteur'
							WHEN T.iTutorID IS NOT NULL THEN 'Tuteur'
							WHEN R.RepID IS NOT NULL THEN 'Représentant'
						END + ' : ' + New.LastName + ', ' + New.FirstName, 
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
						ELSE 'SocialNumber' + @RecSep + RTrim(IsNull(Old.SocialNumber, '')) + @RecSep + RTrim(IsNull(New.SocialNumber, ''))
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
				LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = New.HumanID
				LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = New.HumanID
				LEFT JOIN dbo.Un_Tutor T ON T.iTutorID = New.HumanID
				LEFT JOIN dbo.Un_Rep R ON R.RepID = New.HumanID
		WHERE	(B.BeneficiaryID IS NOT NULL OR S.SubscriberID IS NOT NULL OR T.iTutorID IS NOT NULL OR R.RepID IS NOT NULL)
			AND	(	IsNull(Old.FirstName, '') <> IsNull(New.FirstName, '')
					OR IsNull(Old.LastName, '') <> IsNull(New.LastName, '')
					OR IsNull(Old.BirthDate, 0) <> IsNull(New.BirthDate, 0)
					OR IsNull(Old.DeathDate, 0) <> IsNull(New.DeathDate, 0)
					OR RTrim(Old.LangID) <> RTrim(New.LangID)
					OR RTrim(Old.SexID) <> RTrim(New.SexID)
					OR RTrim(IsNull(Old.SocialNumber, '')) <> RTrim(IsNull(New.SocialNumber, ''))
					OR RTrim(IsNull(Old.cID_Pays_Origine, '')) <> RTrim(IsNull(New.cID_Pays_Origine, ''))
				)
	
	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_Mo_Human_Upd'
	
	EXEC dbo.TT_PrintDebugMsg @@PROCID, 'End'
END

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue réprsentant l''ancienne table dbo.Mo_Human qui a été recréée dans le schema ProAcces', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Mo_Human';

