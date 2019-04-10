/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service		: psREPR_ObtenirProjectionDeCommission
Nom du service		: Obtenir les projection de commission
But 				: Obtenir les projection de commission 
Facette				: REPR

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE [dbo].[psREPR_ObtenirProjectionDeCommission] 372,  '2009-12-31'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-12-13		Donald Huppé						Création du service	

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_ObtenirProjectionDeCommission] 
(
	@RepTreatmentID int,
	@RepProjectionDate datetime
)
AS

BEGIN

/*

Afficher un message indiquant que ce rapport utilise les projections préalablement demandée et calculées le dimanche

*/
	DECLARE @RepTreatmentDate DATETIME

	SELECT 
		@RepTreatmentDate = RepTreatmentDate 
	FROM 
		un_reptreatment 
	WHERE 
		RepTreatmentID =  @RepTreatmentID

	SELECT 
		-- Représentant
		Code = R.RepCode, 
		Nom = H.LastName, 
		Prenom = H.FirstName, 
		R.RepID, 
		Début = R.BusinessStart, 
		Fin = R.BusinessEnd, 
		
		-- Commission
		AvanceCouvrir = ISNULL(RCM.AvanceCouvrir,0), 
		CommVenir = ISNULL(RCM.CommVenir,0), 
		AvanceSpecial = ISNULL(RCM.AvanceSpecial,0), 
		AvanceResil = ISNULL(CC.SommeDeRepChargeAmount,0), 
		
		-- Projection
		RPJ.RepProjectionDate, 
		PeriodCommBonus = ISNULL(RPJ.PeriodCommBonus,0), 
		YearCommBonus = ISNULL(RPJ.YearCommBonus,0), 
		PeriodCoveredAdvance = ISNULL(RPJ.PeriodCoveredAdvance,0), 
		YearCoveredAdvance = ISNULL(RPJ.YearCoveredAdvance,0), 
		AVSAmount = ISNULL(RPJ.AVSAmount,0), 
		AVRAmount = ISNULL(RPJ.AVRAmount,0), 
		AdvanceSolde = ISNULL(RPJ.AdvanceSolde,0), 
		AVSAmountSolde = ISNULL(RPJ.AVSAmountSolde,0), 
		AVRAmountSolde = ISNULL(RPJ.AVRAmountSolde,0)
	FROM 
		Un_Rep R
		JOIN dbo.Mo_Human H ON R.RepID = H.HumanID
		LEFT JOIN (
			SELECT RC.RepID, SUM(RC.RepChargeAmount) AS SommeDeRepChargeAmount
			FROM Un_RepCharge RC
			WHERE RC.RepChargeTypeID='AVR'
			GROUP BY RC.RepID
			) CC ON R.RepID = CC.RepID 
		LEFT JOIN ( -- Rep_Commission
			SELECT 
				RT.RepCode, 
				RT.RepID, 
				RT.RepName AS Représentant, 
				R1.BusinessStart AS Début, 
				R1.BusinessEnd AS Fin, 
				RT.Advance AS AvanceCouvrir, 
				RT.FuturCom AS CommVenir, 
				SUM(SA.Amount) AS AvanceSpecial 
			FROM 
				Un_Dn_RepTreatmentSumary  RT
				JOIN Un_Rep R1 ON RT.RepID = R1.RepID 
				LEFT JOIN Un_SpecialAdvance SA ON R1.RepID = SA.RepID
			WHERE 1=1
				and RT.RepTreatmentDate = @RepTreatmentDate
				AND RT.RepTreatmentID = @RepTreatmentID  -- select * from un_reptreatment
			GROUP BY 
				RT.RepCode, 
				RT.RepID, 
				RT.RepName, 
				R1.BusinessStart, 
				R1.BusinessEnd, 
				RT.Advance, 
				RT.FuturCom
		)RCM ON R.RepID = RCM.RepID
		LEFT JOIN ( -- Rep_Projections
			SELECT 
				H2.LastName, 
				H2.FirstName, 
				R2.RepCode, 
				R2.RepID, 
				PS.RepProjectionDate, 
				PS.PeriodCommBonus, 
				PS.YearCommBonus, 
				PS.PeriodCoveredAdvance, 
				PS.YearCoveredAdvance, 
				PS.AVSAmount, 
				PS.AVRAmount, 
				PS.AdvanceSolde, 
				PS.AVSAmountSolde, 
				PS.AVRAmountSolde 
			FROM 
				Un_Rep R2
				JOIN dbo.Mo_Human H2 ON R2.RepID = H2.HumanID
				LEFT JOIN Un_RepProjectionSumary PS ON R2.RepID = PS.RepID 
			WHERE 
				PS.RepProjectionDate Is Null OR PS.RepProjectionDate = @RepProjectionDate
		)RPJ ON R.RepID = RPJ.RepID
	ORDER BY H.LastName, H.FirstName

END
/*

-- Rep_Commission
SELECT 
	RT.RepCode, 
	RT.RepID, 
	RT.RepName AS Représentant, 
	R.BusinessStart AS Début, 
	R.BusinessEnd AS Fin, 
	RT.Advance AS AvanceCouvrir, 
	RT.FuturCom AS CommVenir, 
	Sum(SA.Amount) AS AvanceSpecial 
--INTO [Rep_Commissions_2009-12-20]
FROM 
	Un_Dn_RepTreatmentSumary  RT
	JOIN Un_Rep R ON RT.RepID = R.RepID 
	LEFT JOIN Un_SpecialAdvance SA ON R.RepID = SA.RepID
WHERE 
	RT.RepTreatmentDate='2009-12-20'
	AND RT.RepTreatmentID=372 -- SELECT * FROM Un_RepTreatmentSumary
GROUP BY 
	RT.RepCode, 
	RT.RepID, 
	RT.RepName, 
	R.BusinessStart, 
	R.BusinessEnd, 
	RT.Advance, 
	RT.FuturCom
ORDER BY RT.RepName

-- Rep_Projection
SELECT 
	H.LastName, 
	H.FirstName, 
	R.RepCode, 
	R.RepID, 
	PS.RepProjectionDate, 
	PS.PeriodCommBonus, 
	PS.YearCommBonus, 
	PS.PeriodCoveredAdvance, 
	PS.YearCoveredAdvance, 
	PS.AVSAmount, 
	PS.AVRAmount, 
	PS.AdvanceSolde, 
	PS.AVSAmountSolde, 
	PS.AVRAmountSolde 
--INTO [Rep_Projections_2009-12-31]
FROM 
	Un_Rep R
	JOIN dbo.Mo_Human H ON R.RepID = H.HumanID
	LEFT JOIN Un_RepProjectionSumary PS ON R.RepID = PS.RepID
WHERE 
	PS.RepProjectionDate Is Null OR PS.RepProjectionDate = '2009-12-31'
ORDER BY 
	H.LastName, 
	H.FirstName
*/

