/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : psIQEE_CreerTransactions06_22
Nom du service  : Créer les transactions de  type 06, sous type 22 - Retrait prématuré de cotisations
But             : Sélectionner, valider et créer les transactions de type 06 – Impôt spécial, 22 - Retrait
                  prématuré de cotisations, dans un nouveau fichier de transactions de l’IQÉÉ.
Facette         : IQÉÉ

Paramètres d’entrée :
    Paramètre               Description
    --------------------    -----------------------------------------------------------------
    iID_Fichier_IQEE        Identifiant du nouveau fichier de transactions dans lequel les transactions 06-22 doivent être créées.
    @bFichiers_Test         Indicateur si les fichiers test doivent être tenue en compte dans la production du fichier.  
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

Exemple d’appel :   exec dbo.psIQEE_CreerTransactions06_22 10, 0, NULL, 0, 'T',0

Paramètres de sortie:
    Champ               Description
    ------------        ------------------------------------------
    iCode_Retour        = 0 : Exécution terminée normalement
                        < 0 : Erreur de traitement

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    --------------------------------------------------------------------------
    2009-04-22  Éric Deshaies           Création du service                        
    2012-05-28  Eric Michaud            Projet septembre 2012    
    2012-08-14  Stéphane Barbeau        Ajout OR (O.OperTypeID = 'IQE' AND CO.ConventionOperAmount < 0.00) pour le calcul du solde de l'IQEE et IQEE+.
    2012-08-17  Dominique Pothier       Désactivation validation 1104
    2012-08-17  Stéphane Barbeau        Ajout du traitement IF @mSolde_IQEE < 0 
    2012-08-20  Stéphane Barbeau        Ajustement traitement variable @mCotisations_Donne_Droit_IQEE et appels des fonctions fnIQEE_CalculerSoldeCreditBase_Convention et fnIQEE_CalculerSoldeMajoration_Convention.
    2012-08-21  Stéphane Barbeau        Ajustement formule division de l'impôt spécial, mise en valeur absolue la valeur de C et ajustement assignation de la valeur de B
    2012-08-22  Stéphane Barbeau        Ajout d'une clause IF sur le traitement @mCotisations_Donne_Droit_IQEE
    2012-08-22  Stéphane Barbeau        Ajustements validation 1114.        
    2012-12-07  Stéphane Barbeau        Ajout du paramètre @iID_Utilisateur_Creation et appel psIQEE_CreerOperationFinanciereIQE_DeclarationImpotsSpeciaux pour créer l'opération IQE directement.
    2012-12-07  Stéphane Barbeau        Ajustements des calculs de @mIQEE_ImpotSpecial et @mSolde_IQEE_Base pour empêcher les écarts de 0,01$.
    2013-08-09  Stéphane Barbeau        Désactivation validation 1103
    2013-10-18  Stéphane Barbeau        Réduction des Appels à psIQEE_AjouterRejet pour le rejet générique: condition IF @iResultat <= 0 changée pour IF @iResultat <> 0
                                        Raison: Unless documented otherwise, all system stored procedures return a value of 0. This indicates success and a nonzero value indicates failure.
    2013-11-06  Stéphane Barbeau        Requête curImpotSpecial22: Ajout du paramètre @dtFinCotisation dans la fonction fnIQEE_ConventionConnueRQ                                                    
                                        et exclusion si impôt spécial 91 déjà créé.
    2013-12-13  Stéphane Barbeau        Requête -- S'il n'y a pas d'erreur, créer la transaction 06-22: Retrait du critère lié au critère AND R.iID_Lien_Vers_Erreur_1 = @iID_Convention_Selectionne
    2014-08-13  Stéphane Barbeau        Ajout validation #1115 et paramètre @bit_CasSpecial..
    2015-12-01  Steeve Picard           Utilisation de la nouvelle fonction «fntCONV_ObtenirStatutConventionEnDate_PourTous»
    2015-12-16  Steeve Picard           Activation de la validation #1103
    2016-01-08  Steeve Picard           Correction au niveau des validations pour tenir compte de la Convention_ID
    2016-02-02  Steeve Picard           Optimisation en remplaçant les curseurs SQL par des boucles WHILE
    2016-02-19  Steeve Picard           Retrait des 2 derniers paramètres de « fnIQEE_ConventionConnueRQ »
    2016-03-01  Steeve Picard           Ne pas déduire le montant de RIN avec preuve du total de cotisation subventionnable
    2016-03-16  Steeve Picard           Optimisation en traitant par batch et non une convention à la fois
    2016-05-17  Steeve Picard           Correction pour exclure seulement les conventions fermés à la fin de la période et non ayant fermé et réouverte
    2016-06-09  Steeve Picard           Correction d'un bug TI-3564 (Jira)
                                        Optimisation en utilisant plusieurs tables temporaires
    2016-10-04  Steeve Picard           Changement de la validation pour rejeter les conventions avec une des opérations TRI/RIM/OUT
    2016-12-14  Steeve Picard           Optimisation en traitant par batch et non une convention à la fois
    2017-06-09  Steeve Picard           Ajout du paramètre « @tiCode_Version = 0 » pour passer la valeur « 2 » lors d'une annulation/reprise
    2017-07-10  Steeve Picard           Appel à «psIQEE_CreerOperationFinanciere_ImpotsSpeciaux» seulement s'il y a eu création d'au moins une transaction
    2017-07-11  Steeve Picard           Élimination du paramètre « iID_Convention » pour toujours utiliser la table « #TB_ListeConvention »
    2017-09-15  Steeve Picard           Modificiation à la fonction «fntIQEE_CalculerMontantsDemande_PourTous» qui ne retourne plus le champ «mTotal_Cotisations_Subventionnables»
    2017-12-19  Steeve Picard           Modificiation à la fonction «fntIQEE_CalculerMontantsDemande_PourTous» qui retourne aussi la «RIN_SansPreuve»
    2018-01-04  Steeve Picard           Validation de base si @cCode_Portee = '' pour l'estimation du rapport à recevoir
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments «tblIQEE_ImpotsSpeciaux»
    2018-02-26  Steeve Picard           Empêcher que la «dtFinCotisation» soit plus grande que la dernière fin de mois
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
    2018-09-19  Steeve Picard           Ajout du champ «iID_SousType» à la table «tblIQEE_CasSpeciaux» pour pouvoir filtrer
    2018-09-19  Steeve Picard           Ajout du champ «iID_SousType» à la table «tblIQEE_CasSpeciaux» pour pouvoir filtrer
    2018-09-20  Steeve Picard           Ajout de la vérification que l'opération «AVC» ait été déclarée préalablement au même titre que les «PAE»
    2018-11-27  Steeve Picard           Ne bloquer la déclaration que si elle a de l'IQÉÉ dans le PAE antérieur et ignorer les opérations «AVC» en fait de compte
    2018-12-06  Steeve Picard           Utilisation des nouvelles fonctions «fntIQEE_Transfert_NonDeclare & fntIQEE_PaiementBeneficiaire_NonDeclare»
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_CreerTransactions06_22]
(
    @iID_Fichier_IQEE INT,
    @siAnnee_Fiscale SMALLINT,
    @bArretPremiereErreur BIT,
    @cCode_Portee CHAR(1),
    @iID_Utilisateur_Creation INT,
    @bit_CasSpecial BIT,
    @tiCode_Version TINYINT = 0
)
AS
BEGIN
    SET NOCOUNT ON

    PRINT ''
    PRINT 'Impôt spécial de sous type 22 - Retrait prématuré de cotisation (T06-22) pour ' + STR(@siAnnee_Fiscale, 4)
    PRINT '----------------------------------------------------------------------------------'
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions06_22 started'

    IF Object_ID('tempDB..#TB_ListeConvention') IS NULL
        RAISERROR ('La table « #TB_ListeConvention (RowNo INT Identity(1,1), ConventionID int, ConventionNo varchar(20) » est abesente ', 16, 1)

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Identifie le(s) convention(s)'
    DECLARE @iCount int = (SELECT Count(*) FROM #TB_ListeConvention)
    IF @iCount > 0
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - ' + LTrim(Str(@iCount)) + ' conventions à génèrées'

    DECLARE @StartTimer datetime = GetDate(),
            @QueryTimer datetime,
            @ElapseTime datetime,
            --@IntervalPrint INT = 5000,
            @MaxRow INT = 0,
            @IsDebug bit = dbo.fn_IsDebug()

    --  Déclaration des variables
    BEGIN 
        DECLARE 
            @tiID_TypeEnregistrement TINYINT,       @iID_SousTypeEnregistrement INT,
            @dtDebutCotisation DATE,                @dtMinCotisation DATE = '2007-02-21',
            @dtFinCotisation DATE,                  @dtMaxCotisation DATE = DATEADD(DAY, -DAY(GETDATE()), GETDATE()),
            @vcNo_Convention VARCHAR(15)
    
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
        cCode_Type_Enregistrement = '06'
        AND cCode_Sous_Type = '22'

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

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération des conventions à déclarer'
    BEGIN
        IF OBJECT_ID('tempdb..#TB_Convention_06_22') IS NOT NULL
            DROP TABLE #TB_Convention_06_22
    
        SET ROWCOUNT @MaxRow

        -- Identifier et sélectionner les retraits et bénéficiaire admissible au PAE
        SET @QueryTimer = GetDate()
        ;WITH CTE_Oper AS (
            SELECT
                O.OperID
            FROM
                dbo.Un_Oper O
                LEFT JOIN dbo.Un_OperCancelation OCS ON OCS.OperSourceID = O.OperID
                LEFT JOIN dbo.Un_OperCancelation OC ON OC.OperID = O.OperID
            WHERE
                OC.OperID IS NULL AND OCS.OperSourceID IS NULL
        ),
        CTE_Cotisation as (
            SELECT DISTINCT
                ct.UnitID --, Sum(Ct.Cotisation + Ct.Fee) AS TotalCotisationFee
            FROM
                dbo.Un_Cotisation Ct
                JOIN CTE_Oper O ON O.OperId = Ct.OperId
            WHERE
                Ct.EffectDate Between @dtDebutCotisation And @dtFinCotisation 
            GROUP BY 
                ct.UnitID
            HAVING
                Sum(Ct.Cotisation + Ct.Fee) < 0
        )
        SELECT DISTINCT 
            X.ConventionID, X.ConventionNo,
            BeneficiaryID = (SELECT BeneficiaryID FROM dbo.Un_Convention WHERE ConventionID = X.ConventionID)
        INTO
            #TB_Convention_AvecRetrait
        FROM 
            CTE_Cotisation Ct
            JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
            JOIN #TB_ListeConvention X ON X.ConventionID = U.ConventionID AND X.dtReconnue_RQ IS NOT NULL
         WHERE 0 = 0
            AND X.ConventionStateID <> 'FRM'
            AND NOT Exists (
                    SELECT * FROM dbo.tblIQEE_ImpotsSpeciaux I
                                  JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType T ON T.iID_Sous_Type = I.iID_Sous_Type
                                                                                 AND T.cCode_Sous_Type = '91'
                     WHERE I.iID_Convention = X.ConventionID
                       AND I.tiCode_Version IN (0,2)
                       AND I.cStatut_Reponse = 'R'
                )
        SET @iCount = @@rowCount
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' ayant eu un retrait (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        SET @QueryTimer = GetDate()
        ;WITH CTE_Subvention AS (
            SELECT iID_Convention, mCotisations, mTransfert_IN, mTotal_Cotisations, mTotal_RIN_SansPreuve,
                   mTotal_Retrait = mTotal_RIN_SansPreuve - (mCotisations + mTransfert_IN)
              FROM dbo.fntIQEE_CalculerMontantsDemande_PourTous(NULL, @dtDebutCotisation, @dtFinCotisation, DEFAULT)
             WHERE mTotal_Subventionnables = 0
        )
        SELECT DISTINCT 
            Ct.ConventionID, Ct.ConventionNo, Ct.BeneficiaryID, 
            S.mCotisations, S.mTransfert_IN, S.mTotal_Cotisations, mTotal_Retrait
        INTO
            #TB_Convention_06_22
        FROM
            #TB_Convention_AvecRetrait Ct
            JOIN CTE_Subvention S ON S.iID_Convention = Ct.ConventionID
        WHERE S.mTotal_Retrait < 0

        SET @iCount = @@rowCount
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' à traitées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        SET ROWCOUNT 0

        IF NOT EXISTS(SELECT TOP 1 * FROM #TB_Convention_06_22)
           RETURN

        IF @iCount < 5
            SET @MaxRow = @iCount

        -- Trouver les bénéficiaires à la fin de l'année fiscale
        SET @QueryTimer = GetDate()
        UPDATE C SET 
            BeneficiaryID = B.iID_Beneficiaire
        FROM 
            #TB_Convention_06_22 C
            JOIN dbo.fntCONV_ObtenirBeneficiaireParConventionEnDate(@dtFinCotisation, NULL) B ON B.iID_Convention = C.ConventionID
        WHERE
            C.BeneficiaryID <> B.iID_Beneficiaire

        SET @iCount = @@rowCount
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' bénéficiares revisés (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            select '#TB_Convention_06_22', * from #TB_Convention_06_22 ORDER BY ConventionID

        IF OBJECT_ID('tempdb..#TB_Beneficiary_06_22') IS NOT NULL
            DROP TABLE #TB_Beneficiary_06_22

        SET @QueryTimer = GetDate()
        ;WITH CTE_Beneficiary AS (
            SELECT DISTINCT
                C.BeneficiaryID, LTrim(H.LastName) as Nom, LTrim(H.FirstName) as Prenom, H.SexID as Sexe, H.BirthDate as DateNaissance, H.SocialNumber as NAS
            FROM
                #TB_Convention_06_22 C
                JOIN dbo.Mo_Human H ON H.HumanID = C.BeneficiaryID
        )
        SELECT DISTINCT
            B.BeneficiaryID, B.Nom, B.Prenom, B.Sexe, B.DateNaissance,
            dbo.fn_Mo_FormatHumanName(B.Nom, '', B.Prenom, '', '', 0) as NomPrenom, B.NAS --Replace(N.SocialNumber, ' ', '') As NAS
        INTO
            #TB_Beneficiary_06_22
        FROM 
            CTE_Beneficiary B
            --LEFT JOIN dbo.fntCONV_ObtenirNasParHumainEnDate(@dtFinCotisation) N ON N.HumanID = H.HumanID
        SET @ElapseTime = @QueryTimer - @QueryTimer

        SELECT @iCount = Count(distinct BeneficiaryID) FROM #TB_Beneficiary_06_22
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' bénéficiaires correspondant (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            select * from #TB_Beneficiary_06_22 ORDER BY BeneficiaryID

        IF OBJECT_ID('tempdb..#TB_Subvention_06_22') IS NOT NULL
            DROP TABLE #TB_Subvention_06_22

        SET @QueryTimer = GetDate()
        ; WITH CTE_Convention as (
          SELECT DISTINCT
             C.ConventionID, 
             Cotisations_Retirees = -C.mTotal_Retrait,
             Cotisations_Donne_Droit_IQEE = IsNull(A.Solde_Ayant_Droit_IQEE, 0),
             Credit_Base = S.mCreditBase, 
             Majoration = S.mMajoration, 
             Interet = S.mInteret, 
             Total_IQEE = S.mCreditBase + S.mMajoration
          FROM
            #TB_Convention_06_22 C
            JOIN dbo.fntIQEE_CalculerSoldeIQEE_PourRQ(NULL, @siAnnee_Fiscale, NULL) S ON S.iID_Convention = C.ConventionID
            LEFT JOIN dbo.fntIQEE_CotisationsEtAyantEuDroit_ParConvention(NULL, @siAnnee_Fiscale, NULL) A ON A.iID_Convention = C.ConventionID
        )
        SELECT DISTINCT
            C.ConventionID, C.Credit_Base, C.Majoration, C.Interet, 
            Cotisations_Retirees = C.Cotisations_Retirees,
            Solde_IQEE = CASE WHEN C.Total_IQEE < 0 THEN cast(0.0 as money) ELSE C.Total_IQEE END,
            Cotisations_Donne_Droit_IQEE,
            ImpotSpecial = CAST(CASE Cotisations_Donne_Droit_IQEE WHEN 0 THEN 0 
                                     ELSE Round((C.Total_IQEE * Abs(C.Cotisations_Retirees)) / C.Cotisations_Donne_Droit_IQEE, 2)
                                END as money),
            Solde_IQEE_Base = Cast(0 as money),
            Solde_IQEE_Majore = Cast(0 as money)
        INTO
            #TB_Subvention_06_22
        FROM 
            CTE_Convention C

        -- Calcul de l'impôt spécial
        -- Égal au mimimum entre
        --        1- Solde du compte de l'IQÉÉ immédiatement avant la fin de l'année
        --          2- Montant de la formule (A x C) / B
        -- Formule de Revenu Québec (A x C) / B
        -- A: Solde du compte de l'IQEE immédiatement avant la fin de l'année(@mIQEE_Majoration + @mIQEE_Crédit_de_base).
        -- B: Total des cotisations versées au régime immédiatement avant la fin de l'année ayant donné droit à l'IQEE.
        -- C: Montant de la cotisation  retirée du régime à l'égard de laquelle un IQÉÉ a été reçu immédiatement avant la fin de l'année.

        UPDATE #TB_Subvention_06_22 SET
            ImpotSpecial = CAST(Round((Solde_IQEE * Abs(Cotisations_Retirees)) / Cotisations_Donne_Droit_IQEE, 2) as money)
        WHERE
            Cotisations_Donne_Droit_IQEE <> 0

        UPDATE #TB_Subvention_06_22 SET
            ImpotSpecial = Solde_IQEE
        WHERE
            ImpotSpecial > Solde_IQEE

        UPDATE #TB_Subvention_06_22 SET
            Solde_IQEE_Base = round(Credit_Base * ImpotSpecial / (Credit_Base + Majoration),2) 
        WHERE
            Credit_Base + Majoration > 0

        UPDATE #TB_Subvention_06_22 SET
            Solde_IQEE_Majore = ImpotSpecial - Solde_IQEE_Base

        SET @ElapseTime = @QueryTimer - @QueryTimer

        SELECT @iCount = Count(distinct ConventionID) FROM #TB_Subvention_06_22
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' solde de l''IQÉÉ correspondant (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @iCount = 0
            RETURN

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            select * from #TB_Subvention_06_22 ORDER BY ConventionID
    END

    ---------------------------------------------------------------------------------------------
    -- Valider les retraits prématurés et conserver les raisons de rejet en vertu des validations
    ---------------------------------------------------------------------------------------------
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Validation des conventions selon les critères RQ'
    BEGIN
        DECLARE 
            @iID_Validation INT,
            @iCode_Validation INT,
            @vcDescription VARCHAR(300),
            @cType CHAR(1),
            @iCountRejets INT

        -- Sélectionner les validations à faire pour le sous type de transaction
        IF OBJECT_ID('tempdb..#TB_Rejet_06_22') IS NULL
            CREATE TABLE #TB_Rejets_06_22 (
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
            TRUNCATE TABLE #TB_Rejet_06_22

        -- Sélectionner les validations à faire pour le sous type de transaction
        IF OBJECT_ID('tempdb..#TB_Validation_06_22') IS NOT NULL
            DROP TABLE #TB_Validation_06_22

        SELECT 
            V.iID_Validation, V.iCode_Validation, V.cType, V.vcDescription_Parametrable as vcDescription
        INTO
            #TB_Validation_06_22
        FROM
            tblIQEE_Validations V
        WHERE 
            V.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
            AND IsNull(V.iID_Sous_Type, 0) = IsNull(@iID_SousTypeEnregistrement, 0)
            AND V.bValidation_Speciale = 0
            AND V.bActif = 1
            AND ( @cCode_Portee = 'T'
                  OR (@cCode_Portee = 'A' AND V.cType = 'E')
                  OR (@cCode_Portee = 'I' AND V.bCorrection_Possible = 1)
                  OR (ISNULL(@cCode_Portee, '') = '' AND V.cType = 'E' AND V.bCorrection_Possible = 0)
                )
        SET @iCount = @@ROWCOUNT
        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '    » ' + LTrim(Str(@iCount)) + ' validations à appliquer'

        -- Boucler à travers les validations du sous type de transaction
        SET @iID_Validation = 0               
        WHILE Exists(SELECT TOP 1 * FROM #TB_Validation_06_22 WHERE iID_Validation > @iID_Validation) 
        BEGIN
            SET @iCountRejets = 0

            SELECT  @iID_Validation = Min(iID_Validation) 
            FROM    #TB_Validation_06_22
            WHERE   iID_Validation > @iID_Validation

            SELECT  @iCode_Validation = iCode_Validation,
                    @vcDescription = vcDescription,
                    @cType = cType
            FROM    #TB_Validation_06_22 
            WHERE   iID_Validation = @iID_Validation

            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - Validation #' + LTrim(Str(@iCode_Validation)) + ': ' + @vcDescription

            BEGIN TRY
                -- Validation #1101
                IF @iCode_Validation = 1101 
                BEGIN
                    INSERT INTO #TB_Rejets_06_22 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT
                        C.ConventionID, @iID_Validation, @vcDescription, NULL, NULL, C.ConventionID, NULL, NULL
                    FROM 
                        #TB_Convention_06_22 C
                        JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Convention = C.ConventionID
                        JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
                    WHERE 
                        I.siAnnee_Fiscale = @siAnnee_Fiscale
                        AND I.iID_Sous_Type = @iID_SousTypeEnregistrement
                        AND I.cStatut_Reponse = 'R'

                    SET @iCountRejets = @@ROWCOUNT
                END
                ;
                -- Validation #1102
                IF @iCode_Validation = 1102 
                BEGIN
                    INSERT INTO #TB_Rejets_06_22 (
                        iID_Convention, iID_Validation, vcDescription, vcValeur_Reference, vcValeur_Erreur, 
                        iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT 
                        C.ConventionID, @iID_Validation, @vcDescription, NULL, NULL, C.ConventionID, NULL, NULL
                    FROM 
                        #TB_Convention_06_22 C
                        JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Convention = C.ConventionID
                        JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
                    WHERE 
                        I.iID_Sous_Type = @iID_SousTypeEnregistrement
                        AND I.cStatut_Reponse = 'A'
                        AND I.tiCode_Version <> 1

                    SET @iCountRejets = @@ROWCOUNT
                END
                ;
                ---- Validation #1103
                IF @iCode_Validation = 1103
                BEGIN
                    INSERT INTO #TB_Rejets_06_22 (
                        iID_Convention, iID_Validation, vcDescription, vcValeur_Reference, vcValeur_Erreur, 
                        iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT 
                        C.ConventionID, @iID_Validation, @vcDescription, NULL, NULL, C.ConventionID, NULL, NULL
                    FROM 
                        #TB_Convention_06_22 C
                        JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Convention = C.ConventionID
                        JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
                        JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = I.iID_Impot_Special
                        JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                        JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                    WHERE 0 = 0
                        --AND I.iID_Cotisation = @iID_Cotisation
                        AND I.iID_Sous_Type = @iID_SousTypeEnregistrement
                        AND I.cStatut_Reponse = 'E'
                        AND I.dtDate_Evenement = @dtFinCotisation
                        AND TE.cCode_Type_Enregistrement = '06'
                        AND SE.vcCode_Statut = 'ATR'

                    SET @iCountRejets = @@ROWCOUNT
                END
                ;
                -- Validation #1104
                IF @iCode_Validation = 1104 
                    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '       » Skipped'
                --BEGIN
                --    INSERT INTO #TB_Rejets_06_22 (
                --        iID_Convention, iID_Validation, vcDescription, vcValeur_Reference, vcValeur_Erreur, 
                --        iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                --    )
                --    SELECT DISTINCT 
                --        C.ConventionID, @iID_Validation, @vcDescription, NULL, NULL, C.ConventionID, NULL, NULL
                --    FROM 
                --        #TB_Convention_06_22 C
                --        JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Convention = C.ConventionID
                --        JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
                --        JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = I.iID_Impot_Special
                --        JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                --        JOIN tblIQEE_Erreurs E ON E.iID_Erreur = EE.iID_Erreur
                --        JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                --    WHERE 0 = 0
                --        --AND I.iID_Cotisation = @iID_Cotisation
                --        AND I.iID_Sous_Type = @iID_SousTypeEnregistrement
                --        AND I.cStatut_Reponse IN ('A','R')
                --        AND I.dtDate_Evenement < @dtDate_Evenement
                --        AND TE.cCode_Type_Enregistrement = '06' AND TE.cCode_Sous_Type IN ('91','51')

                --    SET @iCountRejets = @@ROWCOUNT
                --END
                ;
                -- Validation #1105
                IF @iCode_Validation = 1105
                BEGIN
                    INSERT INTO #TB_Rejets_06_22 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT 
                        C.ConventionID, @iID_Validation, REPLACE(@vcDescription,'%vcBeneficiaire%', B.NomPrenom), 
                        NULL, B.NAS, C.ConventionID, C.BeneficiaryID, NULL
                    FROM 
                        #TB_Convention_06_22 C
                        JOIN #TB_Beneficiary_06_22 B ON B.BeneficiaryID = C.BeneficiaryID --And B.dtTraitement = C.dtTraitement
                    WHERE
                        dbo.FN_CRI_CheckSin(B.NAS, 0) = 0

                    SET @iCountRejets = @@ROWCOUNT
                END
                ;
                -- Validation #1106
                IF @iCode_Validation = 1106
                BEGIN
                    INSERT INTO #TB_Rejets_06_22 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT
                        C.ConventionID, @iID_Validation, @vcDescription, 
                        NULL, NULL, C.ConventionID, C.BeneficiaryID, NULL
                    FROM 
                        #TB_Convention_06_22 C
                        JOIN #TB_Beneficiary_06_22 B ON B.BeneficiaryID = C.BeneficiaryID --And B.dtTraitement = C.dtTraitement
                    WHERE
                        IsNull(B.Nom, '') = ''

                    SET @iCountRejets = @@ROWCOUNT
                END
                ;
                -- Validation #1107
                IF @iCode_Validation = 1107
                BEGIN
                    INSERT INTO #TB_Rejets_06_22 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT 
                        C.ConventionID, @iID_Validation, @vcDescription, 
                        NULL, NULL, C.ConventionID, C.BeneficiaryID, NULL
                    FROM 
                        #TB_Convention_06_22 C
                        JOIN #TB_Beneficiary_06_22 B ON B.BeneficiaryID = C.BeneficiaryID --And B.dtTraitement = C.dtTraitement
                    WHERE 
                        IsNull(B.Prenom, '') = ''

                    SET @iCountRejets = @@ROWCOUNT
                END
                ;
                -- Validation #1108
                IF @iCode_Validation = 1108
                BEGIN
                    INSERT INTO #TB_Rejets_06_22 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT 
                        C.ConventionID, @iID_Validation, B.NomPrenom, 
                        NULL, NULL, C.ConventionID, C.BeneficiaryID, NULL
                    FROM 
                        #TB_Convention_06_22 C
                        JOIN #TB_Beneficiary_06_22 B ON B.BeneficiaryID = C.BeneficiaryID --And B.dtTraitement = C.dtTraitement
                    WHERE 
                        B.DateNaissance IS NULL

                    SET @iCountRejets = @@ROWCOUNT
                END
                ;
                -- Validation #1109
                IF @iCode_Validation = 1109
                BEGIN
                    ;WITH CTE_Convention as (
                        SELECT DISTINCT
                            C.ConventionID, B.BeneficiaryID, B.NomPrenom, 
                            CONVERT(VARCHAR(10), B.DateNaissance, 120) as dtNaissance, 
                            CONVERT(VARCHAR(10), @dtFinCotisation, 120) as dtEvenement
                        FROM
                            #TB_Convention_06_22 C
                            JOIN #TB_Beneficiary_06_22 B ON B.BeneficiaryID = C.BeneficiaryID --And B.dtTraitement = C.dtTraitement
                        WHERE
                            IsNull(B.DateNaissance, '1900-01-01') > @dtFinCotisation --C.dtTraitement
                    )
                    INSERT INTO #TB_Rejets_06_22 (
                        iID_Convention, iID_Validation, 
                        vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, 
                        iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT
                        C.ConventionID, @iID_Validation, 
                        REPLACE(REPLACE(@vcDescription, '%vcBeneficiaire%', C.NomPrenom), '%dtDate_Evenement%', Convert(varchar(10), dtTransfert, 120)),
                        Convert(varchar(10), dtTransfert, 120), Convert(varchar(10), C.dtNaissance, 120), 
                        C.ConventionID, C.BeneficiaryID, NULL
                    FROM 
                        CTE_Convention C
                        LEFT JOIN (
                            SELECT 
                                T.iID_Convention, IsNull(T.dtDate_Transfert, @dtFinCotisation) as dtTransfert,
                                Row_Num = Row_Number() OVER(PARTITION BY T.iID_Convention ORDER BY T.dtDate_Transfert DESC)
                            FROM 
                                tblIQEE_Transferts T
                                JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE
                                JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TE ON TE.iID_Sous_Type = T.iID_Sous_Type
                                JOIN dbo.tblIQEE_ImpotsSpeciaux I ON I.iID_Convention = T.iID_Convention
                                JOIN @TB_FichierIQEE F2 ON F2.iID_Fichier_IQEE = I.iID_Fichier_IQEE
                                JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType TE2 ON TE2.iID_Sous_Type = T.iID_Sous_Type
                            WHERE  0 = 0
                                AND T.cStatut_Reponse IN ('A','R')
                                AND TE.cCode_Sous_Type = '01'
                                AND TE2.cCode_Sous_Type IN ('51', '91')
                        ) T ON T.iID_Convention = C.ConventionID AND T.Row_Num = 1
                    WHERE 
                        C.dtNaissance > dtTransfert

                    SET @iCountRejets = @@ROWCOUNT
                END
                ;
                -- Validation #1110 -- DP 2008-08-17: Désactiver, car les valeurs du sexe sont hardcodés en BD
                IF @iCode_Validation = 1110 
                    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '       » Skipped'
                --BEGIN
                --    INSERT INTO #TB_Rejets_06_22 (
                --        iID_Convention, iID_Validation, vcDescription, 
                --        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                --    )
                --    SELECT DISTINCT
                --        C.ConventionID, @iID_Validation, REPLACE(@vcDescription,'%vcBeneficiaire%', B.NomPrenom),
                --        NULL, NULL, C.ConventionID, C.BeneficiaryID, NULL
                --    FROM
                --        #TB_Convention_06_22 C
                --        JOIN #TB_Beneficiary_06_22 B ON B.BeneficiaryID = C.BeneficiaryID --And B.dtTraitement = C.dtTraitement
                --    WHERE
                --        IsNull(B.Sexe, '') NOT IN ('F','M')

                --    SET @iCountRejets = @@ROWCOUNT
                --END
                ;
                -- Validation #1111
                IF @iCode_Validation = 1111
                BEGIN
                    ;WITH CTE_Convention as (
                        SELECT DISTINCT
                            C.ConventionID, C.BeneficiaryID, B.Nom, B.NomPrenom,
                            dbo.fnIQEE_ValiderNom(B.Nom) as vcCaractereInvalide
                        FROM
                            #TB_Convention_06_22 C
                            JOIN #TB_Beneficiary_06_22 B ON B.BeneficiaryID = C.BeneficiaryID --And B.dtTraitement = C.dtTraitement
                    )
                    INSERT INTO #TB_Rejets_06_22 (
                        iID_Convention, iID_Validation, vcDescription, vcValeur_Reference, vcValeur_Erreur, 
                        iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT 
                        C.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%vcBeneficiaire%', C.NomPrenom),'%vcCaractereNonConforme%', C.vcCaractereInvalide),
                        NULL, C.Nom, C.ConventionID, C.BeneficiaryID, NULL
                    FROM
                        CTE_Convention C
                    WHERE
                        C.vcCaractereInvalide IS NOT NULL

                    SET @iCountRejets = @@ROWCOUNT
                END                    
                ;
                -- Validation #1112
                IF @iCode_Validation = 1112
                BEGIN
                    ;WITH CTE_Convention as (
                        SELECT DISTINCT
                            C.ConventionID, C.BeneficiaryID, B.Nom, B.NomPrenom,
                            dbo.fnIQEE_ValiderNom(B.Nom) as vcCaractereInvalide
                        FROM
                            #TB_Convention_06_22 C
                            JOIN #TB_Beneficiary_06_22 B ON B.BeneficiaryID = C.BeneficiaryID --And B.dtTraitement = C.dtTraitement
                    )
                    INSERT INTO #TB_Rejets_06_22 (
                        iID_Convention, iID_Validation, vcDescription, 
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT 
                        C.ConventionID, @iID_Validation, 
                            REPLACE(REPLACE(@vcDescription,'%vcBeneficiaire%', C.Nom), '%vcCaractereNonConforme%', C.vcCaractereInvalide), 
                        NULL, C.Nom, C.ConventionID, C.BeneficiaryID, NULL
                    FROM
                        CTE_Convention C
                    WHERE
                        C.vcCaractereInvalide IS NOT NULL

                    SET @iCountRejets = @@ROWCOUNT
                END                    
                ;
                -- Validation #1113
                IF @iCode_Validation = 1113
                    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '       » Skipped'
                --BEGIN
                --    INSERT INTO #TB_Rejets_06_22 (
                --        iID_Convention, iID_Validation, vcDescription, 
                --        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                --    )
                --    SELECT DISTINCT 
                --        C.ConventionID, @iID_Validation, @vcDescription, 
                --        NULL, NULL, C.ConventionID, NULL, NULL
                --    FROM 
                --        #TB_Convention_06_22 C
                --    WHERE 
                --        C.ConventionNo IN (
                --            'C-20001005008','C-20001031021','R-20060717009','R-20060717011','R-20060717008',
                --            'U-20051201028','R-20070627056','R-20070627058','F-20011119002','I-20050506001',
                --            'I-20070925002','I-20070705002','I-20031223005','D-20010730001','T-20081101023',
                --            'I-20071107001','C-19991018042','I-20050923003','I-20050923002','T-20081101028',
                --            'U-20080902012','U-20080902012','U-20081028013','U-20080923016','R-20080923006',
                --            'R-20080915007','R-20081105003','U-20071213003','U-20080403001','R-20080317046',
                --            'R-20080317047','U-20071114068','U-20080411009','R-20080411001','U-20081009005',
                --            'R-20080916001','U-20080827021','U-20081105042','R-20071120004','R-20071217029',
                --            'U-20071217012','U-20080204002','U-20080930010','T-20081101006','T-20081101017',
                --            'T-20081101067','1449340',      '2083034',      '2039499')

                --    SET @iCountRejets = @@ROWCOUNT
                --END                    
                ;
                -- Validation #1114
                IF @iCode_Validation = 1114
                    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '       » Skipped'
                --BEGIN
                --    INSERT INTO #TB_Rejets_06_22 (
                --         iID_Convention, iID_Validation, vcDescription, vcValeur_Reference, vcValeur_Erreur, 
                --         iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                --    )
                --    SELECT DISTINCT 
                --        C.ConventionID, @iID_Validation, REPLACE(@vcDescription,'%iID_Convention%', C.ConventionNo),
                --        NULL, B.Nom, C.ConventionID, @mSolde_Fixe, @mCotisations_Donne_Droit_IQEE
                --    FROM 
                --        #TB_Convention_06_22 C
                --        JOIN #TB_Beneficiary_06_22 B ON B.BeneficiaryID = C.BeneficiaryID --And B.dtTraitement = C.dtTraitement
                --    WHERE
                --        C.Cotisations_Donne_Droit_IQEE = 0

                --    SET @iCountRejets = @@ROWCOUNT
                --END                    
                ;
                -- Validation #1115    
                IF @iCode_Validation = 1115
                BEGIN
                    INSERT INTO #TB_Rejets_06_22 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT 
                        C.ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcNo_Convention%', C.ConventionNo),
                        NULL, NULL, C.ConventionID, NULL, NULL
                    FROM 
                        #TB_Convention_06_22 C
                        JOIN dbo.tblIQEE_CasSpeciaux CS ON CS.iID_Convention = C.ConventionID
                    WHERE 0 = 0
                        AND CS.bCasRegle = 0
                        AND ISNULL(CS.tiID_TypeEnregistrement, @tiID_TypeEnregistrement) = @tiID_TypeEnregistrement
                        AND ISNULL(CS.iID_SousType, @iID_SousTypeEnregistrement) = @iID_SousTypeEnregistrement

                    SET @iCountRejets = @@ROWCOUNT
                END
                ;
                -- Validation 1116
                IF @iCode_Validation = 1116 
                BEGIN
                    INSERT INTO #TB_Rejets_06_22 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT
                        TB.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%dtTransfert%', CONVERT(VARCHAR(10), T.OperDate, 120)), '%OperTypeID%', T.OperTypeID), 
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        dbo.fntIQEE_Transfert_NonDeclare(DEFAULT, @dtFinCotisation) T
                        JOIN #TB_Convention_06_22 TB ON TB.ConventionID = T.ConventionID
                    WHERE
                        T.OperDate < @dtFinCotisation

                    SET @iCountRejets = @@ROWCOUNT
                END
                ;
                -- Validation 1117
                IF @iCode_Validation = 1117 
                BEGIN
                    INSERT INTO #TB_Rejets_06_22 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        TB.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%dtPaiement%', CONVERT(VARCHAR(10), PB.OperDate, 120)), '%ScholarshipNo%', TB.ConventionNo),
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        dbo.fntIQEE_PaiementBeneficiaire_NonDeclare(DEFAULT, @dtFinCotisation) PB
                        JOIN #TB_Convention_06_22 TB ON TB.ConventionID = PB.ConventionID
                    WHERE
                        PB.OperDate < @dtFinCotisation

                    SET @iCountRejets = @@ROWCOUNT
                END
            END TRY
            BEGIN CATCH
                PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '       » *** ERREUR_VALIDATION ***'

                INSERT INTO ##tblIQEE_RapportCreation 
                    (cSection, iSequence, vcMessage)
                SELECT
                    '3', 10, '       '+CONVERT(VARCHAR(25),GETDATE(),121)+'     '+vcDescription_Parametrable + ' ' + LTrim(Str(@iCode_Validation))
                FROM
                    dbo.tblIQEE_Validations
                WHERE 
                    iCode_Validation = 1100

                RETURN -1
            END CATCH

            -- S'il y a eu des rejets de validation
            IF @iCountRejets > 0
            BEGIN
                PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '       » ' + LTrim(Str(@iCountRejets)) + ' rejets'

                -- Et si on traite seulement les 1ères erreurs de chaque convention
                IF @bArretPremiereErreur = 1 AND @cType = 'E'
                BEGIN
                    -- Efface que les conventions ayant un rejet sur la validation courante
                    DELETE FROM #TB_Convention_06_22
                    WHERE EXISTS (SELECT * FROM #TB_Rejets_06_22 WHERE iID_Convention = ConventionID AND iID_Validation = @iID_Validation)
                END
            END

        END -- IF @iCode_Validation 

        -- Efface tous les conventions ayant eu au moins un rejet de validation
        DELETE FROM #TB_Convention_06_22
        WHERE EXISTS (SELECT * FROM #TB_Rejets_06_22 WHERE iID_Convention = ConventionID)

        INSERT INTO dbo.tblIQEE_Rejets (
            iID_Fichier_IQEE, siAnnee_Fiscale, iID_Convention, iID_Validation, vcDescription,
            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
            --,tCommentaires, iID_Utilisateur_Modification, dtDate_Modification
        )
        SELECT 
            @iID_Fichier_IQEE, @siAnnee_Fiscale, R.iID_Convention, R.iID_Validation, R.vcDescription,
            R.vcValeur_Reference, vcValeur_Erreur, R.iID_Lien_Vers_Erreur_1, R.iID_Lien_Vers_Erreur_2, R.iID_Lien_Vers_Erreur_3
        FROM 
            #TB_Rejets_06_22 R
    END

    --------------------------------------
    -- Traite les retraits des cotisations
    --------------------------------------
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Déclaration des retraits de cotisations'
    BEGIN
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   Créer les enregistrements d''impôt spéciaux.'
        SET @QueryTimer = GetDate()
        ; WITH CTE_Sexe as (
            SELECT X.rowID as ID, X.strField as Code
            FROM ProAcces.fn_SplitIntoTable('F,M', ',') X
        )
        INSERT INTO dbo.tblIQEE_ImpotsSpeciaux (
            iID_Fichier_IQEE, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse, iID_Convention, vcNo_Convention,
            iID_Sous_Type, --iID_Remplacement_Beneficiaire, iID_Transfert, iID_Operation, iID_Cotisation,
            --iID_RI, iID_Cheque, iID_Statut_Convention, 
                dtDate_Evenement, mCotisations_Retirees,
            mSolde_IQEE_Base, mSolde_IQEE_Majore, mIQEE_ImpotSpecial, mRadiation, mCotisations_Donne_Droit_IQEE,
            --mJuste_Valeur_Marchande, mBEC, mSubvention_Canadienne, mSolde_IQEE, 
                iID_Beneficiaire,
            vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire,
            --vcCode_Postal_Etablissement, vcNom_Etablissement, iID_Ligne_Fichier, iID_Paiement_Impot_CBQ, iID_Paiement_Impot_MMQ,
            mMontant_A, mMontant_B, mMontant_C --, mMontant_AFixe, mEcart_ReelvsFixe,
            --iID_Transaction_Convention_CBQ_Renversee, iID_Transaction_Convention_MMQ_Renversee
        )
        SELECT
            @iID_Fichier_IQEE, @siAnnee_Fiscale, @tiCode_Version, 'A', C.ConventionID, C.ConventionNo,
            @iID_SousTypeEnregistrement, --iID_Remplacement_Beneficiaire, iID_Transfert, iID_Operation, iID_Cotisation,
            --TB.CollegeID, iID_Cheque, iID_Statut_Convention, 
                @dtFinCotisation, Round(S.Cotisations_Retirees, 2),
            S.Solde_IQEE_Base, S.Solde_IQEE_Majore, S.ImpotSpecial, 0, S.Cotisations_Donne_Droit_IQEE,
            --mJuste_Valeur_Marchande, mBEC, mSubvention_Canadienne, mSolde_IQEE, 
                C.BeneficiaryID,
            B.NAS, Left(B.Nom, 20), Left(B.Prenom, 20), B.DateNaissance, (SELECT ID FROM CTE_Sexe WHERE Code = B.Sexe),
            --C.CollegeCode, vcNom_Etablissement, iID_Ligne_Fichier, iID_Paiement_Impot_CBQ, iID_Paiement_Impot_MMQ,
            S.Solde_IQEE, S.Cotisations_Donne_Droit_IQEE, S.Cotisations_Retirees --, ROUND(S.Solde_Fixe,2), ROUND(@mMontantImpotSpecial_Ecart_Fixe_VS_Reel,2),
            --iID_Transaction_Convention_CBQ_Renversee, iID_Transaction_Convention_MMQ_Renversee
        FROM
            #TB_Convention_06_22 C
            JOIN #TB_Beneficiary_06_22 B ON B.BeneficiaryID = C.BeneficiaryID
            LEFT JOIN #TB_Subvention_06_22 S ON S.ConventionID = C.ConventionID

        SET @iCount = @@RowCount
        SET @ElapseTime = @QueryTimer - GetDate()
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' enregistrements ajoutés (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @iCount > 0
            IF EXISTS(SELECT * FROM dbo.tblIQEE_Fichiers WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE AND bInd_Simulation = 0)
                EXEC dbo.psIQEE_CreerOperationFinanciere_ImpotsSpeciaux @iID_Utilisateur_Creation, @iID_Fichier_IQEE, @iID_SousTypeEnregistrement
    END

    SET @ElapseTime = GetDate() - @StartTimer
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions06_22 completed' 
                + ' (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

    IF OBJECT_ID('tempdb..#TB_Validation_06_22') IS NOT NULL
        DROP TABLE #TB_Validation_06_22
    IF OBJECT_ID('tempdb..#TB_Rejets_06_22') IS NOT NULL
        DROP TABLE #TB_Rejets_06_22
    IF OBJECT_ID('tempdb..#TB_Subvention_06_22') IS NOT NULL
        DROP TABLE #TB_Subvention_06_22
    IF OBJECT_ID('tempdb..#TB_Beneficiary_06_22') IS NOT NULL
        DROP TABLE #TB_Beneficiary_06_22
    IF OBJECT_ID('tempdb..#TB_Convention_06_22') IS NOT NULL
        DROP TABLE #TB_Convention_06_22

    -- Retourner 0 si le traitement est réussi
    RETURN 0
END
