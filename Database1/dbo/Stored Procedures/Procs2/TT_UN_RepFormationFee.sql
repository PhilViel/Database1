/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_RepFormationFee 
Description         :	Traitement des frais de formations.
Valeurs de retours  :	@ReturnValue :
									>0 :	Le traitement a réussi.
									<=0 :	Le traitement a échoué.
Note                :	ADX0000696	IA	2005-08-16	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_RepFormationFee] (
	@ConnectID INTEGER, -- ID unique de connexion de l’usager qui a lancé le traitement.
	@RepTreatmentID INTEGER, -- ID unique du traitement de commissions.
	@RepTreatmentDate DATETIME, -- Date du traitement de commissions qui correspond au dernier jour inclusivement à traiter dans le traitement.
	@LastRepTreatmentDate DATETIME ) -- Date du dernier traitement de commissions avant celui-ci.
AS
BEGIN
	DECLARE 
		@Result INTEGER

	-- Insère un ajustement/retenu de frais de formation retirant de l'argent au directeur d'agence pour chaque vente faites par un de
	-- ses représentants entre le traitement de commission précédent et celui-ci.
	INSERT INTO Un_RepCharge (
		RepID, -- ID du représentant
		RepChargeTypeID, -- ID du type d'ajustement/retenu
		RepChargeDesc, -- Raison de l'ajustement/retenu
		RepChargeAmount, -- Montant de l'ajustement/retenu 
		RepTreatmentID, -- ID du traitement de commission
		RepChargeDate ) -- Date d'entrée en vigueur de l'ajustement/retenu
		SELECT 
			RepID = V.BossID, -- ID du représentant qui est directeur d'agance
			RepChargeTypeID = 'FRF', -- ID du type d'ajustement/retenu (Frais de formation)
			RepChargeDesc = 'Frais de formation sur ' + CAST( CAST(SUM(V.UnitQty) AS DECIMAL(10,3)) AS VARCHAR) + ' unité(s)',
			RepChargeAmount = -ROUND(SUM(V.RepChargeAmount),2), -- Montant de l'ajustement/retenu 
			RepTreatmentID = @RepTreatmentID, -- ID du traitement de commission courant
			RepChargeDate = @RepTreatmentDate -- Date d'entrée en vigueur de l'ajustement/retenu (Date du traitement de commissions)
		FROM (
			-- Retourne le montant de frais de formation à charger aux directeurs d'agences pour les ventes faites entre le traitement de
			-- commission précédent et celui-ci.
			SELECT 
				B.BossID, -- ID du supérieur
				B.UnitID, -- D du groupe d'unités
				UnitQty = U.UnitQty + ISNULL(VR.UnitReductQty, 0), -- Nombre d'unités du groupe d'unités au moment de la ventes. (Nombre d'unités du groupe d'unités + Unités résiliés de ce groupe)
				RepChargeAmount = (U.UnitQty + ISNULL(VR.UnitReductQty, 0)) * VF.FormationFeeAmount -- Montant retenu pour remboursement de frais de formation
			FROM (
				-- Trouve le directeur d'agence avec le plus gros pourcentage de commissions de chaque groupe d'unités.  C'est seulement à 
				-- lui que sont imputés les frais de formation.
				SELECT
					VB.UnitID, -- ID du groupe d'unités
					BossID = MIN(VB.BossID) -- ID du représentant qui est directeur d'agance
				FROM (
					-- Trouve tout les supérieurs de chaque groupe d'unités et leurs pourcentage de commissions
					SELECT DISTINCT
						U.UnitID, -- ID du groupe d'unités
						RH.BossID, -- ID du représentant qui est directeur d'agance
						RH.RepBossPct -- Pourcentage de ce représentant en tant que directeur d'agence sur ce groupe d'unités
					FROM dbo.Un_Unit U
					JOIN Un_RepBossHist RH ON RH.RepID = U.RepID AND RH.RepRoleID = 'DIR'
					JOIN Un_RepLevelHist RLH ON RLH.RepID = RH.BossID
					-- S'assure que le supérieur à belle et bien un historique de niveau.
					WHERE U.InForceDate >= RLH.StartDate 
						AND( U.InForceDate <= RLH.EndDate
							OR RLH.EndDate IS NULL
							)
						-- Trouve le directeur d'agence du groupe d'unités à l'aide de l'historique des supérieurs du représentant qui a fait la vente
						AND U.InForceDate >= RH.StartDate 
						AND( U.InForceDate <= RH.EndDate
							OR RH.EndDate IS NULL
							)
					) VB
				LEFT JOIN (
					-- Trouve tout les supérieurs de chaque groupe d'unités et leurs pourcentage de commissions
					SELECT DISTINCT
						U.UnitID, -- ID du groupe d'unités
						RH.BossID, -- ID du représentant qui est directeur d'agance
						RH.RepBossPct -- Pourcentage de ce représentant en tant que directeur d'agence sur ce groupe d'unités
					FROM dbo.Un_Unit U
					JOIN Un_RepBossHist RH ON RH.RepID = U.RepID AND RH.RepRoleID = 'DIR'
					JOIN Un_RepLevelHist RLH ON RLH.RepID = RH.BossID
					-- S'assure que le supérieur à belle et bien un historique de niveau.
					WHERE U.InForceDate >= RLH.StartDate
						AND( U.InForceDate <= RLH.EndDate
							OR RLH.EndDate IS NULL
							)
						-- Trouve le directeur d'agence du groupe d'unités à l'aide de l'historique des supérieurs du représentant qui a fait la vente
						AND U.InForceDate >= RH.StartDate
						AND( U.InForceDate <= RH.EndDate
							OR RH.EndDate IS NULL
							)
					) VB2 ON VB2.UnitID = VB.UnitID AND (VB2.RepBossPct >= VB.RepBossPct) AND (VB2.BossID <> VB.BossID)
				WHERE VB2.BossID IS NULL -- Garde seulement le directeur d'agence avec le plus haut pourcentage
				GROUP BY VB.UnitID
				) B 
			JOIN dbo.Un_Unit U ON U.UnitID = B.UnitID
			JOIN (
				-- Retourne la date du premier dépôt de chaque groupe d'unités.  C'est à cette date que les frais de formations pour ce 
				-- groupe d'unités sont imputés au directeur d'agence.
				SELECT 
					U.UnitID, -- ID du groupe d'unités
					FirstDepositDate = -- Date du premier dépôt (N'importe qu'elle transaction est considéré comme un dépôt
						CASE 
							-- On a pas l'historique des transactions avant le 30 janvier 1998.  Si il y a une transaction à cette date, on 
							-- prend la date d'entrée en vigueur du groupe d'unités comme date de premier dépôt.
							WHEN MIN(O.OperDate) = CAST('1998-01-30' AS DATETIME) THEN MIN(U.InForceDate)
						ELSE MIN(O.OperDate) 
						END
				FROM dbo.Un_Unit U
				JOIN Un_Cotisation C ON C.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = C.OperID
				WHERE O.OperTypeID <> 'BEC'
				GROUP BY U.UnitID
				) VU ON VU.UnitID = U.UnitID
			JOIN (
				-- Retroune les différentes configuration du montant par unités de frais de formations à charger au durecteur d'agence
				SELECT
					F.StartDate, -- Date d'entrée en vigueur de la configuration
					VR.EndDate, -- Date calculé de fin d'entrée en vigueur de la configuration
					F.FormationFeeAmount -- Montant de frais de formation par unités imputé aux directeurs d'agence pour la période de vigueur de cette configuration
				FROM Un_RepFormationFeeCfg F
				LEFT JOIN (
					-- Calcul la date de fin de la configuration.  La date de fin de la configuration est la plus petite date de début des
					-- configurations dont la date de début est ultérieurs à celle-ci - un jour
					SELECT 
						F1.RepFormationFeeCfgID, -- ID de la configuration de frais de formation
						EndDate = MIN(F2.StartDate -1) -- Date de fin calculé.
					FROM Un_RepFormationFeeCfg F1
					JOIN Un_RepFormationFeeCfg F2 ON F2.RepFormationFeeCfgID > F1.RepFormationFeeCfgID
					GROUP BY F1.RepFormationFeeCfgID
					) VR ON VR.RepFormationFeeCfgID = F.RepFormationFeeCfgID
				) VF ON U.InForceDate >= VF.StartDate AND (U.InForceDate < VF.EndDate OR VF.EndDate IS NULL)
			LEFT JOIN (
				-- Retourne le nombre d'unités résiliés pour chaque groupe d'unités
				SELECT 
					UnitID, -- ID du groupe d'unités
					UnitReductQty = SUM(UnitQty) -- Nombre d'unités résiliés de ce groupe d'unités depuis le début
				FROM Un_UnitReduction
				GROUP BY UnitID
				) VR ON VR.UnitID = U.UnitID
			-- Inclus uniqument les ventes faites par un représentant entre le traitement de commission précédent et celui-ci.
			WHERE (VU.FirstDepositDate > @LastRepTreatmentDate)
				AND (VU.FirstDepositDate <= @RepTreatmentDate)
				AND (U.UnitQty + ISNULL(VR.UnitReductQty, 0)) * VF.FormationFeeAmount <> 0
			) V
		GROUP BY V.BossID
		HAVING SUM(V.RepChargeAmount) <> 0 -- Crée l'ajustement/retenu seulement si les frais de formations à chargé sont différent de 0,00$
		
	IF @@ERROR = 0
		SET @Result = 1
	ELSE
		SET @Result = -1
		
	RETURN (@Result)
END


