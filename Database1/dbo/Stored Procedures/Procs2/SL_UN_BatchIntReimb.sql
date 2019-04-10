/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */
	
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_BatchIntReimb
Description         :	Procédure retournant les données pour remplir la grille de visualisation de l’outil de 
						gestion des remboursements intégraux (RIN).  Elle doit être appelée à l’ouverture de l’outil 
						et lors du rafraîchissement de la liste.
			
Valeurs de retours  :	Dataset :
							UnitID					ID unique du groupe d’unités.
							ConventionID			ID unique de la convention.
							SubscriberID			ID unique du souscripteur.
							BeneficiaryID			ID unique du bénéficiaire.
							FeeByUnit				indique les interets par groupe d'unites
							ConventionIDInd			ID unique de la Convention Individuelle
							ConventionNoInd			Numéro de la convention individuelle.
							InForceDate				Date d’entrée en vigueur du groupe d’unités.
							UnitQty					Nombre d’unités.
							ConventionNo			Numéro de la convention.
							PlanId					Numero du type de plan.
							PlanDesc				Description du plan
							[Transaction]			Type de transaction (RIN ou RIO)
							indCotisationNegative	Indique si les frais sont couverts par la modalite dela convention individuelle
							SubscriberLastName		Nom du souscripteur.
							SubscriberFirstName		Prénom du souscripteur.
							BeneficiaryLastName		Nom du bénéficiaire.
							BeneficiaryFirstName	Prénom du bénéficiaire.
							iStep					Numéro de l’étape actuel du RIN.
							IsChecked				Indique si la case à cocher est supposée être cochée.
							HaveRegistrationProof	Indique si on a une preuve d’inscription complète.
							CotisationFee			Capital.
							EstimatedCotisationFee	Capital souscrit.
							CESGExpected			SCEE prévue (20%).
							CESG					SCEE reçue.
							LastDeposit				Date estimé de dernier dépôt.
							bBenefIsInsur			Indique s’il y a de l’assurance bénéficiaire ou non.
							OperID					ID de l’opération RIN si elle a été faite.
							ChequeID				ID du chèque de RI s’il a été émis.
							IntOriginalEstimatedReimbDate	Date estimée originale de remboursement intégral.
							IntEstimatedReimbDate		Date estimée de remboursement intégral 
							bStopPayment				Champ indiquant si une convention est en arrêt de paiement bStopPayment  = 1 (‘Oui’ ) n’est pas en arrêt de paiement bStopPayment = 0 (‘Non’ ).
							bIsContestWinner			Indique si la source de vente du groupe d'unités est de type gagnant de concours
							SubAddressLost				Indique si l'adresse du souscripteur est perdu
							BenAddressLost				Indique si l'adresse du bénéficiaire est perdu
							mIQEECdb					Montant du crédit de base de l'IQEE
							mIQEEMaj					Montant du crédit majoré de l'IQEE

Exemple d'appel :
					EXECUTE [dbo].[SL_UN_BatchIntReimb] 2, 0

Note                :	ADX0000694	IA	2005-06-03	Bruno Lapointe		Création
						ADX0001612	BR	2005-10-14	Bruno Lapointe		Exclure les RIN annulé ou d'annulation et optimisation.
						ADX0001624	BR	2005-10-19	Bruno Lapointe		Preuve d'inscription.
						ADX0001114	IA	2006-11-17	Alain Quirion			Gestion des deux périodes de calcul de date estimée de RI (FN_UN_EstimatedIntReimbDate)												
						ADX0002426	BR	2007-05-22	Alain Quirion			Modification : Un_CESP au lieu de Un_CESP900
						ADX0001357	IA	2007-06-04	Alain Quirion			Ajout du champ bIsContestWinner
						ADX0001414	IA	2007-06-08	Alain Quirion			Ajout du champ SubAddressLost et BenAddressLost
						ADX0003037	UR	2007-08-22	Bruno Lapointe	Gérer le cas des deux arrêts de paiements actifs sur une même convention
										2008-06-09	Nassim Rekkab				Ajout nouvelle colonne Transactions
										2008-06-09	Nassim Rekkab				Ajout colonne PlanId
										2008-06-09	Nassim Rekkab				Ajout d'un indicateur de cotisation negative (si la convention individuelle
																								ne couvre pas les frais de la modalité)
										2008-06-19	Jean-Francois Arial			Identifier un RIN-RIO
										2008-07-15	Jean-Francois Arial			Ajouter la colonne PmtEndConnectID pour le stop bleu
										2009-03-10	Patrick Robitaille				Ajouter la colonne PlanDesc afin d'avoir la description du plan
										2009-03-10	Patrick Robitaille				Ajouter les colonnes SubscriberCountry et BeneficiaryCountry afin d'afficher les pays respectifs.
										2010-12-20	Jean-François Gauthier	Ajout des colonnes mIQEECdb et mIQEEMaj
										2011-01-11	Jean-François Gauthier	Correction des noms de champs IQEE
										2011-04-12	Frédérick Thibault			Gestion des différents type d'opérations de conversion (RIO et RIM) (FT1)
										2012-07-20	Donald Huppé					GLPI 7945 : sortir seulement les unité de convention non fermé
										2014-04-15	Pierre-Luc Simard			Ne plus afficher les cas à partir de l'étape 4 puisque géré dans Proacces.
										2014-10-08	Pierre-Luc Simard			Afficher à nouveau l'étape 4 pour les RIM
										2015-03-09	Donald Huppé				GLPI 13779 : Exclure les convention qui sont déjà RI.
                                        2018-01-25  Pierre-Luc Simard           N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_BatchIntReimb] 
	(@ConnectID INTEGER,		-- ID de connexion de l'usager qui demande la liste.
	@UnitIDs INTEGER)		-- ID du blob contenant les UnitID séparés par des "," des groupe d'unités dont on veut 
							-- rafraîchir les donn‚es de la grille.  Si 0, alors on veut rafraîchir tout les unités 
							-- de la grille.
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE
		@dtRINToolLastTreatedDate DATETIME,
		@dtRINToolLastImportedDate DATETIME,
		@UserID INTEGER,
		@dtTreatment DATETIME
		
	SET @dtTreatment = GETDATE()
				
	SELECT 
			@dtRINToolLastTreatedDate = MAX(dtRINToolLastTreatedDate),
			@dtRINToolLastImportedDate = MAX(dtRINToolLastImportedDate)
	FROM Un_Def

	SELECT @UserID = UserID
	FROM Mo_Connect
	WHERE ConnectID = @ConnectID

	CREATE TABLE #tUnitToRIN (
		UnitID INTEGER PRIMARY KEY)

	IF @UnitIDs = 0
		INSERT INTO #tUnitToRIN
			SELECT DISTINCT 
				U.UnitID
			FROM dbo.Un_Unit U
			JOIN dbo.Un_Convention C ON U.ConventionID = C.ConventionID
			JOIN Un_Modal M ON M.ModalID = U.ModalID
			JOIN Un_Plan P ON P.PlanID = M.PlanID
			JOIN Un_IntReimbStep USt ON USt.UnitID = U.UnitID
			JOIN (
				select 
					Cs.conventionid ,
					ccs.startdate,
					cs.ConventionStateID
				from 
					un_conventionconventionstate cs
					join (
						select 
						conventionid,
						startdate = max(startDate)
						from un_conventionconventionstate
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
				) css on C.conventionid = css.conventionid
			WHERE dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust) BETWEEN @dtRINToolLastTreatedDate AND @dtRINToolLastImportedDate
					AND P.PlanTypeID = 'COL' 
					AND ConventionStateID <> 'FRM'
	ELSE
		INSERT INTO #tUnitToRIN
			SELECT DISTINCT 
				UnitID = Val
			FROM dbo.FN_CRQ_BlobToIntegerTable(@UnitIDs) B
			JOIN dbo.Un_Unit U ON U.UnitID = B.Val
			JOIN Un_IntReimbStep USt ON USt.UnitID = U.UnitID
			JOIN Un_Modal M ON M.ModalID = U.ModalID
			JOIN Un_Plan P ON P.PlanID = M.PlanID
			WHERE dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust) BETWEEN @dtRINToolLastTreatedDate AND @dtRINToolLastImportedDate
				AND P.PlanTypeID = 'COL' 

	CREATE TABLE #tConvCESP (
		ConventionID INTEGER PRIMARY KEY,
		CESG MONEY NOT NULL )

	INSERT INTO #tConvCESP
		SELECT -- 3 sec
			CE.ConventionID,
			CESG = SUM(CE.fCESG+CE.fACESG+CE.fCLB)
		FROM Un_CESP CE
		JOIN dbo.Un_Unit U ON U.ConventionID = CE.ConventionID
		JOIN #tUnitToRIN URin ON URin.UnitID = U.UnitID
		GROUP BY CE.ConventionID
		
	CREATE TABLE #tUnitCotisation (
		UnitID INTEGER PRIMARY KEY,
		CotisationFee MONEY NOT NULL,
		CESGExpected MONEY NOT NULL )

	INSERT INTO #tUnitCotisation
		SELECT -- 5 sec
			Ct.UnitID,
			CotisationFee = SUM(Ct.Cotisation+Ct.Fee),
			CESGExpected = 
				SUM(
					CASE 
						WHEN Ct.EffectDate >= '1998-02-01' THEN ROUND((Ct.Cotisation+Ct.Fee)*.2, 2)
					ELSE 0
					END
					)
		FROM Un_Cotisation Ct
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		JOIN #tUnitToRIN URin ON URin.UnitID = U.UnitID
		GROUP BY Ct.UnitID

	CREATE TABLE #tUnitChq (
		UnitID INTEGER PRIMARY KEY,
		OperID INTEGER NOT NULL,
		ChequeID INTEGER NOT NULL )

	INSERT INTO #tUnitChq
		SELECT -- 3 sec
			URin.UnitID,
			O.OperID,
			ChequeID = ISNULL(Ch.OperID,0)
		FROM #tUnitToRIN URin
		JOIN Un_Cotisation Ct ON Ct.UnitID = URin.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		LEFT JOIN Un_OperCancelation OC ON OC.OperID = O.OperID OR OC.OperSourceID = O.OperID
		LEFT JOIN (
			SELECT DISTINCT L.OperID
			FROM Un_OperLinkToCHQOperation L
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = L.iOperationID
			JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
			) Ch ON Ch.OperID = O.OperID
		WHERE O.OperTypeID = 'RIN'
			AND OC.OperID IS NULL

	-- Ajout JFG :  2010-12-20 : Recherche des types IQEE
	DECLARE @TypeIQEEMaj TABLE
					(
						vcType CHAR(3)
					)

	INSERT INTO @TypeIQEEMaj
	(
		vcType
	)
	SELECT 
		f.cID_Type_Oper_Convention 
	FROM 
		dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_MAJORATION') f

	DECLARE @TypeIQEECdb TABLE
					(
						vcType CHAR(3)
					)

	INSERT INTO @TypeIQEECdb
	(
		vcType
	)
	SELECT 
		f.cID_Type_Oper_Convention 
	FROM 
		dbo.fntOPER_ObtenirOperationsCategorie('OPER_MONTANTS_CREDITBASE') f

	SELECT 
		DISTINCT
			U.UnitID,-- ID unique du groupe d’unités.
			U.ConventionID, -- ID unique de la convention.
			C.SubscriberID, -- ID unique du souscripteur.
			C.BeneficiaryID, -- ID unique du bénéficiaire.
			M2.FeeByUnit, -- Frais par unité conv individuelle
			ConventionIDInd=C2.ConventionID, --Id convention individuelle
			ConventionNoInd=C2.ConventionNo, --No convnetion individuelle
			U.InForceDate, -- Date d’entrée en vigueur du groupe d’unités.
			U.UnitQty,-- Nombre d’unités.
			C.ConventionNo, -- Numéro de la convention.
			P.PlanID,-- Nassim :ID unique du plan 
			P.PlanDesc, -- Description du plan
			
			-- FT1
			--[Transaction] = CASE WHEN ISNULL(O.OperID,0) > 0 THEN 'RIN' WHEN ISNULL(TOPER.iID_Oper_RIO,0) > 0 THEN 'RIO' ELSE NULL END,--Nassim: recuperer la transaction du type RIO 
			[Transaction] = 
				CASE 
					WHEN TOPER.OperTypeID IN ('RIO', 'RIM') THEN
						TOPER.OperTypeID
					WHEN ISNULL(O.OperID,0) > 0 THEN 
						'RIN' 
					WHEN ISNULL(TOPER.iID_Oper_RIO, 0) > 0 THEN 
						TOPER.OperTypeID
					ELSE 
						NULL
				END,--Nassim: recuperer la transaction du type RIO 
			
			indCotisationNegative = CAST (CASE WHEN CT2.mTotalCotisation < 0 THEN 1 ELSE 0 END AS BIT),--Nassim: verifie si la cotisation individuelle couvre les frais de modalite
			SubscriberLastName = HS.LastName, -- Nom du souscripteur.
			SubscriberFirstName = HS.FirstName, -- Prénom du souscripteur.
			SubscriberCountry = CS.CountryName, -- Pays du souscripteur.
			BeneficiaryLastName = HB.LastName, -- Nom du bénéficiaire.
			BeneficiaryFirstName = HB.FirstName, -- Prénom du bénéficiaire.
			BeneficiaryCountry = CB.CountryName, -- Pays du bénéficiaire.
			iStep = USt.iIntReimbStep, -- Numéro de l’étape actuel du RIN.
			IsChecked = 
				CASE 
					WHEN Cn.ConnectID IS NULL THEN 0
				ELSE 1
				END, -- Indique si la case à cocher est supposée être cochée.
			HaveRegistrationProof = -- Indique si on a une preuve d’inscription complète.
				CAST	(
						CASE
							WHEN ISNULL(B.CollegeID,0) > 0
								AND ISNULL(B.StudyStart,0) > 0
								AND B.ProgramYear > 0
								AND B.ProgramLength > 0 
								AND B.RegistrationProof <> 0 THEN 1
						ELSE 0
						END AS BIT
						),
			CotisationFee = ISNULL(Ct.CotisationFee,0), -- Capital.
			EstimatedCotisationFee = M.PmtQty * ROUND(M.PmtRate * U.UnitQty,2), -- Capital souscrit.
			CESGExpected = ISNULL(Ct.CESGExpected,0), -- SCEE prévue (20%).
			CESG = ISNULL(CESG.CESG,0), -- SCEE reçue.
			LastDeposit = dbo.fn_Un_LastDepositDate(U.InForceDate, C.FirstPmtDate, M.PmtQty, M.PmtByYearID), -- Date estimé de dernier dépôt.
			bBenefIsInsur =
				CASE 
					WHEN U.BenefInsurID IS NULL THEN 0
				ELSE 1
				END, 	-- Indique s’il y a de l’assurance bénéficiaire ou non.
			OperID = ISNULL(O.OperID,0), 	-- ID de l’opération RIN si elle a été faite.
			ChequeID = ISNULL(O.ChequeID,0), -- ID du chèque de RI s’il a été émis.
			IntOriginalEstimatedReimbDate = dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, NULL), -- Date estimée originale de remboursement intégral.
			IntEstimatedReimbDate = dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust),	-- Date estimée de remboursement intégral 
			bStopPayment = 	
				CASE
					WHEN Br.ConventionID IS NULL THEN 0
				ELSE 1
				END, -- Champ indiquant si une convention est en arrêt de paiement bStopPayment  = 1 (‘Oui’ ) n’est pas en arrêt de paiement bStopPayment = 0 (‘Non’ ).
			bIsContestWinner = ISNULL(SS.bIsContestWinner,0),
			SubAddressLost = S.AddressLost,
			BenAddressLost = B.bAddressLost,
			TOPER.iID_OPER_RIO, -- numéro de l'opération RIO,
			ISNULL(U.PmtEndConnectId,0) AS PmtEndConnectId -- Ajouté JFA 2008-07-15
			,mIQEEMaj	=		(	SELECT 
											SUM(co.ConventionOperAmount)
										FROM
											dbo.Un_ConventionOper co
											INNER JOIN @TypeIQEEMaj t
												ON t.vcType = co.ConventionOperTypeID
										WHERE		
											co.ConventionID = U.ConventionID)
			,mIQEECdb	=		(	SELECT 
											SUM(co.ConventionOperAmount)
										FROM
											dbo.Un_ConventionOper co
											INNER JOIN @TypeIQEECdb t
												ON t.vcType = co.ConventionOperTypeID
										WHERE		
											co.ConventionID = U.ConventionID)			
	FROM 
		#tUnitToRIN URin
		INNER JOIN dbo.Un_Unit U 
			ON U.UnitID = URin.UnitID
		LEFT OUTER JOIN Un_SaleSource SS 
			ON SS.SaleSourceID = U.SaleSourceID
		INNER JOIN Un_Modal M 
			ON M.ModalID = U.ModalID
		INNER JOIN Un_Plan P 
			ON P.PlanID = M.PlanID
		INNER JOIN dbo.Un_Convention C 
			ON C.ConventionID = U.ConventionID
		LEFT OUTER JOIN (  
						SELECT DISTINCT
							ConventionID
						FROM Un_Breaking 
						WHERE BreakingStartDate < @dtTreatment
							AND ISNULL(BreakingEndDate, @dtTreatment) >= @dtTreatment
						) Br 
			ON Br.ConventionID = C.ConventionID
		INNER JOIN dbo.Un_Subscriber S 
			ON S.SubscriberID = C.SubscriberID
		INNER JOIN dbo.Mo_Human HS 
			ON HS.HumanID = S.SubscriberID	
		INNER JOIN dbo.Mo_Adr SA 
			ON HS.AdrID = SA.AdrID
		INNER JOIN Mo_Country CS 
			ON CS.CountryID = SA.CountryID
		INNER JOIN dbo.Un_Beneficiary B 
			ON B.BeneficiaryID = C.BeneficiaryID
		INNER JOIN dbo.Mo_Adr AB 
			ON HS.AdrID = AB.AdrID
		INNER JOIN Mo_Country CB 
			ON CB.CountryID = AB.CountryID
		INNER JOIN dbo.Mo_Human HB 
			ON HB.HumanID = C.BeneficiaryID
		INNER JOIN ( -- 0 sec
					SELECT
						URin.UnitID,
						iIntReimbStepID = MAX(iIntReimbStepID)
					FROM #tUnitToRIN URin
					JOIN Un_IntReimbStep USt ON USt.UnitID = URin.UnitID
					GROUP BY URin.UnitID
				) UStT 
					ON UStT.UnitID = U.UnitID
		INNER JOIN Un_IntReimbStep USt 
			ON USt.iIntReimbStepID = UStT.iIntReimbStepID
		LEFT OUTER JOIN Un_IntReimbBatchCheck UCh 
			ON UCh.UnitID = U.UnitID
		LEFT OUTER JOIN Mo_Connect Cn 
			ON Cn.ConnectID = UCh.ConnectID AND Cn.UserID = @UserID
		LEFT OUTER JOIN #tUnitChq O 
			ON O.UnitID = U.UnitID
		LEFT OUTER JOIN #tUnitCotisation Ct 
			ON Ct.UnitID = U.UnitID
		LEFT OUTER JOIN #tConvCESP CESG 
			ON CESG.ConventionID = C.ConventionID
		LEFT OUTER JOIN tblOPER_OperationsRIO TOPER 
			ON (TOPER.iID_Convention_Source = C.ConventionID AND TOPER.iID_Unite_Source = U.UnitID	AND TOPER.bRIO_ANNULEE = 0 AND TOPER.bRIO_QuiAnnule = 0)
		LEFT OUTER JOIN dbo.Un_Convention C2 
			ON C2.ConventionID = TOPER.iID_Convention_Destination
		LEFT OUTER JOIN (
							SELECT Cot2.UnitID,mTotalCotisation = ISNULL(SUM(Cot2.Cotisation),0)
							FROM Un_Cotisation Cot2
							GROUP BY Cot2.UnitID) CT2 
					ON CT2.UnitID = TOPER.iID_Unite_Destination
		LEFT OUTER JOIN dbo.Un_Unit U2 
			ON U2.UnitID = TOPER.iID_Unite_Destination
		LEFT OUTER JOIN Un_Modal M2 
			ON M2.ModalID = U2.ModalID
	WHERE ISNULL(USt.iIntReimbStep,0) < 5

		-- glpi 13779 : exlure les convention qui sont déjà RI
		AND NOT (
			USt.iIntReimbStep = 3
			AND isnull(u.IntReimbDate,'9999-12-31') BETWEEN '2014-05-01' and '8888-12-31'
			AND ISNULL(Ct.CotisationFee,0) = 0 
			AND  'RIN' = 
					CASE 
						WHEN TOPER.OperTypeID IN ('RIO', 'RIM') THEN
							TOPER.OperTypeID
						WHEN ISNULL(O.OperID,0) > 0 THEN 
							'RIN' 
						WHEN ISNULL(TOPER.iID_Oper_RIO, 0) > 0 THEN 
							TOPER.OperTypeID
						ELSE 
							NULL
					END

		)
		
	GROUP BY 
		U.UnitID, U.ConventionID, C.SubscriberID, C.BeneficiaryID, M2.FeeByUnit, C2.ConventionID, 
		C2.ConventionNo, U.InForceDate, U.UnitQty, C.ConventionNo, P.PlanID, P.PlanDesc, O.OperID, 
		TOPER.iID_Oper_RIO, TOPER.OperTypeID, HS.LastName, HS.FirstName, HB.LastName, HB.FirstName, CS.CountryName, CB.CountryName,
		USt.iIntReimbStep, Cn.ConnectID, B.CollegeID, B.StudyStart, B.ProgramYear, B.ProgramLength,
		B.RegistrationProof, Ct.CotisationFee, M.PmtQty,M.PmtRate,U.UnitQty, Ct.CESGExpected,
		CESG.CESG, C.FirstPmtDate, M.PmtByYearID, U.BenefInsurID, O.ChequeID, M.BenefAgeOnBegining, 
		P.IntReimbAge, U.IntReimbDateAdjust, Br.ConventionID, SS.bIsContestWinner, S.AddressLost,
		B.bAddressLost,U.PmtEndConnectId, CAST (CASE WHEN CT2.mTotalCotisation < 0 THEN 1 ELSE 0 END AS BIT)
	ORDER BY		
		IntEstimatedReimbDate, 
		IntOriginalEstimatedReimbDate,
		C.ConventionNo -- Numéro de la convention.
    */
END