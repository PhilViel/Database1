/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : psIQEE_ImporterFichierCOT
Nom du service  : Importer un fichier de réponses COT
But             : Traiter un fichier de réponses du type "Avis de cotisation" de Revenu Québec dans le module de l'IQÉÉ.  Insertion de
Facette         : IQÉÉ

Paramètres d’entrée :
        Paramètre               Description
        --------------------    -----------------------------------------------------------------
        iID_Fichier_IQEE        Identifiant unique du fichier d'erreur de l'IQÉÉ en cours d'importation.
        siAnnee_Fiscale         Année fiscale des réponses du fichier en cours d'importation.                            
        cID_Langue              Langue du traitement.

Exemple d’appel : Cette procédure doit uniquement être appelé du service "psIQEE_ImporterFichierReponses".

Paramètres de sortie:    
        Table                       Champ                               Description
        ------------------------    --------------------------------    ---------------------------------
        S/O                         dtDate_Paiement_Courriel            Date de paiement qui servira au formatage du courriel aux destinataires
        S/O                         mMontant_Total_Paiement_Courriel    Montant total du paiement qui servira au formatage du courriel aux destinataires    
        S/O                         bInd_Erreur                         Indicateur s'il y a eue une erreur dans le traitement.

Historique des modifications:
        Date        Programmeur                 Description                                
        ----------  ------------------------    -----------------------------------------
        2009-10-26  Éric Deshaies               Création du service                        
        2012-09-07  Éric Michaud                Modification pour ajout ligne 42
        2012-09-18  Stéphane Barbeau            Ajustements opération IQE et ajout traitement avis de cotisation fictif.
        2012-09-20  Stéphane Barbeau            Ajout de la division dans le calcul de @mMontant_IQEE_Base et gestion du cas des impôts spéciaux déduits à 0$.
        2012-10-30  Stéphane Barbeau            Traitement de statistiques avec l'avis de cotisation fictif et la table tblIQEE_StatistiquesImpotsSpeciaux.
        2012-11-07  Stéphane Barbeau            Répartition des montants des réponses pour minimiser les soldes négatifs des comptes CBQ et MMQ.
        2012-11-08  Stéphane Barbeau            Mesure préventive lorsque @mMontant_Recu = 0
        2012-11-12  Stéphane Barbeau            Cas particuliers de balancement de comptes où soit @iID_Transaction_Convention_CBQ ou @iID_Transaction_Convention_CBQ est NULL.
        2012-11-12  Stéphane Barbeau            Correction assignations @des iID_Transaction CBQ et MMQ nuls dans tblIQEE_ReponsesImpotsSpeciaux
        2012-12-04  Stéphane Barbeau            IF (@mSoldeFixe_CBQ < 0) AND (@mSoldeFixe_MMQ > 0) : Ajout de la validation IF @iID_Transaction_Convention_CBQ IS NULL.
        2013-08-09  Stéphane Barbeau            Créer une nouvelle opération de subvention avec @dtDate_Paiement plutôt que la date du jour. 
        2014-03-25  Stéphane Barbeau            Prise en charge de @dtDate_Paiement lorsqu'il n'y a pas de paiement et de @mMontant_Total_A_Payer_Courriel lorsqu'il n'y a pas d'avis fictif.
        2014-03-31  Stéphane Barbeau            Ne plus utiliser @mMontant_Recu, toujours @mMontant_Calcule.  
        2014-05-09  Stéphane Barbeau            Ajout du paramètre de sortie @mSolde_Avis_Fictif. 
        2014-08-28  Stéphane Barbeau            Ajout de @dtDate_PaiementDuFichier pour éviter d'écrire la valeur @dtDate_Paiement tblIQEE_Fichiers
        2015-05-26  Stéphane Barbeau            Importation réponses T06-1, SET @mMontant_IQEE = ... + @mMontant_Interets 
                                                    IF (@mMontant_Cotisation <> @mMontant_Calcule) OR @tiCode_Version = 1 --@mMontant_DeclareImpotSpecial
        2015-06-01  Stéphane Barbeau            Ajout du traitement de l'ajout d'Intérêts (MIM).
        2015-06-26  Stéphane Barbeau            Utilisation exclusive de @mMontant_Calcule: RQ semble être revenu sur sa décision, ajustements faits pour pouvoir traiter aussi avec @mMontant_Recu.
                                                    SET @mMontant_IQEE : Retrait de @mMontant_Interets de la formule de la somme.
                                                    Activation du code mettre à jour le T06-0 au statut 'T' dans les des annulations - reprises.
        2016-03-08  Patrice Côté                Ajout de la gestion de l'id de transaction.
        2016-11-22  Steeve Picard               Inclure le montant de solde de l'avis précédent dans le renversement de l'IQÉÉ pour un avis d'annulation
        2016-12-15  Steeve Picard               Correction du calcul du surplus que RQ vient chercher
        2017-09-11  Steeve Picard               Correction pour récupérer les soldes de l'IQÉÉ
        2017-10-02  Steeve Picard               Fixe lorsque la réponse est pour 2 transactions et qu'au moins une des 2 est de sous-type 23
        2018-02-08  Steeve Picard               Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
        2018-05-08  Steeve Picard               Conversion des champs «fID_Avis & fID_Avis_Precedent» de «float» à «integer»
        2018-08-01  Steeve Picard               Correction dans le calcul du montant remboursé lorsque «tiCode_Version = 1»
        2018-01-01  Steeve Picard               Correction lorsqu'il n'y a pas de date de paiement
*********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_ImporterFichierCOT
(
    @iID_Fichier_IQEE INT,
    @siAnnee_Fiscale SMALLINT,
    @cID_Langue CHAR(3),
    @iID_Connexion int,
    @dtDate_Paiement_Courriel DATETIME OUTPUT,
    @mMontant_Total_A_Payer_Courriel MONEY OUTPUT,
    @mSolde_Avis_Fictif MONEY OUTPUT,
    @bInd_Erreur BIT OUTPUT
)
AS
BEGIN
    
    -- Déclarations des variables locales
    DECLARE @cLigne CHAR(1000),
            @mMontant_Total_Paiement MONEY,
            @dtDate_Production_Paiement DATETIME,
            @dtDate_Paiement DATETIME,
            @iNumero_Paiement INT,
            @vcInstitution_Paiement VARCHAR(4),
            @vcTransit_Paiement VARCHAR(5),
            @vcCompte_Paiement VARCHAR(12),
            @mMontant_Total_A_Payer MONEY,
            @mMontant_Total_Cotise MONEY,
            @mMontant_Total_Recu MONEY,
            @mMontant_Total_Interets MONEY,
            @mSolde_Paiement_RQ MONEY,    
            @iID_Impot_Special_IQEE int,
            @dtDate_Evenement DATE,
            @iID_Avis bigint,
            @iID_Avis_Precedent bigint,
            @cType_Avis Varchar(1),
            @dtDate_Avis datetime,
            @dtDate_PreAvis datetime,
            @mMontant_Cotisation money,
            @mMontant_Calcule money,
            @mMontant_Penalite money,
            @mMontant_Interets money,
            @mMontant_Recu money,
            @mSolde money,
            @mSolde_IQEE money,
            @mSolde_Cotisations_IQEE money,
            @mMontant_IQEE MONEY,
            @mMontant_IQEE_Base MONEY,
            @mMontant_IQEE_Majore MONEY,
            @iID_Paiement_Impot_CBQ INT,
            @iID_Paiement_Impot_MMQ INT,
            @iID_Paiement_Impot_MIM INT,   -- Intérêts
            @Sous_Type varchar(24),
            @iID_Sous_Type int,
            @siAnnee int,
            @vcNo_Convention Varchar(15),
            @ImpotsSpeciaux_mSolde_IQEE_Base money,
            @iID_Reponse_Impot_Special int,
            @iID_Transaction_Convention_CBQ INT,
            @iID_Transaction_Convention_MMQ int,
            @iID_Transaction_Convention_MIM int, -- Intérêts
                                
            @vcOPER_MONTANTS_CREDITBASE VARCHAR(100),
            @vcOPER_MONTANTS_MAJORATION VARCHAR(100),
            @iID_Operation int,
            @iID_Convention int,
            @dttoday DATETIME = getdate(),
            @cID_Type_Operation CHAR(3),
            @dtDate_Sommaire_Avis_Cotisation_Impots_Speciaux DATETIME,
            @mMontant_DemandeImpotSpecial money,
            @tiCode_Version tinyint,
            
            -- Variable d'interaction avec la table tblIQEE_StatistiquesImpotsSpeciaux
            @iID_Statistique_Impots_Speciaux int,
            @iNb_Avis_Zero int = 0,
            @iNb_Avis_Debiteurs int = 0,
            @iNb_Avis_Crediteurs int = 0,
            @mTotal_Cotisations_Avis_Zero money = 0,
            @mTotal_Cotisations_Avis_Debiteurs money = 0,
            @mTotal_Cotisations_Avis_Crediteurs money = 0,
            @mTotal_Cotisations_Avis_Fictif money = 0,
            @mTotal_Cotisations_Total_Avis money = 0,
            @mSomme_Accaparee_Avis_Zero money = 0,
            @mSomme_Accaparee_Avis_Debiteurs money = 0,
            @mSomme_Accaparee_Avis_Crediteurs money = 0,
            @mSomme_Accaparee_Avis_Fictif money = 0,
            @mSomme_Accaparee_Total_Avis money = 0,
            @bSomme_Accaparee_Balance bit = 0,
            @mEcart_Somme_Accaparee_Total_Avis money = 0,
            @mInterets_Avis_Zero money = 0,
            @mInterets_Avis_Debiteurs money = 0,
            @mInterets_Avis_Crediteurs money = 0,
            @mInterets_Avis_Fictif money = 0,
            @mInterets_Total_Avis money = 0,
            @mSolde_Avis_Zero money = 0,
            @mSolde_Avis_Debiteurs money = 0,
            @mSolde_Avis_Crediteurs money = 0,
            @mSolde_Total_Avis money = 0,
            @bSolde_Avis_Balance bit = 0,
            @mEcart_Solde_Total_Avis bit = 0,
            @vcID_Transaction_RQ VARCHAR (176),
            @iID_LigneFichier int,
            @IsDebug bit = dbo.fn_IsDebug()
    
    DECLARE @mCompare_Somme_Accaparee MONEY        
    DECLARE @fID_Regime float
    DECLARE @mSoldeFixe_CBQ MONEY
    DECLARE @mSoldeFixe_MMQ MONEY
    --DECLARE @mMontant_Recu_Calcule MONEY  -- Cette variable remplace @mMontant_Recu dans le calcul de la variable @mMontant_IQEE
    DECLARE @dtDate_PaiementDuFichier DATETIME
                                    
    -- Initialisations
    SET @dtDate_Paiement_Courriel = NULL
    SET @mMontant_Total_A_Payer_Courriel = 0
    SET @bInd_Erreur = 0
    SET @cID_Type_Operation = dbo.fnOPER_ObtenirTypesOperationCategorie('IQEE_CODE_INJECTION_MONTANT_CONVENTION')
    SET @vcOPER_MONTANTS_CREDITBASE = dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_MONTANTS_CREDITBASE')
    SET @vcOPER_MONTANTS_MAJORATION = dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_MONTANTS_MAJORATION')
    
    ------------------------------------------------------------------
    -- Traiter le sommaire de la cotisation (type d'enregistrement 41)
    ------------------------------------------------------------------
    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierCOT          - '+
            'Traiter le sommaire de la cotisation (type d''enregistrement 41).')

    -- Trouver les types d'enregistrement 41 (sommaire de la cotisation)
    DECLARE @nombreLignes INT

    SELECT @cLigne = Min(LF.cLigne),
           @nombreLignes = COUNT(*)
    FROM tblIQEE_LignesFichier LF
    WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
      AND SUBSTRING(LF.cLigne,1,2) = '41'
    GROUP BY LF.cLigne
    
    IF @nombreLignes <= 0
    BEGIN
        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('2',10,'       Erreur: Pas d''enregistrement de type 41 (sommaire de la cotisation).')
        GOTO ERREUR_TRAITEMENT
    END
    
    IF @nombreLignes > 1
    BEGIN
        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('2',10,'       Erreur: Plusieurs enregistrements de type 41 (sommaire de la cotisation).')
        GOTO ERREUR_TRAITEMENT
    END

    -- Lire les informations de la transaction
    --SET @dtDate_Production_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,17,8),'D',NULL,NULL) AS DATETIME)
    SET @dtDate_Sommaire_Avis_Cotisation_Impots_Speciaux = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,17,8),'D',NULL,NULL) AS DATETIME)
    SET @mMontant_Total_Cotise = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,25,12), '9', NULL, 2) AS MONEY)
    SET @mMontant_Total_Recu = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,37,12), '9', NULL, 2) AS MONEY)
    SET @mMontant_Total_Interets = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,49,12), '9', NULL, 2) AS MONEY)
    SET @mSolde_Paiement_RQ = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,61,12), '9', NULL, 2) AS MONEY)

    -- Déterminer si c'est un montant à payer ou à recevoir
    SET @mMontant_Total_A_Payer = NULL
    SET @mMontant_Total_Paiement = NULL

    IF @mSolde_Paiement_RQ > 0
        BEGIN
            SET @mMontant_Total_A_Payer = @mSolde_Paiement_RQ
            SET @mMontant_Total_A_Payer_Courriel = @mMontant_Total_A_Payer_Courriel + @mMontant_Total_A_Payer*-1
        END

    IF @mSolde_Paiement_RQ < 0
        BEGIN
            SET @mMontant_Total_Paiement = @mSolde_Paiement_RQ*-1
            SET @mMontant_Total_A_Payer_Courriel = @mMontant_Total_A_Payer_Courriel + @mMontant_Total_Paiement
        END

    -- Déterminer les informations du paiement s'il y a un paiement
    IF @mMontant_Total_Paiement IS NOT NULL AND @mMontant_Total_Paiement > 0 AND SUBSTRING(@cLigne,85,8) <> REPLACE(SPACE(8), ' ', '0')
        BEGIN
            IF dbo.FN_IsDebug() <> 0 BEGIN 
                PRINT '@dtDate_Paiement :' + SUBSTRING(@cLigne,85,8)
                PRINT '@iNumero_Paiement :' + SUBSTRING(@cLigne,93,8)
                PRINT '@vcInstitution_Paiement :' + SUBSTRING(@cLigne,101,4)
                PRINT '@vcTransit_Paiement :' + SUBSTRING(@cLigne,105,5)
                PRINT '@vcCompte_Paiement :' + SUBSTRING(@cLigne,110,12)
            END 
            SET @dtDate_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,85,8), 'D', NULL, NULL) AS DATETIME)
            SET @iNumero_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,93,8), '9', NULL, 0) AS INT)
            SET @vcInstitution_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,101,4),'X',4,NULL) AS VARCHAR(4))
            SET @vcTransit_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,105,5),'X',5,NULL) AS VARCHAR(5))
            SET @vcCompte_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,110,12),'X',12,NULL) AS VARCHAR(12))
        END
    ELSE
        BEGIN
            SET @iNumero_Paiement = NULL
            SET @dtDate_Paiement = GETDATE()  -- Mettre la date du jour au cas où une opération IQE doit être faite
            SET @vcInstitution_Paiement = NULL
            SET @vcTransit_Paiement = NULL
            SET @vcCompte_Paiement = NULL
        END

    -- Retenir les informations pour le courriel
    SET @dtDate_Paiement_Courriel = @dtDate_Paiement

    IF @iNumero_Paiement is NULL
        SET @dtDate_PaiementDuFichier  = NULL
    ELSE
        SET @dtDate_PaiementDuFichier  = @dtDate_Paiement
                    
    -- Mettre à jour le fichier
    UPDATE tblIQEE_Fichiers
    SET mMontant_Total_Paiement = @mMontant_Total_Paiement,
        mMontant_Total_A_Payer = @mMontant_Total_A_Payer,
        mMontant_Total_Cotise = @mMontant_Total_Cotise,
        mMontant_Total_Recu = @mMontant_Total_Recu,
        mMontant_Total_Interets = @mMontant_Total_Interets,
        mSolde_Paiement_RQ = @mSolde_Paiement_RQ,
        iNumero_Paiement = @iNumero_Paiement,
        dtDate_Paiement = @dtDate_PaiementDuFichier,
        vcInstitution_Paiement = @vcInstitution_Paiement,
        vcTransit_Paiement = @vcTransit_Paiement,
        vcCompte_Paiement = @vcCompte_Paiement,
        dtDate_Sommaire_Avis_Cotisation_Impots_Speciaux = @dtDate_Sommaire_Avis_Cotisation_Impots_Speciaux
    WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

    ------------------------------------------------------------------
    -- Traiter les avis de cotisation (type d'enregistrement 42)
    ------------------------------------------------------------------
    DECLARE curType42 CURSOR FOR
        SELECT cLigne
        FROM tblIQEE_LignesFichier LF
        WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
          AND SUBSTRING(LF.cLigne,1,2) = '42'

    OPEN curType42
    FETCH NEXT FROM curType42 INTO @cLigne

    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierCOT          - '+
            'Traiter le sommaire de la cotisation (type d''enregistrement 42).')

    WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Réinitialisation des variables pour garantir l'intégrité du traitement en boucle
            SET @fID_Regime = NULL
            SET @siAnnee = NULL
            SET @vcNo_Convention = NULL
            SET @iID_Avis =             NULL
            SET @iID_Avis_Precedent = NULL
            SET @cType_Avis =         NULL
            SET @dtDate_Avis =         NULL
            SET @dtDate_PreAvis = NULL
            SET @mMontant_Cotisation = NULL
            SET @mMontant_Calcule =     NULL
            SET @mMontant_Penalite = NULL
            SET @mMontant_Interets = NULL
            SET @mMontant_Recu =     NULL
            SET @mSolde =             NULL
            SET @mSolde_IQEE =         NULL
            SET @mSolde_Cotisations_IQEE = NULL
            SET @mMontant_IQEE = NULL
            SET @mMontant_IQEE_Base = NULL
            SET @mMontant_IQEE_Majore = NULL
            SET @iID_Reponse_Impot_Special = NULL
            SET @iID_Operation = NULL
            SET @iID_Transaction_Convention_CBQ = NULL
            SET @iID_Transaction_Convention_MMQ = NULL
            SET @mSoldeFixe_CBQ = NULL
            SET @mSoldeFixe_MMQ = NULL
            SET @vcID_Transaction_RQ = NULL
                
            SET @siAnnee = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,3,4), '9', NULL, 0) AS INT)
            SET @vcNo_Convention = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,17,15),'X',15,NULL) AS VARCHAR(15))
            SET @fID_Regime = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,32,10), '9', NULL, 0) AS FLOAT)
            SET @iID_Avis                = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,43,10), '9', NULL, 0) AS bigint)
            SET @iID_Avis_Precedent      = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,53,10), '9', NULL, 0) AS bigint) 
            SET @cType_Avis              = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,42,1), 'X', 1, NULL) AS Varchar(1))
            SET @dtDate_Avis             = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,63,8), 'D', NULL,NULL) AS DATETIME) 
            SET @mMontant_Cotisation     = Isnull(CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,71,9), '9', NULL, 2) AS MONEY),0.00)
            SET @mMontant_Calcule        = Isnull(CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,80,9), '9', NULL, 2) AS MONEY),0.00)
            SET @mMontant_Penalite       = Isnull(CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,89,9), '9', NULL, 2) AS MONEY),0.00)
            SET @mMontant_Interets       = Isnull(CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,98,9), '9', NULL, 2) AS MONEY),0.00)
            SET @mMontant_Recu           = Isnull(CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,107,9), '9', NULL, 2) AS MONEY),0.00)
            SET @mSolde                  = Isnull(CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,116,9), '9', NULL, 2) AS MONEY),0.00)
            SET @mSolde_IQEE             = Isnull(CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,125,9), '9', NULL, 2) AS MONEY),0.00)
            SET @mSolde_Cotisations_IQEE = Isnull(CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,134,9), '9', NULL, 2) AS MONEY),0.00)
                
            -- L'avis de cotisation n'est pas fictif
            IF @fID_Regime > 0  
                BEGIN     
                    IF @IsDebug <> 0 PRINT ''
                    IF @IsDebug <> 0 PRINT '@vcNo_Convention       : ' + @vcNo_Convention
                    
                    DECLARE @vcID_Transaction_Liste VARCHAR(200),
                            @vcSous_Type_Liste VARCHAR(22),
                            @nPos int

                    SET @vcSous_Type_Liste = LTrim(RTrim(Cast(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,143,22), 'X',22, NULL) as varchar(24))))
                    SET @vcID_Transaction_Liste = RTRIM(LTRIM(CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,209,176), 'X', NULL, NULL) AS Varchar(176))))

                    WHILE LEN(@vcID_Transaction_Liste) > 0
                    BEGIN
                        SET @nPos = CHARINDEX(' ', @vcID_Transaction_Liste, 1)
                        IF @nPos = 0
                            SET @nPos = LEN(@vcID_Transaction_Liste) + 1

                        SELECT @iID_LigneFichier = cast('0'+LEFT(@vcID_Transaction_Liste, @nPos - 1) as int),
                               @Sous_Type = LEFT(@vcSous_Type_Liste, 2)

                        SELECT @vcID_Transaction_Liste = SubString(@vcID_Transaction_Liste, @nPos + 1, LEN(@vcID_Transaction_Liste)),
                               @vcSous_Type_Liste = SubString(@vcSous_Type_Liste, 3, LEN(@vcSous_Type_Liste))
                            
                        IF @IsDebug <> 0 PRINT '@vcID_Transaction_RQ: '+ LTRIM(STR(@iID_LigneFichier))
                        IF @IsDebug <> 0 PRINT '@Sous_Type: ' + @Sous_Type
                        
                        SET @iid_Sous_Type = NULL
                        SET @iID_Impot_Special_IQEE = NULL
                        SET @dtDate_Evenement = NULL
                        SET @mMontant_DemandeImpotSpecial = NULL 
                        SET @ImpotsSpeciaux_mSolde_IQEE_Base = NULL
                        SET @iID_Convention = NULL
                        SET @tiCode_Version = NULL
                        declare @cStatut_Reponse char(1) 

                        SELECT @iid_Sous_Type = iID_Sous_Type 
                        FROM tblIQEE_SousTypeEnregistrement
                        WHERE cCode_Sous_Type = @Sous_Type

                        SELECT TOP 1 
                                @iID_Impot_Special_IQEE = ISP.iID_Impot_Special,
                                @dtDate_Evenement = DATEADD(MINUTE, -1, CAST(CAST(ISP.dtDate_Evenement AS DATE) AS DATETIME)),
                                --@dtDate_Evenement = F.dtDate_Creation_Fichiers,
                                @mMontant_DemandeImpotSpecial = ISP.mIQEE_ImpotSpecial, 
                                @ImpotsSpeciaux_mSolde_IQEE_Base = ISP.mSolde_IQEE_Base,
                                @iID_Convention = ISP.iID_Convention,
                                @tiCode_Version = ISP.tiCode_Version,
                                @cStatut_Reponse = ISP.cStatut_Reponse
                        FROM 
                            dbo.tblIQEE_ImpotsSpeciaux ISP
                            join dbo.tblIQEE_Fichiers F on F.iID_Fichier_IQEE = ISP.iID_Fichier_IQEE
                        WHERE 
                            (   ISNULL(@iID_LigneFichier, 0) = 0
                                AND ISP.vcNo_Convention = @vcNo_Convention
                                AND ISP.siAnnee_Fiscale = @siAnnee
                                AND ISP.iID_Sous_Type = @iid_Sous_Type
                                --AND ISP.cStatut_Reponse = 'A'
                            )    
                            OR (ISNULL(@iID_LigneFichier, 0) > 0 
                                AND ISP.iID_Ligne_Fichier = @iID_LigneFichier
                            )
                        ORDER BY
                            ISP.iID_Impot_Special DESC

                        IF @IsDebug <> 0 BEGIN
                            PRINT '@iID_Impot_Special: '+ LTRIM(STR(@iID_Impot_Special_IQEE))
                            PRINT '@tiCode_Version   : '+ LTRIM(STR(@tiCode_Version))
                            PRINT '@cStatut_Reponse  : '+ @cStatut_Reponse
                            PRINT '@dtDate_Evenement : '+ CONVERT(VARCHAR(10), @dtDate_Evenement, 120)
                        END
                
                        -- Mesure préventive du Question DA16434 #3.  Dans certaines réponses RQ déclare que la somme reçu est de 0$ par erreur.  
                        -- La solution de RQ:  Prendre le montant aux positions [080-088] (@mMontant_Calcule).  
                        -- 2014-03-31.  Dans tous les cas, il ne faut plus utiliser @mMontant_Recu, toujours @mMontant_Calcule.  
                        -- Il a été prouvé que RQ peut se tromper sur le champ @mMontant_Recu dans les enregistrements 42 
                        -- 2015-06-25: RQ semble être revenu sur sa décision, ajustements faits pour pouvoir traiter les deux cas.

                        --SET @mMontant_IQEE = @mMontant_Cotisation + @mMontant_Penalite - @mMontant_Recu
                        SET @mMontant_IQEE = @mMontant_Cotisation - @mMontant_Calcule
                
                        --Section debug
                        IF @IsDebug <> 0 BEGIN 
                            PRINT '@mMontant_Cotisation   : ' + str(@mMontant_Cotisation, 10, 2)
                            PRINT '@mMontant_Calcule      : ' + str(@mMontant_Calcule, 10, 2)
                            PRINT '@mMontant_Interets     : ' + str(@mMontant_Interets, 10, 2)
                            PRINT '@mMontant_Recu         : ' + str(@mMontant_Recu, 10, 2)
                            PRINT '@mMontant_Solde        : ' + str(@mSolde, 10, 2)
                            PRINT '@mMontant_Solde_IQEE   : ' + str(@mSolde_IQEE, 10, 2)
                            PRINT '@mMontant_IQEE         : ' + str(@mMontant_IQEE, 10, 2)
                        END 

                        -- 2016-11-22   Retrouve les montants de l'avis de l'avis précédent
                        IF @iID_Avis_Precedent > 0 and @cType_Avis = '2'
                        BEGIN
                            DECLARE @mMontant_Cotisation_Previous money,
                                    @mMontant_Calcule_Previous MONEY,
                                    @mMontant_IQEE_Previous MONEY

                            SELECT --@mMontant_IQEE = @mMontant_IQEE - (mSolde - mSolde_IQEE - mMontant_Interets)
                                   --@mMontant_IQEE = @mMontant_IQEE - (mMontant_IQEE + 0) --mMontant_Interets)
                                   @dtDate_Evenement = I.dtDate_Evenement,
                                   @dtDate_PreAvis = dtDate_Avis,
                                   @mMontant_Cotisation_Previous = mMontant_Cotisation,
                                   @mMontant_Calcule_Previous = mMontant_Calcule,
                                   @mMontant_IQEE_Previous = 0
                              FROM tblIQEE_ReponsesImpotsSpeciaux R JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Impot_Special = R.iID_Impot_Special_IQEE
                             WHERE iID_Avis = @iID_Avis_Precedent

                            IF @tiCode_Version = 1
                                SET @mMontant_IQEE = -@mMontant_Cotisation_Previous
                            ELSE 
                                SET @mMontant_IQEE = @mMontant_IQEE - (@mMontant_Cotisation_Previous- @mMontant_Calcule_Previous)

                            IF @IsDebug <> 0 begin
                                PRINT 'Previous               : ' + IsNull(Convert(varchar(20), @dtDate_Evenement, 120), '')
                                PRINT '  @mMontant_Cotisation : ' + str(@mMontant_Cotisation_Previous, 10, 2)
                                PRINT '  @mMontant_Calcule    : ' + str(@mMontant_Calcule_Previous, 10, 2)
                                PRINT '  @mMontant_IQEE       : ' + str(@mMontant_IQEE, 10, 2)
                            END

                        END 
                
                        IF @mSolde > 0 
                            BEGIN
                                    SET @iNb_Avis_Debiteurs = @iNb_Avis_Debiteurs + 1
                                    SET @mTotal_Cotisations_Avis_Debiteurs = @mTotal_Cotisations_Avis_Debiteurs + @mMontant_Cotisation
                                    SET @mSomme_Accaparee_Avis_Debiteurs = @mSomme_Accaparee_Avis_Debiteurs + @mMontant_Calcule
                                    SET @mInterets_Avis_Debiteurs = @mInterets_Avis_Debiteurs + @mMontant_Interets
                            END
                        ELSE
                            BEGIN
                                IF @mSolde < 0
                                    BEGIN
                                        SET @iNb_Avis_Crediteurs = @iNb_Avis_Crediteurs +1
                                        SET @mTotal_Cotisations_Avis_Crediteurs = @mTotal_Cotisations_Avis_Crediteurs + @mMontant_Cotisation
                                        SET @mSomme_Accaparee_Avis_Crediteurs = @mSomme_Accaparee_Avis_Crediteurs + @mMontant_Calcule
                                        SET @mInterets_Avis_Crediteurs = @mInterets_Avis_Crediteurs + @mMontant_Interets
                                    END
                                ELSE -- @mSolde = 0
                                    BEGIN
                                        SET @iNb_Avis_Zero = @iNb_Avis_Zero + 1
                                        SET @mTotal_Cotisations_Avis_Zero = @mTotal_Cotisations_Avis_Zero + @mMontant_Cotisation
                                        SET @mSomme_Accaparee_Avis_Zero = @mSomme_Accaparee_Avis_Zero + @mMontant_Calcule
                                        SET @mInterets_Avis_Zero = @mInterets_Avis_Zero + @mMontant_Interets
                                    END
                            END    

                        -- Gestion du cas des impôts spéciaux calculés par GUI à 0$.  2 sources: tblIQEE_ImpotsSpeciaux. et @mMontant_Calcule du segment 42
                        -- Pour régler le cas de la question DA16434 adressée à RQ.
                        IF @mMontant_IQEE = 0.00
                            SET @mMontant_IQEE_Base = 0.00
                        ELSE
                        BEGIN
                            --IF @mMontant_Calcule =0.00 --IF @mMontant_DeclareImpotSpecial=0.00
                            --    SET @mMontant_IQEE_Base = @mMontant_IQEE
                            --ELSE
                            --    SET @mMontant_IQEE_Base = isnull(round((@ImpotsSpeciaux_mSolde_IQEE_Base / @mMontant_DemandeImpotSpecial * @mMontant_IQEE),2),0.00)
                            --    --SET @mMontant_IQEE_Base = isnull(round((@ImpotsSpeciaux_mSolde_IQEE_Base / @mMontant_Calcule * @mMontant_IQEE),2),0.00)

                            -- 2016-11-22   Calculer le solde de chaque compte avant le renversement de l'IQÉÉ
                            SELECT @mSoldeFixe_CBQ = dbo.fnIQEE_CalculerSoldeFixe_CreditBase_Convention(@iID_Convention, @dtDate_Evenement) --IsNull(@dtDate_PreAvis, @dtDate_Avis)) --GETDATE())
                            SELECT @mSoldeFixe_MMQ = dbo.fnIQEE_CalculerSoldeFixe_Majoration_Convention(@iID_Convention, @dtDate_Evenement) --IsNull(@dtDate_PreAvis, @dtDate_Avis)) --GETDATE())
                            IF @IsDebug <> 0 begin
                                PRINT '@mSoldeFixe_CBQ        : ' + str(@mSoldeFixe_CBQ, 10, 2)
                                PRINT '@mSoldeFixe_MMQ        : ' + str(@mSoldeFixe_MMQ, 10, 2)
                            END
                        
                            -- 2016-11-22   Détermine le ratio de partage de l'IQÉÉ entre le crédit de base & le crédit majoré
                            DECLARE @fRatioIQEE decimal(12,10) = 1.0
                            SET @mMontant_DemandeImpotSpecial = @mSoldeFixe_CBQ + @mSoldeFixe_MMQ
                            IF @mMontant_DemandeImpotSpecial <> 0
                                SET @fRatioIQEE = @mSoldeFixe_CBQ / @mMontant_DemandeImpotSpecial
                            IF @IsDebug <> 0 PRINT '@fRatioIQEE            : ' + str(@fRatioIQEE * 100, 10, 4)

                            -- 2016-11-22   Répartir le montant de l'IQÉÉ à renverser selon le ratio calculé
                            SET @mMontant_IQEE_Base = isnull(round((@mMontant_IQEE * @fRatioIQEE),2),0.00)
                        END

                        SET @mMontant_IQEE_Majore = isnull(round(@mMontant_IQEE - @mMontant_IQEE_Base,2),0.00)
                        IF @IsDebug <> 0 BEGIN
                            PRINT '@mMontant_IQEE_Base    : ' + str(@mMontant_IQEE_Base, 10, 2)
                            PRINT '@mMontant_IQEE_Majore  : ' + str(@mMontant_IQEE_Majore, 10, 2)
                        END 

                        INSERT INTO tblIQEE_ReponsesImpotsSpeciaux
                            (iID_Impot_Special_IQEE,iID_Fichier_IQEE
                                ,iID_Avis
                                ,iID_Avis_Precedent
                                ,cType_Avis
                                ,dtDate_Avis
                                ,mMontant_Cotisation
                                ,mMontant_Calcule
                                ,mMontant_Penalite
                                ,mMontant_Interets
                                ,mMontant_Recu
                                ,mSolde
                                ,mSolde_IQEE
                                ,mSolde_Cotisations_IQEE
                                ,mMontant_IQEE
                                ,mMontant_IQEE_Base
                                ,mMontant_IQEE_Majore
                                ,iID_Paiement_Impot_CBQ
                                ,iID_Paiement_Impot_MMQ
                                ,cRaison_Impot_Special)
                        --OUTPUT inserted.*
                        values        
                            (@iID_Impot_Special_IQEE,
                            @iID_Fichier_IQEE,
                            @iID_Avis,
                            @iID_Avis_Precedent,
                            @cType_Avis,
                            @dtDate_Avis,
                            @mMontant_Cotisation,
                            @mMontant_Calcule,
                            @mMontant_Penalite,
                            @mMontant_Interets,
                            @mMontant_Recu,
                            @mSolde,
                            @mSolde_IQEE,
                            @mSolde_Cotisations_IQEE,
                            @mMontant_IQEE,
                            @mMontant_IQEE_Base,
                            @mMontant_IQEE_Majore,
                            @iID_Paiement_Impot_CBQ,
                            @iID_Paiement_Impot_MMQ,
                            @Sous_Type)
                            
                        SET @iID_Reponse_Impot_Special = SCOPE_IDENTITY()

                        -- Marquer la transaction de demande d'origine comme ayant reçu une réponse
                        IF @tiCode_Version = 1
                            UPDATE tblIQEE_ImpotsSpeciaux SET cStatut_Reponse = 'T'
                             WHERE iID_Impot_Special = @iID_Impot_Special_IQEE
                               AND cStatut_Reponse = 'D'
                        ELSE 
                            UPDATE tblIQEE_ImpotsSpeciaux SET cStatut_Reponse = 'R'
                             WHERE iID_Impot_Special = @iID_Impot_Special_IQEE
                               AND cStatut_Reponse = 'A'

                        -- Cas d'une demande d'annulation-reprise
                        
                        --Trouver la demande d'origine
                        declare @iID_Impot_Special_IQEE_Originale int
                        IF @tiCode_Version IN (1,2)
                            BEGIN
                                SELECT @iID_Impot_Special_IQEE_Originale = A.iID_Enregistrement_Demande_Annulation
                                  FROM tblIQEE_Annulations A 
                                 WHERE A.iID_Enregistrement_Annulation = @iID_Impot_Special_IQEE

                                --UPDATE tblIQEE_ImpotsSpeciaux
                                --   SET cStatut_Reponse = 'T'
                                -- WHERE iID_Impot_Special = @iID_Impot_Special_IQEE_Originale
                                --   AND cStatut_Reponse = 'D'
                            END

                        IF (@mMontant_Cotisation <> @mMontant_Calcule) OR @cType_Avis = '2' OR @tiCode_Version = 1 --@mMontant_DeclareImpotSpecial
                            BEGIN
                                -- Créer une nouvelle opération de subvention
                                EXECUTE @iID_Operation = dbo.SP_IU_UN_Oper @iID_Connexion, 0, @cID_Type_Operation, @dtDate_Paiement

                                IF @mMontant_IQEE_Base <> 0
                                    BEGIN
                                        -- Injecter le montant dans la convention
                                        INSERT INTO dbo.Un_ConventionOper
                                                    (OperID
                                                    ,ConventionID
                                                    ,ConventionOperTypeID
                                                    ,ConventionOperAmount)
                                                VALUES
                                                    (@iID_Operation
                                                    ,@iID_Convention
                                                    ,@vcOPER_MONTANTS_CREDITBASE
                                                    ,@mMontant_IQEE_Base * -1)
                                            
                                        SET @iID_Transaction_Convention_CBQ = SCOPE_IDENTITY()

                                        -- Mettre à jour les identifiants de l'injection dans la réponse
                                        UPDATE dbo.tblIQEE_ReponsesImpotsSpeciaux
                                            SET iID_Paiement_Impot_CBQ = @iID_Transaction_Convention_CBQ
                                        WHERE iID_Reponse_Impot_Special = @iID_Reponse_Impot_Special
                                    END            

                                IF @mMontant_IQEE_Majore <> 0
                                    BEGIN
                                        -- Injecter le montant dans la convention
                                        INSERT INTO dbo.Un_ConventionOper
                                                    (OperID
                                                    ,ConventionID
                                                    ,ConventionOperTypeID
                                                    ,ConventionOperAmount)
                                                VALUES
                                                    (@iID_Operation
                                                    ,@iID_Convention
                                                    ,@vcOPER_MONTANTS_MAJORATION
                                                    ,@mMontant_IQEE_Majore * -1)
                                        SET @iID_Transaction_Convention_MMQ = SCOPE_IDENTITY()

                                        -- Mettre à jour les identifiants de l'injection dans la réponse
                                        UPDATE dbo.tblIQEE_ReponsesImpotsSpeciaux
                                            SET iID_Paiement_Impot_MMQ = @iID_Transaction_Convention_MMQ
                                        WHERE iID_Reponse_Impot_Special = @iID_Reponse_Impot_Special
                                                
                                    END
                    
                                --- Intérêts
                                IF @mMontant_Interets <> 0
                                    BEGIN
                                        -- Injecter le montant dans la convention
                                        INSERT INTO dbo.Un_ConventionOper
                                                    (OperID
                                                    ,ConventionID
                                                    ,ConventionOperTypeID
                                                    ,ConventionOperAmount)
                                                VALUES
                                                    (@iID_Operation
                                                    ,@iID_Convention
                                                    ,'MIM'
                                                    ,@mMontant_Interets * -1)
                                            
                                        SET @iID_Transaction_Convention_MIM = SCOPE_IDENTITY()

                                        -- Mettre à jour les identifiants de l'injection dans la réponse
                                        UPDATE dbo.tblIQEE_ReponsesImpotsSpeciaux
                                            SET iID_Paiement_Impot_MIM = @iID_Transaction_Convention_MIM
                                        WHERE iID_Reponse_Impot_Special = @iID_Reponse_Impot_Special
                                            
                                    END
                                
                                --- Intérêts
                                
                                -- Procédure de répartition des soldes pour minimiser les soldes négatifs lors de décaissements    
                                
                                --Calculer le solde de chaque compte après l'ajout de l'opération IQE
                                SELECT @mSoldeFixe_CBQ = dbo.fnIQEE_CalculerSoldeFixe_CreditBase_Convention(@iID_Convention,GETDATE())

                                SELECT @mSoldeFixe_MMQ = dbo.fnIQEE_CalculerSoldeFixe_Majoration_Convention(@iID_Convention,GETDATE())                                    

                                DECLARE @mSoldeFixe_Ecart money = 0
                                
                                -- 2016-11-22   Rebalancement rendu inutile car il est balancé avec le calcul précédent du ratio
                                -- Faire le balancement si cela en vaut la peine
                                --IF (@mSoldeFixe_CBQ < 0 AND @mSoldeFixe_MMQ > 0) OR (@mSoldeFixe_CBQ > 0 AND @mSoldeFixe_MMQ < 0)
                                --    BEGIN
                                --        SET @mSoldeFixe_Ecart = CASE WHEN ABS(@mSoldeFixe_CBQ) > @mSoldeFixe_MMQ 
                                --                                     THEN @mSoldeFixe_MMQ 
                                --                                     ELSE ABS(@mSoldeFixe_CBQ) 
                                --                                END * Sign(@mSoldeFixe_MMQ)

                                --        -- Balancer le solde négatif dans l'autre compte
                                --        IF @iID_Transaction_Convention_MMQ IS NULL  --Cas où @mMontant_IQEE_Majore = 0, donc il n'existe pas de transaction MMQ.
                                --            BEGIN
                                --                -- Injecter le montant dans la convention
                                --                INSERT INTO [dbo].[Un_ConventionOper]
                                --                           ([OperID]
                                --                           ,[ConventionID]
                                --                           ,[ConventionOperTypeID]
                                --                           ,[ConventionOperAmount])
                                --                     VALUES
                                --                           (@iID_Operation
                                --                           ,@iID_Convention
                                --                           ,@vcOPER_MONTANTS_MAJORATION
                                --                           ,-1 * @mSoldeFixe_Ecart)
                                                    
                                --                SET @iID_Transaction_Convention_MMQ = SCOPE_IDENTITY()
                                                    
                                --                -- Mettre à jour les identifiants de l'injection dans la réponse
                                --                UPDATE [dbo].[tblIQEE_ReponsesImpotsSpeciaux]
                                --                    SET iID_Paiement_Impot_MMQ = @iID_Transaction_Convention_MMQ
                                --                WHERE iID_Reponse_Impot_Special = @iID_Reponse_Impot_Special
                                --            END
                                --        ELSE
                                --            BEGIN                                
                                --                UPDATE [dbo].[Un_ConventionOper]
                                --                SET ConventionOperAmount = ConventionOperAmount - @mSoldeFixe_Ecart
                                --                WHERE ConventionOperID = @iID_Transaction_Convention_MMQ
                                --            END  -- IF @iID_Transaction_Convention_MMQ IS NULL
                                        
                                --        -- Balancer le solde à 0 du compte en souffrance 
                                --        IF @iID_Transaction_Convention_CBQ IS NULL  --Cas où @mMontant_IQEE_Base = 0, donc il n'existe pas de transaction MMQ.
                                --            BEGIN
                                --                -- Injecter le montant dans la convention
                                --                INSERT INTO [dbo].[Un_ConventionOper]
                                --                           ([OperID]
                                --                           ,[ConventionID]
                                --                           ,[ConventionOperTypeID]
                                --                           ,[ConventionOperAmount])
                                --                     VALUES
                                --                           (@iID_Operation
                                --                           ,@iID_Convention
                                --                           ,@vcOPER_MONTANTS_CREDITBASE
                                --                           ,@mSoldeFixe_Ecart)
                                                    
                                --                SET @iID_Transaction_Convention_CBQ = SCOPE_IDENTITY()
                                                    
                                --                UPDATE [dbo].[tblIQEE_ReponsesImpotsSpeciaux]
                                --                    SET iID_Paiement_Impot_CBQ = @iID_Transaction_Convention_CBQ
                                --                WHERE iID_Reponse_Impot_Special = @iID_Reponse_Impot_Special
                                --            END
                                --        ELSE
                                --            BEGIN
                                --                UPDATE [dbo].[Un_ConventionOper]
                                --                SET ConventionOperAmount = ConventionOperAmount + @mSoldeFixe_Ecart
                                --                WHERE ConventionOperID = @iID_Transaction_Convention_CBQ
                                --            END
                                --    END    -- (@mSoldeFixe_CBQ ) < 0
                            END    -- IF @mMontant_Cotisation <> @mMontant_Calcule --@mMontant_DeclareImpotSpecial        
                    END
                END    -- IF @fID_Regime > 0         
            ELSE  -- @fID_Regime = 0  Traitement de l'avis de Cotisation fictif
                BEGIN    
                    --  Stats de l'Avis fictif
                    SET @mTotal_Cotisations_Avis_Fictif = @mTotal_Cotisations_Avis_Fictif + @mMontant_Cotisation
                    SET @mSomme_Accaparee_Avis_Fictif = @mSomme_Accaparee_Avis_Fictif + @mMontant_Calcule
                    SET @mInterets_Avis_Fictif = @mInterets_Avis_Fictif + @mMontant_Interets
                    SET @mSolde_Avis_Fictif = @mTotal_Cotisations_Avis_Fictif + @mInterets_Avis_Fictif - @mSomme_Accaparee_Avis_Fictif
                 
                    -- Stats cumulatives
                    SET @mTotal_Cotisations_Total_Avis = @mTotal_Cotisations_Avis_Zero + @mTotal_Cotisations_Avis_Debiteurs + @mTotal_Cotisations_Avis_Crediteurs + @mTotal_Cotisations_Avis_Fictif
                    SET @mSomme_Accaparee_Total_Avis = @mSomme_Accaparee_Avis_Zero + @mSomme_Accaparee_Avis_Debiteurs + @mSomme_Accaparee_Avis_Crediteurs + @mSomme_Accaparee_Avis_Fictif
                    SET @mInterets_Total_Avis = @mInterets_Avis_Zero + @mInterets_Avis_Debiteurs + @mInterets_Avis_Crediteurs + @mInterets_Avis_Fictif
                
                    SET @mSolde_Avis_Zero = @mTotal_Cotisations_Avis_Zero + @mInterets_Avis_Zero - @mSomme_Accaparee_Avis_Zero
                    SET @mSolde_Avis_Debiteurs  = @mTotal_Cotisations_Avis_Debiteurs + @mInterets_Avis_Debiteurs  - @mSomme_Accaparee_Avis_Debiteurs
                    SET @mSolde_Avis_Crediteurs = @mTotal_Cotisations_Avis_Crediteurs + @mInterets_Avis_Crediteurs - @mSomme_Accaparee_Avis_Crediteurs
                    SET @mSolde_Total_Avis = @mSolde_Avis_Zero + @mSolde_Avis_Debiteurs + @mSolde_Avis_Crediteurs + @mSolde_Avis_Fictif
                    
                END
            
            FETCH NEXT FROM curType42 INTO @cLigne
        END

    CLOSE curType42
    DEALLOCATE curType42

    -- Comparer les valeurs entrées avec les données de la table tblIQEE_ImpotsSpeciaux
    
    SELECT @mCompare_Somme_Accaparee= IsNull(SUM(DIS.mIQEE_ImpotSpecial),0) 
    FROM tblIQEE_ImpotsSpeciaux DIS
    JOIN tblIQEE_Fichiers FIC ON FIC.iID_Fichier_IQEE = DIS.iID_Fichier_IQEE
    WHERE 
        DIS.siAnnee_Fiscale = @siAnnee_Fiscale 
        AND DIS.cStatut_Reponse <> 'R'

    IF @mCompare_Somme_Accaparee = @mSomme_Accaparee_Total_Avis 
        BEGIN
            SET @bSomme_Accaparee_Balance = 1
            SET @mEcart_Somme_Accaparee_Total_Avis = 0
        END
    ELSE
        BEGIN
            SET @mEcart_Somme_Accaparee_Total_Avis = ABS(@mSomme_Accaparee_Total_Avis - @mCompare_Somme_Accaparee)
        END

    IF @mSolde_Paiement_RQ  = @mSolde_Total_Avis
        BEGIN
            SET @bSolde_Avis_Balance = 1
            SET @mEcart_Solde_Total_Avis = 0
        END
    ELSE
        BEGIN
            SET @mEcart_Solde_Total_Avis = ABS(@mSolde_Total_Avis - @mSolde_Paiement_RQ)
        END

    INSERT INTO dbo.tblIQEE_StatistiquesImpotsSpeciaux (
            iID_Fichier_Reponse_Impots_Speciaux, siAnnee_Fiscale, iNb_Avis_Zero, iNb_Avis_Debiteurs, iNb_Avis_Crediteurs,
            mTotal_Cotisations_Avis_Zero, mTotal_Cotisations_Avis_Debiteurs, mTotal_Cotisations_Avis_Crediteurs, mTotal_Cotisations_Avis_Fictif, mTotal_Cotisations_Total_Avis,
            mSomme_Accaparee_Avis_Zero, mSomme_Accaparee_Avis_Debiteurs, mSomme_Accaparee_Avis_Crediteurs, mSomme_Accaparee_Avis_Fictif, mSomme_Accaparee_Total_Avis,
            bSomme_Accaparee_Balance, mEcart_Somme_Accaparee_Total_Avis,
            mInterets_Avis_Zero, mInterets_Avis_Debiteurs, mInterets_Avis_Crediteurs, mInterets_Avis_Fictif, mInterets_Total_Avis,
            mSolde_Avis_Zero, mSolde_Avis_Debiteurs, mSolde_Avis_Crediteurs, mSolde_Avis_Fictif, mSolde_Total_Avis,
            bSolde_Avis_Balance, mEcart_Solde_Total_Avis
        )
    VALUES (
            @iID_Fichier_IQEE, @siAnnee_Fiscale, @iNb_Avis_Zero, @iNb_Avis_Debiteurs, @iNb_Avis_Crediteurs,
            @mTotal_Cotisations_Avis_Zero, @mTotal_Cotisations_Avis_Debiteurs, @mTotal_Cotisations_Avis_Crediteurs, @mTotal_Cotisations_Avis_Fictif, @mTotal_Cotisations_Total_Avis,
            @mSomme_Accaparee_Avis_Zero, @mSomme_Accaparee_Avis_Debiteurs, @mSomme_Accaparee_Avis_Crediteurs, @mSomme_Accaparee_Avis_Fictif, @mSomme_Accaparee_Total_Avis,
            @bSomme_Accaparee_Balance, @mEcart_Somme_Accaparee_Total_Avis,
            @mInterets_Avis_Zero, @mInterets_Avis_Debiteurs, @mInterets_Avis_Crediteurs, @mInterets_Avis_Fictif, @mInterets_Total_Avis,
            @mSolde_Avis_Zero, @mSolde_Avis_Debiteurs, @mSolde_Avis_Crediteurs, @mSolde_Avis_Fictif, @mSolde_Total_Avis,
            @bSolde_Avis_Balance, @mEcart_Solde_Total_Avis
        )
                
    SET @iID_Statistique_Impots_Speciaux = SCOPE_IDENTITY()

    SELECT  @mMontant_Total_A_Payer_Courriel = SUM(mMontant_IQEE + mMontant_Interets)  
    FROM tblIQEE_ReponsesImpotsSpeciaux where iID_Fichier_IQEE=@iID_Fichier_IQEE
            
    -- Ajouter le solde de l'avis fictif
    SET @mMontant_Total_A_Payer_Courriel = @mMontant_Total_A_Payer_Courriel + @mSolde_Avis_Fictif

    GOTO FIN_TRAITEMENT

    ERREUR_TRAITEMENT:
        SET @bInd_Erreur = 1

    FIN_TRAITEMENT:
END