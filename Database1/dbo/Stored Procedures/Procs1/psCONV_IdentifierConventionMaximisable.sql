/****************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc.

Code du service	: psCONV_IdentifierConventionMaximisable
Nom du service		: 
But 				: 
Description		:   Permet d'identifier les conventions d'un bénéficiaires, d'un souscripteur ou de tous les souscripteurs 
                    d'un représentant en indiquant s'ils sont maximisables et éligibles à la prêt.

Paramètres d’entrée	:	
        Paramètre			    Oblig   Description
        --------------------    -----   -----------------------------------------------------------------
        @SubscriberID           Non	    ID du souscripteur pour lequel on désire la liste
                                        si NULL, La liste pour tous les souscripteurs est retournée
        @RepID                  Non     ID du représentant

Paramètres de sortie:
        Champ                   Description
        --------------------    ---------------------------------

Exemple d'appel : 
        EXEC psCONV_IdentifierConventionMaximisable NULL, NULL, NULL, NULL, 1
        EXEC psCONV_IdentifierConventionMaximisable 690691, NULL, NULL, NULL, NULL
        EXEC psCONV_IdentifierConventionMaximisable 690691, NULL, NULL, '2018-06-30', NULL
        EXEC psCONV_IdentifierConventionMaximisable NULL, 178849, NULL, NULL, NULL 
        EXEC psCONV_IdentifierConventionMaximisable NULL, NULL, 288649, NULL, NULL 

        
Historique des modifications:
        Date        Programmeur         Description
        ----------  ----------------    ------------------------------------------------------------
        2017-04-18  Pierre-Luc Simard   Création de la procédure
        2017-04-25  Pierre-Luc Simard   Exclusion des bénéficiaires ayant un RIN
                                        Valider que l'argent versé avant 16 ans n'a pas été retiré avant ses 16 ans 
		2017-09-13	Simon Tanguay		Seule les résidents de la province de Québec doivent être considéré comme
										éligible au prêt (Un_Convention.bEstEligiblePret).
        2018-02-22  Pierre-Luc Simard   JIRA PROD-8266: Ne plus exclure les arrêts de paiement
        2018-04-04  Steeve Picard       Remplacement de la fonction «fnCONV_ObtenirStatutConventionEnDatePourTous» par «fntCONV_ObtenirStatutConventionEnDate_PourTous»
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_IdentifierConventionMaximisable](
    @RepID INT = NULL,
    @SubscriberID INT = NULL,
    @BeneficiaryID INT = NULL,
    @EnDateDu DATE = NULL,
    @bEnregistrerValeurs BIT = 0) 
AS
BEGIN

    DECLARE 
        --@SubscriberID INT = NULL,
        --@BeneficiaryID INT = NULL,
        --@RepID INT = NULL,
        --@EnDateDu DATE = NULL,   
        --@bEnregistrerValeurs BIT = 0
        @Au31DecembreAnneeEnCour DATE
    
    --SET @SubscriberID = 178849
    --SET @BeneficiaryID = 288649
    --SET @RepID = 690691
    --SET @EnDateDu = '2018-06-30'
    --SET @bEnregistrerValeurs = 0

    IF @EnDateDu IS NULL
        SET @EnDateDu = GETDATE()

    SET @Au31DecembreAnneeEnCour = STR(YEAR(@EnDateDu), 4) + '-12-31'

    ;WITH 
    --  Liste des conventions REE
    CTE_ConventionREE AS (
        SELECT C.ConventionID, C.ConventionNo, C.SubscriberID, C.BeneficiaryID, C.dtSignature, C.tiMaximisationREEE, S.RepID 
        FROM dbo.Un_Convention C
        JOIN Un_Subscriber S ON S.SubscriberID = C.SubscriberID
        JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(DEFAULT, DEFAULT) CS ON CS.ConventionID = C.ConventionID
        WHERE CS.ConventionStateID = 'REE'
            AND C.SubscriberID = ISNUll(@SubscriberID, C.SubscriberID)
            AND C.BeneficiaryID = ISNUll(@BeneficiaryID, C.BeneficiaryID)
            AND S.RepID = ISNUll(@RepID, S.RepID)
    ),
    --  Souscripteurs ayant des conventions REE
    CTE_Souscripteur AS (
        SELECT DISTINCT
            C.SubscriberID, Age_Sousc = dbo.fn_Mo_Age(HS.BirthDate, @EnDateDu), C.RepID
        FROM CTE_ConventionREE C
        JOIN Mo_Human HS ON HS.HumanID = C.SubscriberID
        WHERE HS.BirthDate IS NOT NULL 
        ),
    --  Bénéficiaires ayant des conventions REE
    CTE_Beneficiaire AS (
        SELECT DISTINCT
            B.BeneficiaryID, B.Age_Benef_31Dec, B.Date_16ans_Benef,
            LimiteMaximisation = 2000 * B.Age_Benef_31Dec + (500 * CASE WHEN B.Age_Benef_31Dec > YEAR(@EnDateDu) - 2006 
                                                                   THEN YEAR(@EnDateDu) - 2006
                                                                   ELSE B.Age_Benef_31Dec
                                                                   END)
        FROM (
            SELECT DISTINCT  
                C.BeneficiaryID, 
                Age_Benef_31Dec = YEAR(@EnDateDu) - YEAR(HB.BirthDate),
                Date_16ans_Benef = CAST(CAST(YEAR(HB.BirthDate) + 15 AS VARCHAR(4)) + '-12-31' AS DATE)
            FROM CTE_ConventionREE C
            JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
            WHERE HB.BirthDate IS NOT NULL 
            ) B
    ),
    -- Liste de toutes les conventions du souscripteur
    CTE_SouscripteurConvention AS (
        SELECT C.ConventionID, C.ConventionNo, C.SubscriberID, C.BeneficiaryID, CS.ConventionStateID, C.dtSignature, C.tiMaximisationREEE 
        FROM dbo.Un_Convention C
        JOIN CTE_Souscripteur S ON S.SubscriberID = C.SubscriberID
        JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(DEFAULT, DEFAULT) CS ON CS.conventionID = C.ConventionID
        WHERE CS.ConventionStateID IN ('REE', 'TRA', 'FRM')
    ),
    CTE_SouscripteurSignature AS (
        SELECT DISTINCT SubscriberID, dtSignature = MIN(dtSignature)
        FROM CTE_SouscripteurConvention
        GROUP BY SubscriberID
    ),
    CTE_SouscripteurUnit AS (
        SELECT C.ConventionID, U.UnitID, U.UnitQty
        FROM CTE_SouscripteurConvention C
        JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
        --JOIN dbo.fnCONV_ObtenirStatutUnitEnDatePourTous(DEFAULT, DEFAULT) S ON S.UnitID = U.UnitID
        --JOIN dbo.Un_UnitState US ON US.UnitStateID = S.UnitStateID
        --WHERE US.OwnerUnitStateID IN ('REE', 'TRA') --S.UnitStateID IN ('')
    ),
    CTE_SouscripteurCotisation AS (
        SELECT U.ConventionID, O.OperTypeID
        FROM CTE_SouscripteurUnit U
        JOIN dbo.Un_Cotisation Ct ON Ct.UnitID = U.UnitID
        JOIN dbo.Un_Oper O ON O.OperID = Ct.OperID
        GROUP BY U.ConventionID, O.OperTypeID
    ),
    -- Il n’a pas d’historique de retour de paiement (chèque sans fond et DPA) 
    CTE_SouscripteurNSF AS (
        SELECT DISTINCT C.SubscriberID
        FROM CTE_SouscripteurConvention C
        JOIN CTE_SouscripteurCotisation Ct ON Ct.ConventionID = C.ConventionID
        WHERE Ct.OperTypeID IN ('NSF', 'RES')
    ),
    /*CTE_SouscripteurArretConv AS (
        SELECT DISTINCT C.SubscriberID
        FROM CTE_SouscripteurConvention C
        JOIN Un_Breaking Br ON Br.ConventionID = C.ConventionID
    ),
    CTE_SouscripteurArretUnit AS (
        SELECT DISTINCT C.SubscriberID
        FROM CTE_SouscripteurConvention C
        JOIN  (
            SELECT U.ConventionID
            FROM CTE_SouscripteurConvention C 
            JOIN Un_Unit U ON U.ConventionID = C.ConventionID
            JOIN dbo.Un_UnitHoldPayment UHP ON UHP.UnitID = U.UnitID
            GROUP BY U.ConventionID
            HAVING COUNT(*) > 0
            ) UHP ON UHP.ConventionID = C.ConventionID
    ),*/
    --  Bénéficiaires de 16-17 ans
    CTE_Beneficiaire1617 AS (
        SELECT B.BeneficiaryID, B.Date_16ans_Benef
        FROM CTE_Beneficiaire B
        WHERE B.Age_Benef_31Dec BETWEEN 16 AND 17
    ),
    --  Bénéficiaires de 16-17 ans - Validation des cotisations
    CTE_Beneficiaire1617Cotisation AS (
        SELECT 
            C.BeneficiaryID,
            Ans = YEAR(CT.EffectDate),
            CotisationFraisSolde = SUM(CT.Cotisation + CT.Fee)
        FROM CTE_Beneficiaire1617 B
        JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
        JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
        JOIN dbo.Un_Cotisation CT ON U.UnitID = CT.UnitID
        JOIN dbo.Un_Oper O ON CT.OperID = O.OperID
        LEFT JOIN dbo.Un_OperCancelation OCS ON OCS.OperSourceID = O.OperID
        LEFT JOIN dbo.Un_OperCancelation OC ON OC.OperID = O.OperID
        WHERE CT.EffectDate <= B.Date_16ans_Benef
            AND OCS.OperID IS NULL
            AND OC.OperID IS NULL
        GROUP BY 
            C.BeneficiaryID, 
            YEAR(CT.EffectDate)
    ),
    -- Bénéficiaires de 16-17 ans qui passent les validation sur les cotisations
    CTE_Beneficiaire1617CotisationMinimale AS (
        SELECT DISTINCT B.BeneficiaryID
        FROM (
            -- Liste des bénéficiaire ayant au moins 4 années de 100$ et que la solde est d'au moins 400$ avant 16 ans
            SELECT B100.BeneficiaryID
            FROM (
                SELECT
                    CF.BeneficiaryID
                FROM CTE_Beneficiaire1617Cotisation CF
                WHERE CF.CotisationFraisSolde >= 100
                GROUP BY CF.BeneficiaryID
                HAVING COUNT(CF.BeneficiaryID) >= 4
                ) B100
            JOIN (
                SELECT
                    CF.BeneficiaryID
                FROM CTE_Beneficiaire1617Cotisation CF
                GROUP BY CF.BeneficiaryID
                HAVING SUM(CF.CotisationFraisSolde) >= 400
                ) T100 ON T100.BeneficiaryID = B100.BeneficiaryID
            UNION ALL 
            -- Liste des bénéficiaires ayant au moins 2000$ avant 16 ans
            SELECT 
                CF.BeneficiaryID
            FROM CTE_Beneficiaire1617Cotisation CF
            GROUP BY CF.BeneficiaryID
            HAVING SUM(CF.CotisationFraisSolde) >= 2000
            ) B
    ),
    -- Bénéficiaires ayant eu au moins un RIN
    CTE_BeneficiaireRIN AS (
        SELECT DISTINCT B.BeneficiaryID
        FROM CTE_Beneficiaire B 
        JOIN Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
        JOIN Un_Unit U ON U.ConventionID = C.ConventionID
        JOIN dbo.Un_Cotisation CT ON U.UnitID = CT.UnitID
        JOIN dbo.Un_Oper O ON CT.OperID = O.OperID
        LEFT JOIN dbo.Un_OperCancelation OCS ON OCS.OperSourceID = O.OperID
        LEFT JOIN dbo.Un_OperCancelation OC ON OC.OperID = O.OperID
        WHERE O.OperTypeID = 'RIN'
            AND OCS.OperID IS NULL
            AND OC.OperID IS NULL
    )
    SELECT 
        C.ConventionID, C.ConventionNo,
        C.SubscriberID, S.Age_Sousc, S.RepID, 
        C.BeneficiaryID, B.Age_Benef_31Dec, B.Date_16ans_Benef,
        LimiteMaximisation = CASE WHEN B.LimiteMaximisation < 36000 THEN B.LimiteMaximisation ELSE 36000 END,
        tiMaximisationREEE = C.tiMaximisationREEE,
        --ConventionEligibleMaximisation,
        ConventionEligiblePret =  CASE 
                                      WHEN S.Age_Sousc >= 60 THEN 0
                                      WHEN B.Age_Benef_31Dec > 16 THEN 0
                                      WHEN SS.dtSignature > DATEADD(YEAR, -7, GETDATE()) THEN 0
                                      WHEN SNSF.SubscriberID IS NOT NULL THEN 0
                                      --WHEN SAC.SubscriberID IS NOT NULL THEN 0
                                      --WHEN SAU.SubscriberID IS NOT NULL THEN 0
									  WHEN SA.iID_Province != 34 THEN 0 -- Le souscripteur doit être résident du Québec
                                      ELSE 1
                                    END
    INTO #tConvention
    FROM CTE_ConventionREE C 
    JOIN CTE_Souscripteur S ON S.SubscriberID = C.SubscriberID
    JOIN CTE_Beneficiaire B ON B.BeneficiaryID = C.BeneficiaryID
    JOIN fntGENE_ObtenirAdresseEnDate_PourTous(NULL, NULL, NULL, NULL) SA ON SA.iID_Source = S.SubscriberID AND SA.cType_Source = 'H'
    JOIN fntGENE_ObtenirAdresseEnDate_PourTous(NULL, NULL, NULL, NULL) BA ON BA.iID_Source = B.BeneficiaryID AND BA.cType_Source = 'H'
    LEFT JOIN CTE_SouscripteurSignature SS ON SS.SubscriberID = C.SubscriberID
    LEFT JOIN CTE_SouscripteurNSF SNSF ON SNSF.SubscriberID = C.SubscriberID
    --LEFT JOIN CTE_SouscripteurArretConv SAC ON SAC.SubscriberID = C.SubscriberID
    --LEFT JOIN CTE_SouscripteurArretUnit SAU ON SAU.SubscriberID = C.SubscriberID
    LEFT JOIN CTE_Beneficiaire1617 B1617 ON B1617.BeneficiaryID = B.BeneficiaryID
    LEFT JOIN CTE_Beneficiaire1617CotisationMinimale B1617CM ON B1617CM.BeneficiaryID = B1617.BeneficiaryID
    LEFT JOIN CTE_BeneficiaireRIN RIN ON RIN.BeneficiaryID = C.BeneficiaryID
    WHERE SA.cID_Pays = 'CAN' -- Le souscripteur doit être résident Canadien
        AND SA.iID_Province IN (28, 34) -- Le souscripteur doit être résident du Québec ou du Nouveau-Brunswick
        AND BA.cID_Pays = 'CAN' -- Le bénéficiaire doit être résident Canadien     
        AND (B.Age_Benef_31Dec BETWEEN 12 AND 15 -- Le bénéficiaire a entre 12 et 15 ans 
            OR (B1617.BeneficiaryID IS NOT NULL AND B1617CM.BeneficiaryID IS NOT NULL)) -- ou 16 ans ou 17 ans, et a au moins 2000$ ou 4 années de 100$
        AND RIN.BeneficiaryID IS NULL -- Pas de RIN versé à ce bénéficiaire
       
    --PRINT 'Liste des bénéficiaires'

    -- Liste des bénéficiaires
    SELECT DISTINCT
        C.BeneficiaryID, 
        C.LimiteMaximisation,
        CotisationFraisSolde = CAST(0 AS MONEY), 
        CotisationFraisFutur = CAST(0 AS MONEY)
    INTO #tBeneficiaireMaximisation
    FROM #tConvention C

    --PRINT 'Liste des groupes d''unités des bénéficiaires avec le solde des cotisations et des frais'

    -- Liste des groupes d'unités des bénéficiaires avec le solde des cotisations et des frais
    SELECT DISTINCT
        TB.BeneficiaryID,
        U.UnitID,
        U.UnitQty,
        U.InForceDate,
        CN.FirstPmtDate,
        M.PmtQty,
        M.PmtByYearID,
        M.PmtRate,
        DernierDepot = @Au31DecembreAnneeEnCour,
        CotisationFraisSolde = ISNULL(CF.TotalCotisation + CF.TotalFee, 0),
        CotisationFraisFutur = CAST(0 AS MONEY)
    INTO #tUnit
    FROM #tBeneficiaireMaximisation TB
    JOIN dbo.Un_Convention CN ON CN.BeneficiaryID = TB.BeneficiaryID
    JOIN dbo.Un_Unit U ON U.ConventionID = CN.ConventionID
    JOIN dbo.Un_Modal M ON M.ModalID = U.ModalID
    LEFT JOIN dbo.fntCONV_CalculerCotisationAndFeeByBeneficiary(GETDATE(), DEFAULT) CF ON CF.UnitID = U.UnitID

    -- Va chercher la date de dernier dépôt de chaque groupe d'unités
    UPDATE #tUnit
    SET DernierDepot = dbo.fn_Un_LastDepositDate(InForceDate, FirstPmtDate, PmtQty, PmtByYearID)

    -- Va chercher les dépôts futurs pour chaque groupe d'unités à la date du dernier dépôt, lorsque la date du dernier dépôt est dans l'année
    UPDATE #tUnit
    SET CotisationFraisFutur = dbo.FN_UN_EstimatedCotisationAndFee(GETDATE(), DernierDepot, DAY(FirstPmtDate), UnitQty, PmtRate, PmtByYearID, PmtQty, InForceDate)
    WHERE DernierDepot BETWEEN DATEADD(DAY, 1, GETDATE()) AND @Au31DecembreAnneeEnCour
    
    -- Va chercher les dépôts futurs pour chaque groupe d'unités au 31 décembre, lorsque la date du dernier dépôt est supérieure au 31 décembre
    UPDATE #tUnit
    SET CotisationFraisFutur = dbo.FN_UN_EstimatedCotisationAndFee(GETDATE(), @Au31DecembreAnneeEnCour, DAY(FirstPmtDate), UnitQty, PmtRate, PmtByYearID, PmtQty, InForceDate)
    WHERE DernierDepot > @Au31DecembreAnneeEnCour
    
    ;WITH CTE_BeneficiaireCotisation AS (
        SELECT
            BeneficiaryID,
            CotisationFraisSolde = SUM(CotisationFraisSolde),
            CotisationFraisFutur = SUM(CotisationFraisFutur)
        FROM #tUnit
        GROUP BY BeneficiaryID
        )
        UPDATE TB SET 
            CotisationFraisSolde = ISNULL(F.CotisationFraisSolde, 0), 
            CotisationFraisFutur = ISNULL(F.CotisationFraisFutur, 0)
        FROM #tBeneficiaireMaximisation TB
        JOIN CTE_BeneficiaireCotisation F ON F.BeneficiaryID = TB.BeneficiaryID

    --PRINT 'Limite'

    SELECT
        C.ConventionID,
        C.ConventionNo,
        C.SubscriberID,
        C.RepID,
        C.Age_Sousc,
        C.BeneficiaryID,
        C.Age_Benef_31Dec,
        C.Date_16ans_Benef,
        C.LimiteMaximisation,
        mMaximisation_MontantDisponible = BM.LimiteMaximisation - (BM.CotisationFraisSolde + BM.CotisationFraisFutur),
        C.tiMaximisationREEE,
        C.ConventionEligiblePret
    INTO #tConventionMaximisable
    FROM #tBeneficiaireMaximisation BM
    JOIN #tConvention C ON C.BeneficiaryID = BM.BeneficiaryID
    WHERE BM.LimiteMaximisation > BM.CotisationFraisSolde + BM.CotisationFraisFutur

    IF @bEnregistrerValeurs = 1 
        AND @BeneficiaryID IS NULL 
        AND @SubscriberID IS NULL 
        AND @RepID IS NULL 
        AND @EnDateDu = CAST(GETDATE() AS DATE) 
    BEGIN 
        --PRINT 'Mise à jour des infos'
        -- Mettre à jour les conventions
    /*
        SELECT 
            C.ConventionID,
            C.bEstMaximisable,
            C.bEstEligiblePret,
            bEstMaximisable = CASE WHEN ISNULL(CM.ConventionID, 0) <> 0 THEN 1 ELSE 0 END,
            bEstEligiblePret = ISNULL(CM.ConventionEligiblePret, 0)
        FROM dbo.Un_Convention C
        LEFT JOIN #tConventionMaximisable CM ON CM.ConventionID = C.ConventionID
        WHERE C.bEstMaximisable <> CASE WHEN ISNULL(CM.ConventionID, 0) <> 0 THEN 1 ELSE 0 END
            OR C.bEstEligiblePret <> ISNULL(CM.ConventionEligiblePret, 0)
    */
        -- Désactiver les triggers sur Un_convention
        IF object_id('tempdb..#DisableTrigger') IS NULL
    	    CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
    
        INSERT INTO #DisableTrigger VALUES('TR_U_Un_Convention_F_dtRegStartDate')	
        INSERT INTO #DisableTrigger VALUES('TUn_Convention')	
        INSERT INTO #DisableTrigger VALUES('TUn_Convention_State')	
        INSERT INTO #DisableTrigger VALUES('TUn_Convention_YearQualif')	
    
        UPDATE C SET
            bEstMaximisable = CASE WHEN ISNULL(CM.ConventionID, 0) <> 0 THEN 1 ELSE 0 END,
            bEstEligiblePret = ISNULL(CM.ConventionEligiblePret, 0)
        FROM dbo.Un_Convention C
        LEFT JOIN #tConventionMaximisable CM ON CM.ConventionID = C.ConventionID
        WHERE C.bEstMaximisable <> CASE WHEN ISNULL(CM.ConventionID, 0) <> 0 THEN 1 ELSE 0 END
            OR C.bEstEligiblePret <> ISNULL(CM.ConventionEligiblePret, 0)

        DELETE FROM #DisableTrigger WHERE vcTriggerName LIKE 'TR_U_Un_Convention_F_dtRegStartDate'
        DELETE FROM #DisableTrigger WHERE vcTriggerName LIKE 'TUn_Convention'
        DELETE FROM #DisableTrigger WHERE vcTriggerName LIKE 'TUn_Convention_State'
        DELETE FROM #DisableTrigger WHERE vcTriggerName LIKE 'TUn_Convention_YearQualif'
   
   
        -- Mettre à jour les bénéficiaires
    /*
        SELECT 
            B.BeneficiaryID,
            B.mMaximisation_Limite,
            B.mMaximisation_MontantDisponible,
            mMaximisation_Limite = ISNULL(BM.LimiteMaximisation,0),
            mMaximisation_MontantDisponible = ISNULL(BM.LimiteMaximisation, 0) - (ISNULL(BM.CotisationFraisSolde, 0) + ISNULL(BM.CotisationFraisFutur, 0))
        FROM Un_Beneficiary B 
        LEFT JOIN #tBeneficiaireMaximisation BM ON BM.BeneficiaryID = B.BeneficiaryID
        WHERE ISNULL(B.mMaximisation_Limite, 0) <> ISNULL(BM.LimiteMaximisation, 0)
            OR ISNULL(B.mMaximisation_MontantDisponible, 0) <> ISNULL(BM.LimiteMaximisation, 0) - (ISNULL(BM.CotisationFraisSolde, 0) + ISNULL(BM.CotisationFraisFutur, 0))
    */
        -- Désactiver les triggers sur Un_convention
        INSERT INTO #DisableTrigger VALUES('TUn_Beneficiary')	
    
        UPDATE B SET 
            mMaximisation_Limite = ISNULL(BM.LimiteMaximisation,0),
            mMaximisation_MontantDisponible = ISNULL(BM.LimiteMaximisation, 0) - (ISNULL(BM.CotisationFraisSolde, 0) + ISNULL(BM.CotisationFraisFutur, 0))
        FROM Un_Beneficiary B 
        LEFT JOIN #tBeneficiaireMaximisation BM ON BM.BeneficiaryID = B.BeneficiaryID
        WHERE ISNULL(B.mMaximisation_Limite, 0) <> ISNULL(BM.LimiteMaximisation, 0)
            OR ISNULL(B.mMaximisation_MontantDisponible, 0) <> ISNULL(BM.LimiteMaximisation, 0) - (ISNULL(BM.CotisationFraisSolde, 0) + ISNULL(BM.CotisationFraisFutur, 0))

        DELETE FROM #DisableTrigger WHERE vcTriggerName LIKE 'TUn_Beneficiary'
    END   
    ELSE 
    BEGIN 
        SELECT 
            C.ConventionID,
            C.SubscriberID,
            C.BeneficiaryID,
            C.RepID,
            C.Age_Benef_31Dec,
            C.mMaximisation_MontantDisponible,
            C.tiMaximisationREEE,
            C.ConventionEligiblePret    
        FROM #tConventionMaximisable C    
    END 

    DROP TABLE #tConvention
    DROP TABLE #tUnit
    DROP TABLE #tConventionMaximisable
    DROP TABLE #tBeneficiaireMaximisation

END