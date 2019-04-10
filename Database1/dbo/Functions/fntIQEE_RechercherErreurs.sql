/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service :   fntIQEE_RechercherErreurs
Nom du service  :   Rechercher les erreurs 
But             :   Rechercher à travers les erreurs de l’IQÉÉ et obtenir les informations des erreurs.
Facette         :   IQÉÉ

Paramètres d’entrée :
    Paramètre                       Description
    ----------------------------    -----------------------------------------------------------------
    cID_Langue                      Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
                                    Le français est la langue par défaut si elle n’est pas spécifiée.
    iID_Erreur                      Identifiant unique de l’erreur de l’IQÉÉ.  S’il est vide, toutes les erreurs sont considérées.
    tiID_Type_Enregistrement        Identifiant du type d’enregistrement relié à l’erreur.  S’il est vide, tous les types d’enregistrement sont considérés.
    iID_Enregistrement              Identifiant d’un enregistrement relié à l’erreur.  S’il est vide, tous les enregistrements sont considérés.
    iID_Convention                  Identifiant unique de la convention relié à l’erreur.  S’il est vide, toutes les conventions sont considérées.
    vcNo_Convention                 Numéro de la convention relié à l’erreur.  S’il est vide, toutes les conventions sont considérées.
    tiID_Categorie_Erreur           Identifiant unique d’une catégorie d’erreur.  S’il est vide, toutes les catégories sont considérées.
    siCode_Erreur                   Identifiant unique du type d’erreur. S’il est vide, tous les types d’erreur sont considérés.
    siAnnee_Fiscale                 Année fiscale du fichier d’où provient l’erreur.  Si elle est vide, toutes les années sont considérées.
    iID_Fichier_IQEE                Identifiant du fichier d’où provient l’erreur.  Si elle est vide, tous les fichiers sont considérés.
    tiID_Statuts_Erreur             Identifiant du statut de l’erreur.  S’il est vide, tous les statuts sont considérés.
    vcCommentaires                  Partie de commentaire.  S’il est vide, tous les types de commentaires sont considérés.

Exemple d’appel :
    SELECT * FROM dbo.fntIQEE_RechercherErreurs(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)

Paramètres de sortie :  Tous les champs de la table « tblIQEE_Erreurs » en plus des champs suivants.

    Champ                           Description
    ----------------------------    ---------------------------------
    iID_Erreur
    iID_Fichier_IQEE
    tiID_Categorie_Erreur           Identifiant de la catégorie de l’erreur.
    siCode_Erreur                   Code du type d’erreur RQ.
    tiID_Type_Enregistrement
    tiID_Statuts_Erreur
    vcElement_Erreur
    vcValeur_Erreur
    tCommentaires
    iID_Utilisateur_Modification
    dtDate_Modification
    vcUtilisateur_Modification
    iID_Convention                  Identifiant de la convention 
    vcNo_Convention                 Numéro de la convention relié à l'erreur
    iID_Enregistrement              Identifiant de l’enregistrement relié à l’erreur recherchée.
    vcType_Enregistrement           Description du type d’enregistrement en erreur.
    vcType_ErreurRQ                 Description du type d’erreur RQ.
    cCode_Type_Enregistrement       Code du type d'enregistrement en erreur.
    bInd_Modifiable_Utilisateur     
    iID_Utilisateur_Traite
    dtDate_Traite 
    vcUtilisateur_Traite 
    dtDate_Transaction              Date de la transaction en erreur.
    iID_Souscripteur                Identifiant du souscripteur de la transaction en erreur.
    iID_Beneficiaire                Identifiant du bénéficiaire de la transaction en erreur.
    iID_Ancien_Beneficiaire         Identifiant du nouveau bénéficiaire de la transaction en erreur.
    cCode_Sous_Type                 Code de sous-type d'enregistrement de la transaction en erreur.
    vcDescription_Sous_Type         Description du sous-type d'enregistrement de la transaction en erreur.
    tiCode_Version                  Code de version de la transaction en erreur.
    vcDescription_Version           Description de la version de la transaction en erreur.

Historique des modifications:
    Date        Programmeur         Description
    ----------  ----------------    ----------------------------------------------------------------
    2008-10-06  Éric Deshaies       Création du service                            
    2008-10-22  Patrice Péau        Rajout des parametres de sorties ( vcType_Enregistrement, vcType_ErreurRQ, siCode_Erreur )                             
    2009-02-10  Éric Deshaies       Ajout du champ "tblIQEE_TypesEnregistrement.cCode_Type_Enregistrement"
    2009-03-18  Éric Deshaies       Lire les erreurs de tous les types d'enregistrement et changer le préfixe du service
    2009-04-16  Éric Deshaies       Ajouter le champ "bInd_Modifiable_Utilisateur" à la sortie
    2010-07-22  Éric Deshaies       Associer les erreurs sur les transactions d'annulation à la catégorie des erreurs informatiques
    2010-08-03  Éric Deshaies       Mise à niveau sur la traduction des champs
    2010-08-15  Éric Deshaies       Création d'une nouvelle catégorie pour les erreurs par association
    2010-08-30  Éric Deshaies       Ajout de champs pour des modifications à l'application Web.
    2011-01-04  Éric Deshaies       Correction d'une erreur d'exécution parce que l'erreur ne pouvait pas être associée à une catégorie d'erreur. 
    2014-01-03  Stéphane Barbeau    Diviser la requête d'origine pour avoir des résultats de chaque type de transaction.
    2014-09-09  Stéphane Barbeau    Table @tblIQEE_Erreurs: Ajustement de la taille de vcType_ErreurRQ pour être de la même que vcDescription dans la table tblIQEE_TypesErreurRQ.
    2018-02-08  Steeve Picard       Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
    2018-06-06  Steeve Picard       Modificiation de la gestion des retours d'erreur par RQ
****************************************************************************************************/
CREATE FUNCTION dbo.fntIQEE_RechercherErreurs
(
    @cID_Langue CHAR(3),
    @iID_Erreur INT,
    @tiID_Type_Enregistrement TINYINT,
    @iID_Enregistrement INT,
    @iID_Convention INT,
    @vcNo_Convention VARCHAR(15),
    @tiID_Categorie_Erreur TINYINT,
    @siCode_Erreur SMALLINT,
    @siAnnee_Fiscale SMALLINT,
    @iID_Fichier_IQEE INT,
    @tiID_Statuts_Erreur TINYINT,
    @vcCommentaires VARCHAR(75)
)
RETURNS @tblIQEE_Erreurs TABLE
(
    iID_Erreur INT NOT NULL,
    iID_Fichier_IQEE INT NOT NULL,
    tiID_Categorie_Erreur TINYINT NOT NULL,
    siCode_Erreur SMALLINT NOT NULL,
    tiID_Type_Enregistrement SMALLINT NULL,
    tiID_Statuts_Erreur TINYINT NOT NULL,
    vcElement_Erreur VARCHAR(30) NULL,
    vcValeur_Erreur VARCHAR(40) NULL,
    tCommentaires TEXT NULL,
    iID_Utilisateur_Modification INT NULL,
    dtDate_Modification DATETIME NULL,
    vcUtilisateur_Modification VARCHAR(50) NULL,
    iID_Convention INT NULL,
    vcNo_Convention VARCHAR(15) NULL,
    iID_Enregistrement INT NULL,
    vcType_Enregistrement VARCHAR(100) NULL,
    vcType_ErreurRQ VARCHAR(500) NOT NULL,
    cCode_Type_Enregistrement CHAR(2) NULL,
    bInd_Modifiable_Utilisateur BIT NOT NULL,
    iID_Utilisateur_Traite INT NULL,
    dtDate_Traite DATETIME NULL,
    vcUtilisateur_Traite VARCHAR(50) NULL,
    dtDate_Transaction DATETIME NULL,
    iID_Souscripteur INT NULL,
    iID_Beneficiaire INT NULL,
    iID_Ancien_Beneficiaire INT NULL,
    cCode_Sous_Type CHAR(2) NULL,
    vcDescription_Sous_Type VARCHAR(200) NULL,
    tiCode_Version TINYINT NULL,
    vcDescription_Version VARCHAR(20) NULL
)
AS
BEGIN
    -- Considérer le français comme la langue par défaut
    IF @cID_Langue IS NULL
        SET @cID_Langue = 'FRA'

    -- Si les valeurs numériques sont à 0, c'est comme si elle n'étaient pas présente
    IF @iID_Fichier_IQEE = 0
        SET @iID_Fichier_IQEE = NULL

    IF @siAnnee_Fiscale = 0
        SET @siAnnee_Fiscale = NULL

    IF @iID_Erreur = 0
        SET @iID_Erreur = NULL

    IF @tiID_Type_Enregistrement = 0
        SET @tiID_Type_Enregistrement = NULL

    IF @iID_Enregistrement = 0
        SET @iID_Enregistrement = NULL

    IF @iID_Convention = 0
        SET @iID_Convention = NULL

    IF @tiID_Categorie_Erreur = 0
        SET @tiID_Categorie_Erreur = NULL

    IF @siCode_Erreur = 0
        SET @siCode_Erreur = NULL
    
    IF @tiID_Statuts_Erreur = 0
        SET @tiID_Statuts_Erreur = NULL

    --select @cCode_Type_Enregistrement=cCode_Type_Enregistrement FROM dbo.tblIQEE_TypesEnregistrement where  tiID_Type_Enregistrement=@tiID_Type_Enregistrement

    Declare @cCode_Type_Enregistrement char(2)

    IF @tiID_Type_Enregistrement is not null
        SELECT @cCode_Type_Enregistrement = cCode_Type_Enregistrement 
          FROM dbo.tblIQEE_TypesEnregistrement 
         WHERE tiID_Type_Enregistrement = @tiID_Type_Enregistrement

    BEGIN 
        IF ISNULL(@cCode_Type_Enregistrement, '02') ='02' 
        BEGIN
            -- Rechercher les erreurs de RQ selon les critères de recherche
            INSERT INTO @tblIQEE_Erreurs (
                iID_Erreur, iID_Fichier_IQEE, tiID_Categorie_Erreur, siCode_Erreur, tiID_Type_Enregistrement,
                tiID_Statuts_Erreur, vcElement_Erreur, vcValeur_Erreur, tCommentaires,
                iID_Utilisateur_Modification, dtDate_Modification, vcUtilisateur_Modification,
                iID_Convention, vcNo_Convention,
                iID_Enregistrement, vcType_Enregistrement,
                vcType_ErreurRQ, cCode_Type_Enregistrement,
                bInd_Modifiable_Utilisateur, iID_Utilisateur_Traite, dtDate_Traite, vcUtilisateur_Traite,
                dtDate_Transaction, iID_Souscripteur, iID_Beneficiaire, iID_Ancien_Beneficiaire,
                cCode_Sous_Type, vcDescription_Sous_Type, tiCode_Version, vcDescription_Version
            )
            SELECT 
                E.iID_Erreur, E.iID_Fichier_IQEE,            
                    CASE WHEN D.tiCode_Version = 1 AND CEB.vcCode_Categorie <> 'TI2' THEN 
                              CASE WHEN CEB.vcCode_Categorie = 'OPE' THEN CE2.tiID_Categorie_Erreur ELSE CE.tiID_Categorie_Erreur END
                         ELSE TER.tiID_Categorie_Erreur END AS tiID_Categorie_Erreur,
                    E.siCode_Erreur, E.tiID_Type_Enregistrement,
                E.tiID_Statuts_Erreur, E.vcElement_Erreur, E.vcValeur_Erreur, E.tCommentaires,
                E.iID_Utilisateur_Modification, E.dtDate_Modification, U1.FirstName + ' ' + U1.LastName,
                D.iID_Convention, D.vcNo_Convention,
                E.iID_Enregistrement, TE.vcDescription,
                TER.vcDescription, TE.cCode_Type_Enregistrement,
                SE.bInd_Modifiable_Utilisateur, E.iID_Utilisateur_Traite, E.dtDate_Traite, U2.FirstName + ' ' + U2.LastName AS vcUtilisateur_Traite,
                CAST(CAST(D.siAnnee_Fiscale AS VARCHAR(4))+'-12-31' AS DATETIME), D.iID_Souscripteur, D.iID_Beneficiaire_31decembre, NULL,
                NULL, NULL, D.tiCode_Version, VT.vcDescription
            FROM 
                dbo.tblIQEE_Erreurs E
                JOIN dbo.tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement                
                JOIN dbo.tblIQEE_TypesErreurRQ TER ON TER.siCode_Erreur = E.siCode_Erreur
                JOIN dbo.tblIQEE_CategoriesErreur CE ON CE.vcCode_Categorie = 'TI'
                JOIN dbo.tblIQEE_CategoriesErreur CE2 ON CE2.vcCode_Categorie = 'TI2'
                JOIN dbo.tblIQEE_CategoriesErreur CEB ON CEB.tiID_Categorie_Erreur = TER.tiID_Categorie_Erreur
                JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E.iID_Fichier_IQEE
                JOIN dbo.tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                LEFT JOIN dbo.tblIQEE_Demandes D ON D.iID_Demande_IQEE = E.iID_Enregistrement
                LEFT JOIN dbo.tblIQEE_VersionsTransaction VT ON VT.tiCode_Version = D.tiCode_Version
                LEFT JOIN dbo.Mo_Human U1 ON U1.HumanID = E.iID_Utilisateur_Modification
                LEFT JOIN dbo.Mo_Human U2 ON U2.HumanID = E.iID_Utilisateur_Traite
            WHERE 
                TER.bInd_Erreur_Grave = 0
                AND TE.cCode_Type_Enregistrement = '02' 
                AND ( @iID_Erreur IS NULL OR E.iID_Erreur = @iID_Erreur ) 
                AND ( @siCode_Erreur IS NULL OR E.siCode_Erreur = @siCode_Erreur ) 
                AND ( @tiID_Statuts_Erreur IS NULL OR E.tiID_Statuts_Erreur = @tiID_Statuts_Erreur ) 
                AND ( @iID_Fichier_IQEE IS NULL OR E.iID_Fichier_IQEE = @iID_Fichier_IQEE ) 
                AND ( @tiID_Categorie_Erreur IS NULL 
                      OR CASE WHEN D.tiCode_Version = 1 AND CEB.vcCode_Categorie <> 'TI2' THEN 
                                   CASE WHEN CEB.vcCode_Categorie = 'OPE' THEN CE2.tiID_Categorie_Erreur ELSE CE.tiID_Categorie_Erreur END
                              ELSE TER.tiID_Categorie_Erreur
                         END = @tiID_Categorie_Erreur
                    ) 
                AND ( @vcCommentaires IS NULL OR E.tCommentaires LIKE '%'+@vcCommentaires+'%') 
                AND ( @tiID_Type_Enregistrement IS NULL OR E.tiID_Type_Enregistrement = @tiID_Type_Enregistrement ) 
                AND ( @siAnnee_Fiscale IS NULL OR D.siAnnee_Fiscale = @siAnnee_Fiscale ) 
                AND ( @iID_Enregistrement IS NULL OR E.iID_Enregistrement = @iID_Enregistrement ) 
                AND ( @iID_Convention IS NULL OR D.iID_Convention = @iID_Convention ) 
                AND ( @vcNo_Convention IS NULL OR D.vcNo_Convention = @vcNo_Convention )
            ORDER BY 
                D.vcNo_Convention, E.siCode_Erreur
        END

        IF ISNULL(@cCode_Type_Enregistrement, '03') = '03' 
        BEGIN
            -- Rechercher les erreurs de RQ selon les critères de recherche
            INSERT INTO @tblIQEE_Erreurs (
                iID_Erreur, iID_Fichier_IQEE, tiID_Categorie_Erreur, siCode_Erreur, tiID_Type_Enregistrement,
                tiID_Statuts_Erreur, vcElement_Erreur, vcValeur_Erreur, tCommentaires,
                iID_Utilisateur_Modification, dtDate_Modification, vcUtilisateur_Modification,
                iID_Convention, vcNo_Convention,
                iID_Enregistrement, vcType_Enregistrement,
                vcType_ErreurRQ, cCode_Type_Enregistrement,
                bInd_Modifiable_Utilisateur, iID_Utilisateur_Traite, dtDate_Traite, vcUtilisateur_Traite,
                dtDate_Transaction, iID_Souscripteur, iID_Beneficiaire, iID_Ancien_Beneficiaire,
                cCode_Sous_Type, vcDescription_Sous_Type, tiCode_Version, vcDescription_Version
            )
            SELECT 
                E.iID_Erreur, E.iID_Fichier_IQEE,            
                    CASE WHEN RB.tiCode_Version = 1 AND CEB.vcCode_Categorie <> 'TI2' THEN 
                              CASE WHEN CEB.vcCode_Categorie = 'OPE' THEN CE2.tiID_Categorie_Erreur ELSE CE.tiID_Categorie_Erreur END
                         ELSE TER.tiID_Categorie_Erreur
                    END AS tiID_Categorie_Erreur,
                    E.siCode_Erreur, E.tiID_Type_Enregistrement,
                E.tiID_Statuts_Erreur, E.vcElement_Erreur, E.vcValeur_Erreur, E.tCommentaires,
                E.iID_Utilisateur_Modification, E.dtDate_Modification, U1.FirstName + ' ' + U1.LastName,
                RB.iID_Convention, RB.vcNo_Convention,
                E.iID_Enregistrement, TE.vcDescription,
                TER.vcDescription, TE.cCode_Type_Enregistrement,
                SE.bInd_Modifiable_Utilisateur, E.iID_Utilisateur_Traite, E.dtDate_Traite, U2.FirstName + ' ' + U2.LastName AS vcUtilisateur_Traite,
                RB.dtDate_Remplacement, NULL, RB.iID_Nouveau_Beneficiaire, RB.iID_Ancien_Beneficiaire,
                NULL, NULL, RB.tiCode_Version, VT.vcDescription
            FROM 
                dbo.tblIQEE_Erreurs E
                JOIN dbo.tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement                
                JOIN dbo.tblIQEE_TypesErreurRQ TER ON TER.siCode_Erreur = E.siCode_Erreur
                JOIN dbo.tblIQEE_CategoriesErreur CE ON CE.vcCode_Categorie = 'TI'
                JOIN dbo.tblIQEE_CategoriesErreur CE2 ON CE2.vcCode_Categorie = 'TI2'
                JOIN dbo.tblIQEE_CategoriesErreur CEB ON CEB.tiID_Categorie_Erreur = TER.tiID_Categorie_Erreur
                JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E.iID_Fichier_IQEE
                JOIN dbo.tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                LEFT JOIN dbo.tblIQEE_RemplacementsBeneficiaire RB ON RB.iID_Remplacement_Beneficiaire = E.iID_Enregistrement
                LEFT JOIN dbo.tblIQEE_VersionsTransaction VT ON VT.tiCode_Version = RB.tiCode_Version
                LEFT JOIN dbo.Mo_Human U1 ON U1.HumanID = E.iID_Utilisateur_Modification
                LEFT JOIN dbo.Mo_Human U2 ON U2.HumanID = E.iID_Utilisateur_Traite
            WHERE 
                ( @iID_Erreur IS NULL OR E.iID_Erreur = @iID_Erreur )
                AND TE.cCode_Type_Enregistrement = '03'
                AND TER.bInd_Erreur_Grave = 0  
                AND ( @siCode_Erreur IS NULL OR E.siCode_Erreur = @siCode_Erreur ) 
                AND ( @tiID_Statuts_Erreur IS NULL OR E.tiID_Statuts_Erreur = @tiID_Statuts_Erreur ) 
                AND ( @iID_Fichier_IQEE IS NULL OR E.iID_Fichier_IQEE = @iID_Fichier_IQEE ) 
                AND ( @tiID_Categorie_Erreur IS NULL 
                      OR CASE WHEN RB.tiCode_Version = 1 AND CEB.vcCode_Categorie <> 'TI2' THEN 
                                   CASE WHEN CEB.vcCode_Categorie = 'OPE' THEN CE2.tiID_Categorie_Erreur ELSE CE.tiID_Categorie_Erreur END
                              ELSE TER.tiID_Categorie_Erreur
                         END = @tiID_Categorie_Erreur
                    ) 
                AND ( @vcCommentaires IS NULL OR E.tCommentaires LIKE '%'+@vcCommentaires+'%') 
                AND ( @tiID_Type_Enregistrement IS NULL OR E.tiID_Type_Enregistrement = @tiID_Type_Enregistrement ) 
                AND ( @siAnnee_Fiscale IS NULL OR RB.siAnnee_Fiscale = @siAnnee_Fiscale ) 
                AND ( @iID_Enregistrement IS NULL OR E.iID_Enregistrement = @iID_Enregistrement ) 
                AND ( @iID_Convention IS NULL OR RB.iID_Convention = @iID_Convention ) 
                AND ( @vcNo_Convention IS NULL OR RB.vcNo_Convention = @vcNo_Convention )
            ORDER BY 
                RB.vcNo_Convention, TER.siCode_Erreur
        END                    

        IF ISNULL(@cCode_Type_Enregistrement, '04') = '04' 
        BEGIN
            INSERT INTO @tblIQEE_Erreurs (
                iID_Erreur, iID_Fichier_IQEE, tiID_Categorie_Erreur, siCode_Erreur, tiID_Type_Enregistrement,
                tiID_Statuts_Erreur, vcElement_Erreur, vcValeur_Erreur, tCommentaires,
                iID_Utilisateur_Modification, dtDate_Modification, vcUtilisateur_Modification,
                iID_Convention, vcNo_Convention,
                iID_Enregistrement, vcType_Enregistrement,
                vcType_ErreurRQ, cCode_Type_Enregistrement,
                bInd_Modifiable_Utilisateur, iID_Utilisateur_Traite, dtDate_Traite, vcUtilisateur_Traite,
                dtDate_Transaction, iID_Souscripteur, iID_Beneficiaire, iID_Ancien_Beneficiaire,
                cCode_Sous_Type, vcDescription_Sous_Type, tiCode_Version, vcDescription_Version
            )
            SELECT 
                E.iID_Erreur, E.iID_Fichier_IQEE,            
                    CASE WHEN T.tiCode_Version = 1 AND CEB.vcCode_Categorie <> 'TI2' THEN 
                              CASE WHEN CEB.vcCode_Categorie = 'OPE' THEN CE2.tiID_Categorie_Erreur ELSE CE.tiID_Categorie_Erreur END
                         ELSE TER.tiID_Categorie_Erreur END AS tiID_Categorie_Erreur,
                    E.siCode_Erreur, E.tiID_Type_Enregistrement,
                E.tiID_Statuts_Erreur, E.vcElement_Erreur, E.vcValeur_Erreur, E.tCommentaires,
                E.iID_Utilisateur_Modification, E.dtDate_Modification, U1.FirstName + ' ' + U1.LastName,
                T.iID_Convention, T.vcNo_Convention,
                E.iID_Enregistrement, TE.vcDescription,
                TER.vcDescription, TE.cCode_Type_Enregistrement,
                SE.bInd_Modifiable_Utilisateur, E.iID_Utilisateur_Traite, E.dtDate_Traite, U2.FirstName + ' ' + U2.LastName AS vcUtilisateur_Traite,
                T.dtDate_Transfert, T.iID_Souscripteur, T.iID_Beneficiaire, NULL,
                ST.cCode_Sous_Type, ST.vcDescription, T.tiCode_Version, VT.vcDescription
            FROM 
                dbo.tblIQEE_Erreurs E
                JOIN dbo.tblIQEE_TypesErreurRQ TER ON TER.siCode_Erreur = E.siCode_Erreur
                JOIN dbo.tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement                
                JOIN dbo.tblIQEE_CategoriesErreur CE ON CE.vcCode_Categorie = 'TI'
                JOIN dbo.tblIQEE_CategoriesErreur CE2 ON CE2.vcCode_Categorie = 'TI2'
                JOIN dbo.tblIQEE_CategoriesErreur CEB ON CEB.tiID_Categorie_Erreur = TER.tiID_Categorie_Erreur
                JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E.iID_Fichier_IQEE
                JOIN dbo.tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                LEFT JOIN dbo.tblIQEE_Transferts T ON T.iID_Transfert = E.iID_Enregistrement
                LEFT JOIN dbo.tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = T.iID_Sous_Type
                LEFT JOIN dbo.tblIQEE_VersionsTransaction VT ON VT.tiCode_Version = T.tiCode_Version
                LEFT JOIN dbo.Mo_Human U1 ON U1.HumanID = E.iID_Utilisateur_Modification
                LEFT JOIN dbo.Mo_Human U2 ON U2.HumanID = E.iID_Utilisateur_Traite
            WHERE 
                ( @iID_Erreur IS NULL OR E.iID_Erreur = @iID_Erreur ) 
                AND TE.cCode_Type_Enregistrement = '04'
                AND TER.bInd_Erreur_Grave = 0
                AND ( @siCode_Erreur IS NULL OR E.siCode_Erreur = @siCode_Erreur ) 
                AND ( @tiID_Statuts_Erreur IS NULL OR E.tiID_Statuts_Erreur = @tiID_Statuts_Erreur ) 
                AND ( @iID_Fichier_IQEE IS NULL OR E.iID_Fichier_IQEE = @iID_Fichier_IQEE ) 
                AND ( @tiID_Categorie_Erreur IS NULL 
                      OR CASE WHEN T.tiCode_Version = 1 AND CEB.vcCode_Categorie <> 'TI2' THEN 
                                   CASE WHEN CEB.vcCode_Categorie = 'OPE' THEN CE2.tiID_Categorie_Erreur ELSE CE.tiID_Categorie_Erreur END
                              ELSE TER.tiID_Categorie_Erreur
                         END = @tiID_Categorie_Erreur
                    ) 
                AND ( @vcCommentaires IS NULL OR E.tCommentaires LIKE '%'+@vcCommentaires+'%') 
                AND ( @tiID_Type_Enregistrement IS NULL OR E.tiID_Type_Enregistrement = @tiID_Type_Enregistrement ) 
                AND ( @siAnnee_Fiscale IS NULL OR T.siAnnee_Fiscale = @siAnnee_Fiscale ) 
                AND ( @iID_Enregistrement IS NULL OR E.iID_Enregistrement = @iID_Enregistrement ) 
                AND ( @iID_Convention IS NULL OR T.iID_Convention = @iID_Convention ) 
                AND ( @vcNo_Convention IS NULL OR T.vcNo_Convention = @vcNo_Convention )
            ORDER BY 
                T.vcNo_Convention, TER.siCode_Erreur
        END
        
        IF ISNULL(@cCode_Type_Enregistrement, '05') = '05' 
        BEGIN
            INSERT INTO @tblIQEE_Erreurs (
                iID_Erreur, iID_Fichier_IQEE, tiID_Categorie_Erreur, siCode_Erreur, tiID_Type_Enregistrement,
                tiID_Statuts_Erreur, vcElement_Erreur, vcValeur_Erreur, tCommentaires,
                iID_Utilisateur_Modification, dtDate_Modification, vcUtilisateur_Modification,
                iID_Convention, vcNo_Convention,
                iID_Enregistrement, vcType_Enregistrement,
                vcType_ErreurRQ, cCode_Type_Enregistrement,
                bInd_Modifiable_Utilisateur, iID_Utilisateur_Traite, dtDate_Traite, vcUtilisateur_Traite,
                dtDate_Transaction, iID_Souscripteur, iID_Beneficiaire, iID_Ancien_Beneficiaire,
                cCode_Sous_Type, vcDescription_Sous_Type, tiCode_Version, vcDescription_Version
            )
            SELECT 
                E.iID_Erreur, E.iID_Fichier_IQEE,            
                    CASE WHEN PB.tiCode_Version = 1 AND CEB.vcCode_Categorie <> 'TI2' THEN 
                              CASE WHEN CEB.vcCode_Categorie = 'OPE' THEN CE2.tiID_Categorie_Erreur ELSE CE.tiID_Categorie_Erreur END
                         ELSE TER.tiID_Categorie_Erreur END AS tiID_Categorie_Erreur,
                    E.siCode_Erreur, E.tiID_Type_Enregistrement,
                E.tiID_Statuts_Erreur, E.vcElement_Erreur, E.vcValeur_Erreur, E.tCommentaires,
                E.iID_Utilisateur_Modification, E.dtDate_Modification, U1.FirstName + ' ' + U1.LastName,
                PB.iID_Convention, PB.vcNo_Convention,
                E.iID_Enregistrement, TE.vcDescription,
                TER.vcDescription, TE.cCode_Type_Enregistrement,
                SE.bInd_Modifiable_Utilisateur, E.iID_Utilisateur_Traite, E.dtDate_Traite, U2.FirstName + ' ' + U2.LastName AS vcUtilisateur_Traite,
                PB.dtDate_Paiement, NULL, PB.iID_Beneficiaire, NULL,
                ST.cCode_Sous_Type, ST.vcDescription, PB.tiCode_Version, VT.vcDescription
            FROM 
                dbo.tblIQEE_Erreurs E
                JOIN dbo.tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement                
                JOIN dbo.tblIQEE_TypesErreurRQ TER ON TER.siCode_Erreur = E.siCode_Erreur
                JOIN dbo.tblIQEE_CategoriesErreur CE ON CE.vcCode_Categorie = 'TI'
                JOIN dbo.tblIQEE_CategoriesErreur CE2 ON CE2.vcCode_Categorie = 'TI2'
                JOIN dbo.tblIQEE_CategoriesErreur CEB ON CEB.tiID_Categorie_Erreur = TER.tiID_Categorie_Erreur
                JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E.iID_Fichier_IQEE
                JOIN dbo.tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                LEFT JOIN dbo.tblIQEE_PaiementsBeneficiaires PB ON PB.iID_Paiement_Beneficiaire = E.iID_Enregistrement
                LEFT JOIN dbo.tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = PB.iID_Sous_Type
                LEFT JOIN dbo.tblIQEE_VersionsTransaction VT ON VT.tiCode_Version = PB.tiCode_Version
                LEFT JOIN dbo.Mo_Human U1 ON U1.HumanID = E.iID_Utilisateur_Modification
                LEFT JOIN dbo.Mo_Human U2 ON U2.HumanID = E.iID_Utilisateur_Traite
            WHERE 
                ( @iID_Erreur IS NULL OR E.iID_Erreur = @iID_Erreur ) 
                AND TE.cCode_Type_Enregistrement = '05'
                AND TER.bInd_Erreur_Grave = 0
                AND ( @siCode_Erreur IS NULL OR E.siCode_Erreur = @siCode_Erreur ) 
                AND ( @tiID_Statuts_Erreur IS NULL OR E.tiID_Statuts_Erreur = @tiID_Statuts_Erreur ) 
                AND ( @iID_Fichier_IQEE IS NULL OR E.iID_Fichier_IQEE = @iID_Fichier_IQEE ) 
                AND ( @tiID_Categorie_Erreur IS NULL 
                      OR CASE WHEN PB.tiCode_Version = 1 AND CEB.vcCode_Categorie <> 'TI2' THEN 
                                   CASE WHEN CEB.vcCode_Categorie = 'OPE' THEN CE2.tiID_Categorie_Erreur ELSE CE.tiID_Categorie_Erreur END
                              ELSE TER.tiID_Categorie_Erreur
                         END = @tiID_Categorie_Erreur
                    ) 
                AND ( @vcCommentaires IS NULL OR E.tCommentaires LIKE '%'+@vcCommentaires+'%') 
                AND ( @tiID_Type_Enregistrement IS NULL OR E.tiID_Type_Enregistrement = @tiID_Type_Enregistrement ) 
                AND ( @siAnnee_Fiscale IS NULL OR PB.siAnnee_Fiscale = @siAnnee_Fiscale ) 
                AND ( @iID_Enregistrement IS NULL OR E.iID_Enregistrement = @iID_Enregistrement ) 
                AND ( @iID_Convention IS NULL OR PB.iID_Convention = @iID_Convention ) 
                AND ( @vcNo_Convention IS NULL OR PB.vcNo_Convention = @vcNo_Convention )
            ORDER BY 
                PB.vcNo_Convention, TER.siCode_Erreur
        END        

        IF ISNULL(@cCode_Type_Enregistrement, '06') = '06'  
        BEGIN
            INSERT INTO @tblIQEE_Erreurs (
                iID_Erreur, iID_Fichier_IQEE, tiID_Categorie_Erreur, siCode_Erreur, tiID_Type_Enregistrement,
                tiID_Statuts_Erreur, vcElement_Erreur, vcValeur_Erreur, tCommentaires,
                iID_Utilisateur_Modification, dtDate_Modification, vcUtilisateur_Modification,
                iID_Convention, vcNo_Convention,
                iID_Enregistrement, vcType_Enregistrement,
                vcType_ErreurRQ, cCode_Type_Enregistrement,
                bInd_Modifiable_Utilisateur, iID_Utilisateur_Traite, dtDate_Traite, vcUtilisateur_Traite,
                dtDate_Transaction, iID_Souscripteur, iID_Beneficiaire, iID_Ancien_Beneficiaire,
                cCode_Sous_Type, vcDescription_Sous_Type, tiCode_Version, vcDescription_Version
            )
            SELECT 
                E.iID_Erreur, E.iID_Fichier_IQEE,            
                    CASE WHEN I.tiCode_Version = 1 AND CEB.vcCode_Categorie <> 'TI2' THEN 
                            CASE WHEN CEB.vcCode_Categorie = 'OPE' THEN CE2.tiID_Categorie_Erreur ELSE CE.tiID_Categorie_Erreur END
                         ELSE TER.tiID_Categorie_Erreur END AS tiID_Categorie_Erreur,
                    E.siCode_Erreur, E.tiID_Type_Enregistrement,
                E.tiID_Statuts_Erreur, E.vcElement_Erreur, E.vcValeur_Erreur, E.tCommentaires,
                E.iID_Utilisateur_Modification, E.dtDate_Modification, U1.FirstName + ' ' + U1.LastName,
                I.iID_Convention, I.vcNo_Convention,
                E.iID_Enregistrement, TE.vcDescription,
                TER.vcDescription, TE.cCode_Type_Enregistrement,
                SE.bInd_Modifiable_Utilisateur, E.iID_Utilisateur_Traite, E.dtDate_Traite, U2.FirstName + ' ' + U2.LastName AS vcUtilisateur_Traite,
                I.dtDate_Evenement, NULL, I.iID_Beneficiaire, NULL,
                ST.cCode_Sous_Type, ST.vcDescription, I.tiCode_Version, VT.vcDescription
            FROM 
                dbo.tblIQEE_Erreurs E
                JOIN dbo.tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement                
                JOIN dbo.tblIQEE_TypesErreurRQ TER ON TER.siCode_Erreur = E.siCode_Erreur
                JOIN dbo.tblIQEE_CategoriesErreur CE ON CE.vcCode_Categorie = 'TI'
                JOIN dbo.tblIQEE_CategoriesErreur CE2 ON CE2.vcCode_Categorie = 'TI2'
                JOIN dbo.tblIQEE_CategoriesErreur CEB ON CEB.tiID_Categorie_Erreur = TER.tiID_Categorie_Erreur
                JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = E.iID_Fichier_IQEE
                JOIN dbo.tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                LEFT JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Impot_Special = E.iID_Enregistrement
                LEFT JOIN dbo.tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = I.iID_Sous_Type
                LEFT JOIN dbo.tblIQEE_VersionsTransaction VT ON VT.tiCode_Version = I.tiCode_Version
                LEFT JOIN dbo.Mo_Human U1 ON U1.HumanID = E.iID_Utilisateur_Modification
                LEFT JOIN dbo.Mo_Human U2 ON U2.HumanID = E.iID_Utilisateur_Traite
            WHERE 
                ( @iID_Erreur IS NULL OR E.iID_Erreur = @iID_Erreur ) 
                AND TE.cCode_Type_Enregistrement = '06'
                AND TER.bInd_Erreur_Grave = 0
                AND ( @siCode_Erreur IS NULL OR E.siCode_Erreur = @siCode_Erreur ) 
                AND ( @tiID_Statuts_Erreur IS NULL OR E.tiID_Statuts_Erreur = @tiID_Statuts_Erreur ) 
                AND ( @iID_Fichier_IQEE IS NULL OR E.iID_Fichier_IQEE = @iID_Fichier_IQEE ) 
                AND ( @tiID_Categorie_Erreur IS NULL 
                      OR CASE WHEN I.tiCode_Version = 1 AND CEB.vcCode_Categorie <> 'TI2' THEN 
                                   CASE WHEN CEB.vcCode_Categorie = 'OPE' THEN CE2.tiID_Categorie_Erreur ELSE CE.tiID_Categorie_Erreur END
                              ELSE TER.tiID_Categorie_Erreur
                         END = @tiID_Categorie_Erreur
                    ) 
                AND ( @vcCommentaires IS NULL OR E.tCommentaires LIKE '%'+@vcCommentaires+'%') 
                AND ( @tiID_Type_Enregistrement IS NULL OR E.tiID_Type_Enregistrement = @tiID_Type_Enregistrement ) 
                AND ( @siAnnee_Fiscale IS NULL OR I.siAnnee_Fiscale = @siAnnee_Fiscale ) 
                AND ( @iID_Enregistrement IS NULL OR E.iID_Enregistrement = @iID_Enregistrement ) 
                AND ( @iID_Convention IS NULL OR I.iID_Convention = @iID_Convention ) 
                AND ( @vcNo_Convention IS NULL OR I.vcNo_Convention = @vcNo_Convention )
            ORDER BY 
                I.vcNo_Convention, TER.siCode_Erreur
        END    
    END

    RETURN 
END 
