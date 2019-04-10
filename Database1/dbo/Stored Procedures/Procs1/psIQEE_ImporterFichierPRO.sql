/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_ImporterFichierPRO
Nom du service        : Importer un fichier de réponses PRO
But                 : Traiter un fichier de réponses du type "Transactions de détermination de crédit" de Revenu Québec
                      dans le module de l'IQÉÉ.
Facette                : IQÉÉ

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------
                        iID_Fichier_IQEE            Identifiant unique du fichier d'erreur de l'IQÉÉ en cours
                                                    d'importation.
                        siAnnee_Fiscale                Année fiscale des réponses du fichier en cours d'importation.
                        cID_Langue                    Langue du traitement.

Exemple d’appel        :    Cette procédure doit uniquement être appelé du service "psIQEE_ImporterFichierReponses".

Paramètres de sortie:    Table                        Champ                            Description
                          -------------------------    ---------------------------     ---------------------------------
                        S/O                            dtDate_Paiement_Courriel        Date de paiement qui servira au
                                                                                    formatage du courriel aux destinataires
                        S/O                            mMontant_Total_Paiement_        Montant total du paiement qui servira
                                                        Courriel                    au formatage du courriel aux destinataires    
                        S/O                            bInd_Erreur                        Indicateur s'il y a eue une erreur
                                                                                    dans le traitement.

Historique des modifications:
        Date            Programmeur                            Description                                
        ------------    ----------------------------------    -----------------------------------------
        2009-10-26        Éric Deshaies                        Création du service                            
        2014-05-08        Stéphane Barbeau                    Ajout de commit pour amélioration de performance et d'un compteur.
        2016-03-11        Patrice Cote                        Ajout de la gestion des identifiants de transaction.
        2018-02-08      Steeve Picard                       Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
***********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_ImporterFichierPRO 
(
    @iID_Fichier_IQEE INT,
    @siAnnee_Fiscale SMALLINT,
    @cID_Langue CHAR(3),
    @dtDate_Paiement_Courriel DATETIME OUTPUT,
    @mMontant_Total_Paiement_Courriel MONEY OUTPUT,
    @bInd_Erreur BIT OUTPUT
)
AS
BEGIN
    -- Déclarations des variables locales
    DECLARE @cLigne CHAR(1000),
            @iID_Lien_Fichier_IQEE_Demande INT,
            @vcDescription VARCHAR(250),
            @tiID_Categorie_Justification_RQ TINYINT,
            @vcNo_Convention VARCHAR(15),
            @tiID_Type_Reponse TINYINT,
            @cCode CHAR(2),
            @vcCode VARCHAR(2),
            @iID_Demande_IQEE INT,
            @tiID_Justification_RQ TINYINT,
            @mMontant MONEY,
            @bInd_Partage BIT,
            @iNB_Transactions1 INT,
            @iNB_Transactions2 INT,
            @iNB_Transactions3 INT,
            @mMontant_Total_Paiement MONEY,
            @mMontant_Total_Paiement_Importe MONEY,
            @dtDate_Production_Paiement DATETIME,
            @dtDate_Paiement DATETIME,
            @iNumero_Paiement INT,
            @vcInstitution_Paiement VARCHAR(4),
            @vcTransit_Paiement VARCHAR(5),
            @vcCompte_Paiement VARCHAR(12),
            @vcNo_Identification_RQ VARCHAR(10),
            @cCode_Statut CHAR(1),
            @iID_Statut_Annulation INT,
            @bIndicateur_Cession BIT,
            @iID_Convention INT,
            @vcNAS_Beneficiaire VARCHAR(9),
            @vcNom_Beneficiaire VARCHAR(20),
            @vcPrenom_Beneficiaire VARCHAR(20),
            @dtDate_Naissance_Beneficiaire DATETIME,
            @vcIdTransaction VARCHAR(15),
            @nouvelleJustificationCree BIT = 0
            
    -- Initialisations
    SET @dtDate_Paiement_Courriel = NULL
    SET @mMontant_Total_Paiement_Courriel = 0
    SET @bInd_Erreur = 0

    Declare @iNbTransactionsTraitees int
    set @iNbTransactionsTraitees = 0
    --------------------------------------------------------------------------------------------------------
    ---- Création automatique des nouvelles justifications RQ inexistantes dans la table de référence de GUI
    --------------------------------------------------------------------------------------------------------
    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierPRO          - '+
            'Création nouvelles justifications RQ')

    -- Rechercher les justifications RQ utilisées
    DECLARE curNouvelleJustifications CURSOR LOCAL FAST_FORWARD FOR
        SELECT DISTINCT CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,101,2), 'A', 2, NULL) AS CHAR(2)),
               'JG'
        FROM tblIQEE_LignesFichier LF
        WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
          AND SUBSTRING(LF.cLigne,1,2) = '22'
          AND SUBSTRING(LF.cLigne,101,2) <> '  '
    UNION
        SELECT DISTINCT CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,103,2), 'A', 2, NULL) AS CHAR(2)),
               'JG'
        FROM tblIQEE_LignesFichier LF
        WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
          AND SUBSTRING(LF.cLigne,1,2) = '22'
          AND SUBSTRING(LF.cLigne,103,2) <> '  '
    UNION
        SELECT DISTINCT CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,114,2), 'A', 2, NULL) AS CHAR(2)),
               'JCB'
        FROM tblIQEE_LignesFichier LF
        WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
          AND SUBSTRING(LF.cLigne,1,2) = '22'
          AND SUBSTRING(LF.cLigne,114,2) <> '  '
    UNION
        SELECT DISTINCT CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,126,2), 'A', 2, NULL) AS CHAR(2)),
               'JM'
        FROM tblIQEE_LignesFichier LF
        WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
          AND SUBSTRING(LF.cLigne,1,2) = '22'
          AND SUBSTRING(LF.cLigne,126,2) <> '  '
    UNION
        SELECT DISTINCT CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,128,2), 'A', 2, NULL) AS CHAR(2)),
               'EM'
        FROM tblIQEE_LignesFichier LF
        WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
          AND SUBSTRING(LF.cLigne,1,2) = '22'
          AND SUBSTRING(LF.cLigne,128,2) <> '  '

    -- Boucler les justifications RQ utilisées
    OPEN curNouvelleJustifications
    FETCH NEXT FROM curNouvelleJustifications INTO @cCode,@vcCode
    WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Création de la justification RQ si elle n'existe pas
            IF NOT EXISTS(SELECT *
                          FROM tblIQEE_JustificationsRQ J
                          WHERE J.cCode = @cCode)
                BEGIN
                    SET @vcDescription = 'Description à déterminer par le département informatique'

                    -- Trouver l'identifiant de la catégorie de justification
                    SELECT @tiID_Categorie_Justification_RQ = CJ.tiID_Categorie_Justification_RQ
                    FROM tblIQEE_CategorieJustification CJ
                    WHERE CJ.vcCode = @vcCode

                    -- Créer la nouvelle justification
                    INSERT INTO dbo.tblIQEE_JustificationsRQ
                               (cCode
                               ,vcDescription
                               ,tiID_Categorie_Justification_RQ)
                         VALUES
                               (@cCode
                               ,@vcDescription
                               ,@tiID_Categorie_Justification_RQ)

                    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                    VALUES ('2',10,'       Avertissement: Nouveau code de justification RQ ajouté automatiquement.'+
                                   '  La description doit être révisée.')
                    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                    VALUES ('2',10,'              Code: '+@cCode)
                END

            FETCH NEXT FROM curNouvelleJustifications INTO @cCode,@vcCode
        END
    CLOSE curNouvelleJustifications
    DEALLOCATE curNouvelleJustifications

    -------------------------------------------------------------
    -- Traiter le sommaire du paiement (type d'enregistrement 21)
    -------------------------------------------------------------

    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierPRO          - '+
            'Traiter le sommaire du paiement (type d''enregistrement 21).')

    ---- Trouver les types d'enregistrement 21 (sommaire du paiement)
    DECLARE @nombreLignes21 INT

    SELECT @cLigne = Min(LF.cLigne),
           @nombreLignes21 = COUNT(*)
    FROM tblIQEE_LignesFichier LF
    WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
      AND SUBSTRING(LF.cLigne,1,2) = '21'
    GROUP BY LF.cLigne
    
    IF @nombreLignes21 <= 0
    BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'       Erreur: Pas d''enregistrement de type 21 (sommaire du paiement).')
            GOTO ERREUR_TRAITEMENT
    END
    
    IF @nombreLignes21 > 1
    BEGIN
        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('2',10,'       Erreur: Plusieurs enregistrements de type 21 (sommaire du paiement).')
        GOTO ERREUR_TRAITEMENT
    END

    -- Lire les informations de la transaction
    SET @mMontant_Total_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,17,12), '9', NULL, 2) AS MONEY)
    SET @iNumero_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,45,8), '9', NULL, 0) AS INT)
    SET @dtDate_Production_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,29,8),'D',NULL,NULL) AS DATETIME)
    SET @dtDate_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,37,8), 'D', NULL, NULL) AS DATETIME)
    SET @vcInstitution_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,53,4), 'X', 4, NULL) AS VARCHAR(4))
    SET @vcTransit_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,57,5), 'X', 5, NULL) AS VARCHAR(5))
    SET @vcCompte_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,62,12), 'X', 12, NULL) AS VARCHAR(12))
    SET @vcNo_Identification_RQ = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,74,10), 'X', 10, NULL) AS VARCHAR(10))
    IF @vcNo_Identification_RQ = ''
        SET @vcNo_Identification_RQ = NULL

    -- Mettre à jour le fichier
    UPDATE tblIQEE_Fichiers
    SET mMontant_Total_Paiement = @mMontant_Total_Paiement,
        iNumero_Paiement = @iNumero_Paiement,
        dtDate_Production_Paiement = @dtDate_Production_Paiement,
        dtDate_Paiement = @dtDate_Paiement,
        vcInstitution_Paiement = @vcInstitution_Paiement,
        vcTransit_Paiement = @vcTransit_Paiement,
        vcCompte_Paiement = @vcCompte_Paiement,
        vcNo_Identification_RQ = @vcNo_Identification_RQ
    WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

    -- Retenir les informations pour le courriel
    IF @mMontant_Total_Paiement > 0
        BEGIN
            SET @dtDate_Paiement_Courriel = @dtDate_Paiement
            SET @mMontant_Total_Paiement_Courriel = @mMontant_Total_Paiement
        END


    --------------------------------------------------------------------
    -- Traiter les déterminations du Ministre (type d'enregistrement 22)
    --------------------------------------------------------------------
    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierPRO          - '+
            'Traiter les déterminations du Ministre (type d''enregistrement 22).')

    -- Trouver les types d'enregistrement 22 (détermination du Ministre)
    DECLARE curType22 CURSOR LOCAL FAST_FORWARD FOR
        SELECT cLigne
        FROM tblIQEE_LignesFichier LF
        WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
          AND SUBSTRING(LF.cLigne,1,2) = '22'
          
    OPEN curType22
    FETCH NEXT FROM curType22 INTO @cLigne
    WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRANSACTION
                
                -- Lire les informations de la transaction
                SET @vcNo_Convention = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,17,15), 'X', 15, NULL) AS VARCHAR(15))
                SET @bIndicateur_Cession = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,176,1), '9', NULL, 0) AS BIT)
                SET @vcIdTransaction = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,229,15), 'X', 15, NULL) AS VARCHAR(15))
                
                -- Si la réponse est une réponse reliée à une demande d'IQÉÉ faisant une cession de l'IQÉÉ au promoteur cessionnaire suite à un transfert total,
                -- il n'est pas possible de trouver une demande originale à la réponse.  Sinon, il faut trouver la demande originale.
                IF @bIndicateur_Cession = 0
                    BEGIN
                        --Si on a un ID de transaction, on retrouve la demande originale facilement
                        IF ISNULL(@vcIdTransaction, '') <> ''
                            BEGIN
                                SELECT @iID_Demande_IQEE = D.iID_Demande_IQEE,
                                       @iID_Lien_Fichier_IQEE_Demande = D.iID_Fichier_IQEE,
                                       @iID_Convention = D.iID_Convention,
                                       @cCode_Statut = D.cStatut_Reponse
                                FROM tblIQEE_Demandes D
                                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                            AND F.bFichier_Test = 0
                                WHERE D.iID_Ligne_Fichier = CAST(@vcIdTransaction AS INT)
                                  AND D.siAnnee_Fiscale = @siAnnee_Fiscale
                            END
                            
                        --Si on a pas d'ID de transaction
                        ELSE
                            BEGIN
                                -- Valider qu'il y a une seule transaction d'origine relié à la réponse
                                SELECT @iNB_Transactions1 = COUNT(*)
                                FROM tblIQEE_Demandes D
                                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                            AND F.bFichier_Test = 0
                                WHERE D.vcNo_Convention = @vcNo_Convention
                                  AND D.siAnnee_Fiscale = @siAnnee_Fiscale
                                  AND D.tiCode_Version = 0
                                  AND D.cStatut_Reponse = 'A'

                                IF @iNB_Transactions1 = 1
                                    SET @cCode_Statut = 'A'

                                SELECT @iNB_Transactions2 = COUNT(*)
                                FROM tblIQEE_Demandes D
                                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                            AND F.bFichier_Test = 0
                                WHERE D.vcNo_Convention = @vcNo_Convention
                                  AND D.siAnnee_Fiscale = @siAnnee_Fiscale
                                  AND D.tiCode_Version = 0
                                  AND D.cStatut_Reponse = 'R'

                                IF @iNB_Transactions2 = 1
                                    SET @cCode_Statut = 'R'

                                SELECT @iNB_Transactions3 = COUNT(*)
                                FROM tblIQEE_Demandes D
                                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                            AND F.bFichier_Test = 0
                                WHERE D.vcNo_Convention = @vcNo_Convention
                                  AND D.siAnnee_Fiscale = @siAnnee_Fiscale
                                  AND D.tiCode_Version = 0
                                  AND D.cStatut_Reponse = 'D'

                                IF @iNB_Transactions3 = 1
                                    SET @cCode_Statut = 'D'

                                IF @iNB_Transactions1 + @iNB_Transactions2 + @iNB_Transactions3 > 1
                                    BEGIN
                                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                                        VALUES ('2',10,'       Erreur: Ne peux pas déterminer une seule transaction d''origine d''une réponse.  Il y en as plusieurs.')
                                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                                        VALUES ('2',10,'              #Convention: '+ISNULL(@vcNo_Convention,''))

                                        CLOSE curType22
                                        DEALLOCATE curType22

                                        GOTO ERREUR_TRAITEMENT
                                    END

                                IF @iNB_Transactions1 + @iNB_Transactions2 + @iNB_Transactions3 = 0
                                    BEGIN
                                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                                        VALUES ('2',10,'       Erreur: Ne peux pas déterminer la transaction d''origine de la réponse.')
                                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                                        VALUES ('2',10,'              #Convention: '+ISNULL(@vcNo_Convention,''))

                                        CLOSE curType22
                                        DEALLOCATE curType22

                                        GOTO ERREUR_TRAITEMENT
                                    END
                            
                            

                                -- Trouver la transaction de demande d'origine relié à la réponse
                                SELECT @iID_Demande_IQEE = D.iID_Demande_IQEE,
                                       @iID_Lien_Fichier_IQEE_Demande = D.iID_Fichier_IQEE,
                                       @iID_Convention = D.iID_Convention
                                FROM tblIQEE_Demandes D
                                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                            AND F.bFichier_Test = 0
                                WHERE D.vcNo_Convention = @vcNo_Convention
                                  AND D.siAnnee_Fiscale = @siAnnee_Fiscale
                                  AND D.tiCode_Version = 0
                                  AND D.cStatut_Reponse = @cCode_Statut
                            END
                            
                        -- Ajouter le fichier de demandes de la réponse dans la liste des fichiers de demandes répondues s'il
                        -- n'y est pas déjà 
                        IF NOT EXISTS (SELECT *
                                       FROM #tblIQEE_Fichiers_Demandes
                                       WHERE iID_Lien_Fichier_IQEE_Demande = @iID_Lien_Fichier_IQEE_Demande)
                            BEGIN
                                SELECT @iNB_Transactions1 = COUNT(*)
                                FROM tblIQEE_Demandes D
                                WHERE D.iID_Fichier_IQEE = @iID_Lien_Fichier_IQEE_Demande

                                INSERT INTO #tblIQEE_Fichiers_Demandes
                                    (iID_Lien_Fichier_IQEE_Demande
                                    ,iNB_Transactions)
                                VALUES
                                    (@iID_Lien_Fichier_IQEE_Demande
                                    ,@iNB_Transactions1)
                            END

                        -- Marquer la transaction de demande d'origine comme ayant reçu une réponse
                        UPDATE tblIQEE_Demandes
                        SET cStatut_Reponse = 'R'
                        WHERE iID_Demande_IQEE = @iID_Demande_IQEE
                          AND cStatut_Reponse = 'A'
                    END
                ELSE
                    BEGIN
                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                        VALUES ('2',10,'       Avertissement: Première cession de l''IQÉÉ reçue.  Vérifier que l''importation est OK et vérifier le résultat dans les historiques de l''IQÉÉ.')
                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                        VALUES ('2',10,'              #Convention: '+@vcNo_Convention)

                        SET @iID_Demande_IQEE = NULL

                        SET @iID_Convention = NULL
                        SELECT @iID_Convention = C.ConventionID
                        FROM dbo.Un_Convention C
                        WHERE C.ConventionNo = @vcNo_Convention

                        IF @iID_Convention IS NULL
                            BEGIN
                                SET @vcNAS_Beneficiaire = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,42,9), 'X', 9, NULL) AS VARCHAR(9))
                                SET @vcNom_Beneficiaire = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,51,20), 'X', 20, NULL) AS VARCHAR(20))
                                SET @vcPrenom_Beneficiaire = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,71,20), 'X', 20, NULL) AS VARCHAR(20))
                                SET @dtDate_Naissance_Beneficiaire = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,91,8), 'D', NULL, NULL) AS DATETIME)

                                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                                VALUES ('2',10,'       Erreur: Numéro de convention invalide sur une cession de l''IQÉÉ.  La réponse a été importé, mais il faut'+
                                                                    ' mettre l''ID de convention dans la table "tblIQEE_ReponsesDemande"')
                                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                                VALUES ('2',10,'              #Convention: '+ISNULL(@vcNo_Convention,''))
                                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                                VALUES ('2',10,'              NAS du bénéficiaire: '+ISNULL(@vcNAS_Beneficiaire,''))
                                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                                VALUES ('2',10,'              Nom du bénéficiaire: '+ISNULL(@vcNom_Beneficiaire,''))
                                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                                VALUES ('2',10,'              Prénom du bénéficiaire: '+ISNULL(@vcPrenom_Beneficiaire,''))
                                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                                VALUES ('2',10,'              Date de naissance du bénéficiaire: '+ISNULL(CONVERT(VARCHAR(10),@dtDate_Naissance_Beneficiaire,120),''))

                                CLOSE curType22
                                DEALLOCATE curType22

                                GOTO ERREUR_TRAITEMENT
                            END
                    END

                -- Traiter le code de justification global 1
                SET @cCode = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,101,2), 'A', 2, NULL) AS CHAR(2))

                IF @cCode IS NOT NULL AND @cCode <> ''
                    BEGIN
                        -- Trouver l'identifiant de la justification RQ
                        SELECT @tiID_Justification_RQ = J.tiID_Justification_RQ
                        FROM tblIQEE_JustificationsRQ J
                        WHERE J.cCode = @cCode

                        -- Trouver l'identifiant du type de réponse
                        SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                        FROM tblIQEE_TypesReponse TR
                        WHERE TR.vcCode = 'JG1'

                        -- Insérer la réponse
                        INSERT INTO dbo.tblIQEE_ReponsesDemande
                                   (iID_Demande_IQEE
                                   ,iID_Fichier_IQEE
                                   ,tiID_Type_Reponse
                                   ,tiID_Justification_RQ
                                   ,iID_Convention)
                             VALUES
                                   (@iID_Demande_IQEE
                                   ,@iID_Fichier_IQEE
                                   ,@tiID_Type_Reponse
                                   ,@tiID_Justification_RQ
                                   ,@iID_Convention)
                    END

                -- Traiter le code de justification global 2
                SET @cCode = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,103,2), 'A', 2, NULL) AS CHAR(2))

                IF @cCode IS NOT NULL AND @cCode <> ''
                    BEGIN
                        -- Trouver l'identifiant de la justification RQ
                        SELECT @tiID_Justification_RQ = J.tiID_Justification_RQ
                        FROM tblIQEE_JustificationsRQ J
                        WHERE J.cCode = @cCode

                        -- Trouver l'identifiant du type de réponse
                        SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                        FROM tblIQEE_TypesReponse TR
                        WHERE TR.vcCode = 'JG2'

                        -- Insérer la réponse
                        INSERT INTO dbo.tblIQEE_ReponsesDemande
                                   (iID_Demande_IQEE
                                   ,iID_Fichier_IQEE
                                   ,tiID_Type_Reponse
                                   ,tiID_Justification_RQ
                                   ,iID_Convention)
                             VALUES
                                   (@iID_Demande_IQEE
                                   ,@iID_Fichier_IQEE
                                   ,@tiID_Type_Reponse
                                   ,@tiID_Justification_RQ
                                   ,@iID_Convention)
                    END

                -- Traiter le crédit de base
                SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,105,9), '9', NULL, 2) AS MONEY)
                SET @cCode = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,114,2), 'A', 2, NULL) AS CHAR(2))
                SET @bInd_Partage = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,116,1), '9', NULL, 0) AS BIT)

                IF @mMontant > 0 OR
                  (@cCode IS NOT NULL AND @cCode <> '')
                    BEGIN
                        -- Trouver l'identifiant de la justification RQ
                        IF @cCode IS NOT NULL AND @cCode <> ''
                            SELECT @tiID_Justification_RQ = J.tiID_Justification_RQ
                            FROM tblIQEE_JustificationsRQ J
                            WHERE J.cCode = @cCode
                        ELSE
                            SET @tiID_Justification_RQ = NULL

                        -- Trouver l'identifiant du type de réponse
                        SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                        FROM tblIQEE_TypesReponse TR
                        WHERE TR.vcCode = 'CDB'

                        -- Insérer la réponse
                        INSERT INTO dbo.tblIQEE_ReponsesDemande
                               (iID_Demande_IQEE
                               ,iID_Fichier_IQEE
                               ,tiID_Type_Reponse
                               ,tiID_Justification_RQ
                               ,mMontant
                               ,bInd_Partage
                               ,iID_Convention)
                         VALUES
                               (@iID_Demande_IQEE
                               ,@iID_Fichier_IQEE
                               ,@tiID_Type_Reponse
                               ,@tiID_Justification_RQ
                               ,@mMontant
                               ,@bInd_Partage
                               ,@iID_Convention)
                    END

                -- Traiter la majoration
                SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,117,9), '9', NULL, 2) AS MONEY)
                SET @cCode = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,126,2), 'A', 2, NULL) AS CHAR(2))
                SET @bInd_Partage = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,130,1), '9', NULL, 0) AS BIT)

                IF @mMontant > 0 OR
                  (@cCode IS NOT NULL AND @cCode <> '')
                    BEGIN
                        -- Trouver l'identifiant de la justification RQ
                        IF @cCode IS NOT NULL AND @cCode <> ''
                            SELECT @tiID_Justification_RQ = J.tiID_Justification_RQ
                            FROM tblIQEE_JustificationsRQ J
                            WHERE J.cCode = @cCode
                        ELSE
                            SET @tiID_Justification_RQ = NULL

                        -- Trouver l'identifiant du type de réponse
                        SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                        FROM tblIQEE_TypesReponse TR
                        WHERE TR.vcCode = 'MAJ'

                        -- Insérer la réponse
                        INSERT INTO dbo.tblIQEE_ReponsesDemande
                               (iID_Demande_IQEE
                               ,iID_Fichier_IQEE
                               ,tiID_Type_Reponse
                               ,tiID_Justification_RQ
                               ,mMontant
                               ,bInd_Partage
                               ,iID_Convention)
                         VALUES
                               (@iID_Demande_IQEE
                               ,@iID_Fichier_IQEE
                               ,@tiID_Type_Reponse
                               ,@tiID_Justification_RQ
                               ,@mMontant
                               ,@bInd_Partage
                               ,@iID_Convention)
                    END

                -- Traiter le code explicatif de la majoration
                SET @cCode = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,128,2), 'A', 2, NULL) AS CHAR(2))

                IF @cCode IS NOT NULL AND @cCode <> ''
                    BEGIN
                        -- Trouver l'identifiant de la justification RQ
                        SELECT @tiID_Justification_RQ = J.tiID_Justification_RQ
                        FROM tblIQEE_JustificationsRQ J
                        WHERE J.cCode = @cCode

                        -- Trouver l'identifiant du type de réponse
                        SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                        FROM tblIQEE_TypesReponse TR
                        WHERE TR.vcCode = 'EXM'

                        -- Insérer la réponse
                        INSERT INTO dbo.tblIQEE_ReponsesDemande
                                   (iID_Demande_IQEE
                                   ,iID_Fichier_IQEE
                                   ,tiID_Type_Reponse
                                   ,tiID_Justification_RQ
                                   ,iID_Convention)
                             VALUES
                                   (@iID_Demande_IQEE
                                   ,@iID_Fichier_IQEE
                                   ,@tiID_Type_Reponse
                                   ,@tiID_Justification_RQ
                                   ,@iID_Convention)
                    END

                -- Traiter les intérêts fournis par RQ
                SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,131,9), '9', NULL, 2) AS MONEY)

                IF @mMontant > 0 
                    BEGIN
                        -- Trouver l'identifiant du type de réponse
                        SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                        FROM tblIQEE_TypesReponse TR
                        WHERE TR.vcCode = 'INT'

                        -- Insérer la réponse
                        INSERT INTO dbo.tblIQEE_ReponsesDemande
                               (iID_Demande_IQEE
                               ,iID_Fichier_IQEE
                               ,tiID_Type_Reponse
                               ,mMontant
                               ,iID_Convention)
                         VALUES
                               (@iID_Demande_IQEE
                               ,@iID_Fichier_IQEE
                               ,@tiID_Type_Reponse
                               ,@mMontant
                               ,@iID_Convention)
                    END

                -- Traiter les montants de cotisation donnant droit à l'IQÉÉ
                SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,140,9), '9', NULL, 2) AS MONEY)

                IF @mMontant > 0 
                    BEGIN
                        -- Trouver l'identifiant du type de réponse
                        SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                        FROM tblIQEE_TypesReponse TR
                        WHERE TR.vcCode = 'MCI'

                        -- Insérer la réponse
                        INSERT INTO dbo.tblIQEE_ReponsesDemande
                               (iID_Demande_IQEE
                               ,iID_Fichier_IQEE
                               ,tiID_Type_Reponse
                               ,mMontant
                               ,iID_Convention)
                         VALUES
                               (@iID_Demande_IQEE
                               ,@iID_Fichier_IQEE
                               ,@tiID_Type_Reponse
                               ,@mMontant
                               ,@iID_Convention)
                    END

                -- Traiter les montants de cumul IQÉÉ pour le bénéficiaire
                SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,149,9), '9', NULL, 2) AS MONEY)

                IF @mMontant > 0 
                    BEGIN
                        -- Trouver l'identifiant du type de réponse
                        SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                        FROM tblIQEE_TypesReponse TR
                        WHERE TR.vcCode = 'CIB'

                        -- Insérer la réponse
                        INSERT INTO dbo.tblIQEE_ReponsesDemande
                               (iID_Demande_IQEE
                               ,iID_Fichier_IQEE
                               ,tiID_Type_Reponse
                               ,mMontant
                               ,iID_Convention)
                         VALUES
                               (@iID_Demande_IQEE
                               ,@iID_Fichier_IQEE
                               ,@tiID_Type_Reponse
                               ,@mMontant
                               ,@iID_Convention)
                    END

                -- Traiter les soldes IQÉÉ
                SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,158,9), '9', NULL, 2) AS MONEY)

                IF @mMontant > 0 
                    BEGIN
                        -- Trouver l'identifiant du type de réponse
                        SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                        FROM tblIQEE_TypesReponse TR
                        WHERE TR.vcCode = 'SOI'

                        -- Insérer la réponse
                        INSERT INTO dbo.tblIQEE_ReponsesDemande
                               (iID_Demande_IQEE
                               ,iID_Fichier_IQEE
                               ,tiID_Type_Reponse
                               ,mMontant
                               ,iID_Convention)
                         VALUES
                               (@iID_Demande_IQEE
                               ,@iID_Fichier_IQEE
                               ,@tiID_Type_Reponse
                               ,@mMontant
                               ,@iID_Convention)
                    END

                -- Traiter les soldes des cotisations ayant donné droit à l'IQÉÉ
                SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,167,9), '9', NULL, 2) AS MONEY)

                IF @mMontant > 0 
                    BEGIN
                        -- Trouver l'identifiant du type de réponse
                        SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                        FROM tblIQEE_TypesReponse TR
                        WHERE TR.vcCode = 'SCD'

                        -- Insérer la réponse
                        INSERT INTO dbo.tblIQEE_ReponsesDemande
                               (iID_Demande_IQEE
                               ,iID_Fichier_IQEE
                               ,tiID_Type_Reponse
                               ,mMontant
                               ,iID_Convention)
                         VALUES
                               (@iID_Demande_IQEE
                               ,@iID_Fichier_IQEE
                               ,@tiID_Type_Reponse
                               ,@mMontant
                               ,@iID_Convention)
                    END
                COMMIT TRANSACTION
                set @iNbTransactionsTraitees = @iNbTransactionsTraitees + 1

            FETCH NEXT FROM curType22 INTO @cLigne
        END
    CLOSE curType22
    DEALLOCATE curType22

    --------------------------------------------------------------------------------------------------------------------
    -- Valider que les montants de l'enregistrement 21 (sommaire du paiement) équivaut à la somme des réponses importées
    --------------------------------------------------------------------------------------------------------------------

    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierPRO          - '+
            'Valider montants sommaire avec somme des réponses importées.')

    SELECT @mMontant_Total_Paiement_Importe = ISNULL(SUM(ISNULL(RD.mMontant,0)),0)
    FROM tblIQEE_ReponsesDemande RD
         JOIN tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
                                     AND TR.vcCode IN ('CDB','MAJ','INT')
    WHERE RD.iID_Fichier_IQEE = @iID_Fichier_IQEE

    IF @mMontant_Total_Paiement <> @mMontant_Total_Paiement_Importe
        BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'       Erreur: Le montant total des réponses importées ('+
                            dbo.fn_Mo_FloatToStr(@mMontant_Total_Paiement_Importe,@cID_Langue,2,1)+
                            ') ne correspond pas au montant de'+
                           ' l''enregistrement 21 (sommaire du paiement)('+dbo.fn_Mo_FloatToStr(@mMontant_Total_Paiement,@cID_Langue,2,1)+').')

            GOTO ERREUR_TRAITEMENT
        END

    GOTO FIN_TRAITEMENT

    ERREUR_TRAITEMENT:
        SET @bInd_Erreur = 1

    FIN_TRAITEMENT:
END
