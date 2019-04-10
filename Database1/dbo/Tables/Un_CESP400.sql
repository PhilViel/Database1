CREATE TABLE [dbo].[Un_CESP400] (
    [iCESP400ID]                INT                   IDENTITY (1, 1) NOT NULL,
    [iCESPSendFileID]           INT                   NULL,
    [OperID]                    INT                   NULL,
    [CotisationID]              INT                   NULL,
    [ConventionID]              INT                   NOT NULL,
    [iCESP800ID]                INT                   NULL,
    [iReversedCESP400ID]        INT                   NULL,
    [tiCESP400TypeID]           TINYINT               NOT NULL,
    [tiCESP400WithdrawReasonID] TINYINT               NULL,
    [vcTransID]                 VARCHAR (15)          NOT NULL,
    [dtTransaction]             DATETIME              NOT NULL,
    [iPlanGovRegNumber]         INT                   NOT NULL,
    [ConventionNo]              VARCHAR (15)          NOT NULL,
    [vcSubscriberSINorEN]       VARCHAR (75)          NOT NULL,
    [vcBeneficiarySIN]          VARCHAR (75)          NOT NULL,
    [fCotisation]               MONEY                 NOT NULL,
    [bCESPDemand]               BIT                   NOT NULL,
    [dtStudyStart]              DATETIME              NULL,
    [tiStudyYearWeek]           TINYINT               NULL,
    [fCESG]                     MONEY                 NOT NULL,
    [fEAPCESG]                  MONEY                 NOT NULL,
    [fEAP]                      MONEY                 NOT NULL,
    [fPSECotisation]            MONEY                 NOT NULL,
    [iOtherPlanGovRegNumber]    INT                   NULL,
    [vcOtherConventionNo]       VARCHAR (15)          NULL,
    [tiProgramLength]           TINYINT               NULL,
    [cCollegeTypeID]            [dbo].[UnCollegeType] NULL,
    [vcCollegeCode]             VARCHAR (10)          NULL,
    [siProgramYear]             SMALLINT              NULL,
    [vcPCGSINorEN]              VARCHAR (15)          NULL,
    [vcPCGFirstName]            VARCHAR (35)          NULL,
    [vcPCGLastName]             VARCHAR (50)          NULL,
    [tiPCGType]                 [dbo].[UnPCGType]     NULL,
    [fCLB]                      MONEY                 NOT NULL,
    [fEAPCLB]                   MONEY                 NOT NULL,
    [fPG]                       MONEY                 NOT NULL,
    [fEAPPG]                    MONEY                 NOT NULL,
    [vcPGProv]                  VARCHAR (2)           NULL,
    [fCotisationGranted]        MONEY                 CONSTRAINT [DF_Un_CESP400_fCotisationGranted] DEFAULT (0) NOT NULL,
    [fACESGPart]                MONEY                 CONSTRAINT [DF_Un_CESP400_fACESGPart] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Un_CESP400] PRIMARY KEY CLUSTERED ([iCESP400ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESP400_Un_CESP400__iReversedCESP400ID] FOREIGN KEY ([iReversedCESP400ID]) REFERENCES [dbo].[Un_CESP400] ([iCESP400ID]),
    CONSTRAINT [FK_Un_CESP400_Un_CESP400Type__tiCESP400TypeID] FOREIGN KEY ([tiCESP400TypeID]) REFERENCES [dbo].[Un_CESP400Type] ([tiCESP400TypeID]),
    CONSTRAINT [FK_Un_CESP400_Un_CESP400WithdrawReason__tiCESP400WithdrawReasonID] FOREIGN KEY ([tiCESP400WithdrawReasonID]) REFERENCES [dbo].[Un_CESP400WithdrawReason] ([tiCESP400WithdrawReasonID]),
    CONSTRAINT [FK_Un_CESP400_Un_CESP800__iCESP800ID] FOREIGN KEY ([iCESP800ID]) REFERENCES [dbo].[Un_CESP800] ([iCESP800ID]),
    CONSTRAINT [FK_Un_CESP400_Un_CESPSendFile__iCESPSendFileID] FOREIGN KEY ([iCESPSendFileID]) REFERENCES [dbo].[Un_CESPSendFile] ([iCESPSendFileID]),
    CONSTRAINT [FK_Un_CESP400_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_Un_CESP400_Un_Cotisation__CotisationID] FOREIGN KEY ([CotisationID]) REFERENCES [dbo].[Un_Cotisation] ([CotisationID]),
    CONSTRAINT [FK_Un_CESP400_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP400_CotisationID]
    ON [dbo].[Un_CESP400]([CotisationID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP400_OperID]
    ON [dbo].[Un_CESP400]([OperID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP400_iCESPSendFileID]
    ON [dbo].[Un_CESP400]([iCESPSendFileID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP400_ConventionID]
    ON [dbo].[Un_CESP400]([ConventionID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP400_iReversedCESP400ID]
    ON [dbo].[Un_CESP400]([iReversedCESP400ID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP400_iCESP800ID]
    ON [dbo].[Un_CESP400]([iCESP800ID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP400_vcTransID]
    ON [dbo].[Un_CESP400]([vcTransID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP400_ConventionID_dtTransaction_tiCESP400TypeID_iCESP800ID_iCESP400ID_iReversedCESP400ID]
    ON [dbo].[Un_CESP400]([ConventionID] ASC, [dtTransaction] ASC, [tiCESP400TypeID] ASC, [iCESP800ID] ASC, [iCESP400ID] ASC, [iReversedCESP400ID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP400_vcBeneficiarySIN_tiCESP400TypeID]
    ON [dbo].[Un_CESP400]([vcBeneficiarySIN] ASC, [tiCESP400TypeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP400_iCESPSendFileID_CotisationID]
    ON [dbo].[Un_CESP400]([iCESPSendFileID] ASC, [CotisationID] ASC)
    INCLUDE([iCESP400ID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP400_tiCESP400TypeID_vcBeneficiarySIN_iCESP400ID_ConventionID]
    ON [dbo].[Un_CESP400]([tiCESP400TypeID] ASC, [vcBeneficiarySIN] ASC, [iCESP400ID] ASC, [ConventionID] ASC)
    INCLUDE([dtTransaction], [iCESP800ID], [iCESPSendFileID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP400_iReversedCESP400ID_ConventionID_iCESP400ID_dtTransaction_tiCESP400TypeID_iCESP800ID]
    ON [dbo].[Un_CESP400]([iReversedCESP400ID] ASC, [ConventionID] ASC, [iCESP400ID] ASC, [dtTransaction] ASC, [tiCESP400TypeID] ASC, [iCESP800ID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE STATISTICS [_dta_stat_1672549192_1_6]
    ON [dbo].[Un_CESP400]([iCESP400ID], [iCESP800ID]);


GO
CREATE STATISTICS [_dta_stat_1672549192_1_15_8]
    ON [dbo].[Un_CESP400]([iCESP400ID], [vcBeneficiarySIN], [tiCESP400TypeID]);


GO
CREATE STATISTICS [_dta_stat_1672549192_8_5_1]
    ON [dbo].[Un_CESP400]([tiCESP400TypeID], [ConventionID], [iCESP400ID]);


GO
CREATE STATISTICS [_dta_stat_1672549192_11_8_6]
    ON [dbo].[Un_CESP400]([dtTransaction], [tiCESP400TypeID], [iCESP800ID]);


GO
CREATE STATISTICS [_dta_stat_1672549192_5_15_8_1]
    ON [dbo].[Un_CESP400]([ConventionID], [vcBeneficiarySIN], [tiCESP400TypeID], [iCESP400ID]);


GO
CREATE STATISTICS [_dta_stat_1672549192_1_7_5_11_8]
    ON [dbo].[Un_CESP400]([iCESP400ID], [iReversedCESP400ID], [ConventionID], [dtTransaction], [tiCESP400TypeID]);


GO
CREATE STATISTICS [_dta_stat_1672549192_1_11_8_6_7]
    ON [dbo].[Un_CESP400]([iCESP400ID], [dtTransaction], [tiCESP400TypeID], [iCESP800ID], [iReversedCESP400ID]);


GO
CREATE STATISTICS [_dta_stat_1672549192_5_1_11_8_6_7]
    ON [dbo].[Un_CESP400]([ConventionID], [iCESP400ID], [dtTransaction], [tiCESP400TypeID], [iCESP800ID], [iReversedCESP400ID]);


GO
CREATE STATISTICS [_dta_stat_1672549192_11_13_34_1_15_8]
    ON [dbo].[Un_CESP400]([ConventionNo], [dtTransaction], [fCLB], [iCESP400ID], [tiCESP400TypeID], [vcBeneficiarySIN]);


GO
CREATE STATISTICS [_dta_stat_1672549192_11_13_34_1_2_15_8_20]
    ON [dbo].[Un_CESP400]([ConventionNo], [dtTransaction], [fCESG], [fCLB], [iCESP400ID], [iCESPSendFileID], [tiCESP400TypeID], [vcBeneficiarySIN]);


GO
CREATE STATISTICS [_dta_stat_1672549192_11_15_8_17]
    ON [dbo].[Un_CESP400]([bCESPDemand], [dtTransaction], [tiCESP400TypeID], [vcBeneficiarySIN]);


GO
CREATE STATISTICS [_dta_stat_1672549192_11_34_15_8_20_1_2]
    ON [dbo].[Un_CESP400]([dtTransaction], [fCESG], [fCLB], [iCESP400ID], [iCESPSendFileID], [tiCESP400TypeID], [vcBeneficiarySIN]);


GO
CREATE STATISTICS [_dta_stat_1672549192_11_5]
    ON [dbo].[Un_CESP400]([ConventionID], [dtTransaction]);


GO
CREATE STATISTICS [_dta_stat_1672549192_11_8]
    ON [dbo].[Un_CESP400]([dtTransaction], [tiCESP400TypeID]);


GO
CREATE STATISTICS [_dta_stat_1672549192_15_8_1_5]
    ON [dbo].[Un_CESP400]([ConventionID], [iCESP400ID], [tiCESP400TypeID], [vcBeneficiarySIN]);


GO
CREATE STATISTICS [_dta_stat_1672549192_15_8_17_1_11_13_2_34_20]
    ON [dbo].[Un_CESP400]([bCESPDemand], [ConventionNo], [dtTransaction], [fCESG], [fCLB], [iCESP400ID], [iCESPSendFileID], [tiCESP400TypeID], [vcBeneficiarySIN]);


GO
CREATE STATISTICS [_dta_stat_1672549192_15_8_17_1_11_2_34]
    ON [dbo].[Un_CESP400]([bCESPDemand], [dtTransaction], [fCLB], [iCESP400ID], [iCESPSendFileID], [tiCESP400TypeID], [vcBeneficiarySIN]);


GO
CREATE STATISTICS [_dta_stat_1672549192_17_2_1_15]
    ON [dbo].[Un_CESP400]([bCESPDemand], [iCESP400ID], [iCESPSendFileID], [vcBeneficiarySIN]);


GO
CREATE STATISTICS [_dta_stat_1672549192_2_1_15]
    ON [dbo].[Un_CESP400]([iCESP400ID], [iCESPSendFileID], [vcBeneficiarySIN]);


GO
CREATE STATISTICS [_dta_stat_1672549192_2_15_8_17_34_20]
    ON [dbo].[Un_CESP400]([bCESPDemand], [fCESG], [fCLB], [iCESPSendFileID], [tiCESP400TypeID], [vcBeneficiarySIN]);


GO
CREATE STATISTICS [_dta_stat_1672549192_20_2_1_15_8_17]
    ON [dbo].[Un_CESP400]([bCESPDemand], [fCESG], [iCESP400ID], [iCESPSendFileID], [tiCESP400TypeID], [vcBeneficiarySIN]);


GO
CREATE STATISTICS [_dta_stat_1672549192_34_1_15]
    ON [dbo].[Un_CESP400]([fCLB], [iCESP400ID], [vcBeneficiarySIN]);


GO
CREATE STATISTICS [_dta_stat_1672549192_34_15_20_1_2_8_17_11]
    ON [dbo].[Un_CESP400]([bCESPDemand], [dtTransaction], [fCESG], [fCLB], [iCESP400ID], [iCESPSendFileID], [tiCESP400TypeID], [vcBeneficiarySIN]);


GO
CREATE STATISTICS [_dta_stat_1672549192_34_15_8_20_1]
    ON [dbo].[Un_CESP400]([fCESG], [fCLB], [iCESP400ID], [tiCESP400TypeID], [vcBeneficiarySIN]);


GO
CREATE STATISTICS [_dta_stat_1672549192_5_1_15]
    ON [dbo].[Un_CESP400]([ConventionID], [iCESP400ID], [vcBeneficiarySIN]);


GO
CREATE STATISTICS [_dta_stat_1672549192_6_1_5_11]
    ON [dbo].[Un_CESP400]([ConventionID], [dtTransaction], [iCESP400ID], [iCESP800ID]);


GO
CREATE STATISTICS [_dta_stat_1672549192_6_8_11]
    ON [dbo].[Un_CESP400]([dtTransaction], [iCESP800ID], [tiCESP400TypeID]);


GO
CREATE STATISTICS [_dta_stat_1672549192_8_1_2_15_17_34]
    ON [dbo].[Un_CESP400]([bCESPDemand], [fCLB], [iCESP400ID], [iCESPSendFileID], [tiCESP400TypeID], [vcBeneficiarySIN]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table PCEE des enregistrement 400 (Transactions financières)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’enregistrement 400', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'iCESP400ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du fichier d’envoi', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'iCESPSendFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l''opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la cotisation', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'CotisationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’enregistrement 800 d’erreur s’il y en a un.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'iCESP800ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’enregistrement 400 annulé par celui-ci', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'iReversedCESP400ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type de transaction (11, 13, 14, 19, 21, 23, 22, 24, 25)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'tiCESP400TypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la raison du remboursement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'tiCESP400WithdrawReasonID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de transaction unique expédié à la SCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'vcTransID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de la transaction', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'dtTransaction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro d’enregistrement du régime au gouvernement (ARC)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'iPlanGovRegNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'ConventionNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'NAS ou NE du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'vcSubscriberSINorEN';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'NAS ou NE du bénéficiaire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'vcBeneficiarySIN';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de la cotisation', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'fCotisation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Subvention demandé (0 = Non, 1 = Oui)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'bCESPDemand';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de début des études', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'dtStudyStart';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de semaine consécutive où le bénéficiaire est inscrit à des études postsecondaires au cours de l’année. (30 si université, 34 si un autre établissement d’enseignement)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'tiStudyYearWeek';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de SCEE et de SCEE+', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'fCESG';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant du PAE imputable à la SCEE et SCEE+', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'fEAPCESG';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de cotisation retiré dans l’EPS', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'fPSECotisation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro d’enregistrement de l’autre régime au gouvernement (ARC)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'iOtherPlanGovRegNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de l’autre contrat', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'vcOtherConventionNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Durée du programme EPS', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'tiProgramLength';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''établissement d''enseignement. (01 = Universitas, 02 = Cégep/Collège communautaire, 03 = Établissement privé, 04 = Autres)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'cCollegeTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code postal de l’établissement d’enseignement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'vcCollegeCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Année du program EPS', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'siProgramYear';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'NAS ou NE du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'vcPCGSINorEN';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Prénom du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'vcPCGFirstName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'vcPCGLastName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type de principal responsable (1 = Personne avec un NAS, 2 = Compagnie avec un NE).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'tiPCGType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant du BEC.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'fCLB';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant du PAE imputable au BEC.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'fEAPCLB';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de la subvention provinciale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'fPG';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant du PAE imputable à la subvention provinciale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'fEAPPG';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Province de la subvention provincial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'vcPGProv';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Contient le montant de subvention bonifiée à rembourser', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400', @level2type = N'COLUMN', @level2name = N'fACESGPart';

