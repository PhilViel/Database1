/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service     :   fntCONV_ObtenirRevenusCohorte
Nom du service		: 
But 				:   Permet d'obtenir les valeurs en revenus des différentes cohortes à une date donnée
Description		    :   Cette fonction est appelée à chaque fois qu'il est nécesaire d'obtenir les revenus d'une cohorte
Facette			    :   CONV
Référence			: 

Paramètres d’entrée	:	Paramètre					Obligatoire	Description
					    --------------------------	-----------	-----------------------------------------------------------------
					    @dDate_Effective			Oui			Date à laquelle nous souhaitons obtenir les valeurs (Date du jour si NULL)

Exemple d'appel : 
        -- Obtenir la liste
        SELECT * FROM dbo.fntCONV_ObtenirRevenusCohorte(GETDATE())
        -- Obtenir les valeurs pour une sélection de convention
        SELECT 
            C.ConventionID,
            C.ConventionNo,
            C.YearQualif,
            RC.* 
         FROM Un_Convention C 
         JOIN Un_Plan P ON P.PlanID = C.PlanID
         JOIN dbo.fntCONV_ObtenirRevenusCohorte(GETDATE()) RC 
                            ON RC.iID_Regroupement_Regime = P.iID_Regroupement_Regime
                                AND (RC.YearQualif = C.YearQualif
                                    -- Si année de qualif est > que le max prévu, on prend le max
                                    OR (C.YearQualif > RC.iDerniere_AnneeQualif AND RC.YearQualif = RC.iDerniere_AnneeQualif) 
                                    -- Si année de qualif est < que le min prévu, on prend le min
                                    OR (C.YearQualif < RC.iPremiere_AnneeQualif AND RC.YearQualif = RC.iPremiere_AnneeQualif)
                                    )
        WHERE C.SubscriberID = 601617
        
Historique des modifications:
        Date        Programmeur			    Description						Référence
        ----------  ------------------      ---------------------------  	------------
        2017-11-30  Pierre-Luc Simard       Création de la fonction		
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirRevenusCohorte]
(
	@dDate_Effective DATE
)
RETURNS TABLE AS
RETURN (
    SELECT 
        RC.dDate_Effective,
        RC.iID_Regroupement_Regime,
        RC.YearQualif, 
        RCY.iPremiere_AnneeQualif,
        RCY.iDerniere_AnneeQualif,
        RC.mRevenus_Cohorte,
        RC.mQuantite_Unite,
        RC.mRevenu_CohorteParUnite        
    FROM tblCONV_RevenusCohorte RC
    JOIN (
        SELECT
            RCD.dDerniereDate,
            iID_Regroupement_Regime,
            iPremiere_AnneeQualif = MIN(RC.YearQualif),
            iDerniere_AnneeQualif = MAX(RC.YearQualif)
        FROM tblCONV_RevenusCohorte RC
        JOIN (
            SELECT dDerniereDate = MAX(RC.dDate_Effective) 
            FROM tblCONV_RevenusCohorte RC
            WHERE RC.dDate_Effective <= @dDate_Effective
            ) RCD ON RCD.dDerniereDate = RC.dDate_Effective
        GROUP BY 
            iID_Regroupement_Regime, 
            RCD.dDerniereDate
        ) RCY ON RCY.dDerniereDate = RC.dDate_Effective AND RCY.iID_Regroupement_Regime = RC.iID_Regroupement_Regime
)