/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service :   psIQEE_CreerTransactions03
Nom du service  :   Créer les transactions de type 03 - Remplacement de bénéficiaire 
But             :   Sélectionner, valider et créer les transactions de type 03 – Remplacement de bénéficiaire, dans
                    un nouveau fichier de transactions de l’IQÉÉ.
Facette         :   IQÉÉ

Paramètres d’entrée :
        Paramètre               Description
        --------------------    -----------------------------------------------------------------
        iID_Fichier_IQEE        Identifiant du nouveau fichier de transactions dans lequel les transactions 03 doivent être créées.
        bFichiers_Test          Indicateur si les fichiers test doivent être tenue en compte dans la production du fichier.  
                                Normalement ce n’est pas le cas, mais pour fins d’essais et de simulations il est possible de tenir compte
                                des fichiers tests comme des fichiers de production.  S’il est absent, les fichiers test ne sont pas considérés.
        iID_Convention          Identifiant unique de la convention pour laquelle la création des
                                fichiers est demandée.  La convention doit exister.
        bArretPremiereErreur    Indicateur si le traitement doit s’arrêter après le premier message d’erreur.
                                S’il est absent, les validations n’arrêtent pas à la première erreur.
        cCode_Portee            Code permettant de définir la portée des validations.
                                    « T » = Toutes les validations
                                    « A » = Toutes les validations excepter les avertissements (Erreurs
                                            seulement)
                                    « I » = Uniquement les validations sur lesquelles il est possible
                                            d’intervenir afin de les corriger
                                    S’il est absent, toutes les validations sont considérées.
        bit_CasSpecial          Indicateur pour permettre la résolution de cas spéciaux sur des T02 dont le délai de traitement est dépassé. 

Exemple d’appel :   
        exec dbo.psIQEE_CreerTransactions03 10, 0, NULL, 0, 'T', 0

Paramètres de sortie :
        Champ               Description
        ------------        ------------------------------------------
        iCode_Retour        = 0 : Exécution terminée normalement
                            < 0 : Erreur de traitement

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    --------------------------------------------------------------------------
    2009-02-02  Éric Deshaies           Création du service                            
    2012-05-11  Stéphane Barbeau        Désactivation validations 102 et 130
                                        Désactivation de champs facultatifs par RQ
                                        Traitement de conversion des valeurs de la table Un_RelationshipType                                                        
    2012-05-14  Stéphane Barbeau        Ajustement des appels des fonctions fnIQEE_RemplacementBeneficiaire et fntGENE_ObtenirElementsAdresse                                                    
    2012-05-22  Eric Michaud            Relocaliser le code et le mettre dans psIQEE_CreerTransactions03 pour Un_RelationshipType 
    2012-08-14  Stéphane Barbeau        Remplacement de la validation #102 par clause supplémentaire pour Select curRemplacement et mise par défaut du statut 'R' dans la commande INSERT.
    2012-08-21  Dominique Pothier       Ajout de la validation 132
    2012-08-21  Stéphane Barbeau        Désactivation validation 110 et traitement sur @vcNo_Civique_Beneficiaire
    2012-08-23  Stéphane Barbeau        Ajout traitement conditionnel de @bInd_Remplacement_Reconnu
    2012-08-27  Stéphane Barbeau        Désactivation validation 111 et traitement sur @vcRue_Beneficiaire
    2013-08-01  Stéphane Barbeau        Désactivation validation 103.
    2013-08-15  Stéphane Barbeau        Ajout validation 135.  Désactivation validation 104.
    2013-10-04  Stéphane Barbeau        curRemplacement: retrait de la condition NOT EXISTS et remplacement par clause AND CB.iID_Changement_Beneficiaire NOT IN 
    2013-10-17  Stéphane Barbeau        curRemplacement: Clause WHERE; Ajustement remplacement validation 102 et ajout condition d'exclusion des T03 avec erreur RQ 3028.
    2013-10-18  Stéphane Barbeau        Réduction des Appels à psIQEE_AjouterRejet pour le rejet générique: condition IF @iResultat <= 0 changée pour IF @iResultat <> 0
                                        Raison: Unless documented otherwise, all system stored procedures return a value of 0. This indicates success and a nonzero value indicates failure.
    2013-11-06  Stéphane Barbeau        Requête curRemplacement: Ajout du paramètre CB.dtDate_Changement_Beneficiaire dans la fonction fnIQEE_ConventionConnueRQ.
    2013-12-09  Stéphane Barbeau        Ajustement rejet 135 pour exclure toute T03 ayant plusieurs changements de bénéficiaires faits le même jour dans l'année.
    2013-12-13  Stéphane Barbeau        Requête -- S'il n'y a pas d'erreur, créer la transaction 03: Retrait condition --AND R.iID_Lien_Vers_Erreur_1 = @iID_Changement_Beneficiaire
    2014-07-07  Stéphane Barbeau        Mise a niveau selon nouveau module des adresses: remplacer fnGENE_AdresseEnDate par fntGENE_ObtenirAdresseEnDate
    2014-07-29  Stéphane Barbeau        Performance: retrait de l'utilisation de fntGENE_ObtenirAdresseEnDate et requêtes directes sur les tables tblGENE_Adresse et tblGENE_AdresseHistorique
                                        Traitement des valeurs @cCode_Pays et @cCode_Pays_Beneficiaire.
    2014-08-13  Stéphane Barbeau        Ajout de la validation #136 et paramètre @bit_CasSpecial.    
    2014-09-19  Stéphane Barbeau        Traitement des adresses ayant des cases postales et des routes rurales séparées selon les nouvelles tables les tables tblGENE_Adresse et tblGENE_AdresseHistorique.
    2014-09-24  Stéphane Barbeau        Adresses: Numéro civique et nom de la rue, validations 137 et 138 ajoutées.  Retrait de la logiques des validations désactivées 110 et 111.
    2014-11-18  Stéphane Barbeau        Ajustement attribution @vcCasePostaleRouteRurale_Beneficiaire avec requête tblGENE_Adresse
                                        Nouvelle requête pour @iID_Adresse_Beneficiaire_Date_Remplacement avec table tblGENE_AdresseHistorique
    2015-09-11  Stéphane Barbeau        Réactivation de déclaration du numéro d'appartement du nouveau bénéficiaire.                                                            
                                        Résolution d'un problème de NULL avec @vcRue_Beneficiaire.
    2016-01-08  Steeve Picard           Correction au niveau des validations pour tenir compte de la Convention_ID
    2016-02-02  Steeve Picard           Optimisation en remplaçant les curseurs SQL par des boucles WHILE
    2016-02-19  Steeve Picard           Retrait des 2 derniers paramètres de « fnIQEE_ConventionConnueRQ »
    2016-06-13  Steeve Picard           Correction dans le WHERE qui joint les tables «tblIQEE_RemplacementsBeneficiaire» et «fntCONV_RechercherChangementsBeneficiaire»
    2016-11-25  Steeve Picard           Changement d'orientation de la valeur de retour de «fnIQEE_RemplacementBeneficiaireReconnu»
    2017-02-01  Steeve Picard           Optimisation en traitant par batch et non une convention à la fois
    2017-05-25  Steeve Picard           Modification pour les indicateurs «bLien_Frere_Soeur, bLien_Sang_Nouveau_Beneficiaire_Souscripteur_Initial» dont la condition «moins de 21 ans» est manquante dans le NID d'IQÉÉ
    2017-06-07  Steeve Picard           Légère modification dans la recherche des cas
    2017-06-09  Steeve Picard           Ajout du paramètre « @tiCode_Version = 0 » pour passer la valeur « 2 » lors d'une annulation/reprise
    2017-07-11  Steeve Picard           Élimination du paramètre « iID_Convention » pour toujours utiliser la table « #TB_ListeConvention »
    2017-08-22  Steeve Picard           Utilisation du NAS courant du bénéficiaire au lieu de celui dans l'historique
    2017-10-05  Steeve Picard           Ajout de la validation pour rejeter les conventions ayant été impliqué dans un «RIO» antérieurement
                                        Ajout de la validation pour rejeter les conventions ayant une des opérations TRI/RIM/OUT antérieurement
    2017-11-07  Steeve Picard           Réajustement pour valider tous les changements bénéficiaires
    2017-11-30  Steeve Picard           Recherche les premières adresses connues dans le cas d'une vente anti-datée
                                        Recherche les dernières adresses antérieures dans le cas où il n'y a plus d'adresse active
    2017-12-20  Steeve Picard           Traiter les cas où il a eu plus d''un changement bénéficiaire au contrat
    2018-01-04  Steeve Picard           Validation de base si @cCode_Portee = '' pour l'estimation du rapport à recevoir
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments «tblIQEE_RemplacementsBeneficiaire»
    2018-02-26  Steeve Picard           Empêcher que la «dtFinCotisation» soit plus grande que la dernière fin de mois
    2018-03-15  Steeve Picard           Bloquer la déclaration si elle n'est pas reconnu et qu'elle a un PAE
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
    2018-09-19  Steeve Picard           Ajout du champ «iID_SousType» à la table «tblIQEE_CasSpeciaux» pour pouvoir filtrer
    2018-09-20  Steeve Picard           Ajout de la vérification que l'opération «AVC» ait été déclarée préalablement au même titre que les «PAE»
    2018-11-27  Steeve Picard           Ne bloquer la déclaration que si elle a de l'IQÉÉ dans le PAE antérieur et ignorer les opérations «AVC» en fait de compte
    2018-12-06  Steeve Picard           Utilisation des nouvelles fonctions «fntIQEE_Transfert_NonDeclare & fntIQEE_PaiementBeneficiaire_NonDeclare»
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_CreerTransactions03]
(
    @iID_Fichier_IQEE INT, 
    @siAnnee_Fiscale SMALLINT, 
    @bArretPremiereErreur BIT, 
    @cCode_Portee CHAR(1), 
    @bit_CasSpecial BIT,
    @tiCode_Version TINYINT = 0
)
AS
BEGIN
    SET NOCOUNT ON

    PRINT ''
    PRINT 'Déclaration des remplacements de bénéficiaire au contrat (T03) pour ' + STR(@siAnnee_Fiscale, 4)
    PRINT '------------------------------------------------------------------------'
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions_03 started'

    IF Object_ID('tempDB..#TB_ListeConvention') IS NULL
        RAISERROR ('La table « #TB_ListeConvention (RowNo INT Identity(1,1), ConventionID int, ConventionNo varchar(20) » est abesente ', 16, 1)

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Identifie le(s) convention(s)'
    DECLARE @iCount int = (SELECT Count(*) FROM #TB_ListeConvention)
    IF @iCount > 0
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - ' + LTrim(Str(@iCount)) + ' conventions à génèrées'

    DECLARE @StartTimer datetime = GetDate(),       @MaxRow INT = 0,
            @QueryTimer datetime,                   @ElapseTime datetime, 
            @IsDebug bit = dbo.fn_IsDebug()        


    --  Déclaration des variables
    BEGIN 
        DECLARE 
            @tiID_TypeEnregistrement TINYINT,       @iID_SousTypeEnregistrement INT,
            @dtDebutCotisation DATE,                @dtMinCotisation DATE = '2007-02-21',
            @dtFinCotisation DATE,                  @dtMaxCotisation DATE = DATEADD(DAY, -DAY(GETDATE()), GETDATE()),
            @iAgeLimiteRemplacementReconnu int
    
        -- Sélectionner dates applicables aux transactions
        SELECT @dtDebutCotisation = Str(@siAnnee_Fiscale, 4) + '-01-01 00:00:00',
                @dtFinCotisation = STR(@siAnnee_Fiscale, 4) + '-12-31 23:59:59'

        IF @dtDebutCotisation < @dtMinCotisation
            SET @dtDebutCotisation = @dtMinCotisation

        IF @dtFinCotisation > @dtMaxCotisation
            SET @dtFinCotisation = @dtMaxCotisation
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupère les IDs du type & sous-type pour ce type d''enregistrement'
    SELECT 
        @tiID_TypeEnregistrement = tiID_Type_Enregistrement, 
        @iID_SousTypeEnregistrement = iID_Sous_Type
    FROM
        dbo.vwIQEE_Enregistrement_TypeEtSousType 
    WHERE
        cCode_Type_Enregistrement = '03'
        AND cCode_Sous_Type IS NULL

    DECLARE @TB_FichierIQEE TABLE (
                iID_Fichier_IQEE INT, 
                --siAnnee_Fiscale INT, 
                dtDate_Creation DATE, 
                dtDate_Paiement DATE
            )

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupère les fichiers IQEE'
    INSERT INTO @TB_FichierIQEE 
        (iID_Fichier_IQEE, /*siAnnee_Fiscale,*/ dtDate_Creation, dtDate_Paiement)
    SELECT DISTINCT 
        iID_Fichier_IQEE, /*siAnnee_Fiscale,*/ dtDate_Creation, dtDate_Paiement
    FROM 
        dbo.tblIQEE_Fichiers F
        JOIN dbo.tblIQEE_TypesFichier T ON T.tiID_Type_Fichier = F.tiID_Type_Fichier
    WHERE
        0 = 0 --T.bTeleversable_RQ <> 0
        AND (
                (bFichier_Test = 0  AND bInd_Simulation = 0)
                OR iID_Fichier_IQEE = @iID_Fichier_IQEE
            )
        --(@bFichiers_Test = 1 OR bFichier_Test = 0 OR iID_Fichier_IQEE = @iID_Fichier_IQEE)
        --AND (bInd_Simulation = 0 OR iID_Fichier_IQEE = @iID_Fichier_IQEE)

    ------------------------------------------------------------------------------------------------------
    -- Identifier et sélectionner les remplacements de bénéficiaire parmis les changements de bénéficiaire
    ------------------------------------------------------------------------------------------------------
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Identifie les conventions devant déclarer une T03'
    BEGIN
        IF OBJECT_ID('tempdb..#TB_Convention_03') IS NOT NULL
            DROP TABLE #TB_Convention_03

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupère les conventions ayant un changement bénéficiaire au contrat'
        SET @QueryTimer = GetDate()
    
        SET ROWCOUNT @MaxRow

        -- Sélectionner les changements de bénéficiaire de l'année fiscale dans les conventions connues de RQ
        ; WITH CTE_Convention AS (
            SELECT DISTINCT
                C.ConventionID, C.ConventionNo, C.SubscriberID, C.IdSouscripteurOriginal,
                CB.iID_Changement_Beneficiaire, CB.dtDate_Changement_Beneficiaire, CB.iID_Nouveau_Beneficiaire, CB.iID_Ancien_Beneficiaire,
                CB.bLien_Frere_Soeur_Avec_Ancien_Beneficiaire, CB.bLien_Sang_Avec_Souscripteur_Initial, CB.tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire
            FROM     
                dbo.Un_Convention C
                JOIN #TB_ListeConvention X ON X.ConventionID = C.ConventionID
                JOIN dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, NULL, NULL, NULL, @dtDebutCotisation, @dtFinCotisation, NULL, NULL, NULL, NULL, NULL, NULL, NULL) CB 
                     ON CB.iID_Convention = C.ConventionID
            WHERE 
                CB.vcCode_Raison <> 'INI'
                AND X.ConventionStateID <> 'FRM'
                AND ISNULL(X.dtReconnue_RQ, GETDATE()) < CB.dtDate_Changement_Beneficiaire
        )
        SELECT DISTINCT
            C.ConventionID, C.ConventionNo, C.SubscriberID, C.IdSouscripteurOriginal, 
            iID_Remplacement = C.iID_Changement_Beneficiaire, 
            dtRemplacement = C.dtDate_Changement_Beneficiaire, 
            iID_BeneficiaryNew = C.iID_Nouveau_Beneficiaire, 
            LienFraterie = C.bLien_Frere_Soeur_Avec_Ancien_Beneficiaire, 
            LienParente_SubscriberWithNew = RTS.tiCode_Equivalence_IQEE, 
            iID_BeneficiaryOld = C.iID_Ancien_Beneficiaire, 
            LienSang_WithFirstSubscriber = C.bLien_Sang_Avec_Souscripteur_Initial,
            bRemplacementReconnu = CAST(0 AS BIT)  -- Reconnu par défaut
        INTO
            #TB_Convention_03
        FROM     
            CTE_Convention C
            LEFT JOIN dbo.Un_RelationshipType RTS ON RTS.tiRelationshipTypeID = C.tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire
        WHERE
            -- Pour remplacer la règle de validation #102 puisque RQ n'envoie pas de réponse aux T03
            NOT EXISTS ( 
                SELECT * FROM tblIQEE_RemplacementsBeneficiaire RB JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = RB.iID_Fichier_IQEE
                WHERE RB.iID_Changement_Beneficiaire = C.iID_Changement_Beneficiaire 
                      AND RB.tiCode_Version IN (0, 2)
                      AND RB.cStatut_Reponse IN ('A','R','D')
            )
            ---- Exclure les changements de bénéficiaires dont des T03 ont été faites et qu'elles ont reçu des erreurs 3028 de RQ (Le bénéficiaire remplacé est inconnu de l’IQEE)
            --AND NOT EXISTS (
            --    SELECT * FROM tblIQEE_RemplacementsBeneficiaire RB
            --                  JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = RB.iID_Remplacement_Beneficiaire
            --    WHERE RB.iID_Changement_Beneficiaire = C.iID_Changement_Beneficiaire 
            --          AND E.siCode_Erreur = 3028
            --)

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer

        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime), 4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @iCount < 5
            SET @MaxRow = @iCount

        SET ROWCOUNT 0

        IF @iCount = 0
            RETURN

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Vérifies s''il y a eu plus d''un changement bénéficiaire au contrat'
        SET @QueryTimer = GetDate()
        SET @iCount = 0
        BEGIN
            DECLARE @iID_Convention INT = 0,
                    @dtRemplacement_New DATETIME,
                    @dtRemplacement_Old DATETIME,
                    @iID_Beneficiary_New INT,
                    @iID_Beneficiary_Old INT

            -- Recherche les conventions à vérifier
            SELECT ConventionID, dtPremierRemplacement = MIN(dtRemplacement)
              INTO #TB_Duplicata_03 
              FROM #TB_Convention_03
             GROUP BY ConventionID
            HAVING COUNT(*) > 1

            WHILE EXISTS(SELECT * FROM #TB_Duplicata_03 WHERE ConventionID > @iID_Convention)
            BEGIN
                SELECT @iID_Convention = MIN(ConventionID) --, @dtRemplacement_New = dtPremierRemplacement
                  FROM #TB_Duplicata_03
                 WHERE ConventionID > @iID_Convention
                 --ORDER BY ConventionID

                SELECT TOP 1 @dtRemplacement_Old = dtRemplacement, 
                             @iID_Beneficiary_Old = iID_BeneficiaryOld
                  FROM #TB_Convention_03
                 WHERE ConventionID = @iID_Convention
                 ORDER BY dtRemplacement

                WHILE EXISTS(SELECT * FROM #TB_Convention_03 WHERE ConventionID = @iID_Convention AND dtRemplacement > @dtRemplacement_Old)
                BEGIN
                    SELECT TOP 1 @dtRemplacement_New = dtRemplacement, 
                                 @iID_Beneficiary_New = iID_BeneficiaryNew
                      FROM #TB_Convention_03 C
                     WHERE ConventionID = @iID_Convention AND dtRemplacement > @dtRemplacement_Old
                     ORDER BY dtRemplacement  

                    IF @iID_Beneficiary_New = @iID_Beneficiary_Old
                    BEGIN
                        DELETE FROM #TB_Convention_03
                         WHERE ConventionID = @iID_Convention AND dtRemplacement IN (@dtRemplacement_New, @dtRemplacement_Old)

                        SET @iCount = @iCount + @@ROWCOUNT

                        SELECT TOP 1 @dtRemplacement_Old = dtRemplacement, 
                                     @iID_Beneficiary_Old = iID_BeneficiaryOld
                          FROM #TB_Convention_03
                         WHERE ConventionID = @iID_Convention AND dtRemplacement > @dtRemplacement_New
                         ORDER BY dtRemplacement  
                    END 
                    ELSE
                        SELECT @dtRemplacement_Old = @dtRemplacement_New, 
                               @iID_Beneficiary_Old = @iID_Beneficiary_New
                END 
            END 

            SET @ElapseTime = GetDate() - @QueryTimer
            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' duplicates removed (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime), 4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
        END 
    END

    IF NOT EXISTS(SELECT TOP 1 * FROM #TB_Convention_03)
       RETURN

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération les infos des bénéficiaires'
    BEGIN
        IF Object_ID('tempDB..#TB_Beneficiary_03') IS NOT NULL
            DROP TABLE #TB_Beneficiary_03
    
        SET @QueryTimer = GetDate()
        ;WITH CTE_Beneficiary as (
            SELECT DISTINCT
                iID_Beneficiary = H.HumanID, 
                C.iID_Remplacement, C.dtRemplacement,
                vcNAS = REPLACE(H.SocialNumber, ' ', ''), --REPLACE(N.SocialNumber, ' ', ''), 
                vcNom = LTRIM(H.LastName), 
                vcPrenom = LTRIM(H.FirstName), 
                dtNaissance = H.BirthDate, 
                cSexe = H.SexID
            FROM 
                #TB_Convention_03 C
                JOIN dbo.Mo_Human H ON H.HumanID = C.iID_BeneficiaryNew OR H.HumanID = C.iID_BeneficiaryOld
                --JOIN dbo.fntCONV_ObtenirNasParHumainEnDate(@dtFinCotisation) N ON N.HumanID = H.HumanID
        ),
        CTE_Adresse as (
            SELECT DISTINCT
                iID_Beneficiary,
                iID_Remplacement,
                iID_Adresse, 
                vcNumero_Civique, 
                vcUnite, 
                vcNom_Rue,
                vcInternationale1,
                iID_TypeBoite, 
                vcBoite, 
                vcVille, 
                vcProvince, 
                cID_Pays, vcPays,
                vcCodePostal, 
                bResidenceFaitQuebec
            FROM (
                SELECT  
                    B.iID_Beneficiary,
                    B.iID_Remplacement,
                    A.iID_Adresse, 
                    A.vcNumero_Civique, 
                    A.vcUnite, 
                    A.vcNom_Rue,
                    A.vcInternationale1,
                    A.iID_TypeBoite, 
                    A.vcBoite, 
                    A.vcVille, 
                    A.vcProvince, 
                    A.cID_Pays, A.vcPays,
                    A.vcCodePostal, 
                    A.bResidenceFaitQuebec,
                    Row_Num = Row_Number() OVER(PARTITION BY B.iID_Beneficiary, B.iID_Remplacement ORDER BY A.dtDate_Debut DESC)
                FROM
                    CTE_Beneficiary B
                    JOIN dbo.fntGENE_ObtenirAdressesEntre_PourTous(NULL, 1, @dtDebutCotisation, @dtFinCotisation, 0) A 
                         ON A.iID_Source = B.iID_Beneficiary And A.cType_Source = 'H'
                WHERE 
                    CAST(B.dtRemplacement AS DATE) BETWEEN A.dtDate_Debut And IsNull(DateAdd(day, -1, A.dtDate_Fin), '9999-12-31')
                ) X
            WHERE
                X.Row_Num = 1
        )
        SELECT 
            TB.iID_Beneficiary, TB.iID_Remplacement, TB.dtRemplacement,
            TB.vcNAS, TB.vcNom, TB.vcPrenom, TB.dtNaissance, TB.cSexe, 
            vcNomPrenom = dbo.fn_Mo_FormatHumanName(TB.vcNom, '', TB.vcPrenom, '', '', 0), 
            Age_31_Decembre = YEAR(@dtFinCotisation) - YEAR(TB.dtNaissance),
            A.iID_Adresse, 
            vcAdresse_Tmp = LTrim(RTrim(Coalesce(A.vcNom_Rue, A.vcInternationale1, ''))), 
            vcNoCivique = LTrim(RTrim(A.vcNumero_Civique)), 
            vcAppartement = LTrim(RTrim(A.vcUnite)), 
            vcNomRue = LTrim(RTrim(Coalesce(A.vcNom_Rue, A.vcInternationale1, ''))) +
                       CASE 
                           WHEN Len(ISNULL(A.vcBoite, '')) > 0 THEN 
                               CASE A.iID_TypeBoite 
                                   WHEN 1 THEN ' CP '
                                   WHEN 3 THEN ' RR '
                                   ELSE ''
                               END + A.vcBoite
                           ELSE ''
                       END, 
            A.iID_TypeBoite, 
            A.vcBoite, 
            A.vcVille, 
            vcProvince = CASE A.cID_Pays WHEN 'CAN' THEN A.vcProvince
                                         ELSE NULL
                         END, 
            cID_Pays = CASE A.cID_Pays WHEN 'CAN' THEN A.cID_Pays
                                       WHEN 'USA' THEN A.cID_Pays
                                       ELSE 'AUT'
                       END, 
            A.vcCodePostal, 
            bResidenceQuebec = A.bResidenceFaitQuebec, 
            vcAdresseLigne3 = CASE A.cID_Pays WHEN 'CAN' THEN NULL
                                              WHEN 'USA' THEN A.vcProvince
                                              ELSE A.vcPays
                              END
        INTO
            #TB_Beneficiary_03
        FROM 
            CTE_Beneficiary TB
            --JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = TB.iID_Beneficiary
            LEFT JOIN CTE_Adresse A ON A.iID_Beneficiary = TB.iID_Beneficiary And A.iID_Remplacement = TB.iID_Remplacement

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime), 4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
        
        IF EXISTS(SELECT TOP 1 * FROM #TB_Beneficiary_03 WHERE iID_Adresse IS NULL)
        BEGIN
            SET @QueryTimer = GetDate()
            PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération des adresses inexistantes fiscale des bénéficiaires pour cette année fiscale'

            UPDATE B SET
                iID_Adresse = A.iID_Adresse,
                vcAdresse_Tmp = LTrim(RTrim(Coalesce(A.vcNom_Rue, A.vcInternationale1, ''))),
                vcNoCivique = A.vcNumero_Civique,
                vcAppartement = A.vcUnite,
                vcNomRue = LTrim(RTrim(IsNull(A.vcNom_Rue, A.vcInternationale1))),
                iID_TypeBoite = A.iID_TypeBoite,
                vcBoite = A.vcBoite,
                vcVille = A.vcVille,
                vcProvince = LTrim(RTrim(CASE A.cID_Pays WHEN 'CAN' THEN A.vcProvince
                                                            ELSE NULL
                                            END)),
                cID_Pays = LTrim(RTrim(CASE A.cID_Pays WHEN 'CAN' THEN A.cID_Pays
                                                        WHEN 'USA' THEN A.cID_Pays
                                                        ELSE 'AUT'
                                        END)),
                vcCodePostal = LTrim(RTrim(IsNull(A.vcCodePostal, ''))),
                vcAdresseLigne3 = LTrim(RTrim(CASE A.cID_Pays WHEN 'CAN' THEN NULL
                                                                WHEN 'USA' THEN A.vcProvince
                                                                ELSE A.vcPays
                                                END))
            FROM 
                #TB_Beneficiary_03 B 
                JOIN dbo.fntGENE_ObtenirDerniereAdresseConnue(DEFAULT, 1, @dtFinCotisation, 0) A ON A.iID_Source = B.iID_Beneficiary
            WHERE
                B.iID_Adresse IS NULL 

            SET @iCount = @@ROWCOUNT
            SET @ElapseTime = GetDate() - @QueryTimer
            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées antérieurement (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

            SET @QueryTimer = GetDate()

            UPDATE B SET
                iID_Adresse = A.iID_Adresse,
                vcAdresse_Tmp = LTrim(RTrim(Coalesce(A.vcNom_Rue, A.vcInternationale1, ''))),
                vcNoCivique = A.vcNumero_Civique,
                vcAppartement = A.vcUnite,
                vcNomRue = LTrim(RTrim(IsNull(A.vcNom_Rue, A.vcInternationale1))),
                iID_TypeBoite = A.iID_TypeBoite,
                vcBoite = A.vcBoite,
                vcVille = A.vcVille,
                vcProvince = LTrim(RTrim(CASE A.cID_Pays WHEN 'CAN' THEN A.vcProvince
                                                            ELSE NULL
                                            END)),
                cID_Pays = LTrim(RTrim(CASE A.cID_Pays WHEN 'CAN' THEN A.cID_Pays
                                                        WHEN 'USA' THEN A.cID_Pays
                                                        ELSE 'AUT'
                                        END)),
                vcCodePostal = LTrim(RTrim(IsNull(A.vcCodePostal, ''))),
                vcAdresseLigne3 = LTrim(RTrim(CASE A.cID_Pays WHEN 'CAN' THEN NULL
                                                                WHEN 'USA' THEN A.vcProvince
                                                                ELSE A.vcPays
                                                END))
            FROM 
                #TB_Beneficiary_03 B 
                LEFT JOIN dbo.fntGENE_ObtenirAdressePremiereConnue(DEFAULT, 1, @dtFinCotisation, 0) A ON A.iID_Source = B.iID_Beneficiary
            WHERE
                B.iID_Adresse IS NULL 

            SET @iCount = @@ROWCOUNT
            SET @ElapseTime = GetDate() - @QueryTimer
            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées ultérieurement (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
        END

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Corrige le # civique & appartement des adresses de bénéficiaire ayant un «-»'
        SET @QueryTimer = GetDate()
        ;WITH CTE_Civique as (
            SELECT
                iID_Adresse, vcNomRue, iBlank = CharIndex(' ', vcNomRue, 1), 
                                       iDash = IsNull(CharIndex('-', vcNomRue, 1), 0)
            FROM
                #TB_Beneficiary_03
            WHERE
                Len(IsNull(vcNoCivique, '')) = 0
                AND Len(IsNull(vcNomRue, '')) > 0
                AND CharIndex(' ', vcNomRue, 1) > 0
        ),
        CTE_Addresse as (
            SELECT
                iID_Adresse, 
                NoCivique = LTrim(RTrim(Replace(CASE WHEN iDash Between 1 And iBlank 
                                                     THEN SubString(vcNomRue, iDash + 1, iBlank - iDash -1) 
                                                     ELSE Left(vcNomRue, iBlank - 1) 
                                                END, ',', ''))),
                NomRue = LTrim(RTrim(SubString(vcNomRue, iblank, Len(vcNomRue) - iBlank + 1))),
                NoApp = LTrim(RTrim(CASE WHEN iDash Between 1 And iBlank 
                                         THEN Left(vcNomRue, iDash - 1)
                                         ELSE NULL 
                                    END))
            FROM
                CTE_Civique
        )
        UPDATE TB SET
            vcNoCivique = Left(CASE WHEN IsNumeric(Left(A.NoCivique,1)) = 0 AND IsNumeric(Left(A.NoApp, 1)) <> 0 THEN A.NoApp 
                                    ELSE A.NoCivique 
                               END, 10),
            vcAppartement = Left(CASE WHEN IsNumeric(Left(A.NoCivique,1)) = 0 AND IsNumeric(Left(A.NoApp, 1)) <> 0 THEN A.NoCivique 
                                      ELSE A.NoApp 
                                 END, 10),
            vcNomRue = LTrim(A.NomRue)
        FROM
            #TB_Beneficiary_03 TB 
            JOIN CTE_Addresse A ON A.iID_Adresse = TB.iID_Adresse
        WHERE 
            Len(IsNull(TB.vcNoCivique, '')) = 0
            AND Len(A.NoCivique) > 0
            --AND (IsNumeric(A.NoCivique) <> 0 OR IsNumeric(A.NoApp) <> 0)

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' corrigées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Corrige le # civique & appartement des adresses de bénéficiaire n''ayant pas de «-»'
        SET @QueryTimer = GetDate()
        UPDATE #TB_Beneficiary_03 SET
            vcNoCivique = Left(vcNoCivique, Len(vcNoCivique)-1),
            vcAppartement = Right(vcNoCivique, 1)
        WHERE 
            IsNumeric(vcNoCivique) = 0
            AND vcNoCivique Like '%[0-9][a-z,A-Z]'

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' corrigées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            SELECT * from #TB_Beneficiary_03
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Identification des remplacements qui sont reconnus selon l''âge des bénéficiaires'
    BEGIN 
        SET @iAgeLimiteRemplacementReconnu = CAST(dbo.fnGENE_ObtenirParametre('IQEE_LIMITE_AGE_REMPLACEMENT_BENEF_RECONNU', @dtDebutCotisation, NULL, NULL, NULL, NULL, NULL) AS INT)

        SET @QueryTimer = GetDate()
        UPDATE C SET 
            bRemplacementReconnu = 1
        FROM
            #TB_Convention_03 C
            JOIN #TB_Beneficiary_03 New ON New.iID_Beneficiary = C.iID_BeneficiaryNew
            JOIN #TB_Beneficiary_03 Old ON Old.iID_Beneficiary = C.iID_BeneficiaryOld
        WHERE
            --dbo.fn_Mo_Age(New.dtNaissance, C.dtRemplacement) < @iAgeLimiteRemplacementReconnu
            DATEADD(YEAR, @iAgeLimiteRemplacementReconnu, New.dtNaissance) > DATEADD(MONTH, 1, DATEADD(DAY, -DAY(C.dtRemplacement), C.dtRemplacement))
            AND ( C.LienFraterie <> 0
                  OR ( C.LienSang_WithFirstSubscriber <> 0
                       --AND dbo.fn_Mo_Age(New.dtNaissance, C.dtRemplacement) < @iAgeLimiteRemplacementReconnu
                       AND DATEADD(YEAR, @iAgeLimiteRemplacementReconnu, Old.dtNaissance) > DATEADD(MONTH, 1, DATEADD(DAY, -DAY(C.dtRemplacement), C.dtRemplacement))
                  )
            )
        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' identifiés (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime), 4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
    END
    
    -------------------------------------------------------------------------------------
    -- Valider les conventions et conserver les raisons de rejet en vertu des validations
    -------------------------------------------------------------------------------------
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Validation des conventions selon les critères RQ'
    BEGIN
        DECLARE
            @iID_Validation INT,                      @iCode_Validation INT, 
            @vcDescription VARCHAR(300),              @cType CHAR(1), 
            @iCountRejets INT

        IF OBJECT_ID('tempdb..#TB_Rejet_03') IS NULL
            CREATE TABLE #TB_Rejets_03 (
                    iID_Convention int NOT NULL, 
                    iID_Validation int NOT NULL, 
                    vcDescription varchar(300) NOT NULL, 
                    vcValeur_Reference varchar(200) NULL, 
                    vcValeur_Erreur varchar(200) NULL, 
                    iID_Lien_Vers_Erreur_1 int NULL, 
                    iID_Lien_Vers_Erreur_2 int NULL, 
                    iID_Lien_Vers_Erreur_3 int NULL
            )
        ELSE
            TRUNCATE TABLE #TB_Rejet_03

        -- Sélectionner les validations à faire pour le sous type de transaction
        IF OBJECT_ID('tempdb..#TB_Validation_03') IS NOT NULL
            DROP TABLE #TB_Validation_03

        -- SELECT * FROM tblIQEE_Validations WHERE tiID_Type_Enregistrement = 2 ORDER BY bActif desc, iOrdre_Presentation
        SELECT 
            V.iOrdre_Presentation, V.iID_Validation, V.iCode_Validation, V.cType, V.vcDescription_Parametrable as vcDescription
        INTO
            #TB_Validation_03
        FROM
            tblIQEE_Validations V
        WHERE 
            V.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
            AND IsNull(V.iID_Sous_Type, 0) = IsNull(@iID_SousTypeEnregistrement, 0)
            AND V.bValidation_Speciale = 0
            AND V.bActif = 1
            AND (   @cCode_Portee = 'T'
                    OR (@cCode_Portee = 'A' AND V.cType = 'E')
                    OR (@cCode_Portee = 'I' AND V.bCorrection_Possible = 1)
                    OR (ISNULL(@cCode_Portee, '') = '' AND V.cType = 'E' AND V.bCorrection_Possible = 0)
            )
        SET @iCount = @@ROWCOUNT
        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   » ' + LTrim(Str(@iCount)) + ' validations à appliquer'

        -- Boucler à travers les validations du sous type de transaction
        DECLARE @iOrdre_Presentation int = 0               
        WHILE Exists(SELECT TOP 1 * FROM #TB_Validation_03 WHERE iOrdre_Presentation > @iOrdre_Presentation) 
        BEGIN
            SET @iCountRejets = 0

            SELECT TOP 1
                @iOrdre_Presentation = iOrdre_Presentation, 
                @iID_Validation = iID_Validation, 
                @iCode_Validation = iCode_Validation, 
                @vcDescription = vcDescription, 
                @cType = cType
            FROM
                #TB_Validation_03 
            WHERE
                iOrdre_Presentation > @iOrdre_Presentation
            ORDER BY 
                iOrdre_Presentation

            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - Validation #' + LTrim(Str(@iCode_Validation)) + ': ' + @vcDescription

            BEGIN TRY
                -- Validation : Le remplacement de bénéficiaire a déjà été envoyé et une réponse reçue de RQ
                IF @iCode_Validation = 101 
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement
                        FROM
                            #TB_Convention_03 C
                            JOIN dbo.tblIQEE_RemplacementsBeneficiaire RB ON RB.iID_Changement_Beneficiaire = C.iID_Remplacement
                            JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = RB.iID_Fichier_IQEE
                        WHERE
                            RB.cStatut_Reponse = 'R'
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription, 
                        NULL, NULL, iID_Remplacement, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le remplacement de bénéficiaire est en attente d’une réponse de RQ
                IF @iCode_Validation = 102 
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement
                        FROM
                            #TB_Convention_03 C
                            JOIN dbo.tblIQEE_RemplacementsBeneficiaire RB ON RB.iID_Changement_Beneficiaire = C.iID_Remplacement
                            JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = RB.iID_Fichier_IQEE
                        WHERE
                            RB.cStatut_Reponse = 'A'
                            AND RB.tiCode_Version <> 1
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription, 
                        NULL, NULL, iID_Remplacement, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Une erreur soulevée par RQ est en cours de traitement pour le remplacement de bénéficiaire
                IF @iCode_Validation = 103
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement
                        FROM
                            #TB_Convention_03 C
                            JOIN dbo.tblIQEE_RemplacementsBeneficiaire RB ON RB.iID_Changement_Beneficiaire = C.iID_Remplacement
                            JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = RB.iID_Fichier_IQEE
                            JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = RB.iID_Remplacement_Beneficiaire
                            JOIN dbo.tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                        WHERE
                            E.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
                            AND SE.vcCode_Statut = 'ATR'
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription, 
                        NULL, NULL, iID_Remplacement, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS de l'ancien bénéficiaire est absent
                IF @iCode_Validation = 104
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNAS
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryOld And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcNAS, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription, 
                        NULL, vcNAS, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom de l'ancien bénéficiaire est absent
                IF @iCode_Validation = 105
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryOld And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcNom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription, 
                        NULL, NULL, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom de l'ancien bénéficiaire est absent
                IF @iCode_Validation = 106
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryOld And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcPrenom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription, 
                        NULL, NULL, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La date de naissance de l'ancien bénéficiaire est absent
                IF @iCode_Validation = 107
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNomPrenom
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryOld And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            B.dtNaissance IS NULL
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La date de naissance de l'ancien bénéficiaire est plus grande que la date du changement de bénéficiaire
                IF @iCode_Validation = 108
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNomPrenom,
                            vcDateRemplacement = CONVERT(VARCHAR(10), C.dtRemplacement, 120),
                            vcDateNaissance = CONVERT(VARCHAR(10), B.dtNaissance, 120)
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryOld And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            B.dtNaissance > C.dtRemplacement
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), '%dtDate_Changement%', vcDateRemplacement),
                        vcDateRemplacement, vcDateNaissance, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le sexe de l'ancien bénéficiaire n’est pas défini
                IF @iCode_Validation = 109
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, vcNomPrenom
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryOld And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            NOT B.cSexe IN ('F', 'M')
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation,  Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le numéro civique de l’adresse à la date du changement du nouveau bénéficiaire est absent ou ne peut pas être déterminé
                IF @iCode_Validation = 110
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.ConventionNo, C.iID_Remplacement, B.iID_Beneficiary, B.iID_Adresse, B.vcAdresse_Tmp
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcNoCivique, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcAdresse_Tmp, iID_Remplacement, iID_Beneficiary, iID_Adresse
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La rue de l’adresse à la date du changement du nouveau bénéficiaire est absente ou ne peut pas être déterminée
                IF @iCode_Validation = 111
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.ConventionNo, C.iID_Remplacement, B.iID_Beneficiary, B.iID_Adresse, B.vcAdresse_Tmp
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcNomRue, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcAdresse_Tmp, iID_Remplacement, iID_Beneficiary, iID_Adresse
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La ville de l’adresse à la date du changement du nouveau bénéficiaire est absente
                IF @iCode_Validation = 112
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNomPrenom, B.iID_Adresse,
                            vcDateRemplacement = CONVERT(VARCHAR(10), C.dtRemplacement, 120)
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcVille, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), '%dtDate_Changement%', vcDateRemplacement),
                        NULL, NULL, iID_Remplacement, iID_Beneficiary, iID_Adresse
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le code postal de l’adresse à la date du changement du nouveau bénéficiaire est absente
                IF @iCode_Validation = 113
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNomPrenom, B.iID_Adresse,
                            vcDateRemplacement = CONVERT(VARCHAR(10), C.dtRemplacement, 120)
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcCodePostal, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), '%dtDate_Changement%', vcDateRemplacement),
                        NULL, NULL, iID_Remplacement, iID_Beneficiary, iID_Adresse
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le code postal canadien de l’adresse à la date du changement du nouveau bénéficiaire est invalide
                IF @iCode_Validation = 114
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNomPrenom, B.iID_Adresse, B.vcCodePostal,
                            vcDateRemplacement = CONVERT(VARCHAR(10), C.dtRemplacement, 120)
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            B.cID_Pays = 'CAN'
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), '%dtDate_Changement%', vcDateRemplacement),
                        NULL, vcCodePostal, iID_Remplacement, iID_Beneficiary, iID_Adresse
                    FROM
                        CTE_Convention
                    WHERE
                        Len(Replace(IsNull(vcCodePostal, ''), ' ', '')) = 6
                        AND dbo.fnGENE_ValiderCodePostal(vcCodePostal, 'CAN') = 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le pays de l’adresse à la date du changement du nouveau bénéficiaire ne peut être déterminé avec le nom de la province ou la ville
                IF @iCode_Validation = 115
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNomPrenom, B.iID_Adresse, B.vcVille, B.vcProvince,
                            vcDateRemplacement = CONVERT(VARCHAR(10), C.dtRemplacement, 120)
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.cID_Pays, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(
                                                         Replace(
                                                           Replace(
                                                             Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), 
                                                             '%dtDate_Changement%', vcDateRemplacement),
                                                           '%vcVille%', vcVille),
                                                         '%vcNom_Province%', vcProvince),
                        NULL, NULL, iID_Remplacement, iID_Beneficiary, iID_Adresse
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le code de province canadienne associé à l’adresse à la date du changement du nouveau bénéficiaire est absent
                IF @iCode_Validation = 116
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNomPrenom, B.iID_Adresse,
                            vcDateRemplacement = CONVERT(VARCHAR(10), C.dtRemplacement, 120)
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            B.cID_Pays = 'CAN'
                            AND Len(IsNull(B.vcProvince, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), '%dtDate_Changement%', vcDateRemplacement),
                        NULL, NULL, iID_Remplacement, iID_Beneficiary, iID_Adresse
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS du nouveau bénéficiaire est absent
                IF @iCode_Validation = 117
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNAS
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcNAS, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription, 
                        NULL, vcNAS, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du nouveau bénéficiaire est absent
                IF @iCode_Validation = 118
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcNom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription, 
                        NULL, NULL, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom du nouveau bénéficiaire est absent
                IF @iCode_Validation = 119
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcPrenom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription, 
                        NULL, NULL, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La date de naissance du nouveau bénéficiaire est absent
                IF @iCode_Validation = 120
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNomPrenom
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            B.dtNaissance IS NULL
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La date de naissance du nouveau bénéficiaire est plus grande que la date du changement de bénéficiaire
                IF @iCode_Validation = 121
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNomPrenom,
                            vcDateRemplacement = CONVERT(VARCHAR(10), C.dtRemplacement, 120),
                            vcDateNaissance = CONVERT(VARCHAR(10), B.dtNaissance, 120)
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            B.dtNaissance > C.dtRemplacement
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), '%dtDate_Changement%', vcDateRemplacement),
                        vcDateRemplacement, vcDateNaissance, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le sexe du nouveau bénéficiaire n’est pas défini
                IF @iCode_Validation = 122
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, vcNomPrenom
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            NOT B.cSexe IN ('F', 'M')
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation,  Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom de l'ancien bénéficiaire contient au moins 1 caractère non conforme
                IF @iCode_Validation = 123
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNomPrenom, B.vcPrenom, 
                            vcCaractere = dbo.fnIQEE_ValiderNom(B.vcPrenom)
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryOld And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcPrenom, '')) <> 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), '%vcCaractereNonConforme%', vcCaractere),
                        NULL, vcPrenom, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention
                    WHERE
                        Len(vcCaractere) > 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom de l'ancien bénéficiaire contient au moins 1 caractère non conforme
                IF @iCode_Validation = 124
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNomPrenom, B.vcNom, 
                            vcCaractere = dbo.fnIQEE_ValiderNom(B.vcNom)
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryOld And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcNom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), '%vcCaractereNonConforme%', vcCaractere),
                        NULL, vcNom, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom du nouveau bénéficiaire contient au moins 1 caractère non conforme
                IF @iCode_Validation = 125
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNomPrenom, B.vcPrenom, 
                            vcCaractere = dbo.fnIQEE_ValiderNom(B.vcPrenom)
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcPrenom, '')) <> 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), '%vcCaractereNonConforme%', vcCaractere),
                        NULL, vcPrenom, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention
                    WHERE
                        Len(vcCaractere) > 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du nouveau bénéficiaire contient au moins 1 caractère non conforme
                IF @iCode_Validation = 126
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNomPrenom, B.vcNom, 
                            vcCaractere = dbo.fnIQEE_ValiderNom(B.vcNom)
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcNom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), '%vcCaractereNonConforme%', vcCaractere),
                        NULL, vcNom, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : L'indicateur si l'ancien bénéficiaire a un lien frère/soeur avec le nouveau bénéficiaire est absent
                IF @iCode_Validation = 127
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, vcNomPrenom_New = New.vcNomPrenom, vcNomPrenom_Old = Old.vcNomPrenom
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 Old ON Old.iID_Beneficiary = C.iID_BeneficiaryOld And Old.dtRemplacement = C.dtRemplacement
                            JOIN #TB_Beneficiary_03 New ON New.iID_Beneficiary = C.iID_BeneficiaryOld And New.dtRemplacement = C.dtRemplacement
                        WHERE
                            C.LienFraterie IS NULL
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%vcNouveau_Beneficiaire%', vcNomPrenom_New), '%vcAncien_Beneficiaire%', vcNomPrenom_Old),
                        NULL, NULL, iID_Remplacement, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : L'indicateur s'il y a un lien de sang entre le nouveau bénéficiaire et le souscripteur initial est absent
                IF @iCode_Validation = 128
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.vcNomPrenom, 
                            vcSubscriber = dbo.fn_Mo_FormatHumanName(H.LastName,'', H.FirstName,'','',0)
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                            JOIN dbo.Un_Subscriber s ON S.SubscriberID = C.IdSouscripteurOriginal
                            JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
                        WHERE
                            C.LienSang_WithFirstSubscriber IS NULL
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        C.ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%vcBeneficiaire%', C.vcNomPrenom), '%vcSouscripteur_Initial%', C.vcSubscriber),
                        NULL, NULL, C.iID_Remplacement, NULL, NULL
                    FROM
                        CTE_Convention C

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le type de relation entre le souscripteur et le nouveau bénéficiaire est absent
                IF @iCode_Validation = 129
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.vcNomPrenom,
                            vcSubscriber = dbo.fn_Mo_FormatHumanName(H.LastName,'', H.FirstName,'','',0)
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryOld And B.dtRemplacement = C.dtRemplacement
                            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.IdSouscripteurOriginal
                            JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
                        WHERE
                            C.LienParente_SubscriberWithNew IS NULL
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), '%vcSouscripteur%', vcSubscriber),
                        NULL, NULL, iID_Remplacement, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Les transactions de la convention sont retenues parce qu'elle a fait l'objet de transactions manuelles de l'IQÉÉ 
                --              avant que les transactions soient implantées dans UniAccès
                IF @iCode_Validation = 130
                BEGIN
                    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » *** SKIPPED ***'
                    --; WITH CTE_Convention as (
                    --    SELECT
                    --        C.ConventionID, C.iID_Remplacement
                    --    FROM
                    --        #TB_Convention_03 C
                    --    WHERE
                    --        C.ConventionNo IN ( 'C-20001005008','C-20001031021','R-20060717009','R-20060717011','R-20060717008',
                    --                            'U-20051201028','R-20070627056','R-20070627058','F-20011119002','I-20050506001',
                    --                            'I-20070925002','I-20070705002','I-20031223005','2039499','D-20010730001',
                    --                            '1449340','2083034','I-20071107001','C-19991018042','I-20050923003','I-20050923002',
                    --                            'U-20080902012','U-20080902012','U-20081028013','U-20080923016','R-20080923006',
                    --                            'R-20080915007','R-20081105003','U-20071213003','U-20080403001','R-20080317046',
                    --                            'R-20080317047','U-20071114068','U-20080411009','R-20080411001','U-20081009005',
                    --                            'R-20080916001','U-20080827021','U-20081105042','R-20071120004','R-20071217029',
                    --                            'U-20071217012','U-20080204002','U-20080930010','T-20081101006','T-20081101017',
                    --                            'T-20081101023','T-20081101028','T-20081101067')
                    --)
                    --INSERT INTO #TB_Rejets_03 (
                    --    iID_Convention, iID_Validation, vcDescription, 
                    --    vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    --)
                    --SELECT 
                    --    ConventionID, @iID_Validation, @vcDescription,
                    --    NULL, NULL, iID_Remplacement, NULL, NULL
                    --FROM
                    --    CTE_Convention

                    --SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La convention a été fermée par une transaction d'impôt spécial 91 ou 51
                IF @iCode_Validation = 131
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement
                        FROM
                            #TB_Convention_03 C
                            JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Convention = C.ConventionID
                            JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
                            JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType T ON T.iID_Sous_Type = I.iID_Sous_Type
                        WHERE
                            I.cStatut_Reponse IN ('A','R')
                            AND I.dtDate_Evenement < C.dtRemplacement
                            AND T.cCode_Sous_Type IN ('51', '91')
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, iID_Remplacement, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS de l'ancien bénéficiaire est invalide
                IF @iCode_Validation = 132
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNAS
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryOld And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcNAS, '')) > 0
                            AND dbo.FN_CRI_CheckSin(B.vcNAS, 0) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription, 
                        NULL, vcNAS, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS du nouveau bénéficiaire est invalide
                IF @iCode_Validation = 133
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.iID_Remplacement, B.iID_Beneficiary, B.vcNAS
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcNAS, '')) > 0
                            AND dbo.FN_CRI_CheckSin(B.vcNAS, 0) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription, 
                        NULL, vcNAS, iID_Remplacement, iID_Beneficiary, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Paramètre(s) manquant(s) pour exécuter la fonction de reconnaissance du changement de bénéficiaire 
                --fnIQEE_RemplacementBeneficiaireReconn
                IF @iCode_Validation = 134
                BEGIN
                    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » *** SKIPPED ***'
                END

                -- Validation : La convention a un nombre de changements de bénéficiaire > 1
                IF @iCode_Validation = 135
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.ConventionNo
                        FROM
                            #TB_Convention_03 C
                        GROUP BY
                            C.ConventionID, C.ConventionNo
                        HAVING
                            Count(*) > 1
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcNo_Convention%', ConventionNo),
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La convention a des cas spéciaux non résolus avec Revenu Québec en cours
                IF @iCode_Validation = 136
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.ConventionNo
                        FROM
                            #TB_Convention_03 C
                            JOIN dbo.tblIQEE_CasSpeciaux CS ON CS.iID_Convention = C.ConventionID
                        WHERE
                            CS.bCasRegle = 0
                            AND ISNULL(CS.tiID_TypeEnregistrement, @tiID_TypeEnregistrement) = @tiID_TypeEnregistrement
                            AND ISNULL(CS.iID_SousType, @iID_SousTypeEnregistrement) = @iID_SousTypeEnregistrement
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(@vcDescription, '%vcNo_Convention%', ConventionNo),
                        NULL, NULL, ConventionID, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le numéro civique de l'adresse du nouveau bénéficiaire est absent ou ne peut pas être déterminé.
                --              Le numéro civique "1" sera forcé
                IF @iCode_Validation = 137
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.ConventionNo, C.iID_Remplacement, B.iID_Beneficiary, B.iID_Adresse, B.vcAdresse_Tmp
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcNoCivique, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcAdresse_Tmp, iID_Remplacement, iID_Beneficiary, iID_Adresse
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom de la rue de l'adresse du nouveau bénéficiaire est absent ou ne peut pas être déterminé
                IF @iCode_Validation = 138
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.ConventionNo, C.iID_Remplacement, B.iID_Beneficiary, B.iID_Adresse, B.vcAdresse_Tmp
                        FROM
                            #TB_Convention_03 C
                            JOIN #TB_Beneficiary_03 B ON B.iID_Beneficiary = C.iID_BeneficiaryNew And B.dtRemplacement = C.dtRemplacement
                        WHERE
                            Len(IsNull(B.vcNomRue, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcAdresse_Tmp, iID_Remplacement, iID_Beneficiary, iID_Adresse
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La convention individuelle est issue d'un RIO où il reste des montants d'IQÉÉ dans la convention Universitas source
                IF @iCode_Validation = 139
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT DISTINCT
                            C.ConventionID, 
                            Solde = Sum(CO.ConventionOperAmount) 
                        FROM
                            #TB_Convention_03 C
                            JOIN dbo.Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblOPER_OperationsRIO RIO
                                         LEFT JOIN dbo.tblIQEE_Transferts T ON T.iID_Convention = RIO.iID_Convention_Source 
                                                                            OR T.iID_Convention = RIO.iID_Convention_Destination
                                                                           AND T.dtDate_Transfert = RIO.dtDate_Enregistrement
                                WHERE 
                                    RIO.iID_Convention_Destination = C.ConventionID
                                    AND RIO.bRIO_Annulee = 0
                                    AND RIO.bRIO_QuiAnnule = 0
                            )
                            AND CO.ConventionOperTypeID IN (
                                    SELECT cID_Type_Oper_Convention FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_MAJORATION')
                                    UNION
                                    SELECT cID_Type_Oper_Convention FROM dbo.fntOPER_ObtenirOperationsCategorie('IQEE_SOMMAIRE_PCEEIQEE_CREDIT_BASE')
                            )
                        GROUP BY
                            C.ConventionID
                    )
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        CTE_Convention
                    WHERE
                        Solde > 0
                END 

                -- Validation : Le transfert doit être déclaré à RQ avant que la convention puisse être fermée
                IF @iCode_Validation = 140
                BEGIN
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT
                        TB.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%dtTransfert%', CONVERT(VARCHAR(10), T.OperDate, 120)), '%OperTypeID%', T.OperTypeID), 
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        dbo.fntIQEE_Transfert_NonDeclare(DEFAULT, @dtFinCotisation) T
                        JOIN #TB_Convention_03 TB ON TB.ConventionID = T.ConventionID
                    WHERE
                        T.OperDate < TB.dtRemplacement

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le PAE doit être déclaré à RQ avant un changement bénéficiaire non-reconnu
                IF @iCode_Validation = 141
                BEGIN
                    INSERT INTO #TB_Rejets_03 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%dtPaiement%', CONVERT(VARCHAR(10), PB.OperDate, 120)), '%ScholarshipNo%', TB.ConventionNo),
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        dbo.fntIQEE_PaiementBeneficiaire_NonDeclare(DEFAULT, @dtFinCotisation) PB
                        JOIN #TB_Convention_03 TB ON TB.ConventionID = PB.ConventionID
                    WHERE
                        PB.OperDate < TB.dtRemplacement

                    SET @iCountRejets = @@ROWCOUNT
                END
            END TRY
            BEGIN CATCH
                PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » *** ERREUR_VALIDATION ***'
                PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     »     ' + ERROR_MESSAGE()

                INSERT INTO ##tblIQEE_RapportCreation 
                    (cSection, iSequence, vcMessage)
                SELECT
                    '3', 10, '       '+CONVERT(VARCHAR(25), GETDATE(), 121)+'     '+vcDescription_Parametrable + ' ' + LTrim(Str(@iCode_Validation))
                FROM
                    dbo.tblIQEE_Validations
                WHERE 
                    iCode_Validation = 100

                RETURN -1
            END CATCH

            IF @iCountRejets > 0
            BEGIN
                -- S'il y a eu des rejets de validation
                PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCountRejets)) + CASE @cType WHEN 'E' THEN ' rejets'
                                                                                                                         WHEN 'A' THEN ' avertissements'
                                                                                                                         ELSE ''
                                                                                                             END

                -- Et si on traite seulement les 1ères erreurs de chaque convention
                IF @bArretPremiereErreur = 1 AND @cType = 'E'
                BEGIN
                    -- Efface que les conventions ayant un rejet sur la validation courante
                    DELETE FROM #TB_Convention_03
                    WHERE EXISTS (SELECT * FROM #TB_Rejets_03 WHERE iID_Convention = ConventionID AND iID_Validation = @iID_Validation)
                END
            END
        END -- IF @iCode_Validation 

        -- Efface tous les conventions ayant eu au moins un rejet de validation
        DELETE FROM #TB_Convention_03
        WHERE EXISTS (SELECT * FROM #TB_Rejets_03 R 
                                    JOIN dbo.tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation 
                       WHERE V.cType = 'E' And R.iID_Convention = ConventionID AND R.iID_Lien_Vers_Erreur_1 = iID_Remplacement )

        INSERT INTO dbo.tblIQEE_Rejets (
            iID_Fichier_IQEE, siAnnee_Fiscale, iID_Convention, iID_Validation, vcDescription, 
            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
            --, tCommentaires, iID_Utilisateur_Modification, dtDate_Modification
        )
        SELECT 
            @iID_Fichier_IQEE, @siAnnee_Fiscale, R.iID_Convention, R.iID_Validation, R.vcDescription, 
            R.vcValeur_Reference, vcValeur_Erreur, R.iID_Lien_Vers_Erreur_1, R.iID_Lien_Vers_Erreur_2, R.iID_Lien_Vers_Erreur_3
        FROM 
            #TB_Rejets_03 R
    END

    ---------------------------------------
    -- Enregistrer les transactions valides
    ---------------------------------------
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Déclaration des changements de bénéficiaires'
    BEGIN
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   Créer les enregistrements de remplacement bénéficiaires.'
        SET @QueryTimer = GetDate()

        -- Créer la transaction 03
        ; WITH CTE_Sexe as (
            SELECT X.rowID as ID, X.strField as Code
            FROM ProAcces.fn_SplitIntoTable('F,M', ',') X
        ),
        CTE_Remplacement_Old AS (
            SELECT C.ConventionID, C.ConventionNo, C.iID_Remplacement, C.dtRemplacement, 
                   C.iID_BeneficiaryOld, B_Old.vcNAS AS vcNAS_Old, B_Old.vcNom AS vcNom_Old, B_Old.vcPrenom AS vcPrenom_Old, B_Old.dtNaissance AS dtNaissance_Old, S.ID AS tiSexe_Old, 
                   iAge_Old = B_Old.Age_31_Decembre,
                   C.iID_BeneficiaryNew, C.LienFraterie, C.LienParente_SubscriberWithNew, C.LienSang_WithFirstSubscriber, C.bRemplacementReconnu
              FROM #TB_Convention_03 C
                   JOIN #TB_Beneficiary_03 B_Old ON B_Old.iID_Beneficiary = C.iID_BeneficiaryOld And B_Old.iID_Remplacement = C.iID_Remplacement
                   JOIN CTE_Sexe S ON S.Code = B_Old.cSexe
        ),
        CTE_Remplacement_New AS (
            SELECT C.ConventionID, C.ConventionNo, C.iID_Remplacement, C.dtRemplacement, 
                   C.iID_BeneficiaryOld, C.vcNAS_Old, C.vcNom_Old, C.vcPrenom_Old, C.dtNaissance_Old, C.tiSexe_Old, C.iAge_Old,
                   C.iID_BeneficiaryNew, B_New.vcNAS AS vcNAS_New, B_New.vcNom AS vcNom_New, B_New.vcPrenom AS vcPrenom_New, B_New.dtNaissance AS dtNaissance_New, S.ID AS tiSexe_New, 
                   iAge_New = B_New.Age_31_Decembre,
                   C.LienFraterie, C.LienParente_SubscriberWithNew, C.LienSang_WithFirstSubscriber, C.bRemplacementReconnu, 
                   B_New.iID_Adresse, B_New.vcAppartement, B_New.vcNoCivique, B_New.vcNomRue, B_New.vcAdresseLigne3, 
                   B_New.vcVille, B_New.vcProvince, B_New.cID_Pays, B_New.vcCodePostal, B_New.bResidenceQuebec
              FROM CTE_Remplacement_Old C
                   JOIN #TB_Beneficiary_03 B_New ON B_New.iID_Beneficiary = C.iID_BeneficiaryNew And B_New.iID_Remplacement = C.iID_Remplacement
                   JOIN CTE_Sexe S ON S.Code = B_New.cSexe
        ),
        CTE_Remplacement AS (
            SELECT C.ConventionID, C.ConventionNo, C.iID_Remplacement, C.dtRemplacement, 
                   C.iID_BeneficiaryOld, C.vcNAS_Old, C.vcNom_Old, C.vcPrenom_Old, C.dtNaissance_Old, C.tiSexe_Old, C.iAge_Old,
                   C.iID_BeneficiaryNew, C.vcNAS_New, C.vcNom_New, C.vcPrenom_New, C.dtNaissance_New, C.tiSexe_New, C.iAge_New,
                   C.LienFraterie, C.LienParente_SubscriberWithNew, C.LienSang_WithFirstSubscriber, C.bRemplacementReconnu, 
                   C.iID_Adresse, C.vcAppartement, C.vcNoCivique, C.vcNomRue, C.vcAdresseLigne3, 
                   C.vcVille, C.vcProvince, C.cID_Pays, C.vcCodePostal, C.bResidenceQuebec
              FROM CTE_Remplacement_New C
        )
        INSERT INTO dbo.tblIQEE_RemplacementsBeneficiaire (
            iID_Fichier_IQEE, siAnnee_Fiscale, iID_Convention, vcNo_Convention, tiCode_Version, cStatut_Reponse, 
            iID_Changement_Beneficiaire, dtDate_Remplacement, bLien_Frere_Soeur, tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire,
            bLien_Sang_Nouveau_Beneficiaire_Souscripteur_Initial, bInd_Remplacement_Reconnu, 
            iID_Ancien_Beneficiaire, vcNAS_Ancien_Beneficiaire, vcNom_Ancien_Beneficiaire, vcPrenom_Ancien_Beneficiaire, dtDate_Naissance_Ancien_Beneficiaire, tiSexe_Ancien_Beneficiaire, 
            iID_Nouveau_Beneficiaire, vcNAS_Nouveau_Beneficiaire, vcNom_Nouveau_Beneficiaire, vcPrenom_Nouveau_Beneficiaire, dtDate_Naissance_Nouveau_Beneficiaire, tiSexe_Nouveau_Beneficiaire, 
            iID_Adresse_Beneficiaire_Date_Remplacement, vcAppartement_Beneficiaire, vcNo_Civique_Beneficiaire, vcRue_Beneficiaire, 
            vcLigneAdresse3_Beneficiaire, vcVille_Beneficiaire, vcProvince_Beneficiaire, vcPays_Beneficiaire, vcCodePostal_Beneficiaire, 
            bResidence_Quebec --, iID_Ligne_Fichier
        )
        SELECT DISTINCT
            @iID_Fichier_IQEE, @siAnnee_Fiscale, C.ConventionID, C.ConventionNo, @tiCode_Version, 'A',
            C.iID_Remplacement, C.dtRemplacement, CASE WHEN iAge_New >= 21 THEN 0 ELSE C.LienFraterie END, C.LienParente_SubscriberWithNew, 
            CASE WHEN iAge_New >= 21 THEN 0 ELSE C.LienSang_WithFirstSubscriber END, C.bRemplacementReconnu, 
            C.iID_BeneficiaryOld, C.vcNAS_Old, Left(C.vcNom_Old, 20), Left(C.vcPrenom_Old, 20), C.dtNaissance_Old, C.tiSexe_Old, 
            C.iID_BeneficiaryNew, C.vcNAS_New, Left(C.vcNom_New, 20), Left(C.vcPrenom_New, 20), C.dtNaissance_New, C.tiSexe_New, 
            C.iID_Adresse, Left(C.vcAppartement,6), IsNull(Left(C.vcNoCivique,10), '1'), Left(C.vcNomRue,30),
            Left(C.vcAdresseLigne3,40), Left(C.vcVille,30), Left(C.vcProvince,2), Left(C.cID_Pays,3), Left(C.vcCodePostal,10), 
            CASE Left(IsNull(C.vcProvince, ''), 2) WHEN 'QC' THEN 1 ELSE C.bResidenceQuebec END --, iID_Ligne_Fichier
        FROM
            CTE_Remplacement C

        SET @iCount = @@RowCount
        SET @ElapseTime = @QueryTimer - GetDate()
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' enregistrements ajoutés (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime), 4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
    END

    SET @ElapseTime = GetDate() - @StartTimer
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions03 completed' 
                + ' (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime), 4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

    IF OBJECT_ID('tempdb..#TB_Validation_03') IS NOT NULL
        DROP TABLE #TB_Validation_03
    IF OBJECT_ID('tempdb..#TB_Rejets_03') IS NOT NULL
        DROP TABLE #TB_Rejets_03
    IF OBJECT_ID('tempdb..#TB_Beneficiary_03') IS NOT NULL
        DROP TABLE #TB_Beneficiary_03
    IF OBJECT_ID('tempdb..#TB_Convention_03') IS NOT NULL
        DROP TABLE #TB_Convention_03

    -- Retourner 0 si le traitement est réussi
    RETURN 0
END
