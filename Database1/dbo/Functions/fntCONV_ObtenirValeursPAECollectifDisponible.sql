/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service     :   fntCONV_ObtenirValeursPAECollectifDisponible
Nom du service		: 
But 				:   Permet d'obtenir les valeurs admissibles à un PAE pour un régime collectif 
Description		    :   Cette fonction est appelée à chaque fois qu'il est nécesaire d'obtenir le nombre d'unités converties admissibles à un PAE,
                        la ristourne et la quote-part
Facette			    :   CONV
Référence			: 

Paramètres d’entrée	:	Paramètre					Obligatoire	Description
					    --------------------------	-----------	-----------------------------------------------------------------
					    @iConventionID				Non			ID de la convention pour laquelle on veut les valeurs, par défaut, pour tous

Exemple d'appel : 
        SELECT * FROM dbo.fntCONV_ObtenirValeursPAECollectifDisponible(138407)
        SELECT * FROM dbo.fntCONV_ObtenirValeursPAECollectifDisponible(NULL) -- Pour tous
        
Historique des modifications:
        Date        Programmeur			    Description						Référence
        ----------  ------------------      ---------------------------  	------------
        2017-11-30  Pierre-Luc Simard       Création de la fonction		
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirValeursPAECollectifDisponible]
(
	@iConventionID INT = NULL
)
RETURNS TABLE AS
RETURN (
    WITH CTE_Conv AS (
        SELECT 
            C.ConventionID,
            C.ConventionNo,
            C.PlanID,
            NB_Unites_Convention = UD.UnitQty,
            UD.bRIN_Verse,
            UD.Depot,
            UD.UnitQty,
            UD.MontantSouscrit,
            UD.Taux_Avancement,
            NB_Unites_PAE_Verse = UD.mQuantite_UniteDemande,
            NB_Unites_Disponibles_PAE = UD.Unites_Disponibles_PAE
        FROM dbo.Un_Convention C
        JOIN dbo.fntCONV_ObtenirQuantiteUniteDisponiblePAE(@iConventionID) UD ON UD.ConventionID = C.ConventionID
        JOIN dbo.fntCONV_ObtenirConventionAdmissiblePAE(@iConventionID) CA  ON CA.ConventionID = C.ConventionID
        WHERE C.ConventionID = ISNULL(@iConventionID, C.ConventionID)
          AND C.PlanID <> 4
    ),
    CTE_Cohorte AS (
        -- Dernière valeur unitaire saisie pour chacun des plans collectifs
        SELECT 
            P.PlanID,
            P.Row_Num,
            P.UnitValue,
            P.ScholarshipYear
        FROM (
            SELECT 
	            PV.PlanID,
                Row_Num = ROW_NUMBER() OVER(PARTITION BY PV.PlanID ORDER BY PV.ScholarshipYear DESC),
                PV.UnitValue,
                PV.ScholarshipYear
            FROM Un_PlanValues PV
            JOIN Un_Plan P ON P.PlanID = PV.PlanID
            WHERE P.PlanTypeID = 'COL'
                AND PV.ScholarshipNo = 0
            ) P 
        WHERE P.Row_Num = 1
    ) 
    SELECT 
        TC.ConventionID,
        TC.ConventionNo,
        TC.NB_Unites_Convention,
        TC.bRIN_Verse,
        TC.Depot,
        TC.MontantSouscrit,
        TC.Taux_Avancement,
        TC.NB_Unites_PAE_Verse,
        TC.NB_Unites_Disponibles_PAE,
        U.Nb_Unites_Disponibles_PAE_Convertie,
        U.RistourneAss,
        QuotePart = CAST((U.Nb_Unites_Disponibles_PAE_Convertie * PC.UnitValue) AS DECIMAL(10,2))   
    --FROM #tConv TC 
    FROM CTE_Conv TC
    JOIN dbo.Un_Convention C ON C.ConventionID = TC.ConventionID
    --JOIN #tPlanCohorte PC ON PC.PlanID = C.PlanID
    JOIN CTE_Cohorte PC ON PC.PlanID = C.PlanID
    JOIN (
	    SELECT 
	        TC.ConventionID,
	        NB_Unites_Disponibles_PAE = CAST(SUM(CASE WHEN TC.NB_Unites_Convention = 0 THEN 0 ELSE ((TC.NB_Unites_Disponibles_PAE / TC.NB_Unites_Convention) * U.UnitQty) END) AS DECIMAL(10,3)),
	        Nb_Unites_Disponibles_PAE_Convertie = CAST(SUM((CASE WHEN TC.NB_Unites_Convention = 0 THEN 0 ELSE ((TC.NB_Unites_Disponibles_PAE / TC.NB_Unites_Convention) * U.UnitQty) END) * dbo.fnCONV_ObtenirFacteurConversion(TC.PlanID, M.ModalDate, U.SignatureDate, U.InForceDate)) AS DECIMAL(10,3)),
	        RistourneAss = CAST(SUM((CASE WHEN TC.NB_Unites_Convention = 0 THEN 0 ELSE ((TC.NB_Unites_Disponibles_PAE / TC.NB_Unites_Convention) * U.UnitQty) END) * dbo.fnCONV_ObtenirRistourneAssurance(U.ModalID, U.WantSubscriberInsurance, U.SignatureDate, U.InForceDate)) AS DECIMAL(10,2))--AS MONEY)  
        FROM CTE_Conv TC 
            JOIN dbo.Un_Unit U ON U.ConventionID = TC.ConventionID
            JOIN Un_Modal M ON M.ModalID = U.ModalID
        WHERE U.TerminatedDate IS NULL -- Non résilié   
            AND ISNULL(U.ActivationConnectID, 0) <> 0 -- Activé
        GROUP BY TC.ConventionID
        ) U ON U.ConventionID = C.ConventionID
)