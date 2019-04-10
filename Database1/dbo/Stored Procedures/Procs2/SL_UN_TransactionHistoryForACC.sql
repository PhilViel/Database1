/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : 	SL_UN_TransactionHistoryForACC
Description         : 	Procédure retournant les données nécessaires à l'historique des transactions de la 
								comptabilité
Valeurs de retours  :	Dataset contenant les données
Note                :	ADX0000570	IA	2004-10-29	Bruno Lapointe			Création
						ADX0001237	BR	2004-01-19	Bruno Lapointe			Retour du status de l'opération
						ADX0000753	IA	2005-11-03	Bruno Lapointe			Changer les valeurs de retours +HaveCheque, 
																						-ChequeID, -ChequeNo, -ChequeDate, 
																						-ChequeOrderID, -ChequeOrderDate, 
																						-ChequeOrderDesc, -ChequeName, -ChequeAmount
			ADX0001100	IA	2006-10-24	Alain Quirion		Retour de TIO pour les opérations liées au transfert interne
			ADX0001235	IA	2007-02-14	Alain Quirion		Utilisation de dtRegStartDate pour la date de début de régime
							2010-05-10	Pierre Paquet		Ne pas afficher les transferts à zéro.
							2010-06-07	Pierre Paquet		Correction: Ne pas afficher cotisation = 0.
							2010-10-14	Frederick Thibault	Ajout du champ fACESGPart pour régler le problème SCEE+
							
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_TransactionHistoryForACC] (
	@Type VARCHAR(3), -- Type d'historique (convention 'CNV', souscripteur 'SUB' ou groupe d’unité 'GUN')
	@ID INTEGER) -- Id de l’objet (ConventionID, SubscriberID ou UnitID).	
AS
BEGIN
	-- Bâtis une table des groupes d'unités avec la liste de IDs passer en paramètre  
	CREATE TABLE #Unit (
		UnitID INTEGER PRIMARY KEY)

	CREATE TABLE #Convention (
		ConventionID INTEGER PRIMARY KEY)

	IF @Type = 'SUB' 
	BEGIN
		INSERT INTO #Unit
			SELECT DISTINCT
				U.UnitID
			FROM dbo.Un_Unit U
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			WHERE @ID = C.SubscriberID

		INSERT INTO #Convention
			SELECT DISTINCT
				C.ConventionID
			FROM dbo.Un_Convention C 
			WHERE @ID = C.SubscriberID
	END
	ELSE IF @Type = 'CNV'
	BEGIN
		INSERT INTO #Unit
			SELECT DISTINCT
				U.UnitID
			FROM dbo.Un_Unit U
			WHERE @ID = U.ConventionID

		INSERT INTO #Convention
			SELECT DISTINCT
				C.ConventionID
			FROM dbo.Un_Convention C 
			WHERE @ID = C.ConventionID
	END
	ELSE IF @Type = 'GUN'
		INSERT INTO #Unit
			SELECT DISTINCT
				U.UnitID
			FROM dbo.Un_Unit U
			WHERE @ID = U.UnitID

	CREATE TABLE #LockAccount (
		ConventionID INTEGER PRIMARY KEY,
		EffectDate DATETIME,
		FCBOperID INTEGER
	)

	INSERT INTO #LockAccount	
		SELECT 
			C.ConventionID,
			EffectDate = dbo.FN_CRQ_DateNoTime(C.dtRegStartDate),
			FCB.FCBOperID
		FROM dbo.Un_Convention C 
		JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
		JOIN #Unit T ON T.UnitID = U.UnitID 
		LEFT JOIN (
			SELECT 
				U.ConventionID,
				FCBOperID = MIN(O.OperID)
			FROM #Unit T
			JOIN dbo.Un_Unit U ON U.UnitID = T.UnitID
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			WHERE O.OperTypeID = 'FCB'
			GROUP BY U.ConventionID
			) FCB ON FCB.ConventionID = C.ConventionID
		GROUP BY
			C.ConventionID,
			C.dtRegStartDate,
			FCB.FCBOperID

	-- Table qui donne les opérations spéciales dont la fenêtre de visualisation ne correspond pas précisément au OperTypeID Ex: TFR lié à une résiliation.
	CREATE TABLE #SpecialOperView (
		OperID INTEGER PRIMARY KEY,
		OperTypeIDView CHAR(3),
		PlanTypeIDView CHAR(3)
	)

	INSERT INTO #SpecialOperView (
			OperID,
			OperTypeIDView,
			PlanTypeIDView)
		SELECT
			O.OperID,
			'RIN',
			NULL
		FROM #Unit U
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_IntReimbOper IRO ON IRO.OperID = O.OperID
		WHERE 	O.OperTypeID = 'TFR'
		-----
		UNION
		-----
		SELECT
			O.OperID,
			'RES',
			NULL
		FROM #Unit U
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
		JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID AND URC2.CotisationID <> Ct.CotisationID
		JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
		JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID
		WHERE 	O.OperTypeID = 'TFR'
			AND	O2.OperTypeID = 'RES'
		-----
		UNION
		-----
		SELECT
			O.OperID,
			'OUT',
			NULL
		FROM #Unit U
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID		
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
		JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID AND URC2.CotisationID <> Ct.CotisationID
		JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
		JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID
		LEFT JOIN Un_TIO T ON T.iOUTOperID = O2.OperID
		LEFT JOIN UN_CESP400 C4 ON O.OperID = C4.OperID -- 2010-05-10
		WHERE 	O.OperTypeID = 'TFR'
			AND	O2.OperTypeID = 'OUT'
			AND T.iTIOID IS NULL		-- N'est pas lié à un transfert interne
			AND NOT (C4.tiCESP400TypeID = 23 AND C4.fCLB = 0 AND C4.fCESG = 0 AND C4.fACESGPart = 0) -- 2010-05-10
		-----
		UNION
		-----
		SELECT
			O.OperID,
			'TIO',
			P.PlanTypeID
		FROM #Unit U
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID		
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_TIO T ON T.iTINOperID = O.OperID
		JOIN Un_Oper O2 ON O2.OperID = T.iOUTOperID
		JOIN Un_Cotisation Ct2 ON Ct2.OperID = O2.OperID			
		JOIN dbo.Un_Unit U2 ON U2.UnitID = Ct2.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U2.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		LEFT JOIN UN_CESP400 C4 ON O.OperID = C4.OperID -- 2010-05-10
		WHERE O.OperTypeID = 'TIN'
			AND O2.OperTypeID = 'OUT'
			AND NOT (C4.tiCESP400TypeID = 23 AND C4.fCLB = 0 AND C4.fCESG = 0 AND C4.fACESGPart = 0) -- 2010-05-10
		-----
		UNION
		-----
		SELECT
			O.OperID,
			'TIO',
			P.PlanTypeID
		FROM #Unit U
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN dbo.Un_Unit U2 ON U2.UnitID = U.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U2.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_TIO T ON T.iOUTOperID = O.OperID
		JOIN Un_Oper O2 ON O2.OperID = T.iTINOperID
		LEFT JOIN UN_CESP400 C4 ON O.OperID = C4.OperID -- 2010-05-10
		WHERE O.OperTypeID = 'OUT'
			AND O2.OperTypeID = 'TIN'
			AND NOT (C4.tiCESP400TypeID = 19 AND C4.fCLB = 0 AND C4.fCESG = 0 AND C4.fACESGPart = 0) -- 2010-05-10
			
		-----
		UNION
		-----
		SELECT
			O.OperID,
			'TIO',
			P.PlanTypeID
		FROM #Unit U
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN dbo.Un_Unit U2 ON U2.UnitID = U.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U2.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
		JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID AND URC2.CotisationID <> Ct.CotisationID
		JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
		JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID
		JOIN Un_TIO T ON O2.OperID = T.iOUTOperID
		LEFT JOIN UN_CESP400 C4 ON O.OperID = C4.OperID -- 2010-05-10
		WHERE 	O.OperTypeID = 'TFR'
			AND	O2.OperTypeID = 'OUT'
			AND NOT (C4.tiCESP400TypeID = 23 AND C4.fCLB = 0 AND C4.fCESG = 0 AND C4.fACESGPart = 0) -- 2010-05-10
		-----
		UNION
		-----
		SELECT
			O.OperID,
			'PAE',
			NULL
		FROM #Convention C
		JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
		JOIN Un_Oper O ON O.OperID = CO.OperID
		JOIN Un_ScholarshipPmt SP ON SP.OperID = O.OperID
		JOIN Un_ScholarshipPmt SP2 ON SP2.ScholarshipID = SP.ScholarshipID AND SP2.OperID <> SP.OperID
		JOIN Un_Oper O2 ON O2.OperID = SP2.OperID
		WHERE 	O.OperTypeID = 'RGC'
			AND	O2.OperTypeID = 'PAE'
		
	-- Toutes les transactions sauf les changements de dépôts
	SELECT 
		O.OperID,
		O.OperDate,
		Ct.EffectDate,
		O.OperTypeID,
		Total = 
			ISNULL(Ct.Cotisation,0) + 
			ISNULL(Ct.Fee,0) + 
			ISNULL(Ct.SubscInsur,0) + 
			ISNULL(Ct.BenefInsur,0) + 
			ISNULL(Ct.TaxOnInsur,0) + 
			ISNULL(Ct.ClientInt,0) +
			ISNULL(Ct.AvailableFee,0),
		Cotisation = ISNULL(Ct.Cotisation,0),
		Fee = ISNULL(Ct.Fee,0),
		SubscInsur = ISNULL(Ct.SubscInsur,0),
		BenefInsur = ISNULL(Ct.BenefInsur,0),
		TaxOnInsur = ISNULL(Ct.TaxOnInsur,0),
		ClientInt = ISNULL(Ct.ClientInt,0),
		Penality = 0,
		ToPay = 0,
		AvailableFee = ISNULL(Ct.AvailableFee,0),
		iOperationID = ISNULL(L.iOperationID,0),
		HaveCheque = 
			CAST	(	
					CASE 
						WHEN Ch.OperID IS NULL THEN 0
					ELSE 1
					END AS BIT
					),
		LockAccount = CAST(ISNULL(Ct.LockAccount,0) AS BIT),
		ChequeSuggestion = CAST(
			CASE 
				WHEN ISNULL(CS.OperID,0) > 0 THEN 1
			ELSE 0
			END AS BIT),
		OperTypeIDView = ISNULL(SOV.OperTypeIDView, O.OperTypeID),
		PlanTypeIDView = ISNULL(SOV.PlanTypeIDView, ''),
		Status =
			CASE
				WHEN CO.OperID IS NOT NULL THEN 1
				WHEN AO.OperID IS NOT NULL THEN 2
			ELSE 0
			END
	FROM Un_Oper O
	LEFT JOIN #SpecialOperView SOV ON SOV.OperID = O.OperID
	-- Va chercher le montant de cotisation, de frais, d'assurance souscripteur, d'assurance bénéficiaire, de taxes, ainsi que la date effective
	LEFT JOIN (
		SELECT 
			OperID,
			EffectDate = MAX(EffectDate),
			Cotisation = SUM(Cotisation),
			Fee = SUM(Fee),
			SubscInsur = SUM(SubscInsur),
			BenefInsur = SUM(BenefInsur),
			TaxOnInsur = SUM(TaxOnInsur),
			ClientInt = SUM(ClientInt),
			AvailableFee = SUM(AvailableFee),
			LockAccount  
		FROM (
			SELECT 
				Ct.OperID,
				Ct.EffectDate,
				Cotisation = SUM(Ct.Cotisation),
				Fee = SUM(Ct.Fee),
				SubscInsur = SUM(Ct.SubscInsur),
				BenefInsur = SUM(Ct.BenefInsur),
				TaxOnInsur = SUM(Ct.TaxOnInsur),
				ClientInt = 0,
				AvailableFee = 0,
				LockAccount = 
					CASE 
						WHEN L.ConventionID IS NULL THEN 1
					ELSE 0
					END
			FROM Un_Cotisation Ct
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN #Unit T ON T.UnitID = U.UnitID 
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			-- Va chercher les informations des chèques
			LEFT JOIN (
				SELECT DISTINCT L.OperID
				FROM Un_OperLinkToCHQOperation L
				JOIN CHQ_OperationDetail OD ON OD.iOperationID = L.iOperationID
				JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
				) Ch ON Ch.OperID = O.OperID
			LEFT JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
			LEFT JOIN Un_UnitReduction UR ON UR.UnitReductionID = URC.UnitReductionID
			LEFT JOIN Un_NoChequeReason NCR ON NCR.NoChequeReasonID = UR.NoChequeReasonID
			LEFT JOIN Un_OperCancelation OC ON OC.OperSourceID = O.OperID OR OC.OperID = O.OperID
			LEFT JOIN Un_TIO TIO ON TIO.iOUTOperID = O.OperID
			LEFT JOIN #LockAccount L ON C.ConventionID = L.ConventionID AND (
													CASE 
														WHEN L.EffectDate IS NULL THEN O.Operdate+1
														WHEN L.EffectDate < '2003-01-01' THEN O.Operdate-1
														WHEN O.OperTypeID = 'FCB' THEN O.Operdate-1
														WHEN O.OperTypeID = 'RCB' THEN O.Operdate+1
														WHEN L.EffectDate = O.OperDate AND O.OperID < L.FCBOperID THEN O.Operdate+1
													ELSE L.EffectDate
													END <= O.OperDate)
			WHERE O.OperDate <= GETDATE() -- Élimine les transactions dont la date d'opération est plus grand que la date du jour
			  AND (URC.CotisationID IS NULL -- Élimine les RES et OUT sans chèque qui n'ont pas de raison de ne pas émettre de cheque
				 OR O.OperTypeID = 'TFR'
				 OR Ch.OperID IS NOT NULL
				 OR ISNULL(NCR.NoChequeReasonImplicationID,0) = 1
				 OR OC.OperID IS NOT NULL
				 OR TIO.iOUTOperID IS NOT NULL)
			  AND (O.OperTypeID NOT IN ('RET','RIN', 'PAE', 'AVC') -- Exclus les opérations qui doivent émettre un cheque et qui n'en émet pas
				 OR Ch.OperID IS NOT NULL
				 OR OC.OperID IS NOT NULL)
			GROUP BY 
				Ct.OperID,
				Ct.EffectDate,
				CASE 
					WHEN L.ConventionID IS NULL THEN 1
				ELSE 0
				END
			-----
			UNION
			-----
			SELECT 
				O.OperID,
				EffectDate = O.OperDate,
				Cotisation = 0,
				Fee = 0,
				SubscInsur = 0,
				BenefInsur = 0,
				TaxOnInsur = 0,
				ClientInt = 
					SUM(CASE 
							 WHEN CO.ConventionOperTypeID = 'INC' THEN CO.ConventionOperAmount
						 ELSE 0
						 END),
				AvailableFee =
					SUM(CASE 
							 WHEN CO.ConventionOperTypeID = 'FDI' THEN CO.ConventionOperAmount
						 ELSE 0
						 END),
				LockAccount = 
					CASE 
						WHEN L.ConventionID IS NULL THEN 1
					ELSE 0
					END
			FROM Un_Oper O
			JOIN Un_ConventionOper CO ON CO.OperID = O.OperID
			JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
			JOIN #Convention T ON T.ConventionID = C.ConventionID
			LEFT JOIN ( -- Va chercher les opérations RES et OUT sans raison avec implication 'RES à zéro'
				SELECT DISTINCT
					T.ConventionID,
					Ct.OperID
				FROM #Convention T
				JOIN dbo.Un_Unit U ON U.ConventionID = T.ConventionID
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
				JOIN Un_UnitReduction UR ON UR.UnitReductionID = URC.UnitReductionID
				LEFT JOIN Un_NoChequeReason NCR ON NCR.NoChequeReasonID = UR.NoChequeReasonID
				WHERE ISNULL(NCR.NoChequeReasonImplicationID,0) <> 1
				) UR ON UR.ConventionID = C.ConventionID AND O.OperID = UR.OperID
			-- Va chercher les informations des chèques
			LEFT JOIN (
				SELECT DISTINCT L.OperID
				FROM Un_OperLinkToCHQOperation L
				JOIN CHQ_OperationDetail OD ON OD.iOperationID = L.iOperationID
				JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
				) Ch ON Ch.OperID = O.OperID
			LEFT JOIN Un_OperCancelation OC ON OC.OperSourceID = O.OperID OR OC.OperID = O.OperID
			LEFT JOIN Un_TIO TIO ON TIO.iOUTOperID = O.OperID
			LEFT JOIN #LockAccount L ON C.ConventionID = L.ConventionID AND (
													CASE 
														WHEN L.EffectDate IS NULL THEN O.Operdate+1
														WHEN L.EffectDate < '2003-01-01' THEN O.Operdate-1
														WHEN O.OperTypeID = 'FCB' THEN O.Operdate-1
														WHEN O.OperTypeID = 'RCB' THEN O.Operdate+1
														WHEN L.EffectDate = O.OperDate AND O.OperID < L.FCBOperID THEN O.Operdate+1
													ELSE L.EffectDate
													END <= O.OperDate)
			WHERE CO.ConventionOperTypeID IN ('INC','FDI')
			  AND O.OperDate <= GETDATE() -- Élimine les transactions dont la date d'opération est plus grand que la date du jour
			  AND (UR.ConventionID IS NULL -- Élimine les RES et OUT sans chèque qui n'ont pas de raison de ne pas émettre de cheque
				 OR O.OperTypeID = 'TFR'
				 OR Ch.OperID IS NOT NULL
				 OR OC.OperID IS NOT NULL
				 OR TIO.iOUTOperID IS NOT NULL)
			  AND (O.OperTypeID NOT IN ('RET','RIN', 'PAE', 'AVC') -- Exclus les opérations qui doivent émettre un cheque et qui n'en émet pas
				 OR Ch.OperID IS NOT NULL
				 OR OC.OperID IS NOT NULL)
			GROUP BY 
				O.OperDate,
				O.OperID,
				CASE 
					WHEN L.ConventionID IS NULL THEN 1
				ELSE 0
				END
			) V
			GROUP BY 
				OperID,
				LockAccount
		) Ct ON Ct.OperID = O.OperID
	-- Va chercher les informations des chèques
	LEFT JOIN (
		SELECT DISTINCT L.OperID
		FROM Un_OperLinkToCHQOperation L
		JOIN CHQ_OperationDetail OD ON OD.iOperationID = L.iOperationID
		JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
		) Ch ON Ch.OperID = O.OperID
	LEFT JOIN Un_OperLinkToCHQOperation L ON L.OperID = O.OperID
	LEFT JOIN Un_ChequeSuggestion CS ON CS.OperID = O.OperID
	LEFT JOIN Un_OperCancelation CO ON CO.OperSourceID = O.OperID
	LEFT JOIN Un_OperCancelation AO ON AO.OperID = O.OperID
	LEFT JOIN UN_CESP400 C4 ON O.OperID = C4.OperID -- 2010-05-10
	WHERE Ct.OperID IS NOT NULL
		AND O.OperTypeID NOT IN ('BEC')
		AND NOT (C4.tiCESP400TypeID IN (19, 23) AND C4.fCLB = 0 AND C4.fCESG = 0 AND C4.fACESGPart = 0 AND C4.fCotisation = 0 ) -- 2010-05-10
		
	ORDER BY 
		O.OperDate DESC, 
		O.OperID DESC 

	-- Détruit les tables temporaires
	DROP TABLE #LockAccount
	DROP TABLE #Convention
	DROP TABLE #Unit
END


