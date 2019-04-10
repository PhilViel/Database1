/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : psIQEE_CreerTransactions02
Nom du service  : Créer les transactions de type 02 - Demande de l'IQÉÉ
But             : Sélectionner, valider et créer les transactions de type 02 – Demande de l'IQÉÉ, dans un nouveau fichier de transactions de l’IQÉÉ.
Facette         : IQÉÉ

Paramètres d’entrée :
        Paramètre               Description
        --------------------    -----------------------------------------------------------------
        iID_Fichier_IQEE        Identifiant du nouveau fichier de transactions dans lequel les transactions 06-22 doivent être créées.
        siAnnee_Fiscale         Année fiscale du fichier de transactions en cours de création.
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
        bConsequence_Annulation Indicateur si le fichier de l'année fiscale est la conséquence seulement d'annulations ou aussi parce que 
                                l'utilisateur en a fait la demande.
        iID_Session             Identifiant de session identifiant de façon unique la création des fichiers de transactions
        dtCreationFichier       Date et heure de la création des fichiers identifiant de façon unique avec identifiant de session, la création des
                                fichiers de transactions.
        cID_Langue              Langue du traitement.
        dtDebutCotisation       Date de début de cotisation selon les paramètres de l'IQÉÉ en vigueur pour l'année fiscale du fichier en cours de création.
        dtFinCotisation         Date de fin de cotisation selon les paramètres de l'IQÉÉ en vigueur pourl'année fiscale du fichier en cours de création.
        bit_CasSpecial          Indicateur pour permettre la résolution de cas spéciaux sur des T02 dont le délai de traitement est dépassé. 

Exemple d’appel : Cette procédure doit être appelée uniquement par "psIQEE_CreerFichierAnnee".

Paramètres de sortie:
    Champ               Description
    ------------        ------------------------------------------
    iCode_Retour        = 0 : Exécution terminée normalement
                        < 0 : Erreur de traitement

Historique des modifications:
    Date        Programmeur             Description
    ----------  --------------------    --------------------------------------------------------------------------
    2009-03-05  Éric Deshaies           Création du service                            
    2009-04-28  Éric Deshaies           Modification à la validation #53
    2009-09-24  Éric Deshaies           Reprise des travaux de développement
    2012-06-28  Éric Michaud            Modification RIN sans ID            
    2012-10-16  Stéphane Barbeau        Conditions ajoutées pour empêcher l'envoi de NAS commençant par 0 pour le principal responsable.
    2012-11-21  Stéphane Barbeau        Suppression de l'information du principal responsable lorsque son NAS commence par 0.
    2012-12-10  Stéphane Barbeau        Désactivation de champs falcultatifs.
    2012-12-20  Stéphane Barbeau        Effacements des Modification RIN sans ID du 2012-06-28
    2012-12-28  Stéphane Barbeau        SIMULATION: DROP INDEX
    2013-01-03  Stéphane Barbeau        Désactivation des validations 38, 39 et 52/traitements champs facultatifs.
    2013-01-10  Stéphane Barbeau        Désactivation des validations 76, 77 78
                                            Désactivation simulation Drop Index
                                            Voir s'il faut faire Amendement validation 54: Exclure les transactions originales (0) AND D.tiCode_Version IN (2)  
    2013-03-22  Stéphane Barbeau        Réactivation modifiée validation 38 et 39 pour principal responsable 
    2013-08-01  Stéphane Barbeau        Validation 54: Rendre utilisable pour les reprises (T02-2)         
    2013-08-09  Stéphane Barbeau        Désactivation validation 60
    2013-08-09  Stéphane Barbeau        Ajout validation 91
    2013-09-09  Stéphane Barbeau        Curseur curConvention: Exclure les conventions fermées qui n'ont pas de (TRI, RIM ou OUT) et les 
                                            conventions ayant reçu des erreurs 1510 selon l'année fournie en paramètre
    2013-09-11  Stéphane Barbeau        Ajout validation 92 et ajustement validation 91.
    2013-09-25  Stéphane Barbeau        Requête @iID_Demande_IQEE_Existante: Ajout de condition pour situation (0, D)(1, E)(2, E)                                                     
                                            Ajustement requête validation #75: Ajout de condition pour situation (0, D)(1, E)(2, E)                                                     
    2013-09-26  Stéphane Barbeau        Ajustement assignation @tiCode_Version : Le NAS du bénéficiaire est maintenant une information amendable.  Retrait de la condition.
    2013-10-02  Stéphane Barbeau        Ajustement validation #2: Condition pour déclencher le rejet seulement pour les originales (@tiCode_Version=0)
    2013-10-29  Stéphane Barbeau        Désactivation validation 54.  Incompatibilité avec workflow qui retournait que des rejets injustifiés.
    2013-11-28  Stéphane Barbeau        Ajustement validation 92.
    2013-12-09  Stéphane Barbeau        Optimisation curseur curConvention et réduction de T02-0 de plus de 3 ans.
    2013-12-10  Stéphane Barbeau        Ajustement validation 91: Condition AND NOT EXISTS
    2013-12-13  Stéphane Barbeau        Requête -- S'il n'y a pas d'erreur, créer la transaction 02: Retrait de la condition --AND R.iID_Lien_Vers_Erreur_1 = @iID_Convention_Selectionne
                                            Réactivation d'ajout des rejets #38 et #39
    2013-12-16  Stéphane Barbeau        Ajustement validation 91: Condition EXISTS sur requête statut FRM.
                                            Amélioration sur prise en charge de la validation 42 (Ajout de la logique de la validation 91).
    2014-01-31  Stéphane Barbeau        Ajout validation 93                                                            
    2014-02-28  Stéphane Barbeau        Ajout paramètre @bPremier_Envoi_Originaux et son traitement ainsi que son exclusion sur les validations 3, 4, 41, 75, 92
    2014-05-22  Stéphane Barbeau        Validation 91: Ajustement requêtes pour valider la dernière valeur de ConventionStateID pour les cas de réouveture de conventions.
    2014-07-07  Stéphane Barbeau        Mise a niveau selon nouveau module des adresses: remplacer fnGENE_AdresseEnDate par fntGENE_TrouverAdresseEnDate
    2014-07-09  Stéphane Barbeau        Performance: retrait de l'utilisation de fntGENE_ObtenirAdresseEnDate et requêtes directes sur les tables tblGENE_Adresse et tblGENE_AdresseHistorique
    2014-07-30  Stéphane Barbeau        Traitement de @cCode_Pays_Souscripteur_TMP et @cCode_Pays_Beneficiaire_TMP.
    2014-08-06  Stéphane Barbeau        Ajout du paramètre @bit_CasSpecial pour permettre la résolution de cas spéciaux sur des T02 dont le délai de traitement est dépassé. 
    2014-08-13  Stéphane Barbeau        Ajout du traitement du rejet #94.
    2014-09-10  Stéphane Barbeau        Rejets 91 et 42: Ajout condition AND @bit_CasSpecial = 0 pour pouvoir traiter des cas spéciaux sur conventions fermées.        
    2014-09-19  Stéphane Barbeau        Traitement des adresses ayant des cases postales et des routes rurales séparées selon les nouvelles tables les tables tblGENE_Adresse et tblGENE_AdresseHistorique.
    2014-10-09  Stéphane Barbeau        Validation #58 retrait de la condition "AND I.dtDate_Evenement < @dtFinCotisation" afin de traiter la validation peu importe l'année fiscale fournie en paramètre.                                                                                                        
    2014-11-07  Stéphane Barbeau        Ajout else @vcAdresse_Beneficiaire_TMP avec @vcRue_Beneficiaire 
                                              else @vcAdresse_Souscripteur_TMP avec @vcRue_Souscripteur si type boîte = 0.
    2014-11-10  Stéphane Barbeau        Ajout else @vcAdresse_Beneficiaire_TMP avec @vcRue_Beneficiaire 
                                              else @vcAdresse_Souscripteur_TMP avec @vcRue_Souscripteur si type boîte = 1.
    2014-11-18  Stéphane Barbeau        Ajustement attribution @vcCasePostaleRouteRurale_Beneficiaire avec requête tblGENE_Adresse
                                            Nouvelle requête pour @iID_Adresse_31Decembre_Beneficiaire avec table tblGENE_AdresseHistorique
    2014-11-25  Stéphane Barbeau        Ajustement validation #6 pour traiter seulement les version originales (tiCode_Version = 0)        
    2014-12-09  Stéphane Barbeau        Code utilisé pour prioriser le champ vcInternationale1 utilisé par le module des adresses de Proacces lors d'adresses hors Canada.
    2015-03-19  Stéphane Barbeau        Ajout validation @bit_CasSpécial validation #43
    2015-09-11  Stéphane Barbeau        Réactivation de déclaration des numéros d'appartement du bénéficiaire et souscripteur.
                                            Requête Curseur: Inclure les demandes au statut en attente 'A' 
    2016-02-02  Steeve Picard           Optimisation en remplaçant les curseurs SQL par des boucles WHILE
    2016-03-01  Steeve Picard           Déduire le montant de RIN avec preuve du total de cotisation subventionnable à partir de 2016
    2016-05-04    Steeve Picard           Renommage de la fonction «fnIQEE_ObtenirDateEnregistrementRQ» qui était auparavant «fnIQEE_ObtenirDateEnregistrementRQ»
    2016-06-09  Steeve Picard           Modification au niveau des paramètres de la fonction «dbo.fntIQEE_CalculerMontantsDemande»
    2016-09-27  Steeve Picard           Réinsérer l'info du co-souscripteur lorsqu'il est présent
    2016-12-14  Steeve Picard           Correctif pour la recherche de «@iID_Demande_IQEE_Existante»
    2016-12-14  Steeve Picard           Optimisation en traitant par batch et non une convention à la fois
    2017-05-04  Steeve Picard           Correctif pour ignorer le principal responsable si son «NAS» débute par «0»
                                        Correctif pour les caractères accentués dans les prénom et les noms
    2017-06-09  Steeve Picard           Ajout du paramètre « @tiCode_Version = 0 » pour passer la valeur « 2 » lors d'une annulation/reprise
    2017-07-11  Steeve Picard           Élimination du paramètre « iID_Convention » pour toujours utiliser la table « #TB_ListeConvention »
    2017-08-16  Steeve Picard           Ramener la vérification l'état de la convention à la fin de l'année fiscale
                                        La validation #91 va rejeter celles qui sont fermées dans l'année suivante
    2017-08-22  Steeve Picard           Utilisation du NAS courant du bénéficiaire au lieu de celui dans l'historique
    2017-09-14  Steeve Picard           Correctif pour les caractères accentués dans les prénom et les noms du principal responsable
    2017-09-27  Steeve Picard           Utilisation de la fonction «dbo.fntOPER_Active» pour les retrouver les opéraitions
    2017-11-23  Steeve Picard           Inclure les conventions qui n'ont pas de statut au 31 décembre de l'année fiscale mais ayant une date d'entrée en vigueur valide
    2017-11-23  Steeve Picard           Recherche les 1ères adresses des souscripteurs/bénéficiaires qui n'ont pas au 31 décembre de l'année fiscale
    2017-11-30  Steeve Picard           Recherche les dernières adresses connues des souscripteurs/bénéficiaires qui n'ont plus d,active au 31 décembre de l'année fiscale
    2017-12-19  Steeve Picard           Modificiation à la fonction «fntIQEE_CalculerMontantsDemande_PourTous» qui retourne aussi la «RIN_SansPreuve»
    2018-01-04  Steeve Picard           Validation de base si @cCode_Portee = '' pour l'estimation du rapport à recevoir
    2018-01-18  Steeve Picard           Sélection des conventions qui sont pas fermées en date du paramètre «@dtFinCotisation»
    2018-01-18  Steeve Picard           Sélection des conventions qui sont pas fermées en date du paramètre «@dtFinCotisation»
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments «tblIQEE_Demandes»
    2018-02-22  Steeve Picard           Élimination des paramètres «@dtDebutCotisation & @dtFinCotisation» pour les convertir en variables basées sur «@siAnnee_Fiscale»
    2018-02-26  Steeve Picard           Empêcher que la «dtFinCotisation» soit plus grande que la dernière fin de mois
    2018-03-16  Steeve Picard           Tenir compte de la date du changement bénéficiaire pour la validation #93 «PCEE : Raison de refus # 7 : Ne satisfait pas à la règle des 16 et 17 ans»
    2018-03-20  Steeve Picard           Ajout d'un paramètre «@StartDate» à la fonction «fntOPER_Active»
    2018-05-15  Steeve Picard           Correction du calcul de cotisation annuelle totale «mCotisations»
    2018-06-04  Steeve Picard           Correction dans la sélection des conventions pour permettre les annulations/reprises
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
    2018-07-05  Steeve Picard           Ajout du champ «bResidenceFaitQuebec» pour les recherches subséquentes des bénéficiaires
    2018-09-19  Steeve Picard           Ajout du champ «iID_SousType» à la table «tblIQEE_CasSpeciaux» pour pouvoir filtrer
    2018-09-25  Steeve Picard           Remplacer la valeur de province «Québec» de l'adresse par «QC»
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_CreerTransactions02]
(
    @iID_Fichier_IQEE INT, 
    @siAnnee_Fiscale SMALLINT, 
    @bPremier_Envoi_Originaux BIT, 
    @bArretPremiereErreur BIT, 
    @cCode_Portee CHAR(1), 
    @bConsequence_Annulation BIT, 
    @iID_Session INT, 
    @dtCreationFichier DATETIME, 
    @cID_Langue CHAR(3), 
    @bit_CasSpecial BIT,
    @tiCode_Version TINYINT = 0
)
AS
BEGIN
    SET NOCOUNT ON

    PRINT ''
    PRINT 'Déclaration des demandes de subvention (T02) pour ' + STR(@siAnnee_Fiscale, 4)
    PRINT '------------------------------------------------------'
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions_02 started'

    DECLARE @BorneInferieureAnneeFiscale int = Year(GetDate()) - 4

    IF @bit_CasSpecial <> 0
        SET @BorneInferieureAnneeFiscale = @siAnnee_Fiscale 

    IF @siAnnee_Fiscale < @BorneInferieureAnneeFiscale AND @tiCode_Version = 0
    BEGIN
        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' On ne peut plus faire de demande de subvention antérieure à l''année ' + STR(@BorneInferieureAnneeFiscale, 4)
        RETURN         
    END 

    IF Object_ID('tempDB..#TB_ListeConvention') IS NULL
        RAISERROR ('La table « #TB_ListeConvention (RowNo INT Identity(1,1), ConventionID int, ConventionNo varchar(20) » est abesente ', 16, 1)

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Identifie le(s) convention(s)'
    DECLARE @iCount int = (SELECT Count(*) FROM #TB_ListeConvention)
    IF @iCount > 0
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - ' + LTrim(Str(@iCount)) + ' conventions à génèrées'

    DECLARE @StartTimer datetime = GetDate(),
            --@WhileTimer datetime,
            @QueryTimer datetime,
            @ElapseTime datetime,
            --@IntervalPrint INT = 5000,
            @MaxRow INT = 0,
            @IsDebug bit = 1 --dbo.fn_IsDebug()

    --  Déclaration des variables
    BEGIN
        DECLARE 
            @dtToday DATE = DATEADD(DAY, -1, DATEADD(MONTH, 2, DATEADD(DAY, 1-DATEPART(DAYOFYEAR, GETDATE()), GETDATE()))), --GETDATE(),
            @tiID_TypeEnregistrement TINYINT,               @iID_SousTypeEnregistrement INT,
            --@vcNo_Convention VARCHAR(15) ,                  @TB_Adresse UDT_tblAdresse,
            @dtDebutCotisation DATETIME,                    @dtFinCotisation DATETIME,
            @bTransfert_Autorise BIT = 1,                   @dtMaxCotisation DATETIME = DATEADD(DAY, -DAY(GETDATE()), GETDATE())
    
        -- Sélectionner dates applicables aux transactions
        SELECT @dtDebutCotisation = Str(@siAnnee_Fiscale, 4) + '-01-01 00:00:00',
               @dtFinCotisation = STR(@siAnnee_Fiscale, 4) + '-12-31 23:59:59'

        IF @dtFinCotisation > @dtMaxCotisation
            SET @dtFinCotisation = @dtMaxCotisation

        DECLARE 
            @TB_Adresse UDT_tblAdresse,
            @vcCaracteresAccents varchar(100) = '%[Å,À,Á,Â,Ã,Ä,Ç,È,É,Ê,Ë,Ì,Í,Î,Ï,Ñ,Ò,Ó,Ô,Õ,Ö,Ù,Ú,Û,Ü,Ý]%'

        CREATE TABLE #TB_CaracteresAccents_02 (
            HumanID INT not NULL,
            OldValue varchar(100) NOT NULL,
            NewValue varchar(100) NOT NULL
        )
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupère les IDs du type & sous-type pour ce type d''enregistrement'
    SELECT 
        @tiID_TypeEnregistrement = tiID_Type_Enregistrement,
        @iID_SousTypeEnregistrement = iID_Sous_Type
    FROM
        dbo.vwIQEE_Enregistrement_TypeEtSousType 
    WHERE
        cCode_Type_Enregistrement = '02'
        AND cCode_Sous_Type IS NULL

    DECLARE @TB_OperCode_BloquantDemande TABLE (ID int IDENTITY(1,1), vcCode varchar(10))

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupère les codes d''opération de cotisation pour les subventions'
    INSERT INTO @TB_OperCode_BloquantDemande (vcCode)
    --OUTPUT inserted.*
    SELECT X.strField
    FROM dbo.fntGENE_SplitIntoTable(dbo.fnOPER_ObtenirTypesOperationCategorie('IQEE-DEMANDE-COTISATION'), ',') X

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

    IF OBJECT_ID('tempDB..#TB_Demande_02') IS NOT NULL
        DROP TABLE #TB_Demande_02

    CREATE TABLE #TB_Demande_02 (
        ConventionID INT, 
        ConventionNo varchar(15),
        ConventionStateID varchar(5),
        SubscriberID INT,
        CoSubscriberID INT,
        BeneficiaryID INT,
        BeneficiarySince DATE,
        Subscriber_LienID tinyint,
        Subcriber_WantIQEE BIT DEFAULT(0),
        dtEntreeEnVigueur DATE,
        DateEnregistrementRQ DATE,
        Cotisation money DEFAULT(0),
        Transfert_IN money DEFAULT(0),
        CotisationTotal money DEFAULT(0),
        CotisationSubventionnable money DEFAULT(0),
        IsRejected bit DEFAULT(0)
    )

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération des conventions à déclarer'
    BEGIN
        ------------------------------------------------------------------------------------------------------------
        -- Identifier et sélectionner les conventions ayant des transactions dans l'année fiscale du fichier à créer
        ------------------------------------------------------------------------------------------------------------

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupère les conventions n''ayant pas de demande active dans l''année'
        SET @QueryTimer = GetDate()
    
        SET ROWCOUNT @MaxRow

        ;WITH CTE_Convention AS (
            SELECT DISTINCT 
                C.ConventionID, C.ConventionNo, S.ConventionStateID, C.SubscriberID, C.CoSubscriberID, C.bSouscripteur_Desire_IQEE, C.dtEntreeEnVigueur, RS.tiCode_Equivalence_IQEE
            FROM 
                dbo.Un_Convention C 
                JOIN #TB_ListeConvention X ON X.ConventionID = C.ConventionID
                LEFT JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtFinCotisation, DEFAULT) S ON S.conventionID = C.ConventionID 
                LEFT JOIN Un_RelationshipType RS ON RS.tiRelationshipTypeID = C.tiRelationshipTypeID
            WHERE
                C.bSouscripteur_Desire_IQEE <> 0
                AND ISNULL(S.ConventionStateID, 'PRP') <> 'FRM'
        ),
        CTE_Cotisation AS (
            SELECT 
                U.ConventionID, Sum(Ct.Cotisation + Ct.Fee) as TotalCotisation
            FROM 
                dbo.Un_Unit U
                JOIN CTE_Convention C ON C.ConventionID = u.ConventionID
                -- Il y a des cotisations dans l'année fiscale
                JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
                                     AND CT.EffectDate Between @dtDebutCotisation AND @dtFinCotisation
                -- Il y a des cotisations applicables aux subventions
                JOIN dbo.fntOPER_Active(@dtDebutCotisation, @dtFinCotisation) O ON O.OperID = CT.OperID
                LEFT JOIN @TB_OperCode_BloquantDemande OB ON OB.vcCode = O.OperTypeID
            WHERE
                OB.ID IS NULL
            GROUP BY
                U.ConventionID
            --HAVING Sum(Ct.Cotisation + Ct.Fee) > 0
        ),
        CTE_Demande as (
            SELECT
                D.iID_Convention, D.tiCode_Version, D.cStatut_Reponse, D.mTotal_Cotisations_Subventionnables,
                Row_Num = ROW_NUMBER() OVER(PARTITION BY D.iID_Convention ORDER BY ISNULL(D.iID_Ligne_Fichier, 2147483647) DESC, D.iID_Demande_IQEE DESC)
            FROM
                dbo.tblIQEE_Demandes D 
                JOIN CTE_Convention C ON C.ConventionID = D.iID_Convention
                JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
            WHERE
                D.siAnnee_Fiscale = @siAnnee_Fiscale
                AND NOT D.cStatut_Reponse IN ('E','X')
        )
        INSERT INTO #TB_Demande_02 (ConventionID, ConventionNo, ConventionStateID, SubscriberID, CoSubscriberID, BeneficiaryID, BeneficiarySince, Subscriber_LienID, Subcriber_WantIQEE, dtEntreeEnVigueur, DateEnregistrementRQ)
        --OUTPUT inserted.*
        SELECT DISTINCT 
            C.ConventionID, C.ConventionNo, C.ConventionStateID, IsNull(CS.SubscriberID_Old, C.SubscriberID), C.CoSubscriberID, CB.iID_Beneficiaire, CB.dtDateDebut, C.tiCode_Equivalence_IQEE, C.bSouscripteur_Desire_IQEE, C.dtEntreeEnVigueur, RQ.dtDate_EnregistrementRQ
        FROM 
            CTE_Convention C
            JOIN CTE_Cotisation Ct ON Ct.ConventionID = C.ConventionID
            JOIN dbo.fntCONV_ObtenirBeneficiaireParConventionEnDate(@dtFinCotisation, DEFAULT) CB ON CB.iID_Convention = C.ConventionID
            LEFT JOIN dbo.fntCONV_PremierChangementSouscripteur(@dtFinCotisation, DEFAULT) CS ON CS.ConventionID = C.ConventionID
            LEFT JOIN dbo.fntIQEE_ObtenirDateEnregistrementRQ_PourTous(DEFAULT) RQ ON RQ.iID_Convention = C.ConventionID
            LEFT JOIN CTE_Demande D ON D.iID_Convention = C.ConventionID AND D.Row_Num = 1
        WHERE
            0 = 0
            AND (   D.iID_Convention IS NULL
                    OR (    D.Row_Num = 1 
                            AND (   D.tiCode_Version = 1 
                                    OR ( D.tiCode_Version = 2 AND D.cStatut_Reponse = 'R' AND D.mTotal_Cotisations_Subventionnables = 0 )
                            )
                    )
            )
        ORDER BY
            C.ConventionID DESC
        SET @iCount = @@ROWCOUNT

        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        SET ROWCOUNT 0

        SET @MaxRow = CASE WHEN @iCount < 10 THEN @iCount ELSE 0 END

        --PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' - Récupération celles des reprises de demande'
        --SET @QueryTimer = GetDate()
        --INSERT INTO #TB_Demande_02 (ConventionID, ConventionNo, SubscriberID, Subcriber_WantIQEE)
        --SELECT DISTINCT 
        --    C.ConventionID, C.ConventionNo, C.SubscriberID, C.bSouscripteur_Desire_IQEE
        --FROM 
        --    #TB_ListeConvention X 
        --    JOIN dbo.Un_Convention C ON C.ConventionID = X.ConventionID
        --    JOIN dbo.tblIQEE_Demandes D ON D.iID_Convention = X.ConventionID
        --                               AND D.siAnnee_Fiscale = @siAnnee_Fiscale
        --    -- Uniquement dans l'année fiscale de la création du fichier en cours
        --    JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
        --    -- Uniquement les demandes d'annulation sur des transactions de la convention
        --    JOIN dbo.tblIQEE_Annulations A ON A.iID_Enregistrement_Demande_Annulation = D.iID_Demande_IQEE
        --WHERE 
        --    -- Sélectionner uniquement ceux de la création en cours
        --    A.iID_Session = @iID_Session
        --    AND A.dtDate_Creation_Fichiers = @dtCreationFichier
        --    AND A.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
        --SET @iCount = @@ROWCOUNT
        --SET @ElapseTime = GetDate() - @QueryTimer
        --PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF EXISTS(SELECT TOP 1 * FROM #TB_Demande_02)
        BEGIN

            --DECLARE @vcMntFrais varchar(10)
            --SET @vcMntFrais = dbo.fnGENE_ObtenirParametre('CONV_MNT_FRAIS_R17', @dtFinCotisation, NULL, NULL, NULL, NULL, NULL)

            PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Récupère la somme des cotisations subventionnables par convention'
            SET @QueryTimer = GetDate()
            UPDATE TB SET 
                Cotisation = S.mCotisations,
                Transfert_IN = S.mTransfert_IN,
                CotisationSubventionnable = S.mTotal_Subventionnables,
                CotisationTotal = S.mTotal_Cotisations
            FROM
                #TB_Demande_02 TB
                JOIN dbo.fntIQEE_CalculerMontantsDemande_PourTous(NULL, @dtDebutCotisation, @dtFinCotisation, DEFAULT) S ON S.iID_Convention = TB.ConventionID
            WHERE
                S.mTotal_Subventionnables > 0

            SET @iCount = @@ROWCOUNT
            SET @ElapseTime = GetDate() - @QueryTimer
            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

            PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Élimine les conventions dont la somme des cotisations subventionnables <= 0'
            SET @QueryTimer = GetDate()
            DELETE FROM #TB_Demande_02
             WHERE CotisationSubventionnable < 0
                OR (CotisationSubventionnable = 0 AND @tiCode_Version <> 2)
            SET @iCount = @@ROWCOUNT
            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' effacées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
        END

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            SELECT * FROM #TB_Demande_02 TB

        SELECT @iCount = COUNT(*)  FROM #TB_Demande_02
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' restantes à traiter (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @iCount = 0
            RETURN 
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération les infos des souscripteurs'
    BEGIN
        IF Object_ID('tempDB..#TB_Subscriber_02') IS NOT NULL
            DROP TABLE #TB_Subscriber_02

        SET @QueryTimer = GetDate()
        ; WITH CTE_Subscriber as (
            SELECT DISTINCT
                TB.SubscriberID, 
                vcNom = LTRIM(H.LastName), 
                vcPrenom = LTRIM(H.FirstName), 
                vcCompagnie = LTRIM(H.CompanyName), 
                cType_HumanOrCompany = CASE WHEN H.IsCompany = 0 THEN 'H' ELSE 'C' END,
                H.SocialNumber,
                vcNEQ = CASE WHEN H.IsCompany <> 0 THEN 
                                  CASE WHEN Len(LTrim(H.StateCompanyNo)) = 0 THEN NULL 
                                       ELSE LTRIM(H.StateCompanyNo) 
                                  END
                             ELSE NULL 
                        END
            FROM 
                #TB_Demande_02 TB
                JOIN dbo.Mo_Human H ON H.HumanID = TB.SubscriberID
        )
        SELECT
            TB.*, 
            vcNAS = TB.SocialNumber, --CASE cType_HumanOrCompany WHEN 'H' THEN IsNull(N.SocialNumber, TB.SocialNumber) ELSE NULL END, 
            vcNomPrenom = dbo.fn_Mo_FormatHumanName(TB.vcNom, '', TB.vcPrenom, '', '', 0),
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
            #TB_Subscriber_02
        FROM 
            CTE_Subscriber TB
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = TB.SubscriberID
            LEFT JOIN dbo.fntCONV_ObtenirNasParHumainEnDate(@dtFinCotisation) N ON N.HumanID = TB.SubscriberID
            LEFT JOIN dbo.fntGENE_ObtenirAdresseEnDate_PourTous(NULL, 1, @dtFinCotisation, 0) A ON A.iID_Source = TB.SubscriberID And A.cType_Source = TB.cType_HumanOrCompany
                                                                                          
        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
        
        IF EXISTS(SELECT TOP 1 * FROM #TB_Subscriber_02 WHERE iID_Adresse IS NULL)
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
                #TB_Subscriber_02 S 
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
                #TB_Subscriber_02 S 
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
            #TB_Subscriber_02
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
        FROM #TB_Subscriber_02 TB
             JOIN dbo.fntIQEE_CorrigerAdresseUserTable(@TB_Adresse) A ON A.iID_Source = TB.SubscriberID And A.iID_Adresse = TB.iID_Adresse

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' corrigées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Génère le nom de rue complet'
        SET @QueryTimer = GetDate()

        UPDATE #TB_Subscriber_02 SET
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
          FROM #TB_Subscriber_02 TB 
               JOIN dbo.Mo_State S ON S.vcNomWeb_FRA = TB.vcProvince OR S.vcNomWeb_ENU = TB.vcProvince
         WHERE TB.cID_Pays = 'CAN'

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            SELECT * from #TB_Subscriber_02
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération les infos des co-souscripteurs'
    BEGIN
        IF Object_ID('tempDB..#TB_CoSubscriber_02') IS NOT NULL
            DROP TABLE #TB_CoSubscriber_02

        SET @QueryTimer = GetDate()
        ; WITH CTE_CoSubscriber as (
            SELECT DISTINCT
                iID_CoSubscriber = TB.SubscriberID, 
                vcNom = LTRIM(H.LastName), 
                vcPrenom = LTRIM(H.FirstName), 
                vcCompagnie = LTRIM(H.CompanyName), 
                cType_HumanOrCompany = CASE WHEN H.IsCompany = 0 THEN 'H' ELSE 'C' END,
                vcNEQ = H.StateCompanyNo
            FROM
                #TB_Demande_02 TB
                JOIN dbo.Mo_Human H ON H.HumanID = TB.SubscriberID
        )
        SELECT
            TB.*, 
            vcNAS = N.SocialNumber, 
            vcNomPrenom = dbo.fn_Mo_FormatHumanName(TB.vcNom, '', TB.vcPrenom, '', '', 0),
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
            #TB_CoSubscriber_02
        FROM 
            CTE_CoSubscriber TB
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = TB.iID_CoSubscriber
            LEFT JOIN dbo.fntCONV_ObtenirNasParHumainEnDate(@dtFinCotisation) N ON N.HumanID = TB.iID_CoSubscriber
            LEFT JOIN dbo.fntGENE_ObtenirAdresseEnDate_PourTous(NULL, 1, @dtFinCotisation, 0) A ON A.iID_Source = TB.iID_CoSubscriber And A.cType_Source = TB.cType_HumanOrCompany
                                                                                          
        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
        
        IF EXISTS(SELECT TOP 1 * FROM #TB_CoSubscriber_02 WHERE iID_Adresse IS NULL)
        BEGIN
            SET @QueryTimer = GetDate()
            PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération des adresses inexistantes fiscale des co-souscripteurs pour cette année fiscale'

            UPDATE CS SET
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
                #TB_CoSubscriber_02 CS 
                JOIN dbo.fntGENE_ObtenirDerniereAdresseConnue(DEFAULT, 1, @dtFinCotisation, 0) A ON A.iID_Source = CS.iID_CoSubscriber
            WHERE
                CS.iID_Adresse IS NULL 

            UPDATE CS SET
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
                #TB_CoSubscriber_02 CS 
                JOIN dbo.fntGENE_ObtenirAdressePremiereConnue(DEFAULT, 1, @dtFinCotisation, 0) A ON A.iID_Source = CS.iID_CoSubscriber
            WHERE
                CS.iID_Adresse IS NULL 

            SET @iCount = @@ROWCOUNT
            SET @ElapseTime = GetDate() - @QueryTimer
            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'
        END

        DELETE FROM @TB_Adresse

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Corrige le # civique & l''appartement des adresses n''en ayant pas'
        SET @QueryTimer = GetDate()

        INSERT INTO @TB_Adresse (iID_Source, iID_Adresse, vcNoCivique, vcAppartement, vcNomRue, iID_TypeBoite, vcBoite)
        SELECT DISTINCT
            iID_CoSubscriber, iID_Adresse, vcNoCivique, vcAppartement, vcNomRue, iID_TypeBoite, vcBoite
        FROM
            #TB_CoSubscriber_02
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
        FROM #TB_CoSubscriber_02 TB
             JOIN dbo.fntIQEE_CorrigerAdresseUserTable(@TB_Adresse) A ON A.iID_Source = TB.iID_CoSubscriber And A.iID_Adresse = TB.iID_Adresse

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' corrigées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Génère le nom de rue complet'
        SET @QueryTimer = GetDate()

        UPDATE #TB_CoSubscriber_02 SET
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
          FROM #TB_CoSubscriber_02 TB 
               JOIN dbo.Mo_State S ON S.vcNomWeb_FRA = TB.vcProvince OR S.vcNomWeb_ENU = TB.vcProvince
         WHERE TB.cID_Pays = 'CAN'

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            SELECT * from #TB_CoSubscriber_02
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Récupération les infos des bénéficiaires'
    BEGIN
        IF Object_ID('tempDB..#TB_Beneficiary_02') IS NOT NULL
            DROP TABLE #TB_Beneficiary_02

        SET @QueryTimer = GetDate()
        ;WITH CTE_Beneficiary as (
            SELECT DISTINCT
                TB.BeneficiaryID,
                vcNAS =  ISNULL(H.SocialNumber, ''), -- CASE WHEN HSN.HumanID IS NULL THEN '' ELSE ISNULL(H.SocialNumber, '') END,
                vcNom = LTRIM(H.LastName), 
                vcPrenom = LTRIM(H.FirstName), 
                dtNaissance = H.BirthDate, 
                cSexe = H.SexID
            FROM 
                #TB_Demande_02 TB
                JOIN dbo.Mo_Human H ON H.HumanID = TB.BeneficiaryID
          --      LEFT JOIN (    
          --          SELECT HumanID, MIN(EffectDate) AS First_EffectDate
                      --FROM dbo.UN_HumanSocialNumber
          --           GROUP BY HumanID
                   -- ) HSN ON HSN.HumanID = H.HumanID AND DATEADD(YEAR, -2, HSN.First_EffectDate) <= TB.dtEntreeEnVigueur
            --WHERE 
            --    DATEDIFF(YEAR, TB.dtEntreeEnVigueur, HSN.First_EffectDate) < 2
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
            #TB_Beneficiary_02
        FROM 
            CTE_Beneficiary TB
            JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = TB.BeneficiaryID
            LEFT JOIN dbo.fntGENE_ObtenirAdresseEnDate_PourTous(NULL, 1, @dtFinCotisation, 0) A ON A.iID_Source = B.BeneficiaryID AND A.cType_Source = 'H'
            --LEFT JOIN #TB_Subscriber_02 S ON S.SubscriberID = B.ResponsableIDSouscripteur
            
        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' retrouvées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        UPDATE B SET
            tiType_Responsable = 1,
            vcNAS_Responsable = S.vcNAS,
            vcNom_Responsable = S.vcNom,
            vcPrenom_Responsable = S.vcPrenom,
            vcNomPrenom_Responsable = S.vcNomPrenom
        FROM 
            #TB_Beneficiary_02 B
            JOIN #TB_Demande_02 D ON D.BeneficiaryID = B.BeneficiaryID
            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
        WHERE 
            tiType_Responsable IS NULL
            AND D.Subscriber_LienID = 1
        
        IF EXISTS(SELECT TOP 1 * FROM #TB_Beneficiary_02 WHERE iID_Adresse IS NULL)
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
                                                END)),
                bResidenceFaitQuebec = A.bResidenceFaitQuebec
            FROM 
                #TB_Beneficiary_02 B 
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
                                                END)),
                bResidenceFaitQuebec = A.bResidenceFaitQuebec
            FROM 
                #TB_Beneficiary_02 B 
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
              FROM #TB_Beneficiary_02
             WHERE PatIndex(@vcCaracteresAccents, vcNom_Responsable) <> 0
                OR PatIndex(@vcCaracteresAccents, vcPrenom_Responsable) <> 0 
        )
        UPDATE #TB_Beneficiary_02 SET
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
            #TB_Beneficiary_02
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
            #TB_Beneficiary_02 TB
            JOIN dbo.fntIQEE_CorrigerAdresseUserTable(@TB_Adresse) A ON A.iID_Source = TB.BeneficiaryID And A.iID_Adresse = TB.iID_Adresse

        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' corrigées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   - Génère le nom de rue complet'
        SET @QueryTimer = GetDate()

        UPDATE #TB_Beneficiary_02 SET
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
          FROM #TB_Beneficiary_02 TB 
               JOIN dbo.Mo_State S ON S.vcNomWeb_FRA = TB.vcProvince OR S.vcNomWeb_ENU = TB.vcProvince
         WHERE TB.cID_Pays = 'CAN'

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            SELECT * from #TB_Beneficiary_02
    END

    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Identifie les conventions ayant déjà eu une demande de subvention dans l''années'
    BEGIN
        IF OBJECT_ID('tempDB..#TB_PrevDemande_02') IS NOT NULL
            DROP TABLE #TB_PrevDemande_02

        CREATE TABLE #TB_PrevDemande_02 (
            iID_Convention INT,
            iID_Demande INT,
            tiCodeVersion TINYINT,
            cStatus char(1)
        )

        SET @QueryTimer = GetDate()
        INSERT INTO #TB_PrevDemande_02 (iID_Convention, iID_Demande, tiCodeVersion, cStatus)
        SELECT DISTINCT 
            TB.ConventionID, D.iID_Demande_IQEE, D.tiCode_Version, D.cStatut_Reponse
        FROM
            #TB_Demande_02 TB 
            JOIN dbo.tblIQEE_Demandes D ON D.iID_Convention = TB.ConventionID
            --JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
        WHERE 
            D.siAnnee_Fiscale = @siAnnee_Fiscale    
            AND (
                    (   D.tiCode_Version IN (0, 2) 
                        AND D.cStatut_Reponse IN ('A', 'R')
                    )
                    OR  (
                        D.tiCode_Version = 0
                        AND D.cStatut_Reponse = 'D'
                        AND NOT EXISTS (
                                SELECT * FROM 
                                    dbo.tblIQEE_Demandes D1 
                                    JOIN @TB_FichierIQEE F1 ON F1.iID_Fichier_IQEE = D1.iID_Fichier_IQEE
                                WHERE
                                    D1.iID_Convention = TB.ConventionID
                                    AND D1.tiCode_Version = 1
                                    AND D1.cStatut_Reponse = 'A'
                                    AND D1.siAnnee_Fiscale = @siAnnee_Fiscale
                            )
                        AND
                        NOT EXISTS ( 
                                SELECT * FROM 
                                    dbo.tblIQEE_Demandes AS D2 
                                    JOIN @TB_FichierIQEE AS F2 ON F2.iID_Fichier_IQEE = D2.iID_Fichier_IQEE
                                WHERE 
                                    D2.iID_Convention = TB.ConventionID
                                    AND D2.tiCode_Version = 2
                                    AND D2.cStatut_Reponse = 'A'
                                    AND D2.siAnnee_Fiscale = @siAnnee_Fiscale
                            )
                    )
                )
        SET @iCount = @@ROWCOUNT
        SET @ElapseTime = GetDate() - @QueryTimer
        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » ' + LTrim(Str(@iCount)) + ' identifiées (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

        IF @IsDebug <> 0 AND @MaxRow between 1 and 10
            select * from #TB_PrevDemande_02
    END

    ------------------------------------------------------------------------------------------------
    -- Valider les demandes de subvention et conserver les raisons de rejet en vertu des validations
    ------------------------------------------------------------------------------------------------
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' Validation des conventions selon les critères RQ'
    BEGIN
        DECLARE
            @iID_Validation INT,                            @iCode_Validation INT, 
            @vcDescription VARCHAR(300),                    @cType CHAR(1), 
            @vcTMP1 VARCHAR(100),                           @vcTMP2 VARCHAR(100), 
            @iCountRejets INT

        IF OBJECT_ID('tempdb..#TB_Rejet_02') IS NULL
            CREATE TABLE #TB_Rejets_02 (
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
            TRUNCATE TABLE #TB_Rejet_02

        -- Sélectionner les validations à faire pour le sous type de transaction
        IF OBJECT_ID('tempdb..#TB_Validation_02') IS NOT NULL
            DROP TABLE #TB_Validation_02

        SELECT 
            V.iOrdre_Presentation, V.iID_Validation, V.iCode_Validation, V.cType, V.vcDescription_Parametrable as vcDescription
        INTO
            #TB_Validation_02
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
        PRINT '   ' + Convert(varchar(20), GetDate(), 120) + '   » ' + LTrim(Str(@iCount)) + ' validations à appliquer'


        -- Boucler à travers les validations du sous type de transaction
        DECLARE @iOrdre_Presentation int = 0               
        WHILE Exists(SELECT TOP 1 * FROM #TB_Validation_02 WHERE iOrdre_Presentation > @iOrdre_Presentation) 
        BEGIN
            SET @iCountRejets = 0

            SELECT TOP 1
                @iOrdre_Presentation = iOrdre_Presentation,
                @iID_Validation = iID_Validation, 
                @iCode_Validation = iCode_Validation,
                @vcDescription = vcDescription,
                @cType = cType
            FROM
                #TB_Validation_02 
            WHERE
                iOrdre_Presentation > @iOrdre_Presentation
            ORDER BY 
                iOrdre_Presentation

            PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '   - Validation #' + LTrim(Str(@iCode_Validation)) + ': ' + @vcDescription

            BEGIN TRY
                -- Validation : Le bénéficiaire n'est pas mineur à la fin de l'année fiscale
                IF @iCode_Validation = 1 
                BEGIN
                    ; WITH CTE_Beneficiary as (
                        SELECT
                            B.BeneficiaryID, B.vcNomPrenom, B.dtNaissance
                        FROM
                            #TB_Beneficiary_02 B
                        WHERE
                            dtNaissance <= DateAdd(year, -18, @dtFinCotisation)
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        C.ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        LTrim(Str(dbo.Fn_Mo_Age(dtNaissance, @dtFinCotisation))), NULL, C.ConventionID, B.BeneficiaryID, NULL
                    FROM
                        CTE_Beneficiary B
                        JOIN #TB_Demande_02 C ON C.BeneficiaryID = B.BeneficiaryID
                    WHERE
                        IsRejected = 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le bénéficiaire n'est pas n’était pas résident du Québec à la fin de l'année fiscale
                IF @iCode_Validation = 2
                BEGIN
                    ; WITH CTE_Beneficiary as (
                        SELECT
                            B.BeneficiaryID, B.vcNomPrenom, B.vcProvince
                        FROM
                            #TB_Beneficiary_02 B
                        WHERE
                            (ISNULL(B.vcProvince, '') <> 'QC' AND B.bResidenceFaitQuebec = 0)
                            AND @tiCode_Version <> 2
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        C.ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        vcProvince, NULL, C.ConventionID, B.BeneficiaryID, NULL
                    FROM
                        CTE_Beneficiary B
                        JOIN #TB_Demande_02 C ON C.BeneficiaryID = B.BeneficiaryID
                    WHERE
                        IsRejected = 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : S'il y a déjà une demande en attente de traitement RQ pour l'année fiscale
                IF @iCode_Validation = 3
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            D.iID_Convention, D.cStatut_Reponse, D.tiCode_Version,
                            RowNum = ROW_NUMBER() OVER(PARTITION BY D.iID_Convention, D.siAnnee_Fiscale ORDER BY F.dtDate_Creation DESC)
                        FROM
                            dbo.tblIQEE_Demandes D
                            JOIN @TB_FichierIQEE F ON D.iID_Fichier_IQEE = F.iID_Fichier_IQEE
                        WHERE
                            D.siAnnee_Fiscale = @siAnnee_Fiscale
                            AND NOT D.cStatut_Reponse IN ('E','X')
                    )
                    DELETE FROM D
                    FROM
                        #TB_Demande_02 D
                        JOIN CTE_Convention C ON C.iID_Convention = D.ConventionID
                    WHERE
                        IsRejected = 0
                        AND C.RowNum = 1
                        AND C.cStatut_Reponse IN ('A', 'R')
                        AND C.tiCode_Version <> 1

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Si une erreur a été soulevée par RQ en cours de traitement
                IF @iCode_Validation = 4
                BEGIN
                    ; WITH CTE_Convention as (
                        SELECT
                            D.iID_Convention
                        FROM
                            @TB_FichierIQEE F 
                            JOIN dbo.tblIQEE_Demandes D ON D.iID_Fichier_IQEE = F.iID_Fichier_IQEE
                            JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = D.iID_Demande_IQEE 
                            JOIN dbo.tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                        WHERE
                            D.siAnnee_Fiscale = @siAnnee_Fiscale
                            AND D.tiCode_Version In (0, 2)
                            AND D.cStatut_Reponse = 'E'
                            And E.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
                            AND SE.vcCode_Statut = 'ATR'
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        D.ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, D.ConventionID, NULL, NULL
                    FROM
                        #TB_Demande_02 D
                        JOIN CTE_Convention C ON C.iID_Convention = D.ConventionID
                    WHERE
                        IsRejected = 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le souscripteur a indiqué qu'il ne veut pas de subvention de l'IQÉÉ
                IF @iCode_Validation = 5
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, D.SubscriberID
                        FROM
                            #TB_Demande_02 D
                            LEFT JOIN #TB_PrevDemande_02 PD ON PD.iID_Convention = D.ConventionID
                        WHERE
                            D.IsRejected = 0
                            AND D.Subcriber_WantIQEE = 0
                            AND PD.iID_Demande IS NULL
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        D.ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, D.ConventionID, D.SubscriberID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le montant net des cotisations subventionnables entre la date de début & de fin de cotisation, est inférieur ou égal à 0.
                IF @iCode_Validation = 6
                BEGIN
                    IF @tiCode_Version <> 0 
                        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » Skipped car «Code Version» n''est pas zéro (@tiCode_Version: ' + LTrim(Str(@tiCode_Version)) + ')'
                    ELSE
                    BEGIN
                        SELECT  @vcTMP1 = CONVERT(VARCHAR(10), @dtDebutCotisation, 120),
                                @vcTMP2 = CONVERT(VARCHAR(10), @dtFinCotisation, 120)

                        ; WITH CTE_Demande as (
                            SELECT
                                D.ConventionID, D.SubscriberID
                            FROM
                                #TB_Demande_02 D
                            WHERE
                                D.IsRejected = 0
                                AND D.CotisationSubventionnable <= 0
                            
                        )
                        INSERT INTO #TB_Rejets_02 (
                            iID_Convention, iID_Validation, vcDescription,
                            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                        )
                        SELECT 
                            D.ConventionID, @iID_Validation, REPLACE(REPLACE(@vcDescription, '%dtDebut_Cotisation%', @vcTMP1), '%dtFin_Cotisation%', @vcTMP2),
                            NULL, NULL, D.ConventionID, D.SubscriberID, NULL
                        FROM
                            CTE_Demande D

                        SET @iCountRejets = @@ROWCOUNT
                    END
                END

                -- Validation : Le montant des cotisations provenant d'une «TIN» a tout été retiré dans la même année fiscale.
                IF @iCode_Validation = 7
                BEGIN
                    IF @tiCode_Version <> 0 
                        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » Skipped car «Code Version» n''est pas zéro (@tiCode_Version: ' + LTrim(Str(@tiCode_Version)) + ')'
                    ELSE
                    BEGIN
                        ;WITH CTE_Cotisation AS (
                            SELECT D.ConventionID, D.SubscriberID, O.OperTypeID, Ct.Cotisation
                              FROM dbo.fntOPER_Active(@dtDebutCotisation, @dtFinCotisation) O
                                   JOIN dbo.Un_Cotisation Ct ON Ct.OperID = O.OperID
                                   JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
                                   JOIN #TB_Demande_02 D ON D.ConventionID = U.ConventionID
                             WHERE Ct.Cotisation <> 0
                        ),
                        CTE_TIN AS (
                            SELECT Ct.ConventionID, Ct.SubscriberID, Total_Cotisation = SUM(Ct.Cotisation) 
                              FROM CTE_Cotisation Ct
                             WHERE Ct.OperTypeID = 'TIN'
                             GROUP BY Ct.ConventionID, Ct.SubscriberID
                        ),
                        CTE_RET AS (
                            SELECT Ct.ConventionID, Total_Retrait = SUM(Ct.Cotisation) 
                              FROM CTE_Cotisation Ct
                             WHERE Ct.OperTypeID = 'RET'
                             GROUP BY Ct.ConventionID
                        )
                        INSERT INTO #TB_Rejets_02 (
                            iID_Convention, iID_Validation, vcDescription,
                            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                        )
                        SELECT 
                            T.ConventionID, @iID_Validation, REPLACE(@vcDescription, '%siAnnee_Fiscale%', STR(@siAnnee_Fiscale)),
                            NULL, NULL, T.ConventionID, T.SubscriberID, NULL
                        FROM 
                            CTE_TIN T JOIN CTE_RET R ON R.ConventionID = T.ConventionID
                                      JOIN dbo.Un_Convention C ON C.ConventionID = T.ConventionID
                        WHERE 
                            T.Total_Cotisation + R.Total_Retrait <= 0

                        SET @iCountRejets = @@ROWCOUNT
                    END
                END

                -- Validation : Le NAS du bénéficiaire doit être fourni dans les 2 premières années de la convention
                IF @iCode_Validation = 8
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, D.BeneficiaryID, B.vcNomPrenom, 
                            YEAR(D.dtEntreeEnVigueur) + 2 AS Annee_Limite
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                            JOIN dbo.tblCONV_ChangementsBeneficiaire CB ON CB.iID_Convention = D.ConventionID AND CB.iID_Nouveau_Beneficiaire = D.BeneficiaryID
                            JOIN dbo.tblCONV_RaisonsChangementBeneficiaire RCB ON RCB.tiID_Raison_Changement_Beneficiaire = CB.tiID_Raison_Changement_Beneficiaire
                            LEFT JOIN (    
                                SELECT HumanID, MIN(EffectDate) AS First_EffectDate
                                  FROM dbo.UN_HumanSocialNumber
                                 WHERE EXISTS(SELECT * FROM #TB_Beneficiary_02 WHERE BeneficiaryID = HumanID)
                                 GROUP BY HumanID
                            ) HSN ON HSN.HumanID = CB.iID_Nouveau_Beneficiaire
                        WHERE
                            D.IsRejected = 0
                            AND LEN(IsNull(B.vcNAS, '')) > 0
                            AND RCB.vcCode_Raison = 'INI'
                            AND YEAR(HSN.First_EffectDate) >= 2009
                            AND YEAR(HSN.First_EffectDate) - YEAR(D.dtEntreeEnVigueur) > 2
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(Annee_Limite, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du bénéficiaire au 31 décembre de l'année fiscale est absent
                IF @iCode_Validation = 10
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT DISTINCT
                            D.ConventionID, B.BeneficiaryID
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(B.vcNom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)),
                        NULL, NULL, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom du bénéficiaire au 31 décembre de l'année fiscale est absent
                IF @iCode_Validation = 11
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(B.vcPrenom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)),
                        NULL, NULL, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La date de naissance du bénéficiaire au 31 décembre de l'année fiscale est absente
                IF @iCode_Validation = 12
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND IsNull(B.dtNaissance, '1900-01-01') = Cast('1900-01-01' as date)
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END
                
                -- Validation : Le bénéficiaire n'était pas encore né au 31 décembre de l'année fiscale
                IF @iCode_Validation = 13
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom, B.dtNaissance
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND IsNull(B.dtNaissance, '1900-01-01') > @dtFinCotisation
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        CONVERT(VARCHAR(10), @dtFinCotisation, 120), CONVERT(VARCHAR(10), dtNaissance, 120), D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le sexe du bénéficiaire au 31 décembre de l'année fiscale n’est pas défini
                IF @iCode_Validation = 14
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom, B.dtNaissance
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND IsNull(B.cSexe, '') Not In ('F', 'M')
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le # civique de l’adresse du bénéficiaire au 31 décembre l'année fiscale est absent ou indéterminé
                IF @iCode_Validation = 15
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom, B.iID_Adresse, vcAdresse_Tmp
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(B.vcNoCivique, '')) = 0
                            AND NOT (B.vcNomRue like 'CP [0-9]%' AND NOT B.vcNomRue like 'CP [0-9]% %')
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom), '%vcAdresse%', vcAdresse_Tmp),
                        NULL, vcAdresse_Tmp, D.ConventionID, D.BeneficiaryID, iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La rue de l’adresse du bénéficiaire au 31 décembre l'année fiscale est absente ou indéterminée
                IF @iCode_Validation = 16
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom, B.iID_Adresse, B.vcAdresse_Tmp
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(B.vcNomRue, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom), '%vcAdresse%', vcAdresse_Tmp),
                        NULL, vcAdresse_Tmp, D.ConventionID, D.BeneficiaryID, iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La ville de l’adresse du bénéficiaire au 31 décembre l'année fiscale est absente
                IF @iCode_Validation = 17
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom, B.iID_Adresse
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(B.vcVille, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, D.ConventionID, D.BeneficiaryID, D.iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le numéro d’entreprise du Québec (NEQ) de l’entreprise souscriptrice est absent ou invalide
                IF @iCode_Validation = 19
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcNEQ
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND S.cType_HumanOrCompany = 'C'
                            AND dbo.fnGENE_ValiderNEQ(IsNull(S.vcNEQ, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcNEQ, D.ConventionID, D.SubscriberID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du souscripteur est absent
                IF @iCode_Validation = 21
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcNom
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND S.cType_HumanOrCompany = 'H'
                            AND Len(IsNull(S.vcNom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, D.ConventionID, D.SubscriberID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom du souscripteur est absent
                IF @iCode_Validation = 22
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcPrenom
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND S.cType_HumanOrCompany = 'H'
                            AND Len(IsNull(S.vcPrenom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, D.ConventionID, D.SubscriberID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le numéro civique de l’adresse du souscripteur est absent ou ne peut pas être déterminé
                IF @iCode_Validation = 23
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcNomPrenom, S.iID_Adresse, vcAdresse_Tmp
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(S.vcNoCivique, '')) = 0
                            AND NOT (S.vcNomRue like 'CP [0-9]%' AND NOT S.vcNomRue like 'CP [0-9]% %')

                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcAdresse_Tmp, D.ConventionID, D.SubscriberID, iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La rue de l’adresse du souscripteur est absente ou ne peut pas être déterminée
                IF @iCode_Validation = 24
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcNomPrenom, S.iID_Adresse, S.vcAdresse_Tmp
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(S.vcNomRue, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcAdresse_Tmp, D.ConventionID, D.SubscriberID, iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La ville de l’adresse du souscripteur est absente
                IF @iCode_Validation = 25
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcNomPrenom, S.iID_Adresse
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(S.vcVille, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, D.ConventionID, D.SubscriberID, D.iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le code postal du souscripteur est absente
                IF @iCode_Validation = 26
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcNomPrenom, S.iID_Adresse, S.vcCodePostal
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(S.vcCodePostal, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcCodePostal, D.ConventionID, D.SubscriberID, D.iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le code postal d'un souscripteur canadien est invalide
                IF @iCode_Validation = 27
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcNomPrenom, S.iID_Adresse, S.vcCodePostal
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(S.vcCodePostal, '')) > 0
                            AND S.cID_Pays = 'CAN'
                            AND Not Replace(S.vcCodePostal, ' ', '') Like '[A-Z][0-9][A-Z][0-9][A-Z][0-9]'
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcCodePostal, D.ConventionID, D.SubscriberID, D.iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le pays de l’adresse du souscripteur ne peut être déterminé avec le nom de la province ou la ville
                IF @iCode_Validation = 28
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcNomPrenom, S.iID_Adresse, S.vcProvince, S.vcVille
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(S.cID_Pays, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%vcNom_Province%', vcProvince), '%vcVille%', vcVille),
                        NULL, NULL, D.ConventionID, D.SubscriberID, D.iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le code de province canadienne associé à l’adresse du souscripteur est absent
                IF @iCode_Validation = 29
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcNomPrenom, S.iID_Adresse, S.vcProvince
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND IsNull(S.cID_Pays, '') = 'CAN'
                            AND Len(IsNull(S.vcProvince, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, D.ConventionID, D.SubscriberID, D.iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du co-souscripteur est absent
                IF @iCode_Validation = 31
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.iID_CoSubscriber, S.vcNom
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_CoSubscriber_02 S ON S.iID_CoSubscriber = D.CoSubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND S.cType_HumanOrCompany = 'H'
                            AND Len(IsNull(S.vcNom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, D.ConventionID, D.iID_CoSubscriber, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom du co-souscripteur est absent
                IF @iCode_Validation = 32
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.iID_CoSubscriber, S.vcPrenom
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_CoSubscriber_02 S ON S.iID_CoSubscriber = D.CoSubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND S.cType_HumanOrCompany = 'H'
                            AND Len(IsNull(S.vcPrenom, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, D.ConventionID, D.iID_CoSubscriber, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le type du principal responsable est absent
                IF @iCode_Validation = 33
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND NOT IsNull(B.tiType_Responsable, 0) IN (1, 2)
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS du principal responsable est absent ou invalide
                IF @iCode_Validation = 34
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNAS_Responsable
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND IsNull(B.tiType_Responsable, 0) = 1
                            AND dbo.FN_CRI_CheckSin(B.vcNAS_Responsable, 0) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcNAS_Responsable, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le numéro d’entreprise du Québec (NEQ) de l’entreprise principale responsable est absent ou invalide
                IF @iCode_Validation = 35
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNEQ_Responsable
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND IsNull(B.tiType_Responsable, 0) = 2
                            AND dbo.fnGENE_ValiderNEQ(B.vcNEQ_Responsable) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcNEQ_Responsable, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du principal responsable est absent
                IF @iCode_Validation = 36
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNom_Responsable
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND IsNull(B.tiType_Responsable, 0) <> 0
                            AND Len(IsNull(B.vcNom_Responsable, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom du principal responsable est absent
                IF @iCode_Validation = 37
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcPrenom_Responsable
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND IsNull(B.tiType_Responsable, 0) = 1
                            AND Len(IsNull(B.vcPrenom_Responsable, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : L’absence d’un principal responsable valide dans la convention n’empêche pas une demande à l’IQÉÉ mais pourrait entrainer le non paiement de la majoration
                IF @iCode_Validation = 38
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT DISTINCT
                            D.ConventionID
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Rejets_02 R ON R.iID_Convention = D.ConventionID
                            JOIN dbo.tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
                        WHERE
                            D.IsRejected = 0
                            AND D.Subscriber_LienID <> 1
                            AND V.iCode_Validation IN (34, 35, 36, 37)
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        D.ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, B.iID_Convention, B.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D
                        JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : L’absence d’un principal responsable valide dans la convention n’empêche pas une demande à l’IQÉÉ mais pourrait entrainer le non paiement de la majoration
                IF @iCode_Validation = 39
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT DISTINCT
                            D.ConventionID
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Rejets_02 R ON R.iID_Convention = D.ConventionID
                            JOIN dbo.tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation
                        WHERE
                            D.IsRejected = 0
                            AND D.Subscriber_LienID = 1
                            AND V.iCode_Validation IN (34, 35, 36, 37)
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        D.ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, B.iID_Convention, B.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D
                        JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID

                    SET @iCountRejets = @@ROWCOUNT
                END
                
                -- Validation : Une demande a déjà été envoyée pour l'année fiscale et une réponse reçue de RQ pour la convention
                IF @iCode_Validation = 41
                BEGIN
                    IF Not (@bPremier_Envoi_Originaux = 0)
                        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » Skipped - Ce sont des 1er envois orignaux'
                    ELSE
                    BEGIN
                        ; WITH CTE_Demande as (
                            SELECT DISTINCT
                                D.ConventionID, D.BeneficiaryID
                            FROM
                                #TB_Demande_02 D
                                JOIN #TB_PrevDemande_02 PD ON PD.iID_Convention = D.ConventionID
                            WHERE
                                D.IsRejected = 0
                                AND PD.cStatus = 'R'
                                AND NOT EXISTS(
                                        SELECT TOP 1 * FROM dbo.tblIQEE_Annulations A 
                                         WHERE A.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
                                           AND A.iID_Enregistrement_Demande_Annulation = PD.iID_Demande
                                           AND A.iID_Session = @iID_Session
                                           AND A.dtDate_Creation_Fichiers = @dtCreationFichier
                                    )
                        )
                        INSERT INTO #TB_Rejets_02 (
                            iID_Convention, iID_Validation, vcDescription,
                            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                        )
                        SELECT 
                            D.ConventionID, @iID_Validation, Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)),
                            NULL, NULL, D.ConventionID, NULL, NULL
                        FROM
                            CTE_Demande D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID

                        SET @iCountRejets = @@ROWCOUNT
                    END
                END

                -- Validation : Pas de cotisation dans l'année fiscale (autre que RIN/RIO)
                IF @iCode_Validation = 42 
                BEGIN
                    IF Not (@bPremier_Envoi_Originaux = 0 AND @bConsequence_Annulation = 0 AND @bit_CasSpecial = 0)
                        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » Skipped - Ce sont des 1er envois orignaux ou des conséquence d''annulation ou des cas spéciaux'
                    ELSE
                    BEGIN
                        ; WITH CTE_Demande as (
                            SELECT DISTINCT
                                D.ConventionID
                            FROM
                                #TB_Demande_02 D
                                JOIN dbo.Un_ConventionOper CO ON C.ConventionID = D.ConventionID
                                                             -- à remettre actif lorsqu'on aura plus de IQEE entrant par après
                                                             --AND CO.ConventionOperTypeID IN ('CBQ', 'MMQ')
                                JOIN dbo.Un_Oper O ON O.OperID = CO.OperID AND O.OperTypeID IN ('TRI','RIM','OUT') 
                            WHERE
                                D.IsRejected = 0
                                AND O.OperDate <= @dtFinCotisation
                                AND NOT EXISTS(SELECT * FROM dbo.tblIQEE_Transferts T WHERE T.iID_Convention = C.ConventionID AND T.dtDate_Transfert = O.OperDate AND T.cStatut_Reponse = 'R' )
                                --AND NOT Exists(
                                --        SELECT TOP 1 * FROM #
                                --         WHERE ConventionID = D.ConventionID AND ConventionStateID = 'FRM'
                                --    )
                                --AND EXISTS( --Exclure toute convention fermée qui inclut un statut de groupe d'unité de transfert OUT, TRI, RIM
                                --        SELECT TOP 1 * FROM dbo.Un_Unit U
                                --                            JOIN dbo.Un_UnitUnitState UUS ON UUS.UnitID = U.UnitID
                                --         WHERE U.ConventionID = D.ConventionID AND UUS.UnitStateID IN ('OUT', 'RIM', 'TRI')
                                --    )
                        )
                        INSERT INTO #TB_Rejets_02 (
                            iID_Convention, iID_Validation, vcDescription,
                            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                        )
                        SELECT 
                            D.ConventionID, @iID_Validation, Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)),
                            NULL, NULL, D.ConventionID, NULL, NULL
                        FROM
                            CTE_Demande D
                        WHERE
                            NOT EXISTS (
                                    SELECT TOP 1 * FROM dbo.Un_Unit U 
                                                        -- Il y a des cotisations dans l'année fiscale
                                                        JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
                                                                             AND CT.EffectDate Between @dtDebutCotisation And @dtFinCotisation
                                                        -- Il y a des cotisations applicables aux subventions
                                                        JOIN Un_Oper O ON O.OperID = CT.OperID
                                                        LEFT JOIN @TB_OperCode_BloquantDemande OB ON OB.vcCode = O.OperTypeID
                                                        LEFT JOIN Un_IntReimb IR ON IR.UnitID = U.UnitID
                                     WHERE U.ConventionID = D.ConventionID
                                       AND OB.vcCode IS NULL
                                )

                        SET @iCountRejets = @@ROWCOUNT
                    END                    
                END

                -- Validation : Le prénom du bénéficiaire au 31 décembre contient au moins 1 caractère non conforme
                IF @iCode_Validation = 43
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcPrenom, B.vcNomPrenom
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(B.vcPrenom, '')) > 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom), '%vcCaractereNonConforme%', vcCaractereNonConforme),
                        NULL, vcPrenom, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        (SELECT *, vcCaractereNonConforme = dbo.fnIQEE_ValiderNom(vcPrenom) FROM CTE_Demande) D
                    WHERE
                        Len(IsNull(vcCaractereNonConforme, '')) > 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du bénéficiaire au 31 décembre contient au moins 1 caractère non conforme
                IF @iCode_Validation = 44
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNom, B.vcNomPrenom
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(B.vcNom, '')) > 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom), '%vcCaractereNonConforme%', vcCaractereNonConforme),
                        NULL, vcNom, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        (SELECT *, vcCaractereNonConforme = dbo.fnIQEE_ValiderNom(vcNom) FROM CTE_Demande) D
                    WHERE
                        Len(IsNull(vcCaractereNonConforme, '')) > 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom du souscripteur contient au moins 1 caractère non conforme
                IF @iCode_Validation = 45
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcPrenom, S.vcNomPrenom
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(S.vcPrenom, '')) > 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom), '%vcCaractereNonConforme%', vcCaractereNonConforme),
                        NULL, vcPrenom, D.ConventionID, D.SubscriberID, NULL
                    FROM
                        (SELECT *, vcCaractereNonConforme = dbo.fnIQEE_ValiderNom(vcPrenom) FROM CTE_Demande) D
                    WHERE
                        Len(IsNull(vcCaractereNonConforme, '')) > 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du souscripteur contient au moins 1 caractère non conforme
                IF @iCode_Validation = 46
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcNom, S.vcNomPrenom
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(S.vcNom, '')) > 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom), '%vcCaractereNonConforme%', vcCaractereNonConforme),
                        NULL, vcNom, D.ConventionID, D.SubscriberID, NULL
                    FROM
                        (SELECT *, vcCaractereNonConforme = dbo.fnIQEE_ValiderNom(vcNom) FROM CTE_Demande) D
                    WHERE
                        Len(IsNull(vcCaractereNonConforme, '')) > 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom du co-souscripteur contient au moins 1 caractère non conforme
                IF @iCode_Validation = 47
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.iID_CoSubscriber, S.vcPrenom, S.vcNomPrenom
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_CoSubscriber_02 S ON S.iID_CoSubscriber = D.CoSubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(S.vcPrenom, '')) > 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom), '%vcCaractereNonConforme%', vcCaractereNonConforme),
                        NULL, vcPrenom, D.ConventionID, D.iID_CoSubscriber, NULL
                    FROM
                        (SELECT *, vcCaractereNonConforme = dbo.fnIQEE_ValiderNom(vcPrenom) FROM CTE_Demande) D
                    WHERE
                        Len(IsNull(vcCaractereNonConforme, '')) > 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du co-souscripteur contient au moins 1 caractère non conforme
                IF @iCode_Validation = 48
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.iID_CoSubscriber, S.vcNom, S.vcNomPrenom
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_CoSubscriber_02 S ON S.iID_CoSubscriber = D.CoSubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(S.vcNom, '')) > 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom), '%vcCaractereNonConforme%', vcCaractereNonConforme),
                        NULL, vcNom, D.ConventionID, D.iID_CoSubscriber, NULL
                    FROM
                        (SELECT *, vcCaractereNonConforme = dbo.fnIQEE_ValiderNom(vcNom) FROM CTE_Demande) D
                    WHERE
                        Len(IsNull(vcCaractereNonConforme, '')) > 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nom du principal responsable contient au moins 1 caractère non conforme
                IF @iCode_Validation = 49
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNom_Responsable, B.vcNomPrenom_Responsable
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(B.vcNom_Responsable, '')) > 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom_Responsable), '%vcCaractereNonConforme%', vcCaractereNonConforme),
                        NULL, vcNom_Responsable, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        (SELECT *, vcCaractereNonConforme = dbo.fnIQEE_ValiderNom(vcNom_Responsable) FROM CTE_Demande) D
                    WHERE
                        Len(IsNull(vcCaractereNonConforme, '')) > 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le prénom du principal responsable contient au moins 1 caractère non conforme
                IF @iCode_Validation = 50
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcPrenom_Responsable, B.vcNomPrenom_Responsable
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND IsNull(B.tiType_Responsable, 0) = 1
                            AND Len(IsNull(B.vcPrenom_Responsable, '')) > 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom_Responsable), '%vcCaractereNonConforme%', vcCaractereNonConforme),
                        NULL, vcPrenom_Responsable, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        (SELECT *, vcCaractereNonConforme = dbo.fnIQEE_ValiderNom(vcPrenom_Responsable) FROM CTE_Demande) D
                    WHERE
                        Len(IsNull(vcCaractereNonConforme, '')) > 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La convention a le statut de proposition
                IF @iCode_Validation = 53
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID
                        FROM
                            #TB_Demande_02 D
                            JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(DATEADD(MONTH, 1, @dtFinCotisation), DEFAULT) S ON S.ConventionID = D.ConventionID
                        WHERE
                            D.IsRejected = 0
                            AND D.ConventionStateID = 'PRP'
                            AND S.ConventionStateID <> 'REE'
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, D.ConventionID, NULL, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La convention a été fermée par une transaction d'impôt spécial 91 ou 51
                IF @iCode_Validation = 58
                BEGIN
                    WITH CTE_Demande as (
                        SELECT DISTINCT
                            D.ConventionID
                        FROM
                            #TB_Demande_02 D
                            JOIN dbo.fntIQEE_ConventionDeclareeFermee(@iID_Fichier_IQEE) I ON I.iID_Convention = D.ConventionID
                        WHERE
                            D.IsRejected = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, D.ConventionID, NULL, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La convention fait l'objet d'un retrait prématuré de cotisations par une transaction d'impôt spécial 22
                IF @iCode_Validation = 59
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT DISTINCT
                            D.ConventionID
                        FROM
                            #TB_Demande_02 D
                        WHERE
                            D.IsRejected = 0
                            AND D.CotisationSubventionnable > 0
                            AND Exists (
                                SELECT * FROM dbo.tblIQEE_ImpotsSpeciaux I
                                              JOIN dbo.vwIQEE_Enregistrement_TypeEtSousType T ON T.iID_Sous_Type = I.iID_Sous_Type
                                              JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
                                 WHERE I.iID_Convention = D.ConventionID
                                   AND I.siAnnee_Fiscale = @siAnnee_Fiscale
                                   AND I.tiCode_Version IN (0, 1)
                                   AND I.cStatut_Reponse IN ('A', 'R')
                                   AND T.cCode_Sous_Type = '22'
                                   AND Not Exists (
                                            SELECT * FROM dbo.tblIQEE_Annulations A
                                             WHERE A.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
                                               AND A.iID_Enregistrement_Demande_Annulation = I.iID_Impot_Special
                                               AND A.iID_Session = @iID_Session
                                               AND A.dtDate_Creation_Fichiers = @dtCreationFichier
                                       )
                            )
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, D.ConventionID, NULL, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS du bénéficiaire au 31 décembre est absent
                IF @iCode_Validation = 61
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(B.vcNAS, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS du bénéficiaire au 31 décembre est invalide
                IF @iCode_Validation = 62
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom, B.vcNAS
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(B.vcNAS, '')) > 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, vcNAS, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D
                    WHERE
                        dbo.FN_CRI_CheckSin(vcNAS, 0) = 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS du souscripteur est absent
                IF @iCode_Validation = 63
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcNAS
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND S.cType_HumanOrCompany = 'H'
                            AND Len(IsNull(S.vcNAS, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcNAS, D.ConventionID, D.SubscriberID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS du souscripteur est invalide
                IF @iCode_Validation = 64
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcNAS
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND S.cType_HumanOrCompany = 'H'
                            AND Len(IsNull(S.vcNAS, '')) > 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcNAS, D.ConventionID, D.SubscriberID, NULL
                    FROM
                        CTE_Demande D
                    WHERE
                        dbo.FN_CRI_CheckSin(IsNull(vcNAS, ''), 0) = 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le code postal du bénéficiaire au 31 décembre l'année fiscale est absente
                IF @iCode_Validation = 65
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom, B.iID_Adresse, B.vcCodePostal
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(B.vcCodePostal, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, D.ConventionID, D.BeneficiaryID, D.iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le code postal du bénéficiaire au 31 décembre l'année fiscale est invalide
                IF @iCode_Validation = 66
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom, B.iID_Adresse, B.vcCodePostal, B.cID_Pays
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(B.vcCodePostal, '')) > 0
                            AND B.cID_Pays = 'CAN'
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, vcCodePostal, D.ConventionID, D.BeneficiaryID, D.iID_Adresse
                    FROM
                        CTE_Demande D
                    WHERE
                        dbo.fnGENE_ValiderCodePostal(vcCodePostal, cID_Pays) = 0
                        --Not Replace(B.vcCodePostal, ' ', '') Like '[A-Z][0-9][A-Z][0-9][A-Z][0-9]'

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le pays de l’adresse du bénéficiaire ne peut être déterminé avec le nom de la province ou la ville
                IF @iCode_Validation = 67
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom, B.iID_Adresse, B.vcProvince, B.vcVille
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(B.cID_Pays, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(
                                                            Replace(Replace(@vcDescription, '%vcNom_Province%', vcProvince), '%vcVille%', vcVille),
                                                            '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, D.ConventionID, D.BeneficiaryID, D.iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le code de province canadienne associé à l’adresse du bénéficiaire au 31 décembre ne peux pas être déterminé
                IF @iCode_Validation = 68 --(identique à #51)
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom, B.iID_Adresse
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND B.cID_Pays = 'CAN'
                            AND Len(IsNull(B.vcProvince, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, D.ConventionID, D.BeneficiaryID, D.iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS du co-souscripteur est absent
                IF @iCode_Validation = 69
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.iID_CoSubscriber, S.vcNAS
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_CoSubscriber_02 S ON S.iID_CoSubscriber = D.CoSubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND S.cType_HumanOrCompany = 'H'
                            AND Len(IsNull(S.vcNAS, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcNAS, D.ConventionID, D.iID_CoSubscriber, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS du co-souscripteur est invalide
                IF @iCode_Validation = 70
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.iID_CoSubscriber, S.vcNAS
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_CoSubscriber_02 S ON S.iID_CoSubscriber = D.CoSubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND S.cType_HumanOrCompany = 'H'
                            AND Len(IsNull(S.vcNAS, '')) > 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcNAS, D.ConventionID, D.iID_CoSubscriber, NULL
                    FROM
                        CTE_Demande D
                    WHERE
                        dbo.FN_CRI_CheckSin(IsNull(vcNAS, ''), 0) = 0

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : L'année de la date de début de contrat est supérieure à l'année fiscale de la demande d'IQÉÉ
                IF @iCode_Validation = 71
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, D.DateEnregistrementRQ
                        FROM
                            #TB_Demande_02 D
                        WHERE
                            D.IsRejected = 0
                            AND Year(D.DateEnregistrementRQ) > @siAnnee_Fiscale
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        Str(@siAnnee_Fiscale, 4), Convert(varchar(10), DateEnregistrementRQ, 120), D.ConventionID, NULL, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le code de province canadienne associé à l'adresse du bénéficiaire au 31 décembre est invalide
                IF @iCode_Validation = 73
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom, B.iID_Adresse, B.vcProvince
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                            LEFT JOIN dbo.Mo_State P ON P.CountryID = B.cID_Pays And P.StateCode = B.vcProvince
                        WHERE
                            D.IsRejected = 0
                            AND B.cID_Pays = 'CAN'
                            AND P.StateID IS NULL
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, vcProvince, D.ConventionID, D.BeneficiaryID, D.iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le code de province canadienne associé à l'adresse du souscripteur est invalide
                IF @iCode_Validation = 74
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcNomPrenom, S.iID_Adresse, S.vcProvince
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                            LEFT JOIN dbo.Mo_State P ON P.CountryID = S.cID_Pays And P.StateCode = S.vcProvince
                        WHERE
                            D.IsRejected = 0
                            AND S.cID_Pays = 'CAN'
                            AND P.StateID IS NULL
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, vcProvince, D.ConventionID, D.SubscriberID, D.iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END
                
                -- Validation : Une annulation de la demande a déjà été envoyée pour l'année fiscale et est en attente d’une réponse de RQ
                IF @iCode_Validation = 75
                BEGIN
                    IF Not (@bPremier_Envoi_Originaux = 0)
                        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » Skipped - Ce sont des 1er envois orignaux'
                    ELSE
                    BEGIN
                        ; WITH CTE_Demande as (
                            SELECT DISTINCT
                                D.ConventionID, D.BeneficiaryID
                            FROM
                                #TB_Demande_02 D
                                JOIN #TB_PrevDemande_02 PD ON PD.iID_Convention = D.ConventionID
                            WHERE
                                D.IsRejected = 0
                                AND PD.cStatus = 'D'
                                AND NOT EXISTS(
                                        SELECT TOP 1 * FROM dbo.tblIQEE_Demandes D1
                                                            JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = D1.iID_Fichier_IQEE
                                         WHERE D1.siAnnee_Fiscale = @siAnnee_Fiscale
                                           AND D1.tiCode_Version IN (1, 2)
                                           AND D1.cStatut_Reponse = 'A'
                                           AND D1.iID_Convention = D.ConventionID
                                    )
                                AND NOT EXISTS(
                                        SELECT TOP 1 * FROM dbo.tblIQEE_Annulations A 
                                         WHERE A.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
                                           AND A.iID_Enregistrement_Demande_Annulation = PD.iID_Demande
                                           AND A.iID_Session = @iID_Session
                                           AND A.dtDate_Creation_Fichiers = @dtCreationFichier
                                    )
                        )
                        INSERT INTO #TB_Rejets_02 (
                            iID_Convention, iID_Validation, vcDescription,
                            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                        )
                        SELECT 
                            D.ConventionID, @iID_Validation, Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)),
                            NULL, NULL, D.ConventionID, NULL, NULL
                        FROM
                            CTE_Demande D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID

                        SET @iCountRejets = @@ROWCOUNT
                    END
                END
                
                -- Validation : Le statut actuel de la convention est "Fermé" et elle ne possède pas d'unité ayant un statut de groupe OUT, RIM ou TRI
                IF @iCode_Validation = 91
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT DISTINCT
                            D.ConventionID, D.ConventionNo
                        FROM
                            #TB_Demande_02 D
                            JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtCreationFichier, DEFAULT) S ON S.ConventionID = D.ConventionID
                        WHERE
                            D.IsRejected = 0
                            AND ISNULL(D.ConventionStateID, 'PTR') <> 'FRM'
                            AND ISNULL(S.ConventionStateID, 'PTR') = 'FRM'
                    ),
                    CTE_Oper AS (
                        SELECT DISTINCT
                            C.ConventionID
                        FROM 
                            CTE_Demande C
                            JOIN Un_Unit U ON U.ConventionID = C.ConventionID
                            JOIN dbo.Un_Cotisation Ct ON Ct.UnitID = U.UnitID
                            JOIN dbo.Un_Oper O ON O.OperID = Ct.OperID
                        WHERE 
                            O.OperDate <= @dtFinCotisation
                            AND O.OperTypeID IN ('OUT', 'RIM', 'TRI')
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT DISTINCT
                        D.ConventionID, @iID_Validation, Replace(@vcDescription, '%iID_Convention%', ConventionNo),
                        NULL, NULL, D.ConventionID, NULL, NULL
                    FROM
                        CTE_Demande D
                        JOIN CTE_Oper O ON O.ConventionID = D.ConventionID

                    SET @iCountRejets = @@ROWCOUNT
                END
                
                -- Validation : Erreur Revenu Québec 1510: Transaction soumise après le délai prescrit sur convention
                IF @iCode_Validation = 92
                BEGIN
                    IF NOT (@bPremier_Envoi_Originaux = 0 AND @tiCode_Version = 0 AND @bit_CasSpecial = 0)
                        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » Skipped - Ce sont des 1er envois orignaux ou des conséquence d''annulation ou des cas spéciaux'
                    ELSE
                    BEGIN
                        ; WITH CTE_Demande as (
                            SELECT DISTINCT
                                D.ConventionID, D.ConventionNo
                            FROM
                                #TB_Demande_02 D
                                JOIN dbo.tblIQEE_Demandes D1 ON D1.iID_Convention = D.ConventionID
                                JOIN @TB_FichierIQEE F ON F.iID_Fichier_IQEE = D1.iID_Fichier_IQEE
                                JOIN dbo.tblIQEE_Erreurs E ON E.iID_Enregistrement = D1.iID_Demande_IQEE
                            WHERE
                                D.IsRejected = 0
                                AND D1.siAnnee_Fiscale = @siAnnee_Fiscale
                                AND E.tiID_Type_Enregistrement = @tiID_TypeEnregistrement
                                AND E.siCode_Erreur = 1510
                        )
                        INSERT INTO #TB_Rejets_02 (
                            iID_Convention, iID_Validation, vcDescription,
                            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                        )
                        SELECT 
                            D.ConventionID, @iID_Validation, Replace(@vcDescription, '%iID_Convention%', ConventionNo),
                            NULL, NULL, D.ConventionID, NULL, NULL
                        FROM
                            CTE_Demande D

                        SET @iCountRejets = @@ROWCOUNT
                    END
                END
                
                -- Validation : Au cours de l'année civile, le bénéficiaire a reçu au moins une fois le message suivant du PCEE : Raison de refus # 7 : Ne satisfait pas à la règle des 16 et 17 ans
                IF @iCode_Validation = 93
                BEGIN
                    IF NOT (@tiCode_Version = 0 )
                        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » Skipped - Ce sont des annulations ou des reprises'
                    ELSE
                    BEGIN
                        ; WITH CTE_CESP_400_2 AS (
                            SELECT DISTINCT 
                                X.ConventionID, X.BeneficiaryID
                            FROM
                                #TB_Demande_02 X
                                JOIN Un_CESP400 c4 ON C4.ConventionID = X.ConventionID
                                join Un_CESPSendFile CF ON c4.iCESPSendFileID = CF.iCESPSendFileID
                                join Un_CESP900 c9 ON c4.iCESP400ID = c9.iCESP400ID  -- and c9.cCESP900CESGReasonID = '7'  AND c9_After.iCESP900ID IS null 
                                -- recherche d'une 400 suivante pour la même cotisation qui reçoit une autre réponse que 7 
                                -- dans la même période (voir si on doit vérifer dans un période subséquente ??? )
                                LEFT join Un_CESP400 c4_after ON c4.CotisationID = c4_after.CotisationID AND c4_after.iCESP400ID > c4.iCESP400ID 
                                                            AND c4_after.dtTransaction BETWEEN X.BeneficiarySince AND @dtFinCotisation 
                                LEFT join Un_CESPSendFile CF_after ON c4_after.iCESPSendFileID = CF_after.iCESPSendFileID and CF_after.dtCESPSendFile > CF.dtCESPSendFile
                                left JOIN Un_CESP900 c9_After ON c4_after.iCESP400ID = c9_After.iCESP400ID and c9_After.cCESP900CESGReasonID <> '7'
                            where 
                                X.IsRejected = 0
                                AND c4.dtTransaction BETWEEN X.BeneficiarySince AND @dtFinCotisation -- mettre la plage de date voulue
                                and c9.cCESP900CESGReasonID = '7' -- Ne satisfait pas la règle des 16 et 17 ans
                                AND c9_After.iCESP900ID IS null -- n'a pas reçu une autre réponse que 7 par la suite. donc la dernière réponse est 7
                        )
                        INSERT INTO #TB_Rejets_02 (
                            iID_Convention, iID_Validation, vcDescription,
                            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                        )
                        SELECT 
                            C.ConventionID, @iID_Validation, Replace(@vcDescription, '%siAnnee_Fiscale%', @siAnnee_Fiscale),
                            NULL, NULL, C.ConventionID, C.BeneficiaryID, NULL
                        FROM
                            CTE_CESP_400_2 C
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = C.BeneficiaryID

                        SET @iCountRejets = @@ROWCOUNT
                    END
                END
                
                -- Validation : La convention a des cas spéciaux non résolus avec Revenu Québec en cours
                IF @iCode_Validation = 94
                BEGIN
                    IF NOT (@bit_CasSpecial = 0 )
                        PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '     » Skipped - Ce sont des cas spéciaux'
                    ELSE
                    BEGIN
                        ; WITH CTE_Demande as (
                            SELECT DISTINCT
                                D.ConventionID, D.ConventionNo
                            FROM
                                #TB_Demande_02 D
                                JOIN dbo.tblIQEE_CasSpeciaux CS ON CS.iID_Convention = D.ConventionID
                            WHERE
                                D.IsRejected = 0
                                AND CS.bCasRegle = 0
                        )
                        INSERT INTO #TB_Rejets_02 (
                            iID_Convention, iID_Validation, vcDescription,
                            vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                        )
                        SELECT 
                            ConventionID, @iID_Validation, Replace(@vcDescription, '%vcNo_Convention%', ConventionNo),
                            NULL, NULL, ConventionID, NULL, NULL
                        FROM
                            CTE_Demande D

                        SET @iCountRejets = @@ROWCOUNT
                    END
                END
                
                --;
                BEGIN   -- Inactif
                ;
                -- Validation : Le NAS du bénéficiaire au 31 décembre de l'année fiscale est absent ou invalide.
                IF @iCode_Validation = 9
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom, B.vcNAS
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND dbo.FN_CRI_CheckSin(B.vcNAS, 0) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, vcNAS, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le code postal du bénéficiaire au 31 décembre l'année fiscale est absente ou invalide
                IF @iCode_Validation = 18
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom, B.iID_Adresse, B.vcCodePostal
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND Len(IsNull(B.vcCodePostal, '')) = 0
                            OR (
                                B.cID_Pays = 'CAN'
                                AND Not Replace(B.vcCodePostal, ' ', '') Like '[A-Z][0-9][A-Z][0-9][A-Z][0-9]'
                            )
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, vcCodePostal, D.ConventionID, D.BeneficiaryID, D.iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS du souscripteur est absent ou invalide
                IF @iCode_Validation = 20
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.SubscriberID, S.vcNAS
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 S ON S.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND S.cType_HumanOrCompany = 'H'
                            AND dbo.FN_CRI_CheckSin(IsNull(S.vcNAS, ''), 0) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcNAS, D.ConventionID, D.SubscriberID, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le NAS du co-souscripteur est absent ou invalide
                IF @iCode_Validation = 30
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, S.iID_CoSubscriber, S.vcNAS
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_CoSubscriber_02 S ON S.iID_CoSubscriber = D.CoSubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND S.cType_HumanOrCompany = 'H'
                            AND dbo.FN_CRI_CheckSin(IsNull(S.vcNAS, ''), 0) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, vcNAS, D.ConventionID, D.iID_CoSubscriber, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le code de province canadienne associé à l’adresse du bénéficiaire au 31 décembre ne peux pas être déterminé
                IF @iCode_Validation = 51
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom, B.iID_Adresse
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND B.cID_Pays = 'CAN'
                            AND Len(IsNull(B.vcProvince, '')) = 0
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, D.ConventionID, D.BeneficiaryID, D.iID_Adresse
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le nombre d'année de résidence au Québec, du bénéficiaire au 31 décembre, doit être plus grand que 0
                IF @iCode_Validation = 52
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, B.BeneficiaryID, B.vcNomPrenom,
                            dtDebut_QC = (SELECT Min(dtDate_Debut) FROM dbo.tblGENE_AdresseHistorique WHERE Year(dtDate_Debut) >= 2007 And dtDate_Debut <= B.dtDate_Debut)
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND B.vcProvince = 'QC'
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, Replace(Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)), '%vcBeneficiaire%', vcNomPrenom),
                        NULL, NULL, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        CTE_Demande D
                    WHERE
                        dtDebut_QC < DateAdd(year, -1, @dtFinCotisation)

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Il y a des transactions subséquentes qui ne sont pas en demande d'annulation/reprise
                IF @iCode_Validation = 54
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID
                        FROM
                            #TB_Demande_02 D
                        WHERE
                            D.IsRejected = 0
                            AND D.ConventionStateID = 'PRP'
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, NULL, D.ConventionID, NULL, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Les transactions de la convention sont retenues parce qu'elle a fait l'objet de transactions manuelles de l'IQÉÉ avant que les transactions soient implantées dans UniAccès
                -- TODO
                IF @iCode_Validation = 55
                BEGIN
                    --; WITH CTE_Demande as (
                    --    SELECT
                    --        D.ConventionID
                    --    FROM
                    --        #TB_Demande_02 D
                    --    WHERE
                    --        D.IsRejected = 0
                    --        AND D.ConventionStateID = 'PRP'
                    --)
                    --INSERT INTO #TB_Rejets_02 (
                    --    iID_Convention, iID_Validation, vcDescription,
                    --    vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    --)
                    --SELECT 
                    --    ConventionID, @iID_Validation, @vcDescription,
                    --    NULL, NULL, D.ConventionID, NULL, NULL
                    --FROM
                    --    CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Au moins 1 transaction de l'année fiscale n'a pas été présentée pour la demande de l'IQÉÉ parce qu'elle a déjà fait l'objet d'une demande précédente
                -- TODO
                IF @iCode_Validation = 60
                BEGIN
                    --; WITH CTE_Demande as (
                    --    SELECT
                    --        D.ConventionID
                    --    FROM
                    --        #TB_Demande_02 D
                    --    WHERE
                    --        D.IsRejected = 0
                    --        AND D.ConventionStateID = 'PRP'
                    --)
                    --INSERT INTO #TB_Rejets_02 (
                    --    iID_Convention, iID_Validation, vcDescription,
                    --    vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    --)
                    --SELECT 
                    --    ConventionID, @iID_Validation, @vcDescription,
                    --    NULL, NULL, D.ConventionID, NULL, NULL
                    --FROM
                    --    CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : La date de début de contrat est invalide
                IF @iCode_Validation = 72
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT
                            D.ConventionID, D.DateEnregistrementRQ
                        FROM
                            #TB_Demande_02 D
                        WHERE
                            D.IsRejected = 0
                            AND Year(D.DateEnregistrementRQ) < 1960
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NULL, Convert(varchar(10), DateEnregistrementRQ, 120), D.ConventionID, NULL, NULL
                    FROM
                        CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END
                
                -- Validation : Le total des cotisations versées est plus petit que le montant des cotisations annuelles versées
                IF @iCode_Validation = 76
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT DISTINCT
                            D.ConventionID, D.BeneficiaryID, D.CotisationTotal, D.CotisationSubventionnable
                        FROM
                            #TB_Demande_02 D
                        WHERE
                            D.IsRejected = 0
                            AND D.CotisationTotal < D.CotisationSubventionnable
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        D.ConventionID, @iID_Validation, Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)),
                        dbo.fn_Mo_MoneyToStr(CotisationTotal, @cID_Langue, 1), dbo.fn_Mo_MoneyToStr(CotisationSubventionnable, @cID_Langue, 1), B.iID_Convention, NULL, NULL
                    FROM
                        CTE_Demande D
                        JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID

                    SET @iCountRejets = @@ROWCOUNT
                END
                
                -- Validation : Le total des cotisations versées est plus petit que le montant des cotisations annuelles versées
                IF @iCode_Validation = 77
                BEGIN
                    ; WITH CTE_Demande as (
                        SELECT DISTINCT
                            D.ConventionID, D.BeneficiaryID, D.CotisationTotal, D1.mTotal_Cotisations as CotisationTotal_Prev
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_PrevDemande_02 PD ON PD.iID_Convention = D.ConventionID
                            JOIN dbo.tblIQEE_Demandes D1 ON D1.iID_Demande_IQEE = PD.iID_Demande
                        WHERE
                            D.IsRejected = 0
                            AND D.CotisationTotal < D1.mTotal_Cotisations
                    )
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        D.ConventionID, @iID_Validation, Replace(@vcDescription, '%siAnnee_Fiscale%', Str(@siAnnee_Fiscale, 4)),
                        dbo.fn_Mo_MoneyToStr(CotisationTotal, @cID_Langue, 1), dbo.fn_Mo_MoneyToStr(CotisationTotal_Prev, @cID_Langue, 1), B.iID_Convention, NULL, NULL
                    FROM
                        CTE_Demande D
                        JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Le total des cotisations versées de l'année en cours est différent du total des cotisations versées de l'année précédente plus les cotisations annuelles
                -- TODO
                IF @iCode_Validation = 78
                BEGIN
                    --; WITH CTE_Demande as (
                    --    SELECT
                    --        D.ConventionID
                    --    FROM
                    --        #TB_Demande_02 D
                    --    WHERE
                    --        D.IsRejected = 0
                    --        AND D.ConventionStateID = 'PRP'
                    --)
                    --INSERT INTO #TB_Rejets_02 (
                    --    iID_Convention, iID_Validation, vcDescription,
                    --    vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    --)
                    --SELECT 
                    --    ConventionID, @iID_Validation, @vcDescription,
                    --    NULL, NULL, D.ConventionID, NULL, NULL
                    --FROM
                    --    CTE_Demande D

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Un ou des caractères ont été remplacés ou supprimés dans le prénom du bénéficiaire
                -- TODO
                IF @iCode_Validation = 79
                BEGIN
                    TRUNCATE TABLE #TB_CaracteresAccents_02

                    ; WITH CTE_Demande as (
                        SELECT
                            H.BeneficiaryID as HumanID, H.vcNom as OldValue
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 H ON H.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND PatIndex(@vcCaracteresAccents, H.vcPrenom) <> 0 
                    )
                    INSERT INTO #TB_CaracteresAccents_02
                        (HumanID, OldValue, NewValue)
                    SELECT
                        HumanID, OldValue, dbo.fn_Mo_FormatStringWithoutAccent(OldValue)
                    FROM
                        CTE_Demande

                    UPDATE TB SET
                        vcPrenom = NewValue
                    FROM
                        #TB_Beneficiary_02 TB
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = TB.BeneficiaryID
                        
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NewValue, OldValue, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        #TB_Demande_02 D
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = D.BeneficiaryID

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Un ou des caractères ont été remplacés ou supprimés dans le nom du bénéficiaire
                -- TODO
                IF @iCode_Validation = 80
                BEGIN
                    TRUNCATE TABLE #TB_CaracteresAccents_02

                    ; WITH CTE_Demande as (
                        SELECT
                            H.BeneficiaryID as HumanID, H.vcNom as OldValue
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 H ON H.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND PatIndex(@vcCaracteresAccents, H.vcNom) <> 0 
                    )
                    INSERT INTO #TB_CaracteresAccents_02
                        (HumanID, OldValue, NewValue)
                    SELECT
                        HumanID, OldValue, dbo.fn_Mo_FormatStringWithoutAccent(OldValue)
                    FROM
                        CTE_Demande

                    UPDATE TB SET
                        vcNom = NewValue
                    FROM
                        #TB_Beneficiary_02 TB
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = TB.BeneficiaryID
                        
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NewValue, OldValue, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        #TB_Demande_02 D
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = D.BeneficiaryID

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Un ou des caractères ont été remplacés ou supprimés dans le prénom du souscripteur
                -- TODO
                IF @iCode_Validation = 81
                BEGIN
                    TRUNCATE TABLE #TB_CaracteresAccents_02

                    ; WITH CTE_Demande as (
                        SELECT
                            H.SubscriberID as HumanID, H.vcPrenom as OldValue
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 H ON H.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND PatIndex(@vcCaracteresAccents, H.vcPrenom) <> 0 
                    )
                    INSERT INTO #TB_CaracteresAccents_02
                        (HumanID, OldValue, NewValue)
                    SELECT
                        HumanID, OldValue, dbo.fn_Mo_FormatStringWithoutAccent(OldValue)
                    FROM
                        CTE_Demande

                    UPDATE TB SET
                        vcPrenom = NewValue
                    FROM
                        #TB_Subscriber_02 TB
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = TB.SubscriberID
                        
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NewValue, OldValue, D.ConventionID, D.SubscriberID, NULL
                    FROM
                        #TB_Demande_02 D
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = D.SubscriberID

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Un ou des caractères ont été remplacés ou supprimés dans le nom du souscripteur
                -- TODO
                IF @iCode_Validation = 82
                BEGIN
                    TRUNCATE TABLE #TB_CaracteresAccents_02

                    ; WITH CTE_Demande as (
                        SELECT
                            H.SubscriberID as HumanID, H.vcNom as OldValue
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Subscriber_02 H ON H.SubscriberID = D.SubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND PatIndex(@vcCaracteresAccents, H.vcNom) <> 0 
                    )
                    INSERT INTO #TB_CaracteresAccents_02
                        (HumanID, OldValue, NewValue)
                    SELECT
                        HumanID, OldValue, dbo.fn_Mo_FormatStringWithoutAccent(OldValue)
                    FROM
                        CTE_Demande

                    UPDATE TB SET
                        vcNom = NewValue
                    FROM
                        #TB_Subscriber_02 TB
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = TB.SubscriberID
                        
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NewValue, OldValue, D.ConventionID, D.SubscriberID, NULL
                    FROM
                        #TB_Demande_02 D
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = D.SubscriberID
                        
                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Un ou des caractères ont été remplacés ou supprimés dans le prénom du co-souscripteur
                -- TODO
                IF @iCode_Validation = 83
                BEGIN
                    TRUNCATE TABLE #TB_CaracteresAccents_02

                    ; WITH CTE_Demande as (
                        SELECT
                            H.iID_CoSubscriber as HumanID, H.vcPrenom as OldValue
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_CoSubscriber_02 H ON H.iID_CoSubscriber = D.CoSubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND PatIndex(@vcCaracteresAccents, H.vcPrenom) <> 0 
                    )
                    INSERT INTO #TB_CaracteresAccents_02
                        (HumanID, OldValue, NewValue)
                    SELECT
                        HumanID, OldValue, dbo.fn_Mo_FormatStringWithoutAccent(OldValue)
                    FROM
                        CTE_Demande

                    UPDATE TB SET
                        vcPrenom = NewValue
                    FROM
                        #TB_CoSubscriber_02 TB
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = TB.iID_CoSubscriber
                        
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NewValue, OldValue, D.ConventionID, D.SubscriberID, NULL
                    FROM
                        #TB_Demande_02 D
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = D.CoSubscriberID

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Un ou des caractères ont été remplacés ou supprimés dans le nom du co-souscripteur
                -- TODO
                IF @iCode_Validation = 84
                BEGIN
                    TRUNCATE TABLE #TB_CaracteresAccents_02

                    ; WITH CTE_Demande as (
                        SELECT
                            H.iID_CoSubscriber as HumanID, H.vcNom as OldValue
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_CoSubscriber_02 H ON H.iID_CoSubscriber = D.CoSubscriberID
                        WHERE
                            D.IsRejected = 0
                            AND PatIndex(@vcCaracteresAccents, H.vcNom) <> 0 
                    )
                    INSERT INTO #TB_CaracteresAccents_02
                        (HumanID, OldValue, NewValue)
                    SELECT
                        HumanID, OldValue, dbo.fn_Mo_FormatStringWithoutAccent(OldValue)
                    FROM
                        CTE_Demande

                    UPDATE TB SET
                        vcNom = NewValue
                    FROM
                        #TB_CoSubscriber_02 TB
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = TB.iID_CoSubscriber
                        
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NewValue, OldValue, D.ConventionID, D.SubscriberID, NULL
                    FROM
                        #TB_Demande_02 D
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = D.CoSubscriberID

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Un ou des caractères ont été remplacés ou supprimés dans le prénom du principal responsable
                -- TODO
                IF @iCode_Validation = 85
                BEGIN
                    TRUNCATE TABLE #TB_CaracteresAccents_02

                    ; WITH CTE_Demande as (
                        SELECT
                            H.BeneficiaryID as HumanID, H.vcNom_Responsable as OldValue
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 H ON H.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND PatIndex(@vcCaracteresAccents, H.vcNom_Responsable) <> 0 
                    )
                    INSERT INTO #TB_CaracteresAccents_02
                        (HumanID, OldValue, NewValue)
                    SELECT
                        HumanID, OldValue, dbo.fn_Mo_FormatStringWithoutAccent(OldValue)
                    FROM
                        CTE_Demande

                    UPDATE TB SET
                        vcNom_Responsable = NewValue
                    FROM
                        #TB_Beneficiary_02 TB
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = TB.BeneficiaryID
                        
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NewValue, OldValue, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        #TB_Demande_02 D
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = D.BeneficiaryID

                    SET @iCountRejets = @@ROWCOUNT
                END

                -- Validation : Un ou des caractères ont été remplacés ou supprimés dans le nom du principal responsable
                -- TODO
                IF @iCode_Validation = 86
                BEGIN
                    TRUNCATE TABLE #TB_CaracteresAccents_02

                    ; WITH CTE_Demande as (
                        SELECT
                            H.BeneficiaryID as HumanID, H.vcPrenom_Responsable as OldValue
                        FROM
                            #TB_Demande_02 D
                            JOIN #TB_Beneficiary_02 H ON H.BeneficiaryID = D.BeneficiaryID
                        WHERE
                            D.IsRejected = 0
                            AND PatIndex(@vcCaracteresAccents, H.vcNom_Responsable) <> 0 
                    )
                    INSERT INTO #TB_CaracteresAccents_02
                        (HumanID, OldValue, NewValue)
                    SELECT
                        HumanID, OldValue, dbo.fn_Mo_FormatStringWithoutAccent(OldValue)
                    FROM
                        CTE_Demande

                    UPDATE TB SET
                        vcPrenom_Responsable = NewValue
                    FROM
                        #TB_Beneficiary_02 TB
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = TB.BeneficiaryID
                        
                    INSERT INTO #TB_Rejets_02 (
                        iID_Convention, iID_Validation, vcDescription,
                        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
                    )
                    SELECT 
                        ConventionID, @iID_Validation, @vcDescription,
                        NewValue, OldValue, D.ConventionID, D.BeneficiaryID, NULL
                    FROM
                        #TB_Demande_02 D
                        JOIN #TB_CaracteresAccents_02 X ON X.HumanID = D.BeneficiaryID

                    SET @iCountRejets = @@ROWCOUNT
                END

                END

                --;
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
                    iCode_Validation = 40

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
                    UPDATE #TB_Demande_02 SET IsRejected = 1
                    --DELETE FROM #TB_Demande_02
                    WHERE EXISTS (SELECT * FROM #TB_Rejets_02 WHERE iID_Convention = ConventionID AND iID_Validation = @iID_Validation)
                END
            END
        END -- IF @iCode_Validation 

        -- Efface tous les conventions ayant eu au moins un rejet de validation
        UPDATE #TB_Demande_02 SET IsRejected = 1
        --DELETE FROM #TB_Demande_02
        WHERE EXISTS (SELECT * FROM #TB_Rejets_02 R JOIN dbo.tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation WHERE V.cType = 'E' And iID_Convention = ConventionID)
    END

    UPDATE B SET
        tiType_Responsable = NULL,
        vcNAS_Responsable = NULL,
        vcNEQ_Responsable = NULL,
        vcNom_Responsable = NULL,
        vcPrenom_Responsable = NULL,
        vcNomPrenom_Responsable = NULL
    FROM 
        #TB_Beneficiary_02 B
        JOIN #TB_Demande_02 D ON D.BeneficiaryID = B.BeneficiaryID
        JOIN #TB_Rejets_02 R ON R.iID_Convention = D.ConventionID
        JOIN dbo.tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation AND V.cType = 'A'
    WHERE 
        V.iCode_Validation IN (33, 34, 35, 36, 37)

    UPDATE #TB_Demande_02
       SET CotisationSubventionnable = 0,
           Cotisation = 0,
           Transfert_IN = 0,
           CotisationTotal = 0
      FROM #TB_Demande_02 D JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = D.BeneficiaryID
     WHERE IsNull(B.vcProvince, '') <> 'QC' AND B.bResidenceFaitQuebec = 0 AND @tiCode_Version = 2

    --------------------------------------
    ---- Traite les demandes de subvention
    --------------------------------------
    ; WITH CTE_Sexe as (
        SELECT X.rowID as ID, X.strField as Code
        FROM ProAcces.fn_SplitIntoTable('F,M', ',') X
    )
    INSERT INTO dbo.tblIQEE_Demandes (
                iID_Fichier_IQEE, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse, 
                iID_Convention, vcNo_Convention, dtDate_Debut_Convention, 
                mCotisations, mTransfert_IN, mTotal_Cotisations_Subventionnables, --mTotal_Cotisations,
                iID_Beneficiaire_31Decembre, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, tiSexe_Beneficiaire, dtDate_Naissance_Beneficiaire, 
                iID_Adresse_31Decembre_Beneficiaire, tiNB_Annee_Quebec, vcAppartement_Beneficiaire, vcNo_Civique_Beneficiaire, vcRue_Beneficiaire, 
                vcLigneAdresse2_Beneficiaire, vcLigneAdresse3_Beneficiaire, vcVille_Beneficiaire, vcProvince_Beneficiaire, vcPays_Beneficiaire, 
                vcCodePostal_Beneficiaire, bResidence_Quebec, 
                iID_Souscripteur, tiType_Souscripteur, vcNAS_Souscripteur, vcNEQ_Souscripteur, vcNom_Souscripteur, vcPrenom_Souscripteur, tiID_Lien_Souscripteur, 
                iID_Adresse_Souscripteur, vcAppartement_Souscripteur, vcNo_Civique_Souscripteur, vcRue_Souscripteur, 
                vcLigneAdresse2_Souscripteur, vcLigneAdresse3_Souscripteur, vcVille_Souscripteur, vcProvince_Souscripteur, vcPays_Souscripteur, 
                vcCodePostal_Souscripteur, vcTelephone_Souscripteur, 
                iID_Cosouscripteur, vcNAS_Cosouscripteur, vcNom_Cosouscripteur, vcPrenom_Cosouscripteur, tiID_Lien_Cosouscripteur, vcTelephone_Cosouscripteur, 
                tiType_Responsable, vcNAS_Responsable, vcNEQ_Responsable, vcNom_Responsable, vcPrenom_Responsable, tiID_Lien_Responsable, 
                --vcAppartement_Responsable, vcNo_Civique_Responsable, vcRue_Responsable, vcLigneAdresse2_Responsable, vcLigneAdresse3_Responsable, vcVille_Responsable, 
                --vcProvince_Responsable, vcPays_Responsable, vcCodePostal_Responsable, vcTelephone_Responsable, 
                bInd_Cession_IQEE
            )
    --OUTPUT inserted.*
    SELECT
        @iID_Fichier_IQEE, @siAnnee_Fiscale, @tiCode_Version, 'A', --CASE WHEN R.iID_Convention IS NULL THEN 'A' ELSE 'X' END,
        C.ConventionID, C.ConventionNo, C.DateEnregistrementRQ,
        C.Cotisation, C.Transfert_IN, C.CotisationSubventionnable, --C.CotisationTotal,
        B.BeneficiaryID, LEFT(B.vcNAS, 9), Left(B.vcNom, 20), Left(B.vcPrenom, 20), (SELECT ID FROM CTE_Sexe WHERE Code = B.cSexe), B.dtNaissance,
        B.iID_Adresse, NULL, Left(B.vcAppartement, 6), LEFT(ISNULL(B.vcNoCivique, '-'), 10), 
            Left(CASE WHEN Len(IsNull(B.vcNomRue, '')) > 0
                      THEN B.vcNomRue + CASE WHEN Len(IsNull(B.vcBoite, '')) = 0
                                             THEN CASE B.iID_TypeBoite WHEN 1 THEN ' CP ' WHEN 2 THEN ' RR ' ELSE ' ' END
                                             ELSE '' 
                                        END
                      ELSE B.vcAdresse_Tmp
                 END, 50),
        NULL, Left(B.vcAdresseLigne3, 40), Left(B.vcVille, 30), Left(IsNull(B.vcProvince, ''), 2), Left(B.cID_Pays, 3), 
        Left(B.vcCodePostal, 10), 
            CASE Left(IsNull(B.vcProvince, ''), 2) WHEN 'QC' THEN 1 ELSE B.bResidenceFaitQuebec END, 
        S.SubscriberID, CASE S.cType_HumanOrCompany WHEN 'H' THEN 1 
                                                      WHEN 'C' THEN 2
                                                      ELSE NULL 
                          END, LEFT(S.vcNAS, 9), Left(S.vcNEQ, 10), Left(S.vcNom, 20), Left(S.vcPrenom, 20), C.Subscriber_LienID,
        S.iID_Adresse, Left(S.vcAppartement, 6), Left(IsNull(S.vcNoCivique, '-'), 10), 
            Left(CASE WHEN Len(IsNull(S.vcNomRue, '')) > 0
                      THEN S.vcNomRue + CASE WHEN Len(IsNull(S.vcBoite, '')) = 0
                                             THEN CASE S.iID_TypeBoite WHEN 1 THEN ' CP ' WHEN 2 THEN ' RR ' ELSE ' ' END
                                             ELSE '' 
                                        END
                      ELSE S.vcAdresse_Tmp
                 END, 50),
        NULL, Left(S.vcAdresseLigne3, 40), Left(S.vcVille, 30), Left(S.vcProvince, 2), Left(S.cID_Pays, 3), 
        Left(S.vcCodePostal, 10), NULL,
        CS.iID_CoSubscriber, LEFT(CS.vcNAS, 9), Left(CS.vcNom, 20), Left(CS.vcPrenom, 20), NULL, NULL,
    --    CASE WHEN tiType_Responsable IS NULL AND C.Subscriber_LienID = 1
          --   THEN CASE S.cType_HumanOrCompany WHEN 'H' THEN 1 WHEN 'C' THEN 2 ELSE NULL END
             --ELSE B.tiType_Responsable END,
    --    CASE WHEN tiType_Responsable IS NULL AND C.Subscriber_LienID = 1 THEN S.vcNAS ELSE B.vcNAS_Responsable END,
    --    CASE WHEN tiType_Responsable IS NULL AND C.Subscriber_LienID = 1 THEN Left(S.vcNEQ, 10) ELSE B.vcNEQ_Responsable END,
    --    CASE WHEN tiType_Responsable IS NULL AND C.Subscriber_LienID = 1 THEN Left(S.vcNom, 20) ELSE B.vcNom_Responsable END,
    --    CASE WHEN tiType_Responsable IS NULL AND C.Subscriber_LienID = 1 THEN Left(S.vcPrenom, 20) ELSE B.vcPrenom_Responsable END,
        B.tiType_Responsable, LEFT(B.vcNAS_Responsable, 9), LEFT(B.vcNEQ_Responsable, 10), Left(B.vcNom_Responsable, 20), Left(B.vcPrenom_Responsable, 20), 
        NULL,
        --NULL, NULL, NULL, NULL, NULL, NULL, 
        --NULL, NULL, NULL, NULL, 
        0
    FROM
        #TB_Demande_02 C
        JOIN #TB_Beneficiary_02 B ON B.BeneficiaryID = C.BeneficiaryID
        JOIN #TB_Subscriber_02 S ON S.SubscriberID = C.SubscriberID
        LEFT JOIN #TB_CoSubscriber_02 CS ON CS.iID_CoSubscriber = C.CoSubscriberID
    WHERE 0=0
        --(IsNull(B.vcProvince, '') = 'QC' OR B.bResidenceFaitQuebec <> 0 OR @tiCode_Version = 2)
        AND NOT (B.iID_Adresse IS NULL OR S.iID_Adresse IS NULL)
        AND NOT EXISTS (
            SELECT * FROM #TB_Rejets_02 R 
                     JOIN dbo.tblIQEE_Validations V ON V.iID_Validation = R.iID_Validation 
                     WHERE V.cType = 'E' AND R.iID_Convention = C.ConventionID
        )
    ORDER BY
        C.ConventionID, C.ConventionNo, C.DateEnregistrementRQ

    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + Str(@@RowCount) + ' conventions acceptés au total'

    --UPDATE dbo.tblIQEE_Demandes SET
    --    tiType_Responsable = tiType_Souscripteur,
    --    vcNAS_Responsable = vcNAS_Souscripteur,
    --    vcNom_Responsable = vcNom_Souscripteur,
    --    vcPrenom_Responsable = vcPrenom_Souscripteur
    --WHERE 
    --    iID_Fichier_IQEE = @iID_Fichier_IQEE
    --    AND tiType_Responsable IS NULL
    --    AND tiID_Lien_Souscripteur = 1

    INSERT INTO dbo.tblIQEE_Rejets (
        iID_Fichier_IQEE, siAnnee_Fiscale, iID_Convention, iID_Validation, vcDescription,
        vcValeur_Reference, vcValeur_Erreur, iID_Lien_Vers_Erreur_1, iID_Lien_Vers_Erreur_2, iID_Lien_Vers_Erreur_3
        --, tCommentaires, iID_Utilisateur_Modification, dtDate_Modification,
        --, tiID_Type_Enregistrement, iID_Enregistrement
    )
    --OUTPUT inserted.*
    SELECT DISTINCT
        @iID_Fichier_IQEE, @siAnnee_Fiscale, R.iID_Convention, R.iID_Validation, R.vcDescription,
        R.vcValeur_Reference, vcValeur_Erreur, R.iID_Lien_Vers_Erreur_1, R.iID_Lien_Vers_Erreur_2, R.iID_Lien_Vers_Erreur_3
        --, @tiID_TypeEnregistrement, D.iID_Demande_IQEE
    FROM 
        #TB_Rejets_02 R
        --LEFT JOIN (
        --    SELECT DISTINCT iID_Convention, iID_Demande_IQEE
        --      FROM dbo.tblIQEE_Demandes
        --     WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE
        --       AND cStatut_Reponse = 'X'
        --    ) D ON D.iID_Convention = R.iID_Convention

    PRINT '   ' + Convert(varchar(20), GETDATE(), 120) + '    » ' + Str(@@RowCount) + ' conventions rejetés au total'

    -----------------------------------
    ---- Libère les tablees temporaires
    -----------------------------------
    BEGIN
        IF Object_ID('tempDB..#TB_CaracteresAccents_02') IS NOT NULL
            DROP TABLE #TB_CaracteresAccents_02
        IF Object_ID('tempDB..#TB_Rejets_02') IS NOT NULL
            DROP TABLE #TB_Rejets_02
        IF Object_ID('tempDB..#TB_Validation_02') IS NOT NULL
            DROP TABLE #TB_Validation_02
        IF Object_ID('tempDB..#TB_PrevDemande_02') IS NOT NULL
            DROP TABLE #TB_PrevDemande_02
        IF Object_ID('tempDB..#TB_Beneficiary_02') IS NOT NULL
            DROP TABLE #TB_Beneficiary_02
        IF Object_ID('tempDB..#TB_CoSubscriber_02') IS NOT NULL
            DROP TABLE #TB_CoSubscriber_02
        IF Object_ID('tempDB..#TB_Subscriber_02') IS NOT NULL
            DROP TABLE #TB_Subscriber_02
        IF Object_ID('tempDB..#TB_Demande_02') IS NOT NULL
            DROP TABLE #TB_Demande_02
    END

    SET @ElapseTime = GetDate() - @StartTimer
    PRINT '   ' + Convert(varchar(20), GetDate(), 120) + ' EXEC psIQEE_CreerTransactions_02 completed' 
                + ' (Elapsed time ' + LTrim(Str((DatePart(day, @ElapseTime)-1) * 24 + DatePart(hour, @ElapseTime),4)) + Right(CONVERT(VARCHAR, @ElapseTime, 120), 6) + ')'

    -- Retourner 0 si le traitement est réussi
    RETURN 0
END
