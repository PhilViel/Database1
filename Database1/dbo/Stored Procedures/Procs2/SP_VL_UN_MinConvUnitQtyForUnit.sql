/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : 	SP_VL_UN_MinConvUnitQtyForUnit
Description         : 	Retourne le minimum d'unités pour une convention si le nombre d'unité envoyé en paramètre plus 
								le nombre actuel d'unités (excluant les unités du groupe d'unité envoyé en paramètre) est 
								inférieure au minimum d'unités pour une convention
Valeurs de retours  :	Retourne un ligne dans un dataset contenant le minimum requis s'il n'est pas respecté, sinon
								retourne aucune ligne.
Note                :						2004-05-27	Bruno Lapointe		Création
								ADX0000568	IA	2005-02-01	Bruno Lapointe		Retourne rien si le total des unités = 0
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_MinConvUnitQtyForUnit](
	@ConventionID INTEGER, -- ID unique de la convention
	@UnitID       INTEGER, -- ID unique du groupe d'unité
	@UnitQty      MONEY, -- Quantité d'unité  
	@InforceDate  DATETIME) -- Date vigueur du groupe d'unité
AS
BEGIN
	DECLARE 
		@MinInforceDate DATETIME

	--Recherche de la date de début de régime qui est la plus petite 
	--date de vigueur des group d'unités d'une convention
	SELECT 
		@MinInforceDate = MIN (InForceDate) 
	FROM dbo.Un_Unit U
	WHERE (ConventionID = @ConventionID)
	GROUP BY ConventionID

	IF ISNULL(@MinInforceDate, 0) = 0 
		SET @MinInforceDate = @InforceDate

	--Retourne un enregistrement avec le minimum d'unité pour la convention si @UnitQty
	--est plus petit que l'enregistrement en vigueur dans la table Un_MinConvUnitQtyCfg
	SELECT
		M.MinUnitQty
	FROM (
		SELECT 
			M.MinUnitQty 
		FROM Un_MinConvUnitQtyCfg M
		WHERE (EffectDate IN (
			SELECT 
				MAX(EffectDate)           
			FROM Un_MinConvUnitQtyCfg 
			WHERE (EffectDate <= @MinInforceDate))
			)
		) M,
		  (
		SELECT 
			SUM(UnitQty) AS SumUnitQty
		FROM dbo.Un_Unit 
		WHERE (ConventionID = @ConventionID) 
		  AND (NOT UnitID = @UnitID) 
		) U
	WHERE	( ISNULL(M.MinUnitQty, 0) > ISNULL(U.SumUnitQty, 0) + @UnitQty )
		AND	( ISNULL(U.SumUnitQty, 0) + @UnitQty <> 0 )
END


