/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :    TT_UN_ConventionAndUnitStateForUnit
Description         :    Calcul les états du groupe d'unités et de sa convention et les mettent à jour pour les 
                                groupes d'unités passés en paramètre.
Valeurs de retours  :    @ReturnValue :
                >0 = Pas d’erreur
                <=0 = Erreur SQL
Note                :                
                    2004-06-11  Bruno Lapointe          Création Point 10.23.02
    ADX0000968  BR  2004-08-23  Bruno Lapointe          Gestion des arrêts de paiements forcés
    ADX0000970  BR  2004-08-23  Bruno Lapointe          Correction de la gestion des états lors de transfert IN
    ADX0000973  BR  2004-08-23  Bruno Lapointe          Correction de la gestion des états lors d'annulation financière
    ADX0000975  BR  2004-08-23  Bruno Lapointe          Correction de la gestion des états lors de modification d'un remboursement intégral
    ADX0000978  BR  2004-08-23  Bruno Lapointe          Correction de la gestion des états lors de résiliation valeur 0
    ADX0000694  IA  2005-06-17  Bruno Lapointe          Ajout du paramètre @BlobID pour offrir une option qui permet de passer plus de ID
    ADX0001216  UR  2005-10-12  Bruno Lapointe          Changer les blobs pour une table temporaire pour optimiser les performances.
    ADX0001095  BR  2005-12-15  Bruno Lapointe          Retour en arrière avec le paramètre VARCHAR(8000) à cause du bogue de Deadlock.
    ADX0000834  IA  2006-04-10  Bruno Lapointe          Adaptation au PCEE 4.3
    ADX0000834  IA  2006-06-28  Bruno Lapointe          Optimisation
    ADX0001114  IA  2006-11-20  Alain Quirion           Gestion des deux périodes de calcul de date estimée de RI (FN_UN_EstimatedIntReimbDate)
    ADX0002426  BR  2007-05-22  Bruno Lapointe          Gestion de la table Un_CESP.
    ADX0002516  BR  2007-08-08  Alain Quirion           Modification du nom de la clé primaire pour une des table temporaires
    ADX0001286  UP  2008-03-03  Bruno Lapointe          Utilisation de dtRegStartDate.
                    2008-06-05  Jean-Francois Arial     Modification du traitement quotidien pour mettre à jour les status en lien avec les opérations RIO
                    2010-07-28  Éric Deshaies           Correction pour le statut "PTR" pour les conventions issues d'un RIO
                                                        Ne pas prendre les RIO d'annulation
                    2011-03-17  Frédérick Thibault      Ajout du statut "RIM" pour les opérations de conversion vers l'individuel
                    2012-10-16  Donald Huppé            Dans la section RIO, prendre le max(OperDate), sinon ça génère plus d'un état de groupe d'unité (voir glpi 8378)
                    2015-04-10  Pierre-Luc Simard       Correction pour ne pas utiliser les cotisations postdatées
                    2016-02-15  Steve Bélanger          Ajout du cas FRM comme état final afin de ne pas mettre à jour les status
                    2016-03-22  Steve Bélanger          Lorsqu'il existe une opération de fermeture, on retourne le statut courant du groupe d'unité au lieu de retourner 'FRM' 
                    2016-08-04  Steeve Picard           Ajouter le critère que si l'annexe B du tuteur est requise mais non signé (reçu), le statut du groupe d'unité demeure en «Transitoire»
                    2016-09-14  Steeve Picard           Renommage de la fonction en «fntCONV_ObtenirStatutConventionEnDate_PourTous»
                    2017-01-30  Pierre-Luc Simard       Ne pas tenir compte des TIN qui annulent pour l'état Proposition Transfert IN (JIRA TI-6551)
                    2017-03-23  Pierre-Luc Simard       Retrait du critère que si l'annexe B du tuteur est requise mais non signé (reçu), le statut du groupe d'unité demeure en «Transitoire»
					2017-12-12	Simon Tanguay		    JIRA: CRIT-1562	Ajouter les tables d'historique de statuts
					2018-02-21  Pierre-Luc Simard       JIRA: CRIT-2703 Retirer les statuts RIN, RIV, RIM, TRI, PAE, PVR et BTP
                                                                        Mettre CPT au lieu de EPG pour les Individuel
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_ConventionAndUnitStateForUnit] (
    @UnitIDs VARCHAR(8000)) -- String de IDs Unique de groupes d'unités séparés par des virgules
AS
BEGIN
    DECLARE 
        @Today DATETIME,
        @TodayNoTime DATETIME

    SET @Today = GETDATE()

    SET @TodayNoTime = dbo.FN_CRQ_DateNoTime(@Today)

    -- Crée un table temporaire dans laquel on insérera le contenu que retournera la fonction dbo.FN_CRQ_IntegerTable
    CREATE TABLE #UnitIDs (
        UnitID INTEGER PRIMARY KEY,
        CotisationFee MONEY NOT NULL ) 

    INSERT INTO #UnitIDs
        SELECT 
            IDs.Val,
            ISNULL(CotisationFee, 0)
        FROM dbo.FN_CRQ_IntegerTable(@UnitIDs) IDs
        LEFT JOIN (
            SELECT 
	            CT.UnitID,
	            CotisationFee = SUM(Cotisation+Fee)
            FROM Un_Cotisation Ct
            JOIN Un_Oper O ON O.OperID = Ct.OperID
            JOIN Un_Unit U ON U.UnitID = Ct.UnitID
            LEFT JOIN tblOPER_OperationsRIO RIO ON RIO.iID_Oper_RIO = O.OperID AND RIO.iID_Unite_Source = U.UnitID AND RIO.bRIO_Annulee = 0
            WHERE O.OperDate <= @Today
                AND O.OperTypeID <> 'RIN'
                AND RIO.iID_Operation_RIO IS NULL -- Exlure les RIO, RIM et TRI sortant
            GROUP BY CT.UnitID
            ) Ct ON IDs.Val = Ct.UnitID

    CREATE TABLE #tConvInf_State (
        ConventionID INTEGER PRIMARY KEY,
        InForceDate DATETIME NOT NULL )

    INSERT INTO #tConvInf_State
        SELECT 
            U.ConventionID,
            InForceDate = MIN(U.InForceDate)
        FROM dbo.Un_Unit U
        JOIN #UnitIDs I ON I.UnitID = U.UnitID
        GROUP BY U.ConventionID

    CREATE TABLE #tConvProp_State (
        ConventionID INTEGER PRIMARY KEY )

    INSERT INTO #tConvProp_State
        SELECT DISTINCT 
            C.ConventionID
        FROM dbo.Un_Convention C 
        JOIN #tConvInf_State I ON I.ConventionID = C.ConventionID
        join dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(null, NULL) S ON S.conventionID = C.ConventionID
        WHERE (
                C.dtRegStartDate IS NULL
                AND I.InForceDate >= '2003-01-01' -- Applique la règle qui dit qu'une convention ne peut être en proposition si elle est avant le 1 janvier 2003
              )
           /*or (
                C.SCEEAnnexeBTuteurRequise <> 0 and C.SCEEAnnexeBTuteurRecue = 0
                AND NOT S.ConventionStateID IN ('REE', 'FRM')
              ) */
    
    CREATE TABLE #tConvTIN_State (
        UnitID INTEGER PRIMARY KEY )

    INSERT INTO #tConvTIN_State
        SELECT DISTINCT
            Ct.UnitID
        FROM Un_Cotisation Ct
        JOIN Un_Oper O ON O.OperID = Ct.OperID
        JOIN #UnitIDs IDs ON IDs.UnitID = Ct.UnitID
        LEFT JOIN Un_OperCancelation OC ON OC.OperSourceID = O.OperID
        LEFT JOIN Un_OperCancelation OCA ON OCA.OperID = O.OperID -- 2017-01-30
        WHERE O.OperTypeID = 'TIN'
          AND (O.OperDate <= @Today)
          AND OC.OperID IS NULL
          AND OCA.OperID IS NULL -- 2017-01-30: N'est pas une annulation

    -- Les lignes qui suivent mettent à jour les états des groupes d'unités
    INSERT INTO Un_UnitUnitState (UnitID, UnitStateID, StartDate)
       SELECT DISTINCT
            V.UnitID,
            V.UnitStateID,
            StartDate = @Today            
        FROM (
           SELECT 
                V.UnitID,
                UnitStateID =
                    CASE    
						WHEN CFF.ConventionID IS NOT NULL THEN --PATCH JIRA CRIT-956, On force ces conventions à FRM car celles-ci étaient fermés lors de la mise en production du projet critère et se serait réouverte car des statuts de GU ont été éliminés dans la SP.
							'FRM'                 
                        WHEN V.ROperTypeID  = 'FRM' THEN -- La fermeture est un état final
                            (SELECT TOP 1 SS.UnitStateID FROM Un_UnitUnitState SS WHERE SS.UnitID = V.UnitID ORDER BY SS.StartDate DESC)
                        WHEN (ISNULL(V.TerminatedDate,0) > 0) AND (ISNULL(V.TerminatedDate,0) <= @Today) THEN
                            CASE 
                                WHEN V.ROperTypeID  = '' THEN 
                                    'RPG' -- Résiliation épargne
                                WHEN V.ROperTypeID  = 'OUT' THEN 
                                    'OUT' -- Transfert OUT
                                WHEN V.RFee <> 0 AND (V.RSubscInsur <> 0 OR V.RBenefInsur <> 0) THEN 
                                    'RCP' -- Résiliation complète
                                WHEN V.RFee <> 0 AND V.RSubscInsur = 0 AND V.RBenefInsur = 0 THEN 
                                    'RFE' -- Résiliation frais et épargne
                                WHEN V.RCotisation = 0 THEN 
                                    'RV0' -- Résiliation valeur 0
                                ELSE 
                                    'RPG' -- Résiliation épargne
                            END
                        WHEN V.ActivationConnectID IS NULL THEN
                            CASE 
                                WHEN V.IsTIN = 1 THEN 
                                    'PIN' -- Proposition transfert IN
                                ELSE 
                                    'PTR' -- Proposition en traitement
                            END
                        WHEN V.IsTransitoire = 1 THEN 
                            'TRA' -- Transitoire
                        WHEN (V.MntSouscrit <= V.CotisationFee) OR (ISNULL(V.IntReimbDate,0) > 0 AND ISNULL(V.IntReimbDate,0) <= @Today) THEN 
                            'CPT' -- Capital Atteint
                        ELSE 
                            'EPG' -- En épargne
                    END
            FROM (
                SELECT 
					U.ConventionID,
                    U.UnitID,
                    U.IntReimbDate,
                    U.TerminatedDate,
                    U.ActivationConnectID,
                    U.InforceDate,
                    IsTransitoire =
                        CASE
                            WHEN TRA.ConventionID IS NULL THEN 0
                        ELSE 1
                        END,
                    MntSouscrit = 
                        CASE
                            WHEN ISNULL(U.PmtEndConnectID,0) > 0 OR P.PlanTypeID = 'IND' THEN ISNULL(IDs.CotisationFee, 0)
                        ELSE ROUND(U.UnitQty * M.PmtRate,2) * M.PmtQty
                        END,
                    EstimatedRI = 
                        dbo.fn_Un_EstimatedIntReimbDate (
                            M.PmtByYearID,
                            M.PmtQty,
                            M.BenefAgeOnBegining,
                            U.InForceDate,
                            P.IntReimbAge,
                            U.IntReimbDateAdjust),
                    P.PlanTypeID,
                    CotisationFee = ISNULL(IDs.CotisationFee, 0),
                    ROperTypeID = ISNULL(R.OperTypeID,ISNULL(RTFR.OperTypeID,'')),                    
                    RCotisation = 
                        CASE 
                            WHEN ISNULL(RTFR.OperDate,0) > ISNULL(R.OperDate,0) THEN 0
                        ELSE ISNULL(R.Cotisation,0)
                        END,
                    RFee = 
                        CASE 
                            WHEN ISNULL(RTFR.OperDate,0) > ISNULL(R.OperDate,0) THEN 0
                        ELSE ISNULL(R.Fee,0)
                        END,
                    RSubscInsur = 
                        CASE 
                            WHEN ISNULL(RTFR.OperDate,0) > ISNULL(R.OperDate,0) THEN 0
                        ELSE ISNULL(R.SubscInsur,0)
                        END,
                    RBenefInsur = 
                        CASE 
                            WHEN ISNULL(RTFR.OperDate,0) > ISNULL(R.OperDate,0) THEN 0
                        ELSE ISNULL(R.BenefInsur,0)
                        END,
                    RTaxOnInsur = 
                        CASE 
                            WHEN ISNULL(RTFR.OperDate,0) > ISNULL(R.OperDate,0) THEN 0
                        ELSE ISNULL(R.TaxOnInsur,0)
                        END,
                    IsTIN =
                        CASE
                            WHEN TIN.UnitID IS NULL THEN 0
                        ELSE 1
                        END,
                    C.YearQualif
                FROM dbo.Un_Unit U
                JOIN #UnitIDs IDs ON IDs.UnitID = U.UnitID
                JOIN Un_Modal M ON M.ModalID = U.ModalID
                JOIN Un_Plan P ON P.PlanID = M.PlanID
                JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                -- Va chercher les conventions qui sont des propositions
                LEFT JOIN #tConvProp_State TRA ON TRA.ConventionID = U.ConventionID
                LEFT JOIN ( -- Va chercher les montants remboursés lors de la dernière résiliation pour déterminer le type de résiliation
                    SELECT 
                        Ct.UnitID,
                        O.OperTypeID,
                        O.OperDate,
                        Ct.Cotisation,
                        Ct.Fee,
                        Ct.SubscInsur,
                        Ct.BenefInsur,
                        Ct.TaxOnInsur
                    FROM Un_Cotisation Ct
                    JOIN Un_Oper O ON O.OperID = Ct.OperID
                    JOIN (
                        SELECT 
                            Ct.UnitID,
                            OperID = MAX(O.OperID)
                        FROM Un_Cotisation Ct
                        JOIN Un_Oper O ON O.OperID = Ct.OperID
                        JOIN #UnitIDs IDs ON IDs.UnitID = Ct.UnitID
                        WHERE O.OperTypeID IN ('RES', 'OUT', 'FRM')
                          AND O.OperDate <= @Today
                        GROUP BY Ct.UnitID
                        ) V ON V.OperID = O.OperID
                    ) R ON R.UnitID = U.UnitID
                LEFT JOIN ( -- Va chercher le dernier TFR lié à une résiliation
                    SELECT 
                        Ct.UnitID,
                        O.OperTypeID,
                        O.OperDate
                    FROM Un_Cotisation Ct
                    JOIN Un_Oper O ON O.OperID = Ct.OperID
                    JOIN (
                        SELECT 
                            Ct.UnitID,
                            OperID = MAX(O.OperID)
                        FROM Un_Cotisation Ct
                        JOIN Un_Oper O ON O.OperID = Ct.OperID
                        JOIN #UnitIDs IDs ON IDs.UnitID = Ct.UnitID
                        LEFT JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
                        WHERE O.OperTypeID = 'TFR'
                          AND URC.CotisationID IS NULL
                          AND O.OperDate <= @Today
                        GROUP BY Ct.UnitID
                        ) V ON V.OperID = O.OperID
                    ) RTFR ON RTFR.UnitID = U.UnitID
                -- Va chercher les groupes d'unités qui on eu des transferts IN
                LEFT JOIN #tConvTIN_State TIN ON TIN.UnitID = U.UnitID
            ) V 
			LEFT JOIN Un_ConventionFRM_Force CFF ON CFF.ConventionID = V.ConventionID
        ) V 
        LEFT JOIN (  -- Va chercher l'état actuel du groupe d'unités
            SELECT     US.UnitID
                    ,US.UnitStateID
            FROM Un_UnitUnitState US
            JOIN (    SELECT     USS.UnitID
                            ,StartDate = MAX(USS.StartDate) 
                FROM Un_UnitUnitState    USS
                JOIN #UnitIDs            IDs ON IDs.UnitID = USS.UnitID
                GROUP BY USS.UnitID
                ) V ON V.UnitID = US.UnitID AND US.StartDate = V.StartDate
            ) EA ON EA.UnitID = V.UnitID
        -- S'assure que l'état actuel du groupe d'unités est différent que celui calculé pour ne pas insérer d'historique inutilement
        WHERE (EA.UnitID IS NULL OR EA.UnitStateID <> V.UnitStateID)
        -- FT1
        --AND EA.UnitStateID <> 'RIM'
        --AND EA.UnitStateID <> 'TRI'
-- Fin de la mise à jour des états de conventions

-- Les lignes qui suivent mettent à jour l'état des conventions

    DECLARE 
        @ConventionID INTEGER,
        @ConventionIDs VARCHAR(8000)

    -- Crée une chaîne de caractère avec tout les conventions des groupes d'unités passés en paramètre
    DECLARE ConventionIDs CURSOR FOR
        SELECT
            ConventionID
        FROM #tConvInf_State

    OPEN ConventionIDs

    FETCH NEXT FROM ConventionIDs
    INTO
        @ConventionID

    SET @ConventionIDs = ''

    WHILE (@@FETCH_STATUS = 0)
    BEGIN
        SET @ConventionIDs = @ConventionIDs + CAST(@ConventionID AS VARCHAR(30)) + ','
    
        FETCH NEXT FROM ConventionIDs
        INTO
            @ConventionID
    END

    CLOSE ConventionIDs;
    DEALLOCATE ConventionIDs;

    -- Appelle la procédure qui met à jour les états des conventions
    EXECUTE TT_UN_ConventionStateForConvention @ConventionIDs 
-- Fin de la mise à jour des états de conventions
END