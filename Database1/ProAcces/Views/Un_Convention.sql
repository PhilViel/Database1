CREATE VIEW [ProAcces].[Un_Convention]
AS
    SELECT
        ConventionID, PlanID, SubscriberID, BeneficiaryID, ConventionNo, FirstPmtDate, PmtTypeID, bACESGRequested, bCLBRequested, tiRelationshipTypeID, 
        bSouscripteur_Desire_IQEE, dtDateProspectus, SCEEFormulaire93Recu, SCEEAnnexeBTuteurRecue, SCEEAnnexeBConfTuteurRecue, SCEEAnnexeBPRespRecue, SCEEAnnexeBConfPRespRecue,
        SCEEFormulaire93SCEEPlusRefusee, SCEEFormulaire93BECRefuse, SCEEFormulaire93SCEERefusee, RaisonDernierChangementSouscripteur, 
        LienSouscripteurVersSouscripteurOriginal, TexteDiplome, IdSouscripteurOriginal, tiCESPState, SCEEAnnexeBTuteurRequise, SCEEAnnexeBPRespRequise, 
        dtRegStartDate, CoSubscriberID, tiID_Lien_CoSouscripteur, dtDate_Fermeture, iID_Raison_Fermeture, vcNote_Fermeture, tiMaximisationREEE, dtInforceDateTIN
    FROM
        dbo.Un_Convention
GO
/*******************************************************************************************************************************************************************************
Nom                 :	TR_Un_Convention_Del
Description         :	Supprimer les données de la table Un_Convention et journaliser la suppression
Valeurs de retours  :	N/A
Note                :		2016-02-15	Pierre-Luc Simard		Ajout des champs pour la fermeture
                            2016-09-13  Pierre-Luc Simard       Ajouter le champ pour la maximisation
                            2017-05-03  Steeve Picard           Ajout des champs pour la confidentialité de l'Annexe B
                            2018-09-05  Pierre-Luc Simard       Ajout de dtInforceDateTIN
*********************************************************************************************************************/
CREATE TRIGGER [ProAcces].[TR_Un_Convention_Del] ON [ProAcces].[Un_Convention]
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
		,	@RecSep CHAR(1) = CHAR(30)
		,	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
		,	@ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'D')
		,	@iID_Utilisateur INT = (SELECT iID_Utilisateur_Systeme FROM dbo.Un_Def)

	-- Insère un log de l'objet inséré.
	INSERT INTO CRQ_Log (ConnectID, LogTableName, LogCodeID, LogTime, LogActionID, LogDesc, LogText)
		SELECT
			2, 'Un_Convention', ConventionID, @Now, @ActionID, 
			LogDesc = 'Convention : ' + ConventionNo, 
			LogText = 'SubscriberID' + @RecSep + LTrim(Str(C.SubscriberID)) 
									 + @RecSep + ISNULL(S.LastName + ', ' + S.FirstName, '') 
									 + @RecSep +  @CrLf +
			'BeneficiaryID' + @RecSep + LTrim(Str(C.BeneficiaryID)) 
									  + @RecSep + ISNULL((Select LastName + ', ' + FirstName From dbo.Mo_Human Where HumanID = C.BeneficiaryID), '') 
									  + @RecSep +  @CrLf +
			'ConventionNo' + @RecSep + C.ConventionNo + @RecSep +  @CrLf +
			'PlanID' + @RecSep + LTrim(Str(C.PlanID)) 
							   + @RecSep + ISNULL((Select PlanDesc From Un_Plan Where PlanID = C.PlanID), '') 
							   + @RecSep +  @CrLf +
						+ @RecSep + @CrLf +
			'tiRelationshipTypeID' + @RecSep + LTrim(Str(C.tiRelationshipTypeID)) 
								   + @RecSep + CASE C.tiRelationshipTypeID WHEN 1 THEN 'Père/Mère'
																		   WHEN 2 THEN 'Grand-père/Grand-mère'
																		   WHEN 3 THEN 'Oncle/Tante'
																		   WHEN 4 THEN 'Frère/Soeur'
																		   WHEN 5 THEN 'Aucun lien de parenté'
																		   WHEN 6 THEN 'Autre'
																		   WHEN 7 THEN 'Organisme'
																		   ELSE ''
												END 
									+ @RecSep + @CrLf +
			'dtDateProspectus' + @RecSep + CASE WHEN ISNULL(C.dtDateProspectus, 0) <= 0 THEN ''
												ELSE CONVERT(CHAR(10), C.dtDateProspectus, 20) 
										   END + @RecSep +  @CrLf +
			'SCEEFormulaire93Recu' + @RecSep + CAST(ISNULL(C.SCEEFormulaire93Recu, 1) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEFormulaire93Recu, 1) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'SCEEAnnexeBTuteurRecue' + @RecSep + CAST(ISNULL(C.SCEEAnnexeBTuteurRecue, 1) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEAnnexeBTuteurRecue, 1) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
		    'SCEEAnnexeBConfTuteurRecue' + @RecSep + CAST(ISNULL(C.SCEEAnnexeBConfTuteurRecue, 1) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEAnnexeBConfTuteurRecue, 1) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'SCEEAnnexeBPRespRecue' + @RecSep + CAST(ISNULL(C.SCEEAnnexeBPRespRecue, 1) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEAnnexeBPRespRecue, 1) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
		    'SCEEAnnexeBConfPRespRecue' + @RecSep + CAST(ISNULL(C.SCEEAnnexeBConfPRespRecue, 1) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEAnnexeBConfPRespRecue, 1) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
            'SCEEFormulaire93SCEERefusee' + @RecSep + CAST(ISNULL(C.SCEEFormulaire93SCEERefusee, 0) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEFormulaire93SCEERefusee, 0) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'SCEEFormulaire93SCEEPlusRefusee' + @RecSep + CAST(ISNULL(C.SCEEFormulaire93SCEEPlusRefusee, 0) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEFormulaire93SCEEPlusRefusee, 0) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'SCEEFormulaire93BECRefuse' + @RecSep + CAST(ISNULL(C.SCEEFormulaire93BECRefuse, 0) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEFormulaire93BECRefuse, 0) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'bSouscripteur_Desire_IQEE' + @RecSep + CAST(ISNULL(C.bSouscripteur_Desire_IQEE, 0) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.bSouscripteur_Desire_IQEE, 0) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'TexteDiplome' + @RecSep + C.TexteDiplome
						   + @RecSep +  @CrLf +
			'FirstPmtDate' + @RecSep + CONVERT(CHAR(10), C.FirstPmtDate, 20) 
						   + @RecSep +  @CrLf +
			'PmtTypeID' + @RecSep + C.PmtTypeID 
						+ @RecSep + CASE C.PmtTypeID WHEN 'AUT' THEN 'Automatique'
													 WHEN 'CHQ' THEN 'Chèque'
													 ELSE ''
									END 
						+ @RecSep +  @CrLf +
			'bACESGRequested' + @RecSep + CAST(ISNULL(C.bACESGRequested, 1) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.bACESGRequested, 1) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'bCLBRequested' + @RecSep + CAST(ISNULL(C.bCLBRequested, 1) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.bCLBRequested, 1) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'iID_Raison_Fermeture' + @RecSep + ISNULL(LTRIM(Str(C.iID_Raison_Fermeture)), '') 
									  + @RecSep + ISNULL((SELECT R.vcRaison_Fermeture FROM dbo.tblCONV_RaisonFermeture R WHERE R.iID_Raison_Fermeture = C.iID_Raison_Fermeture),  '') 
									  + @RecSep +  @CrLf +
			'dtDate_Fermeture' + @RecSep + CASE WHEN ISNULL(C.dtDate_Fermeture, '1900-01-01') <> '1900-01-01' THEN ''
												ELSE CONVERT(CHAR(10), C.dtDate_Fermeture, 20) 
										   END + @RecSep +  @CrLf +
            'tiMaximisationREEE' + @RecSep + CAST(ISNULL(C.tiMaximisationREEE, 0) AS VARCHAR) 
										+ @RecSep + CASE ISNULL(C.tiMaximisationREEE,  0) WHEN 1 THEN 'AccéléREEE' WHEN 2 THEN 'AccéléREEE avec prêt' ELSE '' END
										+ @RecSep + @CrLf +
            'dtInforceDateTIN' + @RecSep + ISNULL(CONVERT(CHAR(10), C.dtInforceDateTIN, 20), '') 
		                + @RecSep +  @CrLf +
			''
	FROM	deleted C
			JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
			JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
			JOIN Un_Plan P ON P.PlanID = C.PlanID

	INSERT INTO #DisableTrigger VALUES('TUn_Convention')	
	INSERT INTO #DisableTrigger VALUES('TUn_Convention_State')	
	INSERT INTO #DisableTrigger VALUES('TUn_Convention_YearQualif')	
	INSERT INTO #DisableTrigger VALUES('TR_I_Un_Convention_F_dtRegStartDate')	
	INSERT INTO #DisableTrigger VALUES('TR_U_Un_Convention_F_dtRegStartDate')	
	INSERT INTO #DisableTrigger VALUES('TR_D_Un_Convention_F_dtRegStartDate')	

	DELETE FROM TB
	FROM dbo.Un_Convention TB INNER JOIN deleted D ON D.ConventionID = TB.ConventionID

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName IN ('TUn_Convention', 'TUn_Convention_State', 'TUn_Convention_YearQualif', 'TR_D_Un_Convention_F_dtRegStartDate', 'TR_I_Un_Convention_F_dtRegStartDate', 'TR_U_Un_Convention_F_dtRegStartDate')	

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END
GO
/*******************************************************************************************************************************************************************************
Nom                 :	TR_Un_Convention_Ins
Description         :	Modifier les données de la table Un_Convention et journaliser les changements
Valeurs de retours  :	N/A
Note                :		2016-02-15	Pierre-Luc Simard		Ajout des champs pour la fermeture
                            2016-09-13  Pierre-Luc Simard       Ajout du champ pour la maximisation
                            2017-05-03  Steeve Picard           Ajout des champs pour la confidentialité de l'Annexe B
                            2018-09-05  Pierre-Luc Simard       Ajout de dtInforceDateTIN
*********************************************************************************************************************/
CREATE TRIGGER [ProAcces].[TR_Un_Convention_Ins] ON [ProAcces].[Un_Convention]
	   INSTEAD OF INSERT
AS BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'

	SET NoCount ON
	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

	-- Si la table #DisableTrigger est présente,  il se pourrait que le trigger
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

	-- *** FIN AVERTISSEMENT *** 
	INSERT INTO #DisableTrigger VALUES('TR_Un_Convention_Ins')	
	INSERT INTO #DisableTrigger VALUES('TUn_Convention')	
	--INSERT INTO #DisableTrigger VALUES('TUn_Convention_State')	
	--INSERT INTO #DisableTrigger VALUES('TUn_Convention_YearQualif')	

	INSERT INTO dbo.Un_Convention (
			PlanID,  SubscriberID,  BeneficiaryID,  ConventionNo,  FirstPmtDate,  PmtTypeID,  bACESGRequested,  bCLBRequested,  tiRelationshipTypeID,  bSouscripteur_Desire_IQEE,  
			dtDateProspectus,  SCEEFormulaire93Recu,  SCEEAnnexeBTuteurRecue,  SCEEAnnexeBConfTuteurRecue,  SCEEAnnexeBPRespRecue,  SCEEAnnexeBConfPRespRecue,  SCEEFormulaire93SCEEPlusRefusee,  SCEEFormulaire93BECRefuse,  SCEEFormulaire93SCEERefusee,  
			RaisonDernierChangementSouscripteur,  IdSouscripteurOriginal,  LienSouscripteurVersSouscripteurOriginal,  TexteDiplome, tiCESPState, SCEEAnnexeBTuteurRequise, SCEEAnnexeBPRespRequise
			, bCESGRequested
			, bFormulaireRecu
			, iID_Raison_Fermeture
			, dtDate_Fermeture
			, vcNote_Fermeture
            , tiMaximisationREEE
            , dtInforceDateTIN
		)
	SELECT
			PlanID,  SubscriberID,  BeneficiaryID,  ConventionNo,  Cast(FirstPmtDate as date),  PmtTypeID,  bACESGRequested,  bCLBRequested,  tiRelationshipTypeID,  bSouscripteur_Desire_IQEE,  
			dtDateProspectus,  ISNULL(SCEEFormulaire93Recu, 0),  ISNULL(SCEEAnnexeBTuteurRecue, 0), ISNULL(SCEEAnnexeBConfTuteurRecue, 0),  ISNULL(SCEEAnnexeBPRespRecue, 0), ISNULL(SCEEAnnexeBConfPRespRecue, 0),  ISNULL(SCEEFormulaire93SCEEPlusRefusee, 0),  ISNULL(SCEEFormulaire93BECRefuse, 0),  ISNULL(SCEEFormulaire93SCEERefusee, 0),  
			RaisonDernierChangementSouscripteur,  IdSouscripteurOriginal,  LienSouscripteurVersSouscripteurOriginal,  TexteDiplome, IsNull(tiCESPState, 0), ISNULL(SCEEAnnexeBTuteurRequise, 0), ISNULL(SCEEAnnexeBPRespRequise, 0)
		  , 0
		  , CASE WHEN SCEEFormulaire93Recu = 1 THEN
			  		  CASE WHEN SCEEAnnexeBTuteurRequise = 1 THEN SCEEAnnexeBTuteurRecue 
						   ELSE 1 
					  END
			     ELSE 0 
		    END
			, iID_Raison_Fermeture
			, dtDate_Fermeture
			, vcNote_Fermeture
            , ISNULL(tiMaximisationREEE, 0)
            , CAST(dtInforceDateTIN AS DATE)

	FROM inserted

	-- Ce SELECT est obligé et doit être immédiatement après l'insertion afin que Entity Framework puisse recevoir le Id du nouveau record
	DECLARE @Id int
	SET @Id = IDENT_CURRENT('dbo.Un_Convention')
	SELECT @Id as ConventionID

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Convention'
	--IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    --    DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Convention_State'
	--IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    --    DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Convention_YearQualif'

	DECLARE @Now datetime = GetDate()
		, 	@RecSep CHAR(1) = CHAR(30)
		, 	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
		, 	@ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'I')
		, 	@iID_Utilisateur INT = (SELECT iID_Utilisateur_Systeme FROM dbo.Un_Def)

	-- Insère un log de l'objet inséré.
	INSERT INTO CRQ_Log (ConnectID,  LogTableName,  LogCodeID,  LogTime,  LogActionID,  LogDesc,  LogText)
		SELECT
			2,  'Un_Convention',  (Select ConventionID From dbo.Un_Convention Where ConventionNo = C.ConventionNo),  
			@Now,  @ActionID,  
			LogDesc = 'Convention : ' + ConventionNo,  
			LogText = 'SubscriberID' + @RecSep + LTrim(Str(C.SubscriberID)) 
									 + @RecSep + ISNULL((Select LastName + ',  ' + FirstName From dbo.Mo_Human Where HumanID = C.SubscriberID),  '') 
									 + @RecSep +  @CrLf +
			'BeneficiaryID' + @RecSep + LTrim(Str(C.BeneficiaryID)) 
									  + @RecSep + ISNULL((Select LastName + ',  ' + FirstName From dbo.Mo_Human Where HumanID = C.BeneficiaryID),  '') 
									  + @RecSep +  @CrLf +
			'ConventionNo' + @RecSep + C.ConventionNo + @RecSep +  @CrLf +
			'PlanID' + @RecSep + LTrim(Str(C.PlanID)) 
							   + @RecSep + ISNULL((Select PlanDesc From Un_Plan Where PlanID = C.PlanID),  '') 
							   + @RecSep +  @CrLf +
						+ @RecSep + @CrLf +
			'tiRelationshipTypeID' + @RecSep + LTrim(Str(C.tiRelationshipTypeID)) 
								   + @RecSep + CASE C.tiRelationshipTypeID WHEN 1 THEN 'Père/Mère'
																		   WHEN 2 THEN 'Grand-père/Grand-mère'
																		   WHEN 3 THEN 'Oncle/Tante'
																		   WHEN 4 THEN 'Frère/Soeur'
																		   WHEN 5 THEN 'Aucun lien de parenté'
																		   WHEN 6 THEN 'Autre'
																		   WHEN 7 THEN 'Organisme'
																		   ELSE ''
												END 
									+ @RecSep + @CrLf +
			'dtDateProspectus' + @RecSep + CASE WHEN ISNULL(C.dtDateProspectus,  0) <= 0 THEN ''
												ELSE CONVERT(CHAR(10),  C.dtDateProspectus,  20) 
										   END + @RecSep +  @CrLf +
			'SCEEFormulaire93Recu' + @RecSep + CAST(ISNULL(C.SCEEFormulaire93Recu,  0) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEFormulaire93Recu,  0) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'SCEEAnnexeBTuteurRecue' + @RecSep + CAST(ISNULL(C.SCEEAnnexeBTuteurRecue,  0) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEAnnexeBTuteurRecue,  0) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'SCEEAnnexeBConfTuteurRecue' + @RecSep + CAST(ISNULL(C.SCEEAnnexeBConfTuteurRecue,  0) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEAnnexeBConfTuteurRecue,  0) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'SCEEAnnexeBPRespRecue' + @RecSep + CAST(ISNULL(C.SCEEAnnexeBPRespRecue,  0) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEAnnexeBPRespRecue,  0) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'SCEEAnnexeBConfPRespRecue' + @RecSep + CAST(ISNULL(C.SCEEAnnexeBConfPRespRecue,  0) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEAnnexeBConfPRespRecue,  0) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'SCEEFormulaire93SCEERefusee' + @RecSep + CAST(ISNULL(C.SCEEFormulaire93SCEERefusee,  0) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEFormulaire93SCEERefusee,  0) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'SCEEFormulaire93SCEEPlusRefusee' + @RecSep + CAST(ISNULL(C.SCEEFormulaire93SCEEPlusRefusee,  0) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEFormulaire93SCEEPlusRefusee,  0) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'SCEEFormulaire93BECRefuse' + @RecSep + CAST(ISNULL(C.SCEEFormulaire93BECRefuse,  0) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.SCEEFormulaire93BECRefuse,  0) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'bSouscripteur_Desire_IQEE' + @RecSep + CAST(ISNULL(C.bSouscripteur_Desire_IQEE,  0) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.bSouscripteur_Desire_IQEE,  0) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'TexteDiplome' + @RecSep + C.TexteDiplome
						   + @RecSep +  @CrLf +
			'FirstPmtDate' + @RecSep + CONVERT(CHAR(10),  C.FirstPmtDate,  20) 
						   + @RecSep +  @CrLf +
			'PmtTypeID' + @RecSep + C.PmtTypeID 
						+ @RecSep + CASE C.PmtTypeID WHEN 'AUT' THEN 'Automatique'
													 WHEN 'CHQ' THEN 'Chèque'
													 ELSE ''
									END 
						+ @RecSep +  @CrLf +
			'bACESGRequested' + @RecSep + CAST(C.bACESGRequested AS VARCHAR) 
										+ @RecSep + CASE WHEN C.bACESGRequested = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'bCLBRequested' + @RecSep + CAST(ISNULL(C.bCLBRequested,  0) AS VARCHAR) 
										+ @RecSep + CASE WHEN ISNULL(C.bCLBRequested,  0) = 0 THEN 'Non' ELSE 'Oui' END 
										+ @RecSep + @CrLf +
			'iID_Raison_Fermeture' + @RecSep + ISNULL(LTRIM(Str(C.iID_Raison_Fermeture)),'') 
									  + @RecSep + ISNULL((SELECT R.vcRaison_Fermeture FROM dbo.tblCONV_RaisonFermeture R WHERE R.iID_Raison_Fermeture = C.iID_Raison_Fermeture),  '') 
									  + @RecSep +  @CrLf +
			'dtDate_Fermeture' + @RecSep + CASE WHEN ISNULL(C.dtDate_Fermeture,  '1900-01-01') <> '1900-01-01' THEN ''
												ELSE CONVERT(CHAR(10),  C.dtDate_Fermeture,  20) 
												END 
										   + @RecSep +  @CrLf +		
            'tiMaximisationREEE' + @RecSep + CAST(ISNULL(C.tiMaximisationREEE,  0) AS VARCHAR)  
			  				     + @RecSep + CASE ISNULL(C.tiMaximisationREEE,  0) WHEN 1 THEN 'AccéléREEE' WHEN 2 THEN 'AccéléREEE avec prêt' ELSE '' END
										+ @RecSep + @CrLf +							
            'dtInforceDateTIN' + @RecSep + ISNULL(CONVERT(CHAR(10),  C.dtInforceDateTIN,  20), '') 
						   + @RecSep +  @CrLf +
			''
	FROM	inserted C

	DECLARE @ConventionNo varchar(50) = '',
			@ConventionID int,
			@ConnectID int = 2,
			@tiRelationshipTypeID int,
			@tiID_Type_Relation_Souscripteur int,
			@tiLienCoSouscripteur int,
			@BeneficiaryID int

	WHILE EXISTS(Select top 1 * From inserted Where ConventionNo > @ConventionNo) BEGIN
		SELECT @ConventionNo = Min(ConventionNo) FROM Inserted WHERE ConventionNo > @ConventionNo
		SELECT @ConventionID = ConventionID FROM ProAcces.Un_Convention WHERE ConventionNo = @ConventionNo

		DECLARE @iExecResult INT

		-- Mettre à jour l'état des prévalidations et les CESRequest de la convention
		EXEC @iExecResult = psCONV_EnregistrerPrevalidationPCEE @ConnectID, @ConventionID, NULL, NULL, NULL
		--IF @iExecResult <= 0 
		--	RaisError -1

		SELECT @BeneficiaryID = BeneficiaryID,
			   @tiRelationshipTypeID = tiRelationshipTypeID,
			   @tiID_Type_Relation_Souscripteur = CASE WHEN tiRelationshipTypeID IN (1,2,4) THEN 1 ELSE 0 END
		  FROM Inserted
		 WHERE ConventionNo = @ConventionNo

		EXEC @iExecResult = dbo.psCONV_AjouterChangementBeneficiaire @ConventionID, @BeneficiaryID, 'INI', NULL, NULL, @tiID_Type_Relation_Souscripteur, @tiRelationshipTypeID, NULL, NULL
		--IF @@ERROR <> 0 OR @iExecResult < 0
		--	RaisError -6

		-- Vérifie s'il y a des informations modifiés qui affecte les enregistrements 100, 200 ou 400
		IF EXISTS (	SELECT ConventionID FROM Inserted
					 WHERE ConventionNo = @ConventionNo
						   OR SubscriberID <> 0
						   --OR IsNull(CoSubscriberID, 0) <> 0
						   OR BeneficiaryID <> 0
						   OR PlanID <> 0
						   OR tiRelationshipTypeID <> 0
				  )
		BEGIN
			-- Appelle de la procédure stockée qui gère les enregistrements 100, 200, et 400 de toutes les conventions du bénéficiaire.
			EXECUTE @iExecResult = dbo.TT_UN_CESPOfConventions @ConnectID, 0, 0, @ConventionID
			--IF @iExecResult <= 0
			--	SET RaisError -7	
		END
	END

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_Un_Convention_Ins'
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END
GO
/*******************************************************************************************************************************************************************************
Nom                 :	TR_Un_Convention_Upd
Description         :	Mettre à jour les données de la table Un-convention et journaliser les changements
Valeurs de retours  :	N/A
Note                :		2016-02-15	Pierre-Luc Simard		Ajout des champs pour la fermeture
                            2016-09-13  Pierre-Luc Simard       Ajout du champ pour la maximisation
                            2017-05-03  Steeve Picard           Ajout des champs pour la confidentialité de l'Annexe B
                            2018-09-05  Pierre-Luc Simard       Ajout de dtInforceDateTIN
*********************************************************************************************************************/
CREATE TRIGGER [ProAcces].[TR_Un_Convention_Upd] ON [ProAcces].[Un_Convention]
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
			EXEC dbo.TT_PrintDebugMsg @@PROCID, 'Trigger Ignored'
			RETURN
		END
	END

	DECLARE @Now DATETIME = GETDATE()

	DECLARE @TB_States TABLE (ConventionID INT, StateID VARCHAR(5))

	; WITH CTE_Last As (
		SELECT S.ConventionID, MAX(S.Startdate) As LastDate
		  FROM dbo.Un_ConventionConventionState S INNER JOIN Inserted I ON I.ConventionID = S.ConventionID
		 WHERE S.Startdate < @Now
		 GROUP BY S.ConventionID
	)
	INSERT INTO @TB_States (ConventionID, StateID)
	SELECT S.ConventionID, S.ConventionStateID
		FROM dbo.Un_ConventionConventionState S INNER JOIN CTE_Last L ON L.ConventionID = S.ConventionID And L.LastDate = S.StartDate

	-- *** FIN AVERTISSEMENT *** 
	INSERT INTO #DisableTrigger VALUES('TR_Un_Convention_Upd')	
	INSERT INTO #DisableTrigger VALUES('TUn_Convention')	
	--INSERT INTO #DisableTrigger VALUES('TUn_Convention_YearQualif')	
	--INSERT INTO #DisableTrigger VALUES('TR_U_Un_Convention_F_dtRegStartDate')	

	UPDATE TB SET
		 PlanID = I.PlanID
		,SubscriberID = I.SubscriberID
		,BeneficiaryID = I.BeneficiaryID
		,ConventionNo = I.ConventionNo
		,FirstPmtDate = CAST(I.FirstPmtDate AS DATE)
		,PmtTypeID = I.PmtTypeID
		,bACESGRequested = I.bACESGRequested
		,bCLBRequested = I.bCLBRequested
		,tiRelationshipTypeID = I.tiRelationshipTypeID
		,bSouscripteur_Desire_IQEE = I.bSouscripteur_Desire_IQEE
		,dtDateProspectus = I.dtDateProspectus
		,SCEEFormulaire93Recu = ISNULL(I.SCEEFormulaire93Recu, 0)
		,SCEEAnnexeBTuteurRecue = ISNULL(I.SCEEAnnexeBTuteurRecue, 0)
        ,SCEEAnnexeBConfTuteurRecue = ISNULL(I.SCEEAnnexeBConfTuteurRecue, 0)
		,SCEEAnnexeBPRespRecue = ISNULL(I.SCEEAnnexeBPRespRecue, 0)
        ,SCEEAnnexeBConfPRespRecue = ISNULL(I.SCEEAnnexeBConfPRespRecue, 0)
		,SCEEFormulaire93SCEEPlusRefusee = ISNULL(I.SCEEFormulaire93SCEEPlusRefusee, 0)
		,SCEEFormulaire93BECRefuse = ISNULL(I.SCEEFormulaire93BECRefuse, 0)
		,SCEEFormulaire93SCEERefusee = ISNULL(I.SCEEFormulaire93SCEERefusee, 0)
		,RaisonDernierChangementSouscripteur = I.RaisonDernierChangementSouscripteur
		,IdSouscripteurOriginal = I.IdSouscripteurOriginal
		,LienSouscripteurVersSouscripteurOriginal = I.LienSouscripteurVersSouscripteurOriginal
		,TexteDiplome = I.TexteDiplome
		,SCEEAnnexeBTuteurRequise = ISNULL(I.SCEEAnnexeBTuteurRequise, TB.SCEEAnnexeBTuteurRequise)
		,SCEEAnnexeBPRespRequise = ISNULL(I.SCEEAnnexeBPRespRequise, TB.SCEEAnnexeBPRespRequise)
		--,bFormulaireRecu = CASE WHEN I.SCEEFormulaire93Recu = 1 THEN
		--	  						CASE WHEN I.SCEEAnnexeBTuteurRequise = 1 THEN I.SCEEAnnexeBTuteurRecue 
		--								 ELSE 1 
		--							END
		--						ELSE 0 
		--				   END
		,dtDate_Fermeture = I.dtDate_Fermeture
		,iID_Raison_Fermeture = I.iID_Raison_Fermeture
		,vcNote_Fermeture = ISNULL(I.vcNote_Fermeture, '')
        ,tiMaximisationREEE = ISNULL(I.tiMaximisationREEE, 0) 
        ,dtInforceDateTIN = CAST(I.dtInforceDateTIN AS DATE)
	FROM dbo.Un_Convention TB INNER JOIN inserted I ON I.ConventionID = TB.ConventionID

	IF UPDATE(tiCESPState)
		UPDATE TB SET tiCESPState = I.tiCESPState
		FROM dbo.Un_Convention TB INNER JOIN inserted I ON I.ConventionID = TB.ConventionID
		WHERE I.tiCESPState IS NOT NULL

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Convention'
	--IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    --    DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_Convention_YearQualif'
	--IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
    --    DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_U_Un_Convention_F_dtRegStartDate'

	DECLARE @ConventionID int = 0,
			@ConnectID int = 2

	WHILE EXISTS(Select top 1 * From inserted Where ConventionID > @ConventionID)
	BEGIN
		SELECT @ConventionID = Min(ConventionID) FROM Inserted WHERE ConventionID > @ConventionID

		DECLARE @iExecResult INT
		
		-- Mettre à jour l'état des prévalidations et les CESRequest de la convention
		EXEC @iExecResult = psCONV_EnregistrerPrevalidationPCEE @ConnectID, @ConventionID, NULL, NULL, NULL
		--IF @iExecResult <= 0 
		--	RaisError -3

		-- Vérifier s'il y a un changement de bénéficiaire
		IF EXISTS(SELECT TOP 1 I.* FROM Inserted I INNER JOIN Deleted D ON D.ConventionID = I.ConventionID
					WHERE I.ConventionID = @ConventionID AND I.BeneficiaryID <> D.BeneficiaryID)
		BEGIN

			IF EXISTS(SELECT TOP 1 * FROM @TB_States WHERE ConventionID = @ConventionID And StateID = 'TRA')
				
				IF EXISTS(SELECT TOP 1 H.* FROM dbo.Mo_Human H INNER JOIN Deleted D ON H.HumanID = D.BeneficiaryID WHERE LTRIM(RTRIM(IsNull(H.SocialNumber, ''))) = '')
				   AND EXISTS (SELECT TOP 1 H.* FROM dbo.Mo_Human H INNER JOIN Inserted I ON H.HumanID = I.BeneficiaryID WHERE IsNull(SocialNumber, '') <> '')
				   AND EXISTS (SELECT TOP 1 H.* FROM dbo.Mo_Human H INNER JOIN Inserted I ON H.HumanID = I.SubscriberID WHERE IsNull(SocialNumber, '') <> '')
				BEGIN
					DECLARE @TB_Cotisation TABLE (UnitID int, Cotisation money, Fee money, RankPos int)
					DECLARE @UnitID int,
							@Cotisation money,
							@Fee money,
							@OperID int,
							@Pos int = 0

					INSERT INTO @TB_Cotisation (UnitID, Cotisation, Fee, RankPos)
					SELECT U.UnitID, SUM(Ct.Cotisation), SUM(Ct.Fee), Row_number() OVER (ORDER BY U.UnitID)
					  FROM dbo.Un_Unit U 
						   JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
						   JOIN Un_Oper O ON O.OperID = Ct.OperID
					 WHERE O.OperDate < @Now
					   AND U.ConventionID = @ConventionID
					 GROUP BY U.UnitID
					HAVING SUM(Ct.Cotisation) <> 0 OR SUM(Ct.Fee) <> 0

					WHILE EXISTS(Select Top 1 * From @TB_Cotisation Where RankPos > @Pos) 
					BEGIN
						SET @Pos = @Pos + 1

						SELECT @UnitID = UnitID, @Cotisation = Cotisation, @Fee = Fee
						  FROM @TB_Cotisation
						 WHERE RankPos = @Pos

						INSERT INTO dbo.Un_Oper (ConnectID, OperTypeID, OperDate)
							 VALUES (@ConnectID, 'RCB', @Now)
						
						SET @OperID = SCOPE_IDENTITY()

						INSERT INTO dbo.Un_Cotisation (OperID, UnitID, EffectDate, Cotisation, Fee, BenefInsur, SubscInsur, TaxOnInsur)
							 VALUES (@OperID, @UnitID, @Now, -@Cotisation, -@Fee, 0, 0, 0)

						INSERT INTO dbo.Un_Oper (ConnectID, OperTypeID, OperDate)
							 VALUES (@ConnectID, 'FBC', @Now)
						
						SET @OperID = SCOPE_IDENTITY()

						INSERT INTO dbo.Un_Cotisation (OperID, UnitID, EffectDate, Cotisation, Fee, BenefInsur, SubscInsur, TaxOnInsur)
							 VALUES (@OperID, @UnitID, @Now, @Cotisation, @Fee, 0, 0, 0)

						INSERT INTO dbo.Un_CESP400 (
										OperID, CotisationID, ConventionID, ConventionNo, tiCESP400TypeID, vcTransID, dtTransaction, fCotisation,
										iPlanGovRegNumber, vcSubscriberSINorEN, vcBeneficiarySIN, 
										bCESPDemand, fCESG, fACESGPart, fEAPCESG, fEAP, fPSECotisation, 
										vcPCGSINorEN, vcPCGFirstName, vcPCGLastName, tiPCGType ,fCLB ,fEAPCLB ,fPG ,fEAPPG
									)
							SELECT	@OperID, @Cotisation, @ConventionID, C.ConventionNo, 11, 'FIN', @Now, @Cotisation + @Fee,
									(Select PlanGovernmentRegNo From Un_Plan P Where P.PlanID = C.PlanID), 
									(Select SocialNumber From ProAcces.Mo_Human Where HumanID = C.SubscriberID), 
									(Select SocialNumber From ProAcces.Mo_Human Where HumanID = B.BeneficiaryID), 
									(Select bCESGRequested From dbo.Un_Convention where ConventionID = C.ConventionID), 0, 0, 0, 0, 0,
									B.vcPCGSINOrEN, B.vcPCGFirstName, B.vcPCGLastName, B.tiPCGType ,0 ,0 ,0 ,0
							  FROM	Inserted C
									INNER JOIN ProAcces.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
							 WHERE	C.ConventionID = @ConventionID
						
						DECLARE @CespID int
						SET @CespID = SCOPE_IDENTITY()

						-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
						UPDATE dbo.Un_CESP400
						   SET vcTransID = 'FIN'+CAST(@CespID AS VARCHAR(12))
						 WHERE iCESP400ID = @CespID
					END
				END
			END

		-- Vérifie s'il y a des informations modifiés qui affecte les enregistrements 100, 200 ou 400
		IF EXISTS (	SELECT TOP 1 I.* FROM Inserted I INNER JOIN Deleted D ON D.ConventionID = I.ConventionID
					 WHERE I.ConventionID = @ConventionID
							OR I.SubscriberID <> D.SubscriberID
							--OR I.CoSubscriberID <> D.CoSubscriberID
							OR I.BeneficiaryID <> D.BeneficiaryID
							OR I.PlanID <> D.PlanID
							OR I.tiRelationshipTypeID <> D.tiRelationshipTypeID )
		BEGIN
			-- Appelle de la procédure stockée qui gère les enregistrements 100, 200, et 400 de toutes les conventions du bénéficiaire.
			EXEC TT_PrintDebugMsg @@ProcID, 'TT_UN_CESPOfConventions'
			EXECUTE @iExecResult = dbo.TT_UN_CESPOfConventions @ConnectID, 0, 0, @ConventionID
		END

		IF @iExecResult <= 0
			SET @ConventionID = -7	
	END

	DECLARE @RecSep CHAR(1) = CHAR(30)
		,	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
		,	@ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'U')
		,	@iID_Utilisateur INT = (SELECT iID_Utilisateur_Systeme FROM dbo.Un_Def)

	-- Insère un log de l'objet inséré.
	INSERT INTO CRQ_Log (ConnectID, LogTableName, LogCodeID, LogTime, LogActionID, LogDesc, LogText)
		SELECT
			2, 'Un_Convention', New.ConventionID, @Now, @ActionID, 
			LogDesc = 'Convention : ' + New.ConventionNo, 
			LogText = 
				CASE WHEN Old.SubscriberID = New.SubscriberID THEN ''
					 ELSE 'SubscriberID' + @RecSep + LTrim(Str(Old.SubscriberID)) 
										 + @RecSep + LTrim(Str(New.SubscriberID)) 
										 + @RecSep + ISNULL((Select LastName + ', ' + FirstName FROM dbo.Mo_Human Where HumanID = Old.SubscriberID), '')
										 + @RecSep + ISNULL((Select LastName + ', ' + FirstName FROM dbo.Mo_Human Where HumanID = New.SubscriberID), '')
										 + @RecSep +  @CrLf
				END +
				CASE WHEN Old.BeneficiaryID = New.BeneficiaryID THEN ''
					 ELSE 'BeneficiaryID' + @RecSep + LTrim(Str(Old.BeneficiaryID)) 
										  + @RecSep + LTrim(Str(New.BeneficiaryID)) 
										  + @RecSep + ISNULL((Select LastName + ', ' + FirstName FROM dbo.Mo_Human Where HumanID = Old.BeneficiaryID), '')
										  + @RecSep + ISNULL((Select LastName + ', ' + FirstName FROM dbo.Mo_Human Where HumanID = New.BeneficiaryID), '')
										  + @RecSep +  @CrLf
				END +
				CASE WHEN Old.ConventionNo = New.ConventionNo THEN ''
					 ELSE 'ConventionNo' + @RecSep + LTrim((Old.ConventionNo)) 
										 + @RecSep + LTrim((New.ConventionNo)) 
										 + @RecSep +  @CrLf
				END +
				CASE WHEN Old.PlanID = New.PlanID THEN ''
					 ELSE 'PlanID' + @RecSep + LTrim(Str(Old.PlanID)) 
								   + @RecSep + LTrim(Str(New.PlanID)) 
								   + @RecSep + ISNULL((Select PlanDesc From Un_Plan Where PlanID = Old.PlanID), '')
								   + @RecSep + ISNULL((Select PlanDesc From Un_Plan Where PlanID = New.PlanID), '')
								   + @RecSep +  @CrLf
				END +
				CASE WHEN Old.tiRelationshipTypeID = New.tiRelationshipTypeID THEN ''
					 ELSE 'tiRelationshipTypeID' + @RecSep + LTrim(Str(Old.tiRelationshipTypeID)) 
												 + @RecSep + LTrim(Str(New.tiRelationshipTypeID)) 
												 + @RecSep + CASE Old.tiRelationshipTypeID WHEN 1 THEN 'Père/Mère'
																						   WHEN 2 THEN 'Grand-père/Grand-mère' 
																						   WHEN 3 THEN 'Oncle/Tante'
																						   WHEN 4 THEN 'Frère/Soeur'
																						   WHEN 5 THEN 'Aucun lien de parenté'
																						   WHEN 6 THEN 'Autre'
																						   WHEN 7 THEN 'Organisme'
																						   ELSE ''
															 END 
												 + @RecSep + CASE New.tiRelationshipTypeID WHEN 1 THEN 'Père/Mère'
																						   WHEN 2 THEN 'Grand-père/Grand-mère' 
																						   WHEN 3 THEN 'Oncle/Tante'
																						   WHEN 4 THEN 'Frère/Soeur'
																						   WHEN 5 THEN 'Aucun lien de parenté'
																						   WHEN 6 THEN 'Autre'
																						   WHEN 7 THEN 'Organisme'
																						   ELSE ''
															 END 
												 + @RecSep +  @CrLf
				END +
				CASE WHEN IsNull(Old.dtDateProspectus, 0) = IsNull(New.dtDateProspectus, 0) THEN ''
					 ELSE 'dtDateProspectus' + @RecSep + CASE WHEN Old.dtDateProspectus Is Null THEN '' ELSE CONVERT(CHAR(10), Old.dtDateProspectus, 20) END
											 + @RecSep + CASE WHEN New.dtDateProspectus Is Null THEN '' ELSE CONVERT(CHAR(10), New.dtDateProspectus, 20) END
											 + @RecSep +  @CrLf
				END +
				CASE WHEN ISNULL(Old.SCEEFormulaire93Recu, 0) = ISNULL(New.SCEEFormulaire93Recu, 0) THEN ''
					 ELSE 'SCEEFormulaire93Recu' + @RecSep + CAST(ISNULL(Old.SCEEFormulaire93Recu, 0) as char(1)) 
													  + @RecSep + CAST(ISNULL(New.SCEEFormulaire93Recu, 0) as char(1)) 
													  + @RecSep + CASE ISNULL(Old.SCEEFormulaire93Recu, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep + CASE ISNULL(New.SCEEFormulaire93Recu, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep +  @CrLf
				END +
				CASE WHEN ISNULL(Old.SCEEAnnexeBTuteurRecue, 0) = ISNULL(New.SCEEAnnexeBTuteurRecue, 0) THEN ''
					 ELSE 'SCEEAnnexeBTuteurRecue' + @RecSep + CAST(ISNULL(Old.SCEEAnnexeBTuteurRecue, 0) as char(1)) 
													  + @RecSep + CAST(ISNULL(New.SCEEAnnexeBTuteurRecue, 0) as char(1)) 
													  + @RecSep + CASE ISNULL(Old.SCEEAnnexeBTuteurRecue, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep + CASE ISNULL(New.SCEEAnnexeBTuteurRecue, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep +  @CrLf
				END +
				CASE WHEN ISNULL(Old.SCEEAnnexeBConfTuteurRecue, 0) = ISNULL(New.SCEEAnnexeBConfTuteurRecue, 0) THEN ''
					 ELSE 'SCEEAnnexeBConfTuteurRecue' + @RecSep + CAST(ISNULL(Old.SCEEAnnexeBConfTuteurRecue, 0) as char(1)) 
													  + @RecSep + CAST(ISNULL(New.SCEEAnnexeBConfTuteurRecue, 0) as char(1)) 
													  + @RecSep + CASE ISNULL(Old.SCEEAnnexeBConfTuteurRecue, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep + CASE ISNULL(New.SCEEAnnexeBConfTuteurRecue, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep +  @CrLf
				END +
				CASE WHEN ISNULL(Old.SCEEAnnexeBPRespRecue, 0) = ISNULL(New.SCEEAnnexeBPRespRecue, 0) THEN ''
					 ELSE 'SCEEAnnexeBPRespRecue' + @RecSep + CAST(ISNULL(Old.SCEEAnnexeBPRespRecue, 0) as char(1)) 
													  + @RecSep + CAST(ISNULL(New.SCEEAnnexeBPRespRecue, 0) as char(1)) 
													  + @RecSep + CASE ISNULL(Old.SCEEAnnexeBPRespRecue, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep + CASE ISNULL(New.SCEEAnnexeBPRespRecue, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep +  @CrLf
				END +
				CASE WHEN ISNULL(Old.SCEEAnnexeBConfPRespRecue, 0) = ISNULL(New.SCEEAnnexeBConfPRespRecue, 0) THEN ''
					 ELSE 'SCEEAnnexeBConfPRespRecue' + @RecSep + CAST(ISNULL(Old.SCEEAnnexeBConfPRespRecue, 0) as char(1)) 
													  + @RecSep + CAST(ISNULL(New.SCEEAnnexeBConfPRespRecue, 0) as char(1)) 
													  + @RecSep + CASE ISNULL(Old.SCEEAnnexeBConfPRespRecue, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep + CASE ISNULL(New.SCEEAnnexeBConfPRespRecue, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep +  @CrLf
				END +
				CASE WHEN ISNULL(Old.SCEEFormulaire93SCEERefusee, 0) = ISNULL(New.SCEEFormulaire93SCEERefusee, 0) THEN ''
					 ELSE 'SCEEFormulaire93SCEERefusee' + @RecSep + CAST(ISNULL(Old.SCEEFormulaire93SCEERefusee, 0) as char(1)) 
													  + @RecSep + CAST(ISNULL(New.SCEEFormulaire93SCEERefusee, 0) as char(1)) 
													  + @RecSep + CASE ISNULL(Old.SCEEFormulaire93SCEERefusee, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep + CASE ISNULL(New.SCEEFormulaire93SCEERefusee, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep +  @CrLf
				END +
				CASE WHEN ISNULL(Old.SCEEFormulaire93SCEEPlusRefusee, 0) = ISNULL(New.SCEEFormulaire93SCEEPlusRefusee, 0) THEN ''
					 ELSE 'SCEEFormulaire93SCEEPlusRefusee' + @RecSep + CAST(ISNULL(Old.SCEEFormulaire93SCEEPlusRefusee, 0) as char(1)) 
													  + @RecSep + CAST(ISNULL(New.SCEEFormulaire93SCEEPlusRefusee, 0) as char(1)) 
													  + @RecSep + CASE ISNULL(Old.SCEEFormulaire93SCEEPlusRefusee, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep + CASE ISNULL(New.SCEEFormulaire93SCEEPlusRefusee, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep +  @CrLf
				END +
				CASE WHEN ISNULL(Old.SCEEFormulaire93BECRefuse, 0) = ISNULL(New.SCEEFormulaire93BECRefuse, 0) THEN ''
					 ELSE 'SCEEFormulaire93BECRefuse' + @RecSep + CAST(ISNULL(Old.SCEEFormulaire93BECRefuse, 0) as char(1)) 
													  + @RecSep + CAST(ISNULL(New.SCEEFormulaire93BECRefuse, 0) as char(1)) 
													  + @RecSep + CASE ISNULL(Old.SCEEFormulaire93BECRefuse, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep + CASE ISNULL(New.SCEEFormulaire93BECRefuse, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep +  @CrLf
				END +
				CASE WHEN ISNULL(Old.bSouscripteur_Desire_IQEE, 0) = ISNULL(New.bSouscripteur_Desire_IQEE, 0) THEN ''
					 ELSE 'bSouscripteur_Desire_IQEE' + @RecSep + CAST(ISNULL(Old.bSouscripteur_Desire_IQEE, 0) as char(1)) 
													  + @RecSep + CAST(ISNULL(New.bSouscripteur_Desire_IQEE, 0) as char(1)) 
													  + @RecSep + CASE ISNULL(Old.bSouscripteur_Desire_IQEE, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep + CASE ISNULL(New.bSouscripteur_Desire_IQEE, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep +  @CrLf
				END +
				CASE WHEN ISNULL(Old.TexteDiplome, '') = ISNULL(New.TexteDiplome,'') THEN ''
					 ELSE 'TexteDiplome' + @RecSep + LTrim(ISNULL(Old.TexteDiplome, '')) 
										 + @RecSep + LTrim(ISNULL(New.TexteDiplome,'')) 
										 + @RecSep +  @CrLf
				END +
				CASE WHEN Old.FirstPmtDate = New.FirstPmtDate THEN ''
					 ELSE 'FirstPmtDate' + @RecSep + CONVERT(CHAR(10), Old.FirstPmtDate, 20) 
										 + @RecSep + CONVERT(CHAR(10), New.FirstPmtDate, 20) 
										 + @RecSep +  @CrLf
				END +
				CASE WHEN Old.PmtTypeID = New.PmtTypeID THEN ''
					 ELSE 'PmtTypeID' + @RecSep + LTrim(Old.PmtTypeID) 
									  + @RecSep + LTrim(New.PmtTypeID) 
									  + @RecSep + CASE Old.PmtTypeID WHEN 'AUT' THEN 'Automatique'
																	 WHEN 'CHQ' THEN 'Chèque'
																	 ELSE ''
												  END 
									  + @RecSep + CASE New.PmtTypeID WHEN 'AUT' THEN 'Automatique'
																	 WHEN 'CHQ' THEN 'Chèque'
																	 ELSE ''
												  END 
									  + @RecSep +  @CrLf
				END +
				CASE WHEN Old.bACESGRequested = New.bACESGRequested THEN ''
					 ELSE 'bACESGRequested' + @RecSep + CAST(Old.bACESGRequested as char(1)) 
													  + @RecSep + CAST(New.bACESGRequested as char(1)) 
													  + @RecSep + CASE Old.bACESGRequested WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep + CASE New.bACESGRequested WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep +  @CrLf
				END +
				CASE WHEN ISNULL(Old.bCLBRequested, 0) = ISNULL(New.bCLBRequested, 0) THEN ''
					 ELSE 'bCLBRequested' + @RecSep + CAST(ISNULL(Old.bCLBRequested, 0) as char(1)) 
													  + @RecSep + CAST(ISNULL(New.bCLBRequested, 0) as char(1)) 
													  + @RecSep + CASE ISNULL(Old.bCLBRequested, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep + CASE ISNULL(New.bCLBRequested, 0) WHEN 0 THEN 'Non' ELSE 'Oui' END
													  + @RecSep +  @CrLf
				END +
				CASE WHEN ISNULL(Old.iID_Raison_Fermeture, 0) = ISNULL(New.iID_Raison_Fermeture, 0)  THEN ''
					 ELSE 'iID_Raison_Fermeture' + @RecSep + ISNULL(LTRIM(Str(Old.iID_Raison_Fermeture)), '') 
										  + @RecSep + ISNULL(LTrim(Str(New.iID_Raison_Fermeture)), '')
										  + @RecSep + ISNULL((Select vcRaison_Fermeture FROM dbo.tblCONV_RaisonFermeture Where iID_Raison_Fermeture = Old.iID_Raison_Fermeture), '')
										  + @RecSep + ISNULL((Select vcRaison_Fermeture FROM dbo.tblCONV_RaisonFermeture Where iID_Raison_Fermeture = New.iID_Raison_Fermeture), '')
										  + @RecSep +  @CrLf
				END +
				CASE WHEN IsNull(Old.dtDate_Fermeture, '1900-01-01') = IsNull(New.dtDate_Fermeture, '1900-01-01') THEN ''
					 ELSE 'dtDate_Fermeture' + @RecSep + CASE WHEN Old.dtDate_Fermeture Is Null THEN '' ELSE CONVERT(CHAR(10), Old.dtDate_Fermeture, 20) END
											 + @RecSep + CASE WHEN New.dtDate_Fermeture Is Null THEN '' ELSE CONVERT(CHAR(10), New.dtDate_Fermeture, 20) END
											 + @RecSep +  @CrLf
				END +
                CASE WHEN ISNULL(Old.tiMaximisationREEE, 0) = ISNULL(New.tiMaximisationREEE, 0) THEN ''
					 ELSE 'tiMaximisationREEE' + @RecSep + CAST(ISNULL(Old.tiMaximisationREEE, 0) as char(1)) 
													  + @RecSep + CAST(ISNULL(New.tiMaximisationREEE, 0) as char(1)) 
													  + @RecSep + CASE ISNULL(Old.tiMaximisationREEE, 0) WHEN 1 THEN 'AccéléREEE' WHEN 2 THEN 'AccéléREEE avec prêt' ELSE '' END
													  + @RecSep + CASE ISNULL(New.tiMaximisationREEE, 0) WHEN 1 THEN 'AccéléREEE' WHEN 2 THEN 'AccéléREEE avec prêt' ELSE '' END
													  + @RecSep +  @CrLf
				END +
                CASE WHEN Old.dtInforceDateTIN = New.dtInforceDateTIN THEN ''
					 ELSE 'dtInforceDateTIN' + @RecSep + ISNULL(CONVERT(CHAR(10), Old.dtInforceDateTIN, 20), '') 
										 + @RecSep + ISNULL(CONVERT(CHAR(10), New.dtInforceDateTIN, 20), '') 
										 + @RecSep +  @CrLf
				END +
				''
		FROM	inserted New
				JOIN deleted Old ON Old.ConventionID = New.ConventionID
		WHERE	Old.SubscriberID <> New.SubscriberID
				OR Old.BeneficiaryID <> New.BeneficiaryID
				OR Old.ConventionNo <> New.ConventionNo
				OR Old.PlanID <> New.PlanID
				OR Old.tiRelationshipTypeID <> New.tiRelationshipTypeID
				OR ISNULL(Old.dtDateProspectus, 0) <> ISNULL(New.dtDateProspectus, 0)
				OR ISNULL(Old.SCEEFormulaire93Recu, 0) <> ISNULL(New.SCEEFormulaire93Recu, 0)
				OR ISNULL(Old.SCEEAnnexeBTuteurRecue, 0) <> ISNULL(New.SCEEAnnexeBTuteurRecue, 0)
                OR ISNULL(Old.SCEEAnnexeBConfTuteurRecue, 0) <> ISNULL(New.SCEEAnnexeBConfTuteurRecue, 0)
				OR ISNULL(Old.SCEEAnnexeBPRespRecue, 0) <> ISNULL(New.SCEEAnnexeBPRespRecue, 0)
                OR ISNULL(Old.SCEEAnnexeBConfPRespRecue, 0) <> ISNULL(New.SCEEAnnexeBConfPRespRecue, 0)
				OR ISNULL(Old.SCEEFormulaire93SCEERefusee, 0) <> ISNULL(New.SCEEFormulaire93SCEERefusee, 0)
				OR ISNULL(Old.SCEEFormulaire93SCEEPlusRefusee, 0) <> ISNULL(New.SCEEFormulaire93SCEEPlusRefusee, 0)
				OR ISNULL(Old.SCEEFormulaire93BECRefuse, 0) <> ISNULL(New.SCEEFormulaire93BECRefuse, 0)
				OR ISNULL(Old.bSouscripteur_Desire_IQEE, 0) <> ISNULL(New.bSouscripteur_Desire_IQEE, 0)
				OR ISNULL(Old.TexteDiplome, '') <> ISNULL(New.TexteDiplome, '')
				OR Old.FirstPmtDate <> New.FirstPmtDate
				OR Old.PmtTypeID <> New.PmtTypeID
				OR Old.bACESGRequested <> New.bACESGRequested
				OR ISNULL(Old.bCLBRequested, 0) <> ISNULL(New.bCLBRequested, 0)
				OR ISNULL(Old.iID_Raison_Fermeture, 0) <> ISNULL(New.iID_Raison_Fermeture, 0)
				OR ISNULL(Old.dtDate_Fermeture, '1900-01-01') <> ISNULL(New.dtDate_Fermeture, '1900-01-01')
                OR ISNULL(Old.tiMaximisationREEE, 0) <> ISNULL(New.tiMaximisationREEE, 0)
                OR ISNULL(Old.dtInforceDateTIN, '1900-01-01') <> ISNULL(New.dtInforceDateTIN, '1900-01-01')

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_Un_Convention_Upd'
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END
GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vue réprsentant l''ancienne table dbo.Un_Convention qui a été recréée dans le schema ProAcces', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPane1', @value = N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Un_Convention_1"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 327
               Right = 478
            End
            DisplayFlags = 280
            TopColumn = 39
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_DiagramPaneCount', @value = 1, @level0type = N'SCHEMA', @level0name = N'ProAcces', @level1type = N'VIEW', @level1name = N'Un_Convention';

