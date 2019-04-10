/********************************************************************************************************************
Copyrights (c) 2015 Gestion Universitas inc
Nom                 :	psREPR_RapportCommissionSurActif
Description         :	Pour le rapport SSRS "RapCommSurActifComptable" : permet d'obtenir les commissions sur l'actif
						pour les représentants pour un mois choisi.
Valeurs de retours  :	Dataset 
Note                :	2016-06-01	Maxime Martel			Création
						2016-10-11	Donald Huppé			Jira ti-4769 : Ajout de GroupeAPart et changer NumeroRep en INT
                        2017-06-12  Pierre-Luc Simard       Ajout des commissions de suivi

exec psREPR_RapportCommissionSurActif '2017-04-30', 'Code'

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_RapportCommissionSurActif]
(
	@StartDate DATETIME,
	@Tri varchar(5) -- 'Code' = Code du Rep, 'Nom' = Nom de famille du rep
)
AS
BEGIN
	DECLARE 
		@dtdateCalcul DATETIME = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,@StartDate))-1),DATEADD(mm,1,@StartDate)),101)
	
    PRINT @dtdateCalcul	
 	
    ;WITH CTE_COMM AS (
        SELECT 
		    CSA.RepID,
		    SommeCommActif = SUM(CSA.mMontant_ComActif),
            SommeCommSuivi = 0 
	    FROM VtblREPR_CommissionsSurActif_Conv CSA
	    WHERE MONTH(@dtdateCalcul) = MONTH(CSA.dDate_Calcul) 
	 	    AND YEAR(@dtDateCalcul) = YEAR(CSA.dDate_Calcul)
        GROUP BY CSA.RepID
		    
        UNION 

        SELECT 
            CS.RepID,
		    SommeCommActif = 0,
		    SommeCommSuivi = SUM(CS.mMontant_ComActif) 
	    FROM VtblREPR_CommissionsSuivi_Conv CS
	    WHERE MONTH(@dtdateCalcul) = MONTH(CS.dDate_Calcul) 
	 	    AND YEAR(@dtDateCalcul) = YEAR(CS.dDate_Calcul)
        GROUP BY CS.RepID
	)
	SELECT 
	    PrenomRep = HR.FirstName, 
		NomRep = HR.LastName, 
		NumeroRep = CASE WHEN ISNUMERIC(R.RepCode) = 1 THEN CAST(r.RepCode AS INT) ELSE -1 END, 
		SommeCommActif = SUM(C.SommeCommActif),
        SommeCommSuivi = SUM(C.SommeCommSuivi),
		GroupeAPart = CASE WHEN R.RepCode = '6141' THEN 1 ELSE 0 END -- Pour mettre "Siege social" à part sur une autre feuille dans le rapport 
	FROM CTE_Comm C
    JOIN Un_Rep R on R.RepID = C.RepID
    JOIN Mo_Human HR ON HR.HumanID = R.RepID
    GROUP BY 
        C.RepID,
        R.RepCode,
        HR.FirstName, 
		HR.LastName
	ORDER BY 
		CASE 
			WHEN @Tri = 'Code' THEN CAST(R.RepCode AS VARCHAR(20))
			WHEN @Tri = 'Nom' THEN HR.LastName
			ELSE CAST(R.RepCode AS VARCHAR(20))
		END
END