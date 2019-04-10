CREATE TABLE [dbo].[Un_Scholarship] (
    [ScholarshipID]          [dbo].[MoID]                IDENTITY (1, 1) NOT NULL,
    [ConventionID]           [dbo].[MoID]                NOT NULL,
    [ScholarshipNo]          [dbo].[MoOrder]             NOT NULL,
    [ScholarshipStatusID]    [dbo].[UnScholarshipStatus] NOT NULL,
    [ScholarshipAmount]      [dbo].[MoMoney]             NOT NULL,
    [YearDeleted]            [dbo].[MoID]                NOT NULL,
    [iIDBeneficiaire]        INT                         NULL,
    [mQuantite_UniteDemande] MONEY                       NULL,
    CONSTRAINT [PK_Un_Scholarship] PRIMARY KEY CLUSTERED ([ScholarshipID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_Scholarship_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_Un_Scholarship_ConventionID_ScholarshipNo]
    ON [dbo].[Un_Scholarship]([ConventionID] ASC, [ScholarshipNo] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Scholarship_ConventionID]
    ON [dbo].[Un_Scholarship]([ConventionID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Scholarship_ScholarshipStatusID]
    ON [dbo].[Un_Scholarship]([ScholarshipStatusID] ASC) WITH (FILLFACTOR = 90);


GO
/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	TUn_Scholarship_State
Description         :	Calcul les états des conventions et de ces groupes d'unités et les mettent à jour,  ce lors 
								d'ajout, modification et suppression de bourse.
Valeurs de retours  :	N/A
Note                :						2004-06-11	Bruno Lapointe		Création Point 10.23.02
								ADX0000694	IA	2005-06-03	Bruno Lapointe		Renommer la procédure 
																							TT_UN_ConventionAndUnitStateForUnit
								ADX0001095	BR	2005-12-15	Bruno Lapointe		Correction mise à jour d'état suite à Deadlock.
								ADX0001233	UP	2007-08-30	Bruno Lapointe		Amélioration du filtre pour déterminer si l'état
																							des groupes d'unités doit être recalculé.
												2010-09-27	Steve Gouin			Remplacer le Disable Trigger par une gestion par table temporaire
												2010-12-01	Pierre-Luc Simard	Ajout du PRINT des Trigger
												2011-07-28	Frédérick Thibault	Ajout de la sauvegarde de l'historique
												
*********************************************************************************************************************/
CREATE TRIGGER dbo.TUn_Scholarship_State ON dbo.Un_Scholarship AFTER INSERT, UPDATE, DELETE
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

	-- Crée une chaîne de caractère avec tout les groupes d'unités affectés
	DECLARE UnitIDs CURSOR FOR
		SELECT
			U.UnitID
		FROM INSERTED I
		JOIN dbo.Un_Unit U ON U.ConventionID = I.ConventionID
		WHERE I.ScholarshipID NOT IN ( 
			-- Exclu les mise à jour de l'état de bourse entre 'En réserve', 
			-- 'Admissible', 'En attente' et 'À payer'
			SELECT 
				I.ScholarshipID
			FROM INSERTED I
			JOIN DELETED D ON D.ScholarshipID = I.ScholarshipID
			WHERE D.ScholarshipNo = I.ScholarshipNo
				AND D.ConventionID = I.ConventionID
				AND(	( D.ScholarshipStatusID IN ('PAD','DEA','REN','25Y','24Y')
						AND I.ScholarshipStatusID <> D.ScholarshipStatusID
						)
					OR	( D.ScholarshipStatusID IN ('RES','ADM','WAI','TPA')
						AND I.ScholarshipStatusID IN ('RES','ADM','WAI','TPA')
						)
					)
			)
		-----
		UNION
		-----
		SELECT
			U.UnitID
		FROM DELETED D
		JOIN dbo.Un_Unit U ON U.ConventionID = D.ConventionID
		WHERE D.ScholarshipID NOT IN (
			-- Exclu les mise à jour de l'état de bourse entre 'En réserve', 
			-- 'Admissible', 'En attente' et 'À payer'
			SELECT 
				I.ScholarshipID
			FROM INSERTED I
			JOIN DELETED D ON D.ScholarshipID = I.ScholarshipID
			WHERE D.ScholarshipNo = I.ScholarshipNo
				AND D.ConventionID = I.ConventionID
				AND(	( D.ScholarshipStatusID IN ('PAD','DEA','REN','25Y','24Y')
						AND I.ScholarshipStatusID <> D.ScholarshipStatusID
						)
					OR	( D.ScholarshipStatusID IN ('RES','ADM','WAI','TPA')
						AND I.ScholarshipStatusID IN ('RES','ADM','WAI','TPA')
						)
					)
			)

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

	-- Appelle le calcul des états seulement s'il y a un groupe d'unités pour 
	-- lequel il faire le calcul.
	IF @UnitIDs <> ''
		-- Appelle la procédure qui met à jour les états des groupes d'unités et des conventions
		EXECUTE TT_UN_ConventionAndUnitStateForUnit @UnitIDs 
		
	----------------------------------------------------------------
	-- Conserve l'historique de la modification
	----------------------------------------------------------------
	INSERT INTO tblCONV_HistoriqueStatutBourse
					(
					 iID_Statut
					,iID_Bourse
					,dtDate_Statut
					)
				SELECT	 SB.iID_Statut
						,ScholarshipID
						,GETDATE()
				FROM tblCONV_StatutBourse SB
				JOIN INSERTED I ON I.ScholarshipStatusID = SB.vcCode_Statut
	
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des bourses.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Scholarship';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la bourse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Scholarship', @level2type = N'COLUMN', @level2name = N'ScholarshipID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la convention (Un_Convention) à laquel appartient la bourse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Scholarship', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de la bourse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Scholarship', @level2type = N'COLUMN', @level2name = N'ScholarshipNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne de 3 caractères qui donne l''état de la bourse (''RES''=En réserve, ''PAD''=Payée, ''ADM''=Admissible, ''WAI''=En attente, ''TPA''=À payer, ''DEA''=Décès, ''REN''=Renonciation, ''25Y''=25 ans de régime, ''24Y''=24 ans d''âge).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Scholarship', @level2type = N'COLUMN', @level2name = N'ScholarshipStatusID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de la bourse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Scholarship', @level2type = N'COLUMN', @level2name = N'ScholarshipAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Contient l''année de l''annulation de la bourse, si la bourse a été annulé à cause d''une renonciation, d''un décès ou du dépassement de la limite de 25 ans de régime ou le 24 ans d''age du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Scholarship', @level2type = N'COLUMN', @level2name = N'YearDeleted';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre d''unités demandé par le client.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Scholarship', @level2type = N'COLUMN', @level2name = N'mQuantite_UniteDemande';

