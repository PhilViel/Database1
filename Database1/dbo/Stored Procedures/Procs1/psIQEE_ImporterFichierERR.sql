/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_ImporterFichierERR
Nom du service        : Importer un fichier d'erreurs (ERR)
But                 : Traiter un fichier d'erreurs de Revenu Québec dans le module de l'IQÉÉ.
Facette                : IQÉÉ

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------
                        iID_Fichier_IQEE_Physique    Identifiant unique du fichier d'erreur logique de l'IQÉÉ en cours
                                                    d'importation qui contient les lignes du fichier d'erreur physique.

Exemple d’appel        :    Cette procédure doit uniquement être appelé du service "psIQEE_ImporterFichierReponses".

Paramètres de sortie:    Table                        Champ                            Description
                          -------------------------    ---------------------------     ---------------------------------
                        S/O                            iNombre_Erreur                    Nombre d'erreurs importées
                                                    bIndicateur_Erreur_Grave        Indicateur que le fichier d'erreurs
                                                                                    contient ou non une erreur grave
                                                                                    (format invalide)

Historique des modifications:
    Date            Programmeur         Description                                
    ----------  --------------------    -----------------------------------------
    2009-10-26  Éric Deshaies           Création du service                            
    2012-09-17  Stéphane Barbeau        Traitement des T03 et T06
    2012-09-19  Stéphane Barbeau        T03 et T06: Emploi de CONVERT(VARCHAR(10), dtDate_Remplacement ou dtDateEvenement,120) dans les SELECT
    2012-11-28  Stéphane Barbeau        Ajout parmamètre @iID_Utilisateur et traitement d'opérations IQE renversée
    2012-02-01  Stéphane Barbeau        T06: INSERT INTO tbl_IQEE_ErreursEnregistrements, Ajout du statut R dans le select pour traiter les T06-23 au statut R par défaut.
    2014-03-19  Stéphane Barbeau        Désactivation Avertissement: Erreur de RQ sur une transaction d'annulation.  Erreur de programmation?
                                        Améliorations sur le traitement des T06-23 (Recherche et Update)
    2014-09-09  Stéphane Barbeau        Ajustement de la taille de la variable @vcDescription pour supporter 
                                        la nouvelle taille du champ du même nom dans la table dbo.tblIQEE_TypesErreurRQ.
    2015-01-22  Stéphane Barbeau        T03: requête @iNB_Transactions ajustée pour inclure les demandes T03 de statut 'A',                                                             
                                             Mettre à jour les demandes d'origines T03 de statut 'A'.
                                             @iID_Transaction_Origine inclure les les demandes d'origines T03 de statut 'A' dans la recherche.
    2016-03-07  Steeve Picard           Utilisation du ID de transaction à partir de novembre 2016
    2016-04-11  Patrice Côté            Modifications de l'importation des erreurs de transfert (T04)
    2017-08-14	Steeve Picard           Mettre tout en erreur si une erreur grave survient et renverser les opérations financières (T-06)
    2017-10-10  Steeve Picard           Correction d'un bug dans la déclaration d'un cursor
    2017-12-11  Steeve Picard           Ajout d'une nouvelle section à partir de novembre 2017
    2018-01-18  Steeve Picard           Correction le renversement des opérations financières lorsque plusieurs erreurs surviennent pour la même transaction
    2018-05-09  Steeve Picard           Correction pour la boucle sur les erreurs d'éléments
    2018-05-17  Steeve Picard           Retourner le montant total des impôts spéciaux renversés dans les conventions en erreur
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
    2018-11-05  Steeve Picard           Correction dans la recherche de la transaction d'origine
***********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_ImporterFichierERR
(
    @iID_Fichier_IQEE_Physique INT,
    @iID_Utilisateur INT,
    @iNombre_Erreur INT OUTPUT,
    @bIndicateur_Erreur_Grave BIT OUTPUT,
    @mSolde_Renverser MONEY OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON
    SET @mSolde_Renverser = 0
    
    -----------------
    -- Initialisation
    -----------------
    DECLARE @cLigne CHAR(1000),
            @iID_Fichier_IQEE_Erreur INT,
            @iID_Fichier_IQEE_Origine INT,
            @siAnnee_Fiscale SMALLINT,
            @tiID_Categorie_Erreur TINYINT,
            @siCode_Erreur SMALLINT,
            @vcDescription VARCHAR(500),
            @vcValeur VARCHAR(100),
            @tiID_Statuts_Erreur TINYINT,
            @iID_Erreur INT,
            @tiID_Type_Enregistrement TINYINT,
            @cCode_Type_Enregistrement CHAR(2),
            @vcNo_Convention VARCHAR(15),
            @tiCode_Version TINYINT,
            @iID_Transaction_Origine INT,
            @cCode_Sous_Type CHAR(2),
            @iID_Sous_Type INT,
            @dtDate_Transaction DATETIME,
            @iNB_Transactions INT,
            @iID_Statut_Annulation INT,
            @iID_Type_Annulation INT,
            @iID_Utilisateur_Systeme INT,
            @vcNom_Element_Structure_Erreur VARCHAR(30),
            @MsgErr varchar(1000), -- = '',
            @IsDebug bit = dbo.fn_IsDebug()

    -- Déterminer le code d'opération
    DECLARE @cID_Type_Operation CHAR(3) = dbo.fnOPER_ObtenirTypesOperationCategorie('IQEE_CODE_INJECTION_MONTANT_CONVENTION')
    DECLARE @vcOPER_MONTANTS_CREDITBASE VARCHAR(100) = dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_MONTANTS_CREDITBASE')
    DECLARE @vcOPER_MONTANTS_MAJORATION  VARCHAR(100) = dbo.fnOPER_ObtenirTypesOperationConvCategorie('OPER_MONTANTS_MAJORATION')
    DECLARE @iID_Connexion INTEGER = (SELECT MAX(ConnectID) FROM dbo.Mo_Connect WHERE UserID = @iID_Utilisateur)
    DECLARE @dtDate_Operation DATE = getdate()

    -- Compter le nombre d'erreur pour le service appelant
    SET @iNombre_Erreur = 0

    -- Déterminer la catégorie des nouvelles erreurs
    SELECT @tiID_Categorie_Erreur = CE.tiID_Categorie_Erreur
    FROM dbo.tblIQEE_CategoriesErreur CE
    WHERE CE.vcCode_Categorie = 'TI'

    IF @IsDebug <> 0
        SELECT * FROM dbo.tblIQEE_CategoriesErreur CE
        WHERE CE.tiID_Categorie_Erreur = @tiID_Categorie_Erreur


    -- Déterminer le statut des nouvelles erreurs
    SELECT @tiID_Statuts_Erreur = SE.tiID_Statuts_Erreur
    FROM dbo.tblIQEE_StatutsErreur SE
    WHERE SE.vcCode_Statut = 'ATR'

    IF @IsDebug <> 0
        SELECT * FROM dbo.tblIQEE_StatutsErreur SE
        WHERE SE.tiID_Statuts_Erreur = @tiID_Statuts_Erreur

    IF OBJECT_ID('tempDB..#TB_Error_12') IS NOT NULL 
        DROP TABLE #TB_Error_12

    ----------------------------------------------------------
    -- Chargement de la table temporaire des lignes converties
    ----------------------------------------------------------

    CREATE TABLE #TB_Error_12 (
        Row_Num INT IDENTITY(1,1),
        siAnneeFiscale SMALLINT,
        vcID_Fiduciaire VARCHAR(10),
        vcNo_Contrat VARCHAR(15),
        iID_RegimeType INT,
        vcNAS_Beneficiaire VARCHAR(9),
        siCode_ErreurStructure SMALLINT,
        vcNom_ErreurStructure nVARCHAR(30),
        siCode_ErreurElement SMALLINT,
        vcNom_ErreurElement VARCHAR(56),
        vcValeur_ErreurElement VARCHAR(80),
        cTypeEnregistrement CHAR(2),
        cSousTypeEnregistrement CHAR(2),
        tiCode_Version TINYINT,
        dtTransaction DATE,
        iID_Transaction int
    )

    INSERT INTO #TB_Error_12 (
        siAnneeFiscale, vcID_Fiduciaire, vcNo_Contrat, iID_RegimeType, vcNAS_Beneficiaire,
        cTypeEnregistrement, siCode_ErreurStructure, vcNom_ErreurStructure,
        siCode_ErreurElement, vcNom_ErreurElement, vcValeur_ErreurElement, 
        tiCode_Version, cSousTypeEnregistrement, dtTransaction, iID_Transaction)
    --OUTPUT inserted.*
    SELECT CAST('0'+SUBSTRING(LF.cLigne,3,4) AS SMALLINT),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,7,10),'X',10,NULL) AS VARCHAR(10)),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,17,15),'X',15,NULL) AS VARCHAR(15)),
           CAST('0'+SUBSTRING(LF.cLigne,32,10) AS INT),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,42,9),'X',9,NULL) AS VARCHAR(9)),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,51,2),'X',2,NULL) AS CHAR(2)),
           CAST('0'+SUBSTRING(LF.cLigne,53,4) AS SMALLINT),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,57,30),'X',30,NULL) AS nVARCHAR(30)),
           -- Position du format avant novembre 2017
           CAST('0'+SUBSTRING(LF.cLigne,87,4) AS SMALLINT),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,91,30),'X',30,NULL) AS VARCHAR(30)),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,121,40),'X',40,NULL) AS VARCHAR(40)),
           CAST('0'+SUBSTRING(LF.cLigne,161,1) AS TINYINT),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,162,2),'X',2,NULL) AS CHAR(2)),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,164,8),'D',8,NULL) AS DATE),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,172,15),'9',15,NULL) AS INT)
      FROM dbo.tblIQEE_LignesFichier LF
     WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE_Physique
       AND Left(LF.cLigne,2) = '12'
       AND CAST('0'+SUBSTRING(LF.cLigne,53,4) AS SMALLINT) > 0
     UNION
    SELECT CAST('0'+SUBSTRING(LF.cLigne,3,4) AS SMALLINT),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,7,10),'X',10,NULL) AS VARCHAR(10)),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,17,15),'X',15,NULL) AS VARCHAR(15)),
           CAST('0'+SUBSTRING(LF.cLigne,32,10) AS INT),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,42,9),'X',9,NULL) AS VARCHAR(9)),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,51,2),'X',2,NULL) AS CHAR(2)),
           CAST('0'+SUBSTRING(LF.cLigne,53,4) AS SMALLINT),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,57,30),'X',30,NULL) AS VARCHAR(30)),
           -- Position du format avant novembre 2017
           CAST('0'+SUBSTRING(LF.cLigne,87,4) AS SMALLINT),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,91,30),'X',30,NULL) AS VARCHAR(30)),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,121,40),'X',40,NULL) AS VARCHAR(40)),
           CAST('0'+SUBSTRING(LF.cLigne,161,1) AS TINYINT),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,162,2),'X',2,NULL) AS CHAR(2)),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,164,8),'D',8,NULL) AS DATE),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,172,15),'9',15,NULL) AS INT)
      FROM dbo.tblIQEE_LignesFichier LF
     WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE_Physique
       AND Left(LF.cLigne,2) = '12'
       AND CAST('0'+SUBSTRING(LF.cLigne,53,4) AS SMALLINT) = 0
       AND CAST('0'+SUBSTRING(LF.cLigne,87,4) AS SMALLINT) > 0
     UNION
    SELECT CAST('0'+SUBSTRING(LF.cLigne,3,4) AS SMALLINT),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,7,10),'X',10,NULL) AS VARCHAR(10)),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,17,15),'X',15,NULL) AS VARCHAR(15)),
           CAST('0'+SUBSTRING(LF.cLigne,32,10) AS INT),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,42,9),'X',9,NULL) AS VARCHAR(9)),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,51,2),'X',2,NULL) AS VARCHAR(2)),
           CAST('0'+SUBSTRING(LF.cLigne,53,4) AS SMALLINT),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,57,30),'X',30,NULL) AS VARCHAR(30)),
           -- Position du format à partir de novembre 2017
           CAST('0'+SUBSTRING(LF.cLigne,187,4) AS SMALLINT),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,191,56),'X',30,NULL) AS VARCHAR(56)),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,247,80),'X',40,NULL) AS VARCHAR(80)),
           CAST('0'+SUBSTRING(LF.cLigne,327,1) AS TINYINT),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,328,2),'X',2,NULL) AS VARCHAR(2)),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,330,8),'D',8,NULL) AS DATE),
           CAST(dbo.fnIQEE_DeformaterChamp(SUBSTRING(LF.cLigne,172,15),'9',15,NULL) AS INT)
      FROM dbo.tblIQEE_LignesFichier LF
     WHERE LF.iID_Fichier_IQEE = @iID_Fichier_IQEE_Physique
       AND Left(LF.cLigne,2) = '12'
       AND CAST('0'+SUBSTRING(LF.cLigne,53,4) AS SMALLINT) = 0
       AND CAST('0'+SUBSTRING(LF.cLigne,187,4) AS SMALLINT) > 0

    IF @IsDebug <> 0
        SELECT * FROM #TB_Error_12

    ----------------------------------------------------------------------------------------------------
    -- Création automatique des nouveaux types d'erreur RQ inexistants dans la table de référence de GUI
    ----------------------------------------------------------------------------------------------------
    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierERR          - '+
            'Création nouveaux types d''erreur RQ')

    -- Rechercher les types d'erreur RQ utilisés
    DECLARE curNouveauTypeErreur CURSOR LOCAL FAST_FORWARD 
        FOR SELECT E.siCode_ErreurStructure, E.vcNom_ErreurStructure
              FROM #TB_Error_12 E
             WHERE E.siCode_ErreurStructure > 0
             UNION
            SELECT E.siCode_ErreurElement, E.vcNom_ErreurElement
              FROM #TB_Error_12 E
             WHERE E.siCode_ErreurElement > 0

    -- Boucler les types d'erreur RQ utilisés
    OPEN curNouveauTypeErreur
    FETCH NEXT FROM curNouveauTypeErreur INTO @siCode_Erreur,@vcNom_Element_Structure_Erreur
    WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Création du type d'erreur RQ s'il n'existe pas
            IF NOT EXISTS(SELECT *
                          FROM dbo.tblIQEE_TypesErreurRQ TE
                          WHERE TE.siCode_Erreur = @siCode_Erreur)
                BEGIN
                    IF @vcNom_Element_Structure_Erreur IS NULL
                        SET @vcDescription = 'Description à déterminer par le département informatique.'
                    ELSE
                        SET @vcDescription = 'Erreur grave de structure sur l''élément "'+@vcNom_Element_Structure_Erreur+
                                             '" (description à réviser par le département informatique)'

                    INSERT INTO dbo.tblIQEE_TypesErreurRQ
                           (siCode_Erreur
                           ,vcDescription
                           ,tiID_Categorie_Erreur
                           ,bInd_Erreur_Grave
                           ,bConsiderer_Traite_Creation_Fichiers)
                     VALUES
                           (@siCode_Erreur
                           ,@vcDescription
                           ,@tiID_Categorie_Erreur
                           ,CASE WHEN @vcNom_Element_Structure_Erreur IS NULL THEN 1 ELSE 0 END
                           ,0)

                    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                    VALUES ('2',10,'       Avertissement: Nouveau code d''erreur RQ ajouté automatiquement.  La description doit être révisée.')
                    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                    VALUES ('2',10,'              Code: '+CAST(@siCode_Erreur AS VARCHAR))
                    IF @vcNom_Element_Structure_Erreur IS NOT NULL
                        INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
                        VALUES ('2',10,'              Description: '+@vcDescription)
                END

            FETCH NEXT FROM curNouveauTypeErreur INTO @siCode_Erreur,@vcNom_Element_Structure_Erreur
        END
    CLOSE curNouveauTypeErreur
    DEALLOCATE curNouveauTypeErreur


    ---------------------------------------------------------------------------------------------------------------------------------
    -- Traiter les types d'enregistrement 12 (erreur): Création de l'erreur et association entre l'erreur et la transaction en erreur
    ---------------------------------------------------------------------------------------------------------------------------------

    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierERR          - '+
            'Création de l''erreur et association entre l''erreur et la transaction en erreur.')

    -- Traiter les erreurs normales (recevabilité d'une transaction)
    ----------------------------------------------------------------
    DECLARE @iID_Transaction_RQ INT = 0,
            @Row_Num INT

    -- Boucler les types d'enregistrement 12 (erreur)
    WHILE EXISTS(SELECT * FROM #TB_Error_12 WHERE iID_Transaction > @iID_Transaction_RQ AND siCode_ErreurElement > 0)
    BEGIN
        -- Récupère les informations de la transaction à traiter
        SELECT TOP 1
            @siAnnee_Fiscale = siAnneeFiscale,
            @vcNo_Convention = vcNo_Contrat,
            @cCode_Type_Enregistrement = cTypeEnregistrement,
            @cCode_Sous_Type = RTRIM(cSousTypeEnregistrement),
            @tiCode_Version = tiCode_Version,
            @dtDate_Transaction = dtTransaction,
            @iID_Transaction_RQ = iID_Transaction,
            @siCode_Erreur = siCode_ErreurElement,
            @vcDescription = vcNom_ErreurElement,
            @vcValeur = vcValeur_ErreurElement,
            @Row_Num = Row_Num
        FROM 
            #TB_Error_12 
        WHERE 
            iID_Transaction > @iID_Transaction_RQ 
            AND siCode_ErreurElement > 0 
        ORDER BY 
            iID_Transaction, Row_Num

        -- Déterminer le fichier logique de l'année fiscale
        SELECT @iID_Fichier_IQEE_Erreur = FL.iID_Fichier_IQEE,
               @iID_Fichier_IQEE_Origine = FL.iID_Lien_Fichier_IQEE_Demande
          FROM #tblIQEE_Fichiers_Logiques FL
         WHERE FL.siAnnee_Fiscale = @siAnnee_Fiscale

        -- Déterminer les identifiante du type ou sous-type de transaction
        SELECT TOP 1
               @tiID_Type_Enregistrement = TE.tiID_Type_Enregistrement,
               @iID_Sous_Type = TE.iID_Sous_Type
          FROM dbo.vwIQEE_Enregistrement_TypeEtSousType TE
         WHERE TE.cCode_Type_Enregistrement = @cCode_Type_Enregistrement
           AND ISNULL(TE.cCode_Sous_Type, REPLICATE('0', 2)) = @cCode_Sous_Type

        IF @IsDebug <> 0
            PRINT 'No_Convention / ID_Transaction_RQ / Type-Transaction : ' + @vcNo_Convention + ' / ' + LTRIM(STR(@iID_Transaction_RQ, 15)) +
                                                                                                 ' / ' + @cCode_Type_Enregistrement + ISNULL(@cCode_Sous_Type, '')
                    
        SET @MsgErr = NULL
        SET @iNB_Transactions = 0

        --SET @iID_Ligne_Fichier = CASE Len(@vcID_Transaction_RQ) WHEN 0 THEN NULL ELSE Cast(@vcID_Transaction_RQ as int) END

        -- T02: Déterminer la transaction d'origine en erreur et mettre à jour son statut
        IF @cCode_Type_Enregistrement = '02'
        BEGIN
            -- Valider qu'il y a une seule transaction d'origine en erreur
            SELECT @iID_Transaction_Origine = Max(D.iID_Demande_IQEE),
                   @iNB_Transactions = COUNT(*)
              FROM dbo.tblIQEE_Demandes D
             WHERE D.iID_Ligne_Fichier = @iID_Transaction_RQ
                   OR ( D.vcNo_Convention = @vcNo_Convention
                        AND D.siAnnee_Fiscale = @siAnnee_Fiscale
                        AND D.iID_Fichier_IQEE = @iID_Fichier_IQEE_Origine
                        AND D.tiCode_Version = @tiCode_Version
                        AND ( ( D.tiCode_Version = 1 
                                AND D.cStatut_Reponse = 'A'
                              )
                              OR (D.tiCode_Version = 0 AND D.cStatut_Reponse IN ('A','E'))
                              OR (D.tiCode_Version = 2 AND D.cStatut_Reponse IN ('A','D','E'))
                            )
                      )
                                   
            IF @iNB_Transactions = 1
                -- Mettre à jour le statut de la transaction d'origine
                UPDATE dbo.tblIQEE_Demandes
                   SET cStatut_Reponse = 'E'
                 WHERE iID_Demande_IQEE = @iID_Transaction_Origine
        END

        -- T03: Déterminer la transaction d'origine en erreur et mettre à jour son statut
        IF @cCode_Type_Enregistrement = '03'
        BEGIN
            -- Valider qu'il y a une seule transaction d'origine en erreur
            SELECT @iID_Transaction_Origine = Max(RB.iID_Remplacement_Beneficiaire),
                   @iNB_Transactions = COUNT(*)
              FROM dbo.tblIQEE_RemplacementsBeneficiaire RB
             WHERE RB.iID_Ligne_Fichier = @iID_Transaction_RQ
                   OR ( RB.vcNo_Convention = @vcNo_Convention
                        AND RB.siAnnee_Fiscale = @siAnnee_Fiscale
                        AND RB.dtDate_Remplacement = @dtDate_Transaction 
                        AND RB.iID_Fichier_IQEE = @iID_Fichier_IQEE_Origine
                        AND RB.tiCode_Version = @tiCode_Version
                        AND RB.cStatut_Reponse IN ('A','R','E')
                      )
                             
            IF @iNB_Transactions = 1
                -- Mettre à jour le statut de la transaction d'origine
                UPDATE dbo.tblIQEE_RemplacementsBeneficiaire
                   SET cStatut_Reponse = 'E'
                 WHERE iID_Remplacement_Beneficiaire = @iID_Transaction_Origine
        END

        -- T04: Déterminer la transaction d'origine en erreur et mettre à jour son statut
        IF @cCode_Type_Enregistrement = '04'
        BEGIN
            -- Valider qu'il y a une seule transaction d'origine en erreur
            SELECT @iID_Transaction_Origine = Max(T.iID_Transfert),
                   @iNB_Transactions = COUNT(*)
              FROM dbo.tblIQEE_Transferts T
             WHERE T.iID_Ligne_Fichier = @iID_Transaction_RQ
                   OR ( T.vcNo_Convention = @vcNo_Convention
                        AND T.siAnnee_Fiscale = @siAnnee_Fiscale
                        AND T.dtDate_Transfert = @dtDate_Transaction 
                        AND T.iID_Sous_Type = @iID_Sous_Type
                        AND T.iID_Fichier_IQEE = @iID_Fichier_IQEE_Origine
                        AND T.tiCode_Version = @tiCode_Version
                        --AND T.cStatut_Reponse IN ('R','E')
                      )
                             
            IF @iNB_Transactions = 1
                -- Mettre à jour le statut de la transaction d'origine
                UPDATE dbo.tblIQEE_Transferts
                   SET cStatut_Reponse = 'E'
                 WHERE iID_Transfert = @iID_Transaction_Origine
        END

        -- T05: Déterminer la transaction d'origine en erreur et mettre à jour son statut
        IF @cCode_Type_Enregistrement = '05'
        BEGIN
            -- Valider qu'il y a une seule transaction d'origine en erreur
            SELECT @iID_Transaction_Origine = Max(PB.iID_Paiement_Beneficiaire),
                   @iNB_Transactions = COUNT(*)
              FROM dbo.tblIQEE_PaiementsBeneficiaires PB
             WHERE PB.iID_Ligne_Fichier = @iID_Transaction_RQ
                   OR ( PB.vcNo_Convention = @vcNo_Convention
                        AND PB.siAnnee_Fiscale = @siAnnee_Fiscale
                        AND PB.dtDate_Paiement = @dtDate_Transaction 
                        AND PB.iID_Sous_Type = @iID_Sous_Type
                        AND PB.iID_Fichier_IQEE = @iID_Fichier_IQEE_Origine
                        AND PB.tiCode_Version = @tiCode_Version
                        AND PB.cStatut_Reponse IN ('R','E')
                      )
                             
            IF @iNB_Transactions = 1
                -- Mettre à jour le statut de la transaction d'origine
                UPDATE dbo.tblIQEE_PaiementsBeneficiaires
                   SET cStatut_Reponse = 'E'
                 WHERE iID_Paiement_Beneficiaire = @iID_Transaction_Origine
        END

        -- T06: Déterminer la transaction d'origine en erreur et mettre à jour son statut
        IF @cCode_Type_Enregistrement = '06'
        BEGIN
            -- Valider qu'il y a une seule transaction d'origine en erreur
            SELECT @iID_Transaction_Origine = Max(TIS.iID_Impot_Special),
                   @iNB_Transactions = COUNT(*)
              FROM dbo.tblIQEE_ImpotsSpeciaux TIS
             WHERE TIS.iID_Ligne_Fichier = @iID_Transaction_RQ
                   OR ( TIS.vcNo_Convention = @vcNo_Convention
                        AND TIS.siAnnee_Fiscale = @siAnnee_Fiscale
                        AND CONVERT(VARCHAR(10), TIS.dtDate_Evenement,120) = @dtDate_Transaction 
                        AND TIS.iID_Sous_Type = @iID_Sous_Type
                        AND TIS.iID_Fichier_IQEE = @iID_Fichier_IQEE_Origine  --SB Pas la bonne variable, @iID_Lien_Fichier_IQEE_Demande   
                        AND TIS.tiCode_Version = @tiCode_Version
                        AND ( ( TIS.tiCode_Version = 1 
                                AND TIS.cStatut_Reponse = 'A'
                              )
                              OR ( TIS.tiCode_Version IN (0,2) 
                                   AND ( TIS.cStatut_Reponse IN ('A','E')
                                         -- Dans le cas des T06-23, il faut tenir compte du statut R car RQ ne retournait pas de réponse pour les T06-23
                                         OR (@iID_Sous_Type = 11 AND TIS.cStatut_Reponse = 'R')
                                       )
                                 )
                            )
                      )
                             
            IF @iNB_Transactions = 1
            BEGIN
                -- Mettre à jour le statut de la transaction d'origine
                UPDATE dbo.tblIQEE_ImpotsSpeciaux
                   SET cStatut_Reponse = 'E'
                 WHERE iID_Impot_Special = @iID_Transaction_Origine

                --  Renverser les opérations IQE de décaissement

                DECLARE @iID_Convention INTEGER
                DECLARE @iID_Transaction_CBQ INTEGER
                DECLARE @iID_Transaction_MMQ INTEGER
                                
                SELECT @iID_Convention = DIS.iID_Convention,
                       @iID_Transaction_CBQ = DIS.iID_Paiement_Impot_CBQ,
                       @iID_Transaction_MMQ = DIS.iID_Paiement_Impot_MMQ
                  FROM dbo.tblIQEE_ImpotsSpeciaux DIS
                 WHERE DIS.iID_Impot_Special = @iID_Transaction_Origine
                                    
                -- Critères à spécifier
                IF @IsDebug <> 0
                    PRINT '   iID_Convention/CBQ/MMQ : ' + STR( @iID_Convention,10) + ' / ' + STR( @iID_Transaction_CBQ,10) + ' / ' + STR( @iID_Transaction_MMQ,10)
                
                IF @iID_Transaction_CBQ IS NOT NULL OR @iID_Transaction_MMQ IS NOT NULL
                BEGIN
                    DECLARE @iID_Operation INTEGER

                    -- Créer l'opération de renversement de déclaration d'impôt spécial
                    EXECUTE @iID_Operation = dbo.SP_IU_UN_Oper @iID_Connexion, 0,  @cID_Type_Operation, @dtDate_Operation

                    DECLARE @mMontant_IQEE_Base money
                    DECLARE @mMontant_IQEE_Majore money
                    DECLARE @iID_Transaction_Convention_CBQ_Renversee int
                    DECLARE @iID_Transaction_Convention_MMQ_Renversee int
                                            
                    SELECT @mMontant_IQEE_Base = 0.00, @mMontant_IQEE_Majore = 0.00

                    IF @iID_Transaction_CBQ IS NOT NULL 
                    BEGIN
                        SELECT @mMontant_IQEE_Base = -ConventionOperAmount 
                          FROM dbo.Un_ConventionOper
                         WHERE ConventionOperID = @iID_Transaction_CBQ
                                                    
                        IF @IsDebug <> 0
                            PRINT '   @mMontant_IQEE_Base : ' + Str(@mMontant_IQEE_Base, 10, 2)
                        IF @mMontant_IQEE_Base <> 0
                        BEGIN
                            -- Injecter le montant dans la convention
                            INSERT INTO dbo.Un_ConventionOper (
                                    OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
                                )
                            VALUES (
                                    @iID_Operation, @iID_Convention, @vcOPER_MONTANTS_CREDITBASE, @mMontant_IQEE_Base
                                )
                                                    
                            SET @iID_Transaction_Convention_CBQ_Renversee = SCOPE_IDENTITY()
                        END                                                            
                                                        
                        UPDATE dbo.tblIQEE_ImpotsSpeciaux
                            SET iID_Transaction_Convention_CBQ_Renversee = @iID_Transaction_Convention_CBQ_Renversee
                            WHERE iID_Impot_Special = @iID_Transaction_Origine
                    END

                    IF @iID_Transaction_MMQ IS NOT NULL
                    BEGIN
                        Select @mMontant_IQEE_Majore = -ConventionOperAmount 
                          FROM dbo.Un_ConventionOper
                         WHERE ConventionOperID = @iID_Transaction_MMQ

                        IF @IsDebug <> 0
                            PRINT '   @mMontant_IQEE_Majoré : ' + Str(@mMontant_IQEE_Majore, 10, 2)
                        IF @mMontant_IQEE_Majore <> 0
                        BEGIN
                            -- Injecter le montant dans la convention
                            INSERT INTO dbo.Un_ConventionOper (
                                OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
                            )
                            VALUES (
                                @iID_Operation, @iID_Convention, @vcOPER_MONTANTS_MAJORATION, @mMontant_IQEE_Majore
                            )
                                                    
                            SET @iID_Transaction_Convention_MMQ_Renversee = SCOPE_IDENTITY()
                        END

                        UPDATE dbo.tblIQEE_ImpotsSpeciaux
                           SET iID_Transaction_Convention_MMQ_Renversee = @iID_Transaction_Convention_MMQ_Renversee 
                         WHERE iID_Impot_Special = @iID_Transaction_Origine
                    END

                    SET @mSolde_Renverser = @mSolde_Renverser + @mMontant_IQEE_Base + @mMontant_IQEE_Majore
                END 
            END
        END

        -- Associer l'erreur à son enregistrement d'origine
        IF @iNB_Transactions = 1
        BEGIN
            SET @siCode_Erreur = 0
            WHILE EXISTS(SELECT * FROM #TB_Error_12 WHERE iID_Transaction = @iID_Transaction_RQ AND siCode_ErreurElement > 0 AND siCode_ErreurElement > @siCode_Erreur)
            BEGIN
                -- Récupère les informations de l'erreur à traiter
                SELECT TOP 1
                   @siCode_Erreur = siCode_ErreurElement,
                   @vcDescription = vcNom_ErreurElement,
                   @vcValeur = vcValeur_ErreurElement,
                   @Row_Num = Row_Num
                FROM 
                    #TB_Error_12 
                WHERE 
                    iID_Transaction = @iID_Transaction_RQ 
                    AND siCode_ErreurElement > @siCode_Erreur
                ORDER BY 
                    siCode_ErreurElement

                -- Ajouter l'erreur
                INSERT INTO dbo.tblIQEE_Erreurs (
                    iID_Fichier_IQEE, tiID_Type_Enregistrement, iID_Enregistrement, siCode_Erreur, 
                    tiID_Statuts_Erreur, vcElement_Erreur, vcValeur_Erreur
                )
                VALUES (
                    @iID_Fichier_IQEE_Erreur, @tiID_Type_Enregistrement, @iID_Transaction_Origine, @siCode_Erreur, 
                    @tiID_Statuts_Erreur, @vcNom_Element_Structure_Erreur, @vcDescription
                )
                SET @iID_Erreur = SCOPE_IDENTITY()
                IF @IsDebug <> 0
                    PRINT '   iID_Erreur : ' + STR(@iID_Erreur)
            END 
        END 
        ELSE
        BEGIN
            IF @iNB_Transactions = 0 AND @iID_Transaction_RQ > 0
            BEGIN
                SET @MsgErr = 'Ne retrouve pas la transaction T-' + @cCode_Type_Enregistrement + ' d''origine dont le ID de la ligne est : ' + LTRIM(STR(@iID_Transaction_RQ))
                RAISERROR (@MsgErr, 11, 1)
            END 
            ELSE
                SET @MsgErr = '       Avertissement: Ne peut pas déterminer la transaction T-' + @cCode_Type_Enregistrement + ' d''origine de l''erreur RQ.'+char(13)+CHAR(10)+
                              '                      L''insertion dans la table dbo.tblIQEE_Erreurs doit se faire manuellement.'

            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,@MsgErr)

            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'')
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'              #Convention: ' + ISNULL(@vcNo_Convention,''))
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'              Type d''enregistrement en erreur: ' + ISNULL(@cCode_Type_Enregistrement,''))
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'              Code d''erreur RQ: ' + ISNULL(STR(@siCode_Erreur, 4),''))
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'              Élément en erreur: ' + ISNULL(@vcDescription,''))
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'              Valeur en erreur: ' + ISNULL(@vcValeur,''))
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'              Date de la transaction: ' + CONVERT(VARCHAR(10),@dtDate_Transaction,121))
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'              ID Fichier d''origine: ' + CAST(ISNULL(@iID_Fichier_IQEE_Origine,0) AS VARCHAR))
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'              ID Ligne d''origine: ' + CAST(ISNULL(@iID_Transaction_RQ,0) AS VARCHAR))
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'              Code de version de la transaction d''origine: ' + CAST(ISNULL(@tiCode_Version,0) AS VARCHAR))
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'              ID de l''erreur: ' + CAST(ISNULL(@iID_Erreur,0) AS VARCHAR))
            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('2',10,'              ID du type d''enregistrement: '+CAST(ISNULL(@tiID_Type_Enregistrement,0) AS VARCHAR))
        END

        SET @iNombre_Erreur = @iNombre_Erreur + 1
    END

    -- Traiter les erreur graves (recevabilité du fichier)
    ------------------------------------------------------
    SET @Row_Num = 0
    WHILE EXISTS(SELECT * FROM #TB_Error_12 WHERE Row_Num > @Row_Num AND siCode_ErreurStructure > 0)
        BEGIN
            SELECT @Row_Num = MIN(Row_Num) FROM #TB_Error_12 WHERE Row_Num > @Row_Num AND siCode_ErreurStructure > 0

            SET @bIndicateur_Erreur_Grave = 1

            -- Récupère les informations de l'erreur à traiter
            SELECT --@siAnnee_Fiscale = siAnneeFiscale,
            --       @vcNo_Convention = vcNo_Contrat,
            --       @cCode_Type_Enregistrement = cTypeEnregistrement,
            --       @cCode_Sous_Type = RTRIM(cSousTypeEnregistrement),
            --       @tiCode_Version = tiCode_Version,
            --       @dtDate_Transaction = dtTransaction,
                   -- Déterminer le code de l'erreur
                   @siCode_Erreur = siCode_ErreurStructure,
                   @vcDescription = vcNom_ErreurStructure
              FROM #TB_Error_12 WHERE Row_Num = @Row_Num

            PRINT '***************' + Replicate('*', 36)
            PRINT ' Erreur grave #' + STR(@siCode_Erreur,4) + ': ' + @vcDescription
            PRINT '***************' + Replicate('*', 36)

            INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierERR          - '+
                    'Erreur grave : ' + STR(@siCode_Erreur,4) + ': ' + @vcDescription)

            -- Déterminer le statut des nouvelles erreurs
            SELECT @tiID_Statuts_Erreur = SE.tiID_Statuts_Erreur
            FROM dbo.tblIQEE_StatutsErreur SE
            WHERE SE.vcCode_Statut = 'TER' -- 'TAR'

            -- Ajouter l'erreur grave
            INSERT INTO dbo.tblIQEE_Erreurs (
                iID_Fichier_IQEE, siCode_Erreur, tiID_Statuts_Erreur, vcElement_Erreur
            )
            VALUES (
                @iID_Fichier_IQEE_Physique, @siCode_Erreur, @tiID_Statuts_Erreur, @vcDescription
            )
            SET @iID_Erreur = SCOPE_IDENTITY()
                    
            -- Associer l'erreur grave à tous les enregistrements  que contenait les fichiers logiques d'origine
            DECLARE @iCount int

            DECLARE @TB_Output TABLE (iID_Enregistrement INT NOT NULL)
                    
            -- Demandes
            BEGIN
                UPDATE D SET cStatut_Reponse = 'X'
                  FROM dbo.tblIQEE_Demandes D
                       JOIN #tblIQEE_Fichiers_Logiques FL ON FL.iID_Lien_Fichier_IQEE_Demande = D.iID_Fichier_IQEE
                 WHERE D.cStatut_Reponse <> 'E'

                SELECT @iCount = @@ROWCOUNT
                PRINT '   ' + LTRIM(STR(@iCount)) + ' demandes mis en erreur'
            END

            -- Remplacement bénéficiaire
            BEGIN
                UPDATE RB SET cStatut_Reponse = 'X'
                  FROM dbo.tblIQEE_RemplacementsBeneficiaire RB
                       JOIN #tblIQEE_Fichiers_Logiques FL ON FL.iID_Lien_Fichier_IQEE_Demande = RB.iID_Fichier_IQEE
                 WHERE RB.cStatut_Reponse <> 'E'

                SELECT @iCount = @@ROWCOUNT
                PRINT '   ' + LTRIM(STR(@iCount)) + ' remplacements bénéficiaires mis en erreur'
            END

            -- Transferts
            BEGIN
                UPDATE T SET cStatut_Reponse = 'E'
                  FROM dbo.tblIQEE_Transferts T
                       JOIN #tblIQEE_Fichiers_Logiques FL ON FL.iID_Lien_Fichier_IQEE_Demande = T.iID_Fichier_IQEE
                 WHERE T.cStatut_Reponse <> 'E' 

                SELECT @iCount = @@ROWCOUNT
                PRINT '   ' + LTRIM(STR(@iCount)) + ' transferts mis en erreur'
            END

            -- PAE
            BEGIN
                UPDATE PB SET cStatut_Reponse = 'X'
                  FROM dbo.tblIQEE_PaiementsBeneficiaires PB
                       JOIN #tblIQEE_Fichiers_Logiques FL ON FL.iID_Lien_Fichier_IQEE_Demande = PB.iID_Fichier_IQEE
                 WHERE PB.cStatut_Reponse <> 'E'

                SELECT @iCount = @@ROWCOUNT
                PRINT '   ' + LTRIM(STR(@iCount)) + ' paiements aux bénéficiaires mis en erreur'
            END

            -- Impôts Spéciaux
            BEGIN
                UPDATE I SET I.cStatut_Reponse = 'X'
                OUTPUT Inserted.iID_Impot_Special INTO @TB_Output
                  FROM dbo.tblIQEE_ImpotsSpeciaux I
                       JOIN #tblIQEE_Fichiers_Logiques FL ON FL.iID_Lien_Fichier_IQEE_Demande = I.iID_Fichier_IQEE
                 WHERE I.cStatut_Reponse <> 'E'

                SELECT @iCount = COUNT(*) FROM @TB_Output
                IF @iCount > 0
                BEGIN
                    PRINT '   ' + LTRIM(STR(@iCount)) + ' impôts spéciaux mis en erreur'

                    IF OBJECT_ID('tempDB..#TB_ImpotSpecial_OperFin') IS NOT NULL
                        DROP TABLE #TB_ImpotSpecial_OperFin

                    SELECT
                        Row_Num = ROW_NUMBER() OVER(ORDER BY iID_Impot_Special), NULL AS iID_Oper,
                        iID_Impot_Special, iID_Convention, mSolde_IQEE_Base, mSolde_IQEE_Majore, mIQEE_ImpotSpecial
                    INTO
                        #TB_ImpotSpecial_OperFin
                    FROM
                        dbo.tblIQEE_ImpotsSpeciaux I 
                        JOIN @TB_Output O ON O.iID_Enregistrement = I.iID_Impot_Special
                    WHERE
                        (mSolde_IQEE_Base <> 0 OR mSolde_IQEE_Majore <> 0)

                    SELECT @mSolde_Renverser = SUM(mIQEE_ImpotSpecial),
                           @iCount = COUNT(*) 
                      FROM #TB_ImpotSpecial_OperFin
                    
                    PRINT '   ' + LTRIM(STR(@iCount)) + ' d''opérations à renverser'

                    --  Renverser les opérations IQE de décaissement
                    IF @iCount > 0
                    BEGIN
                        DECLARE @StartTimer DATETIME = GETDATE()

                        INSERT INTO dbo.Un_Oper (
                            ConnectID,  OperTypeID, OperDate
                        )
                        SELECT
                            @iID_Connexion, @cID_Type_Operation, @dtDate_Operation
                        FROM
                            #TB_ImpotSpecial_OperFin

                        ;WITH CTE_Oper as (
                            SELECT
                                OperID, Row_Num = ROW_NUMBER () OVER(Order By OperID)
                            FROM
                                dbo.Un_Oper
                            WHERE
                                OperDate = @dtDate_Operation
                                AND OperTypeID = @cID_Type_Operation
                                AND ConnectID = @iID_Connexion
                                AND dtSequence_Operation >= @StartTimer
                        )
                        UPDATE I SET
                            iID_Oper = O.OperID
                        FROM
                            #TB_ImpotSpecial_OperFin I
                            JOIN CTE_Oper O ON O.Row_Num = I.Row_Num

                        INSERT INTO dbo.Un_ConventionOper (
                            OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
                        )
                        SELECT
                            iID_Oper, iID_Convention, @vcOPER_MONTANTS_CREDITBASE, mSolde_IQEE_Base
                        FROM
                            #TB_ImpotSpecial_OperFin
                        WHERE
                            mSolde_IQEE_Base <> 0
                        UNION
                        SELECT
                            iID_Oper, iID_Convention, @vcOPER_MONTANTS_MAJORATION, mSolde_IQEE_Majore
                        FROM
                            #TB_ImpotSpecial_OperFin
                        WHERE
                            mSolde_IQEE_Majore <> 0
                    END

                    DELETE FROM @TB_Output
                END
            END

            ----DECLARE @iID_Erreur INT =    Ident_Current('tblIQEE_Erreurs') - 8534                         
            --SELECT TE.cCode_Type_Enregistrement, TST.cCode_Sous_Type, 
            --       ConventionNo = COALESCE(D.vcNo_Convention, RB.vcNo_Convention, T.vcNo_Convention, PB.vcNo_Convention, I.vcNo_Convention),
            --       I.mIQEE_ImpotSpecial, EE.* 
            --  FROM dbo.tblIQEE_Erreurs E 
            --       JOIN dbo.tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
            --       LEFT JOIN dbo.tblIQEE_Demandes D ON D.iID_Demande_IQEE = E.iID_Enregistrement AND TE.cCode_Type_Enregistrement = '02'
            --       LEFT JOIN dbo.tblIQEE_RemplacementsBeneficiaire RB ON RB.iID_Remplacement_Beneficiaire = E.iID_Enregistrement AND TE.cCode_Type_Enregistrement = '03'
            --       LEFT JOIN dbo.tblIQEE_Transferts T ON T.iID_Transfert = E.iID_Enregistrement AND TE.cCode_Type_Enregistrement = '04'
            --       LEFT JOIN dbo.tblIQEE_PaiementsBeneficiaires PB ON PB.iID_Paiement_Beneficiaire = E.iID_Enregistrement AND TE.cCode_Type_Enregistrement = '05'
            --       LEFT JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Impot_Special = E.iID_Enregistrement AND TE.cCode_Type_Enregistrement = '06'
            --       LEFT JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TST ON TST.iID_Sous_Type = COALESCE(T.iID_Sous_Type, I.iID_Sous_Type)
            -- WHERE E.iID_Erreur > @iID_Erreur
            -- ORDER BY 1,2,3
        END

    ------------------------------------------------------------------
    -- Mettre le statut d'erreur aux transactions d'origines en erreur
    ------------------------------------------------------------------
    INSERT INTO ##tblIQEE_RapportImportation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_ImporterFichierERR          - '+
            'Mettre le statut d''erreur aux transactions d''origines en erreur.')
END
