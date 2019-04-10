/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_ConventionAndUnitStateForAll
Description         :	Met à jour tout les états de conventions et des groupes d'unités si nécessaire (si celui 
								calculé est différent de l'état actuel).
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL
Note                :						2004-06-11	Bruno Lapointe		Création Point 10.23.02
							ADX0000968	BR	2004-08-23	Bruno Lapointe		Gestion des arrêts de paiements forcés
							ADX0000970	BR	2004-08-23	Bruno Lapointe		Correction de la gestion des états lors de transfert IN
							ADX0000973	BR	2004-08-23	Bruno Lapointe		Correction de la gestion des états lors d'annulation financière
							ADX0000975	BR	2004-08-23	Bruno Lapointe		Correction de la gestion des états lors de modification d'un remboursement intégral
							ADX0000978	BR	2004-08-23	Bruno Lapointe		Correction de la gestion des états lors de résiliation valeur 0
							ADX0000834	IA	2006-04-10	Bruno Lapointe		Adaptation au PCEE 4.3
							ADX0001235	IA	2007-02-14	Alain Quirion		Utilisation de dtRegStartDate pour la date de début de régime
							ADX0002426	BR	2007-05-23	Bruno Lapointe		Gestion de la table Un_CESP.
							ADX0001216	UP	2007-07-19	Alain Quirion		Bug de création des états de conventions pour les conventions sans groupes d'unités
							ADX0002511	BR	2007-08-07	Bruno Lapointe		La date d'entrée en vigueur de la convention doit 
																						être la plus petite de ses groupes d'unités et non
																						la plus grande.
											2008-06-05	Jean-Francois Arial Modification du traitement quotidien pour mettre à jour les status en lien avec les opérations RIO
											2010-07-28	Éric Deshaies		Correction pour le statut "PTR" pour les conventions issues d'un RIO
																			Ne pas prendre les RIO d'annulation
											2011-03-17	Frédérick Thibault	Ajout dy statut "RIM" pour les opération de conversion vers l'individuel (FT1)
											2012-10-16	Donald Huppé		dans la section RIO, prendre le max(OperDate), sinon ça génère plus d'un état de groupe d'unité (voir glpi 8378)
											2016-02-15	Steve Bélanger	    Ajout du cas FRM comme état final afin de ne pas mettre à jour les status
											2016-03-22	Steve Bélanger		Lorsqu'il existe une opération de fermeture, on retourne le statut courant du groupe d'unité 
					                                                        au lieu de retourner 'FRM' 
                                            2017-01-30  Pierre-Luc Simard   Ne pas tenir compte des TIN qui annulent pour l'état Proposition Transfert IN (JIRA TI-6551)
											2017-12-12	Simon Tanguay		JIRA: CRIT-1562	 Ajouter les tables d'historique de statuts


>>>>>>>>>>>>>>>>>>>>>>> NOTE IMPORTANTE!!!! À Supprimer suite à la mise en production de RIN partiel!!!!!!!!!!!!!!!!!!!!
*********************************************************************************************************************/
create PROCEDURE [dbo].[TT_UN_ConventionAndUnitStateForAll_PRE_RIN_PARTIEL]
AS
BEGIN
	DECLARE 
		@Today DATETIME,
		@TodayNoTime DATETIME
	
	SET @Today = GETDATE()

	SET @TodayNoTime = dbo.FN_CRQ_DateNoTime(@Today)

	-- Les lignes qui suivent mettent à jour les états des groupes d'unités
	INSERT INTO Un_UnitUnitState (UnitID, UnitStateID, StartDate)
	   SELECT DISTINCT
			V.UnitID,
			V.UnitStateID,
			StartDate = @Today
		FROM (
		   SELECT 
				V.UnitID, 
				UnitStateID =
					CASE 
						WHEN CFF.ConventionID IS NOT NULL THEN
							'FRM'
						WHEN V.ROperTypeID  = 'FRM' THEN -- La fermeture est un état final
							(SELECT TOP 1 SS.UnitStateID FROM Un_UnitUnitState SS WHERE SS.UnitID = V.UnitID ORDER BY SS.StartDate DESC)
						WHEN (ISNULL(V.TerminatedDate,0) > 0) AND (ISNULL(V.TerminatedDate,0) <= @Today) THEN
							CASE 
								WHEN RIOOperTypeID = 'RIM' THEN -- FT 2011-03-17
									'RIM'
								WHEN RIOOperTypeID = 'TRI' THEN -- FT 2011-04-20
									'TRI'

								WHEN V.ROperTypeID  = '' THEN 
									'RPG' -- Résiliation épargne
								WHEN V.ROperTypeID  = 'OUT' THEN 
									'OUT' -- Transfert OUT
								WHEN V.RFee <> 0 AND (V.RSubscInsur <> 0 OR V.RBenefInsur <> 0) THEN 
									'RCP' -- Résiliation complète
								WHEN V.RFee <> 0 AND V.RSubscInsur = 0 AND V.RBenefInsur = 0 THEN 
									'RFE' -- Résiliation frais et épargne
								WHEN V.RCotisation = 0 THEN 
									'RV0' -- Résiliation valeur 0
								ELSE 
									'RPG' -- Résiliation épargne
							END
						WHEN (ISNULL(V.IntReimbDate,0) > 0) AND (ISNULL(V.IntReimbDate,0) <= @Today) THEN
							CASE
								WHEN V.PlanTypeID = 'IND' THEN
									CASE 
										WHEN V.IfIndPAEToPaid = 1 THEN 
											'PAE' -- PAE
										ELSE 
											'PVR' -- PAE versés
									END
							ELSE

								CASE
									WHEN V.BRS1 = '' THEN
										CASE 
											WHEN RIOOperTypeID = 'TRI' THEN -- FT 2011-05-25
												'TRI'
											WHEN V.CotisationFee = 0 AND V.YearQualif < 2000 THEN 
												'BTP' -- Bourses toutes payées
											ELSE 
												'RIV' -- Remboursement intégral versé
										END
									ELSE 
										'RIV' -- Remboursement intégral versé
									END
							END
						WHEN V.ActivationConnectID IS NULL THEN
							CASE 
								WHEN V.IsTIN = 1 THEN 
									'PIN' -- Proposition transfert IN
								ELSE 
									'PTR' -- Proposition en traitement
							END
						WHEN V.PlanTypeID = 'IND' AND V.OperDate IS NOT NULL AND V.OperDate > @Today THEN 
							'PTR' -- Proposition en traitement JFA 2008-06-19
						WHEN V.EstimatedRI <= @Today AND V.PlanTypeID <> 'IND' THEN 
							'RIN' -- Remboursement intégral
						WHEN V.IsTransitoire = 1 THEN 
							'TRA' -- Transitoire
						WHEN V.MntSouscrit <= V.CotisationFee THEN 
							CASE
								WHEN RIOOperTypeID = 'RIM' THEN -- FT 2011-03-17
									'RIM'
								ELSE
							
							'CPT' -- Capital Atteint
							
							END
						WHEN V.CotisationFee = 0 AND RIOAnnuleOperTypeID IS NOT NULL THEN -- FT1
							'FRM'
						ELSE 
							'EPG' -- En épargne
					END
			FROM (
				SELECT 
					U.ConventionID,
					U.UnitID,
					U.IntReimbDate,
					U.TerminatedDate,
					U.ActivationConnectID,
					U.InforceDate,
					IsTransitoire =
						CASE
							WHEN TRA.ConventionID IS NULL THEN 0
						ELSE 1
						END,
					MntSouscrit = 
						CASE
							WHEN ISNULL(U.PmtEndConnectID,0) > 0 THEN ISNULL(Ct.CotisationFee, 0)
						ELSE ROUND(U.UnitQty * M.PmtRate,2) * M.PmtQty
						END, PmtEndConnectID, UnitQty, PmtRate, PmtQty,
					EstimatedRI = 
						dbo.fn_Un_EstimatedIntReimbDate (
							M.PmtByYearID,
							M.PmtQty,
							M.BenefAgeOnBegining,
							U.InForceDate,
							P.IntReimbAge,
							U.IntReimbDateAdjust),
					P.PlanTypeID,
					BRS1 = ISNULL(S1.ScholarshipStatusID,''),
					CotisationFee = ISNULL(Ct.CotisationFee, 0),
					ROperTypeID = ISNULL(R.OperTypeID,ISNULL(RTFR.OperTypeID,'')),
					RCotisation = 
						CASE 
							WHEN ISNULL(RTFR.OperDate,0) > ISNULL(R.OperDate,0) THEN 0
						ELSE ISNULL(R.Cotisation,0)
						END,
					RFee = 
						CASE 
							WHEN ISNULL(RTFR.OperDate,0) > ISNULL(R.OperDate,0) THEN 0
						ELSE ISNULL(R.Fee,0)
						END,
					RSubscInsur = 
						CASE 
							WHEN ISNULL(RTFR.OperDate,0) > ISNULL(R.OperDate,0) THEN 0
						ELSE ISNULL(R.SubscInsur,0)
						END,
					RBenefInsur = 
						CASE 
							WHEN ISNULL(RTFR.OperDate,0) > ISNULL(R.OperDate,0) THEN 0
						ELSE ISNULL(R.BenefInsur,0)
						END,
					RTaxOnInsur = 
						CASE 
							WHEN ISNULL(RTFR.OperDate,0) > ISNULL(R.OperDate,0) THEN 0
						ELSE ISNULL(R.TaxOnInsur,0)
						END,
					IsTIN =
						CASE
							WHEN TIN.UnitID IS NULL THEN 0
						ELSE 1
						END,
					IfIndPAEToPaid =
						CASE 
							WHEN PAE.ConventionID IS NULL THEN 0
						ELSE 1
						END,
					C.YearQualif,
					RIO.OperDate -- Date de l'opération RIO JFA 2008-06-05
					,RIOOperTypeID = RIO2.OperTypeID -- FT
					,RIOAnnuleOperTypeID = RIO3.OperTypeID -- FT
				FROM dbo.Un_Unit U 
				JOIN Un_Modal M ON M.ModalID = U.ModalID
				JOIN Un_Plan P ON P.PlanID = M.PlanID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				LEFT JOIN ( -- Va chercher les conventions qui sont des propositions
					SELECT DISTINCT 
						C.ConventionID
					FROM dbo.Un_Convention C 
					JOIN ( -- Va chercher la date de vigueur de la convention
						SELECT 
							ConventionID,
							InForceDate = MIN(InForceDate)
						FROM dbo.Un_Unit 
						GROUP BY ConventionID 
						) I ON I.ConventionID = C.ConventionID					
					WHERE	C.dtRegStartDate IS NULL
						AND (I.InForceDate >= '2003-01-01') -- Applique la règle qui dit qu'une convention ne peut être en proposition si elle est avant le 1 janvier 2003
					) TRA ON TRA.ConventionID = U.ConventionID
				LEFT JOIN Un_Scholarship S1 ON S1.ConventionID = C.ConventionID AND S1.ScholarshipNo = 1 -- Va chercher la première bourse s'il y en a une
				LEFT JOIN ( -- Va chercher le montant d'épargne et de frais cumulé pour chaque groupe d'unités
					SELECT 
						UnitID,
						CotisationFee = SUM(Cotisation+Fee) 
					FROM Un_Cotisation Ct
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					WHERE O.OperDate <= @Today
					GROUP BY UnitID
					) Ct ON Ct.UnitID = U.UnitID
				LEFT JOIN ( -- Va chercher les montants remboursés lors de la dernière résiliation pour déterminer le type de résiliation
					SELECT 
						Ct.UnitID,
						O.OperTypeID,
						O.OperDate,
						Ct.Cotisation,
						Ct.Fee,
						Ct.SubscInsur,
						Ct.BenefInsur,
						Ct.TaxOnInsur
					FROM Un_Cotisation Ct
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					JOIN (
						SELECT 
							Ct.UnitID,
							OperID = MAX(O.OperID)
						FROM Un_Cotisation Ct
						JOIN Un_Oper O ON O.OperID = Ct.OperID
						WHERE O.OperTypeID IN ('RES', 'OUT', 'FRM')
						  AND O.OperDate <= @Today
						GROUP BY Ct.UnitID
						) V ON V.OperID = O.OperID
					) R ON R.UnitID = U.UnitID
				LEFT JOIN ( -- Va chercher le dernier TFR lié à une résiliation
					SELECT 
						Ct.UnitID,
						O.OperTypeID,
						O.OperDate
					FROM Un_Cotisation Ct
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					JOIN (
						SELECT 
							Ct.UnitID,
							OperID = MAX(O.OperID)
						FROM Un_Cotisation Ct
						JOIN Un_Oper O ON O.OperID = Ct.OperID
						LEFT JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
						WHERE O.OperTypeID = 'TFR'
						  AND URC.CotisationID IS NULL
						  AND O.OperDate <= @Today
						GROUP BY Ct.UnitID
						) V ON V.OperID = O.OperID
					) RTFR ON RTFR.UnitID = U.UnitID
				LEFT JOIN ( -- Va chercher les groupes d'unités qui on eu des transferts IN
					SELECT DISTINCT
						Ct.UnitID
					FROM Un_Cotisation Ct
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					LEFT JOIN Un_OperCancelation OC ON OC.OperSourceID = O.OperID
                    LEFT JOIN Un_OperCancelation OCA ON OCA.OperSourceID = O.OperID -- 2017-01-30
					WHERE O.OperTypeID = 'TIN'
					  AND O.OperDate <= @Today
					  AND OC.OperID IS NULL
                      AND OCA.OperID IS NULL -- 2017-01-30
					) TIN ON TIN.UnitID = U.UnitID
				LEFT JOIN (SELECT OperDate = max(O.OperDate), OpRIO.iID_Unite_Destination -- Va chercher la date de l'opération RIO JFA 2008-06-05
					FROM Un_Oper O
					JOIN tblOper_OperationsRIO OpRIO ON (O.OperID = OpRIO.iID_Oper_RIO)
					WHERE OpRIO.bRIO_Annulee = 0 -- va chercher les opérations RIO qui ne sont pas annulées
					  AND OpRIO.bRIO_QuiAnnule = 0
					 GROUP by OpRIO.iID_Unite_Destination
					) RIO ON (RIO.iID_Unite_Destination = U.UnitID)
				LEFT JOIN (SELECT OpRIO.iID_Unite_Source, OpRIO.OperTypeID -- FT1
					FROM Un_Oper O
					JOIN tblOper_OperationsRIO OpRIO ON (O.OperID = OpRIO.iID_Oper_RIO)
					WHERE OpRIO.bRIO_Annulee = 0 -- va chercher les opérations RIO qui ne sont pas annulées
					  AND OpRIO.bRIO_QuiAnnule = 0
					) RIO2 ON (RIO2.iID_Unite_Source = U.UnitID)
				LEFT JOIN (SELECT OpRIO.iID_Unite_Source, OpRIO.OperTypeID -- FT1
					FROM Un_Oper O
					JOIN tblOper_OperationsRIO OpRIO ON (O.OperID = OpRIO.iID_Oper_RIO)
					WHERE OpRIO.bRIO_QuiAnnule = 1 -- va chercher les opérations RIO annulées
					) RIO3 ON (RIO3.iID_Unite_Source = U.UnitID)
				LEFT JOIN ( -- Va chercher les montants qui reste à verser en bourses pour les conventions individuelles
					SELECT 
						V.ConventionID
					FROM (
						SELECT 
							C.ConventionID,
							SUM(CASE ConventionOperTypeID WHEN 'INS' THEN C.ConventionOperAmount ELSE 0 END) AS SumOfINS, 
							SUM(CASE ConventionOperTypeID WHEN 'IS+' THEN C.ConventionOperAmount ELSE 0 END) AS SumOfIS, 
							SUM(CASE ConventionOperTypeID WHEN 'IBC' THEN C.ConventionOperAmount ELSE 0 END) AS SumOfIBC, 
							SUM(CASE ConventionOperTypeID WHEN 'INM' THEN C.ConventionOperAmount ELSE 0 END) AS SumOfINM, 
							SUM(CASE ConventionOperTypeID WHEN 'ITR' THEN C.ConventionOperAmount ELSE 0 END) AS SumOfITR, 
							SUM(CASE ConventionOperTypeID WHEN 'IST' THEN C.ConventionOperAmount ELSE 0 END) AS SumOfIST,
							0 AS SumOfSUB
						FROM Un_ConventionOper C
						JOIN Un_Oper O ON O.OperID = C.OperID
						JOIN dbo.Un_Convention U ON C.ConventionID = U.ConventionID
						JOIN Un_Plan P ON P.PlanID = U.PlanID
						WHERE P.PlanTypeID = 'IND'
						  AND O.OperDate <= @Today
						GROUP BY C.ConventionID
						-----
						UNION 
						-----
						SELECT
							CE.ConventionID,
							SumOfINS = 0, 
							SumOfIS = 0, 
							SumOfIBC = 0, 
							SumOfINM = 0, 
							SumOfITR = 0, 
							SumOfIST = 0, 
							SumOfSUB = SUM(CE.fCESG+CE.fACESG+CE.fCLB)
						FROM Un_CESP CE
						JOIN Un_Oper O ON O.OperID = CE.OperID
						JOIN dbo.Un_Convention U ON CE.ConventionID = U.ConventionID
						JOIN Un_Plan P ON P.PlanID = U.PlanID
						WHERE P.PlanTypeID = 'IND'
						  AND O.OperDate <= @Today
						GROUP BY CE.ConventionID
						) V 
					GROUP BY V.ConventionID 
					HAVING (SUM(V.SumOfINS)>0)
						 OR (SUM(V.SumOfIS)>0)
						 OR (SUM(V.SumOfIBC)>0)
						 OR (SUM(V.SumOfINM)>0)
						 OR (SUM(V.SumOfITR)>0)
						 OR (SUM(V.SumOfIST)>0)
						 OR (SUM(V.SumOfSUB)>0)
					) PAE ON PAE.ConventionID = U.ConventionID
			) V
			LEFT JOIN Un_ConventionFRM_Force CFF ON CFF.ConventionID = V.ConventionID
		) V
		LEFT JOIN ( -- Va chercher l'état actuel du groupe d'unités
			SELECT 
				US.UnitID,
				US.UnitStateID
			FROM Un_UnitUnitState US
			JOIN (
				SELECT 
					UnitID,
					StartDate = MAX(StartDate) 
				FROM Un_UnitUnitState
				GROUP BY UnitID
				) V ON V.UnitID = US.UnitID AND US.StartDate = V.StartDate
			) EA ON EA.UnitID = V.UnitID
		-- S'assure que l'état actuel du groupe d'unités est différent que celui calculé pour ne pas insérer d'historique inutilement
		WHERE (EA.UnitID IS NULL OR EA.UnitStateID <> V.UnitStateID)
		---- FT1
		--AND EA.UnitStateID <> 'RIM'
		--AND EA.UnitStateID <> 'TRI'

-- Fin de la mise à jour des états de conventions
	
-- Les lignes qui suivent mettent à jour l'état des conventions

	-- Va chercher l'état de premier niveau des groupes d'unités
	SELECT 
		ConventionID,
		Unit1LevelStateID = 
			CASE 
				WHEN CS3.UnitStateID IS NOT NULL THEN CS3.UnitStateID -- Gère le cas ou l'état est de troisième niveau 
				WHEN CS2.UnitStateID IS NOT NULL THEN CS2.UnitStateID -- Gère le cas ou l'état est de deuxième niveau 
			ELSE CS.UnitStateID -- Gère le cas ou l'état est de premier niveau 
			END
	INTO #Unit1LevelStateID
	FROM dbo.Un_Unit U
	JOIN Un_UnitUnitState UUS ON UUS.UnitID = U.UnitID
	JOIN ( -- Va chercher la date la plus haute des états (état actuel)
		SELECT
			UnitID,
			StartDate = MAX(StartDate) 
		FROM Un_UnitUnitState
		GROUP BY UnitID
		) UMX ON UMX.UnitID = U.UnitID AND UMX.StartDate = UUS.StartDate -- Élimine les états qui ne sont pas celui actuel
	LEFT JOIN Un_ConventionState CS ON UUS.UnitStateID = CS.UnitStateID
	LEFT JOIN Un_UnitState US ON UUS.UnitStateID = US.UnitStateID
	LEFT JOIN Un_ConventionState CS2 ON US.OwnerUnitStateID = CS2.UnitStateID
	LEFT JOIN Un_UnitState US2 ON US2.UnitStateID = US.OwnerUnitStateID
	LEFT JOIN Un_ConventionState CS3 ON US2.OwnerUnitStateID = CS3.UnitStateID

	INSERT INTO Un_ConventionConventionState
		SELECT DISTINCT
			U.ConventionID,
			CS.ConventionStateID,
			@Today
		FROM #Unit1LevelStateID U
		JOIN Un_ConventionState CS ON (CS.UnitStateID = U.Unit1LevelStateID)
		JOIN ( -- Va chercher l'état de convention qui a le plus haut niveau de priorité, celui qui prévost sur les autres
			SELECT
				ConventionID,
				PriorityLevelID = MIN(CS.PriorityLevelID)
			FROM #Unit1LevelStateID U
			JOIN Un_ConventionState CS ON (CS.UnitStateID = U.Unit1LevelStateID)
			GROUP BY ConventionID
			) V ON (V.ConventionID = U.ConventionID) AND (CS.PriorityLevelID = V.PriorityLevelID) -- Garde uniquement l'état avec le plus au niveau de priorité parmis les unités
		LEFT JOIN ( -- Va chercher l'état actuel de la convention
			SELECT 
				CS.ConventionID,
				CS.ConventionStateID
			FROM Un_ConventionConventionState CS
			JOIN ( -- Va chercher la date la plus haute des états (état actuel) 
				SELECT 
					ConventionID,
					StartDate = MAX(StartDate) 
				FROM Un_ConventionConventionState
				GROUP BY ConventionID
				) V ON (V.ConventionID = CS.ConventionID AND CS.StartDate = V.StartDate) -- Élimine les états qui ne sont pas celui actuel
			) EA ON (EA.ConventionID = U.ConventionID)
		-- S'assure que l'état actuel de la convention est différent que celui calculé pour ne pas insérer d'historique inutilement
		WHERE (EA.ConventionID IS NULL)
			OR (EA.ConventionStateID <> CS.ConventionStateID)

	DROP TABLE #Unit1LevelStateID

	-- Si une convention n'a pas ou plus de groupe d'unité, sont état doit être 'Proposition'
	INSERT INTO Un_ConventionConventionState
		SELECT DISTINCT
			C.ConventionID,
			'PRP',
			@Today
		FROM dbo.Un_Convention C
		LEFT JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		-- Va chercher l'état actuel de la convention
		LEFT JOIN (
			SELECT 
				CS.ConventionID,
				CS.ConventionStateID
			FROM Un_ConventionConventionState CS
			JOIN (
				SELECT 
					ConventionID,
					StartDate = MAX(StartDate) 
				FROM Un_ConventionConventionState
				GROUP BY ConventionID
				) V ON V.ConventionID = CS.ConventionID AND CS.StartDate = V.StartDate
			) EA ON EA.ConventionID = C.ConventionID
		-- S'assure que l'état actuel de la convention est différent que celui calculé pour ne pas insérer d'historique inutilement
		WHERE U.UnitID IS NULL
		  AND (EA.ConventionID IS NULL
			 OR EA.ConventionStateID <> 'PRP')
-- Fin de la mise à jour des états de conventions
END