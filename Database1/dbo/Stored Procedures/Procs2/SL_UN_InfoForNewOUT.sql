/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_InfoForNewOUT
Description         :	Retourne les informations nécessaires pour un nouveau transfert OUT
Valeurs de retours  :	Dataset contenant les données
Note                :	ADX0000568	IA	2005-01-31	Bruno Lapointe			Création
								ADX0001324	BR	2005-03-09	Bruno Lapointe			La procédure de tenait pas conte de la date de résiliation.
								ADX0001354	BR	2005-03-23	Bruno Lapointe			Ajout champ de retour IntSubs
								ADX0000992	IA	2006-05-19	Alain Quirion			Ajout des champs :	
																fIntCESPTIN	MONEY	Intérêt sur PCEE provenant d’un TIN
																fCLB	MONEY	Bon d’étude canadien
																fIntBEC	MONEY	Intérêt sur le bon d’étude canadien.
																fACESG	MONEY	Subvention supplémentaire (SCEE+)
																fIntACESG	MONEY	Intérêt sur la subvention supplémentaire 
																fNoCESGCotBefore98	MONEY	Montant de cotisation non subventionné avant 1998
																fNoCESGCot98AndAfter	MONEY	Montant de cotisation non subventionné en 1998 et après
																fCESGCot	MONEY	Montant de cotisation subventionné.
																fYearBnfCot	MONEY	Montant de cotisation versée cette année par bénéficiaire.
																fBnfCot	MONEY	Montant de cotisation versée par bénéficiaire.
															Suppresion du champ :	IntCESGTIN
															Modification du nom de la procédure stockée
								ADX0002294	BR	2007-02-22	Bruno Lapointe			ne gérait pas la somme null du champ fCotisationGranted de la table CESP400
								ADX0002426	BR	2007-05-23	Bruno Lapointe		Gestion de la table Un_CESP.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_InfoForNewOUT] (
	@UnitID INTEGER, 		-- ID unique du groupe d'unités
	@ReductionDate DATETIME, 	-- Date de réduction
	@RESType INTEGER) 		-- 0 = Remb. frais et ass, 1 = Remb. frais, 2 = Remb. épargne seulement
AS
BEGIN
	DECLARE
		@iReturn INTEGER,
		@iNbDeposit INTEGER,
		@iConventionID INTEGER,
		@fIntSubs MONEY,
		@fIntTIN MONEY,
		@fCESG MONEY,
		@fIntCESG MONEY,		
		@fIntCESPTIN MONEY,		--Intérêt sur PCEE provenant d’un TIN (anciennement @fIntCESGTIN MONEY)
		@fCLB MONEY,			--Bon d’étude canadien
		@fIntBEC MONEY,			--Intérêt sur le bon d’étude canadien.
		@fACESG MONEY,			--Subvention supplémentaire (SCEE+)
		@fIntACESG MONEY,		--Intérêt sur la subvention supplémentaire 
		@fNoCESGCotBefore98 MONEY,	--Montant de cotisation non subventionné avant 1998
		@fNoCESGCot98AndAfter MONEY,	--Montant de cotisation non subventionné en 1998 et après
		@fCESGCot MONEY,		--Montant de cotisation subventionné.
		@fYearBnfCot MONEY,		--Montant de cotisation versée cette année par bénéficiaire.
		@fBnfCot MONEY,			--Montant de cotisation versée par bénéficiaire.
		@bACESGPaid BIT
		
	SET @iReturn = 1

	SELECT 
		@iNbDeposit = dbo.fn_Un_EstimatedNumberOfDepositSinceBeginning(@ReductionDate, DAY(C.FirstPmtDate), M.PmtByYearID, M.PmtQty, U.InForceDate),
		@iConventionID = U.ConventionID
	FROM dbo.Un_Unit U
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	WHERE U.UnitID = @UnitID

	SELECT @fIntSubs = SUM(ConventionOperAmount)
	FROM Un_ConventionOper CO
	JOIN Un_Oper O ON O.OperID = CO.OperID
	WHERE CO.ConventionID = @iConventionID
		AND O.OperDate <= @ReductionDate
		AND CO.ConventionOperTypeID = 'INM'

	SELECT @fIntTIN = SUM(ConventionOperAmount)
	FROM Un_ConventionOper CO
	JOIN Un_Oper O ON O.OperID = CO.OperID
	WHERE CO.ConventionID = @iConventionID
		AND O.OperDate <= @ReductionDate
		AND CO.ConventionOperTypeID = 'ITR'

	SELECT @fIntCESG = SUM(ConventionOperAmount)
	FROM Un_ConventionOper CO
	JOIN Un_Oper O ON O.OperID = CO.OperID
	WHERE CO.ConventionID = @iConventionID
		AND O.OperDate <= @ReductionDate
		AND CO.ConventionOperTypeID = 'INS'

	SELECT @fIntCESPTIN = SUM(ConventionOperAmount)
	FROM Un_ConventionOper CO
	JOIN Un_Oper O ON O.OperID = CO.OperID
	WHERE CO.ConventionID = @iConventionID
		AND O.OperDate <= @ReductionDate
		AND CO.ConventionOperTypeID = 'IST'

	--Intérêt BEC
	SELECT @fIntBEC = SUM(ConventionOperAmount)
	FROM Un_ConventionOper CO
	JOIN Un_Oper O ON O.OperID = CO.OperID
	WHERE CO.ConventionID = @iConventionID
		AND O.OperDate <= @ReductionDate
		AND CO.ConventionOperTypeID = 'IBC'

	--Intérêt SCEE+
	SELECT @fIntACESG = SUM(ConventionOperAmount)
	FROM Un_ConventionOper CO
	JOIN Un_Oper O ON O.OperID = CO.OperID
	WHERE CO.ConventionID = @iConventionID
		AND O.OperDate <= @ReductionDate
		AND CO.ConventionOperTypeID = 'IS+'

	--SCEE, SCEE+ et BEC
	SELECT 
		@fCESG = SUM(fCESG),
		@fACESG = SUM(fACESG),
		@fCLB = SUM(fCLB),
		@fCESGCot = SUM(CE.fCotisationGranted)
	FROM Un_CESP CE
	JOIN Un_Oper O ON O.OperID = CE.OperID
	WHERE CE.ConventionID = @iConventionID
		AND O.OperDate <= @ReductionDate

	-- Cotisation subventionné de l'enregistrement 400
	SELECT
		@fCESGCot = @fCESGCot + ISNULL(SUM(C4.fCotisationGranted),0)
	FROM Un_CESP400 C4
	WHERE C4.ConventionID = @iConventionID
		AND C4.iCESPSendFileID IS NULL

	--Cotisation non subventionnée avant 98 (Tous non subventionnées avant 1998)
	SELECT @fNoCESGCotBefore98 = SUM(Ct.Cotisation)+SUM(Ct.Fee)		-- Somme frais + épargnes
	FROM dbo.Un_Unit U
	JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
	JOIN Un_Oper O ON O.OperID = Ct.OperID
	WHERE U.ConventionID = @iConventionID
		AND Ct.EffectDate < '1998-02-01' 

	--Cotisation non subventionnée après 98
	SELECT @fNoCESGCot98AndAfter = ISNULL(SUM(Ct.Cotisation)+SUM(Ct.Fee),0)-ISNULL(@fCESGCot,0)		-- Somme frais + épargnes
	FROM dbo.Un_Unit U
	JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
	JOIN Un_Oper O ON O.OperID = Ct.OperID
	LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
	WHERE U.ConventionID = @iConventionID
		AND Ct.EffectDate > '1998-01-31' 
		AND(	( O.OperTypeID = 'CPA' 
		 		AND OBF.OperID IS NOT NULL
				)
			OR O.OperDate <= GETDATE()
			)

	--Cotisation de l'année en cours pour le bénéficiaire
	SELECT @fYearBnfCot = SUM(Ct.Cotisation)+SUM(Ct.Fee)		-- Somme frais + épargnes
	FROM dbo.Un_Unit U
	JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
	JOIN Un_Oper O ON O.OperID = Ct.OperID
	LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
	WHERE U.ConventionID = @iConventionID
		AND YEAR(Ct.EffectDate) = YEAR(GETDATE())
		AND(	( O.OperTypeID = 'CPA' 
		 		AND OBF.OperID IS NOT NULL
				)
			OR O.OperDate <= GETDATE()
			)

	--Cotisation pour le bénéficiaire
	SELECT @fBnfCot = SUM(Ct.Cotisation)+SUM(Ct.Fee)		-- Somme frais + épargnes
	FROM dbo.Un_Unit U
	JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
	JOIN Un_Oper O ON O.OperID = Ct.OperID
	LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
	WHERE U.ConventionID = @iConventionID
		AND(	( O.OperTypeID = 'CPA' 
		 		AND OBF.OperID IS NOT NULL
				)
			OR O.OperDate <= GETDATE()
			)

	IF EXISTS (
			SELECT *
			FROM dbo.Un_Unit U
			JOIN Un_CESP CE ON CE.ConventionID = U.ConventionID
			JOIN Un_Oper O ON O.OperID = CE.OperID
			JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
			WHERE UnitID = @UnitID
				AND OT.GovernmentTransTypeID = 13 -- PAE
				AND CE.fACESG <> 0
			)
		SET @bACESGPaid = 1
	ELSE
		SET @bACESGPaid = 0

	SET @fIntSubs = ISNULL(@fIntSubs,0)
	SET @fIntTIN = ISNULL(@fIntTIN,0)
	SET @fCESG = ISNULL(@fCESG,0)
	SET @fIntCESG = ISNULL(@fIntCESG,0)
	SET @fIntCESPTIN = ISNULL(@fIntCESPTIN,0)
	SET @fCLB = ISNULL(@fCLB,0)
	SET @fIntBEC = ISNULL(@fIntBEC,0)
	SET @fACESG = ISNULL(@fACESG,0)
	SET @fIntACESG = ISNULL(@fIntACESG,0)
	SET @fNoCESGCotBefore98 = ISNULL(@fNoCESGCotBefore98,0)
	SET @fNoCESGCot98AndAfter = ISNULL(@fNoCESGCot98AndAfter,0)
	SET @fCESGCot = ISNULL(@fCESGCot,0)
	SET @fYearBnfCot = ISNULL(@fYearBnfCot,0)
	SET @fBnfCot = ISNULL(@fBnfCot,0)
	IF @fNoCESGCot98AndAfter < 0
	BEGIN
		SET @fCESGCot = @fCESGCot + @fNoCESGCot98AndAfter
		SET @fNoCESGCot98AndAfter = 0
	END

	SELECT
		U.UnitID,
		U.UnitQty,
		NbDeposit = @iNbDeposit,
		M.PmtRate,
		P.PlanTypeID,
		Cotisation = ISNULL(Ct.Cotisation,0),
		Fee = ISNULL(Ct.Fee,0),
		SubscInsur = ISNULL(Ct.SubscInsur,0),
		BenefInsur = ISNULL(Ct.BenefInsur,0),
		TaxOnInsur = ISNULL(Ct.TaxOnInsur,0),
		IntSubs = @fIntSubs,
		IntTIN = @fIntTIN,
		CESG = @fCESG,
		IntCESG = @fIntCESG,
		fIntCESPTIN = @fIntCESPTIN,
		fCLB= @fCLB,
		fIntBEC = @fIntBEC,
		fACESG = @fACESG,
		fIntACESG = @fIntACESG,
		fNoCESGCotBefore98 = @fNoCESGCotBefore98,
		fNoCESGCot98AndAfter = @fNoCESGCot98AndAfter,
		fCESGCot = @fCESGCot,
		fYearBnfCot = @fYearBnfCot,
		fBnfCot = @fBnfCot,
		bACESGPaid = @bACESGPaid
	FROM dbo.Un_Unit U
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	LEFT JOIN (
		SELECT
			Ct.UnitID,
			Cotisation = SUM(Ct.Cotisation),
			Fee = SUM(Ct.Fee),
			SubscInsur = SUM(Ct.SubscInsur),
			BenefInsur = SUM(Ct.BenefInsur),
			TaxOnInsur = SUM(Ct.TaxOnInsur)
		FROM Un_Cotisation Ct
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		WHERE O.OperDate <= @ReductionDate
			AND Ct.UnitID = @UnitID
		GROUP BY Ct.UnitID
		) Ct ON Ct.UnitID = U.UnitID
	JOIN Un_Plan P ON P.PlanID = M.PlanID
	WHERE U.UnitID = @UnitID

	IF @@ERROR<>0
		SET @iReturn = -1

	RETURN @iReturn
END


