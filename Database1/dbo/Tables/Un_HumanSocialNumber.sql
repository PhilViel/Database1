CREATE TABLE [dbo].[Un_HumanSocialNumber] (
    [HumanSocialNumberID] [dbo].[MoID]      IDENTITY (1, 1) NOT NULL,
    [HumanID]             [dbo].[MoID]      NOT NULL,
    [ConnectID]           [dbo].[MoID]      NOT NULL,
    [EffectDate]          [dbo].[MoGetDate] NOT NULL,
    [SocialNumber]        [dbo].[MoDesc]    NOT NULL,
    [LoginName]           VARCHAR (50)      NULL,
    CONSTRAINT [PK_Un_HumanSocialNumber] PRIMARY KEY CLUSTERED ([HumanSocialNumberID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_HumanSocialNumber_Mo_Human__HumanID] FOREIGN KEY ([HumanID]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_HumanSocialNumber_HumanID]
    ON [dbo].[Un_HumanSocialNumber]([HumanID] ASC) WITH (FILLFACTOR = 90);


GO
/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	TR_U_Un_HumanSocialNumber_A
Description         :	Calcul les ‚tats des conventions et de ces groupes d'unit‚s et les mettent … jour, ce lors 
								de modification d'historique de num‚ro d'assurance social. 
Valeurs de retours  :	N/A
Note                :	ADX0001292	UP	2008-04-02	Bruno Lapointe		Cr‚ation. Combine et remplace les pr‚c‚dents 
																							triggers de cette table.
										2010-10-01	Steve Gouin			Gestion #DisableTrigger
*********************************************************************************************************************/
CREATE TRIGGER dbo.TR_U_Un_HumanSocialNumber_A ON dbo.Un_HumanSocialNumber AFTER UPDATE
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
		@UnitID INTEGER,
		@UnitIDs VARCHAR(8000)

	-- Cr‚e une chaŒne de caractŠre avec tout les groupes d'unit‚s affect‚s
	DECLARE UnitIDs CURSOR FOR
		SELECT
			U.UnitID
		FROM INSERTED I
		JOIN dbo.Un_Convention C ON C.SubscriberID = I.HumanID OR C.BeneficiaryID = I.HumanID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID

	OPEN UnitIDs

	FETCH NEXT FROM UnitIDs
	INTO
		@UnitID

	SET @UnitIDs = ''

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @UnitIDs = @UnitIDs + CAST(@UnitID AS VARCHAR(30)) + ','
	
		FETCH NEXT FROM UnitIDs
		INTO
			@UnitID
	END

	CLOSE UnitIDs
	DEALLOCATE UnitIDs

	-- Appelle la proc‚dure qui met … jour les ‚tats des groupes d'unit‚s et des conventions
	EXECUTE TT_UN_ConventionAndUnitStateForUnit @UnitIDs 
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	TR_I_Un_HumanSocialNumber_A
Description         :	Calcul les états des conventions et de ces groupes d'unités et les mettent à jour, ce lors 
								d'ajout d'historique de numéro d'assurance social. Aussi,
								met à jour la date d'entrée en REEE (tous les NAS saisis) de la convention.
Valeurs de retours  :	N/A
Note                :	
	ADX0001292	UP	2008-04-02	Bruno Lapointe			Création. Combine et remplace les pr‚c‚dents triggers de cette table.
	ADX0003172	UR	2008-06-25	Bruno Lapointe			Plutôt que mettre la date du jour, met une date calculée.
					2010-03-26	Jean-François Gauthier	Modification afin d'assigner à dtRegStartDate la plus petite date
														entre OperDate (Un_Oper) et EffectDate (Un_Cotisation)
														Remplacement de InforceDate par SignatureDate de la table Un_Unit
					2010-10-04	Steve Gouin				Gestion du #DisableTrigger
					2015-07-24	Pierre-Luc Simard		Ajout du LoginName
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TR_I_Un_HumanSocialNumber_A] ON [dbo].[Un_HumanSocialNumber] AFTER INSERT
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

	-- Mise à jour du LogineName lorsque NULL
	INSERT INTO #DisableTrigger VALUES('TR_U_Un_HumanSocialNumber_A')	
		
	UPDATE HSN
	SET LoginName = dbo.GetUserContext()
	FROM dbo.Un_HumanSocialNumber HSN 
	JOIN inserted I ON I.HumanSocialNumberID = HSN.HumanSocialNumberID
	WHERE HSN.LoginName IS NULL

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TR_U_Un_HumanSocialNumber_A'    

	DECLARE @tConv_TR_I_Un_HumanSocialNumber_A TABLE (
		ConventionID INT PRIMARY KEY )

	-- Gestion de la date d'entrée en REEE
	IF EXISTS(	SELECT S.SubscriberID
					FROM dbo.Un_Subscriber S
					JOIN INSERTED INS ON INS.HumanID = S.SubscriberID )
	BEGIN
		--Souscripteur
		INSERT INTO @tConv_TR_I_Un_HumanSocialNumber_A
			SELECT DISTINCT C.ConventionID
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
			JOIN INSERTED INS ON INS.HumanID = C.SubscriberID					
			JOIN Un_HumanSocialNumber S ON S.HumanID = INS.HumanID
			LEFT JOIN Un_HumanSocialNumber S2 ON S2.HumanID = S.HumanID AND S2.HumanSocialNumberID <> S.HumanSocialNumberID
			WHERE S2.HumanID IS NULL
				AND ISNULL(B.SocialNumber,'') <> ''
				AND C.dtRegStartDate IS NULL
	END
	
	IF EXISTS(	SELECT B.BeneficiaryID
					FROM dbo.Un_Beneficiary B
					JOIN INSERTED INS ON INS.HumanID = B.BeneficiaryID )
	BEGIN
		--Bénéficiaire
		INSERT INTO @tConv_TR_I_Un_HumanSocialNumber_A
			SELECT DISTINCT C.ConventionID
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID	
			JOIN INSERTED INS ON INS.HumanID = 	C.BeneficiaryID			
			JOIN Un_HumanSocialNumber B ON B.HumanID = INS.HumanID
			LEFT JOIN Un_HumanSocialNumber B2 ON B2.HumanID = B.HumanID AND B2.HumanSocialNumberID <> B.HumanSocialNumberID					
			WHERE B2.HumanID IS NULL
				AND ISNULL(S.SocialNumber,'') <> ''
				AND C.dtRegStartDate IS NULL
	END

	IF EXISTS( SELECT * FROM @tConv_TR_I_Un_HumanSocialNumber_A )
	BEGIN
		--Met à jour la date d'entrée en REEE des conventions s'il y a lieu
		UPDATE C
		SET dtRegStartDate = V.dtRegStartDate
		FROM dbo.Un_Convention C
		JOIN (
			SELECT 
				C.ConventionID,
				dtRegStartDate =
					CASE
						WHEN FCB.FCBOperDate IS NOT NULL THEN FCB.FCBOperDate				-- Date de l'opération FCB si pas null
						WHEN FCB.FCBOperDate IS NULL THEN									-- 2010-03-29 : JFG : S'il n'y a pas de FCB et que la date de naissance du bénéficiaire est postérieure à la date de signature de la convention, alors on prend la date de naissance
															CASE WHEN	ISNULL(MIN(h.BirthDate), '1900-01-01') > MIN(U.SignatureDate) THEN MIN(h.BirthDate)
																 ELSE	MIN(U.SignatureDate)
															END	
						WHEN MIN(U.SignatureDate) < '2003-01-01' THEN MIN(U.SignatureDate) -- Date d'entrée en vigueur si avant le 1 janvier 2003
						WHEN Ct.ConventionID IS NULL THEN MIN(U.SignatureDate) -- Date d'entrée en vigueur si aucun FCB sera crée suite … la saisie de ce NAS
						WHEN MIN(U.SignatureDate) < MIN(B.EffectDate) AND MIN(S.EffectDate) < MIN(B.EffectDate) THEN GETDATE() -- Date de saisie du premier NAS du bénéficiaire si plus élevé
						WHEN MIN(U.SignatureDate) < MIN(S.EffectDate) THEN GETDATE() -- Date de saisie du premier NAS du souscripteur si plus élevé
						ELSE MIN(U.SignatureDate) -- Date d'entrée en vigueur de la convention
					END
			FROM @tConv_TR_I_Un_HumanSocialNumber_A MAJ
			JOIN dbo.Un_Convention C ON C.ConventionID = MAJ.ConventionID
			LEFT JOIN dbo.Mo_Human h ON C.BeneficiaryID = h.HumanID
			LEFT JOIN 
					(
					SELECT -- Va chercher la date du FCB s'il y en a un sur la convention
						C.ConventionID,											
						FCBOperDate = CASE	-- 2010-03-29 : JFG : Sélection de la plus petite date entre OperDate et EffectDate
											WHEN MIN(O.OperDate) > MIN(Ct.EffectDate)  THEN MIN(Ct.EffectDate)
											ELSE MIN(O.OperDate)
									  END
					FROM 
						@tConv_TR_I_Un_HumanSocialNumber_A MAJ
						JOIN dbo.Un_Convention C ON C.ConventionID = MAJ.ConventionID
						JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
						JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
						JOIN Un_Oper O ON O.OperID = Ct.OperID
					WHERE 
						O.OperTypeID = 'FCB'
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
			LEFT JOIN ( -- Convention pour lesquelles un FCB sera crée à la suite de la saisie de ce NAS.
				SELECT
					MAJ.ConventionID
				FROM @tConv_TR_I_Un_HumanSocialNumber_A MAJ
				JOIN dbo.Un_Unit U ON U.ConventionID = MAJ.ConventionID
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
				WHERE O.OperDate < GETDATE()
				GROUP BY MAJ.ConventionID
				HAVING (SUM(Ct.Cotisation) <> 0)
					OR (SUM(Ct.Fee) <> 0)
				) Ct ON Ct.ConventionID = C.ConventionID
			GROUP BY C.ConventionNo, C.ConventionID, C.dtRegStartDate, FCB.FCBOperDate, Ct.ConventionID
			HAVING ( MIN(U.SignatureDate) < '2003-01-01'		-- 2010-03-29 : JFG : Remplacement du InforceDate par SignatureDate
					OR ( MIN(B.EffectDate) IS NOT NULL
						AND MIN(S.EffectDate) IS NOT NULL
						)
					)
			) V ON V.ConventionID = C.ConventionID			
	END
	
	DECLARE 
		@UnitID INTEGER,
		@UnitIDs VARCHAR(8000)

	-- Crée une chaîne de caractère avec tout les groupes d'unités affectés
	DECLARE UnitIDs CURSOR FOR
		SELECT
			U.UnitID
		FROM INSERTED I
		JOIN dbo.Un_Convention C ON C.SubscriberID = I.HumanID OR C.BeneficiaryID = I.HumanID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID

	OPEN UnitIDs

	FETCH NEXT FROM UnitIDs
	INTO
		@UnitID

	SET @UnitIDs = ''

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @UnitIDs = @UnitIDs + CAST(@UnitID AS VARCHAR(30)) + ','
	
		FETCH NEXT FROM UnitIDs
		INTO
			@UnitID
	END

	CLOSE UnitIDs
	DEALLOCATE UnitIDs

	-- Appelle la procédure qui met à jour les états des groupes d'unités et des conventions
	EXECUTE TT_UN_ConventionAndUnitStateForUnit @UnitIDs 
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	TR_D_Un_HumanSocialNumber_A
Description         :	Calcul les ‚tats des conventions et de ces groupes d'unit‚s et les mettent … jour, ce lors 
								de suppression d'historique de num‚ro d'assurance social. Aussi, met … jour la date d'entr‚
								en REEE (tous les NAS saisis) de la convention.
Valeurs de retours  :	N/A
Note                :	ADX0001292	UP	2008-04-02	Bruno Lapointe		Creation. Combine et remplace les pr‚c‚dents 
																							triggers de cette table.
										2010-10-01	Steve Gouin			Gestion #DisableTrigger
																							
*********************************************************************************************************************/
CREATE TRIGGER dbo.TR_D_Un_HumanSocialNumber_A ON dbo.Un_HumanSocialNumber AFTER DELETE
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
	
	-- Gestion de la date d'entr‚e en REEE
	--Mise … jour des conventions si on a supprim‚ le premier NAS du souscripteur ou du b‚n‚ficiaire
	UPDATE C
	SET dtRegStartDate = NULL
	FROM dbo.Un_Convention C
	JOIN (
			SELECT C.ConventionID
			FROM DELETED DEL
			JOIN dbo.Un_Convention C ON DEL.HumanID = C.SubscriberID OR DEL.HumanID = C.BeneficiaryID
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
			LEFT JOIN Un_HumanSocialNumber S ON S.HumanID = C.SubscriberID
			LEFT JOIN Un_HumanSocialNumber B ON B.HumanID = C.BeneficiaryID
			WHERE	( S.HumanID IS NULL -- V‚rifie si un NAS est manquant
					OR B.HumanID IS NULL
					OR HS.SocialNumber IS NULL
					OR HB.SocialNumber IS NULL
					)
				AND C.dtRegStartDate IS NOT NULL -- PossŠde une date d'entr‚e en REEE
				AND C.ConventionID IN ( -- L'‚tat de la convention doit ˆtre "PROPOSITION" ou "TRANSITOIRE"
					SELECT 
						T.ConventionID
					FROM (-- Retourne la plus grande date de d‚but d'un ‚tat par convention
						SELECT 
							ConventionID,
							MaxDate = MAX(StartDate)
						FROM Un_ConventionConventionState
						GROUP BY ConventionID
						) T
					JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'‚tat correspondant … la plus grande date par convention
					WHERE CCS.ConventionStateID IN ('PRP','TRA')
					)
			GROUP BY C.ConventionID
			HAVING MIN(U.InForceDate) >= '2003-01-01' -- Applique la rŠgle qui dit qu'une convention ne peut ˆtre en proposition si elle est avant le 1 janvier 2003
			) V ON V.ConventionID = C.ConventionID
	
	DECLARE 
		@UnitID INTEGER,
		@UnitIDs VARCHAR(8000)

	-- Cr‚e une chaŒne de caractŠre avec tout les groupes d'unit‚s affect‚s
	DECLARE UnitIDs CURSOR FOR
		SELECT
			U.UnitID
		FROM DELETED D
		JOIN dbo.Un_Convention C ON C.SubscriberID = D.HumanID OR C.BeneficiaryID = D.HumanID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID

	OPEN UnitIDs

	FETCH NEXT FROM UnitIDs
	INTO
		@UnitID

	SET @UnitIDs = ''

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @UnitIDs = @UnitIDs + CAST(@UnitID AS VARCHAR(30)) + ','
	
		FETCH NEXT FROM UnitIDs
		INTO
			@UnitID
	END

	CLOSE UnitIDs
	DEALLOCATE UnitIDs

	-- Appelle la proc‚dure qui met … jour les ‚tats des groupes d'unit‚s et des conventions
	EXECUTE dbo.TT_UN_ConventionAndUnitStateForUnit @UnitIDs 
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les historiques des numéros d''assurance sociale pour un humain (bénéficiaire, souscripteur, représentant, etc.).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_HumanSocialNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement d''historique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_HumanSocialNumber', @level2type = N'COLUMN', @level2name = N'HumanSocialNumberID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''humain (Mo_Humain) auquel appartient l''historique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_HumanSocialNumber', @level2type = N'COLUMN', @level2name = N'HumanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion de l''usager (Mo_Connect) qui a créé l''enregistrement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_HumanSocialNumber', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur du NAS (Numéro d''assurance sociale).  Le NAS actuel de l''humain est celui avec la plus grande date de vigueur qui est inférieure ou égale à la date du jour.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_HumanSocialNumber', @level2type = N'COLUMN', @level2name = N'EffectDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'C''est le numéro d''assurance sociale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_HumanSocialNumber', @level2type = N'COLUMN', @level2name = N'SocialNumber';

