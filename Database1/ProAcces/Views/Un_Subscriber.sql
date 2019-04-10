CREATE VIEW [ProAcces].[Un_Subscriber] AS
	SELECT SubscriberID, RepID, iID_Preference_Suivi, iID_Preference_Suivi_Siege_Social, bEtats_Financiers_Annuels, bEtats_Financiers_Semestriels, Spouse, 
		   vcConjoint_Employeur, vcConjoint_Profession, dConjoint_Embauche, Contact1, Contact1Phone, bReleve_Papier, dtConsentement_Tremplin, bConsentement_Tremplin
	FROM dbo.Un_Subscriber
GO
CREATE TRIGGER [ProAcces].[TR_Un_Subscriber_Del] ON [ProAcces].[Un_Subscriber]
	   INSTEAD OF DELETE
AS BEGIN
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

	DECLARE @Now datetime = GetDate()
		, 	@RecSep CHAR(1) = CHAR(30)
		, 	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
		, 	@ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'D')
		,	@iID_Utilisateur INT = (SELECT iID_Utilisateur_Systeme FROM dbo.Un_Def)

	;WITH CTE_Human (HumanID, FirstName, LastName, SexID, LangID, SocialNumber, PaysID_Origine, BirthDate, DeathDate) 
	as (
		SELECT	HumanID, FirstName, LastName, SexID, LangID, SocialNumber, cID_Pays_Origine, BirthDate, DeathDate
		  FROM deleted D
				JOIN dbo.Mo_Human H ON H.HumanID = D.SubscriberID
	),
	CTE_Adresse (SourceID, AdresseID, City, StateName, CountryID, CountryName, ZipCode, Nouveau_Format, Adresse)
	as (
		SELECT iID_Source, iID_Adresse, vcVille, vcProvince, cID_Pays, C.CountryName, vcCodePostal, bNouveau_Format, 
			   Adresse =	CASE 
								WHEN A.cID_Pays <> 'CAN' AND A.bNouveau_Format = 1 
									THEN RTrim(RTrim(IsNull(A.vcInternationale1 , '') + SPACE(1) + IsNull(A.vcInternationale2, '')) + SPACE(1) + IsNull(A.vcInternationale3, ''))
								ELSE 
									CASE WHEN ISNULL(A.vcUnite, '') <> '' THEN A.vcUnite + '-' ELSE '' END + 
									CASE WHEN ISNULL(A.vcNumero_Civique, '') <> '' THEN A.vcNumero_Civique + '' ELSE '' END + 
									CASE WHEN ISNULL(A.vcNom_Rue, '') <> '' THEN SPACE(1) + A.vcNom_Rue ELSE '' END + 
									CASE WHEN ISNULL(A.vcBoite , '') <> '' THEN SPACE(1) + 
										CASE WHEN A.iID_TypeBoite = 1 THEN 'CP'
												WHEN A.iID_TypeBoite = 3 THEN 'RR'
										END + SPACE(1) + A.vcBoite 
									ELSE '' END
							END
		  FROM CTE_Human H INNER JOIN dbo.tblGENE_Adresse A ON A.iID_Source = H.HumanID
						   LEFT JOIN dbo.Mo_Country C ON C.CountryID = A.cID_Pays
	),
	CTE_Phone (SourceID, AdresseID, Phone1, Phone2, Fax, Mobile, OtherTel, EMail)
	as (
		SELECT SourceID, AdresseID,
		       Phone1 = dbo.fnGENE_TelephoneEnDate (SourceID, 1, NULL, 0, 0),
			   Phone2 = dbo.fnGENE_TelephoneEnDate (SourceID, 4, NULL, 0, 0),
			   Fax = dbo.fnGENE_TelephoneEnDate (SourceID, 8, NULL, 0, 0),
			   Mobile = dbo.fnGENE_TelephoneEnDate (SourceID, 2, NULL, 0, 0),
			   OtherTel = dbo.fnGENE_TelephoneEnDate (SourceID, 16, NULL, 0, 0),
			   EMail = dbo.fnGENE_CourrielEnDate (SourceID, 1, NULL, 0)
		  FROM CTE_Adresse
	)
	INSERT INTO CRQ_Log (ConnectID, LogTableName, LogCodeID, LogTime, LogActionID, LogDesc, LogText)
			SELECT
				2, 'Un_Subscriber', SubscriberID, @Now, @ActionID, 
				LogDesc = 'Souscripteur : ' + H.LastName + ', ' + H.FirstName, 
				LogText =				
					CASE WHEN ISNULL(H.FirstName, '') = '' THEN ''
						 ELSE 'FirstName' + @RecSep + H.FirstName + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(H.LastName, '') = '' THEN ''
						 ELSE 'LastName' + @RecSep + H.LastName + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(H.BirthDate, 0) <= 0 THEN ''
						 ELSE 'BirthDate' + @RecSep + CONVERT(CHAR(10), H.BirthDate, 20) + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(H.DeathDate, 0) <= 0 THEN ''
						 ELSE 'DeathDate' + @RecSep + CONVERT(CHAR(10), H.DeathDate, 20) + @RecSep + @CrLf
					END + 
					'LangID' + @RecSep + H.LangID
 							 + @RecSep + IsNull((Select LangName From  dbo.Mo_Lang Where LangID = H.LangID), '')
							 + @RecSep + @CrLf + 
					'SexID' + @RecSep + H.SexID
 							+ @RecSep + IsNull((Select SexName From  dbo.Mo_Sex Where LangID = 'FRA' AND SexID = H.SexID), '')
							+ @RecSep + @CrLf + 
					CASE WHEN ISNULL(H.SocialNumber, '') = '' THEN ''
							ELSE 'SocialNumber' + @RecSep + H.SocialNumber + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(H.PaysID_Origine, '') = '' THEN ''
						 ELSE 'cID_Pays_Origine' + @RecSep + H.PaysID_Origine
											     + @RecSep + IsNull((Select CountryName From Mo_Country WHERE CountryID = H.PaysID_Origine), '')
											     + @RecSep + @CrLf
					END +
					CASE WHEN ISNULL(A.Adresse, '') = '' THEN ''
							ELSE 'Address' + @RecSep + A.Adresse + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(A.City, '') = '' THEN ''
							ELSE 'City' + @RecSep + A.City + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(A.StateName, '') = '' THEN ''
							ELSE 'StateName' + @RecSep + A.StateName + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(A.CountryID, '') = '' THEN ''
							ELSE 'CountryID' + @RecSep + A.CountryID + @RecSep + A.CountryName + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(A.ZipCode, '') = '' THEN ''
							ELSE 'ZipCode' + @RecSep + A.ZipCode + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(P.Phone1, '') = '' THEN ''
							ELSE 'Phone1' + @RecSep + P.Phone1 + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(P.Phone2, '') = '' THEN ''
							ELSE 'Phone2' + @RecSep + P.Phone2 + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(P.Fax, '') = '' THEN ''
							ELSE 'Fax' + @RecSep + P.Fax + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(P.Mobile, '') = '' THEN ''
							ELSE 'Mobile' + @RecSep + P.Mobile + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(P.OtherTel, '') = '' THEN ''
							ELSE 'OtherTel' + @RecSep + P.OtherTel + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(P.EMail, '') = '' THEN ''
							ELSE 'EMail' + @RecSep + P.EMail + @RecSep + @CrLf
					END+ 
					CASE WHEN ISNULL(S.RepID, 0) <= 0 THEN ''
						 ELSE 'RepID' + @RecSep + LTrim(Str(S.RepID)) 
									  + @RecSep + (Select ISNULL(LastName, '') + ', ' + IsNull(FirstName, '') FROM dbo.Mo_Human Where HumanID = S.RepID)
									  + @RecSep + @CrLf
					END + 
					CASE WHEN IsNull(S.Spouse, '') = '' THEN ''
						 ELSE 'Spouse' + @RecSep + LTrim(S.Spouse)
									   + @RecSep + @CrLf
					END + 
					CASE WHEN IsNull(S.Contact1, '') = '' THEN ''
						 ELSE 'Contact1' + @RecSep + LTrim(S.Contact1)
									     + @RecSep + @CrLf
					END + 
					CASE WHEN IsNull(S.Contact1Phone, '') = '' THEN ''
						 ELSE 'Contact1Phone' + @RecSep + LTrim(S.Contact1Phone)
											  + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(S.iID_Preference_Suivi, 0) <= 0 THEN ''
						 ELSE 'PreferenceSuiviID' + @RecSep + LTrim(Str(ISNULL(S.iID_Preference_Suivi, 0)))
												  + @RecSep + ISNULL((Select vcDescription From tblCONV_PreferenceSuivi Where iID_Preference_Suivi = S.iID_Preference_Suivi), '')
												  + @RecSep + @CrLf
					END + 
					'bEtats_Financiers_Annuels' + @RecSep 
						+ CASE WHEN ISNULL(S.bEtats_Financiers_Annuels, 0) = 1 THEN 'Oui' ELSE 'Non' END + @RecSep + @CrLf + 
					-- 2011-06-23 : + 2011-12 - CM
					'bEtats_Financiers_Semestriels' + @RecSep 
						+ CASE WHEN ISNULL(S.bEtats_Financiers_Semestriels, 0) = 1 THEN 'Oui' ELSE 'Non' END + @RecSep + @CrLf + 					
					'bReleve_Papier' + @RecSep 
						+ CASE WHEN ISNULL(S.bReleve_Papier, 0) = 1 THEN 'Oui' ELSE 'Non' END + @RecSep + @CrLf + 
					CASE WHEN IsNull(S.vcConjoint_Employeur, '') = '' THEN ''
						 ELSE 'vcConjoint_Employeur' + @RecSep + LTrim(S.vcConjoint_Employeur)
													 + @RecSep + @CrLf
					END + 
					CASE WHEN IsNull(S.vcConjoint_Profession, '') = '' THEN ''
						 ELSE 'vcConjoint_Profession' + @RecSep + LTrim(S.vcConjoint_Profession)
													  + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(CAST(S.dConjoint_Embauche as datetime), 0) <= 0 THEN ''
						 ELSE 'dConjoint_Embauche' + @RecSep + CONVERT(CHAR(10), S.dConjoint_Embauche, 20) 
												   + @RecSep + @CrLf
					END + 
					''
				FROM deleted S
					JOIN CTE_Human H ON H.HumanID = S.SubscriberID
					LEFT JOIN CTE_Adresse A ON A.SourceID = H.HumanID
					LEFT JOIN CTE_Phone P ON P.SourceID = A.SourceID and P.AdresseID = A.AdresseID

	INSERT INTO #DisableTrigger VALUES('TUn_Subscriber')	

	DELETE FROM S
	FROM dbo.Un_Subscriber S
		 INNER JOIN deleted D ON D.SubscriberID = S.SubscriberID

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Subscriber'
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
CREATE TRIGGER [ProAcces].[TR_Un_Subscriber_Upd] ON [ProAcces].[Un_Subscriber]
	   INSTEAD OF UPDATE
AS BEGIN
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
			
	DECLARE @TB_CespState TABLE (SubscriberID int, tiCESPState int)

	INSERT INTO @TB_CespState (SubscriberID, tiCESPState)
	SELECT D.SubscriberID, IsNull(S.tiCESPState, 0)
	  FROM deleted D JOIN dbo.Un_Subscriber S ON S.SubscriberID = D.SubscriberID

	-- *** FIN AVERTISSEMENT *** 
	INSERT INTO #DisableTrigger VALUES('TR_Un_Subscriber_Upd')	
	INSERT INTO #DisableTrigger VALUES('TUn_Subscriber')	

	UPDATE TB SET
	   RepID = I.RepID ,
        Spouse = I.Spouse ,
        Contact1 = I.Contact1 ,
        Contact1Phone = I.Contact1Phone ,
        iID_Preference_Suivi = I.iID_Preference_Suivi ,
        iID_Preference_Suivi_Siege_Social = I.iID_Preference_Suivi_Siege_Social,
        bEtats_Financiers_Annuels = I.bEtats_Financiers_Annuels ,
        bEtats_Financiers_Semestriels = I.bEtats_Financiers_Semestriels ,
        bReleve_Papier = I.bReleve_Papier ,
        vcConjoint_Employeur = I.vcConjoint_Employeur ,
        vcConjoint_Profession = I.vcConjoint_Profession ,
        dConjoint_Embauche = I.dConjoint_Embauche
	FROM
		dbo.Un_Subscriber TB INNER JOIN inserted I ON I.SubscriberID = TB.SubscriberID

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Subscriber'    

	DECLARE @SubscriberID int = 0,
			@Now datetime = GetDate(),
			@iErrorID INT,
			@NewCESPState INT

	WHILE Exists(Select Top 1 SubscriberID From inserted Where SubscriberID > @SubscriberID) BEGIN
		SELECT @SubscriberID = Min(SubscriberID) FROM inserted WHERE SubscriberID > @SubscriberID

		-- Mettre à jour l'état des prévalidations du souscripteur
		EXEC @iErrorID = dbo.psCONV_EnregistrerPrevalidationPCEE 2, NULL, NULL, @SubscriberID, NULL
		SELECT @NewCESPState = ISNULL(tiCESPState, 0) FROM dbo.Un_Subscriber WHERE SubscriberID = @SubscriberID

		-- Vérifie s'il y a des informations modifiés qui affecte les enregistrements du PCEE
		-- Appelle de la procédure stockée qui gère les enregistrements 100, 200, et 400 de toutes les conventions du souscripteur.
		IF EXISTS (SELECT TOP 1 SubscriberID FROM @TB_CespState WHERE SubscriberID = @SubscriberID AND tiCESPState <> @NewCESPState)
			EXECUTE @iErrorID = dbo.TT_UN_CESPOfConventions 2, 0, @SubscriberID, 0
	END

	DECLARE @RecSep CHAR(1) = CHAR(30)
		,	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
		,	@ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'U')
		,	@iID_Utilisateur INT = (SELECT iID_Utilisateur_Systeme FROM dbo.Un_Def)

	;WITH CTE_SubscriberNew as (
		SELECT	SubscriberID, RepID, iID_Preference_Suivi,iID_Preference_Suivi_Siege_Social, bEtats_Financiers_Annuels, bEtats_Financiers_Semestriels,
				Spouse, vcConjoint_Employeur, vcConjoint_Profession, Cast(dConjoint_Embauche as Datetime) As dConjoint_Embauche, 
				Contact1, Contact1Phone, bReleve_Papier
		FROM	inserted
	),
	CTE_SubscriberOld as (
		SELECT	SubscriberID, RepID, iID_Preference_Suivi,iID_Preference_Suivi_Siege_Social, bEtats_Financiers_Annuels, bEtats_Financiers_Semestriels,
				Spouse, vcConjoint_Employeur, vcConjoint_Profession, Cast(dConjoint_Embauche as Datetime) As dConjoint_Embauche, 
				Contact1, Contact1Phone, bReleve_Papier
		FROM	deleted
	)
	INSERT INTO CRQ_Log (ConnectID, LogCodeID, LogTime, LogActionID, LogTableName, LogDesc, LogText)
		SELECT
			2, New.SubscriberID, @Now, @ActionID, 
			LogTableName = 'Un_Subscriber', 
			LogDesc = 'Souscripteur : ' + H.LastName + ', ' + H.FirstName, 
			LogText =				
				CASE WHEN IsNull(New.RepID, 0) = IsNull(Old.RepID, 0) THEN ''
					 ELSE 'RepID' + @RecSep + LTrim(Str(IsNull(Old.RepID, 0))) + @RecSep + LTrim(Str(IsNull(New.RepID, 0))) 
								  + @RecSep + ISNULL((Select LastName + ', ' + FirstName From ProAcces.Mo_Human Where HumanID = Old.RepID), '') 
								  + @RecSep + ISNULL((Select LastName + ', ' + FirstName From ProAcces.Mo_Human Where HumanID = New.RepID), '') 
								  + @RecSep + @CrLf
				END + 
				CASE WHEN IsNull(New.Spouse, '') = IsNull(Old.Spouse, '') THEN ''
					 ELSE 'Spouse' + @RecSep + LTrim(IsNull(Old.Spouse, '')) + @RecSep + LTrim(IsNull(New.Spouse, ''))
								   + @RecSep + @CrLf
				END + 
				CASE WHEN IsNull(New.Contact1, '') = IsNull(Old.Contact1, '') THEN ''
					 ELSE 'Contact1' + @RecSep + LTrim(IsNull(Old.Contact1, '')) + @RecSep + LTrim(IsNull(New.Contact1, '')) 
								     + @RecSep + @CrLf
				END + 
				CASE WHEN IsNull(New.Contact1Phone, '') = IsNull(Old.Contact1Phone, '') THEN ''
					 ELSE 'Contact1Phone' + @RecSep + LTrim(IsNull(Old.Contact1Phone, '')) + @RecSep + LTrim(IsNull(New.Contact1Phone, '')) 
										  + @RecSep + @CrLf
				END + 
				CASE WHEN IsNull(Old.iID_Preference_Suivi, 0) = IsNull(New.iID_Preference_Suivi, 0) THEN ''
					 ELSE 'PreferenceSuiviRepresentant' + @RecSep + LTrim(Str(ISNULL(Old.iID_Preference_Suivi, 0))) + @RecSep + LTrim(Str(ISNULL(New.iID_Preference_Suivi, 0)))
											  + @RecSep + ISNULL((Select vcDescription From dbo.tblCONV_PreferenceSuivi Where iID_Preference_Suivi = Old.iID_Preference_Suivi), '') 
											  + @RecSep + ISNULL((Select vcDescription From dbo.tblCONV_PreferenceSuivi Where iID_Preference_Suivi = New.iID_Preference_Suivi), '') 
											  + @RecSep + @CrLf
				END + 
				CASE WHEN IsNull(Old.iID_Preference_Suivi_Siege_Social, 0) = IsNull(New.iID_Preference_Suivi_Siege_Social, 0) THEN ''
					 ELSE 'PreferenceSuiviSiegeSocial' + @RecSep + LTrim(Str(ISNULL(Old.iID_Preference_Suivi_Siege_Social, 0))) + @RecSep + LTrim(Str(ISNULL(New.iID_Preference_Suivi_Siege_Social, 0)))
											  + @RecSep + ISNULL((Select vcDescription From dbo.tblCONV_PreferenceSuivi Where iID_Preference_Suivi = Old.iID_Preference_Suivi_Siege_Social), '') 
											  + @RecSep + ISNULL((Select vcDescription From dbo.tblCONV_PreferenceSuivi Where iID_Preference_Suivi = New.iID_Preference_Suivi_Siege_Social), '') 
											  + @RecSep + @CrLf
				END + 
				-- 2011-04-08 : + 2011-12 - CM
				CASE WHEN Old.bEtats_Financiers_Annuels = New.bEtats_Financiers_Annuels THEN ''
					 ELSE 'bEtats_Financiers_Annuels' + @RecSep + LTrim(Str(Old.bEtats_Financiers_Annuels)) + @RecSep + LTrim(Str(New.bEtats_Financiers_Annuels))
													  + @RecSep + CASE Old.bEtats_Financiers_Annuels WHEN 0 THEN 'Non' ELSE 'Oui' END 
													  + @RecSep + CASE New.bEtats_Financiers_Annuels WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep + @CrLf
				END +
				-- 2011-06-23 : + 2011-12 - CM
				CASE WHEN Old.bEtats_Financiers_Semestriels = New.bEtats_Financiers_Semestriels THEN ''
					 ELSE 'bEtats_Financiers_Semestriels' + @RecSep + LTrim(Str(Old.bEtats_Financiers_Semestriels)) + @RecSep + LTrim(Str(New.bEtats_Financiers_Semestriels))
														  + @RecSep + CASE Old.bEtats_Financiers_Semestriels WHEN 0 THEN 'Non' ELSE 'Oui' END 
														  + @RecSep + CASE New.bEtats_Financiers_Semestriels WHEN 0 THEN 'Non' ELSE 'Oui' END
														  + @RecSep + @CrLf
				END +
				CASE WHEN Old.bReleve_Papier = New.bReleve_Papier THEN ''
					 ELSE 'bReleve_Papier' + @RecSep + LTrim(Str(Old.bReleve_Papier)) + @RecSep + LTrim(Str(New.bReleve_Papier))
													 + @RecSep + CASE Old.bReleve_Papier WHEN 0 THEN 'Non' ELSE 'Oui' END 
													 + @RecSep + CASE New.bReleve_Papier WHEN 0 THEN 'Non' ELSE 'Oui' END
													 + @RecSep + @CrLf
				END +
				CASE WHEN IsNull(Old.vcConjoint_Employeur, '') = IsNull(New.vcConjoint_Employeur, '') THEN ''
					 ELSE 'vcConjoint_Employeur' + @RecSep + LTrim(IsNull(Old.vcConjoint_Employeur, ''))
												 + @RecSep + LTrim(IsNull(New.vcConjoint_Employeur, ''))
												 + @RecSep + @CrLf
				END + 
				CASE WHEN IsNull(Old.vcConjoint_Profession, '') = IsNull(New.vcConjoint_Profession, '') THEN ''
					 ELSE 'vcConjoint_Profession' + @RecSep + LTrim(IsNull(Old.vcConjoint_Profession, ''))
												  + @RecSep + LTrim(IsNull(New.vcConjoint_Profession, ''))
												  + @RecSep + @CrLf
				END + 
				CASE WHEN IsNull(Old.dConjoint_Embauche, 0) = IsNull(New.dConjoint_Embauche, 0) THEN ''
					 ELSE 'dConjoint_Embauche' + @RecSep + CONVERT(CHAR(10), IsNull(Old.dConjoint_Embauche, 0), 20)
											   + @RecSep + CONVERT(CHAR(10), IsNull(New.dConjoint_Embauche, 0), 20) 
											   + @RecSep + @CrLf
				END + 
				''
		FROM	CTE_SubscriberNew New
				JOIN CTE_SubscriberOld Old ON Old.SubscriberID = New.SubscriberID
				JOIN ProAcces.Mo_Human H ON H.HumanID = New.SubscriberID
		WHERE	IsNull(Old.RepID, 0) <> IsNull(New.RepID, 0)
				OR IsNull(Old.Spouse, '') <> IsNull(New.Spouse, '')
				OR IsNull(Old.Contact1, '') <> IsNull(New.Contact1, '')
				OR IsNull(Old.Contact1Phone, '') <> IsNull(New.Contact1Phone, '')
				OR IsNull(Old.iID_Preference_Suivi, 0) <> IsNull(New.iID_Preference_Suivi, 0)
				OR IsNull(Old.iID_Preference_Suivi_Siege_Social, 0) <> IsNull(New.iID_Preference_Suivi_Siege_Social, 0)
				OR Old.bEtats_Financiers_Annuels <> New.bEtats_Financiers_Annuels
				OR Old.bEtats_Financiers_Semestriels <> New.bEtats_Financiers_Semestriels
				OR Old.bReleve_Papier <> New.bReleve_Papier
				OR IsNull(Old.vcConjoint_Employeur, '') <> IsNull(New.vcConjoint_Employeur, '')
				OR IsNull(Old.vcConjoint_Profession, '') <> IsNull(New.vcConjoint_Profession, '')
				OR IsNull(Old.dConjoint_Embauche, 0) <> IsNull(New.dConjoint_Embauche, 0)

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_Un_Subscriber_Upd'    
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
CREATE TRIGGER [ProAcces].[TR_Un_Subscriber_Ins] ON [ProAcces].[Un_Subscriber]
	   INSTEAD OF INSERT
AS BEGIN
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
	INSERT INTO #DisableTrigger VALUES('TR_Un_Subscriber_Ins')	
	INSERT INTO #DisableTrigger VALUES('TUn_Subscriber')	

	INSERT dbo.Un_Subscriber (
		SubscriberID, RepID, Spouse, Contact1, Contact1Phone, iID_Preference_Suivi, iID_Preference_Suivi_Siege_Social, bEtats_Financiers_Annuels, bEtats_Financiers_Semestriels, 
		bReleve_Papier, vcConjoint_Employeur, vcConjoint_Profession, dConjoint_Embauche
		-- Follows not used but not nullable & without default value
		, ScholarshipLevelID, tiCESPState
	)
	SELECT
		SubscriberID, RepID, Spouse, Contact1, Contact1Phone, iID_Preference_Suivi, iID_Preference_Suivi_Siege_Social, bEtats_Financiers_Annuels, bEtats_Financiers_Semestriels, 
		bReleve_Papier, vcConjoint_Employeur, vcConjoint_Profession, dConjoint_Embauche
		-- Follows not used but not nullable & without default value
		, 'UNK', 0
	FROM
		INSERTED

	IF EXISTS(Select Top 1 * From dbo.Un_Subscriber S JOIN inserted I ON I.SubscriberID = S.SubscriberID Where S.StateID is Null)
		UPDATE S
		   SET S.StateID = A.iID_Province,
			   S.AddressLost = A.bInvalide
		  FROM dbo.Un_Subscriber S JOIN inserted I ON I.SubscriberID = S.SubscriberID
			   JOIN tblGENE_Adresse A ON A.iID_Source = S.SubscriberID AND A.dtDate_Debut <= GETDATE()
		 WHERE S.StateID IS NULL OR S.AddressLost <> A.bInvalide

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Subscriber'

	DECLARE @SubscriberID int = 0,
			@NewCESPState INT,
			@iErrorID int

	WHILE Exists(Select Top 1 SubscriberID From inserted Where SubscriberID > @SubscriberID) BEGIN
		SELECT @SubscriberID = Min(SubscriberID) FROM inserted WHERE SubscriberID > @SubscriberID
		
		-- Mettre à jour l'état des prévalidations du souscripteur
		EXEC @iErrorID = dbo.psCONV_EnregistrerPrevalidationPCEE 2, NULL, NULL, @SubscriberID, NULL
		SELECT @NewCESPState = ISNULL(tiCESPState, 0) FROM dbo.Un_Subscriber WHERE SubscriberID = @SubscriberID
	END

	DECLARE @Now datetime = GetDate()
		, 	@RecSep CHAR(1) = CHAR(30)
		, 	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
		, 	@ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'I')

	;WITH CTE_Human (HumanID, FirstName, LastName, SexID, LangID, SocialNumber, PaysID_Origine, BirthDate, DeathDate) 
	as (
		SELECT HumanID, FirstName, LastName, SexID, LangID, SocialNumber, cID_Pays_Origine, BirthDate, DeathDate
		  FROM inserted I
				JOIN ProAcces.Mo_Human H ON H.HumanID = I.SubscriberID
	)
	INSERT INTO CRQ_Log (ConnectID, LogTableName, LogCodeID, LogTime, LogActionID, LogDesc, LogText)
			SELECT
				2, 'Un_Subscriber', SubscriberID, @Now, @ActionID, 
				LogDesc = 'Souscripteur : ' + H.LastName + ', ' + H.FirstName, 
				LogText =				
					CASE WHEN ISNULL(H.FirstName, '') = '' THEN ''
						 ELSE 'FirstName' + @RecSep + H.FirstName + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(H.LastName, '') = '' THEN ''
						 ELSE 'LastName' + @RecSep + H.LastName + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(H.BirthDate, 0) <= 0 THEN ''
						 ELSE 'BirthDate' + @RecSep + CONVERT(CHAR(10), H.BirthDate, 20) + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(H.DeathDate, 0) <= 0 THEN ''
						 ELSE 'DeathDate' + @RecSep + CONVERT(CHAR(10), H.DeathDate, 20) + @RecSep + @CrLf
					END + 
					'LangID' + @RecSep + H.LangID
 							 + @RecSep + IsNull((Select LangName From  dbo.Mo_Lang Where LangID = H.LangID), '')
							 + @RecSep + @CrLf + 
					'SexID' + @RecSep + H.SexID
 							+ @RecSep + IsNull((Select SexName From  dbo.Mo_Sex Where LangID = 'FRA' AND SexID = H.SexID), '')
							+ @RecSep + @CrLf + 
					CASE WHEN ISNULL(H.SocialNumber, '') = '' THEN ''
							ELSE 'SocialNumber' + @RecSep + H.SocialNumber + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(H.PaysID_Origine, '') = '' THEN ''
						 ELSE 'cID_Pays_Origine' + @RecSep + H.PaysID_Origine
											     + @RecSep + IsNull((Select CountryName From Mo_Country WHERE CountryID = H.PaysID_Origine), '')
											     + @RecSep + @CrLf
					END +
					CASE WHEN ISNULL(S.RepID, 0) <= 0 THEN ''
						 ELSE 'RepID' + @RecSep + LTrim(Str(S.RepID)) 
									  + @RecSep + (Select ISNULL(LastName, '') + ', ' + IsNull(FirstName, '') FROM dbo.Mo_Human Where HumanID = S.RepID)
									  + @RecSep + @CrLf
					END + 
					CASE WHEN IsNull(S.Spouse, '') = '' THEN ''
						 ELSE 'Spouse' + @RecSep + LTrim(S.Spouse)
									   + @RecSep + @CrLf
					END + 
					CASE WHEN IsNull(S.Contact1, '') = '' THEN ''
						 ELSE 'Contact1' + @RecSep + LTrim(S.Contact1)
									     + @RecSep + @CrLf
					END + 
					CASE WHEN IsNull(S.Contact1Phone, '') = '' THEN ''
						 ELSE 'Contact1Phone' + @RecSep + LTrim(S.Contact1Phone)
											  + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(S.iID_Preference_Suivi, 0) <= 0 THEN ''
						 ELSE 'PreferenceSuiviRepresentant' + @RecSep + LTrim(Str(ISNULL(S.iID_Preference_Suivi, 0)))
												  + @RecSep + ISNULL((Select vcDescription From tblCONV_PreferenceSuivi Where iID_Preference_Suivi = S.iID_Preference_Suivi), '')
												  + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(S.iID_Preference_Suivi_Siege_Social, 0) <= 0 THEN ''
						 ELSE 'PreferenceSuiviSiegeSocial' + @RecSep + LTrim(Str(ISNULL(S.iID_Preference_Suivi_Siege_Social, 0)))
												  + @RecSep + ISNULL((Select vcDescription From tblCONV_PreferenceSuivi Where iID_Preference_Suivi = S.iID_Preference_Suivi_Siege_Social), '')
												  + @RecSep + @CrLf
					END + 
					-- 2011-04-08 : + 2011-12 - CM
					'bEtats_Financiers_Annuels' + @RecSep 
						+ CASE WHEN ISNULL(S.bEtats_Financiers_Annuels, 0) = 1 THEN 'Oui' ELSE 'Non' END + @RecSep + @CrLf + 
					-- 2011-06-23 : + 2011-12 - CM
					'bEtats_Financiers_Semestriels' + @RecSep 
						+ CASE WHEN ISNULL(S.bEtats_Financiers_Semestriels, 0) = 1 THEN 'Oui' ELSE 'Non' END + @RecSep + @CrLf + 					
					'bReleve_Papier' + @RecSep 
						+ CASE WHEN ISNULL(S.bReleve_Papier, 0) = 1 THEN 'Oui' ELSE 'Non' END + @RecSep + @CrLf + 
					CASE WHEN IsNull(S.vcConjoint_Employeur, '') = '' THEN ''
						 ELSE 'vcConjoint_Employeur' + @RecSep + LTrim(S.vcConjoint_Employeur)
													 + @RecSep + @CrLf
					END + 
					CASE WHEN IsNull(S.vcConjoint_Profession, '') = '' THEN ''
						 ELSE 'vcConjoint_Profession' + @RecSep + LTrim(S.vcConjoint_Profession)
													  + @RecSep + @CrLf
					END + 
					CASE WHEN ISNULL(CAST(S.dConjoint_Embauche as datetime), 0) <= 0 THEN ''
						 ELSE 'dConjoint_Embauche' + @RecSep + CONVERT(CHAR(10), S.dConjoint_Embauche, 20) 
										  + @RecSep + @CrLf
					END + 
					''
				FROM inserted S
					JOIN CTE_Human H ON H.HumanID = S.SubscriberID

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_Un_Subscriber_Ins'
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue réprsentant l''ancienne table dbo.Un_Subscriber qui a été recréée dans le schema ProAcces', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Subscriber';

