/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_RepBusinessBonus 
Description         :	Traitement des bonis d’affaires.
Valeurs de retours  :	@ReturnValue :
									>0 :	Le traitement a réussi.
									<=0 :	Le traitement a échoué.
Note                :	ADX0000696	IA	2005-08-16	Bruno Lapointe		Création
									    2010-01-04	Donald Huppé	    Correction du calcul du Boni d'affaire du supérieur selon son niveau (rechercher "2010-01-04" dans le code)
                                        2018-02-16  Pierre-Luc Simard   Exclure aussi les groupes d'unités avec un RIN partiel
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_RepBusinessBonus] (
	@ConnectID INTEGER, -- ID unique de connexion de l’usager qui a lancé le traitement.
	@RepTreatmentID INTEGER, -- ID unique du traitement de commissions.
	@RepTreatmentDate DATETIME ) -- Dernier jour inclusivement à traiter dans le traitement.
AS
BEGIN
	DECLARE 
		@iBusinessBonusLimit INTEGER

	-- Met 6 par défaut pour le nombre limite d'années pour toucher les bonis d'affaires d'un groupe d'unités
	SET @iBusinessBonusLimit = 6

	-- Va chercher le nombre limite d'années pour toucher les bonis d'affaires d'un groupe d'unités dans la table de configuration
	SELECT 
		@iBusinessBonusLimit = BusinessBonusLimit
	FROM Un_Def

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- Changement de représentant :
	-- Reprend tout les bonis d'affaires qu'a touché un représentant pour un groupe d'unités dont la vente ne lui est plus attribué.
	INSERT INTO Un_RepBusinessBonus (
		RepTreatmentID, 
		RepID, 
		UnitID, 
		RepLevelID, 
		UnitQty, 
		BusinessBonusAmount, 
		InsurTypeID)
		SELECT 
			RepTreatmentID = @RepTreatmentID, -- ID du traitement de commissions
			RBB.RepID, -- ID du représentant
			RBB.UnitID, -- ID du groupe d'unités
			RBB.RepLevelID, -- ID du niveau du représentant
			U.UnitQty, -- Nombre d'unités du groupe d'unités
			BusinessBonusAmount = SUM(RBB.BusinessBonusAmount)*-1, -- Montant de bonis d'affaire renversée dans ce traitement
			RBB.InsurTypeID -- Type de boni d'affaire
		FROM (
			-- Trouve les groupes d'unités dont la somme des bonis d'affaires est de plus de 0,00$
			SELECT 
				RBB.UnitID -- ID du groupe d'unités
			FROM dbo.Un_Unit U 
			JOIN Un_RepBusinessBonus RBB ON RBB.UnitID = U.UnitID AND (RBB.RepID <> U.RepID)
			JOIN Un_RepLevel RL ON RL.RepLevelID = RBB.RepLevelID AND RL.RepRoleID = 'REP'
			GROUP BY RBB.UnitID
			HAVING SUM(RBB.BusinessBonusAmount) > 0 -- Inclus les groupes d'unités dont la somme des bonis d'affaires est de plus de 0,00$
			) VV 
		JOIN dbo.Un_Unit U ON VV.UnitID = U.UnitID
		JOIN Un_RepBusinessBonus RBB ON U.UnitID = RBB.UnitID
		GROUP BY 
			RBB.RepID, 
			RBB.UnitID, 
			U.UnitQty, 
			RBB.InsurTypeID, 
			RBB.RepLevelID
		HAVING SUM(RBB.BusinessBonusAmount) > 0 -- Inclus les groupes d'unités dont la somme des bonis d'affaires est de plus de 0,00$

	IF @@ERROR = 0
		-- Table temporaire des rôles de supérieurs et des différents pourcentages de commissions qu'on a pour ces rôles pour chaque
		-- groupe d'unités.
		SELECT 
			U.UnitID, -- ID du groupe d'unités
			RBH.RepRoleID, -- ID du rôle
			RepBossPct = MAX(RBH.RepBossPct) -- Pourcentage de commission pour ce rôle et ce groupe d'unités
		INTO #MaxPctBoss
		FROM dbo.Un_Unit U
		JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID
		JOIN Un_RepLevel RL ON RL.RepRoleID = RBH.RepRoleID
		JOIN Un_RepLevelHist RLH ON RLH.RepLevelID = RL.RepLevelID AND RLH.RepID = RBH.BossID
		JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RBH.RepRoleID
		-- Filtre l'historique des supérieurs pour trouver uniquement les supérieurs de ce groupe d'unités
		WHERE U.InForceDate >= RBH.StartDate 
			AND( U.InForceDate <= RBH.EndDate
				OR RBH.EndDate IS NULL
				)
			-- Filtre la configuration des bonis d'affaire pour connaître la configuration en vigueur pour ce groupe d'unités
			AND U.InForceDate >= RBB.StartDate 
			AND( U.InForceDate <= RBB.EndDate
				OR RBB.EndDate IS NULL
				)
			-- Filtre l'historique des niveaux du supérieurs pour s'assurer que ce rôle de supérieur lui était attribué lors de la vente de
			-- ce groupe d'unité.
			AND U.InForceDate >= RLH.StartDate
			AND( U.InForceDate <= RLH.EndDate
				OR RLH.EndDate IS NULL
				)
		GROUP BY 
			U.UnitID, 
			RBH.RepRoleID

	IF @@ERROR = 0
		-- Changement de supérieur :
		-- Reprend tout les bonis d'affaires qu'a touché un supérieur pour un groupe d'unités dont la vente ne lui est plus attribué.
		INSERT INTO Un_RepBusinessBonus (
			RepTreatmentID, 
			RepID, 
			UnitID, 
			RepLevelID, 
			UnitQty, 
			BusinessBonusAmount, 
			InsurTypeID)
			SELECT 
				RepTreatmentID = @RepTreatmentID, -- ID du traitement de commissions
				RBB.RepID, -- ID du représentant
				RBB.UnitID, -- ID du groupe d'unités
				RBB.RepLevelID, -- ID du niveau du représentant
				U.UnitQty, -- Nombre d'unités du groupe d'unités
				BusinessBonusAmount = SUM(RBB.BusinessBonusAmount)*-1, -- Montant de bonis d'affaire renversée dans ce traitement
				RBB.InsurTypeID -- Type de boni d'affaire
			FROM (
				-- Trouve la liste des niveaux des supérieurs pour chaque groupe d'unités
				SELECT 
					RBB.UnitID, -- ID du groupe d'unités
					RL.RepLevelID -- ID du niveau
				FROM dbo.Un_Unit U 
				JOIN #MaxPctBoss UMPct ON UMPct.UnitID = U.UNitID
				JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND UMPct.RepBossPct = RBH.RepBossPct AND UMPct.RepRoleID = RBH.RepRoleID AND (RBH.StartDate <= U.InForceDate) AND (RBH.EndDate IS NULL OR (RBH.EndDate >= U.InForceDate))
				JOIN Un_RepBusinessBonus RBB ON RBB.UnitID = U.UnitID AND (RBB.RepID <> RBH.BossID)
				JOIN Un_RepLevel BRL ON BRL.RepRoleID = RBH.RepRoleID
				JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate OR BRLH.EndDate IS NULL)
				JOIN Un_RepLevel RL ON RL.RepLevelID = RBB.RepLevelID AND (RL.RepRoleID <> 'REP')
				GROUP BY
					RBB.UnitID,
					RL.RepLevelID
				HAVING SUM(RBB.BusinessBonusAmount) > 0 -- Inclus les groupes d'unités dont la somme des bonis d'affaires est de plus de 0,00$
				) VV 
			JOIN dbo.Un_Unit U ON VV.UnitID = U.UnitID
			JOIN Un_RepBusinessBonus RBB ON U.UnitID = RBB.UnitID AND RBB.RepLevelID = VV.RepLevelID
			GROUP BY 
				RBB.RepID, 
				RBB.UnitID, 
				U.UnitQty, 
				RBB.InsurTypeID, 
				RBB.RepLevelID
			HAVING SUM(RBB.BusinessBonusAmount) > 0 -- Inclus les groupes d'unités dont la somme des bonis d'affaires est de plus de 0,00$

	IF @@ERROR = 0
		-- Table temporaire contenant la somme des primes d'assurance souscripteur et d'assurance bénéficiaire
		SELECT
			C.UnitID, -- ID du groupe d'unités
			SubscInsurSum = SUM(C.SubscInsur), -- Somme des primes d'assurance souscripteur pour ce groupe d'unités
			BenefInsurSum = SUM(C.BenefInsur) -- Somme des primes d'assurance bénéficiaire pour ce groupe d'unités
		INTO #SumInsur
		FROM Un_Cotisation C
		JOIN Un_Oper O ON O.OperID = C.OperID
		WHERE O.OperDate <= @RepTreatmentDate -- Exclus les variations des primes ultérieure à la date du traitement de commissions
			-- Inclus seulement les opérations qui ont une variation soit dans les primes d'assurance souscripteur ou dans les primes 
			-- d'assurance bénéficiaire.
			AND( C.SubscInsur <> 0
				OR C.BenefInsur <> 0
				)
		GROUP BY C.UnitID

	IF @@ERROR = 0
		-- Table temporaire contenant la somme des primes d'assurance soucripteur appartenant à des unités résiliés pour chaque groupe
		-- d'unités.  Quoique toujours dans la conventions, cette argent ne doit pas être comptabilisé lors des bonifications des unités
		-- restantes.
		SELECT 
			UnitID, -- ID du groupe d'unités
			SubscInsurSum = SUM(SubscInsurSumByUnit*UnitQty) -- Somme des primes d'assurance souscripteur appartenant à des unités résiliés
		INTO #SumUnitReduction
		FROM Un_UnitReduction        
		WHERE ReductionDate <= @RepTreatmentDate -- Exclus les réductions d'unités ultérieure à la date de traitement de commissiom
		GROUP BY UnitID

	IF @@ERROR = 0
		-- Table temporaire contenant la somme des bonis d'affaires déjà touchés par les représentants pour chaque groupe d'unités,
		-- niveau et type de boni d'affaire
		SELECT 
			RepID, -- ID du représentant
			UnitID, -- ID du groupe d'unités
			SumBusinessBonusAmount = SUM(BusinessBonusAmount), -- Somme des bonis d'affaires qu'a touché ce représentant pour ce groupe d'unités, ce niveau et ce type de boni d'affaire
			RepLevelID, -- ID du niveau
			InsurTypeID -- Type de boni d'affaire
		INTO #SumRepBusinessBonus
		FROM Un_RepBusinessBonus
		GROUP BY 
			RepID, 
			UnitID, 
			InsurTypeID, 
			RepLevelID    

	IF @@ERROR = 0
		-- Table temporaire contenant pour les groupes d'unités concernées le nombre d'unités résiliés ultérieurement au traitement
		-- des commissions.  Le traitement des bonis d'affaire ne doit pas tenir compte de ces réductions d'unités lors du calcul.
		SELECT 
			UnitID, -- ID du groupe d'unités
			UnitQty = SUM(UnitQty) -- Nombre d'unités, de ce groupe d'unités, résiliés ultérieurement au traitement des commissions
		INTO #UnitReductionNotApp
		FROM Un_UnitReduction        
		WHERE ReductionDate > @RepTreatmentDate -- Inclus uniquement les réductions d'unités faites ultérieurement au traitement des commissions
		GROUP BY UnitID

	IF @@ERROR = 0
		-- Boni sur l'assurance souscripteur pour les représentants
		INSERT INTO Un_RepBusinessBonus (
			RepTreatmentID, 
			RepID, 
			UnitID, 
			RepLevelID, 
			UnitQty, 
			BusinessBonusAmount, 
			InsurTypeID)
			SELECT * 
			FROM (
				-- Retourne le montant de tombés de bonis d'affaire que doit avoir le représentant dans ce traitement de commissions pour
				-- ce groupe d'unités, niveau, et type de bonis
				SELECT
					RepTreatmentID = @RepTreatmentID, -- ID du traitement de commissions
					U.RepID, -- ID du représentant
					U.UnitID, -- ID du groupe d'unités
					RL.RepLevelID, -- ID du niveau du représentant
					UnitQty = U.UnitQty + ISNULL(RUNA.UnitQty,0), -- Nombre d'unités du groupe d'unités additionné du nombre d'unités résiliés ultérieurement au traitement de commissions
					BusinessBonusAmount = -- Bonis d'affaire
						CASE
							-- Cas ou on n'a pas d'assurance souscripteur selon la modalité du groupe d'unités
							WHEN ROUND((U.UnitQty + ISNULL(RUNA.UnitQty,0)) * M.SubscriberInsuranceRate,2) * M.PmtByYearID  = 0 THEN 
								ISNULL(RBBE.RepExceptionAmount,0) - ISNULL(VRBB.SumBusinessBonusAmount, 0)
						ELSE
							-- Cas ou on a au moins une année de prime d'assurance perçu mais que le nombre n'est pas supérieur au nombre d'années bonifiées
							CASE  
								WHEN FLOOR((VC.SubscInsurSum - ISNULL(RU.SubscInsurSum,0)) / (ROUND((U.UnitQty + ISNULL(RUNA.UnitQty,0)) * M.SubscriberInsuranceRate,2) * M.PmtByYearID)) <= RBB.BusinessBonusNbrOfYears THEN
									CASE 
										WHEN FLOOR((VC.SubscInsurSum - ISNULL(RU.SubscInsurSum,0)) / (ROUND((U.UnitQty + ISNULL(RUNA.UnitQty,0)) * M.SubscriberInsuranceRate,2) * M.PmtByYearID)) > 0 THEN 
											(FLOOR((VC.SubscInsurSum - ISNULL(RU.SubscInsurSum,0)) / (ROUND((U.UnitQty + ISNULL(RUNA.UnitQty,0)) * M.SubscriberInsuranceRate,2) * M.PmtByYearID)) * ROUND(RBB.BusinessBonusByUnit * (U.UnitQty + ISNULL(RUNA.UnitQty,0)),2)) - ISNULL(VRBB.SumBusinessBonusAmount, 0) + ISNULL(RBBE.RepExceptionAmount,0)
									ELSE 0
									END
							-- Cas ou le nombre d'année de prime perçu d'assurance est supérieur au nombre d'années bonifiées
							ELSE 
								(RBB.BusinessBonusNbrOfYears * ROUND(((U.UnitQty + ISNULL(RUNA.UnitQty,0)) * RBB.BusinessBonusByUnit),2)) - ISNULL(VRBB.SumBusinessBonusAmount, 0) + ISNULL(RBBE.RepExceptionAmount,0)
							END
						END,
					InsurTypeID = 'ISB' -- Type de bonis d'affaire
				FROM dbo.Un_Unit U 
                LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, @RepTreatmentDate) RIN ON RIN.UnitID = U.UnitID
				JOIN Un_Rep R ON R.RepID = U.RepID
				JOIN Un_Modal M ON M.ModalID = U.ModalID AND M.BusinessBonusToPay <> 0  
				JOIN Un_RepLevelHist RLH ON RLH.RepID = U.RepID AND (RLH.StartDate <= U.InForceDate) AND (RLH.EndDate IS NULL OR (RLH.EndDate >= U.InForceDate)) 
				JOIN Un_RepLevel RL ON RL.RepLevelID = RLH.RepLevelID AND RL.RepRoleID = 'REP'
				JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RL.RepRoleID AND RBB.InsurTypeID = 'ISB' AND (RBB.StartDate <= U.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= U.InForceDate)) 
				JOIN #SumInsur VC ON VC.UnitID = U.UnitID 
				LEFT JOIN #SumRepBusinessBonus VRBB ON VRBB.UnitID = U.UnitID AND VRBB.RepID = U.RepID AND VRBB.InsurTypeID = 'ISB' AND VRBB.RepLevelID = RL.RepLevelID
				LEFT JOIN (
					-- Trouve la somme des exceptions sur commissions pour les bonis d'affaires d'assurance souscripteur pour ce groupe
					-- d'unités, ce représentant et ce niveau
					SELECT 
						RE.RepID, -- ID du représentant
						RE.UnitID, -- ID du groupe d'unités
						RE.RepLevelID, -- ID du niveau
						RepExceptionAmount = SUM(RE.RepExceptionAmount) -- Somme des exceptions de commissions pour les bonis d'affaire 
					FROM Un_RepException RE         
					JOIN Un_RepExceptionType RET ON RET.RepExceptionTypeID = RE.RepExceptionTypeID
					WHERE RET.RepExceptionTypeTypeID = 'ISB' -- Exception pour les bonis d'affaires d'assurance bénéficiaire
					  AND RE.RepExceptionDate <= @RepTreatmentDate -- Exclus les exceptions ultérieures au traitement des commissions
					GROUP BY 
						RE.RepID, 
						RE.UnitID,
						RE.RepLevelID
					) RBBE ON RBBE.UnitID = U.UnitID AND RBBE.RepID = U.RepID  AND RBBE.RepLevelID = RL.RepLevelID
				LEFT JOIN #SumUnitReduction RU ON RU.UnitID = U.UnitID 
				LEFT JOIN #UnitReductionNotApp RUNA ON RUNA.UnitID = U.UnitID 
				WHERE ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
                    --U.IntReimbDate IS NULL -- Exclus les groupes d'unités dont le remboursement intégral complet a été effectué.
					AND (DATEADD(YEAR, @iBusinessBonusLimit, U.InforceDate) >= @RepTreatmentDate) -- Exclus les groupes d'unités dont l'entrée en vigueur est ultérieur au traitement de commissions
					AND U.ActivationConnectID IS NOT NULL -- Exclus les groupes d'unités qui ne sont activés
					AND U.StopRepComConnectID IS NULL -- Exclus les groupes d'unités en arrêt de paiement de commissions
					AND R.StopRepComConnectID IS NULL -- Exclus les représentants en arrêt de paiement de commissions
					-- Le représentant doit être actif ou sa date de fin d'activité doit être ultérieur au traitement de commissions
					AND( R.BusinessEnd IS NULL 
						OR (R.BusinessEnd >= @RepTreatmentDate)
						)
					AND (U.WantSubscriberInsurance <> 0) -- Il faut l'assurance souscripteur soit indiqué voulue sur le groupe d'unités 
			) VV
			WHERE BusinessBonusAmount <> 0 -- Exclus les tombés de 0,00$

	IF @@ERROR = 0
		-- Boni sur l'assurance bénéficiaire pour les représentants
		INSERT INTO Un_RepBusinessBonus (
			RepTreatmentID, 
			RepID, 
			UnitID, 
			RepLevelID, 
			UnitQty, 
			BusinessBonusAmount, 
			InsurTypeID)
			SELECT *
			FROM (
				SELECT
					RepTreatmentID = @RepTreatmentID, -- ID du traitement de commissions
					U.RepID, -- ID du représentant
					U.UnitID, -- ID du groupe d'unités
					RL.RepLevelID, -- ID du niveau
					UnitQty = U.UnitQty + ISNULL(RUNA.UnitQty,0), -- Nombre d'unités du groupe d'unités additionné du nombre d'unités résiliés ultérieurement au traitement de commissions
					BusinessBonusAmount = -- Bonis d'affaire
						CASE 
							-- Cas ou on n'a pas d'assurance bénéficiaire sur le groupe d'unités
							WHEN  (M.PmtByYearID * BI.BenefInsurRate) = 0 THEN
								ISNULL(RBBE.RepExceptionAmount,0) - ISNULL(VRBB.SumBusinessBonusAmount, 0)
						ELSE 
							-- Cas ou on a au moins une année de prime d'assurance perçu mais que le nombre n'est pas supérieur au nombre d'années bonifiées
							CASE  
								WHEN FLOOR(VC.BenefInsurSum / (M.PmtByYearID * BI.BenefInsurRate)) <= RBB.BusinessBonusNbrOfYears THEN
									CASE 
										WHEN FLOOR(VC.BenefInsurSum / (M.PmtByYearID * BI.BenefInsurRate)) > 0 THEN 
										  (FLOOR(VC.BenefInsurSum / (M.PmtByYearID * BI.BenefInsurRate)) * RBB.BusinessBonusByUnit) - ISNULL(VRBB.SumBusinessBonusAmount, 0) + ISNULL(RBBE.RepExceptionAmount,0)     
									ELSE 0
									END
							-- Cas ou le nombre d'année de prime d'assurance perçu est supérieur au nombre d'années bonifiées
							ELSE
								(RBB.BusinessBonusNbrOfYears * RBB.BusinessBonusByUnit) - ISNULL(VRBB.SumBusinessBonusAmount, 0) + ISNULL(RBBE.RepExceptionAmount,0)
							END 
						END,
					RBB.InsurTypeID -- Type de bonis d'affaire
				FROM dbo.Un_Unit U 
                LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, @RepTreatmentDate) RIN ON RIN.UnitID = U.UnitID
				JOIN Un_Rep R ON R.RepID = U.RepID
				JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID AND BI.BenefInsurFaceValue IN (10000,20000)
				JOIN Un_Modal M ON M.ModalID = U.ModalID AND (M.BusinessBonusToPay <> 0)
				JOIN Un_RepLevelHist RLH ON RLH.RepID = U.RepID AND (StartDate <= U.InForceDate) AND (EndDate IS NULL OR (EndDate >= U.InForceDate))
				JOIN Un_RepLevel RL ON RL.RepLevelID = RLH.RepLevelID AND RL.RepRoleID = 'REP'
				JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RL.RepRoleID AND (RBB.StartDate <= U.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= U.InForceDate))
				JOIN #SumInsur VC ON VC.UnitID = U.UnitID 
				LEFT JOIN #SumRepBusinessBonus VRBB ON VRBB.UnitID = U.UnitID AND VRBB.RepID = U.RepID AND RBB.InsurTypeID = VRBB.InsurTypeID AND VRBB.RepLevelID = RL.RepLevelID 
				LEFT JOIN (
					-- Trouve la somme des exceptions sur commissions pour les bonis d'affaires d'assurance bénéficiaire pour ce groupe
					-- d'unités, ce représentant, ce niveau et ce type d'exception
					SELECT 
						RE.RepID, -- ID du représentant
						RE.UnitID, -- ID du groupe d'unités
						RE.RepLevelID, -- ID du niveau
						RET.RepExceptionTypeTypeID, -- ID du type d'exception
						RepExceptionAmount = SUM(RE.RepExceptionAmount) -- Somme des exceptions de commissions pour les bonis d'affaire 
					FROM Un_RepException RE         
					JOIN Un_RepExceptionType RET ON RET.RepExceptionTypeID = RE.RepExceptionTypeID
					WHERE RET.RepExceptionTypeTypeID IN ('IB1','IB2') -- Exception pour les bonis d'affaires d'assurance souscripteur seulement
					  AND RE.RepExceptionDate <= @RepTreatmentDate -- Exclus les exceptions ultérieures au traitement des commissions
					GROUP BY 
						RE.RepID, 
						RE.UnitID,
						RE.RepLevelID,
						RET.RepExceptionTypeTypeID
					) RBBE ON RBBE.UnitID = U.UnitID AND RBBE.RepID = U.RepID  AND RBBE.RepLevelID = RL.RepLevelID AND RBB.InsurTypeID = RBBE.RepExceptionTypeTypeID 
				LEFT JOIN #UnitReductionNotApp RUNA ON RUNA.UnitID = U.UnitID 
				WHERE ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
                    --U.IntReimbDate IS NULL -- Exclus les groupes d'unités dont le remboursement intégral complet a été effectué.
					AND (DATEADD(YEAR, @iBusinessBonusLimit, U.InforceDate) >= @RepTreatmentDate) -- Exclus les groupes d'unités dont l'entrée en vigueur est ultérieur au traitement de commissions
					AND U.ActivationConnectID IS NOT NULL -- Exclus les groupes d'unités qui ne sont activés
					AND U.StopRepComConnectID IS NULL -- Exclus les groupes d'unités en arrêt de paiement de commissions
					AND R.StopRepComConnectID IS NULL -- Exclus les représentants en arrêt de paiement de commissions
					-- Le représentant doit être actif ou sa date de fin d'activité doit être ultérieur au traitement de commissions
					AND( R.BusinessEnd IS NULL 
						OR (R.BusinessEnd >= @RepTreatmentDate)
						)
					-- Bonis d'affaire sur assurance bénéficiaire 10 000.00$ ou 20 000.00$
					AND(	( RBB.InsurTypeID = 'IB1' 
							AND BI.BenefInsurFaceValue = 10000
							)
						OR ( RBB.InsurTypeID = 'IB2'
							AND BI.BenefInsurFaceValue = 20000
							)
						)
				) VV
			WHERE BusinessBonusAmount <> 0 -- Exclus les tombés de 0,00$

	-- Boni sur l'assurance souscripteur pour les supérieurs
	IF @@ERROR = 0
		INSERT INTO Un_RepBusinessBonus (
			RepTreatmentID, 
			RepID, 
			UnitID, 
			RepLevelID, 
			UnitQty, 
			BusinessBonusAmount, 
			InsurTypeID)
			SELECT * 
			FROM (
				SELECT
					RepTreatmentID = @RepTreatmentID, -- ID du traitement de commissions
					RepID = RBH.BossID, -- ID du représentant (supérieur)
					U.UnitID, -- ID du groupe d'unités
					BRL.RepLevelID, -- ID du niveau (supérieur)
					UnitQty = U.UnitQty + ISNULL(RUNA.UnitQty,0), -- Nombre d'unités du groupe d'unités additionné du nombre d'unités résiliés ultérieurement au traitement de commissions
					BusinessBonusAmount =  -- Bonis d'affaire
						CASE 
							-- Cas ou on n'a pas d'assurance souscripteur selon la modalité du groupe d'unités
							WHEN ROUND((U.UnitQty + ISNULL(RUNA.UnitQty,0)) * M.SubscriberInsuranceRate,2) * M.PmtByYearID = 0 THEN
								ISNULL(RBBE.RepExceptionAmount,0) - ISNULL(VRBB.SumBusinessBonusAmount, 0)
						ELSE 
							-- Cas ou on a au moins une année de prime d'assurance perçu mais que le nombre n'est pas supérieur au nombre d'années bonifiées
							CASE  
								WHEN FLOOR((VC.SubscInsurSum - ISNULL(RU.SubscInsurSum,0)) / (ROUND((U.UnitQty + ISNULL(RUNA.UnitQty,0)) * M.SubscriberInsuranceRate,2) * M.PmtByYearID)) <= RBB.BusinessBonusNbrOfYears THEN
									CASE 
										WHEN FLOOR((VC.SubscInsurSum - ISNULL(RU.SubscInsurSum,0)) / (ROUND((U.UnitQty + ISNULL(RUNA.UnitQty,0)) * M.SubscriberInsuranceRate,2) * M.PmtByYearID)) > 0 THEN 
										  (FLOOR((VC.SubscInsurSum - ISNULL(RU.SubscInsurSum,0)) / (ROUND((U.UnitQty + ISNULL(RUNA.UnitQty,0)) * M.SubscriberInsuranceRate,2) * M.PmtByYearID)) * (RBB.BusinessBonusByUnit * (U.UnitQty + ISNULL(RUNA.UnitQty,0)))) - ISNULL(VRBB.SumBusinessBonusAmount, 0) + ISNULL(RBBE.RepExceptionAmount,0)
									ELSE 0
									END
							-- Cas ou le nombre d'année de prime perçu d'assurance est supérieur au nombre d'années bonifiées
							ELSE
								(RBB.BusinessBonusNbrOfYears * ROUND(((U.UnitQty + ISNULL(RUNA.UnitQty,0)) * RBB.BusinessBonusByUnit),2)) - ISNULL(VRBB.SumBusinessBonusAmount, 0) + ISNULL(RBBE.RepExceptionAmount,0)
							END 
						END,
					InsurTypeID = 'ISB' -- Type de bonis d'affaire
				FROM dbo.Un_Unit U 
                LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, @RepTreatmentDate) RIN ON RIN.UnitID = U.UnitID
				JOIN Un_Rep R ON R.RepID = U.RepID
				JOIN Un_Modal M ON M.ModalID = U.ModalID AND (M.BusinessBonusToPay <> 0)
				JOIN #MaxPctBoss UMPct ON UMPct.UnitID = U.UNitID
				JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND UMPct.RepBossPct = RBH.RepBossPct AND UMPct.RepRoleID = RBH.RepRoleID AND (RBH.StartDate <= U.InForceDate) AND (RBH.EndDate IS NULL OR (RBH.EndDate >= U.InForceDate))
				JOIN Un_Rep B ON B.RepID = RBH.BossID
				JOIN Un_RepLevel BRL ON BRL.RepRoleID = RBH.RepRoleID
				JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate OR BRLH.EndDate IS NULL)
				-- Correction du 2010-01-04.  On retire ce join et on remplace le join sur RL par BRL partout dans ce select
				--JOIN Un_RepLevel RL ON RL.RepRoleID = RBH.RepRoleID
				JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RBH.RepRoleID AND RBB.InsurTypeID = 'ISB' AND (RBB.StartDate <= U.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= U.InForceDate))
				JOIN #SumInsur VC ON VC.UnitID = U.UnitID 
				LEFT JOIN #SumRepBusinessBonus VRBB ON VRBB.UnitID = U.UnitID AND VRBB.RepID = RBH.BossID AND VRBB.InsurTypeID = 'ISB' AND VRBB.RepLevelID = BRL.RepLevelID 
				LEFT JOIN (
					-- Trouve la somme des exceptions sur commissions pour les bonis d'affaires d'assurance souscripteur pour ce groupe
					-- d'unités, ce représentant(supérieur) et ce niveau
					SELECT 
						RE.RepID, -- ID du représentant
						RE.UnitID, -- ID du groupe d'unités
						RE.RepLevelID, -- ID du niveau
						RepExceptionAmount = SUM(RE.RepExceptionAmount) -- Somme des exceptions de commissions pour les bonis d'affaire 
					FROM Un_RepException RE         
					JOIN Un_RepExceptionType RET ON RET.RepExceptionTypeID = RE.RepExceptionTypeID
					WHERE RET.RepExceptionTypeTypeID = 'ISB' -- Exception pour les bonis d'affaires d'assurance bénéficiaire
					  AND RE.RepExceptionDate <= @RepTreatmentDate -- Exclus les exceptions ultérieures au traitement des commissions
					GROUP BY 
						RE.RepID, 
						RE.UnitID,
						RE.RepLevelID
					) RBBE ON RBBE.UnitID = U.UnitID AND RBBE.RepID = RBH.BossID AND RBBE.RepLevelID = BRL.RepLevelID
				LEFT JOIN #SumUnitReduction RU ON RU.UnitID = U.UnitID
				LEFT JOIN #UnitReductionNotApp RUNA ON RUNA.UnitID = U.UnitID
				WHERE ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
                    --U.IntReimbDate IS NULL -- Exclus les groupes d'unités dont le remboursement intégral complet a été effectué.
					AND (DATEADD(YEAR, @iBusinessBonusLimit, U.InforceDate) >= @RepTreatmentDate) -- Exclus les groupes d'unités dont l'entrée en vigueur est ultérieur au traitement de commissions
					AND U.ActivationConnectID IS NOT NULL -- Exclus les groupes d'unités qui ne sont activés
					AND U.StopRepComConnectID IS NULL -- Exclus les groupes d'unités en arrêt de paiement de commissions
					AND B.StopRepComConnectID IS NULL -- Exclus les représentants en arrêt de paiement de commissions
					-- Le représentant doit être actif ou sa date de fin d'activité doit être ultérieur au traitement de commissions
					AND( B.BusinessEnd IS NULL 
						OR (B.BusinessEnd >= @RepTreatmentDate)
						)
					AND (U.WantSubscriberInsurance <> 0) -- Il faut l'assurance souscripteur soit indiqué voulue sur le groupe d'unités 
				) VV
			WHERE BusinessBonusAmount <> 0 -- Exclus les tombés de 0,00$

	-- Boni sur l'assurance bénéficiaire pour les supérieurs
	IF @@ERROR = 0
		INSERT INTO Un_RepBusinessBonus (
			RepTreatmentID, 
			RepID, 
			UnitID, 
			RepLevelID, 
			UnitQty, 
			BusinessBonusAmount, 
			InsurTypeID)
			SELECT * 
			FROM (
				SELECT
					RepTreatmentID = @RepTreatmentID, -- ID du traitement de commissions
					RepID = RBH.BossID, -- ID du représentant (supérieur)
					U.UnitID, -- ID du groupe d'unités
					BRL.RepLevelID, -- ID du niveau (supérieur)
					UnitQty = U.UnitQty + ISNULL(RUNA.UnitQty,0), -- Nombre d'unités du groupe d'unités additionné du nombre d'unités résiliés ultérieurement au traitement de commissions
					BusinessBonusAmount =  -- Bonis d'affaire
						CASE 
							-- Cas ou on n'a pas d'assurance bénéficiaire sur le groupe d'unités
							WHEN (M.PmtByYearID * BI.BenefInsurRate) = 0 THEN
								ISNULL(RBBE.RepExceptionAmount,0) - ISNULL(VRBB.SumBusinessBonusAmount, 0)
						ELSE 
							-- Cas ou on a au moins une année de prime d'assurance perçu mais que le nombre n'est pas supérieur au nombre d'années bonifiées
							CASE  
								WHEN FLOOR(VC.BenefInsurSum / (M.PmtByYearID * BI.BenefInsurRate)) <= RBB.BusinessBonusNbrOfYears THEN
									CASE 
										WHEN FLOOR(VC.BenefInsurSum / (M.PmtByYearID * BI.BenefInsurRate)) > 0 THEN 
										  (FLOOR(VC.BenefInsurSum / (M.PmtByYearID * BI.BenefInsurRate)) * RBB.BusinessBonusByUnit) - ISNULL(VRBB.SumBusinessBonusAmount, 0) + ISNULL(RBBE.RepExceptionAmount,0)     
									ELSE 0
									END
							-- Cas ou le nombre d'année de prime d'assurance perçu est supérieur au nombre d'années bonifiées
							ELSE (RBB.BusinessBonusNbrOfYears * RBB.BusinessBonusByUnit) - ISNULL(VRBB.SumBusinessBonusAmount, 0) + ISNULL(RBBE.RepExceptionAmount,0)
							END
						END,
					RBB.InsurTypeID -- Type de bonis d'affaire
				FROM dbo.Un_Unit U 
                LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, @RepTreatmentDate) RIN ON RIN.UnitID = U.UnitID
				JOIN Un_Rep R ON R.RepID = U.RepID
				JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID AND BI.BenefInsurFaceValue IN (10000,20000)
				JOIN Un_Modal M ON M.ModalID = U.ModalID AND (M.BusinessBonusToPay <> 0)
				JOIN #MaxPctBoss UMPct ON UMPct.UnitID = U.UNitID
				JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND UMPct.RepBossPct = RBH.RepBossPct AND UMPct.RepRoleID = RBH.RepRoleID AND (RBH.StartDate <= U.InForceDate) AND (RBH.EndDate IS NULL OR (RBH.EndDate >= U.InForceDate))
				JOIN Un_Rep B ON B.RepID = RBH.BossID
				JOIN Un_RepLevel BRL ON BRL.RepRoleID = RBH.RepRoleID
				JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate) AND (U.InForceDate <= BRLH.EndDate OR BRLH.EndDate IS NULL)
				--Correction du 2010-01-04.  On retire ce join et on remplace le join sur RL par BRL partout dans ce select
				--JOIN Un_RepLevel RL ON RL.RepRoleID = RBH.RepRoleID
				JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RBH.RepRoleID AND (RBB.StartDate <= U.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= U.InForceDate)) 
				JOIN #SumInsur VC ON VC.UnitID = U.UnitID 
				LEFT JOIN #SumRepBusinessBonus VRBB ON VRBB.UnitID = U.UnitID AND VRBB.RepID = RBH.BossID AND RBB.InsurTypeID = VRBB.InsurTypeID AND VRBB.RepLevelID = BRL.RepLevelID  
				LEFT JOIN (
					-- Trouve la somme des exceptions sur commissions pour les bonis d'affaires d'assurance bénéficiaire pour ce groupe
					-- d'unités, ce représentant (supérieur), ce niveau et ce type d'exception
					SELECT 
						RE.RepID, -- ID du représentant
						RE.UnitID, -- ID du groupe d'unités
						RE.RepLevelID, -- ID du niveau
						RET.RepExceptionTypeTypeID, -- ID du type d'exception
						RepExceptionAmount = SUM(RE.RepExceptionAmount) -- Somme des exceptions de commissions pour les bonis d'affaire 
					FROM Un_RepException RE         
					JOIN Un_RepExceptionType RET ON RET.RepExceptionTypeID = RE.RepExceptionTypeID
					WHERE RET.RepExceptionTypeTypeID IN ('IB1','IB2') -- Exception pour les bonis d'affaires d'assurance souscripteur seulement
					  AND RE.RepExceptionDate <= @RepTreatmentDate -- Exclus les exceptions ultérieures au traitement des commissions
					GROUP BY 
						RE.RepID, 
						RE.UnitID,
						RE.RepLevelID,
						RET.RepExceptionTypeTypeID
					) RBBE ON RBBE.UnitID = U.UnitID AND RBBE.RepID = RBH.BossID  AND RBBE.RepLevelID = BRL.RepLevelID AND RBB.InsurTypeID = RBBE.RepExceptionTypeTypeID 
				LEFT JOIN #UnitReductionNotApp RUNA ON RUNA.UnitID = U.UnitID 
				WHERE ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
                    --U.IntReimbDate IS NULL -- Exclus les groupes d'unités dont le remboursement intégral complet a été effectué.
					AND (DATEADD(YEAR, @iBusinessBonusLimit, U.InforceDate) >= @RepTreatmentDate) -- Exclus les groupes d'unités dont l'entrée en vigueur est ultérieur au traitement de commissions
					AND U.ActivationConnectID IS NOT NULL -- Exclus les groupes d'unités qui ne sont activés
					AND U.StopRepComConnectID IS NULL -- Exclus les groupes d'unités en arrêt de paiement de commissions
					AND B.StopRepComConnectID IS NULL -- Exclus les représentants en arrêt de paiement de commissions
					-- Le représentant doit être actif ou sa date de fin d'activité doit être ultérieur au traitement de commissions
					AND( B.BusinessEnd IS NULL 
						OR (B.BusinessEnd >= @RepTreatmentDate)
						)
					-- Bonis d'affaire sur assurance bénéficiaire 10 000.00$ ou 20 000.00$
					AND(	( RBB.InsurTypeID = 'IB1'
							AND BI.BenefInsurFaceValue = 10000
							)
						OR (RBB.InsurTypeID = 'IB2'
							AND BI.BenefInsurFaceValue = 20000
							)
						)
				) VV
			WHERE BusinessBonusAmount <> 0 -- Exclus les tombés de 0,00$
 
	IF @@ERROR = 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	-- Suppression des tables temporaires
	DROP TABLE #SumInsur
	DROP TABLE #MaxPctBoss
	DROP TABLE #SumUnitReduction
	DROP TABLE #SumRepBusinessBonus
	DROP TABLE #UnitReductionNotApp

	IF @@ERROR = 0
		RETURN (1)
	ELSE 
		RETURN (0)
END