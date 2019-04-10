/********************************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service : psIQEE_CreerTransactions_04_01
Nom du service  : Créer les transactions de type 04-01 - transfert vers promoteur externe
But             : Sélectionner, valider et créer les transactions de type 04 – 01, concernant les transferts vers l'externes
                  dans un nouveau fichier de transactions de l’IQÉÉ.
Facette         : IQÉÉ

Paramètres d’entrée :
        Paramètre               Description
        --------------------    -----------------------------------------------------------------
        iID_Fichier_IQEE        Identifiant du nouveau fichier de transactions dans lequel les transactions 04-01 doivent être créées.
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

Exemple d’appel : exec dbo.psIQEE_CreerTransactions04_01 10, 0, NULL, 0, 'T'

Paramètres de sortie:
        Champ               Description
        ------------        ------------------------------------------
        iCode_Retour        = 0 : Exécution terminée normalement
                            < 0 : Erreur de traitement

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    --------------------------------------------------------------------------
    2018-02-16  Steeve Picard           Création du service
    2018-03-28  Steeve Picard           Ajustement du total de cotisation avant l'avênement de l'IQÉÉ
    2018-04-09  Steeve Picard           Filtrer l'historique des chèques pour éviter les doublons
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
    2018-08-22  Steeve Picard           Exclure le montant de cotisation de l'année courante du Non Ayant Droit à l'IQÉÉ
    2018-09-19  Steeve Picard           Ajout du champ «iID_SousType» à la table «tblIQEE_CasSpeciaux» pour pouvoir filtrer
    2018-09-20  Steeve Picard           Ajout de la vérification que l'opération «AVC» ait été déclarée préalablement au même titre que les «PAE»
    2018-11-07  Steeve Picard           Filtre seuelement les transferts autorisés pour le moment
    2018-11-15  Steeve Picard           Exclure jusqu'à nouvel ordre, les cas des résiduels ou de révaluation de la majoré
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_CreerTransactions04_01]
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
    PRINT 'Déclaration des transferts cédant vers l''externe (T04-01) pour ' + STR(@siAnnee_Fiscale, 4)
    PRINT '--------------------------------------------------------------------'
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions_04_01 started'

    -- Empêcher ces déclarations en PROD
    IF (@siAnnee_Fiscale < 2017 AND @bit_CasSpecial = 0)
       OR (@siAnnee_Fiscale = 2017 AND @@SERVERNAME IN ('SRVSQL12', 'SRVSQL25'))
    BEGIN
        PRINT '   *** Déclaration non-implanté en PROD ou avant 2018'
        RETURN
    END 

    IF Object_ID('tempDB..#TB_ListeConvention') IS NULL
        RAISERROR ('La table « #TB_ListeConvention (RowNo INT Identity(1,1), ConventionID int, ConventionNo varchar(20) » est abesente ', 16, 1)

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Identifie le(s) convention(s)'
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
            @dtDebutCotisation DATETIME,            @dtFinCotisation DATETIME,
            @bTransfert_Autorise BIT = 1,           @dtMaxCotisation DATETIME = DATEADD(DAY, -DAY(GETDATE()), GETDATE()),
            @TB_Adresse UDT_tblAdresse,             @vcCaracteresAccents varchar(100) = '%[Å,À,Á,Â,Ã,Ä,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ñ,Ò,Ó,Ô,Õ,Ö,Ù,Ú,Û,Ü,Ý]%'
                
        DECLARE @TB_FichierIQEE TABLE (
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

        IF @dtFinCotisation > @dtMaxCotisation
            SET @dtFinCotisation = @dtMaxCotisation

        -- Récupère les IDs du type & sous-type pour ce type d'enregistrement
        SELECT 
            @tiID_TypeEnregistrement = tiID_Type_Enregistrement,
            @iID_SousTypeEnregistrement = iID_Sous_Type
        FROM
            dbo.vwIQEE_Enregistrement_TypeEtSousType 
        WHERE
            cCode_Type_Enregistrement = '04'
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

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupère les conventions ayant eu un transfert'
    BEGIN

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupère les opérations de transfert'
        BEGIN 
            SET @QueryTimer = GETDATE()

            IF OBJECT_ID('tempDB..##TB_Transfert_04_01') IS NOT NULL
                DROP TABLE #TB_Transfert_04_01;
           
            WITH CTE_OUT AS (
                SELECT DISTINCT
                    T.ConventionID, -- = COALESCE(CE.ConventionID, CO.ConventionID, Ct.ConventionID, 0), 
                    dtTransfert = CAST(O.OperDate AS DATE), 
                    T.ExternalPlanID, 
                    tiRegimeType_ExtPromo = T.tiREEEType, 
                    vcContratNo_ExtPromo = T.vcOtherConventionNo,
                    EstComplet = CASE T.bTransfertPartiel WHEN 0 THEN 1 ELSE 0 END,
                    EstAutoriser = T.bIQEE_Autoriser,
                    Epargne = ISNULL(T.mEpargne, 0),
                    PCEE = ISNULL(T.fCESG, 0),
                    BEC = ISNULL(T.fCLB, 0),
                    IQEE_Base = ISNULL(T.mIQEE, 0),
                    IQEE_Plus = ISNULL(T.mIQEE_Plus, 0),
                    Interet = ISNULL(T.fAIP, 0),
                    Total = ISNULL(T.fMarketValue, 0),
                    CotTotal = ISNULL(T.fBnfCot,  0),
                    CotAyantDroit =ISNULL(T.mIQEE_CotAyantDroit, 0),
                    CotNonDroit = ISNULL(T.mIQEE_CotNonDroit, 0),
                    CotAvantDebut = ISNULL(T.mIQEE_CotAvantDebut, 0),
                    CotAnneeCourante = ISNULL(T.fYearBnfCot, 0)
                FROM
                    dbo.fntOPER_Active(@dtDebutCotisation, @dtFinCotisation) O
                    JOIN dbo.Un_OUT T ON T.OperID = O.OperID
                WHERE 
                    O.OperTypeID = 'OUT'
                    AND NOT EXISTS (SELECT * FROM dbo.Un_TIO WHERE iOUTOperID = O.OperID) 
            ),
            CTE_Transfert AS (
                SELECT
                    T.*, 
                    vcNoRegime_ExtPromo = R.vcNoRegime,
                    vcNEQ_ExtPromo = ISNULL(R.vcNEQ_Mandataire, R.vcNEQ_Fiduciaire),
                    bEstAutoriser = CASE WHEN ISNULL(R.dtEntreeEnVigueur, GETDATE()) <= T.dtTransfert  THEN R.bOffreIQEE ELSE 0 END
                FROM
                    CTE_OUT T
                    JOIN dbo.Un_ExternalPlan EP ON EP.ExternalPlanID = T.ExternalPlanID
                    LEFT JOIN dbo.vwIQEE_RegimePromoteur R ON R.vcNoRegime = EP.ExternalPlanGovernmentRegNo
            )
            SELECT DISTINCT
                T.ConventionID, X.ConventionNo, T.dtTransfert,
                T.vcNEQ_ExtPromo, T.vcNoRegime_ExtPromo, 
                T.tiRegimeType_ExtPromo, T.vcContratNo_ExtPromo,
                bEstComplet = T.EstComplet, 
                bEstAutoriser = T.EstAutoriser,
                mSoldePCEE = SUM(T.PCEE), 
                mSoldeBEC = SUM(T.BEC), 
                mSoldeEpargne = SUM(T.Epargne), -- T.Total - T.PCEE - T.BEC - ISNULL(T.IQEE_Base, 0) - ISNULL(T.Interet, 0)),
                mSoldeCreditBase = SUM(ISNULL(T.IQEE_Base, 0)),
                mSoldeMajoration = SUM(ISNULL(T.IQEE_Plus, 0)),
                mSoldeInteret = SUM(ISNULL(T.Interet, 0)),
                mMontantTransfert = SUM(T.Total), 
                mAyantDroitIQEE = (T.CotAyantDroit), 
                mNonDroitApresIQEE = (T.CotNonDroit), 
                mNonDroitAvantIQEE = (T.CotAvantDebut),
                mCotAnneeCourante = SUM(T.CotAnneeCourante)
            INTO
                #TB_Transfert_04_01
            FROM
                CTE_Transfert T
                JOIN #TB_ListeConvention X ON X.ConventionID = T.ConventionID
                JOIN dbo.fntIQEE_ConventionConnueRQ_PourTous(NULL, @siAnnee_Fiscale) RQ ON RQ.iID_Convention = X.ConventionID
            GROUP BY
                T.ConventionID, X.ConventionNo, T.dtTransfert, T.vcNEQ_ExtPromo, T.vcNoRegime_ExtPromo, T.tiRegimeType_ExtPromo, T.vcContratNo_ExtPromo,
                T.EstComplet, T.EstAutoriser,T.CotAyantDroit, T.CotAyantDroit, T.CotNonDroit, T.CotAvantDebut
            HAVING
                SUM(ISNULL(T.IQEE_Base, 0)) > 0 
                OR SUM(ISNULL(T.IQEE_Plus, 0)) > 0
                --SUM(T.BEC + T.PCEE) <> SUM(T.Total)

            SET @iCount = @@ROWCOUNT
            SET @ElapseTime = GetDate() - @QueryTimer
            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '       » ' + LTrim(Str(@iCount)) + ' retrouvée(s) (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

            -- Bloque les non autorisés
            DELETE FROM #TB_Transfert_04_01
            OUTPUT 'Non Autoriser' AS Autoriser, Deleted.*
             WHERE bEstAutoriser = 0     

            -- Bloque les résiduels & les révaluations d'IQÉÉ
            DELETE FROM #TB_Transfert_04_01
            OUTPUT 'Oui' AS blocked, Deleted.*
             WHERE mSoldeEpargne <= 0       

            IF @IsDebug <> 0 AND @MaxRow BETWEEN 1 AND 5
                SELECT '#TB_Transfert', * FROM #TB_Transfert_04_01

            SET @QueryTimer = GETDATE()
            DELETE FROM #TB_Transfert_04_01 WHERE mSoldeCreditBase + mSoldeMajoration < 0
            SET @iCount = @@ROWCOUNT
            SET @ElapseTime = GetDate() - @QueryTimer
            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '       » ' + LTrim(Str(@iCount)) + ' retranchée(s) à zéro (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

            SELECT @iCount = COUNT(*) FROM #TB_Transfert_04_01
            IF @iCount = 0 
                RETURN

            IF @iCount < 5
                SET @MaxRow = @iCount

            IF @IsDebug <> 0 AND @MaxRow BETWEEN 1 AND 5
                SELECT '#TB_Transfert_04_01', * FROM #TB_Transfert_04_01
        END
            
        SET ROWCOUNT 0
    END
    
    IF NOT EXISTS(SELECT TOP 1 * FROM #TB_Transfert_04_01)
       RETURN

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération les infos des souscripteurs'
    BEGIN
        IF Object_ID('tempDB..#TB_Subscriber_04_01') IS NOT NULL
            DROP TABLE #TB_Subscriber_04_01

        SET @QueryTimer = GetDate()
        ; WITH CTE_Subscriber as (
            SELECT DISTINCT
                TB.ConventionID, TB.dtTransfert,
                C.SubscriberID,
                vcNom = LTRIM(H.LastName), 
                vcPrenom = LTRIM(H.FirstName), 
                vcCompagnie = LTRIM(H.CompanyName), 
                cType_HumanOrCompany = CASE WHEN H.IsCompany = 0 THEN 'H' ELSE 'C' END,
                H.SocialNumber, RS.tiCode_Equivalence_IQEE,
                vcNEQ = CASE WHEN H.IsCompany <> 0 THEN 
                                  CASE WHEN Len(LTrim(H.StateCompanyNo)) = 0 THEN NULL 
                                       ELSE LTRIM(H.StateCompanyNo) 
                                  END
                             ELSE NULL 
                        END
            FROM 
                #TB_Transfert_04_01 TB
                JOIN dbo.Un_Convention C ON C.ConventionID = TB.ConventionID
                JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
                LEFT JOIN Un_RelationshipType RS ON RS.tiRelationshipTypeID = C.tiRelationshipTypeID
        )
        SELECT
            TB.*, 
            vcNAS = TB.SocialNumber, --CASE cType_HumanOrCompany WHEN 'H' THEN IsNull(N.SocialNumber, TB.SocialNumber) ELSE NULL END, 
            vcNomPrenom = dbo.fn_Mo_FormatHumanName(TB.vcNom, '', TB.vcPrenom, '', '', 0),
            Subscriber_LienID = tiCode_Equivalence_IQEE,
            A.iID_Adresse, 
            vcAdresse_Tmp = LTrim(RTrim(Coalesce(A.vcNom_Rue, A.vcInternationale1, ''))),
            vcNoCivique = A.vcNumero_Civique,
            vcAppartement = A.vcUnite,
            vcNomRue = LTrim(RTrim(IsNull(A.vcNom_Rue, A.vcInternationale1))),
            A.iID_TypeBoite,
            A.vcBoite,
            A.vcVille,
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
        INTO
            #TB_Subscriber_04_01
        FROM 
            CTE_Subscriber TB
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = TB.SubscriberID
            LEFT JOIN dbo.fntCONV_ObtenirNasParHumainEnDate(@dtFinCotisation) N ON N.HumanID = TB.SubscriberID
            LEFT JOIN dbo.fntGENE_ObtenirAdresseEnDate_PourTous(NULL, 1, @dtFinCotisation, 0) A ON A.iID_Source = TB.SubscriberID And A.cType_Source = TB.cType_HumanOrCompany
                                                                                          
        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
        
        IF EXISTS(SELECT TOP 1 * FROM #TB_Subscriber_04_01 WHERE iID_Adresse IS NULL)
        BEGIN
            PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération des adresses inexistantes fiscale des souscripteurs pour cette année fiscale'
            SET @QueryTimer = GetDate()

            UPDATE S SET
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
                #TB_Subscriber_04_01 S 
                JOIN dbo.fntGENE_ObtenirDerniereAdresseConnue(DEFAULT, 1, @dtFinCotisation, 0) A ON A.iID_Source = SubscriberID
            WHERE
                S.iID_Adresse IS NULL 

            UPDATE S SET
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
                #TB_Subscriber_04_01 S 
                JOIN dbo.fntGENE_ObtenirAdressePremiereConnue(DEFAULT, 1, @dtFinCotisation, 0) A ON A.iID_Source = SubscriberID
            WHERE
                S.iID_Adresse IS NULL 

            SET @iCount = @@ROWCOUNT
            SET @ElapseTime = GetDate() - @QueryTimer
            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
        END
        
        DELETE FROM @TB_Adresse

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Corrige le # civique & l''appartement des adresses n''en ayant pas'
        SET @QueryTimer = GetDate()

        INSERT INTO @TB_Adresse (iID_Source, iID_Adresse, vcNoCivique, vcAppartement, vcNomRue, iID_TypeBoite, vcBoite)
        SELECT DISTINCT
            SubscriberID, iID_Adresse, vcNoCivique, vcAppartement, vcNomRue, iID_TypeBoite, vcBoite
        FROM
            #TB_Subscriber_04_01
        WHERE
            iID_Adresse IS NOT NULL
        --  Len(IsNull(vcNomRue, '')) > 0

        UPDATE TB SET
            vcNoCivique = A.NoCivique,
            vcAppartement = A.Appartement,
            vcNomRue = LTrim(IsNull(A.NomRue, '') + 
                           CASE WHEN Len(IsNull(A.Boite, '')) > 0
                                THEN CASE A.ID_TypeBoite WHEN 1 THEN ' CP ' WHEN 2 THEN ' RR ' ELSE ' ' END + A.Boite
                                ELSE '' 
                           END),
            iID_TypeBoite = A.ID_TypeBoite,
            vcBoite = A.Boite
        --OUTPUT inserted.*
        FROM #TB_Subscriber_04_01 TB
             JOIN dbo.fntIQEE_CorrigerAdresseUserTable(@TB_Adresse) A ON A.iID_Source = TB.SubscriberID And A.iID_Adresse = TB.iID_Adresse

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' corrigées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Génère le nom de rue complet'
        SET @QueryTimer = GetDate()

        UPDATE #TB_Subscriber_04_01 SET
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
          FROM #TB_Subscriber_04_01 TB 
               JOIN dbo.Mo_State S ON S.vcNomWeb_FRA = TB.vcProvince OR S.vcNomWeb_ENU = TB.vcProvince
         WHERE TB.cID_Pays = 'CAN'

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            SELECT * from #TB_Subscriber_04_01
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération les infos des bénéficiaires'
    BEGIN
        IF Object_ID('tempDB..#TB_Beneficiary_04_01') IS NOT NULL
            DROP TABLE #TB_Beneficiary_04_01

        SET @QueryTimer = GetDate()
        ;WITH CTE_Beneficiary as (
            SELECT DISTINCT
                TB.ConventionID, TB.dtTransfert,
                BeneficiaryID = CB.iID_Nouveau_Beneficiaire,
                vcNAS =  ISNULL(H.SocialNumber, ''), -- CASE WHEN HSN.HumanID IS NULL THEN '' ELSE ISNULL(H.SocialNumber, '') END,
                vcNom = LTRIM(H.LastName), 
                vcPrenom = LTRIM(H.FirstName), 
                dtNaissance = H.BirthDate, 
                cSexe = H.SexID
            FROM 
                #TB_Transfert_04_01 TB
                JOIN dbo.tblCONV_ChangementsBeneficiaire CB ON CB.iID_Convention = TB.ConventionID AND CB.dtDate_Changement_Beneficiaire <= TB.dtTransfert
                JOIN dbo.Mo_Human H ON H.HumanID = CB.iID_Nouveau_Beneficiaire
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
            A.bResidenceFaitQuebec,
            -- Donnees du principal responsable
            tiType_Responsable = B.tiPCGType, 
            vcNAS_Responsable = CASE WHEN B.tiPCGType = 1 AND LEFT(B.vcPCGSINorEN, 1) <> '0' THEN B.vcPCGSINorEN
                                     ELSE NULL END, 
            vcNEQ_Responsable = CASE WHEN B.tiPCGType = 2 THEN B.ResponsableNEQ ELSE NULL END, 
            vcNom_Responsable = LTrim(RTrim(B.vcPCGLastName)), 
            vcPrenom_Responsable = CASE WHEN B.tiPCGType = 1 AND LEFT(B.vcPCGSINorEN, 1) <> '0' THEN LTrim(RTrim(B.vcPCGFirstName))
                                        ELSE NULL END, 
            vcNomPrenom_Responsable = CASE WHEN B.tiPCGType = 1 AND LEFT(B.vcPCGSINorEN, 1) <> '0' THEN dbo.fn_Mo_FormatHumanName(B.vcPCGLastName, '', B.vcPCGFirstName, '', '', 0)
                                           WHEN B.tiPCGType = 1 THEN NULL
                                           ELSE LTrim(RTrim(B.vcPCGLastName)) END
        INTO
            #TB_Beneficiary_04_01
        FROM 
            CTE_Beneficiary TB
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = TB.BeneficiaryID
            LEFT JOIN dbo.fntGENE_ObtenirAdresseEnDate_PourTous(NULL, 1, @dtFinCotisation, 0) A ON A.iID_Source = B.BeneficiaryID AND A.cType_Source = 'H'
            --LEFT JOIN #TB_Subscriber_04_01 S ON S.SubscriberID = B.ResponsableIDSouscripteur
            
        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
        
        IF EXISTS(SELECT TOP 1 * FROM #TB_Beneficiary_04_01 WHERE iID_Adresse IS NULL)
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
                #TB_Beneficiary_04_01 B 
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
                #TB_Beneficiary_04_01 B 
                LEFT JOIN dbo.fntGENE_ObtenirAdressePremiereConnue(DEFAULT, 1, @dtFinCotisation, 0) A ON A.iID_Source = B.BeneficiaryID
            WHERE
                B.iID_Adresse IS NULL 

            SET @iCount = @@ROWCOUNT
            SET @ElapseTime = GetDate() - @QueryTimer
            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées ultérieurement (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
        END

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Corrige les accents dans le nom & prénom des principaux responsables'
        SET @QueryTimer = GetDate()

        ;WITH CTE_Responsable AS (
            SELECT BeneficiaryID, vcNom_Responsable, vcPrenom_Responsable, vcNomPrenom_Responsable
              FROM #TB_Beneficiary_04_01
             WHERE PatIndex(@vcCaracteresAccents, vcNom_Responsable) <> 0
                OR PatIndex(@vcCaracteresAccents, vcPrenom_Responsable) <> 0 
        )
        UPDATE #TB_Beneficiary_04_01 SET
            vcNom_Responsable = dbo.fn_Mo_FormatStringWithoutAccent(vcNom_Responsable),
            vcPrenom_Responsable = dbo.fn_Mo_FormatStringWithoutAccent(vcPrenom_Responsable),
            vcNomPrenom_Responsable = dbo.fn_Mo_FormatStringWithoutAccent(vcNomPrenom_Responsable)
        WHERE
            EXISTS (SELECT * FROM CTE_Responsable R WHERE R.BeneficiaryID = BeneficiaryID)

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' corrigées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        DELETE FROM @TB_Adresse

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Corrige le # civique & l''appartement des adresses n''en ayant pas'
        SET @QueryTimer = GetDate()

        INSERT INTO @TB_Adresse (iID_Source, iID_Adresse, vcNoCivique, vcAppartement, vcNomRue, iID_TypeBoite, vcBoite)
        SELECT DISTINCT
            BeneficiaryID, iID_Adresse, vcNoCivique, vcAppartement, vcNomRue, iID_TypeBoite, vcBoite 
        FROM
            #TB_Beneficiary_04_01
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
            #TB_Beneficiary_04_01 TB
            JOIN dbo.fntIQEE_CorrigerAdresseUserTable(@TB_Adresse) A ON A.iID_Source = TB.BeneficiaryID And A.iID_Adresse = TB.iID_Adresse

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' corrigées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Génère le nom de rue complet'
        SET @QueryTimer = GetDate()

        UPDATE #TB_Beneficiary_04_01 SET
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
          FROM #TB_Beneficiary_04_01 TB 
               JOIN dbo.Mo_State S ON S.vcNomWeb_FRA = TB.vcProvince OR S.vcNomWeb_ENU = TB.vcProvince
         WHERE TB.cID_Pays = 'CAN'

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            SELECT * from #TB_Beneficiary_04_01
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

        IF OBJECT_ID('tempdb..#TB_Rejet_04_01') IS NULL
            CREATE TABLE #TB_Rejets_04_01 (
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
            TRUNCATE TABLE #TB_Rejet_04_01

        -- Sélectionner les validations à faire pour le sous type de transaction
        IF OBJECT_ID('tempdb..#TB_Validation_04_01') IS NOT NULL
            DROP TABLE #TB_Validation_04_01

        SELECT 
            V.iOrdre_Presentation, V.iID_Validation, V.iCode_Validation, V.cType, V.vcDescription_Parametrable as vcDescription
        INTO
            #TB_Validation_04_01
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
        WHILE Exists(SELECT TOP 1 * FROM #TB_Validation_04_01 WHERE iOrdre_Presentation > @iOrdre_Presentation) 
        BEGIN
            SET @iCountRejets = 0

            SELECT TOP 1
                @iOrdre_Presentation = iOrdre_Presentation,
                @iID_Validation = iID_Validation, 
                @iCode_Validation = iCode_Validation,
                @vcDescription = vcDescription,
                @cType = cType
            FROM
                #TB_Validation_04_01 
            WHERE
                iOrdre_Presentation > @iOrdre_Presentation
            ORDER BY 
                iOrdre_Presentation

            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - Validation #' + LTrim(Str(@iCode_Validation)) + ': ' + @vcDescription

            BEGIN TRY
                -- Validation : Le transfert a déjà été envoyé et une réponse reçue de RQ.
                IF @iCode_Validation = 701 
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert
                        FROM
                            #TB_Transfert_04_01 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_Transferts T
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE 
                                WHERE 
                                    T.iID_Convention = C.ConventionID
                                    AND T.iID_Sous_Type = @iID_SousTypeEnregistrement
                                    AND T.dtDate_Transfert = C.dtTransfert
                                    AND T.cStatut_Reponse = 'R'
                            )
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : L'impôt spécial de remplacement de bénéficiaire non reconnu est en cours de traitement par RQ et est en attente d’une réponse de RQ
                IF @iCode_Validation = 702
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert
                        FROM
                            #TB_Transfert_04_01 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_Transferts T
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE 
                                WHERE 
                                    T.iID_Convention = C.ConventionID
                                    AND T.iID_Sous_Type = @iID_SousTypeEnregistrement
                                    AND T.dtDate_Transfert = C.dtTransfert
                                    AND T.cStatut_Reponse = 'A'
                                    AND T.tiCode_Version <> 1
                            )
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Une erreur soulevée par Revenu Québec est en cours de traitement pour le transfert
                IF @iCode_Validation = 703
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert
                        FROM
                            #TB_Transfert_04_01 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_Transferts T
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE 
                                              JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = T.iID_Transfert
                                              JOIN dbo.tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                                                                               AND SE.vcCode_Statut = 'ATR'
                                WHERE 
                                    T.iID_Convention = C.ConventionID
									AND E.tiID_Type_Enregistrement = @tiID_TypeEnregistrement														 
                                    AND T.iID_Sous_Type = @iID_SousTypeEnregistrement
                                    AND T.dtDate_Transfert = C.dtTransfert
                                    AND T.cStatut_Reponse = 'E'
                            )
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS du bénéficiaire du transfert est absent ou invalide
                IF @iCode_Validation = 704
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert, B.BeneficiaryID, B.vcNomPrenom, B.vcNAS
                        FROM
                            #TB_Transfert_04_01 C
                            JOIN #TB_Beneficiary_04_01 B ON B.ConventionID = C.ConventionID AND B.dtTransfert = C.dtTransfert
                        WHERE
                            Len(IsNull(B.vcNAS, '')) = 0
                            OR dbo.FN_CRI_CheckSin(B.vcNAS, 0) = 0
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        NULL, vcNAS, NULL, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du bénéficiaire du transfert est absent ou invalide
                IF @iCode_Validation = 705
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert, B.BeneficiaryID
                        FROM
                            #TB_Transfert_04_01 C
                            JOIN #TB_Beneficiary_04_01 B ON B.ConventionID = C.ConventionID AND B.dtTransfert = C.dtTransfert
                        WHERE
                            Len(IsNull(B.vcNom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom du bénéficiaire du transfert est absent ou invalide
                IF @iCode_Validation = 706
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert, B.BeneficiaryID
                        FROM
                            #TB_Transfert_04_01 C
                            JOIN #TB_Beneficiary_04_01 B ON B.ConventionID = C.ConventionID AND B.dtTransfert = C.dtTransfert
                        WHERE
                            Len(IsNull(B.vcPrenom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La date de naissance du bénéficiaire du transfert est absent
                IF @iCode_Validation = 707
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert, B.BeneficiaryID, B.vcNomPrenom
                        FROM
                            #TB_Transfert_04_01 C
                            JOIN #TB_Beneficiary_04_01 B ON B.ConventionID = C.ConventionID AND B.dtTransfert = C.dtTransfert
                        WHERE
                            IsNull(B.dtNaissance, '1900-01-01') = '1900-01-01'
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, NULL, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La date de naissance du bénéficiaire du transfert est plus grande que la date du transfert
                IF @iCode_Validation = 708
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert, B.BeneficiaryID, B.vcNomPrenom, B.dtNaissance
                        FROM
                            #TB_Transfert_04_01 C
                            JOIN #TB_Beneficiary_04_01 B ON B.ConventionID = C.ConventionID AND B.dtTransfert = C.dtTransfert
                        WHERE
                            B.dtNaissance > C.dtTransfert
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        CONVERT(VARCHAR(10), dtTransfert, 120), CONVERT(VARCHAR(10), dtNaissance, 120), NULL, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le sexe du bénéficiaire du transfert n’est pas défini
                IF @iCode_Validation = 709
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert, B.BeneficiaryID, B.vcNomPrenom, B.cSexe
                        FROM
                            #TB_Transfert_04_01 C
                            JOIN #TB_Beneficiary_04_01 B ON B.ConventionID = C.ConventionID AND B.dtTransfert = C.dtTransfert
                        WHERE
                            IsNull(B.cSexe, '') NOT IN ('F', 'M')
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, NULL, BeneficiaryID, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom du bénéficiaire de transfert contient au moins 1 caractère non conforme
                IF @iCode_Validation = 710
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert, B.BeneficiaryID, B.vcNomPrenom, B.vcPrenom, 
                            vcNonConforme = dbo.fnIQEE_ValiderNom(B.vcPrenom)
                        FROM
                            #TB_Transfert_04_01 C
                            JOIN #TB_Beneficiary_04_01 B ON B.ConventionID = C.ConventionID AND B.dtTransfert = C.dtTransfert
                    )
                    INSERT INTO #TB_Rejets_04_01 (
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

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du bénéficiaire de transfert contient au moins 1 caractère non conforme
                IF @iCode_Validation = 711
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert, B.BeneficiaryID, B.vcNomPrenom, B.vcNom, 
                            vcNonConforme = dbo.fnIQEE_ValiderNom(B.vcNom)
                        FROM
                            #TB_Transfert_04_01 C
                            JOIN #TB_Beneficiary_04_01 B ON B.ConventionID = C.ConventionID AND B.dtTransfert = C.dtTransfert
                    )
                    INSERT INTO #TB_Rejets_04_01 (
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

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le numéro d’entreprise du Québec (NEQ) du cessionnaire pour un transfert est absent ou invalide
                IF @iCode_Validation = 712
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert, C.vcNEQ_ExtPromo
                        FROM
                            #TB_Transfert_04_01 C
                        WHERE
                            Len(IsNull(C.vcNEQ_ExtPromo, '')) = 0
                            OR dbo.fnGENE_ValiderNEQ(C.vcNEQ_ExtPromo) = 0
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcNEQ_ExtPromo, NULL, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le montant total du transfert calculé doit être plus grand que 0
                IF @iCode_Validation = 713
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert
                        FROM
                            #TB_Transfert_04_01 C
                        WHERE
                            C.mMontantTransfert < 0
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Un montant d'IQÉÉ fait partie d'un transfert non autorisé (L'IQÉÉ doit être récupéré ou GUI doit prendre la perte)
                IF @iCode_Validation = 715
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert, SoldeIQEE = C.mSoldeCreditBase + c.mSoldeMajoration
                        FROM
                            #TB_Transfert_04_01 C
                        WHERE
                            C.mSoldeCreditBase + c.mSoldeMajoration < 0
                            AND @bTransfert_Autorise = 0
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, LTrim(Str(SoldeIQEE, 10, 2)), NULL, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La transaction de transfert est retenue parce qu'il n'y a pas de montant de cotisation ayant eu droit à l'IQÉÉ
                IF @iCode_Validation = 716
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert, SoldeIQEE = C.mSoldeCreditBase + c.mSoldeMajoration
                        FROM
                            #TB_Transfert_04_01 C
                        WHERE
                            C.mAyantDroitIQEE <= 0
                            AND @bTransfert_Autorise = 0
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(@vcDescription, '%dtTransfert%', CONVERT(varchar(10), dtTransfert, 120)),
                        NULL, LTrim(Str(SoldeIQEE, 10, 2)), NULL, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La convention a été fermée par une transaction d'impôt spécial 91 ou 51
                IF @iCode_Validation = 717
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            C.ConventionID, C.dtTransfert
                        FROM
                            #TB_Transfert_04_01 C
                        WHERE
                            Exists (
                                SELECT * FROM dbo.tblIQEE_Transferts T
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE 
                                              JOIN dbo.tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = T.iID_Sous_Type
                                                                                        AND ST.cCode_Sous_Type IN ('91', '51')
                                WHERE 
                                    T.iID_Convention = C.ConventionID
                                    AND T.cStatut_Reponse IN ('A', 'R')
                                    AND T.dtDate_Transfert < C.dtTransfert
                            )
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La convention a des cas spéciaux non résolus avec Revenu Québec en cours
                IF @iCode_Validation = 718
                BEGIN
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        C.ConventionID, @iID_Validation, REPLACE(@vcDescription, '%vcNo_Convention%', C.ConventionNo),
                        NULL, NULL, NULL, NULL, NULL
                    FROM
                        #TB_Transfert_04_01 C
                        JOIN dbo.tblIQEE_CasSpeciaux CS ON CS.iID_Convention = C.ConventionID
                    WHERE
                        CS.bCasRegle = 0
                        AND ISNULL(CS.tiID_TypeEnregistrement, @tiID_TypeEnregistrement) = @tiID_TypeEnregistrement
                        AND ISNULL(CS.iID_SousType, @iID_SousTypeEnregistrement) = @iID_SousTypeEnregistrement

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le transfert «OUT» précédant doit être déclaré à RQ avant que le transfert puisse être déclaré
                IF @iCode_Validation = 719
                BEGIN
                    ; WITH CTE_OperTIN AS (
                        SELECT CO.ConventionID, O.OperID, O.OperDate, T.iID_Ligne_Fichier, T.cStatut_Reponse,
                               RowNum = ROW_NUMBER() OVER(PARTITION BY CO.ConventionID, O.OperDate ORDER BY T.iID_Transfert DESC)
                          FROM dbo.Un_ConventionOper CO
                               JOIN dbo.fntOPER_Active('2007-02-21', @dtFinCotisation) O ON O.OperID = CO.OperID AND O.OperTypeID = 'OUT'
                               LEFT JOIN dbo.tblIQEE_Transferts T ON T.iID_Convention = CO.ConventionID
                                                                 AND T.dtDate_Transfert = O.OperDate
                         WHERE CO.ConventionOperTypeID IN ('CBQ', 'MMQ')                
                           AND CO.ConventionOperAmount <> 0
                    ),
                    CTE_Convention as (
                        SELECT DISTINCT
                            C.ConventionID, C.ConventionNo, C.dtTransfert, O.OperID, O.OperDate, O.iID_Ligne_Fichier
                        FROM
                            #TB_Transfert_04_01 C
                            JOIN CTE_OperTIN O ON O.ConventionID = C.ConventionID
                                              AND O.OperDate < C.dtTransfert
                        WHERE
                            O.RowNum = 1
                            AND ISNULL(O.cStatut_Reponse, '') <> 'R'
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%vcNo_Convention%', ConventionNo), '%dtPaiement%', CONVERT(VARCHAR(10), OperDate, 120)),
                        NULL, NULL, OperID, iID_Ligne_Fichier, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le transfert «TIN» doit être déclaré à RQ avant que le transfert puisse être déclaré
                IF @iCode_Validation = 720
                BEGIN
                    ; WITH CTE_OperTIN AS (
                        SELECT CO.ConventionID, O.OperID, O.OperDate, T.iID_Ligne_Fichier, T.cStatut_Reponse,
                               RowNum = ROW_NUMBER() OVER(PARTITION BY CO.ConventionID, O.OperDate ORDER BY T.iID_Transfert DESC)
                          FROM dbo.Un_ConventionOper CO
                               JOIN dbo.fntOPER_Active('2007-02-21', @dtFinCotisation) O ON O.OperID = CO.OperID AND O.OperTypeID = 'TIN'
                               LEFT JOIN dbo.tblIQEE_Transferts T ON T.iID_Convention = CO.ConventionID
                                                                 AND T.dtDate_Transfert = O.OperDate
                         --WHERE CO.ConventionOperTypeID IN ('CBQ', 'MMQ')                
                         --  AND CO.ConventionOperAmount <> 0
                    ),
                    CTE_Convention as (
                        SELECT DISTINCT
                            C.ConventionID, C.ConventionNo, C.dtTransfert, O.OperID, O.OperDate, O.iID_Ligne_Fichier
                        FROM
                            #TB_Transfert_04_01 C
                            JOIN CTE_OperTIN O ON O.ConventionID = C.ConventionID
                                              AND O.OperDate < C.dtTransfert
                        WHERE
                            O.RowNum = 1
                            AND ISNULL(O.cStatut_Reponse, '') <> 'R'
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%vcNo_Convention%', ConventionNo), '%dtPaiement%', CONVERT(VARCHAR(10), OperDate, 120)),
                        NULL, NULL, OperID, iID_Ligne_Fichier, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le transfert «RIO» doit être déclaré à RQ avant que le transfert puisse être déclaré
                IF @iCode_Validation = 721
                BEGIN
                    ; WITH CTE_OperTIN AS (
                        SELECT CO.ConventionID, O.OperID, O.OperDate, T.iID_Ligne_Fichier, T.cStatut_Reponse,
                               RowNum = ROW_NUMBER() OVER(PARTITION BY CO.ConventionID, O.OperDate ORDER BY T.iID_Transfert DESC)
                          FROM dbo.Un_ConventionOper CO
                               JOIN dbo.fntOPER_Active('2007-02-21', @dtFinCotisation) O ON O.OperID = CO.OperID AND O.OperTypeID = 'RIO'
                               LEFT JOIN dbo.tblIQEE_Transferts T ON T.iID_Convention = CO.ConventionID
                                                                 AND T.dtDate_Transfert = O.OperDate
                         WHERE CO.ConventionOperTypeID IN ('CBQ', 'MMQ')                
                           AND CO.ConventionOperAmount <> 0
                    ),
                    CTE_Convention as (
                        SELECT DISTINCT
                            C.ConventionID, C.ConventionNo, C.dtTransfert, O.OperID, O.OperDate, O.iID_Ligne_Fichier
                        FROM
                            #TB_Transfert_04_01 C
                            JOIN CTE_OperTIN O ON O.ConventionID = C.ConventionID
                                              AND O.OperDate < C.dtTransfert
                        WHERE
                            O.RowNum = 1
                            AND ISNULL(O.cStatut_Reponse, '') <> 'R'
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%vcNo_Convention%', ConventionNo), '%dtPaiement%', CONVERT(VARCHAR(10), OperDate, 120)),
                        NULL, NULL, OperID, iID_Ligne_Fichier, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le paiement d'aide aux études «PAE» doit être déclaré à RQ avant que le transfert puisse être déclaré
                IF @iCode_Validation = 722
                BEGIN
                    ; WITH CTE_OperPAE AS (
                        SELECT CO.ConventionID, O.OperDate, PB.iID_Ligne_Fichier, O.OperID, PB.cStatut_Reponse,
                               RowNum = ROW_NUMBER() OVER(PARTITION BY CO.ConventionID, O.OperDate ORDER BY PB.iID_Paiement_Beneficiaire DESC)
                          FROM dbo.Un_ConventionOper CO
                               JOIN dbo.fntOPER_Active('2007-02-21', @dtFinCotisation) O ON O.OperID = CO.OperID AND O.OperTypeID = 'PAE'
                               LEFT JOIN dbo.tblIQEE_PaiementsBeneficiaires PB ON PB.iID_Convention = CO.ConventionID
                                                                              AND PB.dtDate_Paiement = O.OperDate
                         WHERE CO.ConventionOperTypeID IN ('CBQ', 'MMQ')                
                           AND CO.ConventionOperAmount <> 0
                    ),
                    CTE_Convention as (
                        SELECT DISTINCT
                            C.ConventionID, C.ConventionNo, C.dtTransfert, O.OperID, O.OperDate, O.iID_Ligne_Fichier
                        FROM
                            #TB_Transfert_04_01 C
                            JOIN CTE_OperPAE O ON O.ConventionID = C.ConventionID
                                              AND O.OperDate < C.dtTransfert
                        WHERE
                            O.RowNum = 1
                            AND ISNULL(O.cStatut_Reponse, '') <> 'R'
                    )
                    INSERT INTO #TB_Rejets_04_01 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%vcNo_Convention%', ConventionNo), '%dtPaiement%', CONVERT(VARCHAR(10), OperDate, 120)),
                        NULL, NULL, OperID, iID_Ligne_Fichier, NULL
                    FROM
                        CTE_Convention

                    SET @iCountRejets = @@ROWCOUNT
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
                    iCode_Validation = 700

                RETURN -1
            END CATCH

            -- S'il y a eu des rejets de validation
            IF @iCountRejets > 0
            BEGIN
                PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCountRejets)) + CASE @cType WHEN 'E' THEN ' rejets'
                                                                                                                         WHEN 'A' THEN ' avertissements'
                                                                                                                         ELSE ''
                                                                                                             END
                -- Et si on traite seulement les 1ères erreurs de chaque convention
                IF @bArretPremiereErreur = 1 AND @cType = 'E'
                BEGIN
                    -- Efface que les conventions ayant un rejet sur la validation courante
                    DELETE FROM T
                      FROM #TB_Transfert_04_01 T
                           JOIN #TB_Rejets_04_01 R ON R.iID_Convention = T.ConventionID
                     WHERE iID_Validation = @iID_Validation
                END
            END
        END -- IF @iCode_Validation 

        -- Efface tous les conventions ayant eu au moins un rejet de validation
        DELETE FROM T
          FROM #TB_Transfert_04_01 T
               JOIN #TB_Rejets_04_01 R ON R.iID_Convention = T.ConventionID
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
            #TB_Rejets_04_01 R
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Déclaration des transferts cédant «OUT»'
    BEGIN
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   Créer les enregistrements des transferts OUT.'
        SET @QueryTimer = GetDate()
        ; WITH CTE_Sexe as (
            SELECT X.rowID as ID, X.strField as Code
            FROM ProAcces.fn_SplitIntoTable('F,M', ',') X
        )
        INSERT INTO dbo.tblIQEE_Transferts (
            iID_Fichier_IQEE, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse, iID_Convention, vcNo_Convention, dtDate_Debut_Convention, iID_Sous_Type, 
            iID_Operation, dtDate_Transfert, mTotal_Transfert, mIQEE_CreditBase_Transfere, mIQEE_Majore_Transfere, 
            mCotisations_Donne_Droit_IQEE, mCotisations_Non_Donne_Droit_IQEE, mCotisations_Versees_Avant_Debut_IQEE, 
            ID_Autre_Promoteur, ID_Regime_Autre_Promoteur, vcNo_Contrat_Autre_Promoteur, 
            iID_Beneficiaire, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire, 
            iID_Adresse_Beneficiaire, vcAppartement_Beneficiaire, vcNo_Civique_Beneficiaire, vcRue_Beneficiaire, 
            vcLigneAdresse2_Beneficiaire, vcLigneAdresse3_Beneficiaire, 
            vcVille_Beneficiaire, vcProvince_Beneficiaire, vcPays_Beneficiaire, vcCodePostal_Beneficiaire,
            bTransfert_Total, bPRA_Deja_Verse, bTransfert_Autorise, 
            iID_Souscripteur, tiType_Souscripteur, vcNAS_Souscripteur, vcNEQ_Souscripteur, vcNom_Souscripteur, vcPrenom_Souscripteur, tiID_Lien_Souscripteur, 
            iID_Adresse_Souscripteur, vcAppartement_Souscripteur, vcNo_Civique_Souscripteur, vcRue_Souscripteur, 
            vcLigneAdresse2_Souscripteur, vcLigneAdresse3_Souscripteur, 
            vcVille_Souscripteur, vcProvince_Souscripteur, vcPays_Souscripteur, vcCodePostal_Souscripteur
        )
        OUTPUT inserted.*
        SELECT
            @iID_Fichier_IQEE, @siAnnee_Fiscale, @tiCode_Version, 'A', T.ConventionID, T.ConventionNo, DE.dtDate_EnregistrementRQ, @iID_SousTypeEnregistrement, 
            NULL, T.dtTransfert, T.mMontantTransfert, T.mSoldeCreditBase, T.mSoldeMajoration, 
            T.mAyantDroitIQEE, T.mNonDroitApresIQEE + T.mNonDroitAvantIQEE, T.mNonDroitAvantIQEE, 
            T.vcNEQ_ExtPromo, T.vcNoRegime_ExtPromo, T.vcContratNo_ExtPromo,
            B.BeneficiaryID, B.vcNAS, Left(B.vcNom, 20), Left(B.vcPrenom, 20), B.dtNaissance, (SELECT ID FROM CTE_Sexe WHERE Code = B.cSexe),
            B.iID_Adresse, Left(B.vcAppartement, 6), LEFT(ISNULL(B.vcNoCivique, '-'), 10), 
                Left(CASE WHEN Len(IsNull(B.vcNomRue, '')) > 0
                          THEN B.vcNomRue + CASE WHEN Len(IsNull(B.vcBoite, '')) = 0
                                                 THEN CASE B.iID_TypeBoite WHEN 1 THEN ' CP ' WHEN 2 THEN ' RR ' ELSE ' ' END
                                                 ELSE '' 
                                            END
                          ELSE B.vcAdresse_Tmp
                     END, 50),
            NULL, Left(B.vcAdresseLigne3, 40), 
            LEFT(B.vcVille, 30), Left(IsNull(B.vcProvince, ''), 2), Left(B.cID_Pays, 3), Left(B.vcCodePostal, 10), 
            T.bEstComplet, 0, T.bEstAutoriser, 
            S.SubscriberID, CASE S.cType_HumanOrCompany WHEN 'H' THEN 1 
                                                          WHEN 'C' THEN 2
                                                          ELSE NULL 
                              END, LEFT(S.vcNAS, 9), Left(S.vcNEQ, 10), Left(S.vcNom, 20), Left(S.vcPrenom, 20), S.Subscriber_LienID,
            S.iID_Adresse, Left(S.vcAppartement, 6), LEFT(ISNULL(S.vcNoCivique, '-'), 10), 
                Left(CASE WHEN Len(IsNull(S.vcNomRue, '')) > 0
                          THEN S.vcNomRue + CASE WHEN Len(IsNull(S.vcBoite, '')) = 0
                                                 THEN CASE S.iID_TypeBoite WHEN 1 THEN ' CP ' WHEN 2 THEN ' RR ' ELSE ' ' END
                                                 ELSE '' 
                                            END
                          ELSE S.vcAdresse_Tmp
                     END, 50),
            NULL, Left(S.vcAdresseLigne3, 40), 
            LEFT(S.vcVille, 30), Left(ISNULL(S.vcProvince, ''), 2), Left(S.cID_Pays, 3), Left(S.vcCodePostal, 10)
        FROM
            #TB_Transfert_04_01 T
            JOIN #TB_Beneficiary_04_01 B ON B.ConventionID = T.ConventionID AND B.dtTransfert = T.dtTransfert
            JOIN #TB_Subscriber_04_01 S ON S.ConventionID = T.ConventionID AND S.dtTransfert = T.dtTransfert
            LEFT JOIN dbo.fntIQEE_ObtenirDateEnregistrementRQ_PourTous(DEFAULT) DE ON DE.iID_Convention = T.ConventionID

        SET @iCount = @@RowCount
        SET @ElapseTime = @QueryTimer - GetDate()
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' enregistrements ajoutés (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
    END

    SET @ElapseTime = GetDate() - @StartTimer
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions04_01 completed' 
                + ' (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

    IF OBJECT_ID('tempdb..#TB_Validation_04_01') IS NOT NULL
        DROP TABLE #TB_Validation_04_01
    IF OBJECT_ID('tempdb..#TB_Rejets_04_01') IS NOT NULL
        DROP TABLE #TB_Rejets_04_01
    IF OBJECT_ID('tempdb..#TB_Beneficiary_04_01') IS NOT NULL
        DROP TABLE #TB_Beneficiary_04_01
    IF OBJECT_ID('tempdb..#TB_Transfert_04_01') IS NOT NULL
        DROP TABLE #TB_Transfert_04_01

    -- Retourner 0 si le traitement est réussi
    RETURN 0
END
