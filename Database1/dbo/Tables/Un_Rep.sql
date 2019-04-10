CREATE TABLE [dbo].[Un_Rep] (
    [RepID]                           [dbo].[MoID]         NOT NULL,
    [RepCode]                         [dbo].[MoDescoption] NULL,
    [RepLicenseNo]                    [dbo].[MoDescoption] NULL,
    [BusinessStart]                   [dbo].[MoDateoption] NULL,
    [BusinessEnd]                     [dbo].[MoDateoption] NULL,
    [HistVerifConnectID]              [dbo].[MoIDoption]   NULL,
    [StopRepComConnectID]             [dbo].[MoIDoption]   NULL,
    [iNumeroBDNI]                     INT                  NULL,
    [bProgrammePreretraite]           BIT                  NULL,
    [vcConditionMaintientInscription] VARCHAR (500)        NULL,
    [dtInscription]                   DATE                 NULL,
    [vcPlumitif]                      VARCHAR (500)        NULL,
    [dtPhoto]                         DATE                 NULL,
    [dtSignatureElectronique]         DATE                 NULL,
    [vcAssurance]                     VARCHAR (3)          NULL,
    [dtEcheanceAssurance]             DATE                 NULL,
    [vcRegimeEmploi]                  VARCHAR (2)          NULL,
    [vcAutreEmployeurActuel]          VARCHAR (60)         NULL,
    [vcAdresseAutreEmploi]            VARCHAR (200)        NULL,
    [vcTelephoneAutreEmploi]          VARCHAR (20)         NULL,
    [vcAnalysteAmf]                   VARBINARY (200)      NULL,
    [dtDemandeInscriptionAmf]         DATE                 NULL,
    [iAnneeQualificationProgrPreRetr] INT                  NULL,
    [iNiveauProgrPreRetr]             INT                  NULL,
    [bEstSuspendu]                    DATETIME             NULL,
    [dtAbandonCandidat]               DATETIME             NULL,
    [EstBloqueCommissionSuivi]        BIT                  CONSTRAINT [DF__Un_Rep__EstBloqu__19C00FA4] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Un_Rep] PRIMARY KEY CLUSTERED ([RepID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_Rep_Mo_Human__RepID] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Rep_RepCode]
    ON [dbo].[Un_Rep]([RepCode] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Rep_RepID_RepCode]
    ON [dbo].[Un_Rep]([RepID] ASC, [RepCode] ASC)
    INCLUDE([BusinessEnd]) WITH (FILLFACTOR = 90);


GO
/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TR_UnRep_Upd
						
Historique des modifications:
		Date			Programmeur				Description									Référence
		------------	----------------------	-----------------------------------------	------------
		2017-05-30	    Pierre-Luc Simard		Ajout du champ EstBloqueCommissionSuivi
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TR_UnRep_Upd] ON [dbo].[Un_Rep]
FOR UPDATE
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
	
	---------------------------------------------
	-- TRIGGER DE MISE · JOUR DE LA TABLE Un_Rep
	---------------------------------------------

	IF UPDATE(BusinessEnd)
		/* On affecte la date de fin du repr‚sentant … celui de l'usager */
		UPDATE Mo_User 
		   SET TerminatedDate = I.BusinessEnd
		  FROM INSERTED I
			   INNER JOIN DELETED D ON I.RepID = D.RepID
		 WHERE Mo_User.UserID = D.RepID

	DECLARE @Now datetime = GetDate()
		,	@RecSep CHAR(1) = CHAR(30)
		,	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
		,	@ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'U')

	INSERT INTO CRQ_Log (ConnectID, LogCodeID, LogTime, LogActionID, LogTableName, LogDesc, LogText)
		SELECT	IsNull(H.LastUpdateConnectID, 1), New.RepID, @Now, @ActionID, 
				LogTableName = 'Un_Rep', 
				LogDesc = 'Représentant : ' + H.LastName + ', ' + H.FirstName, 
				LogText = CASE WHEN ISNULL(Old.RepCode, '') = ISNULL(New.RepCode, '') THEN ''
							   ELSE 'RepCode' + @RecSep + ISNULL(Old.RepCode,'')
											  + @RecSep + ISNULL(New.RepCode,'')
											  + @RecSep + @CrLf
						  END +
						  CASE WHEN ISNULL(Old.RepLicenseNo, '') = ISNULL(New.RepLicenseNo, '') THEN ''
							   ELSE 'RepLicenseNo' + @RecSep + ISNULL(Old.RepLicenseNo,'')
												   + @RecSep + ISNULL(New.RepLicenseNo,'')
												   + @RecSep + @CrLf
						  END +
						  CASE WHEN ISNULL(Old.BusinessStart, 0) = ISNULL(New.BusinessStart, 0) THEN ''
							   ELSE 'BusinessStart' + @RecSep + CONVERT(CHAR(10), ISNULL(Old.BusinessStart, 0), 20)
												    + @RecSep + CONVERT(CHAR(10), ISNULL(New.BusinessStart, 0), 20)
													+ @RecSep + @CrLf
						  END +
						  CASE WHEN ISNULL(Old.BusinessEnd, 0) = ISNULL(New.BusinessEnd, 0) THEN ''
							   ELSE 'BusinessEnd' + @RecSep + CONVERT(CHAR(10), ISNULL(Old.BusinessEnd, 0), 20)
												  + @RecSep + CONVERT(CHAR(10), ISNULL(New.BusinessEnd, 0), 20)
												  + @RecSep + @CrLf
						  END +
						  CASE WHEN ISNULL(Old.iNumeroBDNI, 0) = ISNULL(New.iNumeroBDNI, 0) THEN ''
							   ELSE 'iNumeroBDNI' + @RecSep + LTrim(Str(Old.iNumeroBDNI))
												  + @RecSep + LTrim(Str(New.iNumeroBDNI))
												  + @RecSep + @CrLf
                          END +
                     	  CASE WHEN Old.EstBloqueCommissionSuivi = New.EstBloqueCommissionSuivi THEN ''
					           ELSE 'EstBloqueCommissionSuivi' + @RecSep + LTrim(Str(Old.EstBloqueCommissionSuivi)) + @RecSep + LTrim(Str(New.EstBloqueCommissionSuivi))
											      + @RecSep + CASE Old.EstBloqueCommissionSuivi WHEN 0 THEN 'Non' ELSE 'Oui' END 
												  + @RecSep + CASE New.EstBloqueCommissionSuivi WHEN 0 THEN 'Non' ELSE 'Oui' END
												  + @RecSep + @CrLf
						  END +
						  ''
		FROM	inserted New
				JOIN dbo.Mo_Human H ON H.HumanID = New.RepID
				JOIN deleted Old ON Old.RepID = New.RepID
		WHERE	ISNULL(Old.RepCode, '') <> ISNULL(New.RepCode, '')
				Or ISNULL(Old.RepLicenseNo, '') <> ISNULL(New.RepLicenseNo, '')
				Or ISNULL(Old.BusinessStart, 0) <> ISNULL(New.BusinessStart, 0)
				Or ISNULL(Old.BusinessEnd, 0) <> ISNULL(New.BusinessEnd, 0)
				Or ISNULL(Old.iNumeroBDNI, 0) <> ISNULL(New.iNumeroBDNI, 0)
                Or ISNULL(Old.EstBloqueCommissionSuivi, 0) <> ISNULL(New.EstBloqueCommissionSuivi, 0)
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END
GO

CREATE TRIGGER [dbo].[TUn_Rep] ON [dbo].[Un_Rep] FOR INSERT, UPDATE 
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

  UPDATE Un_Rep SET
    BusinessStart = dbo.fn_Mo_DateNoTime( i.BusinessStart),
    BusinessEnd = dbo.fn_Mo_DateNoTime( i.BusinessEnd)
  FROM Un_Rep U, inserted i
  WHERE U.RepID = i.RepID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO

CREATE TRIGGER [dbo].[TR_UnRep_Del] ON [dbo].[Un_Rep]
FOR DELETE AS 
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
	
	---------------------------------------------
	-- TRIGGER DE SUPPRESSION DE LA TABLE Un_Rep
	---------------------------------------------

	/* On d‚sactive l'usager correspondant */
	UPDATE Mo_User 
	SET TerminatedDate = GETDATE()
	FROM DELETED D
	WHERE Mo_User.UserID = D.RepID

	DECLARE @Now datetime = GetDate()
		,	@RecSep CHAR(1) = CHAR(30)
		,	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
		,	@ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'D')

	INSERT INTO CRQ_Log (ConnectID, LogCodeID, LogTime, LogActionID, LogTableName, LogDesc, LogText)
		SELECT	IsNull(H.LastUpdateConnectID, 1), Old.RepID, @Now, @ActionID, 
				LogTableName = 'Un_Rep', 
				LogDesc = 'Représentant : ' + H.LastName + ', ' + H.FirstName, 
				LogText = 'RepCode' + @RecSep + ISNULL(Old.RepCode,'') + @RecSep + @CrLf +
						  'RepLicenseNo' + @RecSep + ISNULL(Old.RepLicenseNo,'') + @RecSep + @CrLf +
						  'BusinessStart' + @RecSep + CONVERT(CHAR(10), ISNULL(Old.BusinessStart, 0), 20) + @RecSep + @CrLf +
						  'BusinessEnd' + @RecSep + CONVERT(CHAR(10), ISNULL(Old.BusinessEnd, 0), 20) + @RecSep + @CrLf +
						  'iNumeroBDNI' + @RecSep + LTrim(Str(Old.iNumeroBDNI)) + @RecSep + @CrLf +
						  ''
		FROM	deleted Old
				JOIN dbo.Mo_Human H ON H.HumanID = Old.RepID

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TR_UnRep_Ins
						
Historique des modifications:
		Date			Programmeur				Description									Référence
		------------	----------------------	-----------------------------------------	------------
		2017-05-30	    Pierre-Luc Simard		Ajout du champ EstBloqueCommissionSuivi
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TR_UnRep_Ins] ON [dbo].[Un_Rep]
FOR INSERT AS 
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

	------------------------------------
	-- TRIGGER D'AJOUT TABLE Un_Rep
	------------------------------------

	/* Préparation des infos du représentant à ajouter dans la table d'usager */
	SELECT
		H.HumanID,
		/* on remplace tous les caractères avec les accents par les même caractères sans accent en minuscules */
		LoginNameID = dbo.FN_CrqReplaceSpecialChar(

			/* Ajoute la 1re lettre du prénom */
			 LEFT(H.Firstname,1) + 
				/* Si c'est un prénom composé, ajoute la 1re lettre du 2e prénom */
				CASE 
					WHEN CHARINDEX('-', H.Firstname) > 0 THEN 
						SUBSTRING(H.Firstname, CHARINDEX('-', H.Firstname)+1, 1) 
					ELSE 
						'' 
				END + 
				/* Si le nom de famille est composé, on ajoute la 1re lettre du premier nom, suivi du 2e nom */
				/* Si le nom de famille est une serie de nom séparé par des espaces, on met le 1er nom trouvé */
				/* Sinon, on met simplement le nom de famille au complet */
				CASE 
					WHEN CHARINDEX('-', H.LastName) > 0 THEN 
						LEFT(H.LastName,1) + SUBSTRING(H.LastName, CHARINDEX('-', H.LastName)+1, LEN(H.LastName) - CHARINDEX('-', H.LastName)+1) 
					WHEN CHARINDEX(' ', RTRIM(LastName)) > 0 THEN 
						SUBSTRING(H.Lastname, 1, CHARINDEX(' ', H.Lastname)-1) 
					ELSE 
						H.LastName 
				END
		),
		PassWordID = dbo.fn_Mo_encrypt( dbo.FN_CrqReplaceSpecialChar(LEFT(H.LastName,1)) + ISNULL(LEFT(CONVERT(varchar(9),H.SocialNumber),6),'')),
		codeID = G.UserGroupID, -- Indique que c'est un rep
		PassWordDate = GetDate(),
		TerminatedDate = I.BusinessEnd,
		PassWordEndDate = GetDate() -- le password devra être changé au prochain login
	INTO #UserRep
	FROM INSERTED I
	INNER JOIN dbo.Mo_Human H
		ON I.RepID = H.HumanID
	CROSS JOIN (SELECT UserGroupID FROM Mo_UserGroup WHERE UserGroupDesc = 'Représentant') G
	WHERE ISNULL(BusinessEnd, GETDATE() + 1) > GETDATE() -- le représentant travaille toujours
		AND H.HumanID NOT IN (SELECT UserID FROM Mo_User) -- le représentant ne doit pas être déjà un usager
	ORDER BY H.HumanID

	/* Vérification si le login créé n'est pas déjà existant dans la table d'usager */
	IF EXISTS (SELECT U.UserID FROM #UserRep R INNER JOIN Mo_User U ON R.LoginNameID = U.LoginNameID)
	BEGIN

		DECLARE @Len int, @i int

		SELECT @Len = MIN(LoginLen), 
			@i = 1 
		FROM (	SELECT LoginLen = LEN(H.FirstName) 
				FROM #UserRep R 
				INNER JOIN dbo.Mo_Human H 
					ON R.HumanID = H.HumanID 
				INNER JOIN Mo_User U 
					ON R.LoginNameID = U.LoginNameID
			)A

		/* Boucle tant qu'il y a des doublons et qu'on a pas dépassé le nombre de lettre du prénom */
		WHILE EXISTS (SELECT U.UserID FROM #UserRep R INNER JOIN Mo_User U ON R.LoginNameID = U.LoginNameID) AND @i <= @Len
		BEGIN
			/* Modification du login afin de ne pas avoir de doublon dans la table d'usager */
			UPDATE #UserRep
			SET LoginNameID = LEFT(R.LoginNameID,@i) + RTRIM(dbo.FN_CrqReplaceSpecialChar(SUBSTRING(H.FirstName + ' ', @i+1, no-1))) + SUBSTRING(R.LoginNameID, @i+1, LEN(R.LoginNameID)-1) 
			FROM (
					SELECT no = SUM(no), R.LoginNameID, R.HumanID
					FROM (SELECT no = 1, * FROM #UserRep) R
					INNER JOIN (SELECT R.* FROM #UserRep R 
								-----
								UNION
								-----
								SELECT 0,
									U.LoginNameID ,
									U.PassWordID ,
									U.codeID ,
									U.PassWordDate ,
									U.TerminatedDate ,
									U.PassWordEndDate 
								FROM #UserRep R 
								INNER JOIN Mo_User U 
									ON R.LoginNameID = U.LoginNameID
								) RR
						ON R.LoginNameID = RR.LoginNameID
							AND R.HumanID >= RR.HumanID
					GROUP BY R.LoginNameID, R.HumanID
					HAVING SUM(no) > 1
				) R
			INNER JOIN dbo.Mo_Human H 
				ON R.HumanID = H.HumanID
			WHERE #UserRep.HumanID = R.HumanID

			SET @i = @i + 1
		END

		/* On n'a plus assez de lettres afin de différencier des logins identiques (probablement très rare) */
		IF @i > @Len
			/* Concatène '2' au login en double */
			UPDATE #UserRep 
			SET LoginNameID = T.LoginNameID + '2'
			FROM (
					SELECT TOP 1 LLEN = LEN(U.LoginNameID), U.LoginNameID, R.HumanID
					FROM #UserRep R 
					INNER JOIN Mo_User U
						ON U.LoginNameID LIKE R.LoginNameID + '2%'
							OR U.LoginNameID = R.LoginNameID 
					ORDER BY LEN(U.LoginNameID) DESC
				) T
			WHERE #UserRep.HumanID = T.HumanID
	END

	/* Ajout du représentant dans la table d'usager */
	INSERT Mo_User (	UserID,
						LoginNameID,
						PassWordID,
						CodeID,
						PassWordDate,

						TerminatedDate,
						PassWordEndDate
					)
	SELECT HumanID,
		LoginNameID,
		PassWordID,
		codeID,
		PassWordDate,
	
		TerminatedDate,
		PassWordEndDate
	FROM #UserRep	

	/* Suppression de la table temporaire */
	DROP TABLE #UserRep

	DECLARE @Now datetime = GetDate()
		,	@RecSep CHAR(1) = CHAR(30)
		,	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
		,	@ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'I')

	INSERT INTO CRQ_Log (ConnectID, LogCodeID, LogTime, LogActionID, LogTableName, LogDesc, LogText)
		SELECT	IsNull(H.LastUpdateConnectID, 1), New.RepID, @Now, @ActionID, 
				LogTableName = 'Un_Rep', 
				LogDesc = 'Représentant : ' + H.LastName + ', ' + H.FirstName, 
				LogText = CASE WHEN ISNULL(New.RepCode, '') = '' THEN ''
							   ELSE 'RepCode' + @RecSep + ISNULL(New.RepCode,'')
											  + @RecSep + @CrLf
						  END +
						  CASE WHEN ISNULL(New.RepLicenseNo, '') = '' THEN ''
							   ELSE 'RepLicenseNo' + @RecSep + ISNULL(New.RepLicenseNo,'')
												   + @RecSep + @CrLf
						  END +
						  CASE WHEN ISNULL(New.BusinessStart, 0) = 0 THEN ''
							   ELSE 'BusinessStart' + @RecSep + CONVERT(CHAR(10), ISNULL(New.BusinessStart, 0), 20)
													+ @RecSep + @CrLf
						  END +
						  CASE WHEN ISNULL(New.BusinessEnd, 0) = 0 THEN ''
							   ELSE 'BusinessEnd' + @RecSep + CONVERT(CHAR(10), ISNULL(New.BusinessEnd, 0), 20)
												  + @RecSep + @CrLf
						  END +
						  CASE WHEN ISNULL(New.iNumeroBDNI, 0) = 0 THEN ''
							   ELSE 'iNumeroBDNI' + @RecSep + LTrim(Str(New.iNumeroBDNI))
												  + @RecSep + @CrLf
						  END +
                          'EstBloqueCommissionSuivi' + @RecSep 
						       + CASE WHEN ISNULL(New.EstBloqueCommissionSuivi, 0) = 1 THEN 'Oui' ELSE 'Non' END + @RecSep + @CrLf + 
						  ''
		FROM	inserted New
				JOIN dbo.Mo_Human H ON H.HumanID = New.RepID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des représentants.  Contient uniquement les informations propre au représentant.  Le reste des informations sont dans l''humain (Mo_Human) et dans l''adresse (Mo_Adr).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Rep';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant.  Est aussi un HumanID (Mo_Human) unique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Rep', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code du représentant.  Le code est l''identifiant unique d''un représentant chez Gestion Universitas.  C''est comme le numéro d''employé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Rep', @level2type = N'COLUMN', @level2name = N'RepCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de license de ventes du représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Rep', @level2type = N'COLUMN', @level2name = N'RepLicenseNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Début des affaires chez Gestion Universitas.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Rep', @level2type = N'COLUMN', @level2name = N'BusinessStart';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Fin des affaires chez Gestion Universitas.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Rep', @level2type = N'COLUMN', @level2name = N'BusinessEnd';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion (Mo_Connect.ConnectID) de l''usager qui a vérifier l''historique des boss et des niveaux de ce représentant. NULL=Personne ne l''a vérifié.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Rep', @level2type = N'COLUMN', @level2name = N'HistVerifConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion (Mo_Connect.ConnectID) de l''usager qui a arrêté le paiement de commissions pour ce représentant. Null : payer les commissions, <> Null : ne pas payer de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Rep', @level2type = N'COLUMN', @level2name = N'StopRepComConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro BDNI', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Rep', @level2type = N'COLUMN', @level2name = N'iNumeroBDNI';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Régime d''emploi (Temps complet = C, Temps partiel = P)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Rep', @level2type = N'COLUMN', @level2name = N'vcRegimeEmploi';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le représentant est bloqué au niveau du calcul de la commission de suivi.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Rep', @level2type = N'COLUMN', @level2name = N'EstBloqueCommissionSuivi';

