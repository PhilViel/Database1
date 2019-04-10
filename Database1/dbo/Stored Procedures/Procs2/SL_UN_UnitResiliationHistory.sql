/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	SL_UN_UnitResiliationHistory
Description         :	Historique des résiliations d'unités
Valeurs de retours  :	Dataset :
				Information sur résiliation :
					UnitReductionID		INTEGER		ID de la résiliation d’unités.
					InForceDate		DATETIME	Date d’entrée en vigueur du groupe d’unités.
					UnitQty			MONEY		Nombre d’unités du groupe d’unités.
					UnitReductionDate 	DATETIME	Date de la résiliation d’unités
					fUnitQtyBefore		MONEY		Nombre d’unités avant la résiliation.
					fUnitQty_RES		MONEY		Nombre d’unités résiliées.
					FeeSumByUnit		MONEY		Montant de frais disponible par unités résiliées.
					vcUserName_RES		VARCHAR(87)	Nom, prénom de l’usager qui a fait la résiliation.
				Information sur les opérations TFR :
					iAvailableFeeUseID	INTEGER		ID unique de l’historique d’utilisation de frais disponible.
					OperDate		DATETIME	Date d’opération du TFR qui a utilisé les frais disponibles.
					vcDestination		VARCHAR(100)	Destination des frais disponibles.
					fUnitQtyUse		MONEY		Nombre d’unités utilisés. 
					vcUserName_TFR		VARCHAR		Nom et prénom de l’usager qui a fait l’opération TFR.  

					> 0 : [Réussite]
					<= 0 : [Échec].

Note                :	ADX0001157	IA	2006-10-16	Mireya Gonthier		Création		
			ADX0001119	IA	2006-11-01	Alain Quirion		Modification : 	Information sur les RES et les TFR en lien avec les frais disponibles utilisés		
			ADX0002226	BR	2007-01-04	Alain Quirion		BUG : Correction des doubles lorsque le transfert de frais avait lieu sur un TIO
							2013-10-29	Donald Huppé		BUG : correction de la clause where pour faire apparaitre les frais expirés. voir 2013-10-29
			exec SL_UN_UnitResiliationHistory 0,33213
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_UnitResiliationHistory] (
	@iUnitID INTEGER,
	@iUnitReductionID INTEGER)
AS
BEGIN
	SELECT 
		U.UnitID,
		UR.UnitReductionID,
		U.InforceDate,
		UnitQty = U.UnitQty,
		UR.ReductionDate,
		fUnitQtyBefore = U.UnitQty + ISNULL(B1.UnitRESBefore,0),
		fUnitQty_RES = UR.UnitQty,
		UR.FeeSumByUnit,
		vcUserName_RES = CASE 
					WHEN ISNULL(H.FirstName,'') = '' THEN ISNULL(H.LastName,'')
					ELSE ISNULL(H.LastName,'') + ', ' + ISNULL(H.FirstName,'')
				END,
		V.iAvailableFeeUseID,
		UnitReductionID_TFR = V.UnitReductionID,
		V.OperDate,
		V.vcDestination,
		fUnitQtyUse = ISNULL(V.fUnitQtyUse,0),
		V.vcUserName_TFR
	FROM Un_UnitReduction UR
	JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
	JOIN (
		SELECT 	UR.UnitReductionID,
			UnitRESBefore = SUM (UR2.UnitQty)
		FROM Un_UnitReduction UR
		JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
		JOIN Un_UnitReduction UR2 ON UR2.UnitID = U.UnitID AND UR2.UnitReductionID >= UR.UnitReductionID --On utilise le ID au lieu de la date pour différencer deux réduciton le même jour
		WHERE (U.UnitID = @iUnitID OR @iUnitID = 0)
			AND (UR.UnitReductionID = @iUnitReductionID OR @iUnitReductionID = 0)
		GROUP BY UR.UnitReductionID) B1 ON B1.UnitReductionID = UR.UnitReductionID	
	LEFT JOIN Mo_Connect CO ON CO.ConnectID = UR.ReductionConnectID
	LEFT JOIN dbo.Mo_Human H ON H.HumanID = CO.UserID
	LEFT JOIN ( 	-- INFO du TFR
			SELECT 
				A.iAvailableFeeUseID,
				UR.UnitReductionID,
				U.UnitID,
				O.OperDate,
				vcDestination = CASE
							WHEN ISNULL(O2.OperID,-1) <> -1 THEN 'GUI (Frais Expirés)'
							ELSE C2.ConventionNo + ' - ' + CONVERT(VARCHAR,U2.InforceDate,101) + ' (' + CAST(CAST(U2.UnitQty AS DECIMAL(10,3)) AS VARCHAR) + ')'
						END,
				A.fUnitQtyUse,
				vcUserName_TFR = CASE 
							WHEN ISNULL(H.FirstName,'') = '' THEN ISNULL(H.LastName,'')
							ELSE ISNULL(H.LastName,'') + ',  ' + ISNULL(H.FirstName,'')
						END
			FROM Un_AvailableFeeUse A
			JOIN Un_UnitReduction UR ON A.UnitReductionID = UR.UnitReductionID			
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID		
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID	
			JOIN Un_Oper O ON O.OperID = A.OperID
			LEFT JOIN Un_Cotisation CT ON CT.OperID = O.OperID
			LEFT JOIN dbo.Un_Unit U2 ON U2.UnitID = CT.UnitID
			LEFT JOIN dbo.Un_Convention C2 ON C2.ConventionID = U2.ConventionID
			LEFT JOIN Un_OtherAccountOper O2 ON O2.OperID = A.OperID
			LEFT JOIN Mo_Connect CO ON CO.ConnectID = O.ConnectID
			LEFT JOIN dbo.Mo_Human H ON H.HumanID = CO.UserID
			WHERE (U.UnitID = @iUnitID OR @iUnitID = 0)
				AND (UR.UnitReductionID = @iUnitReductionID OR @iUnitReductionID = 0)
				--AND  CT.UnitID  <> U.UnitID) V ON V.UnitReductionID = UR.UnitReductionID
				AND  isnull(CT.UnitID,0)  <> U.UnitID) V ON V.UnitReductionID = UR.UnitReductionID -- 2013-10-29
	WHERE (U.UnitID = @iUnitID OR @iUnitID = 0)
			AND (UR.UnitReductionID = @iUnitReductionID OR @iUnitReductionID = 0)		
	ORDER BY UR.ReductionDate DESC, V.UnitReductionID ASC, V.OperDate DESC, (U.UnitQty + ISNULL(B1.UnitRESBefore,0)) ASC
	
END


