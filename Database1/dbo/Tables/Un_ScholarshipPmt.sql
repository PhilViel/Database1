CREATE TABLE [dbo].[Un_ScholarshipPmt] (
    [ScholarshipPmtID]       [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [OperID]                 [dbo].[MoID]         NOT NULL,
    [ScholarshipID]          [dbo].[MoID]         NOT NULL,
    [CollegeID]              [dbo].[MoID]         NOT NULL,
    [ProgramID]              [dbo].[MoID]         NOT NULL,
    [StudyStart]             [dbo].[MoDateoption] NULL,
    [ProgramLength]          [dbo].[MoID]         NOT NULL,
    [ProgramYear]            [dbo].[MoID]         NOT NULL,
    [RegistrationProof]      [dbo].[MoBitFalse]   NOT NULL,
    [SchoolReport]           [dbo].[MoBitFalse]   NOT NULL,
    [EligibilityQty]         [dbo].[MoOrder]      NOT NULL,
    [CaseOfJanuary]          [dbo].[MoBitFalse]   NOT NULL,
    [EligibilityConditionID] CHAR (3)             NULL,
    CONSTRAINT [PK_Un_ScholarshipPmt] PRIMARY KEY CLUSTERED ([ScholarshipPmtID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_ScholarshipPmt_Un_College__CollegeID] FOREIGN KEY ([CollegeID]) REFERENCES [dbo].[Un_College] ([CollegeID]),
    CONSTRAINT [FK_Un_ScholarshipPmt_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID]),
    CONSTRAINT [FK_Un_ScholarshipPmt_Un_Program__ProgramID] FOREIGN KEY ([ProgramID]) REFERENCES [dbo].[Un_Program] ([ProgramID]),
    CONSTRAINT [FK_Un_ScholarshipPmt_Un_Scholarship__ScholarshipID] FOREIGN KEY ([ScholarshipID]) REFERENCES [dbo].[Un_Scholarship] ([ScholarshipID])
);


GO
ALTER TABLE [dbo].[Un_ScholarshipPmt] NOCHECK CONSTRAINT [FK_Un_ScholarshipPmt_Un_Scholarship__ScholarshipID];


GO
CREATE NONCLUSTERED INDEX [IX_Un_ScholarshipPmt_OperID]
    ON [dbo].[Un_ScholarshipPmt]([OperID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ScholarshipPmt_ScholarshipID]
    ON [dbo].[Un_ScholarshipPmt]([ScholarshipID] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[TUn_ScholarshipPmt] ON [dbo].[Un_ScholarshipPmt] FOR INSERT, UPDATE 
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

  UPDATE Un_ScholarshipPmt SET
    StudyStart = dbo.fn_Mo_IsDateNull( i.StudyStart)
  FROM Un_ScholarshipPmt U, inserted i
  WHERE U.ScholarshipPmtID = i.ScholarshipPmtID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des paiements de bourses.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipPmt';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du paiement de bourse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipPmt', @level2type = N'COLUMN', @level2name = N'ScholarshipPmtID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération financière (Un_Oper) qui a effectué le paiement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipPmt', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la bourse (Un_Scholarship) sur laquelle on fait le paiement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipPmt', @level2type = N'COLUMN', @level2name = N'ScholarshipID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''établissement d''enseignement (Un_College) ou le bénéficiaire fesait ses études lors du paiement selon la preuve d''inscription qu''il a fourni.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipPmt', @level2type = N'COLUMN', @level2name = N'CollegeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du programme d''enseignement (Un_Program) auquel était inscrit le bénéficiaire lors du paiement selon la preuve d''inscription qu''il a fourni.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipPmt', @level2type = N'COLUMN', @level2name = N'ProgramID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date du début des études selon la preuve d''inscription qu''il a fourni.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipPmt', @level2type = N'COLUMN', @level2name = N'StudyStart';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre d''année que dure le programme selon la preuve d''inscription qu''il a fourni.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipPmt', @level2type = N'COLUMN', @level2name = N'ProgramLength';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Qu''elle année du programme il débute selon la preuve d''inscription qu''il a fourni', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipPmt', @level2type = N'COLUMN', @level2name = N'ProgramYear';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champ boolean indiquant si le bénéficiaire avait fourni une preuve d''inscription lors du paiement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipPmt', @level2type = N'COLUMN', @level2name = N'RegistrationProof';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champ boolean indiquant si le bénéficiaire avait fourni un relevé de notes lors du paiement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipPmt', @level2type = N'COLUMN', @level2name = N'SchoolReport';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de crédits auxquelles le bénéficiaire était illigible lors du paiement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipPmt', @level2type = N'COLUMN', @level2name = N'EligibilityQty';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champ boolean indiquant si le bénéficiaire était un cas de janvier lors du paiement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipPmt', @level2type = N'COLUMN', @level2name = N'CaseOfJanuary';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type d''unité utilisé pour indiquer les conditions de réussite (UNK, YEA, CRS, CDT, SES, 3MT, HRS)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ScholarshipPmt', @level2type = N'COLUMN', @level2name = N'EligibilityConditionID';

