/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_RP_UN_RepSpecialAdvance
Description         :	Rapport des avances spéciales
Valeurs de retours  :	Dataset contenant les données du rapport
Note                :	ADX0000093	IA	2004-09-29	Bruno Lapointe		Création
								ADX0001302	BR	2005-02-24	Bruno Lapointe		Correction du solde.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_RP_UN_RepSpecialAdvance] (
	@RepID INTEGER, -- ID unique du représentant (0=Tous)
	@Date DATETIME) -- Date de l'état de compte
AS
BEGIN	
	SELECT
		RepName = H.LastName+', '+H.FirstName, -- Nom du représentant
		V.RepID, -- ID Unique du représentant
		IsActif = -- <>0(True) si actif, 0(False) si inactif
			CASE
				WHEN R.BusinessEnd IS NULL THEN 1
				WHEN R.BusinessEnd > @Date THEN 1
			ELSE 0
			END,
		V.Periode, -- Date à laquelle la variation de solde à eu lieu
		Treatment = SUM(V.AVS), -- Montant de variation dû au ratio avance/com. à venir > 75%
		Manually = SUM(V.SAD), -- Ajouts et diminutions manuels
		Total = SUM(V.AVS+V.SAD), -- Treatment + Manually
		S.Solde -- L’état du compte à la fin de la période
	FROM (
	   SELECT
			RepID, 
			Periode = EffectDate,
			AVS = 0,
			SAD = Amount
		FROM Un_SpecialAdvance
		WHERE RepTreatmentID IS NULL
		  AND EffectDate <= @Date
		UNION ALL
		SELECT 
			RepID, 
			Periode = RepChargeDate,
			AVS = RepChargeAmount,
			SAD = 0
		FROM Un_RepCharge
		WHERE RepChargeTypeID = 'AVS'
		  AND RepChargeDate <= @Date
		) V 
	JOIN dbo.Mo_Human H ON H.HumanID = V.RepID
	JOIN Un_Rep R ON R.RepID = V.RepID
	JOIN (
		SELECT
			A.RepID,
			Periode = A.EffectDate,
			Solde = SUM(A2.Amount)
		FROM (
			SELECT 
				RepID,
				EffectDate,
				SpecialAdvanceID = MAX(SpecialAdvanceID)
			FROM Un_SpecialAdvance
			GROUP BY
				RepID,
				EffectDate
			) A
	   JOIN Un_SpecialAdvance A2 ON A.RepID = A2.RepID
	   WHERE ((A2.EffectDate < A.EffectDate)
			 OR ((A2.EffectDate = A.EffectDate)
			 AND (A2.SpecialAdvanceID <= A.SpecialAdvanceID)))
		  AND A.EffectDate <= @Date
	   GROUP BY
			A.RepID,
			A.EffectDate
		) S ON S.RepID = V.RepID AND S.Periode = V.Periode
	WHERE @RepID = V.RepID
		OR @RepID = 0
	GROUP BY
		H.LastName,
		H.FirstName,
		V.RepID,
		R.BusinessEnd,
		V.Periode,
		S.Solde
	ORDER BY
		H.LastName,
		H.FirstName,
		V.RepID,
		V.Periode
END

/*  Sequence de test - par: PLS - 09-05-2008
	exec [dbo].[SP_RP_UN_RepSpecialAdvance] 
	@RepID = 149653, -- ID unique du représentant (0 = Tous) (149653 = Claude Cossette)
	@Date = '2008-05-01' -- Date de l'état de compte
*/

