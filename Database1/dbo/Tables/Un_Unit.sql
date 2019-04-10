CREATE TABLE [dbo].[Un_Unit] (
    [UnitID]                    [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [ConventionID]              [dbo].[MoID]         NOT NULL,
    [RepID]                     [dbo].[MoIDoption]   NULL,
    [RepResponsableID]          [dbo].[MoIDoption]   NULL,
    [ModalID]                   [dbo].[MoID]         NOT NULL,
    [BenefInsurID]              [dbo].[MoIDoption]   NULL,
    [ActivationConnectID]       [dbo].[MoIDoption]   NULL,
    [ValidationConnectID]       [dbo].[MoIDoption]   NULL,
    [PmtEndConnectID]           [dbo].[MoIDoption]   NULL,
    [StopRepComConnectID]       [dbo].[MoIDoption]   NULL,
    [UnitNo]                    [dbo].[MoDesc]       NOT NULL,
    [UnitQty]                   [dbo].[MoMoney]      NOT NULL,
    [WantSubscriberInsurance]   [dbo].[MoBitTrue]    NOT NULL,
    [InForceDate]               [dbo].[MoGetDate]    NOT NULL,
    [SignatureDate]             [dbo].[MoDateoption] NULL,
    [IntReimbDate]              [dbo].[MoDateoption] NULL,
    [TerminatedDate]            [dbo].[MoDateoption] NULL,
    [SubscribeAmountAjustment]  [dbo].[MoMoney]      NOT NULL,
    [SaleSourceID]              [dbo].[MoIDoption]   NULL,
    [LastDepositForDoc]         DATETIME             NULL,
    [IntReimbDateAdjust]        DATETIME             NULL,
    [dtFirstDeposit]            DATETIME             NULL,
    [dtCotisationEndDateAdjust] DATETIME             NULL,
    [dtInforceDateTIN]          DATETIME             NULL,
    [iSous_Cat_ID]              INT                  CONSTRAINT [DF_Un_Unit_iSousCatID] DEFAULT ((1)) NULL,
    [PETransactionId]           INT                  NULL,
    [bActiverSansLettre]        BIT                  CONSTRAINT [DF_Un_Unit_bActiverSansLettre] DEFAULT ((0)) NULL,
    [iID_BeneficiaireOriginal]  INT                  NULL,
    [iID_RepComActif]           INT                  NULL,
    CONSTRAINT [PK_Un_Unit] PRIMARY KEY CLUSTERED ([UnitID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_Unit_Un_BenefInsur__BenefInsurID] FOREIGN KEY ([BenefInsurID]) REFERENCES [dbo].[Un_BenefInsur] ([BenefInsurID]),
    CONSTRAINT [FK_Un_Unit_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_Un_Unit_Un_Modal__ModalID] FOREIGN KEY ([ModalID]) REFERENCES [dbo].[Un_Modal] ([ModalID]),
    CONSTRAINT [FK_Un_Unit_Un_Rep__RepID] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Un_Rep] ([RepID]),
    CONSTRAINT [FK_Un_Unit_Un_Rep__RepResponsableID] FOREIGN KEY ([RepResponsableID]) REFERENCES [dbo].[Un_Rep] ([RepID]),
    CONSTRAINT [FK_Un_Unit_Un_SaleSource__SaleSourceID] FOREIGN KEY ([SaleSourceID]) REFERENCES [dbo].[Un_SaleSource] ([SaleSourceID]),
    CONSTRAINT [FK_Un_Unit_Un_Unit_Sous_Cat__iSousCatID] FOREIGN KEY ([iSous_Cat_ID]) REFERENCES [dbo].[Un_Unit_Sous_Cat] ([iSous_Cat_ID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Unit_ConventionID]
    ON [dbo].[Un_Unit]([ConventionID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Unit_ModalID]
    ON [dbo].[Un_Unit]([ModalID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Unit_RepID]
    ON [dbo].[Un_Unit]([RepID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Unit_UnitNo]
    ON [dbo].[Un_Unit]([UnitNo] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Unit_dtFirstDeposit]
    ON [dbo].[Un_Unit]([dtFirstDeposit] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Unit_UnitID_ModalID]
    ON [dbo].[Un_Unit]([UnitID] ASC, [ModalID] ASC)
    INCLUDE([PmtEndConnectID], [UnitQty]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Unit_InForceDate]
    ON [dbo].[Un_Unit]([InForceDate] ASC)
    INCLUDE([ConventionID], [RepID], [UnitQty]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Unit_ConventionID_UnitID_TerminatedDate_IntReimbDate]
    ON [dbo].[Un_Unit]([ConventionID] ASC, [UnitID] ASC, [TerminatedDate] ASC, [IntReimbDate] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Unit_ConventionID_InForceDate_UnitID]
    ON [dbo].[Un_Unit]([ConventionID] ASC, [InForceDate] ASC, [UnitID] ASC)
    INCLUDE([dtCotisationEndDateAdjust], [dtFirstDeposit], [dtInforceDateTIN], [IntReimbDate], [IntReimbDateAdjust], [LastDepositForDoc], [ModalID], [PmtEndConnectID], [SaleSourceID], [SignatureDate], [SubscribeAmountAjustment], [TerminatedDate], [UnitQty]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Unit_ConventionID_IntReimbDate_TerminatedDate_UnitID_InForceDate]
    ON [dbo].[Un_Unit]([ConventionID] ASC, [IntReimbDate] ASC, [TerminatedDate] ASC, [UnitID] ASC, [InForceDate] ASC)
    INCLUDE([dtCotisationEndDateAdjust], [dtFirstDeposit], [dtInforceDateTIN], [IntReimbDateAdjust], [LastDepositForDoc], [ModalID], [PmtEndConnectID], [SaleSourceID], [SignatureDate], [SubscribeAmountAjustment], [UnitQty]) WITH (FILLFACTOR = 90);


GO
CREATE STATISTICS [_dta_stat_1333019930_5_1]
    ON [dbo].[Un_Unit]([ModalID], [UnitID]);


GO
CREATE STATISTICS [stat_Un_Unit_IQEE_1]
    ON [dbo].[Un_Unit]([ConventionID], [UnitID]);


GO
CREATE STATISTICS [_dta_stat_1333019930_1_14_2_16_18]
    ON [dbo].[Un_Unit]([ConventionID], [InForceDate], [IntReimbDate], [TerminatedDate], [UnitID]);


GO
CREATE STATISTICS [_dta_stat_1333019930_1_2_18]
    ON [dbo].[Un_Unit]([ConventionID], [TerminatedDate], [UnitID]);


GO
CREATE STATISTICS [_dta_stat_1333019930_14_2]
    ON [dbo].[Un_Unit]([ConventionID], [InForceDate]);


GO
CREATE STATISTICS [_dta_stat_1333019930_16_2_1_18]
    ON [dbo].[Un_Unit]([ConventionID], [IntReimbDate], [TerminatedDate], [UnitID]);


GO
CREATE STATISTICS [_dta_stat_1333019930_18_1_16]
    ON [dbo].[Un_Unit]([IntReimbDate], [TerminatedDate], [UnitID]);


GO
CREATE STATISTICS [_dta_stat_1333019930_18_16_2]
    ON [dbo].[Un_Unit]([ConventionID], [IntReimbDate], [TerminatedDate]);


GO
CREATE STATISTICS [_dta_stat_1333019930_18_2]
    ON [dbo].[Un_Unit]([ConventionID], [TerminatedDate]);


GO
CREATE STATISTICS [_dta_stat_1333019930_2_1_14]
    ON [dbo].[Un_Unit]([ConventionID], [InForceDate], [UnitID]);


GO
/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	TR_U_UN_Unit_A_dtRegStartDate
Description         :	Met … jour la date d'entrée en REEE (tous les NAS saisis) de la convention.
Note                :	
	ADX0003172	UR	2008-06-25	Bruno Lapointe			Création
					2010-03-29	Jean-François Gauthier	Modification afin d'assigner à dtRegStartDate la plus petite date
														entre OperDate (Un_Oper) et EffectDate (Un_Cotisation)
														Modification afin de récupérer SignatureDate au lieu de InForceDate
														Ajout de la validation sur BirthDate
					2010-10-04	Steve Gouin				Gestion du #DisableTrigger
					2014-09-30	Pierre-Luc Simard		Modifier les dates de signature et d'entrée en vigueur dans la convention 
																		Modifier la dtRegStartDate si la date de signature est modifiée
*********************************************************************************************************************/
CREATE TRIGGER dbo.TR_U_UN_Unit_A_dtRegStartDate ON dbo.Un_Unit FOR UPDATE
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
	
	IF EXISTS (
		SELECT *
		FROM DELETED DEL
		JOIN INSERTED INS ON INS.UnitID = DEL.UnitID
		WHERE INS.SignatureDate <> DEL.SignatureDate -- On a modifié la date de signature
			AND INS.UnitID IN ( -- Premier groupe d'unités
				SELECT 
					MIN(U.UnitID)
				FROM dbo.Un_Unit U
				WHERE U.ConventionID = INS.ConventionID
				GROUP BY	
					U.ConventionID) 
		)
	UPDATE C SET	
		dtSignature = INS.SignatureDate,
		dtEntreeEnVigueur = dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(INS.ConventionID)
	FROM dbo.Un_Convention C 
	JOIN INSERTED INS ON INS.ConventionID = C.ConventionID
	JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	WHERE INS.UnitID IN ( -- Premier groupe d'unités
		SELECT 
			MIN(U.UnitID)
		FROM dbo.Un_Unit U
		WHERE U.ConventionID = INS.ConventionID
			AND U.SignatureDate IS NOT NULL
		GROUP BY	
			U.ConventionID) 

	IF EXISTS (
		SELECT *
		FROM DELETED DEL
		JOIN INSERTED INS ON INS.UnitID = DEL.UnitID
		WHERE INS.InForceDate <> DEL.InForceDate -- On a modifié la date d'entr‚e en vigueur
			OR INS.SignatureDate <> DEL.SignatureDate -- On a modifié la date de signature
		)
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
						ELSE MIN(U.SignatureDate) -- Date d'entrée en vigueur de la convention
					END
			FROM INSERTED INS
			JOIN dbo.Un_Convention C ON C.ConventionID = INS.ConventionID
			LEFT OUTER JOIN dbo.Mo_Human h
				ON h.HumanID = C.BeneficiaryID
			LEFT JOIN (
				SELECT -- Va chercher la date du FCB s'il y en a un sur la convention
					C.ConventionID,
					FCBOperDate = CASE	-- 2010-03-29 : JFG : Sélection de la plus petite date entre OperDate et EffectDate
										WHEN MIN(O.OperDate) > MIN(Ct.EffectDate)  THEN MIN(Ct.EffectDate)
										ELSE MIN(O.OperDate)
								  END
				FROM INSERTED INS
				JOIN dbo.Un_Convention C ON C.ConventionID = INS.ConventionID
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
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
			GROUP BY C.ConventionNo, C.ConventionID, C.dtRegStartDate, FCB.FCBOperDate
			HAVING ( MIN(U.InforceDate) < '2003-01-01' 
					OR ( MIN(B.EffectDate) IS NOT NULL
						AND MIN(S.EffectDate) IS NOT NULL
						)
					)
				AND dbo.fn_Mo_DateNoTime(C.dtRegStartDate) <> 
					CASE
						WHEN FCB.FCBOperDate IS NOT NULL THEN FCB.FCBOperDate 
					ELSE MIN(U.InforceDate)
					END
			) V ON V.ConventionID = C.ConventionID			
	END
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TUn_Unit

Historique des modifications:
        Date        Programmeur             Description
        ----------  --------------------    -----------------------------------------------------
        2009-09-09  Éric Deshaies           Suivre les modifications aux enregistrements de la table "Un_Unit".			
        2010-10-04  Steve Gouin             Gestion des disable trigger par #DisableTrigger			
        2016-11-29  Steeve Picard           S'assurer que la date de départ du statut «En Proposition»
        2017-07-05  Steeve Picard           Simplificiation pour la date de départ du statut «En Proposition»
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TUn_Unit] ON [dbo].[Un_Unit] AFTER INSERT, UPDATE 
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

    UPDATE dbo.Un_Unit SET
        UnitQty = ROUND(ISNULL(i.UnitQty, 0), 4),
        InForceDate = dbo.fn_Mo_IsDateNull(i.InForceDate),
        SignatureDate = dbo.fn_Mo_IsDateNull(i.SignatureDate),
        TerminatedDate = dbo.fn_Mo_IsDateNull(i.TerminatedDate),
        IntReimbDate = dbo.fn_Mo_IsDateNull(i.IntReimbDate)
    FROM dbo.Un_Unit U JOIN inserted i ON U.UnitID = i.UnitID

    --  Gère la date de début des statut «Proposition»
    IF UPDATE(SignatureDate)
    BEGIN
        PRINT 'Signature date updated'
        DECLARE @TB_State TABLE (ID INT, StateID varchar(5), StartDate DATETIME, SignatureDate DATETIME)
        DECLARE @nCount INT = 0
    	   
        ;WITH CTE_State as (
            SELECT I.UnitID, S.UnitStateID, S.Startdate, IsNull(I.SignatureDate, S.StartDate) AS SignatureDate,
                   Row_Num = ROW_NUMBER() OVER (Partition By I.UnitID Order By S.StartDate)
              FROM Inserted I LEFT JOIN dbo.Un_UnitUnitState S ON S.UnitID = I.UnitID
        )
        INSERT INTO @TB_State (ID, StateID, StartDate, SignatureDate)
	    SELECT UnitID, UnitStateID, StartDate, SignatureDate
	      FROM CTE_State S
         WHERE Row_Num = 1

	    UPDATE US SET StartDate = S.SignatureDate
	      FROM dbo.Un_UnitUnitState US JOIN @TB_State S ON S.ID = US.UnitID 
                                                       AND S.StartDate = US.StartDate
         WHERE S.StateID = 'PTR'
           AND S.SignatureDate < US.StartDate

        SET @nCount += @@ROWCOUNT
        PRINT 'Start date updated : ' + Str(@nCount, 2)

	   INSERT INTO dbo.Un_UnitUnitState (UnitID, UnitStateID, StartDate)
	   SELECT S.ID, 'PTR', dbo.fn_Mo_IsDateNull(S.SignatureDate)
	     FROM @TB_State S
        WHERE IsNull(S.StateID, '') <> 'PTR' 
          AND S.SignatureDate < S.StartDate

        SET @nCount += @@ROWCOUNT
        PRINT 'Start date inserted : ' + Str(@nCount, 2)

        --IF @nCount > 0
        BEGIN
            DELETE FROM @TB_State

            ;WITH CTE_State as (
                SELECT S.ConventionID, S.ConventionStateID, S.Startdate, 
                       Row_Num = ROW_NUMBER() OVER (Partition By I.ConventionID Order By S.StartDate)
                  FROM dbo.Un_ConventionConventionState S --JOIN Un_Unit U ON U.ConventionID = I.ConventionID
                       JOIN Inserted I ON I.ConventionID = S.ConventionID
            )
            INSERT INTO @TB_State (ID, StateID, StartDate, SignatureDate)
            SELECT DISTINCT S.ConventionID, S.ConventionStateID, S.StartDate, 
                   SignatureDate = (SELECT Min(SignatureDate) FROM dbo.Un_Unit WHERE ConventionID = S.ConventionID)
	          FROM CTE_State S
             WHERE Row_Num = 1

            UPDATE CS SET StartDate = S.SignatureDate
	          FROM dbo.Un_ConventionConventionState CS 
                   JOIN @TB_State S ON S.ID = CS.ConventionID
                                   AND S.StartDate = CS.StartDate
                                   AND S.StateID = CS.ConventionStateID
             WHERE S.StateID = 'PRP'
               AND S.SignatureDate < CS.StartDate

	       INSERT INTO dbo.Un_ConventionConventionState (ConventionID, ConventionStateID, StartDate)
	       SELECT S.ID, 'PRP', S.SignatureDate
	         FROM @TB_State S
             WHERE S.StateID <> 'PRP' 
               AND S.SignatureDate < S.StartDate
        END
    END

	---------------------------------------------------------------------
	-- Suivre les modifications aux enregistrements de la table "Un_Unit"
	---------------------------------------------------------------------

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
		SELECT I.UnitID, D.UnitID
		FROM Inserted I
			 LEFT JOIN Deleted D ON D.UnitID = I.UnitID

	SET @i = 1

	WHILE @i <= @NbOfRecord
	BEGIN
		SELECT 
			@iID_Nouveau_Enregistrement = ID_Nouveau_Enregistrement, 
			@iID_Ancien_Enregistrement = ID_Ancien_Enregistrement 
		FROM @Tinserted 
		WHERE id = @i

		-- Ajouter la modification dans le suivi des modifications
		EXECUTE psGENE_AjouterSuiviModification 9, @iID_Nouveau_Enregistrement, @iID_Ancien_Enregistrement

		SET @i = @i + 1
	END

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END
GO
/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	TR_I_UN_Unit_A_dtRegStartDate
Description         :	Met à jour la date d'entrée en REEE (tous les NAS saisis) de la convention.
Note                :	
	ADX0003172	UR	2008-06-25	Bruno Lapointe	Modification (Renommé).
					2010-03-29	Jean-François Gauthier	Modification afin de récupérer SignatureDate au lieu de InForceDate
																			Ajout de la validation sur BirthDate
					2010-10-04	Steve Gouin					Gestion du #DisableTrigger
					2014-09-29	Pierre-Luc Simard			Enregistrer les dates de signature et d'entrée en vigueur dans la convention
*********************************************************************************************************************/
CREATE TRIGGER dbo.TR_I_UN_Unit_A_dtRegStartDate ON dbo.Un_Unit FOR INSERT
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
	
	--Mise à jour des dates des conventions si premier groupe d'unités
	UPDATE C SET	
		dtSignature = INS.SignatureDate,
		dtEntreeEnVigueur = dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(INS.ConventionID),
		dtRegStartDate = CASE WHEN (ISNULL(HB.SocialNumber, '') <> '' AND ISNULL(HS.SocialNumber, '') <> '') THEN dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(INS.ConventionID) ELSE NULL END
	FROM dbo.Un_Convention C 
	JOIN INSERTED INS ON INS.ConventionID = C.ConventionID
	JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	WHERE INS.UnitID IN ( -- Premier groupe d'unités
		SELECT 
			MIN(U.UnitID)
		FROM dbo.Un_Unit U
		WHERE U.ConventionID = INS.ConventionID
			AND U.SignatureDate IS NOT NULL
		GROUP BY	
			U.ConventionID) 
	
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :   TUn_Unit_State
Description         :   Calcul les états du groupe d'unités et de sa convention et les mettent à jour, 
                        ce lors d'ajout, suppression ou modification de groupes d'unités.
Valeurs de retours  :   N/A
Note                :	
					2004-06-11	Bruno Lapointe		Cr‚ation Point 10.23.02
	ADX0000694	IA	2005-06-03	Bruno Lapointe		Renommage des procédures 
												TT_UN_ConventionAndUnitStateForUnit et TT_UN_ConventionStateForConvention
	ADX0001095	BR	2005-12-15	Bruno Lapointe		Correction mise à jour d'état suite … Deadlock.
					2010-10-01	Steve Gouin		Gestion du #DisableTrigger
					2017-01-18     Steeve Picard       Élimination des «Cursor» pour joindre des IDs
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TUn_Unit_State] ON [dbo].[Un_Unit] AFTER INSERT, UPDATE, DELETE 
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

	-- Vérifie s'il y a des ajouts ou des modifications
	IF EXISTS(
		SELECT DISTINCT
			UnitID
		FROM INSERTED)
	BEGIN
		DECLARE @UnitIDs VARCHAR(8000) = ''

		-- Crée une chaîne de caractère avec tout les groupes d'unités affectés
          SELECT @UnitIDs = @UnitIDs + CAST(UnitID as varchar) + ','
          FROM (SELECT DISTINCT UnitID FROM INSERTED) t
	
		-- Appelle la procédure qui met à jour les états des groupes d'unités et des conventions
		EXECUTE TT_UN_ConventionAndUnitStateForUnit @UnitIDs 
	END -- Fin ajout et modificiation

	-- Vérifie s'il y a des suppressions
	IF EXISTS(
		SELECT DISTINCT
			D.UnitID
		FROM DELETED D
		LEFT JOIN INSERTED I ON I.UnitID = D.UnitID
		WHERE I.UnitID IS NULL)
	BEGIN
		DECLARE @ConventionIDs VARCHAR(8000) = ''
	
		-- Crée une chaîne de caractère avec tout les conventions affectés
          SELECT @ConventionIDs = @ConventionIDs + CAST(ConventionID as varchar) + ','
          FROM (SELECT DISTINCT D.ConventionID 
                  FROM DELETED D LEFT JOIN INSERTED I ON I.UnitID = D.UnitID
                 WHERE I.UnitID IS NULL
               ) t
	
		-- Appelle la procédure qui met à jour les états des conventions
		EXECUTE TT_UN_ConventionStateForConvention @ConventionIDs 
	END -- Fin suppression
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	TR_D_UN_Unit_A_dtRegStartDate
Description         :	Supprime la date d'entr‚ en REEE (tous les NAS saisis) de la convention.
Note                :	
	ADX0003172	UR	2008-06-25	Bruno Lapointe	Cr‚ation.
					2010-10-01	Steve Gouin			Gestion #DisableTrigger
					2014-09-30	Pierre-Luc Simard	Gestion des dates de signature et d'entrée en vigueur
*********************************************************************************************************************/
CREATE TRIGGER dbo.TR_D_UN_Unit_A_dtRegStartDate ON dbo.Un_Unit FOR DELETE
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
	
	-- Retire les dates de la convention s'il n'y plus de groupes d'unités sur celle-ci
	UPDATE C SET 
		dtRegStartDate = NULL,
		dtSignature = NULL,
		dtEntreeEnVigueur = NULL
	FROM dbo.Un_Convention C
	JOIN DELETED DEL ON DEL.ConventionID = C.ConventionID
	-- Plus de groupes d'unit‚s sur la convention
	WHERE C.ConventionID NOT IN (
		SELECT U.ConventionID -- Groupes d'unit‚s restant de la convention
		FROM dbo.Un_Unit U
		JOIN DELETED DEL ON DEL.ConventionID = U.ConventionID
		)
		AND (dtRegStartDate IS NOT NULL
			OR dtSignature IS NOT NULL
			OR dtEntreeEnVigueur IS NOT NULL)
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la convention (Un_Convention) dont fait partie le groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant (Un_Rep) qui a fait la vente.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant (Un_Rep.RepID) qui était le repsonsable (si il y en avait un) du représentant qui a fait la vente.  Quand un représentant commence, on lui attitre un représentant responsable jusqu''à ce qu''il est sont permis.  Null = Pas de responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'RepResponsableID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de modalité de paiement (Un_Modal) de ce groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'ModalID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''assurance bénéficiaire (Un_BenefInsur) de ce groupe d''unités.  Null=Pas d''assurance bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'BenefInsurID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion de l''usager (Mo_Connect.ConnectID) qui a activé ce groupe d''unités. NULL = pas activé', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'ActivationConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion de l''usager (Mo_Connect.ConnectID) qui a validé ce groupe d''unités. NULL = pas validé', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'ValidationConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion de l''usager (Mo_Connect.ConnectID) qui a mis en arrêt de paiement forcé ce groupe d''unités. NULL = pas en arrêt de paiement forcé.  Ce champs a été créé pour gérer les cas de décès de souscripteur assuré par Universitas.  Gestion Universitas au lieu d''émettre un chèque pour le montant restant d''épargnes et de frais à cotiser, décende le montant souscrit au montant actuel cotisé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'PmtEndConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion de l''usager (Mo_Connect.ConnectID) qui a mis en arrêt de paiement de commissions ce groupe d''unités. NULL = pas en arrêt de paiement de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'StopRepComConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro du groupe d''unités.  Pour toutes les nouveaux groupes d''unités à partir d''UniSQL, c''est le numéro de la convention (Un_Convention.ConventionNo).  Pour ceux avant ca peut être différent.  Dans paradox une convention avec deux groupes d''unités était codée comme deux conventions distinctent.  Lors du transfert on a fait une convention avec deux groupes d''unités et on a mis le numéro de convention de paradox de ce champs.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'UnitNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre d''unités que possède actuellement le groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'UnitQty';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant s''il y a de l''assurance souscripteur sur ce groupe d''unités. (=0:Non, <>0:Oui)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'WantSubscriberInsurance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''Entrée en vigueur du groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'InForceDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de signature du groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'SignatureDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de remboursement intégral du groupe d''unités.  NULL = Le remboursement intégral n''a pas encore eu lieu.  Dans le cas de convention de type Individuel ca correspond au remboursement intégral qui a mis à zéro le compte d''épargne et de frais de ce groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'IntReimbDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de résiliation du groupe d''unités.  NULL = Le groupe n''est pas résilié.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'TerminatedDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Ajustement au montant souscrit affiché sur le relevé de dépôt.  Cela ne change pas le montant souscrit, mais uniquement sont affichage sur le relevé de dépôt.  Le montant affiché dans le relevé est la somme de ce champs et du vrai montant souscrit.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'SubscribeAmountAjustment';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la source de vente (Un_SaleSource) du groupe d''unités. NULL = inconnu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'SaleSourceID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'C''est la date de dernier dépôt qui doit apparaître sur le contrat et sur les relevés de dépôts.  Si elle est vide on affiche celle calculée dans les documents.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'LastDepositForDoc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date ajustée de RI. Il ce peut qu''on est à modifier la date extimée de remboursement intégral pour certaines raisons (Changement de bénéficiaire, Cotisation pas complète suite à un retard, etc.)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'IntReimbDateAdjust';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date du premier dépôt, il s''agit de la plus petite date d''opération qui n''est pas un BEC et qui est lié par une cotisation au groupe d''unités. Le champ est calculé par un trigger sur Un_Cotisation et un autre sur Un_Oper', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'dtFirstDeposit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Ajustement de la date de fin de cotisation', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'dtCotisationEndDateAdjust';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d’entrée en vigueur minimale des opérations TIN', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'dtInforceDateTIN';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de la transaction lorsque le groupe d''unité a été créé par la proposition électronique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'PETransactionId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si le groupe d''unité doit être activé sans générer de lettre et de courriel', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'bActiverSansLettre';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du bénéficiaire original, à l''activation de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'iID_BeneficiaireOriginal';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du représentant qui peut recevoir des commissions sur l''actif de ce groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Unit', @level2type = N'COLUMN', @level2name = N'iID_RepComActif';

