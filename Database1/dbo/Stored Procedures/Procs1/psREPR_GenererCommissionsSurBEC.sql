/************************************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc
Code du service:	psREPR_GenererCommissionsSurActif
Nom du service:		Générer les commissions sur le BEC
But:				Calculer les commissions sur le BEC, pour les groupes d'unités admissibles, à une date donnée.
Facette:			REPR

Paramètres d’entrée	:	Paramètre						Description
									--------------------------	-----------------------------------------------------------------
		  							dDateCalcul					Date du calcul (Normalement le premier du mois)
									
Exemple d’appel:	
					EXEC psREPR_GenererCommissionsSurBEC '2018-11-30' -- delete from tblREPR_CommissionsBEC
					UPDATE tblREPR_CommissionsBEC set RepTreatmentID = 844 where RepTreatmentID is null
Paramètres de sortie:		Table						Champ							Description
		  					-------------------------	--------------------------- 	---------------------------------
							S/O							iCode_Retour					Code de retour standard

Historique des modifications:
						2018-11-06	Donald Huppé			Création du service
						2018-12-07	Donald Huppé			Exclure Siège social
************************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_GenererCommissionsSurBEC] (
    @dDateCalcul DATE)
AS
BEGIN

    DECLARE
        @iResult INTEGER,
        @dtSignature DATETIME,
		@mMontant_Boni_Directeur MONEY,
		@mMontant_Boni_Representant MONEY,
		@iDelai_Encaisse_BEC INT,
		@iDelai_Interdiction_COL INT

    SET @iResult = 1
	-- Le boni des directeurs 20$ séparé entre eux au prorata de leur %
    SET @mMontant_Boni_Directeur = CONVERT(FLOAT, dbo.fnGENE_ObtenirParametre('REPR_BONI_BEC_DIR', @dDateCalcul, NULL, NULL, NULL, NULL, NULL))
	-- Le boni du rep = 80 $
    SET @mMontant_Boni_Representant = CONVERT(FLOAT, dbo.fnGENE_ObtenirParametre('REPR_BONI_BEC_REP', @dDateCalcul, NULL, NULL, NULL, NULL, NULL))
	-- La Date (2018-09-10) à partir de laquelle on considère les contrat signée qui sont commissioné
    SET @dtSignature =	dbo.fnGENE_ObtenirParametre('REPR_BONI_BEC_DATE_SIGNATURE', @dDateCalcul, NULL, NULL, NULL, NULL, NULL)
	-- La période (90 jours) précédent la date de calcul dans laquelle on recherche des encaissement de BEC
	SET @iDelai_Encaisse_BEC = CONVERT(FLOAT, dbo.fnGENE_ObtenirParametre('REPR_BONI_BEC_PERIODE_PREC_ENCAISS_BEC', @dDateCalcul, NULL, NULL, NULL, NULL, NULL))
 
	SET @iDelai_Interdiction_COL = CONVERT(FLOAT, dbo.fnGENE_ObtenirParametre('REPR_BONI_BEC_PERIODE_INTERDICTION_COL', @dDateCalcul, NULL, NULL, NULL, NULL, NULL))

 --   SELECT @mMontant_Boni_Directeur
 --   SELECT @mMontant_Boni_Representant
 --   SELECT @dtSignature
	--SELECT @iDelai_Encaisse_BEC
	--SELECT @iDelai_Interdiction_COL

	SELECT DISTINCT
		U.UnitID,
		C.ConventionID,
		U.RepID,
		C.BeneficiaryID,
		U.SignatureDate,
		C.ConventionNo,
		O.OperDate
	INTO #IBEC
	FROM Un_CESP CE
	JOIN Un_Convention C on c.ConventionID = CE.ConventionID
	JOIN Un_Unit U ON U.ConventionID = C.ConventionID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	JOIN Un_Oper O on O.OperID = ce.OperID
	LEFT JOIN (
		-- état des convention par plage de date
		SELECT 
			C.BeneficiaryID,
			c.ConventionNo,
			W.ConventionID,
			W.ConventionConventionStateID,
			cs.ConventionStateID,
			W.StartDate,
			EndDate = ISNULL(MIN(W.EndDate),'9999-12-31')
		FROM (
			SELECT csDebut.ConventionConventionStateID, csDebut.ConventionID, csDebut.StartDate, EndDate = csFin.StartDate
			FROM un_conventionconventionstate csDebut
			LEFT JOIN un_conventionconventionstate csFin ON 
						csFin.ConventionID = csDebut.ConventionID
						AND csFin.StartDate >= csDebut.StartDate
						AND csFin.ConventionConventionStateID > csDebut.ConventionConventionStateID
			) W
			JOIN Un_Convention c ON c.ConventionID = w.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN un_conventionconventionstate cs ON w.ConventionConventionStateID = cs.ConventionConventionStateID
		WHERE P.PlanTypeID = 'COL'
		GROUP BY
			C.BeneficiaryID,
			C.ConventionNo,
			W.ConventionID,
			W.ConventionConventionStateID,
			cs.ConventionStateID,
			W.StartDate
		)H ON 
			H.BeneficiaryID = C.BeneficiaryID 
			AND H.ConventionStateID IN ('TRA','REE')
			AND (
				-- contrat COL pendant la signature du IBEC
				U.SignatureDate BETWEEN H.StartDate AND H.EndDate
				OR
				-- CONTRAT DEVENU REE DANS LES 90 JOURS SUIVANT LA SIGNATURE DU IBEC
				H.StartDate BETWEEN U.SignatureDate AND DATEADD(DAY,@iDelai_Interdiction_COL/*90*/,U.SignatureDate)
				)
	LEFT JOIN tblREPR_CommissionsBEC CB ON CB.BeneficiaryID = C.BeneficiaryID -- Historique des bénéficiaires ayant déjà eu un contrat commissioné
	WHERE 1=1
		AND U.SignatureDate >= @dtSignature --'2018-09-10'
		AND O.OperDate >= DATEADD(DAY,- @iDelai_Encaisse_BEC,@dDateCalcul) --Les réceptions de BEC depuis 90 jours
		AND fCLBFee = 25 -- c'est l'encaissement du frais de 25$ qui est le déclencheur de la commission
		AND o.OperTypeID = 'SUB'
		AND P.PlanTypeID = 'IND'
		AND H.BeneficiaryID IS NULL -- n'a pas un contrat collectif actif lors de la signature (1) du I-BEC 
		AND CB.BeneficiaryID IS NULL -- Ce bénéficiaires n'a jamais eu un contrat commissioné
		AND U.RepID <> 149876 -- Exclure siège social
	ORDER BY O.OperDate
 

 --RETURN
	SELECT 
		dDate_Calcul,
		RepID,
		RepRoleID,
		UnitID, -- On conserve le UnitID car il contient le RepID qui sera commisssionné.  Dans un IND, le conventionID aura été suffisant car un seul gr. d'unité. Anyway, le unitID permet de remonter au ConventionID
		BeneficiaryID,
		mMontant_ComBEC
	INTO #COM
	FROM (
		-- COMMISSION DU REPRÉSENTANT
		SELECT 
			dDate_Calcul = @dDateCalcul,
			RepID = R.RepID,
			RepRoleID = 'REP',
			UnitID = B.UnitID,
			B.BeneficiaryID,
			mMontant_ComBEC = @mMontant_Boni_Representant
		FROM #IBEC B
		JOIN Un_Rep R ON R.RepID = B.RepID
		WHERE ISNULL(R.BusinessEnd,'9999-12-31') > @dDateCalcul -- Le rep est actif

		UNION ALL

		-- COMMISSION DU DIRECTEUR (DIR EN DATE DE LA SIGNATURE DU CONTRAT)
		SELECT 
			dDate_Calcul = @dDateCalcul,
			RepID = R.RepID,
			RepRoleID = 'DIR',
			UnitID = B.UnitID,
			B.BeneficiaryID,
			mMontant_ComBEC = CONVERT(MONEY,@mMontant_Boni_Directeur * RB.RepBossPct / 100.0)
		FROM #IBEC B
		JOIN dbo.Un_RepBossHist RB ON RB.RepID = B.RepID
		JOIN Un_Rep R ON R.RepID = RB.BossID
		WHERE RB.RepRoleID = 'DIR'
			AND StartDate IS NOT NULL
			AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, B.SignatureDate, 120), 10)
			AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, B.SignatureDate, 120), 10))
			AND ISNULL(R.BusinessEnd,'9999-12-31') > @dDateCalcul -- Le directeur est actif, peu importe si le rep est actif ou non
		)V
	ORDER BY V.UnitID, mMontant_ComBEC DESC

	SELECT * FROM #COM

	IF EXISTS (SELECT 1 FROM #COM)

	BEGIN

		------------------------
		BEGIN TRANSACTION
		------------------------

			INSERT INTO tblREPR_CommissionsBEC(
				dDate_Calcul,
				RepID,
				RepRoleID,
				UnitID,
				BeneficiaryID,
				mMontant_ComBEC)
			SELECT 
				dDate_Calcul,
				RepID,
				RepRoleID,
				UnitID,
				BeneficiaryID,
				mMontant_ComBEC		 
			FROM #COM

		IF @@ERROR <> 0
			SET @iResult = -1

		IF @iResult > 0
			------------------
			COMMIT TRANSACTION
			------------------
		ELSE
			--------------------
			ROLLBACK TRANSACTION
			--------------------
	END

	RETURN @iResult

END


