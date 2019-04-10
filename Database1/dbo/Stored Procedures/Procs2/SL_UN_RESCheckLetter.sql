/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_RESCheckLetter
Description         :	Procédure qui renvoi l’ID du chèque de lettre de remboursement d’épargne ou de résiliation sans NAS de la convention s’il y a lieu.  Sinon, le DataSet contiendra le message d’erreur.
Valeurs de retours  :	DataSet :
						
Note                :	ADX0001169	IA	2006-10-25	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RESCheckLetter] (
	@iConventionID INTEGER, 	-- ID de la convention
	@RESType INTEGER)		-- 0=Lettre de remboursement d’épargne(résiliation), 1=Lettre de résiliation sans NAS – chèque émis, 2=Lettre de résiliation sans NAS – aucune épargne	
AS 
BEGIN
	DECLARE 
		@iResult INTEGER,
		@iCheckID INTEGER,
		@NbConventions INTEGER,
		@iOperID INTEGER

	SET @iResult = 1

	-- Va chercher la plus récente résiliation de la convention.
	SELECT @iOperID = ISNULL(MAX(O.OperID),0)
	FROM dbo.Un_Unit U
	JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
	JOIN Un_Oper O ON O.OperID = Ct.OperID
	WHERE U.ConventionID = @iConventionID
		AND O.OperTypeID = 'RES'
		AND O.OperDate IN ( 
				SELECT OperDate = MAX(O.OperDate)
				FROM dbo.Un_Unit U
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID
				WHERE U.ConventionID = @iConventionID
					AND O.OperTypeID = 'RES'
				)

	IF @iOperID <= 0
		SET @iResult = -1

	IF @iResult > 0 AND @RESType IN (0,1)
	BEGIN
		-- Va chercher le chèque lié à l'opération
		SELECT 
			@iCheckID = ISNULL(MAX(CH.iCheckID),0)
		FROM Un_OperLinkToCHQOperation OL
		JOIN CHQ_Operation CP ON CP.iOperationID = OL.iOperationID
		JOIN CHQ_OperationDetail OD ON OD.iOperationID = CP.iOperationID
		JOIN CHQ_CheckOperationDetail COP ON COP.iOperationDetailID = OD.iOperationDetailID
		JOIN CHQ_Check CH ON CH.iCheckID = COP.iCheckID		
		WHERE OL.OperID = @iOperID

		IF @iCheckID <= 0
			SET @iResult = -1
		ELSE
			SET @iResult = @iCheckID
	END

	-- Table qui contient tout les groupes d'unités liés au chèque
	DECLARE @tOperOfCheck TABLE (
		OperID INTEGER PRIMARY KEY,
		UnitID INTEGER NOT NULL )

	IF @iResult > 0 AND @RESType IN (0,1)
	BEGIN
		INSERT INTO @tOperOfCheck
			SELECT DISTINCT Ct.OperID, Ct.UnitID
			FROM CHQ_Check CH
			JOIN CHQ_CheckOperationDetail COP ON CH.iCheckID = COP.iCheckID
			JOIN CHQ_OperationDetail OD ON COP.iOperationDetailID = OD.iOperationDetailID
			JOIN Un_OperLinkToCHQOperation OL ON OD.iOperationID = OL.iOperationID
			JOIN Un_Cotisation Ct ON Ct.OperID = OL.OperID
			WHERE CH.iCheckID = @iCheckID		
	END

	IF @ResType = 0 AND @iResult > 0 -- Lettre de remboursement d’épargne(résiliation)
	BEGIN
		-- Un chèque contenant uniquement des résiliations complètes avec transfert de frais dont 
		-- la raison de résiliation est différente de « sans NAS après un (1) an » ayant été émis sur la convention
		IF EXISTS (
			SELECT 
				OC.OperID
			FROM @tOperOfCheck OC
			JOIN Un_Cotisation Ct ON Ct.OperID = OC.OperID AND Ct.UnitID = OC.UnitID
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
			JOIN Un_UnitReduction UR ON UR.UnitReductionID = URC.UnitReductionID
			JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
			JOIN (	
				SELECT 
					CCS.ConventionID,
					MaxDate = MAX(CCS.StartDate)
				FROM @tOperOfCheck OC
				JOIN dbo.Un_Unit U ON U.UnitID = OC.UnitID
				JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = U.ConventionID
				GROUP BY CCS.ConventionID
				) CS ON U.ConventionID = CS.ConventionID
			JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = CS.ConventionID AND CCS.StartDate = CS.MaxDate
			LEFT JOIN Un_UnitReductionCotisation URC2 ON UR.UnitReductionID = URC2.UnitReductionID AND URC2.CotisationID <> URC.CotisationID
			LEFT JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
			LEFT JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID AND O2.OperTypeID = 'TFR'
			WHERE UR.ReductionDate <> ISNULL(U.TerminatedDate,0) -- La résiliation n'est pas complète
				OR URR.UnitReductionReason = 'sans NAS après un (1) an' -- La raison de résiliation est "sans NAS après un (1) an"
				OR CCS.ConventionStateID <> 'FRM' -- La convention n'est pas résilié.
				OR O2.OperID IS NULL -- Il n'y pas de transfert de frais (TFR)
				)
			SET @iResult = -1 -- Ne répond pas aux critères de ce type de lettre

		-- Le nombre de conventions maximales sera vérifier lors de la commande de la lettre
		/*IF @iResult > 0 
			AND (
				SELECT
					COUNT(DISTINCT U.ConventionID)
				FROM @tOperOfCheck OC
				JOIN dbo.Un_Unit U ON U.UnitID = OC.UnitID
				) > 4 -- Plus de 4 conventions
			SET @iResult = -1 -- Plus de 4 conventions*/
	END
	ELSE IF @RESType = 1 AND @iResult > 0 -- Lettre de résiliation sans NAS – chèque émis
	BEGIN
		IF EXISTS (
			SELECT 
				OC.OperID
			FROM @tOperOfCheck OC
			JOIN Un_Cotisation Ct ON Ct.OperID = OC.OperID AND Ct.UnitID = OC.UnitID
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
			JOIN Un_UnitReduction UR ON UR.UnitReductionID = URC.UnitReductionID
			JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
			JOIN (	
				SELECT 
					CCS.ConventionID,
					MaxDate = MAX(CCS.StartDate)
				FROM @tOperOfCheck OC
				JOIN dbo.Un_Unit U ON U.UnitID = OC.UnitID
				JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = U.ConventionID
				GROUP BY CCS.ConventionID
				) CS ON U.ConventionID = CS.ConventionID
			JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = CS.ConventionID AND CCS.StartDate = CS.MaxDate
			LEFT JOIN Un_UnitReductionCotisation URC2 ON UR.UnitReductionID = URC2.UnitReductionID AND URC2.CotisationID <> URC.CotisationID
			LEFT JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
			LEFT JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID AND O2.OperTypeID = 'TFR'
			WHERE UR.ReductionDate <> ISNULL(U.TerminatedDate,0) -- La résiliation n'est pas complète
				OR URR.UnitReductionReason <> 'sans NAS après un (1) an' -- La raison de résiliation n'est pas "sans NAS après un (1) an"
				OR CCS.ConventionStateID <> 'FRM' -- La convention n'est pas résilié.
				OR O2.OperID IS NULL -- Il n'y pas de transfert de frais (TFR)
				)
			SET @iResult = -1 -- Ne répond pas aux critères de ce type de lettre

		-- Le nombre de conventions maximales sera vérifier lors de la commande de la lettre
		/*IF @iResult > 0 
			AND (
				SELECT
					COUNT(DISTINCT U.ConventionID)
				FROM @tOperOfCheck OC
				JOIN dbo.Un_Unit U ON U.UnitID = OC.UnitID
				) > 1 -- Plus de 1 conventions
			SET @iResult = -1 -- Plus de 1 conventions*/
	END
	ELSE IF @RESType = 2 AND @iResult > 0
	BEGIN
		IF EXISTS (
			SELECT 
				Ct.OperID
			FROM dbo.Un_Unit U
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
			JOIN Un_UnitReduction UR ON UR.UnitReductionID = URC.UnitReductionID
			JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
			JOIN (	
				SELECT 
					CCS.ConventionID,
					MaxDate = MAX(CCS.StartDate)
				FROM Un_Cotisation Ct
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = U.ConventionID
				WHERE Ct.OperID = @iOperID
				GROUP BY CCS.ConventionID
				) CS ON U.ConventionID = CS.ConventionID
			JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = CS.ConventionID AND CCS.StartDate = CS.MaxDate
			WHERE	Ct.OperID = @iOperID
				AND( UR.ReductionDate <> ISNULL(U.TerminatedDate,0) -- La résiliation n'est pas complète
					OR URR.UnitReductionReason <> 'sans NAS après un (1) an' -- La raison de résiliation n'est pas "sans NAS après un (1) an"
					OR CCS.ConventionStateID <> 'FRM' -- La convention n'est pas résilié.
					OR Ct.Cotisation <> 0 -- Épargnes accumulés
					)
				)
			SET @iResult = -1 -- Ne répond pas aux critères de ce type de lettre
	END	

	SELECT
		vcErrorCode =
			CASE @RESType
				WHEN 0 THEN 'RCL'
			ELSE 'RWN'
			END, 
		vcErrorText = 
			CASE @RESType
				WHEN 0 THEN 'Aucun chèque de remboursement d’épargne ne correspond aux critères de la lettre.'
			ELSE 'La convention ne correspond pas aux critères de la lettre.'
			END
	WHERE @iResult < 0

	RETURN @iResult
END


