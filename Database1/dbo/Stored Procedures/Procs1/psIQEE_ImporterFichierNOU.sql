/***********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_ImporterFichierNOU
Nom du service        : Importer un fichier de réponses NOU
But                 : Traiter un fichier de réponses du type "Transactions de nouvelle détermination de crédit" de
                      Revenu Québec dans le module de l'IQÉÉ.
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
        2016-03-14        Patrice Cote                        Ajout de la gestion des identifiants de transaction.
        2018-02-08      Steeve Picard                       Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
***********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_ImporterFichierNOU 
(
    @iID_Fichier_IQEE INT,
    @siAnnee_Fiscale SMALLINT,
    @cID_Langue CHAR(3),
    @dtDate_Paiement_Courriel DATETIME OUTPUT,
    @mMontant_Total_Paiement_Courriel MONEY OUTPUT,
    @mMontant_Total_A_Payer_Courriel MONEY OUTPUT,
    @bInd_Erreur BIT OUTPUT
)
AS
BEGIN
    -- Déclarations des variables locales
    DECLARE @iID_Lien_Fichier_IQEE_Demande INT,
            @cLigne CHAR(1000),
            @vcDescription VARCHAR(250),
            @tiID_Categorie_Justification_RQ TINYINT,
            @vcNo_Convention VARCHAR(15),
            @tiID_Type_Reponse TINYINT,
            @cCode CHAR(2),
            @vcCode VARCHAR(3),
            @iID_Demande_IQEE INT,
            @tiID_Justification_RQ TINYINT,
            @mMontant MONEY,
            @bInd_Partage BIT,
            @iNB_Transactions1 INT,
            @iNB_Transactions2 INT,
            @mMontant_Total_Paiement MONEY,
            @mMontant_Total_Paiement_Importe MONEY,
            @dtDate_Production_Paiement DATETIME,
            @dtDate_Paiement DATETIME,
            @iNumero_Paiement INT,
            @vcInstitution_Paiement VARCHAR(4),
            @vcTransit_Paiement VARCHAR(5),
            @vcCompte_Paiement VARCHAR(12),
            @mMontant_Total_A_Payer MONEY,
            @mMontant_Total_A_Payer_Importe MONEY,
            @cCode_Statut CHAR(1),
            @iID_Enregistrement_Annulation INT,
            @iID_Enregistrement_Origine INT,
            @iID_Statut_Annulation INT,
            @bIndicateur_Cession BIT,
            @iID_Convention INT,
            @vcNAS_Beneficiaire VARCHAR(9),
            @vcNom_Beneficiaire VARCHAR(20),
            @vcPrenom_Beneficiaire VARCHAR(20),
            @dtDate_Naissance_Beneficiaire DATETIME,
            @vcNo_Identification_RQ VARCHAR(10),
            @iID_Utilisateur_Systeme INT,
            @vcIdTransaction VARCHAR(15)

    -- Initialisations
    SET @dtDate_Paiement_Courriel = NULL
    SET @mMontant_Total_Paiement_Courriel = 0
    SET @mMontant_Total_A_Payer_Courriel = 0
    SET @bInd_Erreur = 0

    ------------------------------------------------------------------------------------------------------
    -- Création automatique des nouvelles justifications RQ inexistantes dans la table de référence de GUI
    ------------------------------------------------------------------------------------------------------
    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierNOU          - '+
            'Création nouvelles justifications RQ')
    
    -- Rechercher les justifications RQ utilisées
    DECLARE curNouvelleJustifications CURSOR LOCAL FAST_FORWARD FOR
        SELECT DISTINCT CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,135,2), 'A', 2, NULL) AS CHAR(2)),
               'JG'
        FROM tblIQEE_LignesFichier LF
        WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
          AND SUBSTRING(LF.cLigne,1,2) = '32'
          AND SUBSTRING(LF.cLigne,135,2) <> '  '
    UNION
        SELECT DISTINCT CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,137,2), 'A', 2, NULL) AS CHAR(2)),
               'JG'
        FROM tblIQEE_LignesFichier LF
        WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
          AND SUBSTRING(LF.cLigne,1,2) = '32'
          AND SUBSTRING(LF.cLigne,137,2) <> '  '
    UNION
        SELECT DISTINCT CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,148,2), 'A', 2, NULL) AS CHAR(2)),
               'JCB'
        FROM tblIQEE_LignesFichier LF
        WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
          AND SUBSTRING(LF.cLigne,1,2) = '32'
          AND SUBSTRING(LF.cLigne,148,2) <> '  '
    UNION
        SELECT DISTINCT CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,160,2), 'A', 2, NULL) AS CHAR(2)),
               'JM'
        FROM tblIQEE_LignesFichier LF
        WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
          AND SUBSTRING(LF.cLigne,1,2) = '32'
          AND SUBSTRING(LF.cLigne,160,2) <> '  '
    UNION
        SELECT DISTINCT CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,162,2), 'A', 2, NULL) AS CHAR(2)),
               'EM'
        FROM tblIQEE_LignesFichier LF
        WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
          AND SUBSTRING(LF.cLigne,1,2) = '32'
          AND SUBSTRING(LF.cLigne,162,2) <> '  '

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

    ---------------------------------------------------------------
    -- Traiter le sommaire du traitement (type d'enregistrement 31)
    ---------------------------------------------------------------

    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierNOU          - '+
            'Traiter le sommaire du traitement (type d''enregistrement 31).')

    ---- Trouver les types d'enregistrement 21 (sommaire du paiement)
    DECLARE @nombreLignes21 INT

    SELECT @cLigne = Min(LF.cLigne),
           @nombreLignes21 = COUNT(*)
    FROM tblIQEE_LignesFichier LF
    WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
      AND SUBSTRING(LF.cLigne,1,2) = '31'
    GROUP BY LF.cLigne
    
    IF @nombreLignes21 <= 0
    BEGIN
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'       Erreur: Pas d''enregistrement de type 31 (sommaire du traitement).')
            GOTO ERREUR_TRAITEMENT
    END
    
    IF @nombreLignes21 > 1
    BEGIN
        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
        VALUES ('2',10,'       Erreur: Plusieurs enregistrements de type 31 (sommaire du traitement).')
        GOTO ERREUR_TRAITEMENT
    END

    -- Lire les informations de la transaction
    SET @dtDate_Production_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,17,8),'D',NULL,NULL) AS DATETIME)
    SET @mMontant_Total_A_Payer = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,25,12), '9', NULL, 2) AS MONEY)
    SET @mMontant_Total_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,37,12), '9', NULL, 2) AS MONEY)
    SET @vcNo_Identification_RQ = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,86,10), 'X', 10, NULL) AS VARCHAR(10))
    IF @vcNo_Identification_RQ = ''
        SET @vcNo_Identification_RQ = NULL

    -- Déterminer les informations du paiement s'il y a un paiement
    IF @mMontant_Total_Paiement > 0
        BEGIN
            SET @dtDate_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,49,8), 'D', NULL, NULL) AS DATETIME)
            SET @iNumero_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,57,8), '9', NULL, 0) AS INT)
            SET @vcInstitution_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,65,4),'X',4,NULL) AS VARCHAR(4))
            SET @vcTransit_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,69,5),'X',5,NULL) AS VARCHAR(5))
            SET @vcCompte_Paiement = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,74,12),'X',12,NULL) AS VARCHAR(12))
        END

    IF @mMontant_Total_A_Payer > 0
        BEGIN
            IF @dtDate_Paiement IS NULL
                SET @dtDate_Paiement = @dtDate_Production_Paiement

            SET @iNumero_Paiement = NULL
            SET @vcInstitution_Paiement = NULL
            SET @vcTransit_Paiement = NULL
            SET @vcCompte_Paiement = NULL
        END

    IF @mMontant_Total_A_Payer = 0
        SET @mMontant_Total_A_Payer = NULL

    -- Retenir les informations pour le courriel
    SET @dtDate_Paiement_Courriel = @dtDate_Paiement
    SET @mMontant_Total_A_Payer_Courriel = ISNULL(@mMontant_Total_A_Payer,0)
    SET @mMontant_Total_Paiement_Courriel = @mMontant_Total_Paiement

    -- Mettre à jour le fichier
    UPDATE tblIQEE_Fichiers
    SET mMontant_Total_Paiement = @mMontant_Total_Paiement,
        mMontant_Total_A_Payer = @mMontant_Total_A_Payer,
        iNumero_Paiement = @iNumero_Paiement,
        dtDate_Production_Paiement = @dtDate_Production_Paiement,
        dtDate_Paiement = @dtDate_Paiement,
        vcInstitution_Paiement = @vcInstitution_Paiement,
        vcTransit_Paiement = @vcTransit_Paiement,
        vcCompte_Paiement = @vcCompte_Paiement,
        vcNo_Identification_RQ = @vcNo_Identification_RQ
    WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

    -----------------------------------------------------------------------------
    -- Traiter les nouvelles détermination du Ministre (type d'enregistrement 32)
    -----------------------------------------------------------------------------

    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierNOU          - '+
            'Traiter les nouvelles détermination du Ministre (type d''enregistrement 32).')

    -- Trouver les types d'enregistrement 32 (nouvelles détermination du Ministre)
    DECLARE curType32 CURSOR LOCAL FAST_FORWARD FOR
        SELECT cLigne
        FROM tblIQEE_LignesFichier LF
        WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE
          AND SUBSTRING(LF.cLigne,1,2) = '32'

    OPEN curType32
    FETCH NEXT FROM curType32 INTO @cLigne
    WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Lire les informations de la transaction
            SET @vcNo_Convention = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,17,15),'X',15,NULL) AS VARCHAR(15))
            SET @bIndicateur_Cession = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,228,1), '9', NULL, 0) AS BIT)
            SET @vcIdTransaction = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,281,15), 'X', 15, NULL) AS VARCHAR(15))

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
                                  AND D.tiCode_Version = 2
                                  AND D.cStatut_Reponse = 'A'

                                IF @iNB_Transactions1 = 1
                                    SET @cCode_Statut = 'A'
                                ELSE
                                    BEGIN
                                        SELECT @iNB_Transactions1 = COUNT(*)
                                        FROM tblIQEE_Demandes D
                                             JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                                    AND F.bFichier_Test = 0
                                        WHERE D.vcNo_Convention = @vcNo_Convention
                                          AND D.siAnnee_Fiscale = @siAnnee_Fiscale
                                          AND D.tiCode_Version = 2
                                          AND D.cStatut_Reponse = 'D'

                                        IF @iNB_Transactions1 = 1
                                            SET @cCode_Statut = 'D'
                                    END

                                SELECT @iNB_Transactions2 = COUNT(*)
                                FROM tblIQEE_Demandes D
                                     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                            AND F.bFichier_Test = 0
                                WHERE D.vcNo_Convention = @vcNo_Convention
                                  AND D.siAnnee_Fiscale = @siAnnee_Fiscale
                                  AND D.tiCode_Version = 2
                                  AND D.cStatut_Reponse = 'R'

                                IF @iNB_Transactions2 = 1
                                    SET @cCode_Statut = 'R'

                                IF @iNB_Transactions1 + @iNB_Transactions2 > 1
                                    BEGIN
                                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                                        VALUES ('2',10,'       Erreur: Ne peux pas déterminer une seule transaction de reprise d''origine'+
                                                       ' d''une réponse.')
                                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                                        VALUES ('2',10,'              #Convention: '+ISNULL(@vcNo_Convention,''))

                                        CLOSE curType32
                                        DEALLOCATE curType32

                                        GOTO ERREUR_TRAITEMENT
                                    END

                                IF @iNB_Transactions1 + @iNB_Transactions2 = 0
                                    BEGIN
                                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                                        VALUES ('2',10,'       Erreur: Ne peux pas déterminer une transaction de reprise d''origine'+
                                                       ' pour une réponse.')
                                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                                        VALUES ('2',10,'              #Convention: '+ISNULL(@vcNo_Convention,''))

                                        CLOSE curType32
                                        DEALLOCATE curType32

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
                                  AND D.tiCode_Version = 2
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

                    -- Mettre à jour le statut de la transaction de demande de reprise d'origine comme ayant reçu une réponse
                    IF @cCode_Statut = 'A'
                        UPDATE tblIQEE_Demandes
                        SET cStatut_Reponse = 'R'
                        WHERE iID_Demande_IQEE = @iID_Demande_IQEE
                    
                    IF @cCode_Statut = 'D'
                        UPDATE tblIQEE_Demandes
                        SET cStatut_Reponse = 'T'
                        WHERE iID_Demande_IQEE = @iID_Demande_IQEE

                    -- Trouver la transaction d'annulation et la transaction à l'origine de l'annulation
                    SELECT TOP 1 @iID_Enregistrement_Annulation = A.iID_Enregistrement_Annulation,
                                 @iID_Enregistrement_Origine = A.iID_Enregistrement_Demande_Annulation
                    FROM tblIQEE_Annulations A
                         JOIN tblIQEE_TypesEnregistrement TE ON TE.cCode_Type_Enregistrement = '02'
                    WHERE A.iID_Enregistrement_Reprise = @iID_Demande_IQEE

                    -- Mettre à jour le statut de la transaction d'annulation comme ayant reçu une réponse
                    UPDATE tblIQEE_Demandes
                    SET cStatut_Reponse = 'R'
                    WHERE iID_Demande_IQEE = @iID_Enregistrement_Annulation

                    -- Mettre à jour le statut de la transaction d'origine annulée comme ayant reçu une confirmation de la demande d'annulation
                    UPDATE tblIQEE_Demandes
                    SET cStatut_Reponse = 'T'
                    WHERE iID_Demande_IQEE = @iID_Enregistrement_Origine
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

                            CLOSE curType32
                            DEALLOCATE curType32

                            GOTO ERREUR_TRAITEMENT
                        END
                END

            -- Traiter les montants du crédit de base précédent
            SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,99,9), '9', NULL, 2) AS MONEY)

            IF @mMontant > 0 
                BEGIN
                    -- Trouver l'identifiant du type de réponse
                    SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                    FROM tblIQEE_TypesReponse TR
                    WHERE TR.vcCode = 'CBP'

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

            -- Traiter les montants de majoration précédente
            SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,108,9), '9', NULL, 2) AS MONEY)

            IF @mMontant > 0 
                BEGIN
                    -- Trouver l'identifiant du type de réponse
                    SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                    FROM tblIQEE_TypesReponse TR
                    WHERE TR.vcCode = 'MAP'

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

            -- Traiter les montants d'intérêts précédents
            SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,117,9), '9', NULL, 2) AS MONEY)

            IF @mMontant <> 0 
                BEGIN
                    -- Trouver l'identifiant du type de réponse
                    SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                    FROM tblIQEE_TypesReponse TR
                    WHERE TR.vcCode = 'INP'

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

            -- Traiter les montants de cotisation donnant droit à l'IQÉÉ précédent
            SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,126,9), '9', NULL, 2) AS MONEY)

            IF @mMontant > 0 
                BEGIN
                    -- Trouver l'identifiant du type de réponse
                    SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                    FROM tblIQEE_TypesReponse TR
                    WHERE TR.vcCode = 'MCP'

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

            -- Traiter le code de nouvelle justification globale 1
            SET @cCode = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,135,2), 'A', 2, NULL) AS CHAR(2))

            IF @cCode IS NOT NULL AND @cCode <> ''
                BEGIN
                    -- Trouver l'identifiant de la justification RQ
                    SELECT @tiID_Justification_RQ = J.tiID_Justification_RQ
                    FROM tblIQEE_JustificationsRQ J
                    WHERE J.cCode = @cCode

                    -- Trouver l'identifiant du type de réponse
                    SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                    FROM tblIQEE_TypesReponse TR
                    WHERE TR.vcCode = 'NJ1'

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

            -- Traiter le code de nouvelle justification globale 2
            SET @cCode = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,137,2), 'A', 2, NULL) AS CHAR(2))

            IF @cCode IS NOT NULL AND @cCode <> ''
                BEGIN
                    -- Trouver l'identifiant de la justification RQ
                    SELECT @tiID_Justification_RQ = J.tiID_Justification_RQ
                    FROM tblIQEE_JustificationsRQ J
                    WHERE J.cCode = @cCode

                    -- Trouver l'identifiant du type de réponse
                    SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                    FROM tblIQEE_TypesReponse TR
                    WHERE TR.vcCode = 'NJ2'

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

            -- Traiter le nouveau crédit de base
            SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,139,9), '9', NULL, 2) AS MONEY)
            SET @cCode = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,148,2), 'A', 2, NULL) AS CHAR(2))
            SET @bInd_Partage = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,150,1), '9', NULL, 0) AS BIT)

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
                    WHERE TR.vcCode = 'NCB'

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

            -- Traiter la nouvelle majoration
            SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,151,9), '9', NULL, 2) AS MONEY)
            SET @cCode = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,160,2), 'A', 2, NULL) AS CHAR(2))
            SET @bInd_Partage = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,164,1), '9', NULL, 0) AS BIT)

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
                    WHERE TR.vcCode = 'NMA'

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

            -- Traiter le code du nouvel explicatif de la majoration
            SET @cCode = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,162,2), 'A', 2, NULL) AS CHAR(2))

            IF @cCode IS NOT NULL AND @cCode <> ''
                BEGIN
                    -- Trouver l'identifiant de la justification RQ
                    SELECT @tiID_Justification_RQ = J.tiID_Justification_RQ
                    FROM tblIQEE_JustificationsRQ J
                    WHERE J.cCode = @cCode

                    -- Trouver l'identifiant du type de réponse
                    SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                    FROM tblIQEE_TypesReponse TR
                    WHERE TR.vcCode = 'NEM'

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

            -- Traiter les nouveaux montants de cotisation donnant droit à l'IQÉÉ
            SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,165,9), '9', NULL, 2) AS MONEY)

            IF @mMontant > 0 
                BEGIN
                    -- Trouver l'identifiant du type de réponse
                    SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                    FROM tblIQEE_TypesReponse TR
                    WHERE TR.vcCode = 'NMC'

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

            -- Traiter le crédit de base différentiel
            SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,174,9), '9', NULL, 2) AS MONEY)

            IF @mMontant <> 0 
                BEGIN
                    -- Trouver l'identifiant du type de réponse
                    SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                    FROM tblIQEE_TypesReponse TR
                    WHERE TR.vcCode = 'CBD'

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

            -- Traiter la majoration différentielle
            SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,183,9), '9', NULL, 2) AS MONEY)

            IF @mMontant <> 0 
                BEGIN
                    -- Trouver l'identifiant du type de réponse
                    SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                    FROM tblIQEE_TypesReponse TR
                    WHERE TR.vcCode = 'MAD'

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

            -- Traiter les intérêts différentiels
            SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,192,9), '9', NULL, 2) AS MONEY)

            IF @mMontant <> 0 
                BEGIN
                    -- Trouver l'identifiant du type de réponse
                    SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                    FROM tblIQEE_TypesReponse TR
                    WHERE TR.vcCode = 'IND'

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

            -- Traiter le nouveau cumul IQÉÉ pour le bénéficiaire
            SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,201,9), '9', NULL, 2) AS MONEY)

            IF @mMontant > 0 
                BEGIN
                    -- Trouver l'identifiant du type de réponse
                    SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                    FROM tblIQEE_TypesReponse TR
                    WHERE TR.vcCode = 'NCI'

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

            -- Traiter le nouveau solde IQÉÉ
            SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,210,9), '9', NULL, 2) AS MONEY)

            IF @mMontant > 0 
                BEGIN
                    -- Trouver l'identifiant du type de réponse
                    SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                    FROM tblIQEE_TypesReponse TR
                    WHERE TR.vcCode = 'NSI'

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

            -- Traiter le nouveau solde des cotisations ayant donné droit à l'IQÉÉ
            SET @mMontant = CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(@cLigne,219,9), '9', NULL, 2) AS MONEY)

            IF @mMontant > 0 
                BEGIN
                    -- Trouver l'identifiant du type de réponse
                    SELECT @tiID_Type_Reponse = tiID_Type_Reponse
                    FROM tblIQEE_TypesReponse TR
                    WHERE TR.vcCode = 'NSC'

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

            FETCH NEXT FROM curType32 INTO @cLigne
        END
    CLOSE curType32
    DEALLOCATE curType32

    ----------------------------------------------------------------------------------------------------------------------
    -- Valider que les montants de l'enregistrement 31 (sommaire du traitement) équivaut à la somme des réponses importées
    ----------------------------------------------------------------------------------------------------------------------

    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierNOU          - '+
            'Valider montants sommaire avec somme des réponses importées.')

    CREATE TABLE #tblIQEE_ReponsesImportees
        (iID_Convention INT,
         mMontant MONEY)

    INSERT INTO #tblIQEE_ReponsesImportees
        (iID_Convention,mMontant)
    SELECT RD.iID_Convention, ISNULL(SUM(ISNULL(RD.mMontant,0)),0)*-1
    FROM tblIQEE_ReponsesDemande RD
         JOIN tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
                                     AND TR.vcCode IN ('CBD','MAD','IND')
    WHERE RD.iID_Fichier_IQEE = @iID_Fichier_IQEE
    GROUP BY RD.iID_Convention

    SELECT @mMontant_Total_Paiement_Importe = ISNULL(SUM(RI.mMontant),0)
    FROM #tblIQEE_ReponsesImportees RI
    WHERE RI.mMontant >= 0

    SELECT @mMontant_Total_A_Payer_Importe = ISNULL(SUM(RI.mMontant),0)*-1
    FROM #tblIQEE_ReponsesImportees RI
    WHERE RI.mMontant < 0

    DROP TABLE #tblIQEE_ReponsesImportees

    IF @mMontant_Total_Paiement <> @mMontant_Total_Paiement_Importe OR
       ISNULL(@mMontant_Total_A_Payer,0) <> @mMontant_Total_A_Payer_Importe
        BEGIN
            IF @mMontant_Total_Paiement <> @mMontant_Total_Paiement_Importe
                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                VALUES ('2',10,'       Erreur: Le montant total du paiement des réponses importées ('+
                                dbo.fn_Mo_FloatToStr(@mMontant_Total_Paiement_Importe,@cID_Langue,2,1)+
                                ') ne correspond pas au montant de'+
                               ' l''enregistrement 31 (sommaire du traitement) ('+dbo.fn_Mo_FloatToStr(@mMontant_Total_Paiement,@cID_Langue,2,1)+').')

            IF ISNULL(@mMontant_Total_A_Payer,0) <> @mMontant_Total_A_Payer_Importe
                INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                VALUES ('2',10,'       Erreur: Le montant total à payer des réponses importées ('+
                                dbo.fn_Mo_FloatToStr(@mMontant_Total_A_Payer_Importe,@cID_Langue,2,1)+
                                ') ne correspond pas au montant de'+
                               ' l''enregistrement 31 (sommaire du traitement) ('+dbo.fn_Mo_FloatToStr(ISNULL(@mMontant_Total_A_Payer,0),@cID_Langue,2,1)+').')

--TODO: Remettre en erreur lorsque RQ aura corriger son problème
--            GOTO ERREUR_TRAITEMENT
        END

    GOTO FIN_TRAITEMENT

    ERREUR_TRAITEMENT:
        SET @bInd_Erreur = 1

    FIN_TRAITEMENT:
END
