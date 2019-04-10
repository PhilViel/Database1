/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_Unit_DL
Description         :	Fait les validations BD d'un groupe d'unités avant sa suppression
Valeurs de retours  :	Dataset :
									Code		VARCHAR(3)		Code d'erreur
									NbRecord	VARCHAR(100)	Nombre de cas en erreur
Note                :						2004-05-26	Bruno Lapointe	Création
								ADX0000831	IA	2006-03-23	Bruno Lapointe	Adaptation des conventions pour PCEE 4.3
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_Unit_DL] (
	@UnitID INTEGER)
AS
BEGIN
	-- DU01 = Il y a une ou des transactions de liés
	-- DU02 = Il y a des commissions de liés
	-- DU03 = Il y a des bonis d'affaires de liés
	-- DU04 = Il y a une ou des résiliations de liés
	-- DU05 = Il y a un ou des remboursements intégral de liés
	-- DU06 = Vous ne pouvez pas supprimer ce groupe d’unités car il est le seul de la convention et que celle-ci a été expédiée au PCEE. 

	CREATE TABLE #WngAndErr(
		Code VARCHAR(4),
		NbRecord INTEGER
	)

	-- DU01 = Il y a une ou des transactions de liés
	INSERT INTO #WngAndErr
		SELECT 
			'DU01',
			COUNT(Ct.UnitID)
		FROM Un_Cotisation Ct
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		WHERE Ct.UnitID = @UnitID
			AND O.OperTypeID <> 'BEC'
		HAVING COUNT(Ct.UnitID) > 0

	-- DU02 = Il y a des commissions de liés
	INSERT INTO #WngAndErr
		SELECT 
			'DU02',
			COUNT(UnitID)
		FROM Un_RepCommission
		WHERE UnitID = @UnitID
		HAVING COUNT(UnitID) > 0

	-- DU03 = Il y a des bonis d'affaires de liés
	INSERT INTO #WngAndErr
		SELECT 
			'DU03',
			COUNT(UnitID)
		FROM Un_RepBusinessBonus
		WHERE UnitID = @UnitID
		HAVING COUNT(UnitID) > 0

	-- DU04 = Il y a une ou des résiliations de liés
	INSERT INTO #WngAndErr
		SELECT 
			'DU04',
			COUNT(UnitID)
		FROM Un_UnitReduction
		WHERE UnitID = @UnitID
		HAVING COUNT(UnitID) > 0

	-- DU05 = Il y a un ou des remboursements intégral de liés
	INSERT INTO #WngAndErr
		SELECT 
			'DU05',
			COUNT(UnitID)
		FROM Un_IntReimb
		WHERE UnitID = @UnitID
		HAVING COUNT(UnitID) > 0

	-- DU06 = Vous ne pouvez pas supprimer ce groupe d’unités car il est le seul de la convention et que celle-ci a été expédiée au PCEE. 
	INSERT INTO #WngAndErr
		SELECT 
			'DU06',
			COUNT(U.UnitID)
		FROM dbo.Un_Unit U
		JOIN Un_CESP100 G1 ON G1.ConventionID = U.ConventionID AND G1.iCESPSendFileID IS NOT NULL
		LEFT JOIN dbo.Un_Unit U2 ON U2.ConventionID = U.ConventionID AND U2.UnitID <> U.UnitID
		WHERE U.UnitID = @UnitID
			AND U2.UnitID IS NULL -- C'est le seul groupe d'unité de la convention
		HAVING COUNT(U.UnitID) > 0

	SELECT *
	FROM #WngAndErr

	DROP TABLE #WngAndErr
END


