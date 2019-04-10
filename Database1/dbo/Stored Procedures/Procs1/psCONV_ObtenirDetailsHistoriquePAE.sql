/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas Inc.
Nom                 :	psCONV_ObtenirDetailsHistoriquePAE
Description         :	Retourne les bourses, les paiements sur celles-ci ainsi que le détail des paiements pour une
				        convention ou toutes les conventions liés à un bénéficiaire.
Valeurs de retours  :	Dataset :
									ScholarshipID						INTEGER		ID unique de la bourse.
									ConventionID						INTEGER		ID unique de la convention.
									ScholarshipNo						SMALLINT		Numéro de la bourse.
									fPaymentAmount						MONEY   Montant du chèque ou du dépot direct
									OperDate								DATETIME		Date d’opération.
									ModePaiement						Est un cheque ou Dépot direct ou inconnu
									ScholarshipStatusID				CHAR(3)		Chaîne de 3 caractères qui donne l'état de la bourse ('RES'=En réserve, 'PAD'=Payée, 'ADM'=Admissible, 'WAI'=En attente, 'TPA'=À payer, 'DEA'=Décès, 'REN'=Renonciation, '25Y'=25 ans de régime, '24Y'=24 ans d'âge).
									ScholarshipAmount					MONEY			Montant de la bourse.
									ScholarshipPmtID					INTEGER		ID unique du paiement de bourse.
									OperID								INTEGER		ID unique de l’opération qui a effectué le paiement.
									OperTypeID							CHAR(3)		Code de 3 caractères du type d’opération.
									iOperationID						INTEGER		ID de l’opération dans le module des chèques
									iPaymentID							INTEGER		Id unique du chèque ou du DDD (clef dans la table)
									iPaymentNumber						INTEGER		Numéro du chèque (tel qu'imprimé) ou numéro du DDD mis en négatif pour le distingué du # de chèque	
									dtCheckDate							DATETIME		Date du chèque
									CollegeName							VARCHAR(75)	Établissement d’enseignement.
									ProgramDesc							VARCHAR(75)	Programme
									ProgramLength						INTEGER		Durée du programme.
									StudyStart							DATETIME		Date de début du programme.
									ProgramYear							INTEGER		Année du programme.
									ProgrammeEtudeDateDebutAnneeScolaire DATETIME	Date de début des études de la demande de PAE
									ProgrammeEtudeDureeProgrammeEnAnnees	INTEGER Durée du programme de la demande de PAE
									ProgrammeEtudeNumeroAnneeCourante	INTEGER	L’année du programme de la demande de PAE
									TreizeSemainesEtudesCompletees	INTEGER		0 = non, 1 = oui
Note                :				2005-07-06	Simon Tanguay		Création		JIRA CRIT-1146 Afficher l'historique des PAE dans l'onglet «PAE» de la convention
									2005-07-07	Simon Tanguay/Guehel Bouanga		Correction de la Frequentation
									2017-12-11	JP Simard			Modification	CRIT-1466 Afficher la réussite académique dans l'historique des PAE (convention et bénéficiaire)
									2017-12-11  Stephane Roussel					CRIT-1147 Afficher les détails et la ventilation pour chaque paiement du PAE
									2017-12-14	Simon Tanguay						JIRA CRIT-956 Otpimisatio de la requête (OUTER APPLY dbo.fntOPER_ObtenirEtatDDD(d.id, GETDATE()) OE )
                                    2017-12-14  Pierre-Luc Simard                   Changer la subvention supplémentaire pour SBS au lieu de IS+
                                    2017-12-14  Pierre-Luc Simard                   EligibilityConditionID du paiement au lieu du collège
                                    2017-12-18  Maxime Martel                       Ajout du planId
									2017-12-18  Martin Cyr							Ajout de la date avec les heures (dtSequence_Operation)
									2017-12-19  Martin Cyr							Retourne null dans le cas d'un destinataire inconnu
									2017-12-20  Martin Cyr							Prendre la date du chèque dans CHQ_CheckHistory
                                    2018-01-08  Pierre-Luc Simard                   Retourne les bourses uniquement du bénéficiaire sélectionné lors d'un changement de bénéficiaire
									2018-01-08  Simon Tanguay						CRIT-1842: Lorsqu'une opération est annulé, l'opération de destination doit affiché les détails de la demandePAE associé à la source
									2018-01-08  Simon Tanguay						CRIT-1902: Afficher les détails de chèque ou DDD pour les opérations d'anulation s'il y a.
									2018-01-08  Simon Tanguay						CRIT-1902: Ajout de EstOperationAnnule pour indiqué les opérations qui sont annulées.
									2018-01-18  Guehel Bouanga						CRIT-1972: Afficher le nom et le ID du bénéficiaire dans l'historique de l'onglet PAE de la convention.
									2018-06-26	Maxime Martel						PROD-10236: Paiement chèque non annulé cause montant en double si on ne regroupe pas

Exemple d'appel:    EXEC psCONV_ObtenirDetailsHistoriquePAE 159958, NULL 
                    EXEC psCONV_ObtenirDetailsHistoriquePAE NULL, 272714

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirDetailsHistoriquePAE] (
	@ConventionID INTEGER,
	@BeneficiaryID INTEGER ) -- ID Unique de la convention.
AS
BEGIN
	DECLARE @tScholarshipAmount TABLE  (
		ScholarshipPmtDtlID INTEGER IDENTITY(1,1) PRIMARY KEY,
		ScholarshipPmtDtlCodeID INTEGER,
		ScholarshipPmtID INTEGER,
		ScholarshipPmtDtlOperTypeID CHAR(3),
		ScholarshipPmtDtlAmount MONEY )


	DECLARE @tScholarshipPmtDtl_CESP TABLE (
		iCESPID INTEGER PRIMARY KEY,
		OperID INTEGER NOT NULL,
		ScholarshipPmtID INTEGER NOT NULL,
		fCESG MONEY NOT NULL,
		fACESG MONEY NOT NULL,
		fCLB MONEY NOT NULL )

	DECLARE @tScholarship TABLE (
        ScholarshipID INT,
        BeneficiaryID INT,
		ConventionID INT,
		ConventionNo VARCHAR(15),
        PlanId INT, 
		NomPrenomBeneficiaireOriginal  VARCHAR(50))

	IF (@ConventionID IS NOT NULL)
	    INSERT INTO @tScholarship
	    SELECT 
            S.ScholarshipID,
            BeneficiaryID = ISNULL(S.iIDBeneficiaire, C.BeneficiaryID),
            C.ConventionID, 
            C.ConventionNo, 
            C.PlanID, 
			NomPrenomBeneficiaireOriginal = H.LastName + ', ' + H.FirstName
		FROM Un_Scholarship S 
        JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
		JOIN Mo_Human H ON H.HumanID = S.iIDBeneficiaire
		WHERE S.ConventionID = @ConventionID
	ELSE IF (@BeneficiaryID IS NOT NULL)
		INSERT INTO @tScholarship
		SELECT 
            S.ScholarshipID,
            BeneficiaryID = ISNULL(S.iIDBeneficiaire, C.BeneficiaryID),
            C.ConventionID, 
            C.ConventionNo, 
            C.PlanID, 
			NomPrenomBeneficiaireOriginal = H.LastName + ', ' + H.FirstName
		FROM Un_Scholarship S 
        JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
		JOIN Mo_Human H ON H.HumanID = C.BeneficiaryID
		WHERE (S.iIDBeneficiaire = @BeneficiaryID
            OR (ISNULL(S.iIDBeneficiaire, 0) = 0 AND C.BeneficiaryID = @BeneficiaryID)) 	

	IF EXISTS (
		SELECT 1
		FROM @tScholarship 
		)
	BEGIN
		INSERT INTO @tScholarshipAmount (
				ScholarshipPmtDtlCodeID,
				ScholarshipPmtID,
				ScholarshipPmtDtlOperTypeID,
				ScholarshipPmtDtlAmount )
			SELECT 
				ScholarshipPmtDtlCodeID = C.ConventionOperID,
				P.ScholarshipPmtID,
				ScholarshipPmtDtlOperTypeID = C.ConventionOperTypeID,
				ScholarshipPmtDtlAmount = C.ConventionOperAmount 
			FROM @tScholarship S 
			JOIN Un_ScholarshipPmt P ON P.ScholarshipID = S.ScholarshipID
			JOIN Un_ConventionOper C ON C.OperID = P.OperID
		    WHERE C.ConventionOperAmount <> 0

		INSERT INTO @tScholarshipPmtDtl_CESP (
				iCESPID,
				OperID,
				ScholarshipPmtID,
				fCESG,
				fACESG,
				fCLB )
			SELECT 
				MAX(G.iCESPID),
				G.OperID,
				P.ScholarshipPmtID,
				SUM(G.fCESG),
				SUM(G.fACESG),
				SUM(G.fCLB) 
			FROM @tScholarship S 
			JOIN Un_ScholarshipPmt P ON P.ScholarshipID = S.ScholarshipID
			JOIN Un_CESP G ON G.OperID = P.OperID			
			GROUP BY 
				G.OperID,
				P.ScholarshipPmtID

		INSERT INTO @tScholarshipAmount (
				ScholarshipPmtDtlCodeID,
				ScholarshipPmtID,
				ScholarshipPmtDtlOperTypeID,
				ScholarshipPmtDtlAmount )
			SELECT 
				ScholarshipPmtDtlCodeID = iCESPID,
				ScholarshipPmtID,
				ScholarshipPmtDtlOperTypeID = 'SUB',
				ScholarshipPmtDtlAmount = fCESG 
			FROM @tScholarshipPmtDtl_CESP
			WHERE fCESG <> 0

		INSERT INTO @tScholarshipAmount (
				ScholarshipPmtDtlCodeID,
				ScholarshipPmtID,
				ScholarshipPmtDtlOperTypeID,
				ScholarshipPmtDtlAmount )
			SELECT 
				ScholarshipPmtDtlCodeID = iCESPID,
				ScholarshipPmtID,
				ScholarshipPmtDtlOperTypeID = 'SBS',
				ScholarshipPmtDtlAmount = fACESG 
			FROM @tScholarshipPmtDtl_CESP
			WHERE fACESG <> 0

		INSERT INTO @tScholarshipAmount (
				ScholarshipPmtDtlCodeID,
				ScholarshipPmtID,
				ScholarshipPmtDtlOperTypeID,
				ScholarshipPmtDtlAmount )
			SELECT 
				ScholarshipPmtDtlCodeID = iCESPID,
				ScholarshipPmtID,
				ScholarshipPmtDtlOperTypeID = 'BEC',
				ScholarshipPmtDtlAmount = fCLB 
			FROM @tScholarshipPmtDtl_CESP
			WHERE fCLB <> 0

		INSERT INTO @tScholarshipAmount (
				ScholarshipPmtDtlCodeID,
				ScholarshipPmtID,
				ScholarshipPmtDtlOperTypeID,
				ScholarshipPmtDtlAmount )
			SELECT 
				ScholarshipPmtDtlCodeID = PO.PlanOperID,
				P.ScholarshipPmtID,
				ScholarshipPmtDtlOperTypeID = PO.PlanOperTypeID,
				ScholarshipPmtDtlAmount = PO.PlanOperAmount
			FROM @tScholarship S 
            JOIN Un_ScholarshipPmt P ON P.ScholarshipID = S.ScholarshipID
			JOIN Un_PlanOper PO ON PO.OperID = P.OperID
			WHERE PO.PlanOperAmount <> 0
	END

	SELECT DISTINCT
		S.ScholarshipID, -- ID unique de la bourse.
		S.ConventionID, -- ID unique de la convention.
		TS.ConventionNo,
        TS.PlanId,
        TS.BeneficiaryID,
		TS.NomPrenomBeneficiaireOriginal,
		S.ScholarshipNo, -- Numéro du PAE
		fPaymentAmount = ISNULL(Ch.fAmount,ISNULL(DDD.Montant, 0)), -- Montant du chèque.
		MontantDemandePAE = DP.MontantPAEDemande,
		O.OperDate, -- Date d’opération.
		O.dtSequence_Operation, -- Date d’opération.
		ModePaiement = CASE WHEN CH.iCheckID IS NOT NULL THEN 'CHQ' 
							WHEN ddd.Id is NOT NULL THEN 'DDD' 
							ELSE 'INC' END,
		S.ScholarshipStatusID, -- Chaîne de 3 caractères qui donne l'état de la bourse ('RES'=En réserve, 'PAD'=Payée, 'ADM'=Admissible, 'WAI'=En attente, 'TPA'=À payer, 'DEA'=Décès, 'REN'=Renonciation, '25Y'=25 ans de régime, '24Y'=24 ans d'âge).
		SP.ScholarshipPmtID, -- ID unique du paiement de bourse.
		O.OperID, -- ID unique de l’opération qui a effectué le paiement.
		O.OperTypeID, -- Code de 3 caractères du type d’opération.

		iOperationID = CASE WHEN Ch.OperID IS NOT NULL OR ddd.IdOperationFinanciere IS NOT NULL THEN O.OperID ELSE null END,--ISNULL(L.iOperationID,ISNULL(DDD.ID,0)),
		iPaymentID = ISNULL(Ch.iCheckID, DDD.ID), -- ID unique du chèque ou DDD faisant le paiement s’il y en a un.
		iPaymentNumber = ISNULL(Ch.iCheckNumber, DDD.ID), -- Numéro du chèque ou de DDD.
		DatePaiement = CASE WHEN CH.iCheckID IS NOT NULL THEN Ch.dtHistory 
							WHEN ddd.Id is NOT NULL THEN DDD.DateEtat
							ELSE NULL END, 
		DateDecaissementDDD = DDD.DateDecaissement,
		--SP.CollegeID, -- ID unique de l’établissement d’enseignement.
		CollegeName = ISNULL(CCo.CompanyName,''), -- Établissement d’enseignement.
		--SP.ProgramID, -- ID unique du programme.
		CH.iCheckStatusID,
		P.ProgramDesc, -- Programme
		SP.StudyStart, -- Date de début du programme.
		SP.ProgramLength, -- Durée du programme.
		SP.ProgramYear, -- Année du programme.	
		DDD.InformationBancaireNumeroCompte,
		DestinatairePaiement = CASE WHEN CH.iCheckID IS NOT NULL THEN LTRIM(CH.vcFirstName + ' ') + CH.vcLastName
									WHEN ddd.Id is NOT NULL THEN DDD.FirstName + ' ' + DDD.LastName
									ELSE NULL END,
		StatusPaiementFR = CASE WHEN CH.iCheckID IS NOT NULL THEN CH.vcStatusDescription
								WHEN ddd.Id is NOT NULL THEN DDD.Etat 
								ELSE 'INCONNU' END,							
		StatusPaiementEN = CASE WHEN CH.iCheckID IS NOT NULL THEN CH.vcStatusDescriptionEN
								WHEN ddd.Id is NOT NULL THEN DDD.EtatEN 
								ELSE 'UNKNOWN' END,
		Frequentation = CASE WHEN DP.BeneficiaireEtudieATempsPlein = 1 AND DP.BeneficiaireEtudieATempsPartiel = 0 THEN
						'PLEIN'
						WHEN DP.BeneficiaireEtudieATempsPlein = 0 AND DP.BeneficiaireEtudieATempsPartiel = 1 THEN
						'PARTIEL'
						ELSE
						'INCONNU'
						END,

		--Co.EligibilityConditionID, -- Condition d’admissibilité à la bourse. (Selon l'établissement d'enseignement)
        SP.EligibilityConditionID, -- Condition d’admissibilité à la bourse. (Selon la valeur enregistrée dans le paiement)
		SP.EligibilityQty, -- Quantité nécessaire à l’admissibilité.
		--SPD.ScholarshipPmtDtlID, -- ID du détail du paiement. (Peut correspondre à un ConventionOperID, iCESPID ou un PlanOperID)
		SPD.ScholarshipPmtDtlOperTypeID, -- Chaîne de 3 caractères indiquant le type de détail.
		ScholarshipPmtDtlAmount = -SPD.ScholarshipPmtDtlAmount, -- Montant du détail.
		DP.ProgrammeEtudeDateDebutAnneeScolaire,
		DP.ProgrammeEtudeDureeProgrammeEnAnnees,
		DP.ProgrammeEtudeNumeroAnneeCourante,		
		DP.TreizeSemainesEtudesCompletees,
		EstOperationAnnule = CASE WHEN (UOC.OperSourceID IS NOT NULL) OR (UOC2.OperSourceID IS NOT NULL) THEN 1 ELSE 0 END, 
		IdBeneficiaireOriginal = DP.IdBeneficiaire
	FROM Un_Scholarship S
    JOIN @tScholarship TS ON TS.ScholarshipID = S.ScholarshipID
	LEFT JOIN Un_ScholarshipPmt SP ON SP.ScholarshipID = S.ScholarshipID
	LEFT JOIN Un_Oper O ON O.OperID = SP.OperID
	LEFT JOIN dbo.Un_OperCancelation UOC ON UOC.OperID = O.OperID  --Si c'est la destination d'une operation de cancellation, on va chercher la source pour pouvoir afficher la demandePAE et le cheque s'il existe.
	-- Va chercher les informations des chèques
	LEFT JOIN (
		SELECT
			L.OperID,
			C.iCheckID,
			C.iCheckNumber,
			C.dtEmission,
			C.fAmount,
			C.iCheckStatusID,
			C.vcFirstName,
			C.vcLastName,
			CS.vcStatusDescription,
			CS.vcStatusDescriptionEN, 
			dtHistory= (SELECT MAX(CHist.dtHistory) FROM CHQ_CheckHistory CHist WHERE CHist.iCheckID = C.iCheckID AND CHist.iCheckStatusID = C.iCheckStatusID)
		FROM @tScholarship S
		JOIN Un_ScholarshipPmt SP ON SP.ScholarshipID = S.ScholarshipID
		JOIN Un_OperLinkToCHQOperation L ON SP.OperID = L.OperID
		JOIN CHQ_OperationDetail OD ON OD.iOperationID = L.iOperationID
		JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
		JOIN CHQ_Check C ON C.iCheckID = COD.iCheckID
		JOIN CHQ_CheckStatus CS ON CS.iCheckStatusID = C.iCheckStatusID			
		--JOIN CHQ_CheckHistory CHist ON CHist.iCheckStatusID = C.iCheckStatusID and CHist.iCheckID = C.iCheckID
		--group by L.OperID,
		--	C.iCheckID,
		--	C.iCheckNumber,
		--	C.dtEmission,
		--	C.fAmount,
		--	C.iCheckStatusID,
		--	C.vcFirstName,
		--	C.vcLastName,
		--	CS.vcStatusDescription,
		--	CS.vcStatusDescriptionEN
		) Ch ON Ch.OperID = ISNULL(UOC.OperSourceID, O.OperID)
	--LEFT JOIN Un_OperLinkToCHQOperation L ON O.OperID = L.OperID
	LEFT JOIN Un_Program P ON P.ProgramID = SP.ProgramID
	LEFT JOIN Un_College Co ON Co.CollegeID = SP.CollegeID
	LEFT JOIN Mo_Company CCo ON CCo.CompanyID = Co.CollegeID
	LEFT JOIN @tScholarshipAmount SPD ON SPD.ScholarshipPmtID = SP.ScholarshipPmtID
	LEFT JOIN (
		SELECT d.id, d.IdOperationFinanciere, d.Montant, d.InformationBancaireNumeroCompte, d.DateDecaissement, H.FirstName, H.LastName , OE.DateEtat, OE.EtatEN, OE.Etat
		FROM DecaissementDepotDirect d
		JOIN mo_Human H ON H.HumanID = d.IdDestinataire
		OUTER APPLY dbo.fntOPER_ObtenirEtatDDD(d.id, GETDATE()) OE 
		)ddd ON ddd.IdOperationFinanciere = ISNULL(UOC.OperSourceID, O.OperID)
    LEFT JOIN dbo.DemandePAE DP ON DP.IdOperationFinanciere = ISNULL(UOC.OperSourceID, O.OperID)
	LEFT JOIN dbo.Un_OperCancelation UOC2 ON UOC2.OperSourceID = O.OperID --Utiliser pour retourner EstOperationAnnule
	WHERE (Ch.OperID IS NULL
			OR (Ch.OperID IS NOT NULL AND Ch.iCheckID IS NOT NULL))

END