CREATE TABLE [dbo].[tblTEMP_TransacManuelleIQEE] (
    [IidTransacManuelleIQEE]       INT          IDENTITY (1, 1) NOT NULL,
    [vConventionNo]                VARCHAR (15) NOT NULL,
    [dtDateTransfert]              DATETIME     NOT NULL,
    [dtDateCheque]                 DATETIME     NULL,
    [mIQEE]                        MONEY        NULL,
    [mRendIQEE]                    MONEY        NULL,
    [mIQEE_Plus]                   MONEY        NULL,
    [mRendIQEE_Plus]               MONEY        NULL,
    [cTraiter]                     CHAR (1)     CONSTRAINT [DF_TEMP_TransacManuelleIQEE_cTraiter] DEFAULT ('N') NOT NULL,
    [vcTypeTransfert]              VARCHAR (3)  NOT NULL,
    [mTotal_Transfert]             MONEY        NULL,
    [mCotisations_AyantDroit_IQEE] MONEY        NULL,
    [mCotisations_NonDroit_IQEE]   MONEY        NULL,
    [mCotisations_Avant_IQEE]      MONEY        NULL
);

