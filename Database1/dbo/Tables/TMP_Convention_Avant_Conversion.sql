﻿CREATE TABLE [dbo].[TMP_Convention_Avant_Conversion] (
    [ConventionID]                    [dbo].[MoID]              NOT NULL,
    [ConventionNo]                    VARCHAR (15)              NOT NULL,
    [BeneficiaryID]                   [dbo].[MoID]              NOT NULL,
    [SubscriberID]                    [dbo].[MoID]              NOT NULL,
    [ConventionStateID]               [dbo].[MoOptionCode]      NULL,
    [bFormulaireRecu]                 BIT                       NOT NULL,
    [bCESGRequested]                  BIT                       NOT NULL,
    [bACESGRequested]                 BIT                       NOT NULL,
    [bCLBRequested]                   BIT                       NOT NULL,
    [CtiCESPState]                    TINYINT                   NOT NULL,
    [BtiCESPState]                    TINYINT                   NOT NULL,
    [StiCESPState]                    TINYINT                   NOT NULL,
    [SCEEFormulaire93Recu]            BIT                       NULL,
    [SCEEFormulaire93SCEERefusee]     BIT                       NULL,
    [SCEEFormulaire93SCEEPlusRefusee] BIT                       NULL,
    [SCEEFormulaire93BECRefuse]       BIT                       NULL,
    [SCEEAnnexeBTuteurRequise]        BIT                       NULL,
    [SCEEAnnexeBTuteurRecue]          BIT                       NULL,
    [SCEEAnnexeBPRespRequise]         BIT                       NULL,
    [SCEEAnnexeBPRespRecue]           BIT                       NULL,
    [SLastName]                       [dbo].[MoLastNameoption]  NULL,
    [SFirstName]                      [dbo].[MoFirstNameoption] NULL,
    [SSocialNumber]                   [dbo].[MoDescoption]      NULL,
    [iTutorID]                        INT                       NULL,
    [bTutorIsSubscriber]              BIT                       NULL,
    [TSocialNumber]                   [dbo].[MoDescoption]      NULL,
    [TLastName]                       [dbo].[MoLastNameoption]  NULL,
    [TFirstName]                      [dbo].[MoFirstNameoption] NULL,
    [bPCGIsSubscriber]                BIT                       NULL,
    [vcPCGSINorEN]                    VARCHAR (15)              NULL,
    [vcPCGFirstName]                  VARCHAR (40)              NULL,
    [vcPCGLastName]                   VARCHAR (50)              NULL,
    [tiPCGType]                       [dbo].[UnPCGType]         NULL
);

