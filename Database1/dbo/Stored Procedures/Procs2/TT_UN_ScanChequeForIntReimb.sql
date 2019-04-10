/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_ScanChequeForIntReimb
Description         :	Traitement quotidien qui consultera le module de chèque. Ce traitement modifie l’étape rendu 
			du RIN dans l’outil de gestion des remboursements intégraux selon l’état de l’opération dans 
			le module des chèques. Quand un chèque est proposé sur un RIN, on passe ce dernier à l’étape 
			#6 dans l’outil. Quand un chèque est annulé ou refusé, on recule l’opération à l’étape #5.
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL
Note                :	ADX0000753	IA	2005-10-05	Bruno Lapointe		Création
						ADX0001114	IA	2006-11-21	Alain Quirion		Gestion des deux périodes de calcul de date
																		estimée de RI (FN_UN_EstimatedIntReimbDate).  
											Modifier le champ dtIntReimbTreatedDate pour dtRINToolLastTreatedDate
										2008-07-23	Éric Deshaies		Ne pas faire passer à l'étape #5 les groupes
																		d'unités suite à un RIO.  Les RIO n'ont pas
																		de chèque mais sont toujours à l'étape #6 de
																		l'outil RIN/RIO
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_ScanChequeForIntReimb] 
AS
BEGIN
	DECLARE
		@dtRINToolLastTreatedDate DATETIME,
		@UserID INTEGER,
		@iConnectID INTEGER

	INSERT INTO Mo_Connect (
			UserID,
			CodeID,
			StationName,
			IPAddress)
		SELECT
			UserID,
			0,
			@@SERVERNAME,
			''
		FROM Mo_User
		WHERE LoginNameID = 'Compurangers'

	SET @iConnectID = SCOPE_IDENTITY()

	SELECT @dtRINToolLastTreatedDate = MAX(dtRINToolLastTreatedDate)
	FROM Un_Def

	CREATE TABLE #UnitToRIN (
		UnitID INTEGER PRIMARY KEY)

	INSERT INTO #UnitToRIN
		SELECT DISTINCT
			U.UnitID
		FROM dbo.Un_Unit U
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID
		JOIN Un_IntReimbStep USt ON USt.UnitID = U.UnitID
		WHERE @dtRINToolLastTreatedDate <= dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust)
			AND P.PlanTypeID = 'COL'

	-- Quand un chèque est proposé sur un RIN, on passe ce dernier à l’étape #6 dans l’outil.
	INSERT INTO Un_IntReimbStep (
			UnitID,
			iIntReimbStep,
			dtIntReimbStepTime,
			ConnectID )
		SELECT 
			V.UnitID,
			6,
			GETDATE(),
			@iConnectID
		FROM (
			SELECT DISTINCT UStT.UnitID
			FROM (
				SELECT 
					URin.UnitID,
					iIntReimbStepID = MAX(iIntReimbStepID)
				FROM #UnitToRIN URin
				JOIN Un_IntReimbStep USt ON USt.UnitID = URin.UnitID
				GROUP BY URin.UnitID
				) UStT 
			JOIN Un_IntReimbStep USt ON USt.iIntReimbStepID = UStT.iIntReimbStepID
			JOIN Un_Cotisation Ct ON Ct.UnitID = UStT.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID AND O.OperTypeID = 'RIN'
			JOIN Un_OperLinkToCHQOperation L ON L.OperID = O.OperID
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = L.iOperationID
			JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
			JOIN CHQ_Check C ON C.iCheckID = COD.iCheckID
			WHERE C.iCheckStatusID NOT IN (3,5)
				AND USt.iIntReimbStep = 5
			) V

	-- Quand un chèque est annulé ou refusé, on recule l’opération à l’étape #5.
	INSERT INTO Un_IntReimbStep (
			UnitID,
			iIntReimbStep,
			dtIntReimbStepTime,
			ConnectID )
		SELECT 
			UStT.UnitID,
			5,
			GETDATE(),
			@iConnectID
		FROM (
			SELECT 
				URin.UnitID,
				iIntReimbStepID = MAX(iIntReimbStepID)
			FROM #UnitToRIN URin
			JOIN Un_IntReimbStep USt ON USt.UnitID = URin.UnitID
			GROUP BY URin.UnitID
			) UStT 
		JOIN Un_IntReimbStep USt ON USt.iIntReimbStepID = UStT.iIntReimbStepID
		LEFT JOIN ( -- Groupe d'unité pour lesquelles un chèque non refusé et non annulé a été émis
			SELECT DISTINCT URin.UnitID
			FROM #UnitToRIN URin
			JOIN Un_Cotisation Ct ON Ct.UnitID = URin.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID AND O.OperTypeID = 'RIN'
			JOIN Un_OperLinkToCHQOperation L ON L.OperID = O.OperID
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = L.iOperationID
			JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
			JOIN CHQ_Check C ON C.iCheckID = COD.iCheckID
			WHERE C.iCheckStatusID NOT IN (3,5)
			) V ON V.UnitID = UStT.UnitID
		WHERE V.UnitID IS NULL AND
			  USt.iIntReimbStep = 6 AND
			  NOT EXISTS (SELECT RIO.iID_Operation_RIO
						  FROM tblOPER_OperationsRIO RIO
						  WHERE	RIO.iID_Unite_Source = UStT.UnitID AND
								RIO.bRIO_Annulee = 0 AND
								RIO.bRIO_QuiAnnule = 0)

	DROP TABLE #UnitToRIN
END


