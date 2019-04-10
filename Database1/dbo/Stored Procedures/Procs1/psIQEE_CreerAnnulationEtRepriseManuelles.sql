/****************************************************************************************************
Copyright (c) 2014 Gestion Universitas inc.

Code du service : psIQEE_CreerAnnulationEtRepriseManuelles
Nom du service  : CreerAnnulationEtRepriseManuelles
But             : Créer spontanément les transactions d'annulation et de reprise "brutes" d'une demande d'IQEE T02, T03 ou T06 déjà répondue afin 
                  de résoudre des cas particuliers avec Revenu Québec.
                  Note: une transaction "brute" est basée selon la copie de l'originale sans avoir à se buter aux nombreuses règles de validation.
                  Une fois créée, les transactions générées devront être modifiées par l'analyste des TI dans les tables de l'IQEE associées à la transaction
                  par le biais d'autres scripts.
Facette         : IQÉÉ

Paramètres d’entrée :   
    Paramètre                       Description
    ----------------------------    -----------------------------------------------------------------
    @tiID_TypeEnregistrement        Type d'enregistrement à annuler,
    @siAnnee_Fiscale                Année fiscale demandéeSMALLINT,
    @iID_DemandeIQEE_AAnnuler       Numéro de la demande répondue
    @iID_Raison_Annulation          Id de la raison d'annulation (Source tblIQEE_RaisonsAnnulation)
    @tCommentaires                  Texte explicatif de la raison du traitement
    @bCreerFichier bit,             Booléen spécifiant si le fichier physique doit être créé sur le champ.
    @vcChemin_Fichier               Répertoire où le fichier physique devra être créé.

Exemple d’appel :
    EXECUTE @RC = dbo.psIQEE_CreerAnnulationEtRepriseManuelles ( 2012, 1256923, 13, 'Cas particulier: Convention #U-20020910006',1 ,'\\gestas2\iqee$\Simulations')

Historique des modifications:
    Date        Programmeur                     Description                                
    ----------  ----------------------------    -----------------------------------------
    2014-03-06  Stéphane Barbeau                Création du service
    2014-09-03  Stéphane Barbeau                Ajout du paramètre @tiID_TypeEnregistrement et traitement d'annulation des T03, T04, T05 et T06.
    2015-01-09  Stéphane Barbeau                T06-91:  traitement de vcNAS_Beneficiaire.
    2015-02-18  Stéphane Barbeau                Ajout du paramètre @bCreer_TransactionReprise pour déclencher la construction des reprises pour les T03 et T06.
    2015-11-20  Stéphane Barbeau                Ajout Création T03-2
    2017-09-12  Steeve Picard                   Changer l'approche en passant l'ID de la transaction
    2017-12-05  Steeve Picard                   Annuler aussi la T06-31 dans le cas où on annulerait une T06-91
    2017-12-15  Steeve Picard                   Ajout l'annulation des transactions ultérieures
    2018-01-10  Steeve Picard                   Utilisation des procédures «psIQEE_CreerTransactions??» pour être identique au déclaration à RQ
    2018-02-22  Steeve Picard                   Élimination des paramètres «@dtDebutCotisation & @dtFinCotisation» de la procédure «psIQEE_CreerTransactions02»
    2018-06-04  Steeve Picard                   Réouverture/refermeture des conventions si elles sont fermées en date du jour
    2018-06-25  Steeve Picard                   Ajout du sous-type de transaction pour les reprises
    2018-07-11  Steeve Picard                   Changement pour les T05-01 «PAE» pour le l'IQÉÉ payé
    2018-11-06  Steeve Picard                   Fixe pour annuler seulement les transactions antérieures actives
    2018-12-10  Steeve Picard                   Correction pour ignorer les transactions avec le statut «E ou X»
*********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_CreerAnnulationEtRepriseManuelles
(
    @iID_Fichier_Annulation         INT,
    @iID_LigneFichier               INT,
    @iID_Raison_Annulation          INTEGER,
    @bCreer_TransactionReprise      BIT,
    @iID_Session                    INTEGER,
    @bPremier_Envoi_Originaux       bit = 0,
    @bFichier_Test                  bit = 0,
    @bArretPremiereErreur           bit = 0,
    @cCode_Portee                   char(1) = 'T',
    @iID_Utilisateur_Creation       int = 628022,
    @cID_Langue                     char(3) = NULL,
    @bCasSpecial                    bit = 0,
    @tCommentaires                  VARCHAR(MAX)
)
AS
BEGIN
    --  Déclartion de variable
    DECLARE @siAnnee_Fiscale                INT,
            @iID_Fichier_IQEE               INT,
            @dtCreationFichier              DATETIME,
            @tiID_TypeEnregistrement        TINYINT,
            @cCodeTypeEnregistrement        CHAR(2) = (SELECT LEFT(cLigne, 2) FROM dbo.tblIQEE_LignesFichier WHERE iID_Ligne_Fichier = @iID_LigneFichier),
            @bConsequence_Annulation        bit = 1,
            @dtDebutCotisation              DATE,
            @dtFinCotisation                DATE,
            @vcID_Transactions              VARCHAR(max),
            @vcTMP1                         VARCHAR(10)

    DECLARE
        @iID_Convention             INT, 
        @vcNo_Convention            VARCHAR(15),
        @vcState_Convention         VARCHAR(3),
        @iID_Enregistrement_Annuler INTEGER,
        @iID_Sous_Type              INT,
        @cCode_Sous_Type            CHAR(2),
        @tiCode_Version             TINYINT,
        @cStatut_Reponse            CHAR(1),
        @dtReconnue_RQ              DATE,
        @dtEvenement                DATE,
        @iID_Enregistrement_New     INT,
        @iID_Annulation             INT,
        @iID_Level                  TINYINT

    IF OBJECT_ID('tempDB..#TB_Transaction') IS NOT NULL
        DROP TABLE #TB_Transaction

    CREATE TABLE #TB_Transaction (
        iID_Level           TINYINT IDENTITY(1,1) NOT NULL,
        siAnnee             SMALLINT NOT NULL,
        iID_Fichier         INT NOT NULL,
        iID_Ligne           INT NOT NULL,
        cTypeTransaction    CHAR(2) NOT NULL,
        cSousTypeTrans      CHAR(2) NULL,
        iID_Evenement       INT NOT NULL,
        iID_Annulation      INT NULL 
    )

    SELECT @iID_Convention = TB.iID_Convention,
           @vcNo_Convention = TB.vcNo_Convention,
           @siAnnee_Fiscale = TB.siAnnee_Fiscale, 
           @iID_Fichier_IQEE = TB.iID_Fichier_IQEE, 
           @cCodeTypeEnregistrement = TB.cCodeTypeEnregistrement,
           @cCode_Sous_Type = T.cCode_Sous_Type,
           @iID_Enregistrement_Annuler = TB.iID_Evenement
      FROM dbo.fntIQEE_ObtenirEnregistrementID_FromLigneRQ(@iID_LigneFichier) TB
           JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType T ON T.cCode_Type_Enregistrement = TB.cCodeTypeEnregistrement AND ISNULL(T.iID_Sous_Type, 0) = ISNULL(TB.iID_Sous_Type, 0)

    INSERT INTO #TB_Transaction (
        siAnnee, iID_Fichier, iID_Ligne, cTypeTransaction, cSousTypeTrans, iID_Evenement
    )
    VALUES (
        @siAnnee_Fiscale, @iID_Fichier_IQEE, @iID_LigneFichier, @cCodeTypeEnregistrement, @cCode_Sous_Type, @iID_Enregistrement_Annuler
    )

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR ('L''enregistrement T-%s dont le ID de la transaction RQ est %d ne peut pas être retrouvé', 11, 1, @cCodeTypeEnregistrement, @iID_Enregistrement_Annuler)
        RETURN -1
    END

    SELECT @dtCreationFichier = dtDate_Creation_Fichiers
      FROM dbo.tblIQEE_Fichiers
     WHERE iID_Fichier_IQEE = @iID_Fichier_Annulation

    SET @vcState_Convention = dbo.fnCONV_ObtenirStatutConventionEnDate(@iID_Convention, @dtCreationFichier)
    IF @vcState_Convention = 'FRM'
    BEGIN
        IF OBJECT_ID('tempdb..#DisableTrigger') IS NULL
            CREATE TABLE #DisableTrigger (vcTriggerName VARCHAR(100)) 
            
        INSERT INTO #DisableTrigger (vcTriggerName)
        VALUES ('TUn_ConventionConventionState_I')
    
        INSERT INTO dbo.Un_ConventionConventionState (
            ConventionID, ConventionStateID, StartDate
        )
        VALUES 
            (@iID_Convention, 'REE', DATEADD(MINUTE, -1, @dtCreationFichier))
    END         

    SET @dtDebutCotisation = STR(@siAnnee_Fiscale, 4) + '-01-01'
    SET @dtFinCotisation = STR(@siAnnee_Fiscale, 4) + '-12-31'
    
    SELECT @tiID_TypeEnregistrement = tiID_Type_Enregistrement
      FROM dbo.tblIQEE_TypesEnregistrement
     WHERE cCode_Type_Enregistrement = @cCodeTypeEnregistrement

    PRINT 'Annulation de la transaction #' + LTRIM(STR(@iID_LigneFichier, 10)) + ' pour l''année fiscale ' + STR(@siAnnee_Fiscale, 4) + ' ID: ' + LTRIM(STR(@iID_Fichier_IQEE))
    PRINT '----------------------------------------'

    --  Valide l''existance du ID de déclartations à RQ
    --  ===============================================
    IF 0 =1
    BEGIN
        IF NOT ISNULL(@cStatut_Reponse, ' ') in ('R')
        BEGIN
            RAISERROR ('On ne peut annuler la transaction T-%s dont le ID est %d car son statut %s n''est pas «R - Réponse reçue»', 11, 1, @cCodeTypeEnregistrement, @iID_Enregistrement_Annuler, @cStatut_Reponse)
            RETURN -3
        END

        IF NOT @tiCode_Version IN (0, 2)
        BEGIN
            IF @tiCode_Version IS null
                RAISERROR ('Type d''enregistrement non pris en charge', 11, 1)
            ELSE 
                RAISERROR ('La transaction passée en paramètre n''est ni une originale ni une reprise', 11, 1)
            RETURN
        END
    END
    
    IF OBJECT_ID('tempDB..#TB_ListeConvention') IS NULL 
        CREATE TABLE #TB_ListeConvention (
            RowNo INT Identity(1,1), 
            ConventionID int, 
            ConventionNo varchar(20), 
            ConventionStateID varchar(5), 
            dtReconnue_RQ DATE
        )

    IF NOT EXISTS(SELECT * FROM #TB_ListeConvention WHERE ConventionID = @iID_Convention)
    BEGIN 
        SELECT @dtReconnue_RQ = dtReconnue_RQ FROM dbo.fntIQEE_ConventionConnueRQ_PourTous(@iID_Convention, @siAnnee_Fiscale)

        INSERT INTO #TB_ListeConvention (ConventionID, ConventionNo, ConventionStateID, dtReconnue_RQ)
        SELECT @iID_Convention, @vcNo_Convention, S.ConventionStateID, @dtReconnue_RQ
          FROM dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(Str(@siAnnee_Fiscale, 4)+'-12-31', @iID_Convention) S
    END 
    SELECT * FROM #TB_ListeConvention

    --  Annulation de la transaction
    --  ============================

    PRINT '   Recherche les transactions ultérieures'
    BEGIN
        ;WITH CTE_Fichier AS (
            SELECT F.iID_Fichier_IQEE, ISNULL(F.dtDate_Creation, F.dtDate_Creation_Fichiers) AS dtFichier
              FROM dbo.tblIQEE_Fichiers F --(NULL, NULL, @siAnnee_Fiscale, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL) F
                   JOIN dbo.tblIQEE_TypesFichier T ON T.tiID_Type_Fichier = F.tiID_Type_Fichier
             WHERE 0 = 0 --T.bTeleversable_RQ <> 0
               AND (
                     (F.bFichier_Test = 0  AND F.bInd_Simulation = 0)
                     OR F.iID_Fichier_IQEE = @iID_Fichier_IQEE
                   )
        )
        SELECT D.siAnnee_Fiscale, D.iID_Fichier_IQEE, D.iID_Ligne_Fichier, '02' AS cTypeTransaction,  
                cCode_Sous_Type = CAST(NULL AS CHAR(2)),  iID_Evenement = D.iID_Demande_IQEE, tiCode_Version, cStatut_Reponse,
                RowNum = ROW_NUMBER() OVER(PARTITION BY D.siAnnee_Fiscale ORDER BY F.dtFichier DESC, D.iID_Ligne_Fichier DESC)
            FROM dbo.tblIQEE_Demandes D JOIN CTE_Fichier F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE 
            WHERE D.iID_Convention = @iID_Convention
            AND ( D.siAnnee_Fiscale > @siAnnee_Fiscale
                    OR ( D.siAnnee_Fiscale = @siAnnee_Fiscale
                        AND D.iID_Ligne_Fichier > @iID_LigneFichier
                    )
                )
            AND NOT D.cStatut_Reponse IN ('E','X') 

        --  Retrouve toutes les déclartations ultérieures
        ;WITH CTE_Fichier AS (
            SELECT F.iID_Fichier_IQEE, ISNULL(F.dtDate_Creation, F.dtDate_Creation_Fichiers) AS dtFichier
              FROM dbo.tblIQEE_Fichiers F --(NULL, NULL, @siAnnee_Fiscale, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL) F
                   JOIN dbo.tblIQEE_TypesFichier T ON T.tiID_Type_Fichier = F.tiID_Type_Fichier
             WHERE 0 = 0 --T.bTeleversable_RQ <> 0
               AND (
                     (F.bFichier_Test = 0  AND F.bInd_Simulation = 0)
                     OR F.iID_Fichier_IQEE = @iID_Fichier_IQEE
                   )
        ),
        CTE_Evenement AS (
            SELECT D.siAnnee_Fiscale, D.iID_Fichier_IQEE, D.iID_Ligne_Fichier, '02' AS cTypeTransaction,  
                   cCode_Sous_Type = CAST(NULL AS CHAR(2)),  iID_Evenement = D.iID_Demande_IQEE, tiCode_Version, cStatut_Reponse,
                   RowNum = ROW_NUMBER() OVER(PARTITION BY D.siAnnee_Fiscale ORDER BY F.dtFichier DESC, D.iID_Ligne_Fichier DESC)
              FROM dbo.tblIQEE_Demandes D JOIN CTE_Fichier F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE 
             WHERE D.iID_Convention = @iID_Convention
               AND ( D.siAnnee_Fiscale > @siAnnee_Fiscale
                     OR ( D.siAnnee_Fiscale = @siAnnee_Fiscale
                          AND D.iID_Ligne_Fichier > @iID_LigneFichier
                        )
                   )
               AND NOT D.cStatut_Reponse IN ('E','X') 
            UNION
            SELECT RB.siAnnee_Fiscale, RB.iID_Fichier_IQEE, RB.iID_Ligne_Fichier, '03' AS cTypeTransaction, 
                   cCode_Sous_Type = CAST(NULL AS CHAR(2)),  iID_Evenement = RB.iID_Remplacement_Beneficiaire, tiCode_Version, cStatut_Reponse,
                   RowNum = ROW_NUMBER() OVER(PARTITION BY RB.siAnnee_Fiscale ORDER BY F.dtFichier DESC, RB.iID_Ligne_Fichier DESC)
              FROM dbo.tblIQEE_RemplacementsBeneficiaire RB JOIN CTE_Fichier F ON F.iID_Fichier_IQEE = RB.iID_Fichier_IQEE 
             WHERE RB.iID_Convention = @iID_Convention 
               AND ( RB.siAnnee_Fiscale > @siAnnee_Fiscale
                     OR ( RB.siAnnee_Fiscale = @siAnnee_Fiscale
                          AND RB.iID_Ligne_Fichier > @iID_LigneFichier
                        )
                   )
               AND NOT RB.cStatut_Reponse IN ('E','X') 
            UNION 
            SELECT T.siAnnee_Fiscale, T.iID_Fichier_IQEE, T.iID_Ligne_Fichier, '04' AS cTypeTransaction, 
                   TST.cCode_Sous_Type, T.iID_Transfert, tiCode_Version, cStatut_Reponse,
                   RowNum = ROW_NUMBER() OVER(PARTITION BY T.siAnnee_Fiscale ORDER BY F.dtFichier DESC, T.iID_Ligne_Fichier DESC)
              FROM dbo.tblIQEE_Transferts T JOIN CTE_Fichier F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE 
                   JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TST ON TST.cCode_Type_Enregistrement = '04' AND ISNULL(TST.iID_Sous_Type, 0) = ISNULL(T.iID_Sous_Type, 0)
             WHERE T.iID_Convention = @iID_Convention 
               AND ( T.siAnnee_Fiscale > @siAnnee_Fiscale
                     OR ( T.siAnnee_Fiscale = @siAnnee_Fiscale
                          AND T.iID_Ligne_Fichier > @iID_LigneFichier
                        )
                   )
               AND NOT T.cStatut_Reponse IN ('E','X') 
            UNION 
            SELECT PB.siAnnee_Fiscale, PB.iID_Fichier_IQEE, PB.iID_Ligne_Fichier, '05' AS cTypeTransaction, 
                   TST.cCode_Sous_Type, PB.iID_Paiement_Beneficiaire, tiCode_Version, cStatut_Reponse,
                   RowNum = ROW_NUMBER() OVER(PARTITION BY PB.siAnnee_Fiscale ORDER BY F.dtFichier DESC, PB.iID_Ligne_Fichier DESC)
              FROM dbo.tblIQEE_PaiementsBeneficiaires PB JOIN CTE_Fichier F ON F.iID_Fichier_IQEE = PB.iID_Fichier_IQEE
                   JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TST ON TST.cCode_Type_Enregistrement = '05' AND ISNULL(TST.iID_Sous_Type, 0) = ISNULL(PB.iID_Sous_Type, 0) 
             WHERE PB.iID_Convention = @iID_Convention 
               AND ( PB.siAnnee_Fiscale > @siAnnee_Fiscale
                     OR ( PB.siAnnee_Fiscale = @siAnnee_Fiscale
                          AND PB.iID_Ligne_Fichier > @iID_LigneFichier
                        )
                   )
               AND NOT PB.cStatut_Reponse IN ('E','X') 
            UNION 
            SELECT I.siAnnee_Fiscale, I.iID_Fichier_IQEE, I.iID_Ligne_Fichier, '06' AS cTypeTransaction, 
                   TST.cCode_Sous_Type, I.iID_Impot_Special, tiCode_Version, cStatut_Reponse,
                   RowNum = ROW_NUMBER() OVER(PARTITION BY I.siAnnee_Fiscale ORDER BY F.dtFichier DESC, I.iID_Ligne_Fichier DESC)
              FROM dbo.tblIQEE_ImpotsSpeciaux I JOIN CTE_Fichier F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE 
                   JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TST ON TST.cCode_Type_Enregistrement = '06' AND ISNULL(TST.iID_Sous_Type, 0) = ISNULL(I.iID_Sous_Type, 0)
             WHERE I.iID_Convention = @iID_Convention 
               AND ( I.siAnnee_Fiscale > @siAnnee_Fiscale
                     OR ( I.siAnnee_Fiscale = @siAnnee_Fiscale
                          AND I.iID_Ligne_Fichier > @iID_LigneFichier
                        )
                   )
               AND NOT I.cStatut_Reponse IN ('E','X') 
        )
        INSERT INTO #TB_Transaction (siAnnee, iID_Fichier, iID_Ligne, cTypeTransaction, cSousTypeTrans, iID_Evenement)
        OUTPUT Inserted.*
        SELECT siAnnee_Fiscale, iID_Fichier_IQEE, iID_Ligne_Fichier, cTypeTransaction, cCode_Sous_Type, iID_Evenement
          FROM CTE_Evenement
         WHERE cStatut_Reponse IN ('A','R') AND tiCode_Version <> 1 AND RowNum = 1
         ORDER BY siAnnee_Fiscale, iID_Ligne_Fichier

        IF @cCodeTypeEnregistrement = '06' AND @cCode_Sous_Type = '91'
        BEGIN 
            SELECT 
                @iID_Convention  = I.iID_Convention,
                @dtEvenement = I.dtDate_Evenement
            FROM
                dbo.tblIQEE_ImpotsSpeciaux I
            WHERE
                i.iID_Impot_Special = @iID_Enregistrement_Annuler

            INSERT INTO #TB_Transaction (
                iID_Fichier, siAnnee, iID_Ligne, cTypeTransaction, iID_Evenement
            )
            SELECT 
                @siAnnee_Fiscale, I.iID_Fichier_IQEE, I.iID_Ligne_Fichier, '06', I.iID_Impot_Special
            FROM
                dbo.tblIQEE_ImpotsSpeciaux I
                JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TE ON TE.iID_Sous_Type = I.iID_Sous_Type
                JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
            WHERE
                I.iID_Convention = @iID_Convention AND I.dtDate_Evenement = @dtEvenement
                AND I.tiCode_Version IN (0, 2) AND I.cStatut_Reponse IN ('R', 'A')
                AND TE.cCode_Type_Enregistrement = '06' AND TE.cCode_Sous_Type = '31'
        END 

        IF @bFichier_Test <> 0
            SELECT '#TB_Transaction', * FROM #TB_Transaction
    END

    PRINT '   Annule les transactions retrouvées'
    BEGIN 
        SET @iID_Level = 255
        WHILE EXISTS(SELECT * FROM #TB_Transaction WHERE iID_Level < @iID_Level)
        BEGIN
            SELECT TOP 1 @iID_Level = iID_Level,
                         @siAnnee_Fiscale = siAnnee,
                         @iID_Enregistrement_Annuler = iID_Evenement,
                         @cCodeTypeEnregistrement = cTypeTransaction,
                         @cCode_Sous_Type = cSousTypeTrans
              FROM #TB_Transaction 
             WHERE iID_Level < @iID_Level
             ORDER BY iID_Level DESC 

            PRINT '      Transaction #' + LTRIM(STR(@iID_Enregistrement_Annuler, 10)) + ' de l''année fiscale ' + STR(@siAnnee_Fiscale, 4)
            --EXEC dbo.psIQEE_CreerAnnulationDeclarationRQ @iID_Fichier_Annulation, @dtCreationFichier,
            --                                             @iID_Enregistrement_Annuler, @cCodeTypeEnregistrement, @cCode_Sous_Type,
            --                                             @iID_Raison_Annulation, @iID_Utilisateur_Creation, @tCommentaires
            BEGIN
                SELECT @tiID_TypeEnregistrement = tiID_Type_Enregistrement,
                       @iID_Sous_Type = iID_Sous_Type
                  FROM dbo.vwIQEE_Enregistrement_TypeEtSousType
                 WHERE cCode_Type_Enregistrement = @cCodeTypeEnregistrement
                   AND ISNULL(cCode_Sous_Type, '') = ISNULL(@cCode_Sous_Type, '')

                IF EXISTS(SELECT * FROM dbo.tblIQEE_Annulations WHERE tiID_Type_Enregistrement = @tiID_TypeEnregistrement AND iID_Enregistrement_Demande_Annulation = @iID_Enregistrement_Annuler)
                BEGIN
                    SELECT @iID_Annulation = iID_Annulation,
                           @iID_Enregistrement_New = iID_Enregistrement_Annulation
                      FROM dbo.tblIQEE_Annulations A
                     WHERE tiID_Type_Enregistrement = @tiID_TypeEnregistrement 
                       AND iID_Enregistrement_Demande_Annulation = @iID_Enregistrement_Annuler

                    IF @cCodeTypeEnregistrement = '02'
                        IF NOT EXISTS(SELECT TOP 1 * FROM dbo.tblIQEE_Demandes
                                    WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
                                        AND iID_Demande_IQEE = @iID_Enregistrement_New 
                                        AND iID_Ligne_Fichier IS NULL 
                                        --AND cStatut_Reponse  = 'A'
                                    )
                            SET @iID_Enregistrement_New = NULL

                    IF @cCodeTypeEnregistrement = '03'
                        IF NOT EXISTS(SELECT TOP 1 * FROM dbo.tblIQEE_RemplacementsBeneficiaire
                                    WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
                                        AND iID_Remplacement_Beneficiaire = @iID_Enregistrement_New 
                                        AND iID_Ligne_Fichier IS NULL 
                                        --AND cStatut_Reponse  = 'A'
                                    )
                            SET @iID_Enregistrement_New = NULL

                    IF @cCodeTypeEnregistrement = '04'
                        IF NOT EXISTS(SELECT TOP 1 * FROM dbo.tblIQEE_Transferts
                                    WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
                                        AND iID_Transfert = @iID_Enregistrement_New 
                                        AND iID_Ligne_Fichier IS NULL 
                                        --AND cStatut_Reponse  = 'A'
                                    )
                            SET @iID_Enregistrement_New = NULL

                    IF @cCodeTypeEnregistrement = '05'
                        IF NOT EXISTS(SELECT TOP 1 * FROM dbo.tblIQEE_PaiementsBeneficiaires 
                                    WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
                                        AND iID_Paiement_Beneficiaire = @iID_Enregistrement_New 
                                        AND iID_Ligne_Fichier IS NULL 
                                        --AND cStatut_Reponse  = 'A'
                                    )
                            SET @iID_Enregistrement_New = NULL

                    IF @cCodeTypeEnregistrement = '06'
                        IF NOT EXISTS(SELECT TOP 1 * FROM dbo.tblIQEE_ImpotsSpeciaux
                                    WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
                                        AND iID_Impot_Special = @iID_Enregistrement_New 
                                        AND iID_Ligne_Fichier IS NULL 
                                        --AND cStatut_Reponse  = 'A'
                                    )
                            SET @iID_Enregistrement_New = NULL
                END
                ELSE
                    SET @iID_Enregistrement_New = NULL 
    
                IF @iID_Enregistrement_New IS NULL 
                BEGIN
                    PRINT '   Création de la transaction d''annulation pour l''enregistrement #' + LTRIM(STR(@iID_Enregistrement_Annuler,10))

                    -- Créer la demande d'annulation 
                    INSERT INTO dbo.tblIQEE_Annulations (
                        tiID_Type_Enregistrement, iID_Enregistrement_Demande_Annulation, iID_Session, dtDate_Creation_Fichiers, vcCode_Simulation,
                        dtDate_Demande_Annulation, iID_Utilisateur_Demande, iID_Type_Annulation, iID_Raison_Annulation, tCommentaires,
                        iID_Statut_Annulation
                    )
                    VALUES (
                        @tiID_TypeEnregistrement, @iID_Enregistrement_Annuler, @@spid, @dtCreationFichier, NULL,
                        @dtCreationFichier, @iID_Utilisateur_Creation, 1, @iID_Raison_Annulation, @tCommentaires, 
                        6
                    )
                    SET @iID_Annulation = IDENT_CURRENT('tblIQEE_Annulations')

                    IF @cCodeTypeEnregistrement = '02'
                    BEGIN
                        -- Contruction de l'Annulation 
                        INSERT INTO dbo.tblIQEE_Demandes (
                            iID_Fichier_IQEE, siAnnee_Fiscale, cStatut_Reponse, iID_Convention, vcNo_Convention, tiCode_Version,
                            dtDate_Debut_Convention, tiNB_Annee_Quebec, mCotisations, mTransfert_IN, mTotal_Cotisations_Subventionnables,
                            mTotal_Cotisations, iID_Beneficiaire_31Decembre, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire,
                            dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire, iID_Adresse_31Decembre_Beneficiaire, vcAppartement_Beneficiaire, vcNo_Civique_Beneficiaire,
                            vcRue_Beneficiaire, vcLigneAdresse2_Beneficiaire, vcLigneAdresse3_Beneficiaire, vcVille_Beneficiaire, vcProvince_Beneficiaire,
                            vcPays_Beneficiaire, vcCodePostal_Beneficiaire, bResidence_Quebec, iID_Souscripteur, tiType_Souscripteur,
                            vcNAS_Souscripteur, vcNEQ_Souscripteur, vcNom_Souscripteur, vcPrenom_Souscripteur, tiID_Lien_Souscripteur, 
                            iID_Adresse_Souscripteur, vcAppartement_Souscripteur, vcNo_Civique_Souscripteur, vcRue_Souscripteur, vcLigneAdresse2_Souscripteur,
                            vcLigneAdresse3_Souscripteur, vcVille_Souscripteur, vcCodePostal_Souscripteur, vcProvince_Souscripteur, vcPays_Souscripteur,
                            vcTelephone_Souscripteur, iID_Cosouscripteur, vcNAS_Cosouscripteur, vcNom_Cosouscripteur, vcPrenom_Cosouscripteur,
                            tiID_Lien_Cosouscripteur, vcTelephone_Cosouscripteur, tiType_Responsable, vcNAS_Responsable, vcNEQ_Responsable,
                            vcNom_Responsable, vcPrenom_Responsable, tiID_Lien_Responsable, vcAppartement_Responsable, vcNo_Civique_Responsable,
                            vcRue_Responsable, vcLigneAdresse2_Responsable, vcLigneAdresse3_Responsable, vcVille_Responsable, vcCodePostal_Responsable,
                            vcProvince_Responsable, vcPays_Responsable, vcTelephone_Responsable, bInd_Cession_IQEE
                        )
                        SELECT 
                            @iID_Fichier_Annulation, siAnnee_Fiscale, 'D', iID_Convention, vcNo_Convention, 1,
                            dtDate_Debut_Convention, tiNB_Annee_Quebec, mCotisations, mTransfert_IN, mTotal_Cotisations_Subventionnables,
                            mTotal_Cotisations, iID_Beneficiaire_31Decembre, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire,
                            dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire, iID_Adresse_31Decembre_Beneficiaire, vcAppartement_Beneficiaire, vcNo_Civique_Beneficiaire,
                            vcRue_Beneficiaire, vcLigneAdresse2_Beneficiaire, vcLigneAdresse3_Beneficiaire, vcVille_Beneficiaire, vcProvince_Beneficiaire,
                            vcPays_Beneficiaire, vcCodePostal_Beneficiaire, bResidence_Quebec, iID_Souscripteur, tiType_Souscripteur,
                            vcNAS_Souscripteur, vcNEQ_Souscripteur, vcNom_Souscripteur, vcPrenom_Souscripteur, tiID_Lien_Souscripteur,
                            iID_Adresse_Souscripteur, vcAppartement_Souscripteur, vcNo_Civique_Souscripteur, vcRue_Souscripteur, vcLigneAdresse2_Souscripteur,
                            vcLigneAdresse3_Souscripteur, vcVille_Souscripteur, vcCodePostal_Souscripteur, vcProvince_Souscripteur, vcPays_Souscripteur,
                            vcTelephone_Souscripteur, iID_Cosouscripteur, vcNAS_Cosouscripteur, vcNom_Cosouscripteur, vcPrenom_Cosouscripteur,
                            tiID_Lien_Cosouscripteur, vcTelephone_Cosouscripteur, tiType_Responsable, vcNAS_Responsable, vcNEQ_Responsable,
                            vcNom_Responsable, vcPrenom_Responsable, tiID_Lien_Responsable, vcAppartement_Responsable, vcNo_Civique_Responsable,
                            vcRue_Responsable, vcLigneAdresse2_Responsable, vcLigneAdresse3_Responsable, vcVille_Responsable, vcCodePostal_Responsable,
                            vcProvince_Responsable, vcPays_Responsable, vcTelephone_Responsable, bInd_Cession_IQEE
                        FROM 
                            dbo.tblIQEE_Demandes 
                        WHERE 
                            iID_Demande_IQEE = @iID_Enregistrement_Annuler 

                        SET @iID_Enregistrement_New = IDENT_CURRENT('dbo.tblIQEE_Demandes')

                        -- Insérer les liens entre les transactions de cotisation et la demande
                        WHILE @vcID_Transactions IS NOT NULL AND @vcID_Transactions <> ''
                        BEGIN
                            SET @vcTMP1 = SUBSTRING(@vcID_Transactions,1,CHARINDEX(',',@vcID_Transactions)-1)
                            SET @vcID_Transactions = SUBSTRING(@vcID_Transactions,LEN(@vcTMP1)+2,8000)

                            INSERT INTO dbo.tblIQEE_TransactionsDemande (iID_Demande_IQEE,iID_Transaction)
                            VALUES (@iID_Enregistrement_New,CAST(@vcTMP1 AS INT))
                        END
                    END
                    ELSE IF @cCodeTypeEnregistrement = '03'    
                    BEGIN  
                        -- Contruction de l'Annulation  de la T03-1
                        INSERT INTO dbo.tblIQEE_RemplacementsBeneficiaire (
                            iID_Fichier_IQEE, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse, iID_Convention, vcNo_Convention,
                            iID_Changement_Beneficiaire, dtDate_Remplacement, bInd_Remplacement_Reconnu, bLien_Frere_Soeur, 
                            iID_Ancien_Beneficiaire, vcNAS_Ancien_Beneficiaire, vcNom_Ancien_Beneficiaire, vcPrenom_Ancien_Beneficiaire, 
                            dtDate_Naissance_Ancien_Beneficiaire, tiSexe_Ancien_Beneficiaire,
                            iID_Nouveau_Beneficiaire, vcNAS_Nouveau_Beneficiaire, vcNom_Nouveau_Beneficiaire, vcPrenom_Nouveau_Beneficiaire, 
                            dtDate_Naissance_Nouveau_Beneficiaire, tiSexe_Nouveau_Beneficiaire, 
                            tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire, bLien_Sang_Nouveau_Beneficiaire_Souscripteur_Initial,  iID_Adresse_Beneficiaire_Date_Remplacement, 
                            vcAppartement_Beneficiaire, vcNo_Civique_Beneficiaire, vcRue_Beneficiaire, vcLigneAdresse2_Beneficiaire, vcLigneAdresse3_Beneficiaire, 
                            vcVille_Beneficiaire, vcProvince_Beneficiaire, vcPays_Beneficiaire, vcCodePostal_Beneficiaire, bResidence_Quebec
                        )                   
                        SELECT
                            @iID_Fichier_Annulation, siAnnee_Fiscale, 1, 'D', iID_Convention, vcNo_Convention,
                            iID_Changement_Beneficiaire, dtDate_Remplacement, bInd_Remplacement_Reconnu, bLien_Frere_Soeur,
                            iID_Ancien_Beneficiaire, vcNAS_Ancien_Beneficiaire, vcNom_Ancien_Beneficiaire, vcPrenom_Ancien_Beneficiaire,
                            dtDate_Naissance_Ancien_Beneficiaire, tiSexe_Ancien_Beneficiaire,
                            iID_Nouveau_Beneficiaire, vcNAS_Nouveau_Beneficiaire, vcNom_Nouveau_Beneficiaire, vcPrenom_Nouveau_Beneficiaire,
                            dtDate_Naissance_Nouveau_Beneficiaire, tiSexe_Nouveau_Beneficiaire,
                            tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire, bLien_Sang_Nouveau_Beneficiaire_Souscripteur_Initial, iID_Adresse_Beneficiaire_Date_Remplacement,
                            vcAppartement_Beneficiaire, vcNo_Civique_Beneficiaire, vcRue_Beneficiaire, vcLigneAdresse2_Beneficiaire, vcLigneAdresse3_Beneficiaire, 
                            vcVille_Beneficiaire, vcProvince_Beneficiaire, vcPays_Beneficiaire, vcCodePostal_Beneficiaire, bResidence_Quebec
                        FROM 
                            dbo.tblIQEE_RemplacementsBeneficiaire 
                        WHERE 
                            iID_Remplacement_Beneficiaire = @iID_Enregistrement_Annuler 

                        SET @iID_Enregistrement_New = IDENT_CURRENT('dbo.tblIQEE_RemplacementsBeneficiaire')
                    END
                    ELSE IF @cCodeTypeEnregistrement = '04'
                    BEGIN
                        --  Création de la T04
                        INSERT INTO dbo.tblIQEE_Transferts (
                            iID_Fichier_IQEE, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse, iID_Convention, vcNo_Convention, 
                            dtDate_Debut_Convention, iID_Sous_Type, iID_Operation, iID_TIO, iID_Operation_RIO, 
                            dtDate_Transfert, mTotal_Transfert, mCotisations_Donne_Droit_IQEE, mCotisations_Non_Donne_Droit_IQEE, 
                            mIQEE_CreditBase_Transfere, mIQEE_Majore_Transfere, ID_Autre_Promoteur, ID_Regime_Autre_Promoteur, vcNo_Contrat_Autre_Promoteur, 
                            iID_Beneficiaire, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire, 
                            iID_Adresse_Beneficiaire, vcNo_Civique_Beneficiaire, vcRue_Beneficiaire, vcVille_Beneficiaire, vcProvince_Beneficiaire, vcPays_Beneficiaire, vcCodePostal_Beneficiaire, 
                            bTransfert_Total, bPRA_Deja_Verse, mJuste_Valeur_Marchande, mBEC, bTransfert_Autorise, 
                            iID_Souscripteur, tiType_Souscripteur, vcNAS_Souscripteur, vcNom_Souscripteur, vcPrenom_Souscripteur, tiID_Lien_Souscripteur, 
                            iID_Adresse_Souscripteur, vcNo_Civique_Souscripteur, vcRue_Souscripteur, vcVille_Souscripteur, vcProvince_Souscripteur, vcPays_Souscripteur, vcCodePostal_Souscripteur, 
                            mCotisations_Versees_Avant_Debut_IQEE
                        )
                        SELECT
                            @iID_Fichier_Annulation, siAnnee_Fiscale, 1, 'D', iID_Convention, vcNo_Convention, 
                            dtDate_Debut_Convention, iID_Sous_Type, iID_Operation, iID_TIO, iID_Operation_RIO, 
                            dtDate_Transfert, mTotal_Transfert, mCotisations_Donne_Droit_IQEE, mCotisations_Non_Donne_Droit_IQEE, 
                            mIQEE_CreditBase_Transfere, mIQEE_Majore_Transfere, ID_Autre_Promoteur, ID_Regime_Autre_Promoteur, vcNo_Contrat_Autre_Promoteur, 
                            iID_Beneficiaire, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire, 
                            iID_Adresse_Beneficiaire, vcNo_Civique_Beneficiaire, vcRue_Beneficiaire, vcVille_Beneficiaire, vcProvince_Beneficiaire, vcPays_Beneficiaire, vcCodePostal_Beneficiaire, 
                            bTransfert_Total, bPRA_Deja_Verse, mJuste_Valeur_Marchande, mBEC, bTransfert_Autorise, 
                            iID_Souscripteur, tiType_Souscripteur, vcNAS_Souscripteur, vcNom_Souscripteur, vcPrenom_Souscripteur, tiID_Lien_Souscripteur, 
                            iID_Adresse_Souscripteur, vcNo_Civique_Souscripteur, vcRue_Souscripteur, vcVille_Souscripteur, vcProvince_Souscripteur, vcPays_Souscripteur, vcCodePostal_Souscripteur, 
                            mCotisations_Versees_Avant_Debut_IQEE
                        FROM 
                            dbo.tblIQEE_Transferts
                        WHERE 
                            iID_Transfert = @iID_Enregistrement_Annuler 

                        SET @iID_Enregistrement_New = IDENT_CURRENT('dbo.tblIQEE_Transferts')
                    END 
                    ELSE IF @cCodeTypeEnregistrement = '05'
                    BEGIN
                        --  Création de la T05
                        INSERT INTO dbo.tblIQEE_PaiementsBeneficiaires (
                            iID_Fichier_IQEE, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse, iID_Convention, vcNo_Convention,
                            iID_Sous_Type, iID_Bourse, iID_Paiement_Bourse, iID_Operation, dtDate_Paiement,
                            mCotisations_Retirees, mIQEE_CreditBase, mIQEE_Majoration, mPAE_Verse, iID_Beneficiaire, vcNAS_Beneficiaire,
                            vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire, bResidence_Quebec,
                            tiType_Etudes, tiDuree_Programme, tiAnnee_Programme, dtDate_Debut_Annee_Scolaire, tiDuree_Annee_Scolaire,
                            vcCode_Postal_Etablissement --,vcNom_Etablissement
                        )
                        SELECT
                            @iID_Fichier_Annulation, siAnnee_Fiscale, 1, 'D', iID_Convention, vcNo_Convention, 
                            iID_Sous_Type, iID_Bourse, iID_Paiement_Bourse, iID_Operation, dtDate_Paiement,
                            mCotisations_Retirees, mIQEE_CreditBase, mIQEE_Majoration, mPAE_Verse, iID_Beneficiaire, vcNAS_Beneficiaire,
                            vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire, bResidence_Quebec,
                            tiType_Etudes, tiDuree_Programme, tiAnnee_Programme, dtDate_Debut_Annee_Scolaire, tiDuree_Annee_Scolaire,
                            vcCode_Postal_Etablissement --,vcNom_Etablissement
                        FROM 
                            dbo.tblIQEE_PaiementsBeneficiaires
                        WHERE 
                            iID_Paiement_Beneficiaire = @iID_Enregistrement_Annuler 

                        SET @iID_Enregistrement_New = IDENT_CURRENT('dbo.tblIQEE_PaiementsBeneficiaires')
                    END 
                    ELSE IF @cCodeTypeEnregistrement = '06'
                    BEGIN
                        --  Création de la T06
                        INSERT INTO dbo.tblIQEE_ImpotsSpeciaux (
                            iID_Fichier_IQEE, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse, iID_Convention, vcNo_Convention,
                            iID_Sous_Type, iID_Remplacement_Beneficiaire, iID_Transfert, iID_Operation, iID_Cotisation,
                            iID_RI, iID_Cheque, iID_Statut_Convention, dtDate_Evenement, mCotisations_Retirees,
                            mSolde_IQEE_Base, mSolde_IQEE_Majore, mIQEE_ImpotSpecial, mRadiation, mCotisations_Donne_Droit_IQEE,
                            mJuste_Valeur_Marchande, mBEC, mSubvention_Canadienne, mSolde_IQEE, iID_Beneficiaire,
                            vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire,
                            vcCode_Postal_Etablissement, vcNom_Etablissement, mMontant_A, mMontant_B, mMontant_C, mMontant_AFixe, mEcart_ReelvsFixe
                        )
                        SELECT
                            @iID_Fichier_Annulation, siAnnee_Fiscale, 1, 'D', iID_Convention, vcNo_Convention, 
                            iID_Sous_Type, iID_Remplacement_Beneficiaire, iID_Transfert, iID_Operation, iID_Cotisation,
                            iID_RI, iID_Cheque, iID_Statut_Convention, dtDate_Evenement, mCotisations_Retirees, 
                            mSolde_IQEE_Base, mSolde_IQEE_Majore, mIQEE_ImpotSpecial, mRadiation, mCotisations_Donne_Droit_IQEE, 
                            mJuste_Valeur_Marchande, mBEC, mSubvention_Canadienne, mSolde_IQEE, iID_Beneficiaire, 
                            vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire, 
                            vcCode_Postal_Etablissement, vcNom_Etablissement, mMontant_A, mMontant_B, mMontant_C, mMontant_AFixe, mEcart_ReelvsFixe
                        FROM 
                            dbo.tblIQEE_ImpotsSpeciaux 
                        WHERE 
                            iID_Impot_Special = @iID_Enregistrement_Annuler 

                        IF @@ROWCOUNT > 0
                        BEGIN
                            SET @iID_Enregistrement_New = IDENT_CURRENT('dbo.tblIQEE_ImpotsSpeciaux')

                            --EXEC dbo.psIQEE_CreerOperationFinanciere_ImpotsSpeciaux @iID_Utilisateur = @iID_Utilisateur_Creation,
                            --                                                        @iID_FichierIQEE = @iID_Fichier_Annulation,
                            --                                                        @iID_SousType = @iID_Sous_Type,
                            --                                                        @iID_ImpotSpecial = @iID_Enregistrement_New
                        END 
                        ELSE
                            SET @iID_Enregistrement_New = 0
                    END
                   
                    PRINT '      @iID_Enregistrement_New: ' + STR(@iID_Enregistrement_New) + ' for T' + @cCodeTypeEnregistrement

                    -- Mettre à jour la table tblIQEE_Annulations 
                    UPDATE dbo.tblIQEE_Annulations 
                       SET iID_Enregistrement_Annulation = @iID_Enregistrement_New 
                     WHERE iID_Annulation = @iID_Annulation 
                END
            END 
        END
    END
    
    --  Reprise de la transaction
    --  =========================

    IF @bCreer_TransactionReprise = 0
    BEGIN
        PRINT 'Reprise ...'
        IF EXISTS(SELECT * FROM #TB_Transaction WHERE iID_Level = 1 AND cTypeTransaction = '02')
        BEGIN
            PRINT '   Création de la transaction de reprise à zéro pour #' + LTRIM(STR(@iID_LigneFichier,10))
            --EXEC dbo.psIQEE_CreerTransactions02 @iID_Fichier_Annulation, @siAnnee_Fiscale, @bPremier_Envoi_Originaux, @bArretPremiereErreur,
            --                                    @cCode_Portee,  @bConsequence_Annulation, @iID_Session, @dtCreationFichier, @cID_Langue,
            --                                    @bCasSpecial, @tiCode_Version = 2
            
            INSERT INTO dbo.tblIQEE_Demandes (
                iID_Fichier_IQEE, siAnnee_Fiscale, cStatut_Reponse, iID_Convention, vcNo_Convention, tiCode_Version,
                dtDate_Debut_Convention, tiNB_Annee_Quebec, mCotisations, mTransfert_IN, mTotal_Cotisations_Subventionnables, mTotal_Cotisations, 
                iID_Beneficiaire_31Decembre, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire, 
                iID_Adresse_31Decembre_Beneficiaire, vcAppartement_Beneficiaire, vcNo_Civique_Beneficiaire, vcRue_Beneficiaire, 
                vcLigneAdresse2_Beneficiaire, vcLigneAdresse3_Beneficiaire, vcVille_Beneficiaire, vcProvince_Beneficiaire,
                vcPays_Beneficiaire, vcCodePostal_Beneficiaire, bResidence_Quebec, iID_Souscripteur, tiType_Souscripteur,
                vcNAS_Souscripteur, vcNEQ_Souscripteur, vcNom_Souscripteur, vcPrenom_Souscripteur, tiID_Lien_Souscripteur, 
                iID_Adresse_Souscripteur, vcAppartement_Souscripteur, vcNo_Civique_Souscripteur, vcRue_Souscripteur, vcLigneAdresse2_Souscripteur,
                vcLigneAdresse3_Souscripteur, vcVille_Souscripteur, vcCodePostal_Souscripteur, vcProvince_Souscripteur, vcPays_Souscripteur,
                vcTelephone_Souscripteur, iID_Cosouscripteur, vcNAS_Cosouscripteur, vcNom_Cosouscripteur, vcPrenom_Cosouscripteur,
                tiID_Lien_Cosouscripteur, vcTelephone_Cosouscripteur, tiType_Responsable, vcNAS_Responsable, vcNEQ_Responsable,
                vcNom_Responsable, vcPrenom_Responsable, tiID_Lien_Responsable, vcAppartement_Responsable, vcNo_Civique_Responsable,
                vcRue_Responsable, vcLigneAdresse2_Responsable, vcLigneAdresse3_Responsable, vcVille_Responsable, vcCodePostal_Responsable,
                vcProvince_Responsable, vcPays_Responsable, vcTelephone_Responsable, bInd_Cession_IQEE
            )
            SELECT @iID_Fichier_Annulation, siAnnee_Fiscale, 'A', iID_Convention, vcNo_Convention, 2,
                    dtDate_Debut_Convention, tiNB_Annee_Quebec, 0, 0, 0, 0, 
                    iID_Beneficiaire_31Decembre, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire, 
                    iID_Adresse_31Decembre_Beneficiaire, vcAppartement_Beneficiaire, vcNo_Civique_Beneficiaire, vcRue_Beneficiaire, 
                    vcLigneAdresse2_Beneficiaire, vcLigneAdresse3_Beneficiaire, vcVille_Beneficiaire, vcProvince_Beneficiaire,
                    vcPays_Beneficiaire, vcCodePostal_Beneficiaire, bResidence_Quebec, iID_Souscripteur, tiType_Souscripteur,
                    vcNAS_Souscripteur, vcNEQ_Souscripteur, vcNom_Souscripteur, vcPrenom_Souscripteur, tiID_Lien_Souscripteur,
                    iID_Adresse_Souscripteur, vcAppartement_Souscripteur, vcNo_Civique_Souscripteur, vcRue_Souscripteur, vcLigneAdresse2_Souscripteur,
                    vcLigneAdresse3_Souscripteur, vcVille_Souscripteur, vcCodePostal_Souscripteur, vcProvince_Souscripteur, vcPays_Souscripteur,
                    vcTelephone_Souscripteur, iID_Cosouscripteur, vcNAS_Cosouscripteur, vcNom_Cosouscripteur, vcPrenom_Cosouscripteur,
                    tiID_Lien_Cosouscripteur, vcTelephone_Cosouscripteur, tiType_Responsable, vcNAS_Responsable, vcNEQ_Responsable,
                    vcNom_Responsable, vcPrenom_Responsable, tiID_Lien_Responsable, vcAppartement_Responsable, vcNo_Civique_Responsable,
                    vcRue_Responsable, vcLigneAdresse2_Responsable, vcLigneAdresse3_Responsable, vcVille_Responsable, vcCodePostal_Responsable,
                    vcProvince_Responsable, vcPays_Responsable, vcTelephone_Responsable, bInd_Cession_IQEE
                FROM dbo.tblIQEE_Demandes 
                WHERE iID_Demande_IQEE = @iID_Enregistrement_Annuler 

            SET @iID_Enregistrement_New = IDENT_CURRENT('dbo.tblIQEE_Demandes')
        END
        ELSE
            SET @iID_Enregistrement_New = 0

        SET @iID_Level = 1
    END
    ELSE
        SET @iID_Level = 0

    BEGIN
        PRINT '   Reprise des transactions retrouvées'

        WHILE EXISTS(SELECT * FROM #TB_Transaction WHERE iID_Level > @iID_Level)
        BEGIN
            SELECT TOP 1 @iID_Level = iID_Level,
                         @siAnnee_Fiscale = siAnnee,
                         @iID_Enregistrement_Annuler = iID_Evenement,
                         @cCodeTypeEnregistrement = cTypeTransaction,
                         @cCode_Sous_Type = cSousTypeTrans
              FROM #TB_Transaction 
             WHERE iID_Level > @iID_Level
             ORDER BY iID_Level

            PRINT '      Transaction #' + LTRIM(STR(@iID_Enregistrement_Annuler, 10)) + ' de l''année fiscale ' + STR(@siAnnee_Fiscale, 4)

            IF @cCodeTypeEnregistrement = '02'
            BEGIN
                EXEC dbo.psIQEE_CreerTransactions02 @iID_Fichier_Annulation, @siAnnee_Fiscale, @bPremier_Envoi_Originaux, @bArretPremiereErreur,
                                                    @cCode_Portee,  @bConsequence_Annulation, @iID_Session, @dtCreationFichier, @cID_Langue,
                                                    @bCasSpecial, @tiCode_Version = 2
                SET @iID_Enregistrement_New = IDENT_CURRENT('dbo.tblIQEE_Demandes')

                -- Insérer les liens entre les transactions de cotisation et la demande
                WHILE @vcID_Transactions IS NOT NULL AND @vcID_Transactions <> ''
                BEGIN
                    SET @vcTMP1 = SUBSTRING(@vcID_Transactions,1,CHARINDEX(',',@vcID_Transactions)-1)
                    SET @vcID_Transactions = SUBSTRING(@vcID_Transactions,LEN(@vcTMP1)+2,8000)

                    INSERT INTO dbo.tblIQEE_TransactionsDemande (iID_Demande_IQEE, iID_Transaction)
                    VALUES (@iID_Enregistrement_New, CAST(@vcTMP1 AS INT))
                END
            END 
            ELSE IF @cCodeTypeEnregistrement = '03'
            BEGIN
                EXECUTE dbo.psIQEE_CreerTransactions03 @iID_Fichier_Annulation, @siAnnee_Fiscale, @bArretPremiereErreur,
                                                        @cCode_Portee, @bCasSpecial, @tiCode_Version = 2

                SET @iID_Enregistrement_New = IDENT_CURRENT('dbo.tblIQEE_RemplacementsBeneficiaire')
            END
            ELSE IF @cCodeTypeEnregistrement = '04'
            BEGIN
                IF @cCode_Sous_Type = '01'
                    EXECUTE dbo.psIQEE_CreerTransactions04_01 @iID_Fichier_Annulation, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, 
                                                              @iID_Utilisateur_Creation, @bCasSpecial, @tiCode_Version = 2
                ELSE IF @cCode_Sous_Type = '02'
                    EXECUTE dbo.psIQEE_CreerTransactions04_02 @iID_Fichier_Annulation, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, 
                                                              @iID_Utilisateur_Creation, @bCasSpecial, @tiCode_Version = 2
                ELSE IF @cCode_Sous_Type = '03'
                    EXECUTE dbo.psIQEE_CreerTransactions04_03 @iID_Fichier_Annulation, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, 
                                                              @iID_Utilisateur_Creation, @bCasSpecial, @tiCode_Version = 2

                SET @iID_Enregistrement_New = IDENT_CURRENT('dbo.tblIQEE_Transferts')
            END 
            ELSE IF @cCodeTypeEnregistrement = '05'
            BEGIN
                IF @cCode_Sous_Type = '01'
                    EXECUTE dbo.psIQEE_CreerTransactions05_01 @iID_Fichier_Annulation, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, 
                                                              @iID_Utilisateur_Creation, @bCasSpecial, @tiCode_Version = 2

                SET @iID_Enregistrement_New = IDENT_CURRENT('dbo.tblIQEE_Transferts')
            END 
            ELSE IF @cCodeTypeEnregistrement = '06'
            BEGIN
                IF @cCode_Sous_Type = '01'
                    EXECUTE dbo.psIQEE_CreerTransactions06_01 @iID_Fichier_Annulation, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, 
                                                              @iID_Utilisateur_Creation, @bCasSpecial, @tiCode_Version = 2
                ELSE IF @cCode_Sous_Type = '02'
                    EXECUTE dbo.psIQEE_CreerTransactions06_01 @iID_Fichier_Annulation, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, 
                                                              @iID_Utilisateur_Creation, @bCasSpecial, @tiCode_Version = 2
                ELSE IF @cCode_Sous_Type = '22'
                    EXECUTE dbo.psIQEE_CreerTransactions06_22 @iID_Fichier_Annulation, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, 
                                                              @iID_Utilisateur_Creation, @bCasSpecial, @tiCode_Version = 2
                ELSE IF @cCode_Sous_Type = '23'
                    EXECUTE dbo.psIQEE_CreerTransactions06_23 @iID_Fichier_Annulation, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, 
                                                              @bCasSpecial, @tiCode_Version = 2
                ELSE IF @cCode_Sous_Type = '31'
                    EXECUTE dbo.psIQEE_CreerTransactions06_31 @iID_Fichier_Annulation, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, 
                                                              @iID_Utilisateur_Creation, @bCasSpecial, @tiCode_Version = 2
                ELSE IF @cCode_Sous_Type = '41'
                    EXECUTE dbo.psIQEE_CreerTransactions06_41 @iID_Fichier_Annulation, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, 
                                                              @iID_Utilisateur_Creation, @bCasSpecial, @tiCode_Version = 2
                ELSE IF @cCode_Sous_Type = '91'
                    EXECUTE dbo.psIQEE_CreerTransactions06_91 @iID_Fichier_Annulation, @siAnnee_Fiscale, @bArretPremiereErreur, @cCode_Portee, 
                                                              @iID_Utilisateur_Creation, @bCasSpecial, @tiCode_Version = 2

                SET @iID_Enregistrement_New = IDENT_CURRENT('dbo.tblIQEE_ImpotsSpeciaux')
            END 

            -- Mettre à jour la table tblIQEE_Annulations avec le numéro de reprise
            IF @iID_Enregistrement_New > 0
                UPDATE dbo.tblIQEE_Annulations 
                   SET iID_Enregistrement_Reprise = @iID_Enregistrement_New 
                 WHERE iID_Enregistrement_Demande_Annulation = @iID_Enregistrement_Annuler

        END
    END

    IF @vcState_Convention = 'FRM'
    BEGIN
        INSERT INTO dbo.Un_ConventionConventionState (
            ConventionID, ConventionStateID, StartDate
        )
        VALUES 
            (@iID_Convention, 'FRM', DATEADD(MINUTE, 1, @dtCreationFichier))

        IF OBJECT_ID('tempdb..#DisableTrigger') IS NOT NULL
            DELETE FROM #DisableTrigger WHERE vcTriggerName = 'TUn_ConventionConventionState_I'
    END 

    PRINT 'Annulation de la transaction #' + LTRIM(STR(@iID_LigneFichier, 10)) + ' terminée'
    PRINT '-------------------------------------------------'
END

