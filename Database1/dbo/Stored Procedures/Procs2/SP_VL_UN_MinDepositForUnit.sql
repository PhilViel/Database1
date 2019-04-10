/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : 	SP_VL_UN_MinDepositForUnit
Description         : 	Retourne un enregistrement avec le dépôt minimum par plan et modalité de paiement si le 
								montant de dépôt par rapport a la modalité et le nombre d'unités est plus petit que 
								l'enregistrement en vigueur dans la table Un_MinDepositCfg. seulemnt sur le premier groupe 
								d'unité à la création
Valeurs de retours  : 	Retourne un dataset contenant les limites dépassées.  Si vide, c'est qu'il n'y a pas de
								limite de dépassée.
Note                :						2004-05-27	Bruno Lapointe		Création
								ADX0001245	BR	2005-01-31	Bruno Lapointe		Correction d'un bug d'arrondissement
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_MinDepositForUnit](
	@PlanID INTEGER, -- ID Unique du plan
	@ModalID INTEGER, -- ID Unique de la modalité
	@ConventionID INTEGER, -- ID Unique de la convention
	@InforceDate DATETIME, -- Date de vigueur du groupe d'unités
	@UnitQty MONEY) -- Nombre d'unités du groupe d'unités
AS
BEGIN
	SELECT
		D.ModalTypeID,
		D.MinAmount
	FROM (
		SELECT 
			D.ModalTypeID,
			D.MinAmount
		FROM Un_MinDepositCfg D
		WHERE (EffectDate IN (
			SELECT 
				MAX(EffectDate)           
			FROM Un_MinDepositCfg
			WHERE (EffectDate <= @InforceDate)
			GROUP BY PlanID )
			)
		  AND (PlanID = @PlanID)
		) D,
		(
		SELECT 
			SumDepositAmount = ROUND(@UnitQty * M.PmtRate,2),
			M.PmtByYearID,
			M.PmtQty 
		FROM Un_Modal M
		WHERE (ModalID = @ModalID)
		) M
	WHERE ((
		SELECT 
			COUNT(UnitID) 
		FROM dbo.Un_Unit 
		WHERE ConventionID = @ConventionID) = 0)
		  AND ISNULL(M.SumDepositAmount, 0) < (ISNULL(D.MinAmount, 0))
		  AND ((D.ModalTypeID = 0 AND M.PmtQty = 1) OR (D.ModalTypeID = M.PmtByYearID AND M.PmtQty > 1)) 
END


