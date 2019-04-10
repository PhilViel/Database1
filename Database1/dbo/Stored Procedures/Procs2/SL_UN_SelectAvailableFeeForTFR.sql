/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_SelectAvailableFeeForTFR
Description         :	Retourne les informations pour la sélection des unités et des frais disponibles associés lors de l’opération TFR.
Valeurs de retours  :	Dataset contenant les données :
				UnitReductionID		INTEGER		ID unique de l'entrée d'historique de réduction d'unité.
				ConventionID			INTEGER		ID de la convention
				ConventionNo			VARCHAR(75)	Numéro de convention.
				InForceDate				DATETIME		Date d’entrée en vigueur du groupe d’unité.
				UnitQty					MONEY			Nombre d’unités du groupe d’unités.
				fAvailableUnitQty		MONEY			Nombre d'unités réduit encore disponible
				fFeeSumByUnit			MONEY			Montant de frais par unité réduit non remboursé au client.  Utile aux commissions.
				dtReductionDate		DATE			Date à laquelle a eu lieu la réduction
				fAvailableFee			MONEY			Frais disponible au total
Note                :		ADX0001119	IA	2006-10-31	Alain Quirion			Création
									ADX0002370	BR	2007-04-13	Bruno Lapointe			Bruno Lapointe
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SelectAvailableFeeForTFR](
	@BlobID	INTEGER)	-- Blob contenant les ID de convention séparé par des virgules
AS
BEGIN
	DECLARE @tSelectAvailableFeeConv TABLE (
		ConventionID INT PRIMARY KEY )
		
	INSERT INTO @tSelectAvailableFeeConv
		SELECT iVal 
		FROM dbo.FN_CRI_BlobToIntegerTable(@BlobID)
		
	SELECT 
		UR.UnitReductionID,
		C.ConventionID,
		C.ConventionNo,
		U.InForceDate,
		U.UnitQty,		
		fAvailableUnitQty = UR.UnitQty - ISNULL(U2.UnitUse,0),
		fFeeSumByUnit = UR.FeeSumByUnit,
		UR.ReductionDate,
		fAvailableFee = ISNULL(CF.fAvailableFee, 0)
	FROM Un_UnitReduction UR	
	JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID	
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID	
	JOIN @tSelectAvailableFeeConv AFC ON AFC.ConventionID = C.ConventionID
	LEFT JOIN (	
			SELECT  UR.UnitReductionID,
				UnitUse = SUM(fUnitQtyUse)
			FROM Un_AvailableFeeUse AV 
			JOIN Un_UnitReduction UR ON UR.UnitReductionID = AV.UnitReductionID
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN @tSelectAvailableFeeConv AFC ON AFC.ConventionID = C.ConventionID
			GROUP BY UR.UnitReductionID) U2 ON U2.UnitReductionID = UR.UnitReductionID	
	LEFT JOIN (-- Retourne le total des frais disponibles par convention
		SELECT 
			CO.ConventionID,
			fAvailableFee = SUM(CO.ConventionOperAmount)
		FROM Un_ConventionOper CO
		JOIN @tSelectAvailableFeeConv AFC ON AFC.ConventionID = CO.ConventionID
		WHERE CO.ConventionOperTypeID = 'FDI'
		GROUP BY CO.ConventionID
		) CF ON CF.ConventionID = C.ConventionID
	WHERE (UR.UnitQty - ISNULL(U2.UnitUse,0)) <> 0 --Supprime les autes unités résiliés de la même convention qui n'ont plus de frais disponibles
		AND UR.FeeSumByUnit <> 0
END


