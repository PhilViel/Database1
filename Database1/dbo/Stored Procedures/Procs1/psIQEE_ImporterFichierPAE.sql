/********************************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service :   psIQEE_ImporterFichierPAE
Nom du service  :   Importer un fichier de réponses PAE
But             :   Traiter un fichier de réponses du type "Transactions de paiement traitées" de Revenu Québec 
                    dans le module de l'IQÉÉ.
Facette         :   IQÉÉ

Paramètres d’entrée :
    Paramètre                           Description
    ------------------------            -----------------------------------------------------------------
    iID_Fichier_IQEE                    Identifiant unique du fichier d'erreur de l'IQÉÉ en cours d'importation.
    siAnnee_Fiscale                     Année fiscale des réponses du fichier en cours d'importation.
    cID_Langue                          Langue du traitement.

Exemple d’appel :   
    Cette procédure doit uniquement être appelé du service "psIQEE_ImporterFichierReponses".

Paramètres de sortie :
    Champ                               Description
    ---------------------------         ---------------------------------
    bInd_Erreur                         Indicateur s'il y a eue une erreur dans le traitement.

Historique des modifications:
    Date        Programmeur             Description                                
    ----------  --------------------    -----------------------------------------
    2009-10-26  Steeve Picard           Création du service                            
***********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_ImporterFichierPAE
(
    @iID_Fichier_IQEE INT,
    @siAnnee_Fiscale SMALLINT,
    @cID_Langue CHAR(3),
    @bInd_Erreur BIT OUTPUT
)
AS
BEGIN
    -- Déclarations des variables locales
    DECLARE @cLigne CHAR(1000),
            @vcNo_Convention VARCHAR(15),
            @tiCode_Version TINYINT,
            @vcReponse VARCHAR(10),
            @iID_Paiement_IQEE INT,
            @vcNo_Identification_RQ VARCHAR(10),
            @cCode_Statut CHAR(1),
            @iIdTransaction INT = 0

    Declare @iNbTransactionsTraitees int = 0,
            @iNombreLignes INT,
            @vcMessage VARCHAR(MAX)
            
    SET @vcMessage = CHAR(13) + CHAR(10) + 
                     'Importation des réponses de Paiement de bourse (T05) pour ' + STR(@siAnnee_Fiscale, 4) + CHAR(13) + CHAR(10) +
                     '--------------------------------------------------------------' + CHAR(13) + CHAR(10) +
                     '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_ImporterFichierPAE started (Fichier ID: ' + LTRIM(STR(@iID_Fichier_IQEE, 10)) + ')'
    RAISERROR('%s', 0, 1, @vcMessage)
    
    IF (SELECT COUNT(*) FROM dbo.tblIQEE_LignesFichier WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE AND cLigne LIKE '01%') <> 1
    BEGIN
        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('2',10,'       Erreur: Il doit avoir un seul enregistrements de type 01 (Entête du fichier).')
        GOTO ERREUR_TRAITEMENT
    END
    
    IF (SELECT COUNT(*) FROM dbo.tblIQEE_LignesFichier WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE AND cLigne LIKE '99%') <> 1
    BEGIN
        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('2',10,'       Erreur: Il doit avoir un seul enregistrements de type 99 (fin de fichier).')
        GOTO ERREUR_TRAITEMENT
    END

    -----------------------------------------------------------
    -- Récupère le nombre de réponse (type d'enregistrement 99)
    -----------------------------------------------------------

    SELECT
        @iNombreLignes = CAST(SUBSTRING(LF.cLigne, 13, 9) AS INT) - 2
    FROM 
        dbo.tblIQEE_LignesFichier LF
    WHERE
        LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
        AND LF.cLigne LIKE '99%'

    --------------------------------------------------------------
    -- Traiter les réponses du Ministre (type d'enregistrement 55)
    --------------------------------------------------------------

    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierPAE          - '+
            'Traiter les réponses du Ministre (type d''enregistrement 55)')

    IF OBJECT_ID('tempDB..#TB_Import_T55') IS NOT NULL
        DROP TABLE #TB_Import_T55

    SELECT
        tiCode_Version = CAST(SUBSTRING(LF.cLigne, 3, 1) AS TINYINT),
        iID_Transaction = CAST(SUBSTRING(LF.cLigne, 6, 15) AS INT),
        vcNo_Convention = CAST(SUBSTRING(LF.cLigne, 31, 15) AS VARCHAR(15)),
        iID_Regime = CAST(SUBSTRING(LF.cLigne, 46, 10) AS INT),
        dtPaiement = dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne, 56, 8), 'D', 8, NULL),
        bRevenuAccumule = CAST(SUBSTRING(LF.cLigne, 64, 1) AS BIT),
        vcReponse = CAST(SUBSTRING(LF.cLigne, 183, 7) AS VARCHAR(10)),
        iID_Paiement = CAST(NULL AS INT)
    INTO
        #TB_Import_T55
    FROM 
        dbo.tblIQEE_LignesFichier LF
    WHERE
        LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
        AND LF.cLigne LIKE '55%'

    UPDATE #TB_Import_T55 SET 
        iID_Paiement = (SELECT iID_Paiement_Beneficiaire FROM dbo.tblIQEE_PaiementsBeneficiaires WHERE iID_Ligne_Fichier = iID_Transaction)

    SELECT '#TB_Import_T55', * FROM #TB_Import_T55

    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierPAE          - '+
            'Traiter les réponses de paiement au bénéficiaire (type d''enregistrement 55).')

    WHILE EXISTS(SELECT * FROM #TB_Import_T55 WHERE iID_Transaction > @iIdTransaction)
    BEGIN
        SELECT TOP 1
            @iIdTransaction = iID_Transaction,
            @vcNo_Convention = vcNo_Convention,
            @tiCode_Version = tiCode_Version,
            @vcReponse = vcReponse,
            @iID_Paiement_IQEE = ISNULL(iID_Paiement, 0)
        FROM
            #TB_Import_T55
        WHERE
            iID_Transaction > @iIdTransaction
        ORDER BY
            iID_Transaction
        
        IF @iID_Paiement_IQEE > 0
        BEGIN 
            INSERT INTO dbo.tblIQEE_ReponsesPaiement (
                iID_Paiement_IQEE, iID_Fichier_IQEE, vcStatutTransaction
            )
            VALUES (
                @iID_Paiement_IQEE, @iID_Fichier_IQEE, @vcReponse
            )

            UPDATE dbo.tblIQEE_PaiementsBeneficiaires SET
                cStatut_Reponse = 'R'
            WHERE
                iID_Paiement_Beneficiaire = @iID_Paiement_IQEE

            SET @iNbTransactionsTraitees = @iNbTransactionsTraitees + 1
        END 
        ELSE
            PRINT 'Not found record for : ' + @vcNo_Convention
    END
    
    IF @iNbTransactionsTraitees < @iNombreLignes
    BEGIN
        SET @iNombreLignes = @iNombreLignes - @iNbTransactionsTraitees
        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('2',10,'       Erreur: ' + LTRIM(STR(@iNombreLignes)) + ' enregistrement(s) de type 55 non pas été traité(s).')

        GOTO ERREUR_TRAITEMENT
    END

    GOTO FIN_TRAITEMENT

ERREUR_TRAITEMENT:
    SET @bInd_Erreur = 1

FIN_TRAITEMENT:
END
