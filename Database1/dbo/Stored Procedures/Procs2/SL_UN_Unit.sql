/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_Unit
Description         :	Procédure retournant les données d'un groupe d'unités
Valeurs de retours  :	Dataset de données
Note                :					2004-04-29	Dominic Létourneau	Création
										2004-04-30	Dominic Létourneau	Modification pour 10.23.1 (3.3) : Retrouve l'état actuel d'un groupe d'unités
										2004-05-31	Bruno Lapointe		10.34 (1.1) : Retourne le nom du directeur du groupe d'unités
						ADX0000670	IA	2005-03-14	Bruno Lapointe		Retourne la date de dernier dépôt pour relevés et contrats.
						ADX0001350	BR 	2005-03-21	Bruno Lapointe		Correction du compteur d'horaire de prélèvement
						ADX0001114	IA	2006-11-20	Alain Quirion		Ajout du champ IntReimbDateAdjust
						ADX0001357	IA	2007-06-04	Alain Quirion		Ajout de bIsContestWinner
						ADX0001355	IA	2007-06-06	Alain Quirion		Ajout de : dtCotisationEndDateAdjust, dtInforceDateTIN
						ADX0001355	IA	2007-08-23	B.L.					Ajout de : YearQty
										2008-06-10	Jean-Francois Arial	Ajout du numéro de la convention individuelle
										2009-06-16	Patrick Robitaille	Ajout du champ iSous_Cat_ID pour gérer les catégories de groupes d'unités
                                        2017-12-05  Pierre-Luc Simard   Ne plus valider la table Un_RepBusinessBonusCfg
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_Unit] (
	@ConnectID INTEGER, -- Identifiant unique de la connection	
	@UnitID INTEGER) -- Identifiant unique du groupe d'unités à récupérer
AS
BEGIN

	-- Table temporaire de nombre d'année à ajouter à la date d'entrée en vigueur
	-- pour déterminer la date de fin de cotisation
	DECLARE @tUn_MaxConvDepositDateCfg TABLE (
		dtStart DATETIME NOT NULL,
		dtEnd DATETIME NOT NULL,
		YearQty INT NOT NULL )

	INSERT INTO @tUn_MaxConvDepositDateCfg
	SELECT
		dtStart = M.EffectDate,
		dtEnd = ISNULL(MIN(M2.EffectDate)-1, dbo.fn_CRQ_DateNoTime(GETDATE())),
		M.YearQty
	FROM Un_MaxConvDepositDateCfg M
	LEFT JOIN Un_MaxConvDepositDateCfg M2 ON M2.EffectDate > M.EffectDate OR (M2.EffectDate = M.EffectDate AND M2.MaxConvDepositDateCfgID > M.MaxConvDepositDateCfgID)
	GROUP BY
		M.EffectDate,
		M.YearQty

	-- Retourne les infos d'un groupe d'unités
	SELECT
		U.UnitID,
		U.ConventionID,
		U.ModalID,
		U.UnitQty,
		InForceDate = ISNULL(U.InForceDate,-2),
		SignatureDate = ISNULL(U.SignatureDate,-2),
		U.TerminatedDate,
		U.IntReimbDate,
		U.BenefInsurID,
		U.WantSubscriberInsurance,
		St.StateTaxPct,
		Cotisation = ISNULL(Ct.Cotisation, 0),
		Fee = ISNULL(Ct.Fee, 0),
		U.ActivationConnectID,
		U.ValidationConnectID,
		URepID = U.RepID,
		U.PmtEndConnectID,
		U.IntReimbDateAdjust,
		U.StopRepComConnectID,
		URepName = CASE ISNULL(U.RepID,0) WHEN 0 THEN '' ELSE R.LastName + ', ' + R.FirstName END,
		URepResponsableID =  U.RepResponsableID,
		URepResponsableName = CASE ISNULL(U.RepResponsableID,0) WHEN 0 THEN '' ELSE RR.LastName + ', ' + RR.FirstName END,
		U.SubscribeAmountAjustment,
		U.dtCotisationEndDateAdjust, 
		U.dtInforceDateTIN,
		M.ModalDate,
		M.BenefAgeOnBegining,
		M.PmtByYearID,
		M.PmtQty,
		M.PmtRate,
		M.SubscriberInsuranceRate,
		M.FeeByUnit,
		M.FeeSplitByUnit,
		M.FeeRefundable,
		P.tiAgeQualif,
		M.BusinessBonusToPay,
		M.PlanID,
		P.PlanTypeID,
		P.PlanDesc,
		P.PlanScholarshipQty,
		P.PlanORderID,
		P.PlanGovernmentRegNo,
		P.IntReimbAge,
		BI.BenefInsurDate,
		BI.BenefInsurFaceValue,
		BI.BenefInsurPmtByYear,
		BI.BenefInsurRate,
		AutomaticDepositCount = ISNULL(AD.AutomaticDepositCount, 0),
		UnitHoldPayment = ISNULL(uhp.UnitID, 0), --Indique la présence d'un arrêt de paiement si <> 0
		SS.SaleSourceID,   --point 718
		SS.SaleSourceDesc,  --point 718
		bIsContestWinner = ISNULL(SS.bIsContestWinner,0),
		US.UnitStateID,
		US.UnitStateName,
		UDirName = CASE ISNULL(DIR.BossID,0) WHEN 0 THEN '' ELSE HDIR.LastName + ', ' + HDIR.FirstName END,
		U.LastDepositForDoc, -- Date de dernier dépôt pour le contrat et les relevés de dépôts
		MCD.YearQty,
		C2.ConventionNo as ConventionNoInd, --No convention individuelle JFA 2008-06-10
		U.iSous_Cat_ID
	FROM dbo.Un_Unit U
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	JOIN Un_Plan P ON P.PlanID = M.PlanID
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
	LEFT JOIN Mo_State St ON St.StateID = S.StateID
	LEFT JOIN (-- Retourne le total des cotisations et de frais par unité
		SELECT 
			Ct.UnitID, 
			Cotisation = SUM(Ct.Cotisation), 
			Fee = SUM(Ct.Fee)
		FROM Un_Cotisation Ct
		INNER JOIN Un_Oper O ON O.OperID = Ct.OperID
		LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
		WHERE ((O.OperTypeID = 'CPA' AND ISNULL(OBF.OperID, 0) > 0) OR O.OperDate < = GETDATE())
			AND CT.UnitID = @UnitID
		GROUP BY CT.UnitID
		) Ct ON Ct.UnitID = U.UnitID
	LEFT JOIN dbo.Mo_Human R ON R.HumanID = U.RepID
	LEFT JOIN dbo.Mo_Human RR ON RR.HumanID = U.RepResponsableID
	LEFT JOIN (-- Retourne le nombre de dépôt par unité
		SELECT
			UnitID,
			AutomaticDepositCount = COUNT(AutomaticDepositID)
		FROM Un_AutomaticDeposit
		WHERE UnitID = @UnitID
			AND	( dbo.FN_CRQ_DateNoTime(GETDATE()) BETWEEN StartDate AND EndDate
					 OR	( dbo.FN_CRQ_DateNoTime(GETDATE()) >= StartDate 
							AND ISNULL(EndDate,0) < 2
							)
					)
		GROUP BY UnitID
		) AD ON AD.UnitID = U.UnitID
	LEFT JOIN (-- Sert à la d‚tection d'un arrêt de paiement sur le groupe d'unités
		SELECT DISTINCT UnitID  
		FROM Un_UnitHoldPayment
		WHERE ISNULL(EndDate,0) <= 0
			OR (StartDate <= dbo.fn_Mo_DateNoTime(GETDATE()) AND EndDate >= dbo.fn_Mo_DateNoTime(GETDATE()))
		) UHP ON UHP.UnitID = U.UnitID
	LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
	LEFT JOIN (-- 10.23.1 (3.3) : Retrouve l'état actuel d'un groupe d'unités
		SELECT 
			T.UnitID,
			US.UnitStateID,
			US.UnitStateName
		FROM (-- Retourne la plus grande date de début d'un état par unité
				SELECT 
					UnitID,
					MaxDate = MAX(StartDate)
				FROM Un_UnitUnitState
				WHERE UnitID = @UnitID
					AND StartDate <= GETDATE()
				GROUP BY UnitID
			) T
		INNER JOIN Un_UnitUnitState UUS
			ON T.UnitID = UUS.UnitID
			AND T.MaxDate = UUS.StartDate -- Retrouve l'état correspondant à la plus grande date par unité
		INNER JOIN Un_UnitState US ON UUS.UnitStateID = US.UnitStateID -- Pour retrouver la description de l'état
		) US ON U.UnitID = US.UnitID
	LEFT JOIN (
		SELECT
			M.UnitID,
			BossID = MAX(RBH.BossID)
		FROM (
			SELECT
				U.UnitID,
				U.RepID,
				RepBossPct = MAX(RBH.RepBossPct)
			FROM dbo.Un_Unit U
			JOIN Un_RepBossHist RBH ON (RBH.RepID = U.RepID) AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
			JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
			JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
			--JOIN Un_RepBusinessBonusCfg RBB ON (RBB.RepRoleID = RBH.RepRoleID) AND (U.InForceDate >= RBB.StartDate) AND (U.InForceDate <= RBB.EndDate OR RBB.EndDate IS NULL)
			WHERE U.UnitID = @UnitID
			GROUP BY U.UnitID, U.RepID
			) M
		JOIN dbo.Un_Unit U ON (U.UnitID = M.UnitID)
		JOIN Un_RepBossHist RBH ON (RBH.RepID = M.RepID) AND (RBH.RepBossPct = M.RepBossPct) AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
		WHERE U.UnitID = @UnitID
		GROUP BY M.UnitID
		) DIR ON (DIR.UnitID = U.UnitID)
	LEFT JOIN dbo.Mo_Human HDIR ON (HDIR.HumanID = DIR.BossID)
	LEFT JOIN @tUn_MaxConvDepositDateCfg MCD ON U.InForceDate BETWEEN MCD.dtStart AND MCD.dtEnd
	LEFT JOIN tblOPER_OperationsRIO OpRIO ON (OpRIO.iID_Convention_Source = C.ConventionID AND OpRIO.iID_Unite_Source = U.UnitID AND bRIO_Annulee = 0)
	LEFT JOIN dbo.Un_Convention C2 ON (OpRIO. iID_Convention_Destination = C2.ConventionID)
	WHERE U.UnitID = @UnitID
END


