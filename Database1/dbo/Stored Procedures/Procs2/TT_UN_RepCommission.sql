/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_RepCommission 
Description         :	C'est la procédure principale du traitement des commissions.  Elle appelle	plusieurs sous
								procédures, mais c'est elle qui est appelé par le SQL Agent pour le lancement automatique des
								traitements de commissions.
Valeurs de retours  :	@ReturnValue :
									>0 :	Le traitement a réussi.
									<=0 :	Le traitement a échoué.
Note                :	ADX0000696	IA	2005-08-17	Bruno Lapointe		Création
								ADX0001001	UP	2006-08-31	Bruno Lapointe		Correction du bogue de rerise et redonnage de 
																							commissions quand le représentant qui a fait la 
																							vente est aussi le directeur d'agence et qu'il 
																							est remplacé par une autre représentant.
								ADX0002350	UR	2006-11-22	Bruno Lapointe		Correction du bogue d'arrondissement (Float) des
																							commissions de services. 
												2012-05-06	Pierre-Luc Simard	Désactivation du traitement pour la table Un_RepAccount
                                                2018-02-16  Pierre-Luc Simard   Exclure aussi les groupes d'unités avec un RIN partiel
                                                2018-05-17  Pierre-Luc Simard   Ajout des PlanID dans Un_RepLevelBracket
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_RepCommission] (
	@ConnectID INTEGER, -- ID unique de connexion de l’usager qui a lancé le traitement.
	@RepTreatmentDate DATETIME ) -- Dernier jour inclusivement à traiter dans le traitement.
AS
BEGIN
	DECLARE
		@iResult INTEGER, 
		@iRepTreatmentID INTEGER,
		@fMaxRepRisk MONEY,
		@dtLastTreatmentDate DATETIME

	-- Va chercher la plus grande date de traitement de commissions comme date du traitement précédent
	SELECT 
		@dtLastTreatmentDate = ISNULL(MAX(RepTreatmentDate), 0)   
	FROM Un_RepTreatment   

	-- Va chercher le maximum de % de risque accepté pour un représentant
	SELECT 
		@fMaxRepRisk = ISNULL(MaxRepRisk, 0)
	FROM Un_Def
	IF @fMaxRepRisk = 0
		RETURN(-1)

	-- Traitement qui crée automatiquement toutes les exceptions de commissions et bonis d’affaires pour les réductions d’unités.
	EXECUTE @iResult = TT_UN_RepExceptionForUnitReduction @ConnectID, @RepTreatmentDate
	IF @iResult < = 0 
	BEGIN
		SET @iResult = -2
		GOTO ON_Error
	END
  
	-- Traitement qui crée automatiquement toutes les exceptions de commissions et bonis d’affaires pour les frais non commissionnés
	-- (Ex : TFR).
	EXECUTE @iResult = TT_UN_RepExceptionForUncommissionFees @ConnectID, @RepTreatmentDate
	IF @iResult < = 0 
	BEGIN
		SET @iResult = -3
		GOTO ON_Error
	END

	-- Retourne toutes les groupes d’unités avec le montant d’avance et de commission de service que devrait avoir touché le représentant
	-- par unité selon les frais cotisés antérieurement ou à la date passée en paramètre.
	CREATE TABLE #tRepCommissionForPeriod (
		UnitID INTEGER NOT NULL, -- ID du groupe d'unités
		RepLevelID INTEGER NOT NULL, -- Niveau du représentant
		SumComByUnit MONEY NOT NULL, -- Somme des tombés de commission de service par unités pour ce niveau et ce groupe d'unités
		SumAdvByUnit MONEY NOT NULL, -- Somme des tombés d'avance par unités pour ce niveau et ce groupe d'unités
		TotalFee MONEY NOT NULL,  -- Total des frais pour le groupe d'unités
		CONSTRAINT PK_RepCommissionForPeriod PRIMARY KEY (UnitID,RepLevelID) )
	INSERT INTO #tRepCommissionForPeriod 
		EXECUTE SL_UN_RepCommissionForPeriod @RepTreatmentDate 
	IF @@ERROR <> 0
		RETURN(-4)

	--	Retourne toutes les groupes d’unités avec le montant d’avance et de commission de service que devrait avoir touché les supérieurs
	-- du représentant par unité selon les frais cotisés antérieurement ou à la date passée en paramètre.
	CREATE TABLE #tRepBossCommissionForPeriod (
		UnitID INTEGER NOT NULL, -- ID du groupe d'unités
		RepID INTEGER NOT NULL, -- ID du représentant
		RepLevelID INTEGER NOT NULL, -- Niveau du représentant
		RepBossID INTEGER NOT NULL, -- ID du supérieur
		RepBossPct FLOAT NOT NULL, -- Pourcentage de commissions du supérieur pour ce rôle
		SumComByUnit MONEY NOT NULL, -- Somme des tombés de commission de service par unités pour ce niveau, ce supérieur et ce groupe d'unités
		SumCadByUnit MONEY NOT NULL, -- Somme des tombés d'avance couverte par unités pour ce niveau, ce supérieur et ce groupe d'unités
		SumAdvByUnit MONEY NOT NULL, -- Somme des tombés d'avance par unités pour ce niveau, ce supérieur et ce groupe d'unités
		TotalFee MONEY NOT NULL, -- Total des frais pour le groupe d'unités
		CONSTRAINT PK_RepBossCommissionForPeriod PRIMARY KEY (UnitID, RepID, RepLevelID, RepBossID) )
	INSERT INTO #tRepBossCommissionForPeriod 
		EXECUTE SL_UN_RepBossCommissionForPeriod @RepTreatmentDate  
	IF @@ERROR <> 0
		RETURN(-5)

	-- Retourne toutes les groupes d’unités avec le nombre d’unités qu’ils avaient à la date passée en paramètre.  Le champ UnitQty
	-- du groupe d'unités est mis à jour immédiatement lors d'une réduction d'unités même si cette dernière est datée ultérieurement.
	-- Pour connaître le nombre réel d'unités qu'il y avait dans un groupe d'unités à une date précise, il faut donc additionné au champ
	-- Un_Unit.UnitQty le nombre d'unités résilié ultérieurement à la date.
	CREATE TABLE #TRepUnitQtyForPeriod (
		UnitID INTEGER PRIMARY KEY, -- ID du groupe d'unités
		UnitQty MONEY NOT NULL) -- Nombre d'unités en date du traitement (Inclus les unités résiliés ultérieurement)
	INSERT INTO #TRepUnitQtyForPeriod 
		EXECUTE SL_UN_RepUnitQtyForPeriod @RepTreatmentDate  
	IF @@ERROR <> 0
		RETURN(-6)

	-- Table temporaire qui contient la somme des commissions déjà versées par goupe d'unités, représentant et niveau de représentant
	SELECT 
		R.UnitID, -- ID du groupe d'unités
		R.RepID, -- ID du représentant
		R.RepLevelID, -- ID du niveau du représentant
		TotalCommPaid = SUM(R.CommissionAmount), -- Somme des commissions de service déjà versées pour ce représentant, ce groupe d'unités et ce niveau
		TotalAdvancePaid = SUM(R.AdvanceAmount), -- Somme des avances déjà versées pour ce représentant, ce groupe d'unités et ce niveau
		TotalCoveredAdvancePaid = SUM(R.CoveredAdvanceAmount)  -- Somme des avances couvertes déjà versées pour ce représentant, ce groupe d'unités et ce niveau
	INTO #tRepCommissionPaid
	FROM Un_RepCommission R 
	GROUP BY
		R.UnitID,
		R.RepID,
		R.RepLevelID

	IF @@ERROR <> 0
		RETURN(-7)

	-- Table temporaire qui contient le total par groupe d'unités, représentant et niveau des commissions de service et avances qui
	-- devrait être versé pour cette ventes (groupe d'unités) incluant le passé le présent et le futur.
	-- Avant le UNION c'est pour les représentants uniquement
	SELECT 
		U.UnitID, -- ID du groupe d'unités
		U.RepID, -- ID du représentant
		RH.RepLevelID, -- ID du niveau du représentant
		RepPct = CAST('100.00' AS FLOAT), -- Pourcentage de commissions du représentant pour ce groupe d'unités, ce représentant et ce niveau
		TotalLevelCommAmount = SUM(VRB.SumComByUnit), -- Total de commissions de service que devrait toucher ce représentant pour ce niveau par unité de ce groupe d'unités
		TotalLevelAdvanceAmount = SUM(VRB.SumAdvByUnit) -- Total d'avances que devrait toucher ce représentant pour ce niveau par unité de ce groupe d'unités
	INTO #TRepTotalLevelBracket
	FROM dbo.Un_Unit U
    JOIN Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN Un_RepLevelHist RH ON RH.RepID = U.RepID
	JOIN Un_RepLevel RL ON RL.RepLevelID = RH.RepLevelID AND RL.RepRoleID = 'REP' 
	JOIN (
		-- Retourne les configurations des tombés dans on format de définition de colonne différent
		SELECT  
			RepLevelID, -- ID du niveau du représentant
            PlanID, -- Plan de la convention
			TargetFeeByUnit, -- Frais par unités à atteindre pour que la tombé soit versée
			EffectDate, -- Date d'Entrée en vigueur de la configuration
			TerminationDate, -- Date de fin de vigueur de la configuration
			SumComByUnit = AdvanceByUnit, -- Montant de la tombés de commissions de service
			SumAdvByUnit = 0 -- Montant de la tombés d'avances
		FROM Un_RepLevelBracket 
        WHERE RepLevelBracketTypeID = 'COM' -- Configuration de tombés de commissions de service seulement
		-----
		UNION
		----- 
		SELECT  
			RepLevelID, -- ID du niveau du représentant
            PlanID, -- Plan de la convention
			TargetFeeByUnit, -- Frais par unités à atteindre pour que la tombé soit versée
			EffectDate, -- Date d'Entrée en vigueur de la configuration
			TerminationDate, -- Date de fin de vigueur de la configuration 
			SumComByUnit = 0, -- Montant de la tombés de commissions de service
			SumAdvByUnit = AdvanceByUnit -- Montant de la tombés d'avances
		FROM Un_RepLevelBracket 
		WHERE RepLevelBracketTypeID = 'ADV' -- Configuration de tombés d'avances seulement
		) VRB ON VRB.RepLevelID = RL.RepLevelID AND VRB.PlanID = C.PlanID
	-- Filtre sur le niveau qu'avait le représentant lors de la vente (Date d'entrée en vigueur du groupe d'unités)
	WHERE	( U.InForceDate >= RH.StartDate
			AND( U.InForceDate <= RH.EndDate
				OR RH.EndDate IS NULL
				)
			)
		-- Filtre les configurations de tombés pour avoir seulement ceux en vigueur pour le groupe d'unités
		AND( U.InForceDate >= VRB.EffectDate
			AND( U.InForceDate <= VRB.TerminationDate
				OR VRB.TerminationDate IS NULL
				)
			)
	GROUP BY
		U.UnitID,
		U.RepID,
		RH.RepLevelID
	-----
	UNION
	-----
	-- Même chose pour les supérieurs
	SELECT 
		V.UnitID, -- ID du groupe d'unités
		V.RepID, -- ID du représentant
		V.RepLevelID, -- ID du niveau
		V.RepPct, -- Pourcentage de commissions pour ce niveau
		TotalLevelCommAmount = SUM(V.SumComByUnit), -- Total de commissions de service que devrait toucher ce supérieur (% pas calculé) pour ce niveau par unité de ce groupe d'unités 
		TotalLevelAdvanceAmount = SUM(V.SumAdvByUnit) -- Total des avances que devrait toucher ce supérieur (% pas calculé) pour ce niveau par unité de ce groupe d'unités 
	FROM (
		SELECT DISTINCT
			U.UnitID, -- ID du groupe d'unités
			RepID = RH.BossID, -- ID du supérieur
			RLH.RepLevelID, -- ID du niveau
			VRB.SumComByUnit, -- Montant de la tombés de commissions de service
			VRB.SumAdvByUnit, -- Montant de la tombés d'avance
			RepPct = RH.RepBossPct -- Pourcentage de commissions du supérieur
		FROM dbo.Un_Unit U
        JOIN Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Un_RepBossHist RH ON RH.RepID = U.RepID
		JOIN Un_RepLevelHist RLH ON RLH.RepID = RH.BossID
		JOIN Un_RepLevel RL ON RL.RepLevelID = RLH.RepLevelID AND RL.RepRoleID = RH.RepRoleID AND (RL.RepRoleID <> 'REP')
		JOIN (
			-- Retourne les configurations des tombés dans on format de définition de colonne différent
			SELECT  
				RepLevelID, -- ID du niveau
                PlanID, -- Plan de la convention
				TargetFeeByUnit, -- Frais par unités à atteindre pour que la tombé soit versée
				EffectDate, -- Date d'Entrée en vigueur de la configuration 
				TerminationDate, -- Date de fin de vigueur de la configuration 
				SumComByUnit = AdvanceByUnit, -- Montant de la tombés de commissions de service
				SumAdvByUnit = 0 -- Montant de la tombés d'avances
			FROM Un_RepLevelBracket 
			WHERE RepLevelBracketTypeID = 'COM' -- Configuration de tombés de commissions de service seulement
			-----
			UNION
			----- 
			SELECT  
				RepLevelID, -- ID du niveau
                PlanID, -- Plan de la convention
				TargetFeeByUnit, -- Frais par unités à atteindre pour que la tombé soit versée
				EffectDate, -- Date d'Entrée en vigueur de la configuration
				TerminationDate, -- Date de fin de vigueur de la configuration 
				SumComByUnit = 0, -- Montant de la tombés de commissions de service
				SumAdvByUnit = AdvanceByUnit -- Montant de la tombés d'avances
			FROM Un_RepLevelBracket 
			WHERE RepLevelBracketTypeID = 'ADV' -- Configuration de tombés d'avances seulement
			) VRB ON VRB.RepLevelID = RL.RepLevelID AND VRB.PlanID = C.PlanID
		-- Filtre sur le niveau qu'avait le supérieur lors de la vente (Date d'entrée en vigueur du groupe d'unités)
		WHERE ( U.InForceDate > = RLH.StartDate
				AND( U.InForceDate <= RLH.EndDate
					OR RLH.EndDate IS NULL
					)
				)
			-- Filtre sur les supérieurs qu'avait le représentant lors de la vente (Date d'entrée en vigueur du groupe d'unités)
			AND( U.InForceDate > = RH.StartDate
				AND( U.InForceDate <= RH.EndDate
					OR RH.EndDate IS NULL
					)
				)
			-- Filtre les configurations de tombés pour avoir seulement ceux en vigueur pour le groupe d'unités
			AND( U.InForceDate > = VRB.EffectDate
				AND( U.InForceDate <= VRB.TerminationDate
					OR VRB.TerminationDate IS NULL
					)
				)
		) V
	GROUP BY
		V.UnitID,
		V.RepID,
		V.RepLevelID,
		V.RepPct

	IF @@ERROR <> 0
		RETURN(-8)

	--	Table temporaire des groupes d'unités qui on des frais non commissionnés.  Car pour les avances sont remplacés par des commissions
	-- de service.  Pour les représentants les commissions de servives remplacant les avances seront versées 0,01$ pour 0,01 de frais 
	-- jusqu'à concurrence de montant qu'il devait toucher en avances.  Pour les supérieurs ils seront versés à la place et aux montants
	-- des tombés d'avances couvertes.
	SELECT DISTINCT
		C.UnitID
	INTO #TRepTransacNoComm
	FROM Un_Cotisation C
	JOIN Un_Oper O ON O.OperID = C.OperID
	JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
	WHERE OT.CommissionToPay = 0
		AND (C.Fee > 0)
		AND (O.OperDate < = @RepTreatmentDate)

	-- Insère un enregistrement dans la table listant les traitements de commissions.
	EXECUTE @iRepTreatmentID = IU_UN_RepTreatment @ConnectID, @RepTreatmentDate, @fMaxRepRisk
	IF @iRepTreatmentID < = 0 
	BEGIN
		SET @iResult = -9
		GOTO ON_Error
	END 

	-- Insère dans une table temporaire les commissions dû au représentant par groupe d'unités et niveau pour ce traitement de 
	-- commissions.  Bien sûr on fait le calcul des commissions dû d'abord.
	SELECT 
		V.RepTreatmentID, -- ID du traitement de commissions
		V.RepID, -- ID du représentant
		V.RepLevelID, -- ID du niveau
		V.RepPct, -- Pourcentage de commissions
		V.UnitID, -- ID du groupe d'unités
		V.UnitQty, -- Nombre d'unités
		V.TotalFee, -- Total des frais cotisés pour ce groupe d'unités
		V.CommissionAmount, -- Montant de commissions de service à verser dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
		V.AdvanceAmount, -- Montant d'avances à verser dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
		V.CoveredAdvanceAmount -- Montant d'avances couvertes à verser dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
	INTO #tRepCommission
	FROM (
		SELECT 
			RepTreatmentID = @iRepTreatmentID, -- ID du traitement de commissions
			R.RepID, -- ID du représentant
			VRL.RepLevelID, -- ID du niveau
			RepPct = CAST('100.00' AS FLOAT), -- Pourcentage de commissions
			U.UnitID, -- ID du groupe d'unités
			VU.UnitQty, -- Nombre d'unités
			VRL.TotalFee, -- Total des frais cotisés pour ce groupe d'unités
			CommissionAmount = -- Montant de commissions de service à verser dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
				CASE
					-- Cas de groupe d'unités sans frais non commissionnés
					WHEN ISNULL(VT.UnitID, 0) = 0 THEN
						ROUND((VRL.SumComByUnit * VU.UnitQty), 2) - ISNULL(VRA.TotalCommPaid, 0)
				ELSE 
					-- Cas de groupe d'unités avec frais non commissionnés
					CASE 
						-- Cas ou le montant de frais cotisés pour le groupe d'unités ne dépasse pas le montant de tombés d'avances qui est
						-- remplacés par des commissions de service.
						WHEN VRL.SumAdvByUnit * VU.UnitQty >= VRL.TotalFee THEN
							ROUND((VRL.SumComByUnit * VU.UnitQty) + VRL.TotalFee, 2) - ISNULL(VRA.TotalCommPaid, 0)
					ELSE
						ROUND((VRL.SumComByUnit * VU.UnitQty) + (VRL.SumAdvByUnit * VU.UnitQty), 2) - ISNULL(VRA.TotalCommPaid, 0)
					END
				END,
			AdvanceAmount = -- Montant d'avances à verser dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
				CASE  
					-- Cas de groupe d'unités sans frais non commissionnés
					WHEN ISNULL(VT.UnitID, 0) = 0 THEN
						ROUND(VRL.SumAdvByUnit * VU.UnitQty, 2) - ISNULL(VRA.TotalAdvancePaid, 0)
				ELSE
					-- Cas de groupe d'unités avec frais non commissionnés.  Enlève les avances s'il y en a
					-ISNULL(VRA.TotalAdvancePaid, 0)
				END, 
			CoveredAdvanceAmount = -- Montant d'avances couvertes à verser dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
				CASE  
					-- Cas de groupe d'unités sans frais non commissionnés
					WHEN ISNULL(VT.UnitID, 0) = 0 THEN 
						CASE 
							-- Cas ou le montant de frais cotisés pour le groupe d'unités ne dépasse pas le montant de tombés d'avances 
							-- couvertes.
							WHEN (VRL.TotalFee >= 0) AND (VRL.SumAdvByUnit * VU.UnitQty >= VRL.TotalFee) THEN
								ROUND(VRL.TotalFee, 2) - ISNULL(VRA.TotalCoveredAdvancePaid, 0)
						ELSE
							ROUND(VRL.SumAdvByUnit * VU.UnitQty, 2) - ISNULL(VRA.TotalCoveredAdvancePaid, 0)
						END
					ELSE
						-- Cas de groupe d'unités avec frais non commissionnés.  Enlève les avances couverte s'il y en a
						-ISNULL(VRA.TotalCoveredAdvancePaid, 0)
				END     
		FROM Un_Rep R
		JOIN dbo.Un_Unit U ON U.RepID = R.RepID
		JOIN #TRepUnitQtyForPeriod VU ON VU.UnitID = U.UnitID
		JOIN #tRepCommissionForPeriod VRL ON VRL.UnitID = U.UnitID
		JOIN #TRepTotalLevelBracket RLB ON RLB.UnitID = U.UnitID AND RLB.RepID = R.RepID AND RLB.RepLevelID = VRL.RepLevelID
		LEFT JOIN #tRepCommissionPaid VRA ON VRA.UnitID = U.UnitID AND VRA.RepLevelID = VRL.RepLevelID AND VRA.RepID = U.RepID
		LEFT JOIN #TRepTransacNoComm VT ON VT.UnitID = U.UnitID
		WHERE R.StopRepComConnectID IS NULL -- Exclus les tombés de commissions aux représentant en arrêt de paiement de commissions
		) V
	-- Prend seulement les enregistrements qu'il y a un montant soit de commissions de service, soit d'avances ou soit d'avances couvertes
	-- à verser.
	WHERE (V.CommissionAmount <> 0)
		OR (V.AdvanceAmount <> 0)
		OR (V.CoveredAdvanceAmount <> 0)
	-----
	UNION
	-----
	-- Insère dans une table temporaire les commissions dues aux supérieurs par groupe d'unités et niveau pour ce traitement de 
	-- commissions.  Bien sûr on fait le calcul des commissions dues d'abord.
	SELECT 
		V.RepTreatmentID, -- ID du traitement de commissions
		V.RepID, -- ID du représentant
		V.RepLevelID, -- ID du niveau
		V.RepPct, -- Pourcentage de commissions
		V.UnitID, -- ID du groupe d'unités
		V.UnitQty, -- Nombre d'unités
		V.TotalFee, -- Total des frais cotisés pour ce groupe d'unités
		V.CommissionAmount, -- Montant de commissions de service à verser dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
		V.AdvanceAmount, -- Montant d'avances à verser dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
		V.CoveredAdvanceAmount -- Montant d'avances couvertes à verser dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
	FROM (
		SELECT 
			RepTreatmentID = @iRepTreatmentID, -- ID du traitement de commissions
			RepID = RB.RepBossID, -- ID du représentant(supérieur)
			RB.RepLevelID, -- ID du niveau
			RepPct = RB.RepBossPct, -- Pourcentage de commissions
			RB.UnitID, -- ID du groupe d'unités
			VU.UnitQty, -- Nombre d'unités
			RB.TotalFee, -- Total des frais cotisés pour ce groupe d'unités
			CommissionAmount = -- Montant de commissions de service à verser dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
				CASE  
					-- Cas de groupe d'unités sans frais non commissionnés
					WHEN ISNULL(VT.UnitID, 0) = 0 THEN
						ROUND((RB.SumComByUnit * VU.UnitQty) * (ISNULL(RB.RepBossPct, 0) / 100), 2) - ISNULL(VRA.TotalCommPaid, 0) 
				ELSE
					-- Cas de groupe d'unités avec frais non commissionnés.  Paye les avances couvertes en commissions de service en plus des
					-- tombés de commissions de service standard.
					ROUND(((RB.SumComByUnit + RB.SumCadByUnit) * VU.UnitQty) * (ISNULL(RB.RepBossPct, 0) / 100), 2) - ISNULL(VRA.TotalCommPaid, 0)
				END,
			AdvanceAmount = -- Montant d'avances à verser dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
				CASE  
					-- Cas de groupe d'unités sans frais non commissionnés
					WHEN ISNULL(VT.UnitID, 0) = 0 THEN
						ROUND((RB.SumAdvByUnit * VU.UnitQty) * (ISNULL(RB.RepBossPct, 0) / 100), 2) - ISNULL(VRA.TotalAdvancePaid, 0)
				ELSE
					-- Cas de groupe d'unités avec frais non commissionnés.  On enlève les avances s'il y en a.
					-ISNULL(VRA.TotalAdvancePaid, 0)
				END, 
			CoveredAdvanceAmount = -- Montant d'avances couvertes à verser dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
				CASE  
					-- Cas de groupe d'unités sans frais non commissionnés
					WHEN ISNULL(VT.UnitID, 0) = 0 THEN
						ROUND((RB.SumCadByUnit * VU.UnitQty) * (ISNULL(RB.RepBossPct, 0) / 100), 2) - ISNULL(VRA.TotalCoveredAdvancePaid, 0)
				ELSE
					-- Cas de groupe d'unités avec frais non commissionnés.  On enlève les avances couvertes s'il y en a.
					-ISNULL(VRA.TotalCoveredAdvancePaid, 0)
				END     
		FROM #tRepBossCommissionForPeriod RB
		JOIN Un_Rep R ON R.RepID = RB.RepBossID
		JOIN #TRepUnitQtyForPeriod VU ON VU.UnitID = RB.UnitID
		JOIN #TRepTotalLevelBracket RLB ON RLB.UnitID = RB.UnitID AND RLB.RepID = RB.RepBossID AND RLB.RepLevelID = RB.RepLevelID
		LEFT JOIN #tRepCommissionPaid VRA ON VRA.UnitID = RB.UnitID AND VRA.RepLevelID = RB.RepLevelID AND VRA.RepID = RB.RepBossID
		LEFT JOIN #TRepTransacNoComm VT ON VT.UnitID = RB.UnitID
		WHERE R.StopRepComConnectID IS NULL -- Exclus les tombés de commissions aux représentant en arrêt de paiement de commissions
		) V
	-- Prend seulement les enregistrements qu'il y a un montant soit de commissions de service, soit d'avances ou soit d'avances couvertes
	-- à verser.
	WHERE (V.CommissionAmount <> 0)
		OR (V.AdvanceAmount <> 0)
		OR (V.CoveredAdvanceAmount <> 0)
	-----
	UNION
	-----
	-- Enlève les commissions de service, avances et avances couvertes données à des représentants pour un mauvais niveau. Cela peut
	-- arriver à la suite d'une corection de l'historique des niveaux du représentant ou encore au changement de date d'entrée en vigueur
	-- du groupe d'unités.
	SELECT 
		RepTreatmentID = @iRepTreatmentID, -- ID du traitement de commissions
		R.RepID, -- ID du représentant
		R.RepLevelID, -- ID du niveau
		RepPct = 0, -- Pourcentage de commissions
		R.UnitID, -- ID du groupe d'unités
		UnitQty = 0, -- Nombre d'unités
		TotalFee = 0, -- Total des frais cotisés pour ce groupe d'unités
		CommissionAmount = -R.TotalCommPaid, -- Montant de commissions de service reprises dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
		AdvanceAmount = -R.TotalAdvancePaid, -- Montant d'avances reprises dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement. 
		CoveredAdvanceAmount = -R.TotalCoveredAdvancePaid -- Montant d'avances couvertes reprises dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
	FROM #tRepCommissionPaid R
	JOIN (
		-- Fait la liste des groupes d'unités qui ont reçu des commissions pour une niveau qui n'est pas celui indiquer présentement par
		-- l'historique des niveaux du représentant et la date de vigueur du groupe d'unités
		SELECT DISTINCT
			R.UnitID, -- ID du groupe d'unités
			R.RepID, -- ID du représentant
			L.RepLevelID -- ID du niveau
		FROM Un_RepCommission R
		JOIN dbo.Un_Unit U ON U.UnitID = R.UnitID
		JOIN Un_RepLevelHist H ON H.RepID = U.RepID AND (H.StartDate <= U.InForceDate) AND ((H.EndDate >= U.InForceDate) OR H.EndDate IS NULL)
		JOIN Un_RepLevel L ON L.RepLevelID = R.RepLevelID AND L.RepRoleID = 'REP'
		JOIN Un_RepLevel LH ON LH.RepLevelID = H.RepLevelID AND LH.RepRoleID = 'REP'
		WHERE L.RepLevelID <> LH.RepLevelID -- 
		) VU ON VU.UnitID = R.UnitID AND VU.RepID = R.RepID AND VU.RepLevelID = R.RepLevelID
	-- Prend seulement les enregistrements qu'il y a un montant de commissions de service ou d'avances à verser.
	WHERE (R.TotalCommPaid <> 0)
		OR (R.TotalAdvancePaid <> 0)
	-----
	UNION
	-----
	-- Enlève les commissions de service, avances et avances couvertes données à des représentants à qui on a retiré la vente pour la
	-- donner à un autre. Ce la peut arriver à la suite d'une correction d'erreurs de saisie du représentant.
	SELECT 
		RepTreatmentID = @iRepTreatmentID, -- ID du traitement de commissions
		R.RepID, -- ID du représentant
		R.RepLevelID, -- ID du niveau
		RepPct = 0, -- Pourcentage de commissions
		R.UnitID, -- ID du groupe d'unités
		UnitQty = 0, -- Nombre d'unités
		TotalFee = 0, -- Total des frais cotisés pour ce groupe d'unités
		CommissionAmount = -R.TotalCommPaid, -- Montant de commissions de service reprises dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
		AdvanceAmount = -R.TotalAdvancePaid, -- Montant d'avances reprises dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement. 
		CoveredAdvanceAmount = -R.TotalCoveredAdvancePaid -- Montant d'avances couvertes reprises dans ce traitement pour ce représentant, ce groupe d'unités, ce niveau et ce traitement.
	FROM #tRepCommissionPaid R
	JOIN (
		-- Fait la liste des groupes d'unités qui ont reçu des commissions pour un représentant qui n'est pas celui présentement indiquer
		-- sur le groupe d'unités
		SELECT DISTINCT
			R.UnitID, -- ID du groupe d'unités
			R.RepID -- ID du représentant
		FROM Un_RepCommission R
		JOIN dbo.Un_Unit U ON U.UnitID = R.UnitID
		JOIN Un_RepLevel L ON L.RepLevelID = R.RepLevelID
		WHERE L.RepRoleID = 'REP'
			AND (U.RepID <> R.RepID)
		) VU ON VU.UnitID = R.UnitID AND VU.RepID = R.RepID
	JOIN Un_RepLevel L ON L.RepLevelID = R.RepLevelID
	-- Prend seulement les enregistrements qu'il y a un montant de commissions de service ou d'avances à verser.
	WHERE L.RepRoleID = 'REP'
		AND( (R.TotalCommPaid <> 0)
			OR (R.TotalAdvancePaid <> 0)
			)
	-----
	UNION
	-----
	-- Enlève les commissions de service, avances et avances couvertes données à des supérieurs qui ne sont pas ceux indiqués par 
	-- l'historique des supérieurs du représentant qui a fait la vente et par la date de vigueur du groupe d'unités.
	SELECT 
		RepTreatmentID = @iRepTreatmentID, -- ID du traitement de commissions
		RC.RepID, -- ID du représentant(supérieur)
		RC.RepLevelID, -- ID du niveau
		RepPct = 0, -- Pourcentage de commissions
		RC.UnitID, -- ID du groupe d'unités
		UnitQty = 0, -- Nombre d'unités
		TotalFee = 0, -- Total des frais cotisés pour ce groupe d'unités
		CommissionAmount = -SUM(RC.CommissionAmount), -- Montant de commissions de service reprises dans ce traitement pour ce supérieur, ce groupe d'unités, ce niveau et ce traitement.
		AdvanceAmount = -SUM(RC.AdvanceAmount), -- Montant d'avances reprises dans ce traitement pour ce supérieur, ce groupe d'unités, ce niveau et ce traitement.
		CoveredAdvanceAmount = -SUM(RC.CoveredAdvanceAmount) -- Montant d'avances couvertes reprises dans ce traitement pour ce supérieur, ce groupe d'unités, ce niveau et ce traitement.
	FROM Un_RepCommission RC
	JOIN Un_RepLevel RL ON RL.RepLevelID = RC.RepLevelID AND (RL.RepRoleID <> 'REP')
	-- Exclus les commissions versées aux supérieurs indiqués par l'historique des supérieurs du représentant qui a fait la vente et par
	-- la date de vigueur du groupe d'unités.
	WHERE RC.RepCommissionID NOT IN (
				SELECT 
					RC.RepCommissionID
				FROM Un_RepCommission RC
				JOIN dbo.Un_Unit U ON U.UnitID = RC.UnitID
				JOIN Un_RepLevel RL ON RL.RepLevelID = RC.RepLevelID AND (RL.RepRoleID <> 'REP')
				JOIN Un_RepBossHist H ON H.BossID = RC.RepID AND H.RepID = U.RepID AND H.RepRoleID = RL.RepRoleID AND (U.InForceDate >= H.StartDate) AND (H.EndDate IS NULL OR (U.InForceDate <= H.EndDate))
				)
		-- Prend seulement les enregistrements qu'il y a un montant de commissions de service ou d'avances à verser.
		AND( (RC.CommissionAmount <> 0)
			OR (RC.AdvanceAmount <> 0)
			OR (RC.CoveredAdvanceAmount <> 0)
			) 
	GROUP BY
		RC.RepID,
		RC.RepLevelID,
		RC.UnitID
	HAVING SUM(RC.CommissionAmount) <> 0
		OR	SUM(RC.AdvanceAmount) <> 0
		OR	SUM(RC.CoveredAdvanceAmount) <> 0

	IF @@ROWCOUNT = 0 
	BEGIN
		SET @iResult = -100
		GOTO ON_Error
	END

	-- Traitement des bonis d’affaires.
	EXECUTE @iResult = TT_UN_RepBusinessBonus @ConnectID, @iRepTreatmentID, @RepTreatmentDate
	IF @iResult < = 0 
	BEGIN
		SET @iResult = -11
		GOTO ON_Error
	END

	-- Va chercher la somme des exceptions de commissions par groupe d'unités, représentant et niveau
	SELECT 
		V.UnitID, -- ID du groupe d'unités
		V.RepID, -- ID du représentant
		V.RepLevelID, -- ID du niveau
		ComException = SUM(V.ComException), -- Somme d'exceptions de commissions de service pour ce groupe d'unités, ce représentant et ce niveau
		AdvException = SUM(V.AdvException), -- Somme d'exceptions d'avances pour ce groupe d'unités, ce représentant et ce niveau
		CadException = SUM(V.CadException) -- Somme d'exceptions d'avances couvertes pour ce groupe d'unités, ce représentant et ce niveau
	INTO #tComException
	FROM (
		-- Retourne les exceptions dans un format de définition de colonne différent
		SELECT 
			E.RepExceptionID, -- ID de l'exception, on le mais pour éviter que le UNION rassemble des enregistrements qui ont toutes les autres valeurs identique mais qui sont belle et bien des enregsitrements distincts
			E.UnitID, -- ID du groupe d'unités
			E.RepID, -- ID du représentant
			E.RepLevelID, -- ID du niveau
			ComException = E.RepExceptionAmount, -- Montant de commission de service de l'exception 
			AdvException = 0, -- Montant d'avances de l'exception
			CadException = 0 -- Montant d'avances couvertes de l'exception
		FROM Un_RepException E  
		JOIN Un_RepExceptionType ET ON ET.RepExceptionTypeID = E.RepExceptionTypeID
		JOIN dbo.Un_Unit U ON U.UnitID = E.UnitID
		JOIN Un_Rep R ON R.RepID = E.RepID
		WHERE ET.RepExceptionTypeTypeID = 'COM' -- Exception de commissions de service seulement
			AND (E.RepExceptionDate <= @RepTreatmentDate) -- Exclus les exceptions ultérieurs au traitement de commissions
			AND U.StopRepComConnectID IS NULL -- Exclus les exceptions sur des groupes d'unités en arrêt de paiement de commissions
			AND R.StopRepComConnectID IS NULL -- Exclus les exceptions sur des représentants en arrêt de paiement de commissions
		-----
		UNION
		-----
		SELECT 
			E.RepExceptionID, -- ID de l'exception, on le mais pour éviter que le UNION rassemble des enregistrements qui ont toutes les autres valeurs identique mais qui sont belle et bien des enregsitrements distincts
			E.UnitID, -- ID du groupe d'unités
			E.RepID, -- ID du représentant
			E.RepLevelID, -- ID du niveau
			ComException = 0, -- Montant de commission de service de l'exception 
			AdvException = E.RepExceptionAmount, -- Montant d'avances de l'exception
			CadException = 0 -- Montant d'avances couvertes de l'exception
		FROM Un_RepException E  
		JOIN Un_RepExceptionType ET ON ET.RepExceptionTypeID = E.RepExceptionTypeID
		JOIN dbo.Un_Unit U ON U.UnitID = E.UnitID
		JOIN Un_Rep R ON R.RepID = E.RepID
		WHERE ET.RepExceptionTypeTypeID = 'ADV' -- Exception d'avances seulement
			AND (E.RepExceptionDate <= @RepTreatmentDate) -- Exclus les exceptions ultérieurs au traitement de commissions
			AND U.StopRepComConnectID IS NULL -- Exclus les exceptions sur des groupes d'unités en arrêt de paiement de commissions
			AND R.StopRepComConnectID IS NULL -- Exclus les exceptions sur des représentants en arrêt de paiement de commissions
		-----
		UNION
		-----
		SELECT 
			E.RepExceptionID, -- ID de l'exception, on le mais pour éviter que le UNION rassemble des enregistrements qui ont toutes les autres valeurs identique mais qui sont belle et bien des enregsitrements distincts
			E.UnitID, -- ID du groupe d'unités
			E.RepID, -- ID du représentant
			E.RepLevelID, -- ID du niveau
			ComException = 0, -- Montant de commission de service de l'exception 
			AdvException = 0, -- Montant d'avances de l'exception
			CadException = E.RepExceptionAmount -- Montant d'avances couvertes de l'exception
		FROM Un_RepException E  
		JOIN Un_RepExceptionType ET ON ET.RepExceptionTypeID = E.RepExceptionTypeID
		JOIN dbo.Un_Unit U ON U.UnitID = E.UnitID
		JOIN Un_Rep R ON R.RepID = E.RepID
		WHERE ET.RepExceptionTypeTypeID = 'CAD' -- Exception d'avances couvertes seulement
			AND (E.RepExceptionDate <= @RepTreatmentDate) -- Exclus les exceptions ultérieurs au traitement de commissions
			AND U.StopRepComConnectID IS NULL -- Exclus les exceptions sur des groupes d'unités en arrêt de paiement de commissions
			AND R.StopRepComConnectID IS NULL -- Exclus les exceptions sur des représentants en arrêt de paiement de commissions
		) V
	GROUP BY
		V.UnitID,
		V.RepID,
		V.RepLevelID

	-- Table temporaire donnant la somme des frais cotisés dont la date d'opération est antérieure ou égale à celle du traitement
	-- ce pour chaque groupes d'unités
	SELECT 
		C.UnitID, -- ID du groupe d'unités
		TotalFee = ROUND(SUM(C.Fee), 2) -- Total des frais cotisés
	INTO #tRepFee
	FROM Un_Cotisation C 
	JOIN Un_Oper O ON O.OperID = C.OperID
	WHERE (O.OperDate <= @RepTreatmentDate) -- La date d'opération doit être antérieure ou égale à celle du traitement
		AND OperTypeID NOT IN ('BEC','RIN') -- Exclus les variations de frais des remboursements intégraux
	GROUP BY C.UnitID      

	--Insertion les commissions dues dans la table permanente en tenant compte des exceptions
	INSERT INTO Un_RepCommission (
		RepID,
		UnitID,
		RepLevelID,
		RepTreatmentID,
		UnitQty,
		RepPct,
		TotalFee,
		CommissionAmount,
		AdvanceAmount,
		CoveredAdvanceAmount)
		-- Avant le UNION on prend les commissions dues calculé plutôt.  On y additionne les exceptions de commissions. 
		SELECT 
			R.RepID, -- ID du représentant
			R.UnitID, -- ID du groupe d'unités
			R.RepLevelID, -- ID du niveau
			R.RepTreatmentID, -- ID du traitement
			R.UnitQty, -- Nombre d'unités
			R.RepPct, -- Pourcentage de commissions
			R.TotalFee, -- Total des frais cotisés pour ce groupe d'unités
			CommissionAmount = ROUND(R.CommissionAmount + ISNULL(E.ComException, 0), 2), -- Montant de commissions de services dues (incluant les exceptions)
			AdvanceAmount = ROUND(R.AdvanceAmount + ISNULL(E.AdvException, 0), 2), -- Montant d'avances dues (incluant les exceptions)
			CoveredAdvanceAmount = ROUND(R.CoveredAdvanceAmount + ISNULL(E.CadException, 0), 2) -- Montant d'avances couvertes dues (incluant les exceptions)
		FROM #tRepCommission R
		JOIN Un_RepLevel RL ON R.RepLevelID = RL.RepLevelID
		LEFT JOIN #tComException E ON E.RepID = R.RepID AND E.UnitID = R.UnitID AND E.RepLevelID = R.RepLevelID
		-- Commissions dues + exceptions doivent différer de 0.00$
		WHERE	( (ROUND(R.CommissionAmount + ISNULL(E.ComException, 0), 2) <> 0) 
			 	OR (ROUND(R.AdvanceAmount + ISNULL(E.AdvException, 0), 2) <> 0)    
			 	OR (ROUND(R.CoveredAdvanceAmount + ISNULL(E.CadException, 0), 2) <> 0)
				)
		-----
		UNION
		----- 
		-- Gére le cas des exceptions qui non pas de correspondance dans la table temporaire des commissions dues qui ne comptait pas les 
		-- exceptions
		SELECT 
			V.RepID, -- ID du représentant
			V.UnitID, -- ID du groupe d'unités
			V.RepLevelID, -- ID du niveau
			@iRepTreatmentID, -- ID du traitement de commissions
			VU.UnitQty, -- Nombre d'unités
			V.RepPct, -- Pourcentage de commissions
			V.TotalFee, -- Total de frais cotisés antérieurement ou le jour du traitement de commissions pour ce groupe d'unités
			CommissionAmount = V.ComException, -- Montant de commissions de services dues (incluant les exceptions)
			AdvanceAmount = V.AdvException, -- Montant d'avances dues (incluant les exceptions)
			CoveredAdvanceAmount = V.CadException -- Montant d'avances couvertes dues (incluant les exceptions)
		FROM (
			-- Avant UNION exception des représentants
			SELECT 
				E.RepID, -- ID du représentant
				E.UnitID, -- ID du groupe d'unités
				E.RepLevelID, -- ID du niveau
				RepPct = CAST('100.00' AS FLOAT), -- Pourcentage de commissions
				VRL.TotalFee, -- Total de frais cotisés antérieurement ou le jour du traitement de commissions pour ce groupe d'unités
				E.ComException, -- Montant de commissions de services dues (incluant les exceptions)
				E.AdvException, -- Montant d'avances dues (incluant les exceptions)
				E.CadException -- Montant d'avances couvertes dues (incluant les exceptions)
			FROM #tComException E
			JOIN Un_RepLevel RL ON RL.RepLevelID = E.RepLevelID AND RL.RepRoleID = 'REP' -- Représentants seulement
			JOIN #tRepFee VRL ON VRL.UnitID = E.UnitID
			----- 
			UNION
			----- 
			-- Exception des supérieurs
			SELECT 
				E.RepID, -- ID du représentant
				E.UnitID, -- ID du groupe d'unités
				E.RepLevelID, -- ID du niveau
				RepPct = VRB.RepBossPct, -- Pourcentage de commissions
				VRL.TotalFee, -- Total de frais cotisés antérieurement ou le jour du traitement de commissions pour ce groupe d'unités
				E.ComException, -- Montant de commissions de services dues (incluant les exceptions)
				E.AdvException, -- Montant d'avances dues (incluant les exceptions)
				E.CadException -- Montant d'avances couvertes dues (incluant les exceptions)
			FROM #tComException E
			JOIN #TRepUnitQtyForPeriod VU ON VU.UnitID = E.UnitID
			JOIN Un_RepLevel RL ON RL.RepLevelID = E.RepLevelID AND (RL.RepRoleID <> 'REP') -- Supérieurs seulement
			JOIN (
				-- Trouve les pourcentages de commissions des supérieurs
				SELECT
					U.UnitID, -- ID du groupe d'unités
					RepBossID = RB.BossID, -- ID du supérieur
					RB.RepBossPct, -- Pourcentage de commissions
					RH.RepLevelID -- ID du niveau
				FROM dbo.Un_Unit U   
				JOIN Un_RepBossHist RB ON RB.RepID = U.RepID
				JOIN Un_RepLevel RL ON RL.RepRoleID = RB.RepRoleID
				JOIN Un_RepLevelHist RH ON RH.RepID = RB.BossID AND RH.RepLevelID = RL.RepLevelID
				-- Filtre sur les niveaux en vigueur pour le groupe d'unités selon l'historique des niveaux du supérieur
				WHERE U.InForceDate > = RH.StartDate
					AND( RH.EndDate IS NULL
						OR U.InForceDate <= RH.EndDate
						)
					-- Filtre sur les supérieurs du groupe d'unités selon l'historique des supérieurs du représentant qui a fait la ventes
					AND U.InForceDate > = RB.StartDate
					AND( RB.EndDate IS NULL
						OR U.InForceDate <= RB.EndDate
						)
				) VRB ON VRB.UnitID = E.UnitID AND VRB.RepBossID = E.RepID AND VRB.RepLevelID = E.RepLevelID
			JOIN #tRepFee VRL ON VRL.UnitID = E.UnitID
			) V
		JOIN #TRepUnitQtyForPeriod VU ON VU.UnitID = V.UnitID
		JOIN dbo.Un_Unit U ON U.UnitID = V.UnitID
        LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, @RepTreatmentDate) RIN ON RIN.UnitID = U.UnitID
		-- Inclus seulement les exceptions qui non pas de correspondance dans la table temporaire des commissions dues
		WHERE NOT EXISTS (
					SELECT 
						R.RepID,
						R.UnitID,
						R.RepLevelID
					FROM #tRepCommission R 
					WHERE R.UnitID = V.UnitID AND R.RepID = V.RepID AND R.RepLevelID = V.RepLevelID
					)
			-- Le remboursement intgral ne doit pas avoir été fait sur le groupe d'unités, sinon la date du remboursement doit être 
			-- ultérieur au traitement des commissions
			--AND( U.IntReimbDate IS NULL
			--	OR (U.IntReimbDate > @RepTreatmentDate)
			--	) 
            AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
			-- Le montant de l'exception doit être différent de 0.00$
			AND( (V.ComException <> 0) 
				OR (V.AdvException <> 0) 
				OR (V.CadException <> 0)
				) 

	IF @@ERROR <> 0
	BEGIN
		SET @iResult = -13
		GOTO ON_Error
	END
	
	-- Table temporaire contenant la somme des avances non couvertes et des commissions de service versés par représentant, groupe
	-- d'unités et niveau
	SELECT 
		C.RepID, -- ID du représentant
		C.UnitID, -- ID du groupe d'unités
		C.RepLevelID, -- ID du niveau
		CumAdvance = SUM(C.AdvanceAmount-C.CoveredAdvanceAmount), -- Somme des avances versés non couvertes (Avances - avances couvertes)
		CumComm = SUM(C.CommissionAmount) -- Somme des commissions de services versés
	INTO #SumRepCommissionByUnit
	FROM Un_RepCommission C 
	GROUP BY
		C.RepID,
		C.UnitID,
		C.RepLevelID

	-- Table temporaire contenant le montant de commissions de service versés ou à verser par groupe d'unités, représentant et niveau
	SELECT 
		A.RepID, -- ID du représentant
		A.UnitID, -- ID du groupe d'unités
		A.RepLevelID, -- ID du niveau
		ServiceComm = -- Commissions de service versés ou à verser par groupe d'unités, représentant et niveau
			CASE
				-- Groupe d'unités sans frais non commissionnés
				WHEN ISNULL(TF.UnitID,0) = 0 THEN
					ROUND(CAST((TotalLevelCommAmount * VU.UnitQty) * (A.RepPct / 100) AS MONEY), 2) + ISNULL(E.ComException,0)
			ELSE
				-- Groupe d'unités avec frais non commissionnés ( on inclus les avances aussi dans ce cas car elles sont payés en commissions
				-- de service)
				ROUND(CAST(((TotalLevelCommAmount + TotalLevelAdvanceAmount) * VU.UnitQty) * (A.RepPct / 100)AS MONEY), 2) + ISNULL(E.ComException, 0) + ISNULL(E.AdvException, 0)
			END
	INTO #ServiceComm
	FROM #TRepTotalLevelBracket A
	JOIN #TRepUnitQtyForPeriod VU ON VU.UnitID = A.UnitID
	JOIN dbo.Un_Unit U ON U.UnitID = A.UnitID
	LEFT JOIN #TRepTransacNoComm TF ON TF.UnitID = A.UnitID
	LEFT JOIN #tComException E ON E.UnitID = A.UnitID AND E.RepID = A.RepID AND E.RepLevelID = A.RepLevelID
	WHERE U.ActivationConnectID IS NOT NULL -- Exclus les groupes d'unités qui n'on pas été activés

	-- Table temporaire des commisions de service à venir par représentant (
	SELECT 
		S.RepID, -- ID du représentant
		FuturComm = SUM(S.ServiceComm - ISNULL(R.CumComm,0)) -- Commissions de services à venir
	INTO #FuturComm
	FROM #ServiceComm S 
	LEFT JOIN #SumRepCommissionByUnit R ON R.RepID = S.RepID AND R.UnitID = S.UnitID AND R.RepLevelID = S.RepLevelID
	GROUP BY S.RepID
	
/* Traitement retiré car calculs erronnés  PLS  2012-05-06
	-- Insertion des Retenu par rapport à la règle qu'on ne peut pas donner plus de 75% (paramétré) 
	-- d'avance par rapport au montant d'avance future  
	INSERT INTO Un_RepAccount (
		RepTreatmentID,
		RepID,
		AjustmentAmount)  
		SELECT 
			RepTreatmentID = @iRepTreatmentID, -- ID du traitement de commissions
			R.RepID, -- ID du représentant
			-- Montant de l'ajustement à faire au compte du représentant
			AjustmentAmount = ROUND(dbo.fn_Un_GetRepAccountAjustmentAmount(ISNULL(RA.CommissionAmount, 0), ISNULL(RA.AdvanceAmount, 0), ISNULL(VRA.OldAjustmentAmount, 0), ISNULL(VF.FuturComm, 0), @fMaxRepRisk), 2)
		FROM Un_Rep R
		LEFT JOIN (
			-- Trouve la somme des commissions de services et des avances versée par représentant
			SELECT 
				RepID, -- ID du représentant
				CommissionAmount = SUM(CumComm), -- Somme des commissions de services
				AdvanceAmount = SUM(CumAdvance) -- Somme des avances
			FROM #SumRepCommissionByUnit
			GROUP BY RepID
			) RA ON RA.RepID = R.RepID
		LEFT JOIN #FuturComm VF ON VF.RepID = R.RepID
		LEFT JOIN (
			--Somme des montants d'ajustement avant ce traitement 
			SELECT
				RT.RepTreatmentID, -- ID du traitement
				RA.RepID, -- ID du représentant
				OldAjustmentAmount = SUM(RA.AjustmentAmount) -- Ajustement précédant au compte du souscripteur
			FROM Un_RepTreatment RT
			JOIN Un_RepAccount RA ON RA.RepTreatmentID < RT.RepTreatmentID
			GROUP BY
				RT.RepTreatmentID,
				RA.RepID
			) VRA ON VRA.RepTreatmentID = @iRepTreatmentID AND VRA.RepID = R.RepID AND (VRA.OldAjustmentAmount <> 0)
		-- Insère seulement des ajustements au compte du représentant différents de 0.00$
		WHERE ROUND(dbo.fn_Un_GetRepAccountAjustmentAmount(ISNULL(RA.CommissionAmount, 0), ISNULL(RA.AdvanceAmount, 0), ISNULL(VRA.OldAjustmentAmount, 0), ISNULL(VF.FuturComm, 0), @fMaxRepRisk), 2) <> 0

	IF @@ERROR <> 0
	BEGIN
		SET @iResult = -12
		GOTO ON_Error
	END 
*/
	--	Traitement des frais de formations.
	EXECUTE @iResult = TT_UN_RepFormationFee @ConnectID, @iRepTreatmentID, @RepTreatmentDate, @dtLastTreatmentDate   
	IF @iResult < = 0 
	BEGIN
		SET @iResult = -13
		GOTO ON_Error
	END
	
	-- Traitement d’émission et remboursement des avances spéciales et des avances sur résiliations.
	EXECUTE @iResult = TT_UN_RepTerminatedAndSpecialAdvance @ConnectID, @iRepTreatmentID
	IF @iResult < = 0 
	BEGIN
		SET @iResult = -14
		GOTO ON_Error
	END

	-- Inscrit le ID du traitement sur les ajustements/retenus entrée manuellement qui n'ont pas encore été lié à un traitement
	-- de commissions sans traitement et dont la date est antérieur ou égale à celle du traitement de commissions
	UPDATE Un_RepCharge 
	SET RepTreatmentID = @iRepTreatmentID
	WHERE RepTreatmentID IS NULL -- Pas encore lié à une traitement de commissions
		AND (RepChargeDate < = @RepTreatmentDate) -- Ajustement/retenu dont la date est antérieur ou égale à celle du traitement de commissions
	
	IF @@ERROR <> 0
	BEGIN
		SET @iResult = -15
		GOTO ON_Error
	END
	
	-- Mets à jour la date de barrure des transactions financières en date du traitement
	UPDATE UN_Def 
	SET LastVerifDate = dbo.fn_Mo_DateNoTime(@RepTreatmentDate)

	IF @@ERROR <> 0
	BEGIN
		SET @iResult = -16
		GOTO ON_Error
	END
	
	-- Supprime les tables temporaires
	DROP TABLE #tRepCommissionForPeriod
	DROP TABLE #tRepBossCommissionForPeriod
	DROP TABLE #tRepCommissionPaid
	DROP TABLE #TRepTotalLevelBracket
	DROP TABLE #tRepCommission
	DROP TABLE #TRepTransacNoComm
	DROP TABLE #TRepUnitQtyForPeriod
	DROP TABLE #tComException
	DROP TABLE #ServiceComm
	DROP TABLE #FuturComm
	DROP TABLE #SumRepCommissionByUnit
	DROP TABLE #tRepFee;
	
	RETURN(@iRepTreatmentID)
	
	ON_ERROR:
	BEGIN 
		RETURN(@iResult)
	END
END