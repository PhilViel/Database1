CREATE TABLE [dbo].[Un_Convention] (
    [ConventionID]                             [dbo].[MoID]               IDENTITY (1, 1) NOT NULL,
    [PlanID]                                   [dbo].[MoID]               NOT NULL,
    [SubscriberID]                             [dbo].[MoID]               NOT NULL,
    [BeneficiaryID]                            [dbo].[MoID]               NOT NULL,
    [ConventionNo]                             VARCHAR (15)               NOT NULL,
    [YearQualif]                               [dbo].[MoID]               NOT NULL,
    [FirstPmtDate]                             [dbo].[MoGetDate]          NOT NULL,
    [PmtTypeID]                                [dbo].[UnPmtType]          NOT NULL,
    [ScholarshipYear]                          [dbo].[MoOrder]            NOT NULL,
    [ScholarshipEntryID]                       [dbo].[UnScholarshipEntry] NOT NULL,
    [GovernmentRegDate]                        [dbo].[MoDateoption]       NULL,
    [CoSubscriberID]                           [dbo].[MoIDoption]         NULL,
    [DiplomaTextID]                            INT                        NULL,
    [bSendToCESP]                              BIT                        CONSTRAINT [DF_Un_Convention_bSendToCESP] DEFAULT ((1)) NOT NULL,
    [bCESGRequested]                           BIT                        NOT NULL,
    [bACESGRequested]                          BIT                        NOT NULL,
    [bCLBRequested]                            BIT                        NOT NULL,
    [tiRelationshipTypeID]                     TINYINT                    NOT NULL,
    [tiCESPState]                              TINYINT                    NOT NULL,
    [dtRegStartDate]                           DATETIME                   NULL,
    [InsertConnectID]                          INT                        NULL,
    [LastUpdateConnectID]                      INT                        NULL,
    [dtRegEndDateAdjust]                       DATETIME                   NULL,
    [dtInforceDateTIN]                         DATETIME                   NULL,
    [bSouscripteur_Desire_IQEE]                BIT                        NULL,
    [iID_Destinataire_Remboursement]           INT                        CONSTRAINT [DF_Un_Convention_iIDDestinataireRemboursement] DEFAULT ((1)) NULL,
    [dtDateProspectus]                         DATETIME                   NULL,
    [vcDestinataire_Remboursement_Autre]       VARCHAR (50)               NULL,
    [tiID_Lien_CoSouscripteur]                 TINYINT                    NULL,
    [bFormulaireRecu]                          BIT                        CONSTRAINT [DF_Un_Convention_bFormulaireRecu] DEFAULT ((0)) NOT NULL,
    [iSous_Cat_ID_Resp_Prelevement]            INT                        NULL,
    [bTuteur_Desire_Releve_Elect]              BIT                        CONSTRAINT [DF_Un_Convention_bTuteurDesireReleveElect] DEFAULT ((0)) NULL,
    [iCheckSum]                                INT                        NULL,
    [vcCommInstrSpec]                          VARCHAR (150)              NULL,
    [iID_Justification_Conv_Incomplete]        INT                        NULL,
    [iAnnee_QualifPremierPAE]                  INT                        NULL,
    [dtSignature]                              DATE                       NULL,
    [dtEntreeEnVigueur]                        DATE                       NULL,
    [SCEEFormulaire93Recu]                     BIT                        CONSTRAINT [DF_Un_Convention_SCEEFormulaire93Recu] DEFAULT ((0)) NULL,
    [SCEEAnnexeBTuteurRequise]                 BIT                        CONSTRAINT [DF_Un_Convention_SCEEAnnexeBTuteurRequise] DEFAULT ((0)) NULL,
    [SCEEAnnexeBTuteurRecue]                   BIT                        CONSTRAINT [DF_Un_Convention_SCEEAnnexeBTuteurRecue] DEFAULT ((0)) NULL,
    [SCEEAnnexeBPRespRequise]                  BIT                        CONSTRAINT [DF_Un_Convention_SCEEAnnexeBPRespRequise] DEFAULT ((0)) NULL,
    [SCEEAnnexeBPRespRecue]                    BIT                        CONSTRAINT [DF_Un_Convention_SCEEAnnexeBPRespRecue] DEFAULT ((0)) NULL,
    [SCEEFormulaire93SCEEPlusRefusee]          BIT                        CONSTRAINT [DF_Un_Convention_SCEEFormulaire93SCEEPlusRefusee] DEFAULT ((0)) NULL,
    [SCEEFormulaire93BECRefuse]                BIT                        CONSTRAINT [DF_Un_Convention_SCEEFormulaire93BECRefuse] DEFAULT ((0)) NULL,
    [SCEEFormulaire93SCEERefusee]              BIT                        CONSTRAINT [DF_Un_Convention_SCEEFormulaire93SCEERefusee] DEFAULT ((0)) NULL,
    [RaisonDernierChangementSouscripteur]      INT                        NULL,
    [IdSouscripteurOriginal]                   INT                        NULL,
    [LienSouscripteurVersSouscripteurOriginal] INT                        NULL,
    [TexteDiplome]                             VARCHAR (MAX)              NULL,
    [LoginName]                                VARCHAR (75)               NULL,
    [dtDate_Fermeture]                         DATE                       NULL,
    [iID_Raison_Fermeture]                     INT                        NULL,
    [vcNote_Fermeture]                         VARCHAR (MAX)              NULL,
    [SCEEAnnexeBConfTuteurRecue]               BIT                        CONSTRAINT [DF_CONV_SCEEAnnexeBConfTuteurRecue] DEFAULT ((0)) NULL,
    [SCEEAnnexeBConfPRespRecue]                BIT                        CONSTRAINT [DF_CONV_SCEEAnnexeBConfRespRecue] DEFAULT ((0)) NULL,
    [tiMaximisationREEE]                       TINYINT                    CONSTRAINT [DF_Convention_tiMaximisationREEE] DEFAULT ((0)) NOT NULL,
    [bEstMaximisable]                          BIT                        CONSTRAINT [DF_Un_Convention_bEstMaximisable] DEFAULT ((0)) NOT NULL,
    [bEstEligiblePret]                         BIT                        CONSTRAINT [DF_Un_Convention_bEstEligileMarge] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Un_Convention] PRIMARY KEY CLUSTERED ([ConventionID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_Convention_CONV_DestinataireRemboursement__iIDDestinataireRemboursement] FOREIGN KEY ([iID_Destinataire_Remboursement]) REFERENCES [dbo].[tblCONV_DestinataireRemboursement] ([iID_Destinataire_Remboursement]),
    CONSTRAINT [FK_Un_Convention_CONV_Justification__iIDJustificationConvIncomplete] FOREIGN KEY ([iID_Justification_Conv_Incomplete]) REFERENCES [dbo].[tblCONV_Justification] ([iID_Justification]),
    CONSTRAINT [FK_Un_Convention_CONV_RaisonFermeture__iIDRaisonFermeture] FOREIGN KEY ([iID_Raison_Fermeture]) REFERENCES [dbo].[tblCONV_RaisonFermeture] ([iID_Raison_Fermeture]),
    CONSTRAINT [FK_Un_Convention_Mo_Connect__InsertConnectID] FOREIGN KEY ([InsertConnectID]) REFERENCES [dbo].[Mo_Connect] ([ConnectID]),
    CONSTRAINT [FK_Un_Convention_Mo_Connect__LastUpdateConnectID] FOREIGN KEY ([LastUpdateConnectID]) REFERENCES [dbo].[Mo_Connect] ([ConnectID]),
    CONSTRAINT [FK_Un_Convention_Un_Beneficiary__BeneficiaryID] FOREIGN KEY ([BeneficiaryID]) REFERENCES [dbo].[Un_Beneficiary] ([BeneficiaryID]),
    CONSTRAINT [FK_Un_Convention_Un_DiplomaText__DiplomaTextID] FOREIGN KEY ([DiplomaTextID]) REFERENCES [dbo].[Un_DiplomaText] ([DiplomaTextID]),
    CONSTRAINT [FK_Un_Convention_Un_Plan__PlanID] FOREIGN KEY ([PlanID]) REFERENCES [dbo].[Un_Plan] ([PlanID]),
    CONSTRAINT [FK_Un_Convention_Un_RelationshipType__tiIDLienCoSouscripteur] FOREIGN KEY ([tiID_Lien_CoSouscripteur]) REFERENCES [dbo].[Un_RelationshipType] ([tiRelationshipTypeID]),
    CONSTRAINT [FK_Un_Convention_Un_RelationshipType__tiRelationshipTypeID] FOREIGN KEY ([tiRelationshipTypeID]) REFERENCES [dbo].[Un_RelationshipType] ([tiRelationshipTypeID]),
    CONSTRAINT [FK_Un_Convention_Un_Subscriber__CoSubscriberID] FOREIGN KEY ([CoSubscriberID]) REFERENCES [dbo].[Un_Subscriber] ([SubscriberID]),
    CONSTRAINT [FK_Un_Convention_Un_Subscriber__SubscriberID] FOREIGN KEY ([SubscriberID]) REFERENCES [dbo].[Un_Subscriber] ([SubscriberID]),
    CONSTRAINT [FK_Un_Convention_Un_Unit_Sous_Cat__iSousCatIDRespPrelevement] FOREIGN KEY ([iSous_Cat_ID_Resp_Prelevement]) REFERENCES [dbo].[Un_Unit_Sous_Cat] ([iSous_Cat_ID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Convention_BeneficiaryID]
    ON [dbo].[Un_Convention]([BeneficiaryID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_Un_Convention_ConventionNo]
    ON [dbo].[Un_Convention]([ConventionNo] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Convention_FirstPmtDate]
    ON [dbo].[Un_Convention]([FirstPmtDate] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Convention_PlanID]
    ON [dbo].[Un_Convention]([PlanID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Convention_ScholarshipYear]
    ON [dbo].[Un_Convention]([ScholarshipYear] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Convention_ScholarshipEntryID]
    ON [dbo].[Un_Convention]([ScholarshipEntryID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Convention_SubscriberID]
    ON [dbo].[Un_Convention]([SubscriberID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Convention_YearQualif]
    ON [dbo].[Un_Convention]([YearQualif] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Convention_CoSubscriberID]
    ON [dbo].[Un_Convention]([CoSubscriberID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Convention_ConventionID]
    ON [dbo].[Un_Convention]([ConventionID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Convention_ConventionID_bCLBRequested]
    ON [dbo].[Un_Convention]([ConventionID] ASC, [bCLBRequested] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Convention_PlanID_ConventionID_DiplomaTextID_BeneficiaryID_SubscriberID]
    ON [dbo].[Un_Convention]([PlanID] ASC, [ConventionID] ASC, [DiplomaTextID] ASC, [BeneficiaryID] ASC, [SubscriberID] ASC)
    INCLUDE([ConventionNo]) WITH (FILLFACTOR = 90);


GO
CREATE STATISTICS [stat_Un_Convention_IQEE_1]
    ON [dbo].[Un_Convention]([ConventionID], [SubscriberID]);


GO
CREATE STATISTICS [stat_Un_Convention_IQEE_2]
    ON [dbo].[Un_Convention]([SubscriberID], [CoSubscriberID], [ConventionID]);


GO
CREATE STATISTICS [_dta_stat_165015769_1_2_18_4]
    ON [dbo].[Un_Convention]([BeneficiaryID], [ConventionID], [DiplomaTextID], [PlanID]);


GO
CREATE STATISTICS [_dta_stat_165015769_1_3_18_4_2]
    ON [dbo].[Un_Convention]([BeneficiaryID], [ConventionID], [DiplomaTextID], [PlanID], [SubscriberID]);


GO
CREATE STATISTICS [_dta_stat_165015769_3_18]
    ON [dbo].[Un_Convention]([DiplomaTextID], [SubscriberID]);


GO
CREATE STATISTICS [_dta_stat_165015769_4_18_1]
    ON [dbo].[Un_Convention]([BeneficiaryID], [ConventionID], [DiplomaTextID]);


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc
Nom                 :	TR_U_Un_Convention_F_dtRegStartDate
Description         :	Trigger enlevant date d'entrée en REEE de la convention si l'usager change le 
						bénéficiaire ou le souscripteur pour un sans NAS.
						
Note                :	
	ADX0001286	UP	2008-03-06	Bruno Lapointe			Création
	ADX0003172	UR	2008-06-25	Bruno Lapointe			Plutôt que mettre la date du jour, met une date calculée.
					2010-03-29	Jean-François Gauthier	Modification afin d'assigner à dtRegStartDate la plus petite date
														entre OperDate (Un_Oper) et EffectDate (Un_Cotisation)
					2010-10-04	Steve Gouin				Gestion du #DisableTrigger
************************************************************************************************************/
CREATE TRIGGER [dbo].[TR_U_Un_Convention_F_dtRegStartDate] ON [dbo].[Un_Convention] FOR UPDATE
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
	
	-- Gère le changement de souscripteur ou de bénéficiaire pour un sans NAS
	IF EXISTS (
		SELECT I.ConventionID
		FROM DELETED D
		JOIN INSERTED I ON I.ConventionID = D.ConventionID
		WHERE	(D.SubscriberID <> I.SubscriberID
				OR D.BeneficiaryID <> I.BeneficiaryID
				)
			AND I.dtRegStartDate IS NOT NULL -- Un date d'entrée en REEE
			AND I.tiCESPState = 0 -- Passe pas les prévalidations PCEE.
		)
		--Mise à jour des conventions si on a supprimé le premier NAS du souscripteur ou du bénéficiaire
		UPDATE C
		SET dtRegStartDate = NULL
		FROM dbo.Un_Convention C
		JOIN (
				SELECT I.ConventionID
				FROM INSERTED I
				JOIN dbo.Un_Unit U ON U.ConventionID = I.ConventionID
				LEFT JOIN Un_HumanSocialNumber S ON S.HumanID = I.SubscriberID
				LEFT JOIN Un_HumanSocialNumber B ON B.HumanID = I.BeneficiaryID
				WHERE	( S.HumanID IS NULL -- Vérifie si un NAS est manquant
						OR B.HumanID IS NULL
						)
					AND I.dtRegStartDate IS NOT NULL -- Possède une date d'entrée en REEE
/*					AND I.ConventionID IN ( -- L'état de la convention doit être "PROPOSITION" ou "TRANSITOIRE"
						SELECT 
							T.ConventionID
						FROM (-- Retourne la plus grande date de début d'un état par convention
							SELECT 
								ConventionID,
								MaxDate = MAX(StartDate)
							FROM Un_ConventionConventionState
							GROUP BY ConventionID
							) T
						JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
						WHERE CCS.ConventionStateID IN ('PRP','TRA')
						)
*/				GROUP BY I.ConventionID
				HAVING MIN(U.InForceDate) >= '2003-01-01' -- Applique la règle qui dit qu'une convention ne peut être en proposition si elle est avant le 1 janvier 2003
				) V ON V.ConventionID = C.ConventionID

	-- Gère le changement de souscripteur ou de bénéficiaire pour un avec NAS
	IF EXISTS (
		SELECT I.ConventionID
		FROM DELETED D
		JOIN INSERTED I ON I.ConventionID = D.ConventionID
		WHERE	(D.SubscriberID <> I.SubscriberID
				OR D.BeneficiaryID <> I.BeneficiaryID
				)
			AND I.dtRegStartDate IS NULL -- Pas de date d'entrée en REEE
			AND I.tiCESPState > 0 -- Passe les prévalidations PCEE.
		)
	BEGIN
		--Mise à jour des conventions si on a supprimé le premier NAS du souscripteur ou du bénéficiaire
		UPDATE C
		SET dtRegStartDate = V.dtRegStartDate
		FROM dbo.Un_Convention C
		JOIN (
			SELECT 
				C.ConventionID,
				dtRegStartDate =
					CASE
						WHEN FCB.FCBOperDate IS NOT NULL THEN FCB.FCBOperDate -- Date de l'opération FCB si pas null
						WHEN FCB.FCBOperDate IS NULL THEN									-- 2010-03-29 : JFG : S'il n'y a pas de FCB et que la date de naissance du bénéficiaire est postérieure à la date de signature de la convention, alors on prend la date de naissance
														CASE WHEN	ISNULL(MIN(h.BirthDate), '1900-01-01') > MIN(U.SignatureDate) THEN MIN(h.BirthDate)
															 ELSE	MIN(U.SignatureDate)
														END	
						ELSE MIN(U.SignatureDate)			 -- Date d'entrée en vigueur de la convention -- 2010-03-29 : JFG : Remplacer par la date de signature
					END
			FROM INSERTED INS
			JOIN dbo.Un_Convention C ON C.ConventionID = INS.ConventionID
			LEFT JOIN dbo.Mo_Human h ON C.BeneficiaryID = h.HumanID
			LEFT JOIN (
				SELECT -- Va chercher la date du FCB s'il y en a un sur la convention
					C.ConventionID,
					FCBOperDate =	CASE	-- 2010-03-29 : JFG : Sélection de la plus petite date entre OperDate et EffectDate
										WHEN MIN(O.OperDate) > MIN(Ct.EffectDate)  THEN MIN(Ct.EffectDate)
										ELSE MIN(O.OperDate)
									END
				FROM INSERTED INS
				JOIN dbo.Un_Convention C	
					ON C.ConventionID = INS.ConventionID
				INNER JOIN dbo.Mo_Human h
					ON h.HumanID = C.BeneficiaryID
				JOIN dbo.Un_Unit U 
					ON U.ConventionID = C.ConventionID
				JOIN Un_Cotisation Ct 
					ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O 
					ON O.OperID = Ct.OperID
				WHERE O.OperTypeID = 'FCB'
					AND O.OperID NOT IN (
						SELECT OperID
						FROM Un_OperCancelation
						UNION
						SELECT OperSourceID
						FROM Un_OperCancelation)
				GROUP BY C.ConventionID
				) FCB ON FCB.ConventionID = C.ConventionID
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			LEFT JOIN Un_HumanSocialNumber B ON C.BeneficiaryID = B.HumanID
			LEFT JOIN Un_HumanSocialNumber S ON C.SubscriberID = S.HumanID
			GROUP BY 
				C.ConventionNo, 
				C.ConventionID, 
				C.dtRegStartDate, 
				FCB.FCBOperDate
			HAVING ( MIN(U.SignatureDate) < '2003-01-01'	-- 2010-03-29 : JFG : Remplacer par SignatureDate
					OR ( MIN(B.EffectDate) IS NOT NULL
						AND MIN(S.EffectDate) IS NOT NULL
						)
					)
				AND ISNULL(dbo.fn_Mo_DateNoTime(C.dtRegStartDate),0) <> 
					CASE
						WHEN FCB.FCBOperDate IS NOT NULL THEN FCB.FCBOperDate 
					ELSE MIN(U.InforceDate)
					END
			) V ON V.ConventionID = C.ConventionID		
	END

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO

CREATE TRIGGER [dbo].[TUn_Convention] ON [dbo].[Un_Convention] AFTER INSERT, UPDATE 
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

	UPDATE C SET
		ConventionNo = CASE WHEN ISNULL(i.ConventionNo, '') <> '' THEN i.ConventionNo ELSE dbo.fnCONV_ObtenirNouveauNumeroConvention(i.PlanID, NULL, NULL) END,
		FirstPmtDate = dbo.fn_Mo_DateNoTime(i.FirstPmtDate),
		GovernmentRegDate = dbo.fn_Mo_DateNoTime(i.GovernmentRegDate)
	  --,	bFormulaireRecu = CASE WHEN i.SCEEFormulaire93Recu = 1 THEN
			--						CASE WHEN i.SCEEAnnexeBTuteurRequise = 1 THEN i.SCEEAnnexeBTuteurRecue 
			--								ELSE 1 
			--						END
			--					ELSE 0 
			--				END
	FROM dbo.Un_Convention C INNER JOIN inserted i ON C.ConventionID = i.ConventionID

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	TUn_Convention_State
Description         :	Calcul les états des conventions et les mettent à jour,  ce lors d'ajout de convention.
Valeurs de retours  :	N/A
Note                :						
                         2004-06-11	Bruno Lapointe		Création Point 10.23.02
	ADX0000694	IA	2005-06-03	Bruno Lapointe		Renommage des procédures TT_UN_ConventionStateForConvention
	ADX0001095	BR	2005-12-15	Bruno Lapointe		Correction mise à jour d'état suite à Deadlock.
					2010-10-04	Steve Gouin		Gestion des disable trigger par #DisableTrigger
					2017-01-18     Steeve Picard       Élimination des «Cursor» pour joindre des IDs
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TUn_Convention_State] ON [dbo].[Un_Convention] AFTER INSERT
AS
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'

	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

	-- Si la table #DisableTrigger est présente, il se pourrait que le trigger ne soit pas à exécuter
	IF object_id('tempdb..#DisableTrigger') is not null 
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	-- *** FIN AVERTISSEMENT *** 

	DECLARE @ConventionIDs VARCHAR(8000) = ''

	-- Crée une chaîne de caractère avec tout les conventions affectés
     SELECT @ConventionIDs = @ConventionIDs + CAST(ConventionID as varchar) + ','
     FROM (SELECT DISTINCT ConventionID FROM INSERTED) t

	-- Appelle la proc‚dure qui met à jour les états des conventions
	EXECUTE TT_UN_ConventionStateForConvention @ConventionIDs 

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc.
Nom                 :	TUn_Convention_YearQualif
Description         :	Trigger mettant à jour automatiquement le champ d'année de qualification
Valeurs de retours  :	N/A
Note                :	ADX0001337	IA	2007-06-04	Bruno Lapointe		Création
										2010-10-04	Steve Gouin			Gestion des disable trigger par #DisableTrigger
*********************************************************************************************************************/
CREATE TRIGGER dbo.TUn_Convention_YearQualif ON dbo.Un_Convention FOR INSERT, UPDATE 
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

	IF EXISTS ( -- Ajout
			SELECT I.ConventionID
			FROM INSERTED I
			LEFT JOIN DELETED D ON D.ConventionID = I.ConventionID
			WHERE D.ConventionID IS NULL
			)
	BEGIN
		-- Crée un table temporaire qui contiendra les années de qualifications calculées
		-- des conventions insérées.
		DECLARE @tYearQualif_Ins TABLE (
			ConventionID INT PRIMARY KEY,
			YearQualif INT NOT NULL )
			
		-- Calul les années de qualifications des conventions insérés
		INSERT INTO @tYearQualif_Ins
			SELECT 
				C.ConventionID,
				YearQualif = 
					CASE 
						WHEN P.PlanTypeID = 'IND' THEN 0 -- Si individuel = 0
					ELSE YEAR(HB.BirthDate) + P.tiAgeQualif -- Si collectif Année de la date de naissance du bénéficiaire + Age de qualification du régime.
					END
			FROM dbo.Un_Convention C
			JOIN INSERTED i ON C.ConventionID = I.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID 
			LEFT JOIN DELETED D ON D.ConventionID = I.ConventionID
			WHERE D.ConventionID IS NULL -- Conventions insérées
			
		-- Inscrit l'année de qualification calculée sur les conventions
		UPDATE C
		SET YearQualif = Y.YearQualif
		FROM dbo.Un_Convention C
		JOIN @tYearQualif_Ins Y ON Y.ConventionID = C.ConventionID
		
		-- InsŠre un historique d'année de qualification sur les conventions
		INSERT INTO Un_ConventionYearQualif (
				ConventionID, 
				ConnectID, 
				EffectDate, 
				YearQualif)
			SELECT
				C.ConventionID, 
				ISNULL(C.InsertConnectID,@ConnecTID),
				@GetDate, 
				Y.YearQualif
			FROM dbo.Un_Convention C
			JOIN @tYearQualif_Ins Y ON Y.ConventionID = C.ConventionID
	END
	ELSE IF EXISTS ( -- Modification
			SELECT D.ConventionID
			FROM INSERTED I
			JOIN DELETED D ON D.ConventionID = I.ConventionID
			WHERE I.BeneficiaryID <> D.BeneficiaryID -- Le bénéficiaire à changer.
				OR I.PlanID <> D.PlanID -- Le régime à changer
			)
	BEGIN
		-- Crée un table temporaire qui contiendra les années de qualifications calculées
		-- des conventions dont le bénéficiaire à changer.
		DECLARE @tYearQualif_Upd TABLE (
			ConventionID INT PRIMARY KEY,
			YearQualif INT NOT NULL )
			
		-- Calul les années de qualifications des conventions affectées
		INSERT INTO @tYearQualif_Upd
			SELECT 
				C.ConventionID,
				YearQualif = 
					CASE 
						WHEN P.PlanTypeID = 'IND' THEN 0 -- Si individuel = 0
					ELSE YEAR(HB.BirthDate) + P.tiAgeQualif -- Si collectif Année de la date de naissance du bénéficiaire + Age de qualification du régime.
					END
			FROM dbo.Un_Convention C
			JOIN INSERTED i ON C.ConventionID = I.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID 
			JOIN DELETED D ON D.ConventionID = I.ConventionID
			WHERE	( I.BeneficiaryID <> D.BeneficiaryID -- Le bénéficiaire à changé.
					OR I.PlanID <> D.PlanID -- Le régime à changer
					)
				AND	CASE 
							WHEN P.PlanTypeID = 'IND' THEN 0 -- Si individuel = 0
						ELSE YEAR(HB.BirthDate) + P.tiAgeQualif -- Si collectif Année de la date de naissance du bénéficiaire + Age de qualification du régime.
						END <> C.YearQualif -- L'année de qualification à changer
			
		-- Inscrit l'année de qualification calculée sur les conventions
		UPDATE dbo.Un_Convention 
		SET YearQualif = Y.YearQualif
		FROM dbo.Un_Convention C
		JOIN @tYearQualif_Upd Y ON Y.ConventionID = C.ConventionID
		
		-- Met la date de fin sur le précédent historique de changement d'année de qualification
		UPDATE Un_ConventionYearQualif
		SET TerminatedDate = DATEADD(ms,-2,@GetDate)
		FROM Un_ConventionYearQualif C
		JOIN @tYearQualif_Upd Y ON Y.ConventionID = C.ConventionID
		WHERE C.TerminatedDate IS NULL

		-- InsŠre un historique d'année de qualification sur les conventions
		INSERT INTO Un_ConventionYearQualif (
				ConventionID, 
				ConnectID, 
				EffectDate, 
				YearQualif)
			SELECT
				C.ConventionID, 
				ISNULL(C.LastUpdateConnectID,@ConnecTID), 
				@GetDate, 
				Y.YearQualif
			FROM dbo.Un_Convention C
			JOIN @tYearQualif_Upd Y ON Y.ConventionID = C.ConventionID
	END

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
GRANT SELECT
    ON OBJECT::[dbo].[Un_Convention] TO [svc-portailmigrationprod]
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des conventions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du plan (Un_Plan) de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'PlanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du souscripteur (Un_Subscriber) de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'SubscriberID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du bénéficiaire (Un_Beneficiary) de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'BeneficiaryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro unique de la convention généré selon la formule de Gestion Universitas.  C''est le numéro que l''usager voit, qui est inscrit sur les dossiers et sur les documents expédiés au client.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'ConventionNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Année de qualification aux bourses de la convention.  C''est l''année à laquel le bénéficiaire de la convention pourra toucher sa première bourse pour cette convention s''il rempli les conditions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'YearQualif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'C''est la date des prélèvements de la convention.  Dans le cas d''une convention mensuel, on fait les prélèvements le jour de cette date à chaque mois.  Dans le cas d''une annuel, on prend les prélèvements à chaque année le jour de cette date et le mois de la date de vigueur du groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'FirstPmtDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Mode de paiement de la convention. (AUT = Prélèvement automatique, CHQ = Chèque)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'PmtTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Quand la convention est rendu aux bourses, ce champs garde l''année de bourse en cours.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'ScholarshipYear';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Un caractère identifiant dequel façon la convention est entrée aux bourses. (A = Importation automatique, G = Importation de génie, R = Remise en vigueur, S = Transfert de SOBECO)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'ScholarshipEntryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de vigueur de la convention envoyé à la SCÉÉ.  Dans certain cas, (compte transitoire, changement de bénéficiaire, etc.) cette date est différente de la vrai date de vigueur de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'GovernmentRegDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du co-souscripteur (Un_Subscriber.SubscriberID) de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'CoSubscriberID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du text du diplôme (Un_DiplomaText).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'DiplomaTextID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champ boolean indiquant si la convention doit être envoyée au PCEE (1) ou non (0).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'bSendToCESP';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'SCEE voulue (1) ou non (2)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'bCESGRequested';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'SCEE+ voulue (1) ou non (2)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'bACESGRequested';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'BEC voulu (1) ou non (2)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'bCLBRequested';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du lien de parenté entre le souscripteur et le bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'tiRelationshipTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'État de la convention au niveau des pré-validations. (0 = Rien ne passe , 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'tiCESPState';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de début de régime', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'dtRegStartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de connexion de l''usager qui a inséré la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'InsertConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de connexion de l''usager qui a effectué la dernière modification à la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'LastUpdateConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Ajustement de la date de fin de régime', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'dtRegEndDateAdjust';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d’entrée en vigueur minimale des opérations TIN', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'dtInforceDateTIN';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur que le souscripteur désire obtenir les subventions de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'bSouscripteur_Desire_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date du prospectus.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'dtDateProspectus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Responsable des déductions à la source en référence au projet corporatif', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'iSous_Cat_ID_Resp_Prelevement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contient le checksum de l''enregistrement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'iCheckSum';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique de la justification de convention incomplète', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'iID_Justification_Conv_Incomplete';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de signature de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'dtSignature';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date d’entrée en vigueur de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'dtEntreeEnVigueur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le formulaire 0093 de demande de subvention est reçu et signé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'SCEEFormulaire93Recu';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si l''annexe B du formulaire 93 pour le tuteur est reçue et signée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'SCEEAnnexeBTuteurRequise';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si l''annexe B du Formulaire 93 pour le tuteur est requise (Tuteur <> Souscripteur).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'SCEEAnnexeBTuteurRecue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si l''annexe B du Formulaire 93 pour le principal responsable est requise (Principal responsable <> Souscripteur).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'SCEEAnnexeBPRespRequise';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si l''annexe B du Formulaire 93 pour le principal responsable est reçue et signée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'SCEEAnnexeBPRespRecue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le souscripteur a volontairement refusée de demander la SCEE+ dans le formulaire 0093.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'SCEEFormulaire93SCEEPlusRefusee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le souscripteur a refusée de demander le BEC dans le formulaire 0093.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'SCEEFormulaire93BECRefuse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le souscripteur a refusée de demander la SCEE dans le formulaire 0093.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'SCEEFormulaire93SCEERefusee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Raison du dernier changement de Souscripteur pour la Convention. (0 = Divorce/Séparation, 1 = Décès)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'RaisonDernierChangementSouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du Souscripteur Original de la Convention. Correspond au Souscripteur présent lorsque la Convention a passé à l’état  REEE.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'IdSouscripteurOriginal';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Lien entre le Souscripteur et le Souscripteur Original de la Convention. (0 = Conjoint/Époux, 1 = Autre)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'LienSouscripteurVersSouscripteurOriginal';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Texte du diplôme, qu''il proviennen de la liste officielle (Un_DiplomaText ou non).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'TexteDiplome';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de la fermeture de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'dtDate_Fermeture';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Raison de la fermeture de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'iID_Raison_Fermeture';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Notes concernant la fermeture de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'vcNote_Fermeture';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si l''annexe pour la confidentialité du Formulaire 93 pour le tuteur a été signée', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'SCEEAnnexeBConfTuteurRecue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si l''annexe pour la confidentialité du Formulaire 93 pour le responsable a été signée', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'SCEEAnnexeBConfPRespRecue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur du type de maximisation (0 = aucune maximisation, 1 = acceleREEE, 2 = acceleREEE avec pret)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'tiMaximisationREEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si convention maximisable (0 = non maximisable, 1 = maximisable)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'bEstMaximisable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si convention eligible a un pret', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Convention', @level2type = N'COLUMN', @level2name = N'bEstEligiblePret';

