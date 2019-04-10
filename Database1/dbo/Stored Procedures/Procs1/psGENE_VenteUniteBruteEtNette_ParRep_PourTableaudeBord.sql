
/****************************************************************************************************
Code de service		:		psGENE_VenteUniteBruteEtNette_ParRep_PourTableaudeBord
Nom du service		:		psGENE_VenteUniteBruteEtNette_ParRep_PourTableaudeBord
But					:		Pour le tableau de bord - info par rep
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@dtStartDate				Début de la période
						@dtEndDate					Fin de la période

Exemple d'appel:
						EXEC psGENE_VenteUniteBruteEtNette_ParRep_PourTableaudeBord 
						@dtStartDate = '2018-05-31', 
						@dtEndDate = '2018-05-31'

						EXEC psGENE_VenteUniteBruteEtNette_ParRep_PourTableaudeBord 
						@dtStartDate = '9999-12-31', 
						@dtEndDate = '2018-05-31'
                
						DROP PROC psGENE_VenteUniteBruteEtNette_PourTableaudeBord

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2018-06-14					Donald Huppé							Création du Service

 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_VenteUniteBruteEtNette_ParRep_PourTableaudeBord] 
	(
	@dtStartDate DATETIME,
	@dtEndDate DATETIME
	)


AS
BEGIN

	SET ARITHABORT ON

	DECLARE 
		@dtStartDateNEW DATETIME
		,@dtEndDateNEW DATETIME

	IF @dtStartDate = '9999-12-31'
		BEGIN 
		SET @dtStartDateNEW = CAST(GETDATE() AS DATE)
		SET @dtEndDateNEW = CAST(GETDATE() AS DATE)
		END
	ELSE
		BEGIN 
		SET @dtStartDateNEW = @dtStartDate
		SET @dtEndDateNEW = @dtEndDate
		END		

	IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'TMPGrossANDNetUnits_2')
		DROP TABLE TMPGrossANDNetUnits_2


	create table TMPGrossANDNetUnits_2 (
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
	INSERT TMPGrossANDNetUnits_2 
	EXEC SL_UN_RepGrossANDNetUnits 
		@ReptreatmentID = NULL,
		@StartDate = @dtStartDateNEW,
		@EndDate = @dtEndDateNEW,
		@RepID = 0,
		@ByUnit = 1 



	SELECT 
		dtStartDate = CAST(@dtStartDatenew AS DATE),
		dtEndDate = CAST(@dtEndDateNEW AS DATE),
		r.RepID,
		r.RepCode,
		RepName = HR.FirstName + ' ' + HR.LastName,
		BusinessStart = CAST(R.BusinessStart AS DATE),
		BusinessEnd = CAST(ISNULL(R.BusinessEnd,'9999-12-31') AS DATE),

		UniteBrut = SUM(brut),
		UniteNet =  SUM(Brut - Retraits + Reinscriptions),

		Agence = CASE WHEN br.BossID IN (149593,149489,149521,436381) THEN hb.FirstName + ' ' + hb.LastName ELSE 'Autre' END,
		ConsPctGUI =
				(SELECT 
					ConsPctGUI = round(	
									CASE
									WHEN SUM(Brut24) <= 0 THEN 0
									ELSE (sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100
									END,
									2)
				from TMPGrossANDNetUnits_2 gnu
				),
		DonneeValide = CASE WHEN SUM(brut) <> 0 OR SUM(Brut - Retraits + Reinscriptions) <> 0 THEN 'V' ELSE '' END
	FROM 
		TMPGrossANDNetUnits_2 gnu
		JOIN Un_Rep r on r.RepID = gnu.RepID
		join Mo_Human HR ON HR.HumanID = R.RepID
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
	GROUP BY

		r.RepID,
		r.RepCode,
		HR.FirstName + ' ' + HR.LastName,
		R.BusinessStart,
		R.BusinessEnd,
		br.BossID,
		hb.FirstName + ' ' + hb.LastName
	--HAVING -- splunk ne gère pas ça
	--	SUM(brut) <> 0
	--	OR SUM(Brut - Retraits + Reinscriptions) <> 0



	IF EXISTS (SELECT 1 FROM SYSOBJECTS WHERE NAME = 'TMPGrossANDNetUnits_2')
		DROP TABLE TMPGrossANDNetUnits_2



SET ARITHABORT OFF	
		
END