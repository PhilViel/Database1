CREATE TABLE [dbo].[tblIQEE_ReponsesImpotsSpeciaux] (
    [iID_Reponse_Impot_Special] INT      IDENTITY (1, 1) NOT NULL,
    [iID_Impot_Special_IQEE]    INT      NULL,
    [iID_Fichier_IQEE]          INT      NULL,
    [iID_Avis]                  BIGINT   NOT NULL,
    [iID_Avis_Precedent]        BIGINT   NULL,
    [cType_Avis]                CHAR (1) NOT NULL,
    [dtDate_Avis]               DATETIME NOT NULL,
    [mMontant_Cotisation]       MONEY    NOT NULL,
    [mMontant_Calcule]          MONEY    NOT NULL,
    [mMontant_Penalite]         MONEY    NULL,
    [mMontant_Interets]         MONEY    NOT NULL,
    [mMontant_Recu]             MONEY    NOT NULL,
    [mSolde]                    MONEY    NOT NULL,
    [mSolde_IQEE]               MONEY    NOT NULL,
    [mSolde_Cotisations_IQEE]   MONEY    NOT NULL,
    [mMontant_IQEE]             MONEY    NOT NULL,
    [mMontant_IQEE_Base]        MONEY    NOT NULL,
    [mMontant_IQEE_Majore]      MONEY    NOT NULL,
    [iID_Paiement_Impot_CBQ]    INT      NULL,
    [iID_Paiement_Impot_MMQ]    INT      NULL,
    [cRaison_Impot_Special]     CHAR (2) NOT NULL,
    [iID_Paiement_Impot_MIM]    INT      NULL,
    CONSTRAINT [PK_IQEE_ReponsesImpotsSpeciaux] PRIMARY KEY CLUSTERED ([iID_Reponse_Impot_Special] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_ReponsesImpotsSpeciaux_ConventionOper_CBQ] FOREIGN KEY ([iID_Paiement_Impot_CBQ]) REFERENCES [dbo].[Un_ConventionOper] ([ConventionOperID]),
    CONSTRAINT [FK_IQEE_ReponsesImpotsSpeciaux_ConventionOper_MIM] FOREIGN KEY ([iID_Paiement_Impot_MIM]) REFERENCES [dbo].[Un_ConventionOper] ([ConventionOperID]),
    CONSTRAINT [FK_IQEE_ReponsesImpotsSpeciaux_ConventionOper_MMQ] FOREIGN KEY ([iID_Paiement_Impot_MMQ]) REFERENCES [dbo].[Un_ConventionOper] ([ConventionOperID]),
    CONSTRAINT [FK_IQEE_ReponsesImpotsSpeciaux_Fichiers__iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE]),
    CONSTRAINT [FK_IQEE_ReponsesImpotsSpeciaux_IQEE_Fichiers__iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE]),
    CONSTRAINT [FK_IQEE_ReponsesImpotsSpeciaux_IQEE_ImpotsSpeciaux__iIDImpotSpecialIQEE] FOREIGN KEY ([iID_Impot_Special_IQEE]) REFERENCES [dbo].[tblIQEE_ImpotsSpeciaux] ([iID_Impot_Special])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_ReponsesDemande_iIDImpotSpecialIQEE]
    ON [dbo].[tblIQEE_ReponsesImpotsSpeciaux]([iID_Impot_Special_IQEE] ASC, [iID_Fichier_IQEE] ASC, [iID_Reponse_Impot_Special] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table des réponses des déclarations des impôts spéciaux de l''IQÉÉ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une réponse à une déclaration d''impôt spécial à l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Reponse_Impot_Special';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la déclaration d''impôt spécial à l''IQÉÉ pour laquelle il y a une réponse.  Le champ est nullable pour permettre de recevoir les réponses de RQ aux déclarations faites par d''autres promoteurs lorsque la demande de l’autre promoteur indique à RQ qu’il désire faire la cession de l’IQÉÉ au régime cessionnaire.  Étant donné que ce n’est pas GUI qui en a fait la demande, il n’y a donc pas de lien possible avec une demande d’IQÉÉ de la table tblIQEE_ImpotsSpeciaux.  Malgré cela, les réponses de ce type ont les mêmes effet ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Impot_Special_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du fichier de réponse de l''IQÉÉ associé à la réponse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Fichier_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéros de l''avis de l''avis de cotisation 42 envoyé par RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Avis';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de l''avis précédent de l''avis de cotisation 42 envoyé par RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Avis_Precedent';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de l''avis de cotisation 42.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'cType_Avis';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de l''avis de cotisation 42.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'dtDate_Avis';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de l''impôt spécial calculé par RQ de l''avis de cotisation 42.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mMontant_Cotisation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de remboursement calculé par le fiduciaire de l''avis de cotisation 42.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mMontant_Calcule';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de pénalité de l''avis de cotisation 42.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mMontant_Penalite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant des intérêts de l''avis de cotisation 42.  Montant positif si des intérêts sont payables par le fiduciaire.  Montant négatif si des intérêts sont payabales au fiduciaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mMontant_Interets';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant considéré comme reçu à Revenu Québec pour le présent avis de cotisation.  Provenance: avis de cotisation 42.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mMontant_Recu';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Provenance: avis de cotisation 42.
C''est le résultat suivant:
Montant de la cotisation + Montant de la pénalité + Montant d''intérêts - Montant reçu.  Si >0 alors le montant doit être remboursé à RQ.  Si < 0 alors le montant est retourné au fiduciaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSolde';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Provenance: avis de cotisation 42.  Solde de l''IQEE pour le contrat en question.  Ce montant tient compte de toutes les transactions survenues dans le contrat et inclut l''IQEE (crédit de base et majoration).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSolde_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Provenance: Avis de cotisation 42.  Solde des cotisations ayant donné droits à l''IQEE.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSolde_Cotisations_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Résultat de: Montant de la Cotisation + Montant de la Penalite - Montant Intérêts - Montant Reçu.  Note: Les intérêts sont soustraits car GUI va payer les intérêts.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mMontant_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant du crédit de base déduit sur le calcul de mMontant_IQEE.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mMontant_IQEE_Base';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de la majoration déduite sur le calcul de mMontant_IQEE.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mMontant_IQEE_Majore';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la transaction CBQ de l''opération IQE.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Paiement_Impot_CBQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la transaction MMQ de l''opération IQE.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Paiement_Impot_MMQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Raison de l''impôt spécial associé à l''avis de cotisation 42.  Valeurs possibles: 01, 02, 11, 22, 23, 24, 31, 32, 41, 51 et 91.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'cRaison_Impot_Special';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la transaction MIM de l''opération IQE.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ReponsesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Paiement_Impot_MIM';

