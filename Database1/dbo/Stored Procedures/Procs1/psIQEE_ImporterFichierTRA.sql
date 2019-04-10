/********************************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service :   psIQEE_ImporterFichierTRA
Nom du service  :   Importer un fichier de réponses TRA
But             :   Traiter un fichier de réponses du type "Transactions de transfert traitées" de Revenu Québec 
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
CREATE PROCEDURE dbo.psIQEE_ImporterFichierTRA
(
    @iID_Fichier_IQEE INT,
    @siAnnee_Fiscale SMALLINT,
    @cID_Langue CHAR(3),
    @bInd_Erreur BIT OUTPUT
)
AS
BEGIN
    -- Déclarations des variables locales
    DECLARE @vcNo_Convention VARCHAR(15),
            @tiCode_Version TINYINT,
            @vcReponse VARCHAR(10),
            @iID_Transfert_IQEE INT,
            @iIdTransaction INT = 0

    Declare @iNbTransactionsTraitees int = 0,
            @iNombreLignes INT 

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
    -- Traiter les réponses du Ministre (type d'enregistrement 54)
    --------------------------------------------------------------

    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierTRA          - '+
            'Traiter les réponses du Ministre (type d''enregistrement 53)')

    IF OBJECT_ID('tempDB..#TB_Import_T54') IS NOT NULL
        DROP TABLE #TB_Import_T54

    SELECT
        tiCode_Version = CAST(SUBSTRING(LF.cLigne, 3, 1) AS TINYINT),
        iID_Transaction = CAST(SUBSTRING(LF.cLigne, 6, 15) AS INT),
        vcNo_Convention = CAST(SUBSTRING(LF.cLigne, 31, 15) AS VARCHAR(15)),
        iID_Regime = CAST(SUBSTRING(LF.cLigne, 46, 0) AS INT),
        dtTransfert = dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne, 56, 8), 'D', 8, NULL),
        bTransfertGlobal = CAST(SUBSTRING(LF.cLigne, 193, 1) AS BIT),
        vcReponse = CAST(SUBSTRING(LF.cLigne, 244, 7) AS VARCHAR(10)),
		iID_Transfert = CAST(NULL as INT)
    INTO
        #TB_Import_T54
    FROM 
        dbo.tblIQEE_LignesFichier LF
    WHERE
        LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
        AND LF.cLigne LIKE '54%'

    UPDATE #TB_Import_T54 SET 
        iID_Transfert = (SELECT iID_Transfert FROM dbo.tblIQEE_TRansferts WHERE iID_Ligne_Fichier = iID_Transaction)

    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierTRA          - '+
            'Traiter les réponses de remplacement de bénéficiaire (type d''enregistrement 53).')

    WHILE EXISTS(SELECT * FROM #TB_Import_T54 WHERE iID_Transaction > @iIdTransaction)
    BEGIN
        SELECT TOP 1
            @iIdTransaction = iID_Transaction,
            @vcNo_Convention = vcNo_Convention,
            @tiCode_Version = tiCode_Version,
            @vcReponse = vcReponse,
			@iID_Transfert_IQEE = iID_Transfert
        FROM
            #TB_Import_T54
        WHERE
            iID_Transaction > @iIdTransaction
		ORDER BY
			iID_Transaction
        
        IF @iID_Transfert_IQEE > 0
        BEGIN 
            INSERT INTO dbo.tblIQEE_ReponsesTransfert (
                iID_Transfert_IQEE, iID_Fichier_IQEE, vcStatutTransaction
            )
            VALUES (
                @iID_Transfert_IQEE, @iID_Fichier_IQEE, @vcReponse
            )

            UPDATE dbo.tblIQEE_Transferts SET
                cStatut_Reponse = 'R'
            WHERE
                iID_Transfert = @iID_Transfert_IQEE

            SET @iNbTransactionsTraitees = @iNbTransactionsTraitees + 1
        END 
        ELSE
            PRINT 'Not found record for : ' + @vcNo_Convention
    END
    
    IF @iNbTransactionsTraitees < @iNombreLignes
    BEGIN
        SET @iNombreLignes = @iNombreLignes - @iNbTransactionsTraitees
        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('2',10,'       Erreur: ' + LTRIM(STR(@iNombreLignes)) + ' enregistrement(s) de type 54 non pas été traité(s).')
            
        GOTO ERREUR_TRAITEMENT
    END

    GOTO FIN_TRAITEMENT

ERREUR_TRAITEMENT:
    SET @bInd_Erreur = 1

FIN_TRAITEMENT:
END
