/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_RechercherRejets
Nom du service        : Rechercher les rejets
But                 : Rechercher à travers les rejets de l’IQÉÉ et obtenir les informations de celles-ci.
Facette                : IQÉÉ

Note                : La traduction a été retirer de la programmation afin d'améliorer la performance pour les essais.

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------
                        cID_Langue                    Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
                                                    Le français est la langue par défaut si elle n’est pas spécifiée.
                        tiID_Categorie_Erreur        Identifiant unique d’une catégorie d’erreur.  S’il est vide, les
                                                    rejets de toutes les catégories sont considérés.
                        tiID_Type_Enregistrement    Identifiant du type d’enregistrement relié au rejet.  S’il est vide,
                                                    les rejets de tous les types d’enregistrement sont considérés.
                        iID_Sous_Type                Identifiant d’un sous type d’enregistrement relié au rejet.  S’il
                                                    est vide, les rejets de tous les sous type sont considérés.
                        cType                        Type de validation. S’il est vide, les rejets de tous les types
                                                    sont considérés.  « E » =  Erreurs, « A » = Avertissements
                        tiID_Categorie_Element        Identifiant unique d’une catégorie d’éléments.  S’il est vide, les
                                                    rejets de toutes les catégories sont considérés.
                        bCorrection_Possible        Indicateur de correction possible.  S’il est vide, tous les rejets
                                                    sont considérés.  1 = correction possible.  0 = correction non possible.
                        iID_Validation                Identifiant unique de la validation ayant amenée le rejet.  S’il est
                                                    vide, toutes les validations sont considérées.
                        siAnnee_Fiscale                Année fiscale du fichier de demande ayant amené le rejet.  S’il est
                                                    vide, les rejets de toutes les années fiscales sont considérés.
                        iID_Fichier_IQEE            Identifiant unique d’un fichier de demande ayant amené le rejet.  
                                                    S’il est vide, les rejets de tous les fichiers sont considérés.
                        bEnvoye_RQ                    Indicateur si une transaction a été envoyé à RQ après la création
                                                    du rejet.  S’il est vide, tous les rejets sont considérés.  
                                                    1 = Envoyé à RQ, 0 = Non envoyé à RQ
                        bAutres_Rejets_Erreur        Indicateur de prendre les conventions où il n’y a pas d’autres
                                                    rejets en erreur que la sélection des rejets faites.  S’il est vide,
                                                    la sélection des rejets ne tient pas compte du fait qu’il y ait 
                                                    d’autres erreurs ou non.  S’il est présent, la sélection des rejets
                                                    retient uniquement les conventions où il n’y pas d’autres rejets en
                                                    erreur.
                        vcCommentaires                Partie de texte d’un commentaire saisi par l’utilisateur.  S’il est
                                                    absent, les rejets sont considérés sans tenir compte du commentaire.
                        iID_Convention                Identifiant unique de la convention sur lequel porte le rejet.  S’il
                                                    est absent, les rejets de toutes les conventions sont considérés.
                        vcNo_Convention                Numéro unique de la convention sur lequel porte le rejet.  S’il est
                                                    absent, les rejets de toutes les conventions sont considérés.
                        bConvention_Fermees            Indicateur de sélectionner uniquement les conventions non fermées.
                                                    S’il est absent, tous les statuts des conventions sont considérés et
                                                    s’il est présent, seulement les conventions non fermées ou les
                                                    conventions fermées pour cause de transfert OUT ou PAE versé sont
                                                    sélectionnées.
                        bConvention_OUT_PAE            Indicateur de sélectionner uniquement les conventions fermées pour
                                                    cause de transfert OUT ou PAE versé.  S’il est absent, tous les statuts
                                                    des conventions sont considérés et s’il est présent, seulement les
                                                    conventions fermées pour cause de transfert OUT ou PAE versé sont
                                                    sélectionnées.
                        vcCode_Simulation            Code de simulation.  Permet de rechercher les rejets pour un ou plusieurs
                                                    fichiers de simulation.  S’il est vide, les rejets de tous les fichiers
                                                    sont considérés.
                        bAfficher_Rejets_Convention    Ce paramètre n’est pas un critère de recherche, mais
                            _Selectionnees            une option d’affichage qui permet de retourner tous les rejets des
                                                    conventions sélectionnées par les critères de recherche qui sont dans
                                                    la même année fiscale que les rejets qui entre dans les critères de
                                                    recherche.

Exemple d’appel        :    EXECUTE dbo.psIQEE_RechercherRejets NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
                                                            NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL

Paramètres de sortie:    Tous les champs de la table « tblIQEE_Rejets » en plus des champs suivants.
                        Table                        Champ                            Description
                          -------------------------    ---------------------------     ---------------------------------
                        Un_Convention                ConventionNo                    Numéro de la convention.
                        tblIQEE_Fichiers            siAnnee_Fiscale                    Année fiscal du fichier de transactions.
                        tblIQEE_Fichiers            dtDate_Creation                    Date de création du fichier de
                                                                                    transactions.
                        tblIQEE_Fichiers            bFichier_Test                    Indicateur de fichier test.
                        S/O                            bEnvoye_RQ                        Indicateur si une transaction a été envoyé
                                                                                    à RQ après la création du rejet.  
                                                                                    1 = Envoyé à RQ, 0 = Non envoyé à RQ
                        Un_ConventionState            ConventionStateName                Description du statut de la convention
                                                                                    en rejet.
                        tblIQEE_TypesEnregistrement    cCode_Type_Enregistrement        Code du type d’enregistrement.
                        tblIQEE_TypesEnregistrement    vcDescription                    Description du type d’enregistrement.
                        tblIQEE_SousTypeEnregistrement    cCode_Sous_Type                Code du sous type d’enregistrement.
                        tblIQEE_SousTypeEnregistrement    vcDescription                Description du sous type d’enregistrement.
                        tblIQEE_Validations            cType                            Type de la validation.  « E » =  Erreurs,
                                                                                    « A » = Avertissements
                        tblIQEE_Validations            iCode_Validation                Code de la validation.
                        tblIQEE_Validations            vcDescription                    Description de la validation.
                        tblIQEE_CategoriesElements    tiID_Categorie_Element            Identifiant unique de la catégorie d’éléments.
                        tblIQEE_CategoriesElements    vcCode_Categorie                Code de la catégorie d’éléments.
                        tblIQEE_CategoriesElements    vcDescription                    Description de la catégorie d’éléments.
                        tblIQEE_Validations            bCorrection_Possible            Indicateur s’il est possible d’intervenir
                                                                                    pour corriger le rejet.
                        tblIQEE_Validations            bActif                            Indicateur de validation active ou non.
                        tblIQEE_CategoriesErreur    tiID_Categorie_Erreur            Identifiant unique de la catégorie de rejet.
                        tblIQEE_CategoriesErreur    vcCode_Categorie                Code de la catégorie de rejet.
                        tblIQEE_CategoriesErreur    vcDescription_Categorie_Rejet    Description de la catégorie de rejet.
                        tblIQEE_CategoriesErreur    vcResponsable                    Nom du responsable de la catégorie de rejet.
                        tblIQEE_Validations            vcDescription_Valeur_Erreur        Description de la valeur en erreur.
                        tblIQEE_Validations            vcDescription_Valeur_Reference    Description de la valeur de référence.
                        Mo_Human                    FirstName, LastName                Nom de l’utilisateur qui a fait la dernière
                                                                                    modification du rejet.
                        Un_Convention                SubscriberID                    Identifiant du souscripteur courant de la
                                                                                    convention
                        Un_Convention                BeneficiaryID                    Identifiant du bénéficiaire courant de la
                                                                                    convention

Historique des modifications:
        Date            Programmeur                            Description                                    Référence
        ------------    ----------------------------------    -----------------------------------------    ------------
        2009-06-25        Éric Deshaies                        Création du service
        2009-08-28        Éric Deshaies                        Ajout du souscripteur et du bénéficiaire
                                                            courant de la convention à la sortie
        2010-07-02        Éric Deshaies                        Rechercher uniquement des fichiers de même type
        2010-08-03        Éric Deshaies                        Mise à niveau sur la traduction des champs
        2011-01-13        Éric Deshaies                        Retrait du commentaire sur la transaction de type 06-12
        2014-08-08        Stéphane Barbeau                    Ajout de IsNull pour le champ bEnvoye_RQ dans la requête finale 
                                                            afin d'éviter les erreurs techniques de type Object cannot be cast 
                                                            from DBNull to other types.
        2015-04-10        Stéphane Barbeau                    Désactivation ligne AND PB.iID_Cotisation = R.iID_Lien_Vers_Erreur_1                                                    
                                                            Ce champ n'existe plus dans la table tblIQEE_PaiementsBeneficiaires
        2018-02-08      Steeve Picard                       Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
****************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_RechercherRejets
(
    @cID_Langue CHAR(3),
    @tiID_Categorie_Erreur TINYINT,
    @tiID_Type_Enregistrement TINYINT,
    @iID_Sous_Type INT,
    @cType CHAR(1),
    @tiID_Categorie_Element TINYINT,
    @bCorrection_Possible BIT,
    @iID_Validation INT,
    @siAnnee_Fiscale SMALLINT,
    @iID_Fichier_IQEE INT,
    @bEnvoye_RQ BIT,
    @bAutres_Rejets_Erreur BIT,
    @vcCommentaires VARCHAR(75),
    @iID_Convention INT,
    @vcNo_Convention VARCHAR(15),
    @bConvention_Fermees BIT,
    @bConvention_OUT_PAE BIT,
    @vcCode_Simulation VARCHAR(100),
    @bAfficher_Rejets_Convention_Selectionnees BIT
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Considérer le français comme la langue par défaut
    IF @cID_Langue IS NULL
        SET @cID_Langue = 'FRA'

    -- Si les valeurs numériques sont à 0, c'est comme si elle n'étaient pas présente
    IF @tiID_Categorie_Erreur = 0
        SET @tiID_Categorie_Erreur = NULL

    IF @tiID_Type_Enregistrement = 0
        SET @tiID_Type_Enregistrement = NULL

    IF @iID_Sous_Type = 0
        SET @iID_Sous_Type = NULL

    IF @tiID_Categorie_Element = 0
        SET @tiID_Categorie_Element = NULL

    IF @iID_Validation = 0
        SET @iID_Validation = NULL

    IF @siAnnee_Fiscale = 0
        SET @siAnnee_Fiscale = NULL

    IF @iID_Fichier_IQEE = 0
        SET @iID_Fichier_IQEE = NULL

    IF @iID_Convention = 0
        SET @iID_Convention = NULL

    -- Créer une table temporaire des rejets 
    CREATE TABLE #tblIQEE_ConventionsRejets
       (iID_Rejet INTEGER NOT NULL PRIMARY KEY,
        iID_Convention INTEGER NOT NULL,
        siAnnee_Fiscale SMALLINT NOT NULL,
        bEnvoye_RQ BIT NULL)

    -- Insérer dans la table temporaire les rejets selon les critères de recherche et déterminer s'il y a eue une transaction
    -- envoyé à RQ après l'existance du rejet
    INSERT INTO #tblIQEE_ConventionsRejets
    SELECT  R.iID_Rejet,
            R.iID_Convention,
            R.siAnnee_Fiscale,
            CASE TE.cCode_Type_Enregistrement 
                WHEN '02' THEN
                    CASE WHEN (SELECT COUNT(*)
                               FROM tblIQEE_Demandes D
                                    JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = D.iID_Fichier_IQEE
                                                            AND F2.dtDate_Creation > F.dtDate_Creation
                               WHERE D.iID_Convention = R.iID_Convention
                                 AND D.siAnnee_Fiscale = R.siAnnee_Fiscale) = 0 THEN 0 ELSE 1
                    END
                WHEN '03' THEN
                    CASE WHEN (SELECT COUNT(*)
                               FROM tblIQEE_RemplacementsBeneficiaire RB
                                    JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = RB.iID_Fichier_IQEE
                                                            AND F2.dtDate_Creation > F.dtDate_Creation
                               WHERE RB.iID_Convention = R.iID_Convention
                                 AND RB.iID_Changement_Beneficiaire = R.iID_Lien_Vers_Erreur_1) = 0 THEN 0 ELSE 1
                    END
                WHEN '04' THEN
                    CASE WHEN (SELECT COUNT(*)
                               FROM tblIQEE_Transferts T
                                    JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = T.iID_Fichier_IQEE
                                                            AND F2.dtDate_Creation > F.dtDate_Creation
                               WHERE T.iID_Convention = R.iID_Convention
                                 AND T.iID_Operation = R.iID_Lien_Vers_Erreur_1) = 0 THEN 0 ELSE 1
                    END
                WHEN '05' THEN
                    CASE ST.cCode_Sous_Type
                        WHEN '01' THEN
                            CASE WHEN (SELECT COUNT(*)
                                       FROM tblIQEE_PaiementsBeneficiaires PB
                                            JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = PB.iID_Fichier_IQEE
                                                                    AND F2.dtDate_Creation > F.dtDate_Creation
                                       WHERE PB.iID_Convention = R.iID_Convention
                                         AND PB.iID_Paiement_Bourse = R.iID_Lien_Vers_Erreur_1) = 0 THEN 0 ELSE 1
                            END
                        WHEN '02' THEN
                            CASE WHEN (SELECT COUNT(*)
                                       FROM tblIQEE_PaiementsBeneficiaires PB
                                            JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = PB.iID_Fichier_IQEE
                                                                    AND F2.dtDate_Creation > F.dtDate_Creation
                                       WHERE PB.iID_Convention = R.iID_Convention
                                       -- 2015-04-10 SB: Ce champ n'existe plus dans la table tblIQEE_PaiementsBeneficiaires
                                         --AND PB.iID_Cotisation = R.iID_Lien_Vers_Erreur_1
                                         ) = 0 THEN 0 ELSE 1
                            END
                        END
                WHEN '06' THEN
                    CASE ST.cCode_Sous_Type
                        WHEN '01' THEN
                            CASE WHEN (SELECT COUNT(*)
                                       FROM tblIQEE_ImpotsSpeciaux TIS
                                            JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = TIS.iID_Fichier_IQEE
                                                                    AND F2.dtDate_Creation > F.dtDate_Creation
                                       WHERE TIS.iID_Convention = R.iID_Convention
                                         AND TIS.iID_Remplacement_Beneficiaire = R.iID_Lien_Vers_Erreur_1) = 0 THEN 0 ELSE 1
                            END
                        WHEN '11' THEN
                            CASE WHEN (SELECT COUNT(*)
                                       FROM tblIQEE_ImpotsSpeciaux TIS
                                            JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = TIS.iID_Fichier_IQEE
                                                                    AND F2.dtDate_Creation > F.dtDate_Creation
                                       WHERE TIS.iID_Convention = R.iID_Convention
                                         AND TIS.iID_Transfert = R.iID_Lien_Vers_Erreur_1) = 0 THEN 0 ELSE 1
                            END
                        WHEN '22' THEN
                            CASE WHEN (SELECT COUNT(*)
                                       FROM tblIQEE_ImpotsSpeciaux TIS
                                            JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = TIS.iID_Fichier_IQEE
                                                                    AND F2.dtDate_Creation > F.dtDate_Creation
                                       WHERE TIS.iID_Convention = R.iID_Convention
                                         AND TIS.siAnnee_Fiscale = R.siAnnee_Fiscale) = 0 THEN 0 ELSE 1
                            END
                        END
                        WHEN '23' THEN
                            CASE WHEN (SELECT COUNT(*)
                                       FROM tblIQEE_ImpotsSpeciaux TIS
                                            JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = TIS.iID_Fichier_IQEE
                                                                    AND F2.dtDate_Creation > F.dtDate_Creation
                                       WHERE TIS.iID_Convention = R.iID_Convention
                                         AND TIS.iID_Cotisation = R.iID_Lien_Vers_Erreur_1) = 0 THEN 0 ELSE 1
                            END
                        WHEN '91' THEN
                            CASE WHEN (SELECT COUNT(*)
                                       FROM tblIQEE_ImpotsSpeciaux TIS
                                            JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = TIS.iID_Fichier_IQEE
                                                                    AND F2.dtDate_Creation > F.dtDate_Creation
                                       WHERE TIS.iID_Convention = R.iID_Convention
                                         AND TIS.iID_Statut_Convention = R.iID_Lien_Vers_Erreur_1) = 0 THEN 0 ELSE 1
                            END
                ELSE 0
            END 
    FROM tblIQEE_Rejets R
         JOIN tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
                                  AND (@tiID_Categorie_Erreur IS NULL OR V.tiID_Categorie_Erreur = @tiID_Categorie_Erreur)
                                    AND (@tiID_Type_Enregistrement IS NULL OR V.tiID_Type_Enregistrement = @tiID_Type_Enregistrement)
                                      AND (@iID_Sous_Type IS NULL OR V.iID_Sous_Type = @iID_Sous_Type)
                                      AND (@cType IS NULL OR V.cType = @cType)
                                  AND (@tiID_Categorie_Element IS NULL OR V.tiID_Categorie_Element = @tiID_Categorie_Element)
                                  AND (@bCorrection_Possible IS NULL OR V.bCorrection_Possible = @bCorrection_Possible)
                                  AND (@iID_Validation IS NULL OR V.iID_Validation = @iID_Validation)
         JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = R.iID_Fichier_IQEE
                                AND (@iID_Fichier_IQEE IS NULL OR F.iID_Fichier_IQEE = @iID_Fichier_IQEE)
                                AND (@vcCode_Simulation IS NULL OR F.vcCode_Simulation = @vcCode_Simulation)
         JOIN dbo.Un_Convention C ON C.ConventionID = R.iID_Convention
                             AND (@vcNo_Convention IS NULL OR C.ConventionNo = @vcNo_Convention)
         JOIN Un_ConventionConventionState CS ON CS.ConventionID = R.iID_Convention 
                                             AND CS.StartDate = (SELECT MAX(StartDate)
                                                                 FROM Un_ConventionConventionState CS2
                                                                 WHERE CS2.ConventionID = CS.ConventionID) 
         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = V.tiID_Type_Enregistrement
         LEFT JOIN tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = V.iID_Sous_Type
    WHERE (@iID_Convention IS NULL OR R.iID_Convention = @iID_Convention)
      AND (@siAnnee_Fiscale IS NULL OR R.siAnnee_Fiscale = @siAnnee_Fiscale)
      AND (@vcCommentaires IS NULL OR R.tCommentaires LIKE '%'+@vcCommentaires+'%')
      AND (@bAutres_Rejets_Erreur IS NULL OR 
           NOT EXISTS (SELECT *
                       FROM tblIQEE_Rejets R2
                           JOIN tblIQEE_Validations V2 ON V2.iID_Validation = R2.iID_Validation
                                                      AND V2.cType = 'E'
                      WHERE R2.iID_Convention = R.iID_Convention
                        AND R2.iID_Fichier_IQEE = R.iID_Fichier_IQEE
                        AND R2.iID_Rejet <> R.iID_Rejet))
      AND (@bConvention_Fermees IS NULL OR
           CS.ConventionStateID <> 'FRM')
      AND (@bConvention_OUT_PAE IS NULL OR
           (CS.ConventionStateID = 'FRM'
            AND EXISTS (SELECT *
                        FROM dbo.Un_Unit U
                             JOIN Un_UnitUnitState US ON US.UnitID = U.UnitID
                                                     AND US.StartDate = (SELECT MAX(StartDate)
                                                                         FROM Un_UnitUnitState US2
                                                                         WHERE US2.UnitID = US.UnitID)
                                                     AND US.UnitStateID IN ('PVR','OUT')
                        WHERE U.ConventionID = R.iID_Convention)))

    -- Retirer les conventions qui ne correspondent pas au critère de recherche à savoir s'il y a eue une transaction
    -- envoyé à RQ après l'existance du rejet
    IF @bEnvoye_RQ IS NOT NULL
        DELETE FROM #tblIQEE_ConventionsRejets
        WHERE bEnvoye_RQ = @bEnvoye_RQ  -- C'est égal parce que les valeurs du champ sont inversé par rapport à ce qu'envoi l'interface Web.

    -- Rechercher les informations sur les rejets selon l'option d'affichage
    SELECT  R.iID_Rejet,
            R.iID_Convention,
            C.ConventionNo AS vcNo_Convention,
            R.iID_Fichier_IQEE,
            R.siAnnee_Fiscale,
            F.dtDate_Creation,
            F.bFichier_Test,
            ISNull(CR.bEnvoye_RQ,0) as bEnvoye_RQ,
            ISNULL(T1.vcTraduction,S.ConventionStateName) AS vcDescription_Statut_Convention,
            TE.cCode_Type_Enregistrement,
            ISNULL(T2.vcTraduction,TE.vcDescription) AS vcDescription_Type_Enregistrement,
            ST.cCode_Sous_Type,
            ISNULL(T3.vcTraduction,ST.vcDescription) AS vcDescription_Sous_Type_Enregistrement,
            R.iID_Validation,
            V.cType,
            V.iCode_Validation,
            R.vcDescription,
            ISNULL(T4.vcTraduction,V.vcDescription) AS vcDescription_Validation,
            V.tiID_Categorie_Element,
            CE.vcCode_Categorie AS vcCode_Categorie_Element,
            ISNULL(T5.vcTraduction,CE.vcDescription) AS vcDescription_Categorie_Element,
            V.bCorrection_Possible,
            V.bActif,
            CA.tiID_Categorie_Erreur,    
            CA.vcCode_Categorie AS vcCode_Categorie_Erreur,
            ISNULL(T6.vcTraduction,CA.vcDescription) AS vcDescription_Categorie_Rejet,
            CA.vcResponsable,
            R.vcValeur_Erreur,
            R.vcValeur_Reference,
            ISNULL(T7.vcTraduction,V.vcDescription_Valeur_Erreur) AS vcDescription_Valeur_Erreur,
            ISNULL(T8.vcTraduction,V.vcDescription_Valeur_Reference) AS vcDescription_Valeur_Reference,
            R.iID_Lien_Vers_Erreur_1,
            R.iID_Lien_Vers_Erreur_2,
            R.iID_Lien_Vers_Erreur_3,
            R.tCommentaires,
            R.iID_Utilisateur_Modification,
            U1.FirstName + ' ' + U1.LastName AS vcUtilisateur_Modification,
            R.dtDate_Modification,
            C.SubscriberID AS iID_Souscripteur,
            C.BeneficiaryID AS iID_Beneficiaire
    FROM tblIQEE_Rejets R
         LEFT JOIN #tblIQEE_ConventionsRejets CR ON CR.iID_Rejet = R.iID_Rejet
         JOIN tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
         JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = R.iID_Fichier_IQEE
         JOIN dbo.Un_Convention C ON C.ConventionID = R.iID_Convention
         JOIN Un_ConventionConventionState CS ON CS.ConventionID = R.iID_Convention 
                                             AND CS.StartDate = (SELECT MAX(StartDate)
                                                                 FROM Un_ConventionConventionState CS2
                                                                 WHERE CS2.ConventionID = CS.ConventionID) 
         JOIN Un_ConventionState S ON S.ConventionStateID = CS.ConventionStateID
         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = V.tiID_Type_Enregistrement
         LEFT JOIN tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = V.iID_Sous_Type
         JOIN tblIQEE_CategoriesElements CE ON CE.tiID_Categorie_Element = V.tiID_Categorie_Element
         JOIN tblIQEE_CategoriesErreur CA ON CA.tiID_Categorie_Erreur = V.tiID_Categorie_Erreur
         LEFT JOIN dbo.Mo_Human U1 ON U1.HumanID = R.iID_Utilisateur_Modification
         LEFT JOIN tblGENE_Traductions T1 ON T1.vcNom_Table = 'Un_ConventionState'
                                         AND T1.vcNom_Champ = 'ConventionStateName'
                                         AND T1.vcID_Enregistrement = S.ConventionStateID
                                         AND T1.vcID_Langue = @cID_Langue
         LEFT JOIN tblGENE_Traductions T2 ON T2.vcNom_Table = 'tblIQEE_TypesEnregistrement'
                                         AND T2.vcNom_Champ = 'vcDescription'
                                         AND T2.iID_Enregistrement = TE.tiID_Type_Enregistrement
                                         AND T2.vcID_Langue = @cID_Langue
         LEFT JOIN tblGENE_Traductions T3 ON T3.vcNom_Table = 'tblIQEE_SousTypeEnregistrement'
                                         AND T3.vcNom_Champ = 'vcDescription'
                                         AND T3.iID_Enregistrement = ST.iID_Sous_Type
                                         AND T3.vcID_Langue = @cID_Langue
         LEFT JOIN tblGENE_Traductions T4 ON T4.vcNom_Table = 'tblIQEE_Validations'
                                         AND T4.vcNom_Champ = 'vcDescription'
                                         AND T4.iID_Enregistrement = V.iID_Validation
                                         AND T4.vcID_Langue = @cID_Langue
         LEFT JOIN tblGENE_Traductions T5 ON T5.vcNom_Table = 'tblIQEE_CategoriesElements'
                                         AND T5.vcNom_Champ = 'vcDescription'
                                         AND T5.iID_Enregistrement = CE.tiID_Categorie_Element
                                         AND T5.vcID_Langue = @cID_Langue
         LEFT JOIN tblGENE_Traductions T6 ON T6.vcNom_Table = 'tblIQEE_CategoriesErreur'
                                         AND T6.vcNom_Champ = 'vcDescription'
                                         AND T6.iID_Enregistrement = CA.tiID_Categorie_Erreur
                                         AND T6.vcID_Langue = @cID_Langue
         LEFT JOIN tblGENE_Traductions T7 ON T7.vcNom_Table = 'tblIQEE_Validations'
                                         AND T7.vcNom_Champ = 'vcDescription_Valeur_Erreur'
                                         AND T7.iID_Enregistrement = V.iID_Validation
                                         AND T7.vcID_Langue = @cID_Langue
         LEFT JOIN tblGENE_Traductions T8 ON T8.vcNom_Table = 'tblIQEE_Validations'
                                         AND T8.vcNom_Champ = 'vcDescription_Valeur_Reference'
                                         AND T8.iID_Enregistrement = V.iID_Validation
                                         AND T8.vcID_Langue = @cID_Langue
    WHERE ((@bAfficher_Rejets_Convention_Selectionnees IS NULL
            AND    CR.iID_Rejet IS NOT NULL)
        OR (@bAfficher_Rejets_Convention_Selectionnees = 1
            AND EXISTS (SELECT *
                        FROM #tblIQEE_ConventionsRejets CR1
                        WHERE CR1.iID_Convention = R.iID_Convention
                          AND CR1.siAnnee_Fiscale = R.siAnnee_Fiscale)))
    ORDER BY C.ConventionNo,R.siAnnee_Fiscale,F.dtDate_Creation,TE.cCode_Type_Enregistrement,ST.cCode_Sous_Type, V.iOrdre_Presentation

    DROP TABLE #tblIQEE_ConventionsRejets
END
