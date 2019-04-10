CREATE TABLE [dbo].[Un_ConventionConventionState] (
    [ConventionConventionStateID] [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [ConventionID]                [dbo].[MoID]         NOT NULL,
    [ConventionStateID]           [dbo].[MoOptionCode] NOT NULL,
    [StartDate]                   [dbo].[MoGetDate]    NOT NULL,
    CONSTRAINT [PK_Un_ConventionConventionState] PRIMARY KEY CLUSTERED ([ConventionConventionStateID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_ConventionConventionState_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_Un_ConventionConventionState_Un_ConventionState__ConventionStateID] FOREIGN KEY ([ConventionStateID]) REFERENCES [dbo].[Un_ConventionState] ([ConventionStateID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ConventionConventionState_ConventionID]
    ON [dbo].[Un_ConventionConventionState]([ConventionID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ConventionConventionState_ConventionStateID]
    ON [dbo].[Un_ConventionConventionState]([ConventionStateID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ConventionConventionState_ConventionID_ConventionConventionStateID_StartDate]
    ON [dbo].[Un_ConventionConventionState]([ConventionID] ASC, [ConventionConventionStateID] ASC, [StartDate] ASC)
    INCLUDE([ConventionStateID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ConventionConventionState_StartDate_ConventionID]
    ON [dbo].[Un_ConventionConventionState]([StartDate] DESC, [ConventionID] ASC)
    INCLUDE([ConventionConventionStateID], [ConventionStateID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ConventionConventionState_ConventionID_StartDate_ConventionConventionStateID]
    ON [dbo].[Un_ConventionConventionState]([ConventionID] ASC, [StartDate] ASC, [ConventionConventionStateID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE STATISTICS [stat_Un_ConventionConventionState_IQEE_1]
    ON [dbo].[Un_ConventionConventionState]([ConventionConventionStateID], [ConventionID], [StartDate]);


GO
CREATE STATISTICS [_dta_stat_1552880749_2_1_4]
    ON [dbo].[Un_ConventionConventionState]([ConventionConventionStateID], [ConventionID], [StartDate]);


GO
CREATE STATISTICS [_dta_stat_1552880749_4_2]
    ON [dbo].[Un_ConventionConventionState]([ConventionID], [StartDate]);


GO
/*******************************************************************************************************************************************************************************
Nom                 :	TUn_ConventionConventionState
Note                :		2015-08-19	Pierre-Luc Simard	Création, afin de générer les documents à l'insertion d'un nouvel état
							2015-09-09	Pierre-Luc Simard	La cotisation ne doit pas être un BEC pour que la génération du contrat individuel soit faite
							2015-09-21	Pierre-Luc Simard	La cotisation ne doit pas être un BNA ou une RES
							2015-10-08	Steve Picard			Met à jour le souscripteur original si la convention passe à REER
							2015-11-23	Pierre-Luc Simard	Ne plus générer les documents directement mais remplir la table Un_ConventionTransitionState 
							2015-12-15	Pierre-Luc Simard	Gestion des documents pour les conventions individuel si un premier dépôt existe
							2015-01-25	Pierre-Luc Simard	Générer les documents même si la convention individuelle n'a pas de premier dépôt (Transition "0")
																			Générer la facade individuelle uniquement si le premier dépôt est déjà présent (Transiton "1")
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TUn_ConventionConventionState_I] ON [dbo].[Un_ConventionConventionState] FOR INSERT
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

	-- si le souscripteur original est null, on le met à jour si la convention est passé à REER
	UPDATE C 
	SET IdSouscripteurOriginal = C.SubscriberID
	FROM dbo.Un_Convention C 
	JOIN inserted S ON S.ConventionID = C.ConventionID
	WHERE C.IdSouscripteurOriginal IS NULL 
		AND S.ConventionStateID = 'REE'
	
	INSERT INTO Un_ConventionTransitionState
	        (ConventionID,
	         TransitionCodeID
	        )
	SELECT DISTINCT 
			I.ConventionID,
			0 -- TRA->REE première fois (TransitoireVersREEE1)
	FROM INSERTED I
	--JOIN Un_ConventionConventionState CCS ON CCS.ConventionConventionStateID = I.ConventionConventionStateID
	JOIN dbo.Un_Convention C ON C.ConventionID = I.ConventionID
	JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
	WHERE I.ConventionStateID = 'REE'
		--AND P.PlanTypeID <> 'IND'
		AND I.ConventionID NOT IN ( -- La convention est REE pour la première fois
				SELECT 
					CSS.ConventionID
				FROM INSERTED I
				JOIN Un_ConventionConventionState CSS ON CSS.ConventionID = I.ConventionID
				WHERE CSS.ConventionStateID = 'REE'
					AND I.ConventionConventionStateID <> CSS.ConventionConventionStateID
				)
		AND I.ConventionID IN ( -- La convention a déjà été TRA
				SELECT 
					CSS.ConventionID
				FROM INSERTED I
				JOIN Un_ConventionConventionState CSS ON CSS.ConventionID = I.ConventionID
				WHERE CSS.ConventionStateID = 'TRA'
				)
		AND C.ConventionID NOT IN (
			SELECT DISTINCT 
				CTS.ConventionID
			FROM Un_ConventionTransitionState CTS
			WHERE CTS.TransitionCodeID = 0)

	-- Gestion de la façade pour les contrat individuels
	INSERT INTO Un_ConventionTransitionState(
		ConventionID,
		TransitionCodeID)
	SELECT DISTINCT
		U.ConventionID,
		1 -- TRA->REE première fois pour Individuel avec dépôt déjà présent pour générer la façade (PremierDepotConventionIndividuelleREEE)
	FROM INSERTED I
	JOIN dbo.Un_Convention C ON C.ConventionID = I.ConventionID
	JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	JOIN ( -- Le premier dépôt est déjà effectué dans ce groupe d'unité
		SELECT 
			Ct.UnitID
		FROM INSERTED I
		JOIN Un_Unit U ON U.ConventionID = I.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		WHERE O.OperTypeID NOT IN ('BEC', 'BNA', 'RES')
		) V ON V.UnitID = U.UnitID
	WHERE I.ConventionStateID = 'REE'
		AND P.PlanTypeID = 'IND'
		AND C.ConventionNo NOT LIKE 'T%'
		AND I.ConventionID NOT IN ( -- La convention est REE pour la première fois
				SELECT 
					CSS.ConventionID
				FROM INSERTED I
				JOIN Un_ConventionConventionState CSS ON CSS.ConventionID = I.ConventionID
				WHERE CSS.ConventionStateID = 'REE'
					AND I.ConventionConventionStateID <> CSS.ConventionConventionStateID
				)
		AND I.ConventionID IN ( -- La convention a déjà été TRA
				SELECT 
					CSS.ConventionID
				FROM INSERTED I
				JOIN Un_ConventionConventionState CSS ON CSS.ConventionID = I.ConventionID
				WHERE CSS.ConventionStateID = 'TRA'
				)
		AND U.TerminatedDate IS NULL -- Pas résilié
		AND U.IntReimbDate IS NULL -- Pas de RI versé
		AND U.InForceDate >= '2003-01-01'
		AND C.ConventionID NOT IN (
			SELECT DISTINCT 
				CTS.ConventionID
			FROM Un_ConventionTransitionState CTS
			WHERE CTS.TransitionCodeID = 1)

	/*
	-- Liste les conventions dont c'est la première fois qu'elles passent à l'état REEE
	DECLARE 
		@iMaxConventionID INT,
		@iMaxUnitID INT

	SELECT DISTINCT 
			I.ConventionID
	INTO #tConventionREE
	FROM INSERTED I
	JOIN Un_ConventionConventionState CCS ON CCS.ConventionConventionStateID = I.ConventionConventionStateID
	WHERE I.ConventionStateID = 'REE'
		AND I.ConventionID NOT IN ( -- La convention est REE pour la première fois
				SELECT 
					CSS.ConventionID
				FROM INSERTED I
				JOIN Un_ConventionConventionState CSS ON CSS.ConventionID = I.ConventionID
				WHERE CSS.ConventionStateID = 'REE'
					AND I.ConventionConventionStateID <> CSS.ConventionConventionStateID
				)
		AND I.ConventionID IN ( -- La convention a déjà été TRA
				SELECT 
					CSS.ConventionID
				FROM INSERTED I
				JOIN Un_ConventionConventionState CSS ON CSS.ConventionID = I.ConventionID
				WHERE CSS.ConventionStateID = 'TRA'
				)

	SELECT @iMaxConventionID = MAX(C.ConventionID) 
	FROM #tConventionREE C

	WHILE @iMaxConventionID	IS NOT NULL
		BEGIN

			
			-- Certificat (Diplôme)
			EXEC SP_RP_UN_Certificat 2, @iMaxConventionID, 0

			-- Accusé réception de NAS
			EXECUTE SP_RP_UN_SINReadReceipt 2, @iMaxConventionID, 0

			-- Contrat (Façade)
			SELECT DISTINCT 
				U.UnitID
			INTO #tUnitConventionREE
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			WHERE C.ConventionID = @iMaxConventionID	
				AND U.InForceDate >= '2003-01-01'
				AND U.TerminatedDate IS NULL -- Pas résilié
				AND U.IntReimbDate IS NULL -- Pas de RI versé
				AND ISNULL(U.ActivationConnectID, 0) <> 0 -- Activé, pour ne pas générer de lettre au ajouts d'unités non-activés  

			SELECT 
				@iMaxUnitID = MAX(U.UnitID) 
			FROM #tUnitConventionREE U

			WHILE @iMaxUnitID IS NOT NULL
			BEGIN 
				-- Valide si la convention est individuelle ou collective
				IF EXISTS(SELECT C.ConventionID FROM dbo.Un_Convention C JOIN Un_Plan P ON P.PlanID = C.PlanID WHERE C.ConventionID = @iMaxConventionID AND P.PlanTypeID = 'IND') 
				BEGIN
					-- Valide si au moins une cotisation a été faite pour une individuel et que ce n'est pas une "T"
                	IF EXISTS(
						SELECT CT.UnitID 
						FROM Un_Cotisation CT
						JOIN Un_Oper O ON O.OperID = CT.OperID 
						JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID
						JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
						WHERE CT.UnitID = @iMaxUnitID
							AND C.ConventionNo NOT LIKE 'T%'
							AND O.OperTypeID NOT IN ('BEC', 'BNA', 'RES')
						) 
							EXEC RP_UN_ConventionBourseEtudeIndividuel 2, @iMaxUnitID, 0
				END
				ELSE
					EXEC RP_UN_ConventionBourseEtudeRUI 2, @iMaxUnitID, 0

				SELECT @iMaxUnitID = MAX(U.UnitID) 
				FROM #tUnitConventionREE U
				WHERE U.UnitID < @iMaxUnitID	

			END

			SELECT @iMaxConventionID = MAX(C.ConventionID) 
			FROM #tConventionREE C
			WHERE C.ConventionID < @iMaxConventionID	

			-- Vider la table temporaire pour la prochaine convention
			DROP TABLE #tUnitConventionREE
			
		END 

	-- Suppression de la table temporaire
	DROP TABLE #tConventionREE
	*/
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de lien entre les états et les conventions, elle garde aussi un historique de tout les états des conventions', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionConventionState';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID Unique des enregistrements', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionConventionState', @level2type = N'COLUMN', @level2name = N'ConventionConventionStateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID Unique de la convention (Un_Convention) à qui appartient l’état', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionConventionState', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID Unique de l’état (Un_ConventionState)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionConventionState', @level2type = N'COLUMN', @level2name = N'ConventionStateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure à laquelle l’état est entré en vigueur pour la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionConventionState', @level2type = N'COLUMN', @level2name = N'StartDate';

