/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

--exec ps_TESTCPA

CREATE PROCEDURE [dbo].[ps_TESTCPA] 
AS 
BEGIN

DECLARE 
            @dtDateDernierDepot DATE,
            @ConnectID INTEGER, -- Identificateur unique de connexion de l'usager
            @BeginDate DATETIME, -- Date de début de l'interval à traiter
            @EndDate DATETIME,  -- Date de fin de l'interval à traiter
            @AutomaticDepositDate DATETIME

SELECT 
            @dtDateDernierDepot = MAX(BF.BankFileEndDate) + 1
FROM Un_BankFile BF

PRINT @dtDateDernierDepot

SET @ConnectID  = 2
SET @BeginDate = @dtDateDernierDepot
SET @EndDate = @dtDateDernierDepot

-- Enlève les heures aux dates de début et de fin de l'interval
SET @BeginDate = dbo.fn_Mo_DateNoTime(@BeginDate)
SET @EndDate = dbo.fn_Mo_DateNoTime(@EndDate)

SET @AutomaticDepositDate = @BeginDate

--Table temporaire contenant les conventions dont la date de dépôt
--maximal est entre la date de début et la date de fin des CPA
SELECT
            VI.ConventionID,
            MaxConvDepositDate = DATEADD(YEAR, M.YearQty, CASE 
                                                                                                                                             WHEN ISNULL(VI.dtCotisationEndDateAdjust, VI.InForceDate+1) < VI.InForceDate 
                                                                                                                                                                     AND ISNULL(VI.dtCotisationEndDateAdjust, VI.InForceDate+1) < ISNULL(C.dtInforceDateTIN, VI.InForceDate)
                                                                                                                                                                     THEN VI.dtCotisationEndDateAdjust
                                                                                                                                             WHEN ISNULL(C.dtInforceDateTIN, VI.InForceDate+1) < VI.InForceDate THEN C.dtInforceDateTIN
                                                                                                                                             ELSE VI.InForceDate
                                                                                                                      END)
INTO #MaxConvDate
FROM Un_MaxConvDepositDateCfg M
JOIN (
            SELECT
                        ConventionID,
                        InForceDate = MIN(InForceDate),
                        dtCotisationEndDateAdjust = MIN(dtCotisationEndDateAdjust)
            FROM dbo.Un_Unit 
            GROUP BY ConventionID
            ) VI ON VI.InForceDate >= M.EffectDate            
JOIN dbo.Un_Convention C ON C.ConventionID = VI.ConventionID    
WHERE (M.EffectDate IN( 
            SELECT
                        MAX(EffectDate)
            FROM Un_MaxConvDepositDateCfg
            WHERE EffectDate <= VI.InForceDate))
            AND (DATEADD(YEAR, M.YearQty, VI.InForceDate) <= DATEADD(DAY, 1, @EndDate))

-- Création d'une table de ConventionID indexé contenant tous les conventions avec arrêt de paiement
CREATE TABLE #TT_CPA_Breaking (
            ConventionID INTEGER PRIMARY KEY)

INSERT INTO #TT_CPA_Breaking
            SELECT DISTINCT
                        ConventionID
            FROM Un_Breaking
            WHERE @AutomaticDepositDate BETWEEN BreakingStartDate AND ISNULL(BreakingEndDate, DATEADD(DAY, 1, @AutomaticDepositDate))

-- Création d'une table de UnitID indexé contenant tous les groupes d'unités avec arrêt de paiement
CREATE TABLE #TT_CPA_HoldPayment (
            UnitID INTEGER PRIMARY KEY)

INSERT INTO #TT_CPA_HoldPayment
            SELECT DISTINCT
                        UnitID
            FROM Un_UnitHoldPayment
            WHERE @AutomaticDepositDate BETWEEN StartDate AND ISNULL(EndDate, DATEADD(DAY, 1, @AutomaticDepositDate))

-- --------------------------------------------
-- Début de la génération des CPA automatique   
-- --------------------------------------------
-- Création d'une table de UnitID indexé contenant tous les groupes d'unités avec arrêt de paiement
CREATE TABLE #TT_CPA_AutomaticDeposit (
            UnitID INTEGER PRIMARY KEY)
            
INSERT INTO #TT_CPA_AutomaticDeposit
            SELECT DISTINCT
                        UnitID
            FROM Un_AutomaticDeposit
            WHERE (@AutomaticDepositDate >= StartDate)
                        AND ((ISNULL(EndDate,0) <= 0)
                                   OR (@AutomaticDepositDate <= EndDate))

-- Création d'une table de cotisation temporaire pour minimiser l'accès à la vrai table Un_Cotisation
CREATE TABLE #TT_CPA_TmpInsCotisation (
            OperID INTEGER NOT NULL,
            UnitID INTEGER NOT NULL,
            EffectDate DATETIME NOT NULL,
            Cotisation MONEY NOT NULL,
            Fee MONEY NOT NULL,
            BenefInsur MONEY NOT NULL,
            SubscInsur MONEY NOT NULL,
            TaxOnInsur MONEY NOT NULL)

CREATE TABLE #TT_CPA_CPAToDo (
            UnitID INTEGER,
            UnitQty MONEY,
            FeeSplitByUnit MONEY,
            FeeByUnit MONEY,
            AccountName VARCHAR(75),
            TransitNo VARCHAR(75),
            BankID INTEGER,
            CotisationFee MONEY,
            BenefInsur MONEY,
            SubscInsur MONEY,
            TaxOnInsur MONEY,
            TotCotFee MONEY,
            TotFeeBeforeDep MONEY,
            TotCotBeforeDep MONEY,
            MntSouscrit MONEY)
                                                                                                          
CREATE TABLE #TT_Unit_Sans_Cotisation (
            UnitID INTEGER)

INSERT INTO #TT_Unit_Sans_Cotisation
SELECT DISTINCT
            CT.UnitID
FROM Un_Cotisation CT
JOIN Un_Oper O ON O.OperID = CT.OperID
WHERE O.OperTypeID IN ('CHQ', 'CPA', 'PRD', 'RDI', 'TRA', 'TIN') -- Ne doit pas tenir compte des TFR
                                                                                                                      
-- Créer les CPA selon la cédule habituelle, à l'exception du premier dépôt
INSERT INTO #TT_CPA_CPAToDo
            SELECT
                        U.UnitID,
                        U.UnitQty,
                        M.FeeSplitByUnit,
                        M.FeeByUnit,
                        CA.AccountName,
                        CA.TransitNo,
                        CA.BankID,
                        CotisationFee = ROUND((U.UnitQty * ISNULL(M.PmtRate,0)),2),
                        BenefInsur = ROUND(ISNULL(BI.BenefInsurRate,0),2),
                        SubscInsur = 
                                   CASE U.WantSubscriberInsurance
                                               WHEN 0 THEN 0
                                   ELSE ROUND((U.UnitQty * ISNULL(M.SubscriberInsuranceRate,0)),2)
                                   END,
                        TaxOnInsur = 
                                   CASE U.WantSubscriberInsurance
                                               WHEN 0 THEN ROUND((ISNULL(BI.BenefInsurRate,0) * ISNULL(St.StateTaxPct,0)) + 0.0049,2)
                                   ELSE ROUND((((ISNULL(BI.BenefInsurRate,0) + (U.UnitQty * ISNULL(M.SubscriberInsuranceRate,0))) * ISNULL(St.StateTaxPct,0)) + 0.0049),2)
                                   END,
                        TotCotFee = ISNULL(SUM(T.Cotisation + T.Fee),0),
                        TotFeeBeforeDep = 0,
                        TotCotBeforeDep = 0,
                        MntSouscrit = ROUND(U.UnitQty * ISNULL(M.PmtRate,0),2) * ISNULL(M.PmtQty,0)
            FROM dbo.Un_Convention C
            JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
            JOIN Un_Modal M ON M.ModalID = U.ModalID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            JOIN Un_ConventionAccount CA ON CA.ConventionID = C.ConventionID
            JOIN Un_Plan P ON P.PlanID = C.PlanID
            LEFT JOIN Mo_State St ON St.StateID = S.StateID
            LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
            LEFT JOIN Un_Cotisation T ON T.UnitID = U.UnitID
            LEFT JOIN #MaxConvDate VM ON VM.ConventionID = C.ConventionID AND (VM.MaxConvDepositDate < @AutomaticDepositDate)
            LEFT JOIN #TT_Unit_Sans_Cotisation USCT ON USCT.UnitID = U.UnitID
            WHERE (ISNULL(U.TerminatedDate,0) <= 0)
                        AND (ISNULL(U.IntReimbDate,0) <= 0)
                        AND (U.ActivationConnectID > 0)
                        AND C.ConventionID NOT IN (
                                   SELECT ConventionID
                                   FROM #TT_CPA_Breaking) -- Pas d'arrêt de paiement de convention
                        AND U.UnitID NOT IN (
                                   SELECT UnitID
                                   FROM #TT_CPA_HoldPayment) -- Pas d'arrêt de paiement de groupe d'unités
                        AND U.UnitID NOT IN (
                                   SELECT UnitID
                                   FROM #TT_CPA_AutomaticDeposit) -- Pas d'horaire de prélèvement automatique
                        AND ((ISNULL(VM.ConventionID, 0) = 0) OR (ROUND((U.UnitQty * ISNULL(M.PmtRate,0)),2) <= 0))
                        AND (DAY(C.FirstPmtDate) = DAY(@AutomaticDepositDate))
                        --AND U.dtFirstDeposit IS NOT NULL -- Le premier dépôt est fait
                        AND USCT.UnitID IS NOT NULL -- Le premier dépôt est fait
        AND U.InForceDate <= @AutomaticDepositDate -- La date de début des opérations financière est avant ou égale à la date du traitement
                        AND (C.PmtTypeID = 'AUT')
                        AND ((MONTH(@AutomaticDepositDate) - MONTH(U.InForceDate)) % (12/M.PmtByYearID) = 0)
                        --AND ((ISNULL(U.PETransactionId, 0) <> 0 AND U.dtFirstDeposit IS NULL)  -- Valide si provient de la propo et qu'aucun dépôt n'a été fait, ou que la date du CPA a créer est différente de la date du premier dépôt.
                        --                     OR (MONTH(@AutomaticDepositDate) <> MONTH(U.InForceDate) OR YEAR(@AutomaticDepositDate) <> YEAR(U.InForceDate)))
                        AND (MONTH(@AutomaticDepositDate) <> MONTH(U.InForceDate) OR YEAR(@AutomaticDepositDate) <> YEAR(U.InForceDate)) -- Pas la date du premier dépôt
                        AND (U.PmtEndConnectID IS NULL) -- Pas d'arrêt de paiement forcé
                        AND P.PlanTypeID <> 'IND' -- Pas une convention individuel
            GROUP BY
                        U.UnitID,
                        U.UnitQty,
                        M.FeeSplitByUnit,
                        M.FeeByUnit,
                        CA.AccountName,
                        CA.TransitNo,
                        CA.BankID,
                        U.WantSubscriberInsurance,
                        M.PmtQty,
                        U.UnitQty,
                        M.PmtRate,
                        M.PmtByYearID,
                        BI.BenefInsurRate,
                        St.StateTaxPct,
                        M.SubscriberInsuranceRate
            HAVING ISNULL(SUM(T.Cotisation + T.Fee),0) < ROUND(U.UnitQty * ISNULL(M.PmtRate,0),2) * ISNULL(M.PmtQty,0)
            
-- Créer le premier dépôt dès que possible, à partir de la date du début des opérations financières
--INSERT INTO #TT_CPA_CPAToDo
            SELECT
                        C.ConventionID,
                        C.ConventionNo,
                        U.UnitID,
                        U.UnitQty,
                        M.FeeSplitByUnit,
                        M.FeeByUnit,
                        CA.AccountName,
                        CA.TransitNo,
                        CA.BankID,
                        CotisationFee = ROUND((U.UnitQty * ISNULL(M.PmtRate,0)),2),
                        BenefInsur = ROUND(ISNULL(BI.BenefInsurRate,0),2),
                        SubscInsur = 
                                   CASE U.WantSubscriberInsurance
                                               WHEN 0 THEN 0
                                   ELSE ROUND((U.UnitQty * ISNULL(M.SubscriberInsuranceRate,0)),2)
                                   END,
                        TaxOnInsur = 
                                   CASE U.WantSubscriberInsurance
                                               WHEN 0 THEN ROUND((ISNULL(BI.BenefInsurRate,0) * ISNULL(St.StateTaxPct,0)) + 0.0049,2)
                                   ELSE ROUND((((ISNULL(BI.BenefInsurRate,0) + (U.UnitQty * ISNULL(M.SubscriberInsuranceRate,0))) * ISNULL(St.StateTaxPct,0)) + 0.0049),2)
                                   END,
                        TotCotFee = ISNULL(SUM(T.Cotisation + T.Fee),0),
                        TotFeeBeforeDep = 0,
                        TotCotBeforeDep = 0,
                        MntSouscrit = ROUND(U.UnitQty * ISNULL(M.PmtRate,0),2) * ISNULL(M.PmtQty,0)
            FROM dbo.Un_Convention C
            JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
            JOIN Un_Modal M ON M.ModalID = U.ModalID
            JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            JOIN Un_ConventionAccount CA ON CA.ConventionID = C.ConventionID
            JOIN Un_Plan P ON P.PlanID = C.PlanID
            LEFT JOIN Mo_State St ON St.StateID = S.StateID
            LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
            LEFT JOIN Un_Cotisation T ON T.UnitID = U.UnitID
            LEFT JOIN #MaxConvDate VM ON VM.ConventionID = C.ConventionID AND (VM.MaxConvDepositDate < @AutomaticDepositDate)
            LEFT JOIN #TT_CPA_CPAToDo CPA ON CPA.UnitID = U.UnitID
            LEFT JOIN #TT_Unit_Sans_Cotisation USCT ON USCT.UnitID = U.UnitID
            WHERE (ISNULL(U.TerminatedDate,0) <= 0)
                        AND (ISNULL(U.IntReimbDate,0) <= 0)
                        AND (U.ActivationConnectID > 0)
                        AND C.ConventionID NOT IN (
                                   SELECT ConventionID
                                   FROM #TT_CPA_Breaking) -- Pas d'arrêt de paiement de convention
                        AND U.UnitID NOT IN (
                                   SELECT UnitID
                                   FROM #TT_CPA_HoldPayment) -- Pas d'arrêt de paiement de groupe d'unités
                        AND U.UnitID NOT IN (
                                   SELECT UnitID
                                   FROM #TT_CPA_AutomaticDeposit) -- Pas d'horaire de prélèvement automatique
                        AND ((ISNULL(VM.ConventionID, 0) = 0) OR (ROUND((U.UnitQty * ISNULL(M.PmtRate,0)),2) <= 0))
                        AND CPA.UnitID IS NULL -- Pas de CPA déjà en attente d'être créé
                        --AND U.dtFirstDeposit IS NULL -- Le premier dépôt n'est pas encore fait
                        AND USCT.UnitID IS NULL -- Le premier dépôt n'est pas encore fait
                        AND U.InForceDate <= @AutomaticDepositDate -- La date de début des opérations financière est avant ou égale à la date du traitement
                        AND (C.PmtTypeID = 'AUT')
                        AND (U.PmtEndConnectID IS NULL) -- Pas d'arrêt de paiement forcé
                        AND P.PlanTypeID <> 'IND' -- Pas une convention individuel
            GROUP BY
                        C.ConventionID,
                        C.ConventionNo,
                        U.UnitID,
                        U.UnitQty,
                        M.FeeSplitByUnit,
                        M.FeeByUnit,
                        CA.AccountName,
                        CA.TransitNo,
                        CA.BankID,
                        U.WantSubscriberInsurance,
                        M.PmtQty,
                        U.UnitQty,
                        M.PmtRate,
              M.PmtByYearID,
                        BI.BenefInsurRate,
                        St.StateTaxPct,
                        M.SubscriberInsuranceRate
            HAVING ISNULL(SUM(T.Cotisation + T.Fee),0) < ROUND(U.UnitQty * ISNULL(M.PmtRate,0),2) * ISNULL(M.PmtQty,0)

end