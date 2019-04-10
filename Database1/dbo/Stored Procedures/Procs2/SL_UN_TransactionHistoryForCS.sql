/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : 	SL_UN_TransactionHistoryForCS
Description         : 	Procédure retournant les données nécessaires à l'historique des transactions du service à la 
								clientèle
Valeurs de retours  :	Dataset contenant les données
Note                :						2004-06-04	Bruno Lapointe		Création
								ADX0000554	IA	2004-10-28	Bruno Lapointe			Ajout d'un champ de retour pour indiquer si 
																								un CPA a été expédié dans un fichier bancaire
																								ou non (CPA anticipé)
								ADX0001237	BR	2004-01-19	Bruno Lapointe			Retour du status de l'opération
								ADX0000720	IA	2005-07-19	Bruno Lapointe			CPA d'annulation ou annulé pas en bleu
								ADX0000753	IA	2005-10-05	Bruno Lapointe			Changer les valeurs de retours +HaveCheque, 
																								-ChequeID, -ChequeNo, -ChequeDate, 
																								-ChequeOrderID, -ChequeOrderDate, 
																								-ChequeOrderDesc, -ChequeName, -ChequeAmount
								ADX0000806	IA	2006-03-31	Bruno Lapointe			Adaptation PCEE 4.3 : -GovernmentGrant, +fCESG
																								+fACESG, +fCLB
								ADX0001100	IA	2006-10-24	Alain Quirion			Retour de TIO pour les opérations liées au transfert interne
								ADX0001235	IA	2007-02-13	Alain Quirion		Utilisation de dtRegStartDate pour la date de début de régime
								ADX0002426	BR	2007-05-22	Bruno Lapointe		Création de la table Un_CESP.
												2010-05-10	Pierre Paquet			Ne pas afficher les transferts à zéro.
												2010-06-07	Pierre Paquet			Correction: ajout de Cosation=0 pour l'affichage.
												2011-04-01	Frédérick Thibault	Ajout des fonctionnalité du prospectus 2010-2011 (FT1)
												2014-08-28	Pierre-Luc Simard	Retrait du PlanTypeID pour les TFR car doublons lorsque historique demandé pour un souscripteur (PLS1)
												2014-09-24	Donald Huppé			Modification pour les DDD : on passe le operid dans le champ iOperationID.
												2016-04-21	Pierre-Luc Simard	Ajouter la LastReceiveDate de l'opération FRM lorsque la demande est faite par groupe d'unité
												2016-04-21	Steve Bélanger		Afficher les annulations de FRM avec des parenthèses
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_TransactionHistoryForCS] (
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

	-- Crée des tables temporaires
	CREATE TABLE #TransactionHistory (
		OperID INTEGER,
		OperDate DATETIME,
		EffectDate DATETIME,
		OperTypeID VARCHAR(3),
		CodeNSF VARCHAR(3),
		Total MONEY,
		Cotisation MONEY,
		Fee MONEY,
		Ecart MONEY,
		SubscInsur MONEY,
		BenefInsur MONEY,
		TaxOnInsur MONEY,
		Interests MONEY,
		
		mMontant_Frais		MONEY,	-- FT1
		mMontant_TaxeTPS	MONEY,	-- FT1
		mMontant_TaxeTVQ	MONEY,	-- FT1
		
		LastReceiveDate DATETIME,
		fCESG MONEY, -- Le montant de subvention reçue du PCEE ou remboursée au PCEE pour cette transaction.
		fACESG MONEY, -- Le montant de subvention supplémentaire reçue du PCEE ou remboursée au PCEE pour cette transaction.
		fCLB MONEY, -- Le montant de BEC reçu du PCEE ou remboursé au PCEE dans cette transaction.
		iOperationID INTEGER,
		HaveCheque BIT,
		LockAccount BIT,
		AnticipedCPA BIT,
		OperTypeIDView CHAR(3),
		PlanTypeIDView CHAR(3),
		Status INTEGER
		PRIMARY KEY (OperID, OperTypeID, LockAccount)
	)

	CREATE TABLE #TransactionHistoryOperDate (
		OperDate DATETIME PRIMARY KEY,
		CotisationFee MONEY
	)

	CREATE TABLE #LockAccount (
		ConventionID INTEGER PRIMARY KEY,
		EffectDate DATETIME
	)

	INSERT INTO #LockAccount	
		SELECT 
			C.ConventionID,
			EffectDate = C.dtRegStartDate
		FROM dbo.Un_Convention C 
		JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
		JOIN #Unit T ON T.UnitID = U.UnitID
		GROUP BY C.ConventionID,
					C.dtRegStartDate

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
		WHERE 	O.OperTypeID = 'TFR'
			AND	O2.OperTypeID = 'OUT'
			AND T.iTIOID IS NULL		-- N'est pas lié à un transfert interne
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
		WHERE O.OperTypeID = 'TIN'
			AND O2.OperTypeID = 'OUT'
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
		WHERE O.OperTypeID = 'OUT'
			AND O2.OperTypeID = 'TIN'
		-----
		UNION
		-----
		SELECT
			O.OperID,
			'TIO',
			NULL --P.PlanTypeID  -- PLS1
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
		WHERE 	O.OperTypeID = 'TFR'
			AND	O2.OperTypeID = 'OUT'
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
	INSERT INTO #TransactionHistory 
		SELECT 
			O.OperID,
			O.OperDate,
			Ct.EffectDate,
			O.OperTypeID,
			CodeNSF = ISNULL(BRL.BankReturnTypeID,''),
			Total = 
				ISNULL(Ct.Cotisation,0) + 
				ISNULL(Ct.Fee,0) + 
				ISNULL(Ct.SubscInsur,0) + 
				ISNULL(Ct.BenefInsur,0) + 
				ISNULL(Ct.TaxOnInsur,0) + 
				ISNULL(Ct.Interests,0),
			Cotisation = ISNULL(Ct.Cotisation,0),
			Fee = ISNULL(Ct.Fee,0),
			Ecart = 0,
			SubscInsur = ISNULL(Ct.SubscInsur,0),
			BenefInsur = ISNULL(Ct.BenefInsur,0),
			TaxOnInsur = ISNULL(Ct.TaxOnInsur,0),
			Interests = ISNULL(Ct.Interests,0),
			
			mMontant_Frais		= ISNULL(FRS.mMontant_Frais, 0), -- FT1
			mMontant_TaxeTPS	= ISNULL(FRS.mMontant_TaxeTPS , 0), -- FT1
			mMontant_TaxeTVQ	= ISNULL(FRS.mMontant_TaxeTVQ , 0), -- FT1
			
			LastReceiveDate = ISNULL(GG.LastReceiveDate, FRM.LastReceiveDateFRM),
			fCESG = ISNULL(GG.fCESG,0),
			fACESG  = ISNULL(GG.fACESG ,0),
			fCLB = ISNULL(GG.fCLB,0),
			--iOperationID = ISNULL(L.iOperationID,0),
			iOperationID = case when ddd.IdOperationFinanciere is not NULL or L.iOperationID is not null then o.OperID else 0 end,
			HaveCheque = 
				CAST	(	
						CASE 
							WHEN Ch.OperID IS NULL and ddd.IdOperationFinanciere is null THEN 0
						ELSE 1
						END AS BIT
						),
			LockAccount = ISNULL(Ct.LockAccount,0),
			AnticipedCPA =
				CASE 
					WHEN O.OperTypeID = 'CPA' AND BF.OperID IS NULL AND O.OperDate >= '2002-08-01' AND CO.OperID IS NULL AND AO.OperID IS NULL THEN 1
				ELSE 0
				END,
			OperTypeIDView = ISNULL(SOV.OperTypeIDView, O.OperTypeID),
			PlanTypeIDView =  ISNULL(SOV.PlanTypeIDView,''),
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
				Interests = SUM(Interests),
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
					Interests = 0,
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
				LEFT JOIN #LockAccount L ON C.ConventionID = L.ConventionID AND (
														CASE 
															WHEN L.EffectDate IS NULL THEN O.Operdate+1
															WHEN L.EffectDate < '2003-01-01' THEN O.Operdate-1
														ELSE L.EffectDate
														END <= O.OperDate)
				GROUP BY 
					Ct.OperID,
					Ct.EffectDate,
					CASE 
						WHEN L.ConventionID IS NULL THEN 1
					ELSE 0
					END
				UNION 
				SELECT 
					O.OperID,
					EffectDate = O.OperDate,
					Cotisation = 0,
					Fee = 0,
					SubscInsur = 0,
					BenefInsur = 0,
					TaxOnInsur = 0,
					Interests = SUM(CO.ConventionOperAmount),
					LockAccount = 
						CASE 
							WHEN L.ConventionID IS NULL THEN 1
						ELSE 0
						END
				FROM Un_Oper O
				JOIN Un_ConventionOper CO ON CO.OperID = O.OperID
				JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
				JOIN #Convention T ON T.ConventionID = C.ConventionID
				LEFT JOIN #LockAccount L ON C.ConventionID = L.ConventionID AND (
														CASE 
															WHEN L.EffectDate IS NULL THEN O.Operdate+1
															WHEN L.EffectDate < '2003-01-01' THEN O.Operdate-1
														ELSE L.EffectDate
														END <= O.OperDate)
				WHERE (CO.ConventionOperTypeID = 'INC')
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
		-- Va chercher le code NSF
		LEFT JOIN Mo_BankReturnLink BRL ON BRL.BankReturnCodeID = O.OperID
		-- Va chercher le montant de frais de gestion et les taxes -- FT1
		LEFT JOIN (
			SELECT	 iID_Oper			= FR.iID_Oper
					,mMontant_Frais		= FR.mMontant_Frais
					,mMontant_TaxeTPS	= FT1.mMontant_Taxe
					,mMontant_TaxeTVQ	= FT2.mMontant_Taxe

			FROM tblOPER_Frais		FR
			
			JOIN tblOPER_FraisTaxes	FT1	ON	FT1.iID_Frais			= FR.iID_Frais
										AND	FT1.iID_Type_Parametre	= (	SELECT iID_Type_Parametre
																		FROM tblGENE_TypesParametre
																		WHERE vcCode_Type_Parametre = 'OPER_TAXE_TPS')
			JOIN tblOPER_FraisTaxes	FT2	ON	FT2.iID_Frais			= FR.iID_Frais
										AND	FT2.iID_Type_Parametre	= (	SELECT iID_Type_Parametre
																		FROM tblGENE_TypesParametre
																		WHERE vcCode_Type_Parametre = 'OPER_TAXE_TVQ')
				) FRS ON FRS.iID_Oper = O.OperID
		-- Va chercher le montant de subvention et la dernière date de fichier reçu
		LEFT JOIN (
			-- Va chercher les subventions dans le cas ou le type de recherche est convention ou souscripteur
			SELECT  
				OperID = CE.OperSourceID, 
				LastReceiveDate = MAX(OP.OperDate),
				fCESG  = SUM(CE.fCESG), 
				fACESG = SUM(CE.fACESG),
				fCLB = SUM(CE.fCLB)
			FROM #Convention T
			JOIN dbo.Un_Convention C ON (T.ConventionId = C.ConventionID)
			JOIN Un_CESP CE ON CE.ConventionID = T.ConventionID
			JOIN Un_Oper OP ON OP.OPerID = CE.OperID 
			WHERE  (T.ConventionID = @ID AND @Type = 'CNV') OR (C.SubscriberID = @ID AND @Type = 'SUB')
			GROUP BY CE.OperSourceID

			-----
			UNION
			-----
			-- Va chercher les subventions dans le cas ou le type de recherche est groupe d'unités

			SELECT 
				OperID = CE.OperSourceID,
				LastReceiveDate = MAX(OP.OperDate), 
				fCESG = SUM(CE.fCESG),
				fACESG = SUM(CE.fACESG),
				fCLB = SUM(CE.fCLB)
			FROM #Unit T
			JOIN dbo.Un_Unit U ON U.UnitID = T.UnitID 
			JOIN Un_Cotisation Ct ON Ct.UnitID = T.UnitID 
			JOIN Un_CESP CE ON (CE.CotisationID = Ct.CotisationID  and CE.ConventionID = U.ConventionID)
			JOIN Un_Oper OP ON OP.OperID = CE.OperID 
			WHERE @Type = 'GUN' 
			GROUP BY CE.OperSourceID
			) GG ON GG.OperID = O.OperID
		-- Va chercher les informations des chèques
		LEFT JOIN (
			SELECT DISTINCT L.OperID
			FROM Un_OperLinkToCHQOperation L
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = L.iOperationID
			JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
			) Ch ON Ch.OperID = O.OperID
		LEFT JOIN Un_OperLinkToCHQOperation L ON L.OperID = O.OperID
		LEFT JOIN Un_OperBankFile BF ON BF.OperID = O.OperID
		LEFT JOIN Un_OperCancelation CO ON CO.OperSourceID = O.OperID
		LEFT JOIN Un_OperCancelation AO ON AO.OperID = O.OperID
		LEFT JOIN (SELECT DISTINCT IdOperationFinanciere FROM DecaissementDepotDirect) DDD ON O.OperID = DDD.IdOperationFinanciere
		LEFT JOIN (
				SELECT 
					CE.OperSourceID,
					LastReceiveDateFRM = MAX(O.OperDate)	
				FROM Un_CESP CE
				JOIN Un_Oper O ON O.OperID = CE.OperID
				JOIN Un_Oper OP ON OP.OperID = CE.OperSourceID
				WHERE OP.OperTypeID = 'FRM'
				GROUP BY CE.OperSourceID
				) FRM ON FRM.OperSourceID = O.OperID
		WHERE Ct.OperID IS NOT NULL 

	-- Va chercher les subventions qui ne sont pas lié à une cotisation de cette convention
	INSERT INTO #TransactionHistory
		SELECT 
			O.OperID,
			O.OperDate,
			EffectDate = NULL,
			O.OperTypeID,
			CodeNSF = '',
			Total = 0,
			Cotisation = 0,
			Fee = 0,
			Ecart = 0,
			SubscInsur = 0,
			BenefInsur = 0,
			TaxOnInsur = 0,
			Interests = 0,

			mMontant_Frais		= 0, -- FT1
			mMontant_TaxeTPS	= 0, -- FT1
			mMontant_TaxeTVQ	= 0, -- FT1
			
			LastReceiveDate = GG.LastReceiveDate,
			fCESG = ISNULL(GG.fCESG,0),
			fACESG  = ISNULL(GG.fACESG ,0),
			fCLB = ISNULL(GG.fCLB,0),
			iOperationID = ISNULL(L.iOperationID,0),
			HaveCheque = 
				CAST	(	
						CASE 
							WHEN Ch.OperID IS NULL THEN 0
						ELSE 1
						END AS BIT
						),
			LockAccount = 0,
			AnticipedCPA = 0,
			OperTypeIDView = ISNULL(SOV.OperTypeIDView, O.OperTypeID),
			PlanTypeIDView =  ISNULL(SOV.PlanTypeIDView,''),
			Status =
				CASE
					WHEN CO.OperID IS NOT NULL THEN 1
					WHEN AO.OperID IS NOT NULL THEN 2
				ELSE 0
				END
		FROM Un_Oper O
		LEFT JOIN #SpecialOperView SOV ON SOV.OperID = O.OperID
		-- Va chercher le montant de subvention et la dernière date de fichier reçu
		JOIN (
			-- Va chercher les subventions qui n'ont pas de transaction dans le cas ou le type de recherche est convention ou souscripteur
			SELECT 
				OperID = CE.OperSourceID,
				LastReceiveDate = MAX(V.LastReceiveDate), --Nassim Modif MAX(V.LastReceiveDate)
				fCESG = SUM(CE.fCESG),
				fACESG = SUM(CE.fACESG),
				fCLB = SUM(CE.fCLB)
			FROM #Convention T
			JOIN Un_CESP CE ON CE.ConventionID = T.ConventionID
			JOIN (
				SELECT
					C4.OperID,
					LastReceiveDate = MAX(ORF.OperDate)
				FROM #Convention T
				JOIN Un_CESP400 C4 ON T.ConventionID = C4.ConventionID
				JOIN Un_CESPSendFile SF ON SF.iCESPSendFileID = C4.iCESPSendFileID
				JOIN Un_CESPReceiveFile RF ON RF.iCESPReceiveFileID = SF.iCESPReceiveFileID
				JOIN Un_Oper ORF ON ORF.OperID = RF.OperID
				WHERE C4.CotisationID IS NULL
				GROUP BY C4.OperID
				) V ON V.OperID = CE.OperSourceID
			GROUP BY CE.OperSourceID
			) GG ON GG.OperID = O.OperID
		-- Va chercher les informations des chèques
		LEFT JOIN (
			SELECT DISTINCT L.OperID
			FROM Un_OperLinkToCHQOperation L
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = L.iOperationID
			JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
			) Ch ON Ch.OperID = O.OperID
		LEFT JOIN Un_OperLinkToCHQOperation L ON L.OperID = O.OperID
		LEFT JOIN Un_OperCancelation CO ON CO.OperSourceID = O.OperID
		LEFT JOIN Un_OperCancelation AO ON AO.OperID = O.OperID
		WHERE O.OperTypeID <> 'FRM'
		
	-- Va chercher les changements de dépôts
	INSERT INTO #TransactionHistory
		SELECT 
			OperID = UMH.UnitModalHistoryID,
			OperDate = UMH.StartDate,
			EffectDate = UMH.StartDate,
			OperTypeID = 'CMD',
			CodeNSF = '',
			Total = 0,
			Cotisation = 0,
			Fee = 0,
			Ecart = 0,
			SubscInsur = 0,
			BenefInsur = 0,
			TaxOnInsur = 0,
			Interests = 0,
			
			mMontant_Frais		= 0, -- FT1
			mMontant_TaxeTPS	= 0, -- FT1
			mMontant_TaxeTVQ	= 0, -- FT1

			LastReceiveDate = NULL,
			fCESG = 0,
			fACESG  = 0,
			fCLB = 0,
			iOperationID = 0,
			HaveCheque = CAST(0 AS BIT),
			LockAccount = 
				CASE 
					WHEN L.ConventionID IS NULL THEN 1
				ELSE 0
				END,
			AnticipedCPA = 0,
			OperTypeIDView = 'CMD',
			OperTypeIDView = '',
			Status = 0
		FROM Un_UnitModalHistory UMH
		JOIN dbo.Un_Unit U ON U.UnitID = UMH.UnitID
		JOIN #Unit T ON T.UnitID = U.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		LEFT JOIN (
			SELECT 
				UMH.UnitModalHistoryID,
				CotisationFee = SUM(Cotisation+Fee)
			FROM Un_UnitModalHistory UMH
			JOIN dbo.Un_Unit U ON U.UnitID = UMH.UnitID
			JOIN #Unit T ON T.UnitID = U.UnitID
			JOIN dbo.Un_Convention C ON U.ConventionID = C.ConventionID
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID AND O.OperDate <= UMH.StartDate
			GROUP BY UMH.UnitModalHistoryID
			) Ct ON Ct.UnitModalHistoryID = UMH.UnitModalHistoryID
		LEFT JOIN #LockAccount L ON C.ConventionID = L.ConventionID AND (
														CASE 
															WHEN L.EffectDate IS NULL THEN UMH.StartDate+1
															WHEN L.EffectDate < '2003-01-01' THEN UMH.StartDate-1
														ELSE L.EffectDate
														END <= UMH.StartDate)

	-- Crée une table de date unique pour enlever les doublont et les heures
	INSERT INTO #TransactionHistoryOperDate	
		SELECT DISTINCT
			dbo.FN_CRQ_DateNoTime(OperDate),
			0
		FROM #TransactionHistory 

	-- Va chercher le montant de cotisation et de frais réel pour chaque date d'opération
	DECLARE 
		@OperDate DATETIME,
		@CotisationFee MONEY

	DECLARE Todo CURSOR FOR 
		SELECT 
			OperDate 
		FROM #TransactionHistoryOperDate 
	
	OPEN Todo

	FETCH NEXT FROM Todo	INTO
		@OperDate

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @CotisationFee = ISNULL(SUM(Ct.Cotisation+Ct.Fee),0)
		FROM Un_Oper O 
		JOIN Un_Cotisation Ct ON O.OperID = Ct.OperID
		JOIN dbo.Un_Unit U ON Ct.UnitID = U.UnitID
		JOIN #Unit T ON T.UnitID = U.UnitID
		WHERE O.OperDate <= @OperDate

		UPDATE #TransactionHistoryOperDate
		SET CotisationFee = @CotisationFee
		WHERE OperDate = @OperDate
		
		FETCH NEXT FROM Todo	INTO
			@OperDate		
	END
	CLOSE Todo
	DEALLOCATE Todo

	-- Remplis l'écart pour chacune des transactions
	UPDATE #TransactionHistory
	SET Ecart = Ct.CotisationFee - Est.Estimated
	FROM #TransactionHistory
	JOIN #TransactionHistoryOperDate Ct ON Ct.OperDate = dbo.FN_CRQ_DateNoTime(#TransactionHistory.OperDate)
	JOIN ( -- Va chercher le montant théorique de cotisation et frais à la date d'opération 
		SELECT 
			TH.OperDate,
			P.PlanTypeID,
			Estimated =
				SUM(dbo.FN_UN_EstimatedCotisationAndFee (
								U.InForceDate, 
								TH.OperDate, 
								DAY(C.FirstPmtDate), 
								U.UnitQty+ISNULL(UR.URUnitQty,0),
								M.PmtRate,
								M.PmtByYearID,
								M.PmtQty,
								U.InForceDate))
		FROM #TransactionHistoryOperDate TH
		JOIN ( -- Donne la modalité de paiement qu'avait le groupe d'unités à la date d'opération
			SELECT 
				UMHV.UnitID,
				UMHV.OperDate,
				UnitModalHistoryID = MAX(UMH.UnitModalHistoryID)
			FROM (
				SELECT 
					U.UnitID,
					TH.OperDate,
					StartDate = MAX(UMH.StartDate)
				FROM dbo.Un_Unit U
				JOIN #Unit T ON T.UnitID = U.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN Un_UnitModalHistory UMH ON UMH.UnitID = U.UnitID
				JOIN #TransactionHistoryOperDate TH ON TH.OperDate >= CAST(FLOOR(CAST(UMH.StartDate AS FLOAT)) AS DATETIME)
				GROUP BY 
					U.UnitID,
					TH.OperDate
				) UMHV 
			JOIN Un_UnitModalHistory UMH ON UMH.UnitID = UMHV.UnitID AND UMH.StartDate = UMHV.StartDate
			GROUP BY 
				UMHV.UnitID,
				UMHV.OperDate 
			) UMHV ON UMHV.OperDate = TH.OperDate
		JOIN Un_UnitModalHistory UMH ON UMH.UnitModalHistoryID = UMHV.UnitModalHistoryID
		JOIN dbo.Un_Unit U ON U.UnitID = UMH.UnitID
		JOIN #Unit T ON T.UnitID = U.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Un_Modal M ON M.ModalID = UMH.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID
		LEFT JOIN ( -- Donne le nombre d'unités qui ont été résilié après la date d'opération par groupe d'unités
			SELECT
				U.UnitID,
				TH.OperDate,
				URUnitQty = SUM(ISNULL(UR.UnitQty,0))
			FROM #TransactionHistoryOperDate TH
			JOIN Un_UnitReduction UR ON UR.ReductionDate > TH.OperDate
			JOIN dbo.Un_Unit U ON UR.UnitID = U.UnitID
			JOIN #Unit T ON T.UnitID = U.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			GROUP BY 
				U.UnitID,
				TH.OperDate
			) UR ON UR.UnitID = U.UnitID AND UR.OperDate = TH.OperDate
		GROUP BY TH.OperDate, P.PlanTypeID
		) Est ON Est.OperDate = dbo.FN_CRQ_DateNoTime(#TransactionHistory.OperDate)
	WHERE Est.PlanTypeID <> 'IND'	

	SELECT -- Fait la sélection finale
		OperID,
		OperDate,
		EffectDate,
		--OperTypeID,
		OperTypeID = CASE WHEN OperTypeID = 'FRM' AND Status = 2 THEN '(FRM)' ELSE OperTypeID END,
		CodeNSF,
		Total,
		Cotisation,
		Fee,
		Ecart,
		SubscInsur,
		BenefInsur,
		TaxOnInsur,
		Interests,

		mMontant_Frais,		-- FT1
		mMontant_TaxeTPS,	-- FT1
		mMontant_TaxeTVQ,	-- FT1
		
		LastReceiveDate,
		fCESG ,
		fACESG,
		fCLB,
		iOperationID,
		HaveCheque,
		LockAccount,
		AnticipedCPA,
		OperTypeIDView,
		PlanTypeIDView,
		Status
	FROM #TransactionHistory
	WHERE NOT (OperTypeID IN ('OUT', 'TIN') AND fCESG = 0 AND fACESG = 0 AND fCLB = 0 and Cotisation = 0) -- On exclus les transferts à zéro. 2010-05-10
	ORDER BY OperDate DESC, OperID DESC 

	-- Détruit les tables temporaires
	DROP TABLE #TransactionHistoryOperDate
	DROP TABLE #TransactionHistory 
	DROP TABLE #LockAccount
	DROP TABLE #Convention
	DROP TABLE #Unit
	DROP TABLE #SpecialOperView
END
