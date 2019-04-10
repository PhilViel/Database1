/****************************************************************************************************
Code de service		:		psGENE_VenteUniteBruteEtNette_PourTableaudeBord
Nom du service		:		psGENE_VenteUniteBruteEtNette_PourTableaudeBord
But					:		Pour le tableau de bord
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@dtStartDate				Début de la période
						@dtEndDate					Fin de la période

Exemple d'appel:
						 EXEC psGENE_VenteUniteBruteEtNette_PourTableaudeBord 
						 @dtStartDate = '2018-01-01', 
						 @dtEndDate = '2018-04-30'
                
						DROP PROC psGENE_VenteUniteBruteEtNette_PourTableaudeBord

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2018-05-08					Donald Huppé							Création du Service
						2018-05-14					Donald Huppé							Ratio : Nouvelle condition si solde unité à la fin = 0
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_VenteUniteBruteEtNette_PourTableaudeBord] 
--(
--	@dtStartDate DATETIME,
--	@dtEndDate DATETIME
--	)


AS
BEGIN

	SET ARITHABORT ON

DECLARE
	@dtStartDate DATETIME = '2018-01-01',
	@dtEndDate DATETIME = '2018-04-30'
    /*
	create table TMP_GrossANDNetUnits (
		UnitID_Ori INTEGER,
		UnitID INTEGER,
		RepID INTEGER,
		Recrue INTEGER,
		BossID INTEGER,
		RepTreatmentID INTEGER,
		RepTreatmentDate DATETIME,
		Brut FLOAT,
		Retraits FLOAT,
		Reinscriptions FLOAT,
		Brut24 FLOAT,
		Retraits24 FLOAT,
		Reinscriptions24 FLOAT) 

	-- Les données des Rep
	INSERT TMP_GrossANDNetUnits 
	EXEC SL_UN_RepGrossANDNetUnits 
		@ReptreatmentID = NULL,
		@StartDate = @dtStartDate,
		@EndDate = @dtEndDate,
		@RepID = 0,
		@ByUnit = 1 
        */


/*
-Unités brutes 2018
 -Unités brutes 2017
 -% variations 2018/2017
 -Unité nettes 2018
 -Unité nettes 2017
 -% variations 2018/2017
 -Unités brutes 2018 - représentants actifs au 1er janvier 2018
 -Unités brutes 2017 - représentants actifs au 1er janvier 2018
 -% variations 2018/2017
 -Unités nettes 2018 - représentants actifs au 1er janvier 2018
 -Unités nettes 2017 - représentants actifs au 1er janvier 2018
 -% variations 2018/2017
 -Unités brutes recrues 2018 - représentants actifs depuis le 1er janvier 2018
 -Unités nettes recrues 2018 - représentants actifs depuis le 1er janvier 2018
*/


	SELECT 

		 BrutTotal = SUM(brut)
		,NetTotal =  SUM(Brut - Retraits + Reinscriptions)

		,ActifAu1erJanvier_Brut =		 SUM(CASE WHEN r.BusinessStart <  @dtStartDate AND ISNULL(r.BusinessEnd ,'9999-12-31') > @dtStartDate THEN Brut								ELSE 0 END)
		,ActifAu1erJanvier_Net =		 SUM(CASE WHEN r.BusinessStart <  @dtStartDate AND ISNULL(r.BusinessEnd ,'9999-12-31') > @dtStartDate THEN Brut - Retraits + Reinscriptions	ELSE 0 END)

		,ActifDepuis1erJanvier_Brut =	 SUM(CASE WHEN r.BusinessStart >= @dtStartDate AND ISNULL(r.BusinessEnd ,'9999-12-31') > @dtStartDate THEN Brut								ELSE 0 END)
		,ActifDepuis1erJanvier_Net =	 SUM(CASE WHEN r.BusinessStart >= @dtStartDate AND ISNULL(r.BusinessEnd ,'9999-12-31') > @dtStartDate THEN Brut - Retraits + Reinscriptions	ELSE 0 END)

		,Recrue_Brut =					 SUM(CASE WHEN R.BusinessStart BETWEEN @dtStartDate AND @dtEndDate									  THEN Brut								ELSE 0 END)
		,Recrue_Net =					 SUM(CASE WHEN R.BusinessStart BETWEEN @dtStartDate AND @dtEndDate									  THEN Brut - Retraits + Reinscriptions	ELSE 0 END)


		,MartinMercier_Net=				 SUM(CASE WHEN br.BossID = 149593 THEN Brut - Retraits + Reinscriptions ELSE 0 END)
		,ClementBlais_Net=				 SUM(CASE WHEN br.BossID = 149489 THEN Brut - Retraits + Reinscriptions ELSE 0 END)
		,MichelMaheu_Net=				 SUM(CASE WHEN br.BossID = 149521 THEN Brut - Retraits + Reinscriptions ELSE 0 END)
		,SophieBabeux_Net=				 SUM(CASE WHEN br.BossID = 436381 THEN Brut - Retraits + Reinscriptions ELSE 0 END)

		,AutreAgence_Net=				 SUM(CASE WHEN br.BossID not in (149593,149489,149521,436381) THEN Brut - Retraits + Reinscriptions ELSE 0 END)
		
	FROM 
		TMP_GrossANDNetUnits gnu
        --#GrossANDNetUnits gnu
		JOIN Un_Rep r on r.RepID = gnu.RepID
		JOIN (
			SELECT
				RB.RepID,
				BossID = MAX(BossID)
			FROM 
				Un_RepBossHist RB
				JOIN (
					SELECT
						RepID,
						RepBossPct = MAX(RepBossPct)
					FROM 
						Un_RepBossHist RB
					WHERE 
						RepRoleID = 'DIR'
						AND StartDate IS NOT NULL
						AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
						AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)) 
					GROUP BY
							RepID
					) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
				WHERE RB.RepRoleID = 'DIR'
					AND RB.StartDate IS NOT NULL
					AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
					AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10))
				GROUP BY
					RB.RepID
		)BR ON BR.RepID = gnu.RepID
		JOIN Mo_Human hb on hb.HumanID = br.BossID

SET ARITHABORT OFF	
		
END