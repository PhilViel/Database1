CREATE TABLE [dbo].[tblTEMP_InformationsIQEEPourOUT] (
    [iID_IQEE_OUT]                                  INT          IDENTITY (1, 1) NOT NULL,
    [dtDate_Essais_Transfert]                       DATETIME     NOT NULL,
    [iID_Convention]                                INT          NULL,
    [vcNo_Convention]                               VARCHAR (15) NULL,
    [iID_Convention_Dest]                           INT          NULL,
    [vcNo_Convention_Dest]                          VARCHAR (15) NULL,
    [iID_TIO]                                       INT          NULL,
    [iID_Operation_Out]                             INT          NULL,
    [iID_Operation_TFR]                             INT          NULL,
    [iID_Operation_TIN]                             INT          NULL,
    [iID_Cotisation_Out]                            INT          NULL,
    [bPas_TIO]                                      INT          NULL,
    [bConvention_OUT_pas_fermee]                    BIT          NULL,
    [bOUT_Deplace_deja_IQEE]                        BIT          NULL,
    [bAucun_Solde_IQEE_ou_Rendements]               BIT          NULL,
    [bAutre_sortie_IQEE_apres_transfert]            BIT          NULL,
    [bCompte_en_perte]                              BIT          NULL,
    [bChangement_Benef_non_reconnu_avant_transfert] BIT          NULL,
    [bTransfert_non_reconnu_avant_transfert]        BIT          NULL,
    [bRetrait_premature_avant_transfert]            BIT          NULL,
    [bConvention_Destination_Fermee]                BIT          NULL,
    [bTransfert_a_0]                                BIT          NULL,
    [bPresence_Transfert_BEC]                       BIT          NULL,
    [bPresence_Transfert_BEC_Avec_Rendement_BEC]    BIT          NULL,
    [bAutre_raison_rejet_dans_meme_convention]      BIT          NULL,
    [bAutres_raisons]                               BIT          NULL,
    [bAdmissible_Transfert_IQEE]                    BIT          NULL,
    [mSolde_CBQ_Avant]                              MONEY        NULL,
    [mSolde_MMQ_Avant]                              MONEY        NULL,
    [mSolde_MIM_Avant]                              MONEY        NULL,
    [mSolde_ICQ_Avant]                              MONEY        NULL,
    [mSolde_IMQ_Avant]                              MONEY        NULL,
    [mSolde_IIQ_Avant]                              MONEY        NULL,
    [mSolde_III_Avant]                              MONEY        NULL,
    [mSolde_IQI_Avant]                              MONEY        NULL,
    [mMontant_Total_Transfert]                      MONEY        NULL,
    [mMontant_JVM]                                  MONEY        NULL,
    [fPourcentage_Transfert]                        FLOAT (53)   NULL,
    [mTransfert_CBQ]                                MONEY        NULL,
    [mTransfert_MMQ]                                MONEY        NULL,
    [mTransfert_MIM]                                MONEY        NULL,
    [mTransfert_ICQ]                                MONEY        NULL,
    [mTransfert_IMQ]                                MONEY        NULL,
    [mTransfert_IIQ]                                MONEY        NULL,
    [mTransfert_III]                                MONEY        NULL,
    [mTransfert_IQI]                                MONEY        NULL,
    [mSolde_CBQ_Apres]                              MONEY        NULL,
    [mSolde_MMQ_Apres]                              MONEY        NULL,
    [mSolde_MIM_Apres]                              MONEY        NULL,
    [mSolde_ICQ_Apres]                              MONEY        NULL,
    [mSolde_IMQ_Apres]                              MONEY        NULL,
    [mSolde_IIQ_Apres]                              MONEY        NULL,
    [mSolde_III_Apres]                              MONEY        NULL,
    [mSolde_IQI_Apres]                              MONEY        NULL,
    CONSTRAINT [PK_TEMP_InformationsIQEEPourOUT] PRIMARY KEY CLUSTERED ([iID_IQEE_OUT] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_TEMP_InformationsIQEEPourOUT_dtDateEssaisTransfert]
    ON [dbo].[tblTEMP_InformationsIQEEPourOUT]([dtDate_Essais_Transfert] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_TEMP_InformationsIQEEPourOUT_iIDConvention]
    ON [dbo].[tblTEMP_InformationsIQEEPourOUT]([iID_Convention] ASC) WITH (FILLFACTOR = 90);

