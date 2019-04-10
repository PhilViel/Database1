/****************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc
Code du service        :    psIQEE_RapportIQEE_A_Recevoir_Sommaire
But                 :    Rapport sommaire mensuel de l'IQEE à recevoir
Valeurs de retour   :    Dataset de données
Facette                :   IQÉÉ

Paramètres d’entrée    :    Aucun

Exemple d’appel        :    EXECUTE [dbo].[psIQEE_RapportIQEE_A_Recevoir_Sommaire] 

Paramètres de sortie:    Aucun

Historique des modifications:
    Date        Programmeur             Description                                
    ----------  --------------------    -----------------------------------------
    2014-09-02  Stéphane Barbeau        Création du service                            
    2015-03-31  Stéphane Barbeau        Ajout de dtDate_Fin_ARecevoir dans le Dataset afin d'ajouter la date dans l'entête du rapport.
    2016-04-05  Steeve Picard           Filtrer les doublons à l'aide de la fonction Row_Number()
    2017-04-21  Steeve Picard           Utilisation des nouvelles tables «tblIQEE_Estimer_ARecevoir & tblIQEE_Estimer_APayer»
********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_RapportIQEE_A_Recevoir_Sommaire
AS BEGIN
    IF Object_ID('tempDB..#tblIQEE_Sommaire_RegimeCohorte') IS NOT NULL
        DROP TABLE #tblIQEE_Sommaire_RegimeCohorte

    CREATE TABLE #tblIQEE_Sommaire_RegimeCohorte
    (
        iID_Plan INT NOT NULL,
        siAnnee_Cohorte SMALLINT NULL,
        mCBQ_Estime_ARecevoir MONEY NOT NULL,  
        mMMQ_Estime_ARecevoir MONEY NOT NULL,  
        mCBQ_Estime_APayer MONEY NOT NULL,  
        mMMQ_Estime_APayer MONEY NOT NULL,  
        mTotalEstimation MONEY NOT NULL,
        dtDate_Fin_ARecevoir DATE NOT NULL
    )   

    -- IQEE A recevoir des demandes de subventions (T02)
    INSERT INTO #tblIQEE_Sommaire_RegimeCohorte
    SELECT iID_Plan, 
           siAnnee_Cohorte, 
           isNULL(sum(mCreditBase_Estime),0), 
           isNULL(sum(mMajoration_Estime),0) ,
           0,
           0,
           sum(mTotal_Estime),
           dtFin_ARecevoir
      FROM dbo.tblIQEE_Estimer_ARecevoir
     WHERE mCreditBase_Estime <> 0
        OR mMajoration_Estime <> 0
     GROUP BY iID_Plan, siAnnee_Cohorte, dtFin_ARecevoir
     ORDER BY iID_Plan, siAnnee_Cohorte

    --IQEE à payer par les impôts spéciaux (T06)
    INSERT INTO #tblIQEE_Sommaire_RegimeCohorte
    SELECT iID_Plan, 
           siAnnee_Cohorte, 
           0,
           0,
           sum(mCreditBase_Estime), 
           sum(mMajoration_Estime), 
           sum(mTotal_Estime),
           dtFin_APayer
      FROM dbo.tblIQEE_Estimer_APAyer
     WHERE mCreditBase_Estime <> 0
        OR mMajoration_Estime <> 0
     GROUP BY iID_Plan, siAnnee_Cohorte, dtFin_APayer
     ORDER BY iID_Plan, siAnnee_Cohorte

    UPDATE TB SET siAnnee_Cohorte = 0 
      FROM #tblIQEE_Sommaire_RegimeCohorte TB
           JOIN dbo.Un_Plan P ON P.PlanID = TB.iID_Plan
     WHERE P.PlanTypeID = 'IND'

    -- Requête finale
    SELECT
        P.PlanDesc
        ,SRC.siAnnee_Cohorte 
        ,isnull(SUM(SRC.mCBQ_Estime_ARecevoir ),0) as 'CréditBaseARecevoir'
        ,isnull(SUM(SRC.mMMQ_Estime_ARecevoir ),0)  as 'MajorationARecevoir' 
        ,isnull(SUM(SRC.mCBQ_Estime_APayer ),0) as 'CréditBaseAPayer'
        ,isnull(SUM(SRC.mMMQ_Estime_APayer ),0)  as 'MajorationAPayer' 
        ,isnull(SUM(SRC.mCBQ_Estime_ARecevoir + SRC.mMMQ_Estime_ARecevoir +SRC.mCBQ_Estime_APayer +SRC.mMMQ_Estime_APayer ),0) as 'TotalNet' 
        ,SRC.dtDate_Fin_ARecevoir as 'DateFinEstimation'        
    FROM #tblIQEE_Sommaire_RegimeCohorte    SRC 
         JOIN Un_Plan P ON P.PlanID = SRC.iID_Plan AND P.PlanID <> 11
    GROUP BY P.PlanDesc, SRC.siAnnee_Cohorte, SRC.dtDate_Fin_ARecevoir        
    Order BY P.PlanDesc, SRC.siAnnee_Cohorte
END
