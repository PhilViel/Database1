/********************************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service : psIQEE_CreerTransactions_05_01
Nom du service  : Créer les transactions de type 05-01 - Paiement d'aide aux études (PAE)
But             : Sélectionner, valider et créer les transactions de type 05 – 01, concernant les paiements d'aide aux études
                  dans un nouveau fichier de transactions de l’IQÉÉ.
Facette         : IQÉÉ

Paramètres d’entrée :
        Paramètre               Description
        --------------------    -----------------------------------------------------------------
        iID_Fichier_IQEE        Identifiant du nouveau fichier de transactions dans lequel les transactions 05-01 doivent être créées.
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

Exemple d’appel : exec dbo.psIQEE_CreerTransactions05_01 10, 0, NULL, 0, 'T'

Paramètres de sortie:
        Champ               Description
        ------------        ------------------------------------------
        iCode_Retour        = 0 : Exécution terminée normalement
                            < 0 : Erreur de traitement

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    --------------------------------------------------------------------------
    2018-06-06  Steeve Picard           Création du service
    2018-07-30  Steeve Picard           Utilisation de l'adresse du bénéficiaire au moment du PAE au lieu du 31 décembre
    2018-08-21  Steeve Picard           Prendre que les opérations après le 20 février 2007
    2018-08-24  Steeve Picard           Ajout de la validation #220: Tout retrait doit être déclaré à RQ avant que le PAE
    2018-09-19  Steeve Picard           Ajout du champ «iID_SousType» à la table «tblIQEE_CasSpeciaux» pour pouvoir filtrer
    2018-09-20  Steeve Picard           Ajout de la vérification que l'opération «AVC» ait été déclarée préalablement au même titre que les «PAE»
    2018-11-07  Steeve Picard           On ignore les opérations «AVC» mais on exclut les montants du sous-compte «AVC» des «PAE»
    2018-11-27  Steeve Picard           Ne bloquer la déclaration que si elle a de l'IQÉÉ dans le PAE d'une année antérieure
    2018-12-06  Steeve Picard           Utilisation des nouvelles fonctions «fntIQEE_Transfert_NonDeclare & fntIQEE_PaiementBeneficiaire_NonDeclare»
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_CreerTransactions05_01]
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

    DECLARE @vcMessage VARCHAR(MAX),
            @vbCrLf CHAR(2) = CHAR(13) + CHAR(10)

    SET @vcMessage = CHAR(13) + CHAR(10) + 
                     'Déclaration des PAEs cédant vers l''externe (T05-01) pour ' + STR(@siAnnee_Fiscale, 4) + CHAR(13) + CHAR(10) +
                     '--------------------------------------------------------------------' + CHAR(13) + CHAR(10) +
                     '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions_05_01 started'
    RAISERROR('%s', 0, 1, @vcMessage)
    --PRINT ''
    --PRINT 'Déclaration des PAEs cédant vers l''externe (T05-01) pour ' + STR(@siAnnee_Fiscale, 4)
    --PRINT '--------------------------------------------------------------------'
    --PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions_05_01 started'

    -- Empêcher ces déclarations en PROD
    IF @siAnnee_Fiscale < 2018 AND @bit_CasSpecial = 0 --AND @@SERVERNAME IN ('SRVSQL12', 'SRVSQL25')
    BEGIN
        RAISERROR('%s', 0, 1, '   *** Déclaration non-implanté en PROD pour cette année')
        --PRINT '   *** Déclaration non-implanté en PROD pour cette année'
        RETURN
    END 

    IF Object_ID('tempDB..#TB_ListeConvention') IS NULL
        RAISERROR ('La table « #TB_ListeConvention (RowNo INT Identity(1,1), ConventionID int, ConventionNo varchar(20) » est abesente ', 16, 1)

    SET @vcMessage = '   ' + Convert(varchar(20), GetDate(), 120) + ' Identifie le(s) convention(s)'
    RAISERROR('%s', 0, 1, @vcMessage)
    DECLARE @iCount int = (SELECT Count(*) FROM #TB_ListeConvention)
    IF @iCount > 0
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - ' + LTrim(Str(@iCount)) + ' conventions à vérifier'

    --  Déclaration des variables
    BEGIN 
        DECLARE @StartTimer datetime = GetDate(),
                --@WhileTimer datetime,
                @QueryTimer datetime,
                @ElapseTime datetime,
                --@IntervalPrint INT = 5000,
                @MaxRow INT = (SELECT COUNT(*) FROM #TB_ListeConvention),
                @IsDebug bit = dbo.fn_IsDebug()

        DECLARE 
            @tiID_TypeEnregistrement TINYINT,       @iID_SousTypeEnregistrement INT,
            @dtDebutCotisation DATE,                @dtMinCotisation DATE = '2007-02-21',
            @dtFinCotisation DATE,                  @dtMaxCotisation DATE = DATEADD(DAY, -DAY(GETDATE()), GETDATE()),
            @bPAE_Autorise BIT = 1,                 @vcCaracteresAccents varchar(100) = '%[Å,À,Á,Â,Ã,Ä,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ñ,Ò,Ó,Ô,Õ,Ö,Ù,Ú,Û,Ü,Ý]%',
            @TB_Adresse UDT_tblAdresse
                
        DECLARE 
            @TB_FichierIQEE TABLE (
                iID_Fichier_IQEE INT, 
                --siAnnee_Fiscale INT, 
                dtDate_Creation DATE, 
                dtDate_Traitement_RQ DATE
            )
    END
    
    --  Initialisation des variables
    BEGIN 
        -- Sélectionner dates applicables aux transactions
        SELECT @dtDebutCotisation = Str(@siAnnee_Fiscale, 4) + '-01-01 00:00:00',
               @dtFinCotisation = STR(@siAnnee_Fiscale, 4) + '-12-31 23:59:59'

        IF @dtDebutCotisation < @dtMinCotisation
            SET @dtDebutCotisation = @dtMinCotisation

        IF @dtFinCotisation > @dtMaxCotisation
            SET @dtFinCotisation = @dtMaxCotisation

        -- Récupère les IDs du type & sous-type pour ce type d'enregistrement
        SELECT 
            @tiID_TypeEnregistrement = tiID_Type_Enregistrement,
            @iID_SousTypeEnregistrement = iID_Sous_Type
        FROM
            dbo.vwIQEE_Enregistrement_TypeEtSousType 
        WHERE
            cCode_Type_Enregistrement = '05'
            AND cCode_Sous_Type = '01'

        -- Récupère les fichiers IQEE
        INSERT INTO @TB_FichierIQEE 
            (iID_Fichier_IQEE, /*siAnnee_Fiscale,*/ dtDate_Creation, dtDate_Traitement_RQ)
        SELECT DISTINCT 
            iID_Fichier_IQEE, /*siAnnee_Fiscale,*/ dtDate_Creation, dtDate_Traitement_RQ
        FROM 
            dbo.tblIQEE_Fichiers F
            JOIN dbo.tblIQEE_TypesFichier T ON T.tiID_Type_Fichier = F.tiID_Type_Fichier
        WHERE
            0 = 0 --T.bTeleversable_RQ <> 0
            AND (
                    (bFichier_Test = 0  AND bInd_Simulation = 0)
                    OR iID_Fichier_IQEE = @iID_Fichier_IQEE
                )
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupère les conventions ayant eu un PAE'
    BEGIN

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupère les opérations de PAE'
        BEGIN 
            SET @QueryTimer = GETDATE()

            IF OBJECT_ID('tempDB..#TB_Oper_05_01') IS NOT NULL
                DROP TABLE #TB_Oper_05_01

            SELECT
                S.ConventionID, X.ConventionNo, O.OperID, O.OperDate, O.OperTypeID, 
                S.iIDBeneficiaire, S.ScholarshipAmount, S.ScholarshipStatusID,
                tiTypeEtude = CAST(C.CollegeTypeID AS TINYINT),
                tiDureeProgramme = CAST(SP.ProgramLength AS TINYINT),
                tiAnneeProgramme = CAST(CASE WHEN SP.ProgramYear <= 9 THEN SP.ProgramYear ELSE 9 END AS TINYINT),
                dtDebutAnneeScolaire = SP.StudyStart,
                tiNbSemaineAnneeScolaire = CASE C.CollegeTypeID WHEN '01' THEN 30 ELSE 34 END,
                vcCodeCollege = C.CollegeCode
            INTO
                #TB_Oper_05_01
            FROM 
                dbo.fntOPER_Active(@dtDebutCotisation, @dtFinCotisation) O
                JOIN dbo.Un_ScholarshipPmt SP ON SP.OperID = O.OperID
                JOIN dbo.Un_Scholarship S ON S.ScholarshipID = SP.ScholarshipID
                JOIN #TB_ListeConvention X ON X.ConventionID = S.ConventionID
                JOIN dbo.Un_College C ON C.CollegeID = SP.CollegeID
            WHERE
                O.OperTypeID = 'PAE'
                AND NOT EXISTS(
                    SELECT * FROM dbo.Mo_Company Cie JOIN dbo.Mo_Dep D ON D.CompanyID = Cie.CompanyID
                                                     JOIN dbo.tblGENE_Adresse A ON A.iID_Adresse = D.AdrID
                     WHERE A.cID_Pays = 'CAN' AND Cie.CompanyID = C.CollegeID
                ) 

            SET @iCount = @@ROWCOUNT
            SET @ElapseTime = GetDate() - @QueryTimer
            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '       » ' + LTrim(Str(@iCount)) + ' retrouvée(s) (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

            IF @IsDebug <> 0 --AND @MaxRow BETWEEN 1 AND 5
                SELECT '#TB_Oper', * FROM #TB_Oper_05_01 ORDER BY ConventionID, OperDate
        END
        
        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupère les montants de PAE'
        BEGIN 
            SET @QueryTimer = GETDATE()

            IF OBJECT_ID('tempDB..#TB_Paiement_05_01') IS NOT NULL
                DROP TABLE #TB_Paiement_05_01

            ;WITH 
            CTE_ConvOper_IQEE AS (
                SELECT
                    CO.ConventionID, CO.OperID, 
                    mIQEE_CBQ = -SUM(CASE CO.ConventionOperTypeID WHEN 'CBQ' THEN co.ConventionOperAmount ELSE 0 END), 
                    mIQEE_MMQ = -SUM(CASE CO.ConventionOperTypeID WHEN 'MMQ' THEN co.ConventionOperAmount ELSE 0 END)
                FROM
                    dbo.Un_ConventionOper CO
                    JOIN #TB_Oper_05_01 O ON O.ConventionID = CO.ConventionID AND O.OperID = CO.OperID
                WHERE
                    CO.ConventionOperTypeID IN ('CBQ', 'MMQ')
                GROUP BY
                    CO.ConventionID, CO.OperID
            ),
            CTE_ConvOper_PAE AS (
                SELECT
                    X.ConventionID, X.OperID, 
                    mPAE = SUM(ISNULL(X.mAmount, 0))
                FROM (
                    SELECT
                        O.ConventionID, O.OperID, -(CO.ConventionOperAmount) AS mAmount
                    FROM
                        #TB_Oper_05_01 O
                        JOIN dbo.Un_ConventionOper CO ON CO.ConventionID = O.ConventionID AND CO.OperID = O.OperID
                    WHERE
                        CO.ConventionOperTypeID <> 'AVC'
                    UNION ALL
                    SELECT
                        O.ConventionID, O.OperID, -(C.fCESG + C.fACESG + C.fCLB + C.fCLBFee) AS mAmount
                    FROM
                        #TB_Oper_05_01 O
                        JOIN dbo.Un_CESP C ON C.ConventionID = O.ConventionID AND C.OperID = O.OperID
                    ) X
                GROUP BY
                    X.ConventionID, X.OperID
            ),
            CTE_Paiement AS (
                SELECT
                    X.iID_Convention, X.dtDate_Paiement, X.tiCode_Version, X.cStatut_Reponse
                FROM (
                    SELECT 
                        PB.iID_Convention, PB.dtDate_Paiement, PB.tiCode_Version, PB.cStatut_Reponse,
                        RowNum = ROW_NUMBER() OVER(PARTITION BY PB.iID_Convention, PB.dtDate_Paiement ORDER BY F.dtDate_Creation DESC, ISNULL(PB.iID_Ligne_Fichier, 999999999), PB.iID_Paiement_Beneficiaire DESC)
                    FROM
                        #TB_ListeConvention X
                        JOIN dbo.tblIQEE_PaiementsBeneficiaires PB ON PB.iID_Convention = X.ConventionID
                        JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType T ON T.iID_Sous_Type = PB.iID_Sous_Type
                        JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = PB.iID_Fichier_IQEE
                    WHERE 0=0
                        AND PB.siAnnee_Fiscale = @siAnnee_Fiscale
                        AND NOT PB.cStatut_Reponse IN ('E','X')
                        AND T.cCode_Type_SousType = 'O5-01'
                    ) X
                WHERE
                    X.RowNum = 1
                    AND X.tiCode_Version <> 1
                    AND X.cStatut_Reponse IN ('A','R')
            )
            SELECT 
                O.ConventionID, X.ConventionNo, 
                BeneficiaryID = O.iIDBeneficiaire,
                dtPaiement = O.OperDate,
                cStatut_PAE = O.ScholarshipStatusID,
                bIndRevenuAccumule = 1,
                mIQEE_CreditBase = SUM(ISNULL(I.mIQEE_CBQ, 0)),
                mIQEE_Majoration = SUM(ISNULL(I.mIQEE_MMQ, 0)),
                mPAE_Verse = SUM(ISNULL(P.mPAE, 0)), --SUM(O.ScholarshipAmount),
                mIQEE_Solde = 0,
                O.tiTypeEtude, O.tiDureeProgramme, O.tiAnneeProgramme,
                O.dtDebutAnneeScolaire, O.tiNbSemaineAnneeScolaire, O.vcCodeCollege
            INTO
                #TB_Paiement_05_01
            FROM
                #TB_Oper_05_01 O
                JOIN #TB_ListeConvention X ON X.ConventionID = O.ConventionID
                JOIN dbo.fntIQEE_ConventionConnueRQ_PourTous(NULL, @siAnnee_Fiscale) RQ ON RQ.iID_Convention = X.ConventionID
                LEFT JOIN CTE_Paiement PB ON PB.iID_Convention = O.ConventionID AND PB.dtDate_Paiement = O.OperDate
                LEFT JOIN CTE_ConvOper_IQEE I ON I.ConventionID = O.ConventionID AND I.OperID = O.OperID
                LEFT JOIN CTE_ConvOper_PAE P ON P.ConventionID = O.ConventionID AND P.OperID = O.OperID
            WHERE
                PB.iID_Convention IS NULL 
            GROUP BY
                O.ConventionID, X.ConventionNo, O.iIDBeneficiaire, O.OperDate, O.ScholarshipStatusID,
                O.tiTypeEtude, O.tiDureeProgramme, O.tiAnneeProgramme,
                O.dtDebutAnneeScolaire, O.tiNbSemaineAnneeScolaire, O.vcCodeCollege
            HAVING
                SUM(ISNULL(I.mIQEE_CBQ, 0)) > 0
                OR SUM(ISNULL(I.mIQEE_MMQ, 0)) > 0

            SET @iCount = @@ROWCOUNT
            SET @ElapseTime = GetDate() - @QueryTimer
            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '       » ' + LTrim(Str(@iCount)) + ' retrouvée(s) (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

            IF @iCount = 0 
                RETURN

            IF @iCount < 5
                SET @MaxRow = @iCount

            IF @IsDebug <> 0 --AND @MaxRow BETWEEN 1 AND 5
                SELECT '#TB_PAE', * FROM #TB_Paiement_05_01 ORDER BY ConventionID, dtPaiement
        END
            
        SET ROWCOUNT 0
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération les infos des bénéficiaires'
    BEGIN
        IF Object_ID('tempDB..#TB_Beneficiary_05_01') IS NOT NULL
            DROP TABLE #TB_Beneficiary_05_01

        SET @QueryTimer = GetDate()
        ;WITH CTE_Beneficiary as (
            SELECT DISTINCT
                TB.ConventionID, TB.dtPaiement, TB.BeneficiaryID,
                vcNAS =  ISNULL(H.SocialNumber, ''), -- CASE WHEN HSN.HumanID IS NULL THEN '' ELSE ISNULL(H.SocialNumber, '') END,
                vcNom = LTRIM(H.LastName), 
                vcPrenom = LTRIM(H.FirstName), 
                dtNaissance = H.BirthDate, 
                cSexe = H.SexID
            FROM 
                #TB_Paiement_05_01 TB
                JOIN dbo.Mo_Human H ON H.HumanID = TB.BeneficiaryID
        )
        SELECT 
            TB.*,
            vcNomPrenom = LTrim(RTrim(dbo.fn_Mo_FormatHumanName(TB.vcNom, '', TB.vcPrenom, '', '', 0))),
            A.iID_Adresse, A.bNouveau_Format, A.dtDate_Debut,
            vcAdresse_Tmp = LTrim(RTrim(Coalesce(A.vcNom_Rue, A.vcInternationale1, ''))),
            vcNoCivique = LTrim(RTrim(A.vcNumero_Civique)),
            vcAppartement = LTrim(RTrim(A.vcUnite)),
            vcNomRue = LTrim(RTrim(IsNull(A.vcNom_Rue, A.vcInternationale1))),
            iID_TypeBoite = CASE WHEN LTrim(RTrim(A.vcBoite)) = '' THEN 0 ELSE A.iID_TypeBoite END,
            vcBoite = LTrim(RTrim(A.vcBoite)),
            vcVille = LTrim(RTrim(A.vcVille)),
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
                                          END)),
            A.bResidenceFaitQuebec
        INTO
            #TB_Beneficiary_05_01
        FROM 
            CTE_Beneficiary TB
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = TB.BeneficiaryID
            --LEFT JOIN dbo.fntGENE_ObtenirAdresseEnDate_PourTous(NULL, 1, @dtFinCotisation, 0) A ON A.iID_Source = B.BeneficiaryID AND A.cType_Source = 'H'
            LEFT JOIN dbo.fntGENE_ObtenirAdressesEntre_PourTous(NULL, 1, @dtDebutCotisation, @dtFinCotisation, 0) A ON A.iID_Source = B.BeneficiaryID AND A.cType_Source = 'H'
                                                               AND CAST(TB.dtPaiement AS DATE) BETWEEN A.dtDate_Debut And IsNull(DateAdd(day, -1, A.dtDate_Fin), '9999-12-31')
            
        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
        
        IF EXISTS(SELECT TOP 1 * FROM #TB_Beneficiary_05_01 WHERE iID_Adresse IS NULL)
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
                #TB_Beneficiary_05_01 B 
                JOIN dbo.fntGENE_ObtenirDerniereAdresseConnue(DEFAULT, 1, @dtFinCotisation, 0) A ON A.iID_Source = B.BeneficiaryID
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
                #TB_Beneficiary_05_01 B 
                LEFT JOIN dbo.fntGENE_ObtenirAdressePremiereConnue(DEFAULT, 1, @dtFinCotisation, 0) A ON A.iID_Source = B.BeneficiaryID
            WHERE
                B.iID_Adresse IS NULL 

            SET @iCount = @@ROWCOUNT
            SET @ElapseTime = GetDate() - @QueryTimer
            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées ultérieurement (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
        END

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Corrige les accents dans le nom & prénom des principaux responsables'
        SET @QueryTimer = GetDate()

        DELETE FROM @TB_Adresse

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Corrige le # civique & l''appartement des adresses n''en ayant pas'
        SET @QueryTimer = GetDate()

        INSERT INTO @TB_Adresse (iID_Source, iID_Adresse, vcNoCivique, vcAppartement, vcNomRue, iID_TypeBoite, vcBoite)
        SELECT DISTINCT
            BeneficiaryID, iID_Adresse, vcNoCivique, vcAppartement, vcNomRue, iID_TypeBoite, vcBoite 
        FROM
            #TB_Beneficiary_05_01
        WHERE
            iID_Adresse IS NOT NULL
        --  Len(IsNull(vcNomRue, '')) > 0

        UPDATE TB SET
            vcNoCivique = A.NoCivique,
            vcAppartement = A.Appartement,
            vcNomRue = LTrim(IsNull(A.NomRue, '') + 
                           CASE WHEN Len(IsNull(A.Boite, '')) > 0
                                THEN CASE A.ID_TypeBoite WHEN 1 THEN ' CP ' WHEN 2 THEN ' RR ' ELSE ' #' END + IsNull(A.Boite, '')
                                ELSE '' 
                           END),
            iID_TypeBoite = A.ID_TypeBoite,
            vcBoite = A.Boite
        --OUTPUT inserted.*
        FROM 
            #TB_Beneficiary_05_01 TB
            JOIN dbo.fntIQEE_CorrigerAdresseUserTable(@TB_Adresse) A ON A.iID_Source = TB.BeneficiaryID And A.iID_Adresse = TB.iID_Adresse

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' corrigées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Génère le nom de rue complet'
        SET @QueryTimer = GetDate()

        UPDATE #TB_Beneficiary_05_01 SET
            vcAdresse_Tmp = CASE WHEN Len(IsNull(vcNoCivique, '')) = 0 THEN ''
                                 WHEN vcNoCivique = '-' THEN ''
                                 ELSE CASE WHEN Len(IsNull(vcAppartement, '')) = 0 THEN ''
                                           --WHEN vcAppartement = '-' THEN ''
                                           ELSE vcAppartement + '-'
                                      END + vcNoCivique + ' '
                            END + IsNull(vcNomRue, '')

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' corrigées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        UPDATE TB SET vcProvince = S.StateCode
          FROM #TB_Beneficiary_05_01 TB 
               JOIN dbo.Mo_State S ON S.vcNomWeb_FRA = TB.vcProvince OR S.vcNomWeb_ENU = TB.vcProvince
         WHERE TB.cID_Pays = 'CAN'

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            SELECT * from #TB_Beneficiary_05_01
    END

    --------------------------------------------------------------------------------------------------
    -- Valider les fermetures de convention et conserver les raisons de rejet en vertu des validations
    --------------------------------------------------------------------------------------------------
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Validation des conventions selon les critères RQ'
    BEGIN
        DECLARE
            @iID_Validation INT,                            @iCode_Validation INT, 
            @vcDescription VARCHAR(300),                    @cType CHAR(1), 
            @iCountRejets INT

        IF OBJECT_ID('tempdb..#TB_Rejet_05_01') IS NULL
            CREATE TABLE #TB_Rejets_05_01 (
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
            TRUNCATE TABLE #TB_Rejet_05_01

        -- Sélectionner les validations à faire pour le sous type de transaction
        IF OBJECT_ID('tempdb..#TB_Validation_05_01') IS NOT NULL
            DROP TABLE #TB_Validation_05_01

        SELECT 
            V.iOrdre_Presentation, V.iID_Validation, V.iCode_Validation, V.cType, V.vcDescription_Parametrable as vcDescription
        INTO
            #TB_Validation_05_01
        FROM
            tblIQEE_Validations V
        WHERE 
            V.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
            AND IsNull(V.iID_Sous_Type, 0) = IsNull(@iID_SousTypeEnregistrement, 0)
            AND V.bValidation_Speciale = 0
            AND V.bActif = 1
            AND (
                @cCode_Portee = 'T'
                OR (@cCode_Portee = 'A' AND V.cType = 'E')
                OR (@cCode_Portee = 'I' AND V.bCorrection_Possible = 1)
            )   
        SET @iCount = @@ROWCOUNT
        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   » ' + LTrim(Str(@iCount)) + ' validations à appliquer'

        -- Boucler à travers les validations du sous type de transaction
        DECLARE @iOrdre_Presentation int = 0               
        WHILE Exists(SELECT TOP 1 * FROM #TB_Validation_05_01 WHERE iOrdre_Presentation > @iOrdre_Presentation) 
        BEGIN
            SET @iCountRejets = 0

            SELECT TOP 1
                @iOrdre_Presentation = iOrdre_Presentation,
                @iID_Validation = iID_Validation, 
                @iCode_Validation = iCode_Validation,
                @vcDescription = vcDescription,
                @cType = cType
            FROM
                #TB_Validation_05_01 
            WHERE
                iOrdre_Presentation > @iOrdre_Presentation
            ORDER BY 
                iOrdre_Presentation

            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - Validation #' + LTrim(Str(@iCode_Validation)) + ': ' + @vcDescription

            BEGIN TRY
                -- Validation : Le PAE a déjà été envoyé et une réponse reçue de RQ.
                IF @iCode_Validation = 201 
                BEGIN
                    ; WITH CTE_ReponduRecu AS (
                        SELECT PB.iID_Convention, PB.dtDate_Paiement, PB.tiCode_Version, PB.cStatut_Reponse,
                               Rownum = ROW_NUMBER() OVER(PARTITION BY PB.iID_Convention, PB.dtDate_Paiement ORDER BY FR.dtDate_Traitement_RQ DESC, F.dtDate_Creation DESC, PB.iID_Ligne_Fichier DESC)
                          FROM dbo.tblIQEE_PaiementsBeneficiaires PB
                               JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = PB.iID_Fichier_IQEE 
                               JOIN dbo.tblIQEE_ReponsesPaiement RP ON RP.iID_Paiement_IQEE = PB.iID_Paiement_Beneficiaire
                               JOIN @TB_FichierIQEE FR ON FR.iID_Fichier_IQEE = RP.iID_Fichier_IQEE 
                        WHERE 
                            PB.iID_Sous_Type = @iID_SousTypeEnregistrement
                            AND NOT PB.cStatut_Reponse in ('E', 'X')
                    )
                    --INSERT INTO #TB_Rejets_05_01 (
                    --    iID_Convention, iID_Validation, vcDescription,
                    --    vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    --)
                    --SELECT 
                    --    ConventionID, @iID_Validation, REPLACE(@vcDescription, '%dtPaiement%', CONVERT(VARCHAR(10), R.dtDate_Paiement, 120)),
                    --    NULL, NULL, NULL, NULL, NULL
                    DELETE FROM TB
                    FROM
                        #TB_Paiement_05_01 TB
                        JOIN CTE_ReponduRecu R ON R.iID_Convention = TB.ConventionID AND R.dtDate_Paiement = TB.dtPaiement
                    WHERE
                        R.Rownum = 1
                        AND R.cStatut_Reponse = 'R'
                        AND R.tiCode_Version <> 1

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : Le PAE est en cours de traitement par RQ et est en attente d’une réponse de Revenu Québec.
                IF @iCode_Validation = 202
                BEGIN
                    ; WITH CTE_ReponduRecu AS (
                        SELECT PB.iID_Convention, PB.dtDate_Paiement, PB.tiCode_Version, PB.cStatut_Reponse,
                               Rownum = ROW_NUMBER() OVER(PARTITION BY PB.iID_Convention, PB.dtDate_Paiement ORDER BY F.dtDate_Creation DESC, PB.iID_Ligne_Fichier DESC)
                          FROM dbo.tblIQEE_PaiementsBeneficiaires PB
                               JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = PB.iID_Fichier_IQEE 
                        WHERE 
                            PB.iID_Sous_Type = @iID_SousTypeEnregistrement
                            AND NOT PB.cStatut_Reponse in ('E', 'X')
                    )
                    --INSERT INTO #TB_Rejets_05_01 (
                    --    iID_Convention, iID_Validation, vcDescription,
                    --    vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    --)
                    --SELECT 
                    --    ConventionID, @iID_Validation, REPLACE(@vcDescription, '%dtPaiement%', CONVERT(VARCHAR(10), R.dtDate_Paiement, 120)),
                    --    NULL, NULL, NULL, NULL, NULL
                    DELETE FROM TB
                    FROM
                        #TB_Paiement_05_01 TB
                        JOIN CTE_ReponduRecu R ON R.iID_Convention = TB.ConventionID AND R.dtDate_Paiement = TB.dtPaiement
                    WHERE
                        R.Rownum = 1
                        AND R.cStatut_Reponse = 'A'
                        AND R.tiCode_Version <> 1

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : Une erreur soulevée par Revenu Québec est en cours de traitement pour le PAE
                IF @iCode_Validation = 203
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtPaiement
                        FROM
                            #TB_Paiement_05_01 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_PaiementsBeneficiaires PB
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = PB.iID_Fichier_IQEE 
                                              JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = PB.iID_Paiement_Beneficiaire
                                              JOIN dbo.tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                                                                               AND SE.vcCode_Statut = 'ATR'
                                WHERE 
                                    PB.iID_Convention = C.ConventionID
                                    AND E.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
                                    AND PB.iID_Sous_Type = @iID_SousTypeEnregistrement
                                    AND PB.dtDate_Paiement = C.dtPaiement
                                    AND PB.cStatut_Reponse = 'E'
                            )
                    )
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        CTE_Convention

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : Le NAS du bénéficiaire du PAE est absent ou invalide
                IF @iCode_Validation = 204
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtPaiement, B.BeneficiaryID, B.vcNomPrenom, B.vcNAS
                        FROM
                            #TB_Paiement_05_01 C
                            JOIN #TB_Beneficiary_05_01 B ON B.ConventionID = C.ConventionID AND B.dtPaiement = C.dtPaiement
                        WHERE
                            Len(IsNull(B.vcNAS, '')) = 0
                            OR dbo.FN_CRI_CheckSin(B.vcNAS, 0) = 0
                    )
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        NULL, vcNAS, NULL, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : Le nom du bénéficiaire du PAE est absent ou invalide
                IF @iCode_Validation = 205
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtPaiement, B.BeneficiaryID
                        FROM
                            #TB_Paiement_05_01 C
                            JOIN #TB_Beneficiary_05_01 B ON B.ConventionID = C.ConventionID AND B.dtPaiement = C.dtPaiement
                        WHERE
                            Len(IsNull(B.vcNom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : Le prénom du bénéficiaire du PAE est absent ou invalide
                IF @iCode_Validation = 206
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtPaiement, B.BeneficiaryID
                        FROM
                            #TB_Paiement_05_01 C
                            JOIN #TB_Beneficiary_05_01 B ON B.ConventionID = C.ConventionID AND B.dtPaiement = C.dtPaiement
                        WHERE
                            Len(IsNull(B.vcPrenom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : La date de naissance du bénéficiaire du PAE est absent
                IF @iCode_Validation = 207
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtPaiement, B.BeneficiaryID, B.vcNomPrenom
                        FROM
                            #TB_Paiement_05_01 C
                            JOIN #TB_Beneficiary_05_01 B ON B.ConventionID = C.ConventionID AND B.dtPaiement = C.dtPaiement
                        WHERE
                            IsNull(B.dtNaissance, '1900-01-01') = '1900-01-01'
                    )
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, NULL, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : La date de naissance du bénéficiaire du PAE est plus grande que la date du PAE
                IF @iCode_Validation = 208
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtPaiement, B.BeneficiaryID, B.vcNomPrenom, B.dtNaissance
                        FROM
                            #TB_Paiement_05_01 C
                            JOIN #TB_Beneficiary_05_01 B ON B.ConventionID = C.ConventionID AND B.dtPaiement = C.dtPaiement
                        WHERE
                            B.dtNaissance > C.dtPaiement
                    )
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        CONVERT(VARCHAR(10), dtPaiement, 120), CONVERT(VARCHAR(10), dtNaissance, 120), NULL, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : Le sexe du bénéficiaire du PAE n’est pas défini
                IF @iCode_Validation = 209
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtPaiement, B.BeneficiaryID, B.vcNomPrenom, B.cSexe
                        FROM
                            #TB_Paiement_05_01 C
                            JOIN #TB_Beneficiary_05_01 B ON B.ConventionID = C.ConventionID AND B.dtPaiement = C.dtPaiement
                        WHERE
                            IsNull(B.cSexe, '') NOT IN ('F', 'M')
                    )
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, NULL, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : Le prénom du bénéficiaire de PAE contient au moins 1 caractère non conforme
                IF @iCode_Validation = 210
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtPaiement, B.BeneficiaryID, B.vcNomPrenom, B.vcPrenom, 
                            vcNonConforme = dbo.fnIQEE_ValiderNom(B.vcPrenom)
                        FROM
                            #TB_Paiement_05_01 C
                            JOIN #TB_Beneficiary_05_01 B ON B.ConventionID = C.ConventionID AND B.dtPaiement = C.dtPaiement
                    )
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), '%vcCaractereNonConforme%', vcNonConforme),
                        NULL, vcPrenom, NULL, BeneficiaryID, NULL
                    FROM
                        CTE_Convention
                    WHERE
                        Len(vcNonConforme) > 0

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : Le nom du bénéficiaire de PAE contient au moins 1 caractère non conforme
                IF @iCode_Validation = 211
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtPaiement, B.BeneficiaryID, B.vcNomPrenom, B.vcNom, 
                            vcNonConforme = dbo.fnIQEE_ValiderNom(B.vcNom)
                        FROM
                            #TB_Paiement_05_01 C
                            JOIN #TB_Beneficiary_05_01 B ON B.ConventionID = C.ConventionID AND B.dtPaiement = C.dtPaiement
                    )
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom), '%vcCaractereNonConforme%', vcNonConforme),
                        NULL, vcNom, NULL, BeneficiaryID, NULL
                    FROM
                        CTE_Convention
                    WHERE
                        Len(vcNonConforme) > 0

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : L'année du programme EPS doit être plus grande que 0.
                IF @iCode_Validation = 212
                BEGIN
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        #TB_Paiement_05_01 C
                    WHERE
                        C.tiAnneeProgramme <= 0

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : La date de début de l'année scolaire est absente.
                IF @iCode_Validation = 213
                BEGIN
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        #TB_Paiement_05_01 C
                    WHERE
                        ISNULL(C.dtDebutAnneeScolaire, '1900-01-01') < '1950-01-01'

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : Le code postal de l'établissement d'enseignement est absent (code postal de l'adresse ou code du collège).
                IF @iCode_Validation = 214
                BEGIN
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        #TB_Paiement_05_01 C
                    WHERE
                        LEN(ISNULL(C.vcCodeCollege, '')) = 0 

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : L'année du programme associée au PAE est plus grande que 5.
                IF @iCode_Validation = 215
                BEGIN
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        #TB_Paiement_05_01 C
                    WHERE
                        ISNULL(C.tiAnneeProgramme, 0) > 5 

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : Le dernier statut du chèque associé au PAE est différent de "Imprimé".
                IF @iCode_Validation = 216
                BEGIN
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, cStatut_PAE, NULL, NULL, NULL
                    FROM
                        #TB_Paiement_05_01
                    WHERE
                        cStatut_PAE <> 'PAD'

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : Le montant total du PAE calculé doit être plus grand que 0
                IF @iCode_Validation = 217
                BEGIN
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, LTRIM(STR(mPAE_Verse, 10, 2)), NULL, NULL, NULL
                    FROM
                        #TB_Paiement_05_01
                    WHERE
                        mPAE_Verse <= 0

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : Le «PAE» précédant doit être déclaré à RQ avant que le PAE puisse être déclaré
                IF @iCode_Validation = 218
                BEGIN
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT
                        TB.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%dtPaiement%', CONVERT(VARCHAR(10), PB.OperDate, 120)), '%ScholarshipNo%', TB.ConventionNo),
                        NULL, NULL, NULL, NULL, PB.ScholarshipNo
                    FROM
                        dbo.fntIQEE_PaiementBeneficiaire_NonDeclare(DEFAULT, @dtDebutCotisation) PB
                        JOIN #TB_Paiement_05_01 TB ON TB.ConventionID = PB.ConventionID
                    WHERE
                        PB.OperDate < @dtDebutCotisation

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : Le transfert doit être déclaré à RQ avant que le PAE puisse être déclaré
                IF @iCode_Validation = 219
                BEGIN
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT 
                        TB.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%dtTransfert%', CONVERT(VARCHAR(10), T.OperDate, 120)), '%OperTypeID%', T.OperTypeID), 
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        #TB_Paiement_05_01 TB
                        JOIN dbo.fntIQEE_Transfert_NonDeclare(DEFAULT, @dtFinCotisation) T ON T.ConventionID = TB.ConventionID
                    WHERE
                        T.OperDate < TB.dtPaiement

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : Le retrait doit être déclaré à RQ avant que le PAE puisse être déclaré
                IF @iCode_Validation = 220
                BEGIN
                    ; WITH CTE_Oper AS (
                        SELECT DISTINCT U.ConventionID, O.OperDate, O.OperTypeID
                          FROM dbo.fntOPER_Active('2007-02-21', @dtFinCotisation) O
                               JOIN dbo.Un_Cotisation Ct ON Ct.OperID = O.OperID
                               JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                               JOIN dbo.fntIQEE_ConventionConnueRQ_PourTous(NULL, @siAnnee_Fiscale) RQ ON RQ.iID_Convention = U.ConventionID
                         WHERE Ct.Cotisation + Ct.Fee < 0
                           AND O.OperDate > RQ.dtReconnue_RQ
                           AND EXISTS(SELECT * FROM #TB_Paiement_05_01 TB WHERE TB.ConventionID = U.ConventionID)
                    ),
                    CTE_ImpotSpecial AS (
                        SELECT
                            X.iID_Convention, X.dtDate_Evenement, X.tiCode_Version, X.cStatut_Reponse, X.iID_Ligne_Fichier
                        FROM (
                            SELECT 
                                I.iID_Convention, I.dtDate_Evenement, TST.cCode_Type_SousType, I.tiCode_Version, I.cStatut_Reponse, I.iID_Ligne_Fichier,
                                RowNum = ROW_NUMBER() OVER(PARTITION BY I.iID_Convention, I.dtDate_Evenement, TST.cCode_Type_SousType ORDER BY F.dtDate_Creation DESC, ISNULL(I.iID_Ligne_Fichier, 999999999), I.iID_Impot_Special DESC)
                            FROM
                                dbo.tblIQEE_ImpotsSpeciaux I
                                JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
                                JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TST ON TST.iID_Sous_Type = I.iID_Sous_Type AND TST.cCode_Type_Enregistrement = '06'
                            WHERE 0=0
                                AND I.siAnnee_Fiscale <= @siAnnee_Fiscale
                                AND NOT I.cStatut_Reponse IN ('E','X')
                                AND EXISTS(SELECT * FROM #TB_Paiement_05_01 TB WHERE TB.ConventionID = I.iID_Convention)
                            ) X
                        WHERE
                            X.RowNum = 1
                            AND X.tiCode_Version <> 1
                            AND X.cStatut_Reponse = 'R'       
                    )
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT 
                        TB.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%OperTypeID%', O.OperTypeID), '%dtEvenement%', CONVERT(VARCHAR(10), O.OperDate, 120)),
                        NULL, NULL, TB.ConventionID, NULL, NULL
                    FROM
                        #TB_Paiement_05_01 TB
                        JOIN CTE_Oper O ON O.ConventionID = TB.ConventionID --AND O.dtPaiement = TB.dtPaiement
                        LEFT JOIN CTE_ImpotSpecial I ON O.ConventionID = I.iID_Convention AND I.dtDate_Evenement = O.OperDate
                    WHERE
                        I.iID_Convention IS NULL 
                        AND O.OperDate < TB.dtPaiement

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END

                -- Validation : La convention a été fermée par une transaction d'impôt spécial 91 ou 51
                IF @iCode_Validation = 222
                BEGIN
                    ;WITH CTE_Impot_91 AS (
                        SELECT
                            X.iID_Convention, X.dtDate_Evenement, X.tiCode_Version, X.cStatut_Reponse, X.iID_Ligne_Fichier
                        FROM (
                            SELECT 
                                I.iID_Convention, I.dtDate_Evenement, T.cCode_Type_SousType, I.tiCode_Version, I.cStatut_Reponse, I.iID_Ligne_Fichier,
                                RowNum = ROW_NUMBER() OVER(PARTITION BY I.iID_Convention, I.dtDate_Evenement, T.cCode_Type_SousType ORDER BY F.dtDate_Creation DESC, ISNULL(I.iID_Ligne_Fichier, 999999999), I.iID_Impot_Special DESC)
                            FROM
                                #TB_ListeConvention X
                                JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Convention = X.ConventionID 
                                JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
                                JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType T ON T.iID_Sous_Type = I.iID_Sous_Type
                            WHERE 0=0
                                AND I.siAnnee_Fiscale = @siAnnee_Fiscale
                                AND NOT I.cStatut_Reponse IN ('E','X')
                                AND T.cCode_Type_Enregistrement = 'O6'
                                AND T.cCode_Sous_Type IN ('51', '91')
                            ) X
                        WHERE
                            X.RowNum = 1
                            AND X.tiCode_Version <> 1
                            AND X.cStatut_Reponse IN ('A','R')        
                    )
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT 
                        P.ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        #TB_Paiement_05_01 P
                        JOIN CTE_Impot_91 I ON I.iID_Convention = P.ConventionID
                    WHERE
                        I.dtDate_Evenement < P.dtPaiement

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END
                
                -- Validation : La convention a des cas spéciaux non résolus avec Revenu Québec en cours.
                IF @iCode_Validation = 223
                BEGIN
                    INSERT INTO #TB_Rejets_05_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcNo_Convention%', TB.ConventionNo),
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        #TB_Paiement_05_01 TB
                        JOIN dbo.tblIQEE_CasSpeciaux CS ON CS.iID_Convention = TB.ConventionID
                    WHERE
                        CS.bCasRegle = 0
                        AND ISNULL(CS.tiID_TypeEnregistrement, @tiID_TypeEnregistrement) = @tiID_TypeEnregistrement
                        AND ISNULL(CS.iID_SousType, @iID_SousTypeEnregistrement) = @iID_SousTypeEnregistrement

                    SELECT @iCountRejets = @@ROWCOUNT,
                           @iCount = COUNT(DISTINCT iID_Convention) FROM #TB_Rejets_05_01 WHERE iID_Validation = @iID_Validation
                END
            END TRY
            BEGIN CATCH
                PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » *** ERREUR_VALIDATION ***'
                PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     »     ' + ERROR_MESSAGE()

                INSERT INTO ##tblIQEE_RapportCreation 
                    (cSection, iSequence, vcMessage)
                SELECT
                    '3', 10, '       '+CONVERT(VARCHAR(25),GETDATE(),121)+'     '+vcDescription_Parametrable + ' ' + LTrim(Str(@iCode_Validation))
                FROM
                    dbo.tblIQEE_Validations
                WHERE 
                    iCode_Validation = 200

                RETURN -1
            END CATCH

            -- S'il y a eu des rejets de validation
            IF @iCountRejets > 0
            BEGIN
                PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCountRejets)) + CASE @cType WHEN 'E' THEN ' rejet(s)'
                                                                                                                         WHEN 'A' THEN ' avertissement(s)'
                                                                                                                         ELSE ''
                                                                                                             END + ' pour ' + LTrim(Str(@iCount)) + ' convention(s)'
                -- Et si on traite seulement les 1ères erreurs de chaque convention
                IF @bArretPremiereErreur = 1 AND @cType = 'E'
                BEGIN
                    -- Efface que les conventions ayant un rejet sur la validation courante
                    DELETE FROM P
                      FROM #TB_Paiement_05_01 P
                           JOIN #TB_Rejets_05_01 R ON R.iID_Convention = P.iID_Convention
                     WHERE iID_Validation = @iID_Validation
                END
            END
        END -- IF @iCode_Validation 

        -- Efface tous les conventions ayant eu au moins un rejet de validation
        
        DELETE FROM P
          FROM #TB_Paiement_05_01 P
               JOIN #TB_Rejets_05_01 R ON R.iID_Convention = P.ConventionID
               JOIN dbo.tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
         WHERE V.cType = 'E'

        INSERT INTO dbo.tblIQEE_Rejets (
            iID_Fichier_IQEE, siAnnee_Fiscale, iID_Convention, iID_Validation, vcDescription,
            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
            --,tCommentaires, iID_Utilisateur_Modification, dtDate_Modification
        )
        SELECT 
            @iID_Fichier_IQEE, @siAnnee_Fiscale, R.iID_Convention, R.iID_Validation, R.vcDescription,
            R.vcValeur_Reference, vcValeur_Erreur, R.iID_Lien_Vers_Erreur_1, R.iID_Lien_Vers_Erreur_2, R.iID_Lien_Vers_Erreur_3
        FROM 
            #TB_Rejets_05_01 R
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Déclaration des PAEs'
    BEGIN
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   Créer les enregistrements des PAEs OUT.'
        SET @QueryTimer = GetDate()
        ; WITH CTE_Sexe as (
            SELECT X.rowID as ID, X.strField as Code
            FROM ProAcces.fn_SplitIntoTable('F,M', ',') X
        )
        INSERT INTO dbo.tblIQEE_PaiementsBeneficiaires (
            iID_Fichier_IQEE, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse, iID_Convention, vcNo_Convention,  iID_Sous_Type,  
            dtDate_Paiement, bRevenus_Accumules, mCotisations_Retirees, mIQEE_CreditBase, mIQEE_Majoration, mPAE_Verse, 
            mSolde_IQEE, mJuste_Valeur_Marchande, mCotisations_Versees, mBEC_Autres_Beneficiaires, mBEC_Beneficiaire, mSolde_SCEE, mProgrammes_Autres_Provinces,
            iID_Beneficiaire, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire,  bResidence_Quebec,
            tiType_Etudes, tiDuree_Programme, tiAnnee_Programme, dtDate_Debut_Annee_Scolaire, tiDuree_Annee_Scolaire, vcCode_Postal_Etablissement, vcNom_Etablissement
        )
        SELECT
            @iID_Fichier_IQEE, @siAnnee_Fiscale, @tiCode_Version, 'A', PB.ConventionID, PB.ConventionNo,  @iID_SousTypeEnregistrement,  
            PB.dtPaiement, PB.bIndRevenuAccumule, 0, PB.mIQEE_CreditBase, PB.mIQEE_Majoration, mPAE_Verse, 
            0, 0, 0, 0, 0, 0, 0,
            B.BeneficiaryID, B.vcNAS, Left(B.vcNom, 20), Left(B.vcPrenom, 20), B.dtNaissance,  (SELECT ID FROM CTE_Sexe WHERE Code = B.cSexe), 
                ResidenceFaitQuebec = CASE Left(ISNULL(B.vcProvince, ''), 2) WHEN 'QC' THEN 1 ELSE B.bResidenceFaitQuebec END,
            PB.tiTypeEtude, PB.tiDureeProgramme, PB.tiAnneeProgramme, PB.dtDebutAnneeScolaire, PB.tiNbSemaineAnneeScolaire, PB.vcCodeCollege, NULL
        FROM
            #TB_Paiement_05_01 PB
            JOIN #TB_Beneficiary_05_01 B ON B.ConventionID = PB.ConventionID AND B.dtPaiement = PB.dtPaiement
            LEFT JOIN dbo.fntIQEE_ObtenirDateEnregistrementRQ_PourTous(DEFAULT) DE ON DE.iID_Convention = PB.ConventionID

        SET @iCount = @@RowCount
        SET @ElapseTime = @QueryTimer - GetDate()
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' enregistrements ajoutés (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
    END

    SET @ElapseTime = GetDate() - @StartTimer
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions05_01 completed' 
                + ' (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

    IF OBJECT_ID('tempdb..#TB_Validation_05_01') IS NOT NULL
        DROP TABLE #TB_Validation_05_01
    IF OBJECT_ID('tempdb..#TB_Rejets_05_01') IS NOT NULL
        DROP TABLE #TB_Rejets_05_01
    IF OBJECT_ID('tempdb..#TB_Beneficiary_05_01') IS NOT NULL
        DROP TABLE #TB_Beneficiary_05_01
    IF OBJECT_ID('tempdb..#TB_Paiement_05_01') IS NOT NULL
        DROP TABLE #TB_Paiement_05_01

    -- Retourner 0 si le traitement est réussi
    RETURN 0
END
