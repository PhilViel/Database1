/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_InfoForNewTIO
Description         :	Retourne les informations nécessaires pour un nouveau transfert interne
Valeurs de retours  :	
		Dataset contenant les données :
				iSameBenef		INTEGER		Indique si le bénéficiaire est le même dans les deux conventions.
				iOUTExternalPlanID	INTEGER		ID du plan externe à mettre dans les données du formulaire du OUT.
				iTINExternalPlanID	INTEGER		ID du plan externe à mettre dans les données du formulaire du TIN.
				vcOUTOtherConventionNo 	VARCHAR(75)	Numéro de convention à mettre dans les données du formulaire du OUT.
				vcTINOtherConventionNo 	VARCHAR(75)	Numéro de convention à mettre dans les données du formulaire du TIN.
				dtTINOtherConvention 	DATETIME	Date d’entrée en vigueur à mettre dans les données du formulaire du TIN.
				bOUTEligibleForCESG	BIT		Indique si le plan du TIN est éligible à la SCEE pour les données du formulaire du OUT.
				bOUTEligibleForCLB	BIT		Indique si le plan du TIN est éligible au BEC pour les données du formulaire du OUT.
				fOUTUnitQty		FLOAT		Nombre d’unités du groupe d’unités OUT
				fTINUnitQty		FLOAT		Nombre d’unités du groupe d’unités TIN
				fTINFeeSplitByUnit	FLOAT		Quand le montant de frais cotisé par unité dépasse ce montant les cotisations sont divisé 50% en épargne et 50% en frais.
				fTINFeeByUnit		FLOAT		Montant de frais à payer par unité.
				iNbDeposit		INTEGER		Nombre de dépôt théorique entre la date d’entrée en vigueur du groupe d’unités OUT et la date de résiliation.
				fOUTPmtRate		FLOAT		Montant de cotisation par dépôt pour un groupe d’unités pour le groupe d’unités OUT.
				cOUTPlanTypeID		CHAR(3)		Type de plan de la convention OUT.
				cTINPlanTypeID		CHAR(3)		Type de plan de la convention TIN.
				fOUTCotisation		FLOAT		Solde de cotisation du groupe d’unités OUT.
				fTINCotisation		FLOAT		Solde de cotisation du groupe d’unités TIN.
				fOUTFee			FLOAT		Solde de frais du groupe d’unités OUT.
				fTINFee			FLOAT		Solde de frais du groupe d’unités TIN.
				fSubscInsur		FLOAT		Solde d’assurance souscripteur du groupe d’unités OUT.
				fBenefInsur		FLOAT		Solde d’assurance bénéficiaire du groupe d’unités OUT.
				fTaxOnInsur		FLOAT		Solde de taxes du groupe d’unités OUT.
				fINM			FLOAT		Solde d’intérêt souscrit (plan individuel) ou d’intérêt RI (plan collectif) du groupe d’unités OUT.
				fTINInt			FLOAT		Solde d’intérêt transfert IN du groupe d’unités OUT.
				fCESG			FLOAT		Solde de SCEE du groupe d’unités OUT.
				fCESGInt		FLOAT		Solde d’intérêt SCEE du groupe d’unités OUT.
				fACESG			FLOAT		Solde de SCEE+ du groupe d’unités OUT.
				fACESGInt		FLOAT		Solde d’intérêt SCEE+ du groupe d’unités OUT.
				fCLB			FLOAT		Solde de BEC du groupe d’unités OUT.
				fCLBInt			FLOAT		Solde d’intérêt BEC du groupe d’unités OUT.
				fCESPTINInt		FLOAT		Solde d’intérêt PCEE TIN du groupe d’unités OUT.
				fNoCESGCotBefore98	FLOAT		Solde de cotisations non subventionnées avant 1998 de la convention.
				fNoCESGCot98AndAfter 	FLOAT		Solde de cotisations non subventionnées 1998 et après de la convention.
				fCESGCot		FLOAT		Solde de cotisations subventionnées
				fYearBnfCot		FLOAT		Montant de cotisé pour le bénéficiaire à l’année de la date de résiliation pour cette convention (OUT).
				fBnfCot			FLOAT		Montant de cotisé pour le bénéficiaire à vie pour cette convention (OUT).
				dtLastVerif		DATETIME	Date de blocage du système.
				bACESGPaid		BIT		Indique si de la SCEE + a été versée dans cette convention. 
				dtOUTOtherConvention	DATETIME	Date d’entrée en vigueur à mettre dans les données du formulaire du OUT.
				bTINIsContestWinner		BIT		Indique si la source de vente du groupe d'unités est de type gagnant de concours

Exemple d'appel :
DECLARE @return_value INT
	EXEC	@return_value = [dbo].[SL_UN_InfoForNewTIO]
			@iOUTUnitID = 330968,
			@iTINUnitID = 333647,
			@ReductionDate = NULL,
			@RESType = 3

Note                :	
						ADX0001100	IA	2006-10-23	Alain Quirion			Création
						ADX0002294	BR	2007-02-22	Bruno Lapointe			ne gérait pas la somme null du champ fCotisationGranted de la table CESP400
						ADX0002426	BR	2007-05-23	Bruno Lapointe			Gestion de la table Un_CESP.
						ADX0001357	IA	2007-06-04	Alain Quirion			Ajout du champ bIsContestWinner
						ADX0001231	UP	2007-08-23	Alain Quirion			Le Plan Externe du OUT était utilisée pour le OUT et pour le TIN
										2009-10-29	Jean-François Gauthier	Ajout du RESType = 3
										2009-11-16	Jean-François Gauthier	Concaténation des champs pour en faire un BLOB
										2009-11-18	Jean-François Gauthier	Ajout d'un nom pour le champ de retour du BLOB (vcBlob)
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_InfoForNewTIO] (
	@iOUTUnitID INTEGER,			--ID unique du groupe d'unités du transfert OUT.
	@iTINUnitID INTEGER,			--ID unique du groupe d'unités du transfert IN.
	@ReductionDate DATETIME,		--Date de réduction
	@RESType INTEGER) 				--0 = Remb. frais et ass, 1 = Remb. frais, 2 = Remb. épargne seulement, 3 = Transfert BEC entre 2 unités
AS
BEGIN
	DECLARE
		@iReturn INTEGER,			--Valeur de retour
		@iConventionID INTEGER,			--ID de la conventin du OUT
		@iSameBenef INTEGER,			--Indique si le bénéficiaire est le même dans les deux conventions.
		@iOUTExternalPlanID INTEGER,		--ID du plan externe à mettre dans les données du formulaire du OUT.
		@iTINExternalPlanID INTEGER,		--ID du plan externe à mettre dans les données du formulaire du TIN.
		@vcOUTOtherConventionNo VARCHAR(50),	--Numéro de convention pour le OUT
		@vcTINOtherConventionNo VARCHAR(50),	--Numéro de convention pour le TIN
		@dtTINOtherConvention DATETIME,		--Date d'entrée en vigueur pour le TIN 
		@dtOUTOtherConvention DATETIME,		--Date d'entrée en vigueur pour le OUT 		
		@bOUTEligibleForCESG BIT,		--Indique si le plan du TIN est éligible à la SCEE pour les données du formulaire du OUT.
		@bOUTEligibleForCLB BIT,		--Indique si le plan du TIN est éligible au BEC pour les données du formulaire du OUT.
		@fOUTUnitQty FLOAT,			--Nombre d’unités du groupe d’unités OUT
		@fTINUnitQty FLOAT,			--Nombre d’unités du groupe d’unités TIN
		@fTINFeeSplitByUnit FLOAT,		--Quand le montant de frais cotisé par unité dépasse ce montant les cotisations sont divisé 50% en épargne et 50% en frais.
		@fTINFeeByUnit FLOAT,			--Montant de frais à payer par unité.
		@iNbDeposit INTEGER,			--Nombre de dépôt théorique entre la date d’entrée en vigueur du groupe d’unités OUT et la date de résiliation.
		@fOUTPmtRate FLOAT,			--Montant de cotisation par dépôt pour un groupe d’unités pour le groupe d’unités OUT.
		@cOUTPlanTypeID	CHAR(3),		--Type de plan de la convention OUT.
		@cTINPlanTypeID	CHAR(3),		--Type de plan de la convention TIN.
		@fOUTCotisation FLOAT,			--Solde de cotisation du groupe d’unités OUT.
		@fTINCotisation FLOAT,			--Solde de cotisation du groupe d’unités TIN.
		@fOUTFee FLOAT,				--Solde de frais du groupe d’unités OUT.
		@fTINFee FLOAT,				--Solde de frais du groupe d’unités TIN.
		@fSubscInsur FLOAT,			--Solde d’assurance souscripteur du groupe d’unités OUT.
		@fBenefInsur FLOAT,			--Solde d’assurance bénéficiaire du groupe d’unités OUT.
		@fTaxOnInsur FLOAT,			--Solde de taxes du groupe d’unités OUT.
		@fINM FLOAT,				--Solde d’intérêt souscrit (plan individuel) ou d’intérêt RI (plan collectif) du groupe d’unités OUT.
		@fTINInt FLOAT,				--Solde d’intérêt transfert IN du groupe d’unités OUT.
		@fCESG FLOAT,				--Solde de SCEE du groupe d’unités OUT.
		@fCESGInt FLOAT,			--Solde d’intérêt SCEE du groupe d’unités OUT.
		@fACESG FLOAT,				--Solde de SCEE+ du groupe d’unités OUT.
		@fACESGInt FLOAT,			--Solde d’intérêt SCEE+ du groupe d’unités OUT.
		@fCLB FLOAT,				--Solde BEC du groupe d’unités OUT.
		@fCLBInt FLOAT,				--Solde d’intérêt BEC du groupe d’unités OUT.
		@fCESPTINInt FLOAT,			--Solde d’intérêt PCEE TIN du groupe d’unités OUT.
		@fNoCESGCotBefore98 FLOAT,		--Solde de cotisations non subventionnées avant 1998 de la convention.
		@fNoCESGCot98AndAfter FLOAT,		--Solde de cotisations non subventionnées 1998 et après de la convention.
		@fCESGCot FLOAT,			--Solde de cotisations subventionnées
		@fYearBnfCot FLOAT,			--Montant de cotisé pour le bénéficiaire à l’année de la date de résiliation pour cette convention (OUT).
		@fBnfCot FLOAT,				--Montant de cotisé pour le bénéficiaire à vie pour cette convention (OUT).		
		@dtLastVerif DATETIME,			--Date de blocage du système
		@bACESGPaid BIT,			--Indique si de la SCEE + a été versée dans cette convention. 
		@bPendingApplication BIT,		--Détermine si une demande nde subvention est en cours
		@bTINIsContestWinner BIT		--Indique si le groupe d'unités du TIN a une sour ce de vente de type gagnant de concours
		
	SET @iReturn = 1

	SET @bPendingApplication = 0

	IF EXISTS (
			SELECT C4.*
			FROM Un_CESP400 C4
			JOIN dbo.Un_Convention C ON C.ConventionID = C4.ConventionID
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			WHERE C4.iCESPSendFileID IS NULL	-- Enregistrement 400 non envoyé	
				AND U.UnitID = @iTINUnitID	-- Sur le TIN
		)
		SET @bPendingApplication = 1
	
	-- Vérifie s'il s'agit du même bénéficiaire
	SELECT @iSameBenef = 	CASE ISNULL(TIN.HumanID,-1) 
					WHEN -1 THEN 0
					ELSE 1
				END
	FROM dbo.Un_Unit U1
	JOIN dbo.Un_Convention C1 ON C1.ConventionID = U1.ConventionID
	JOIN dbo.Mo_Human H1 ON H1.HumanID = C1.BeneficiaryID
	LEFT JOIN (	SELECT H2.HumanID
			FROM  Un_Unit U2
			JOIN dbo.Un_Convention C2 ON C2.ConventionID = U2.ConventionID
			JOIN dbo.Mo_Human H2 ON H2.HumanID = C2.BeneficiaryID
			WHERE U2.UnitID = @iTINUnitID) TIN ON TIN.HumanID = H1.HumanID
	WHERE U1.UnitID = @iOUTUnitID
	
	-- Recherche des informations avec le OUT (External = TIN)
	SELECT 
		@iTINExternalPlanID = E.ExternalPlanID,
		@vcTINOtherConventionNo = C.ConventionNo,
		@dtTINOtherConvention = V.InforceDate,
		@fOUTUnitQty = U.UnitQty,
		@iNbDeposit = dbo.fn_Un_EstimatedNumberOfDepositSinceBeginning(@ReductionDate, DAY(C.FirstPmtDate), M.PmtByYearID, M.PmtQty, U.InForceDate)		,
		@cOUTPlanTypeID = P.PlanTypeID,
		@iConventionID = C.ConventionID,
		@fOUTPmtRate = M.PmtRate		
	FROM dbo.Un_Unit U
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	JOIN Un_Plan P ON P.PlanID = M.PlanID
	JOIN Un_ExternalPlan E ON E.ExternalPlanGovernmentRegNo = P.PlanGovernmentRegNo	
	JOIN (
			SELECT  U1.UnitID,
					InforceDate = CASE
									WHEN MIN(U2.InforceDate) < C.dtInforceDateTIN THEN MIN(U2.InforceDate)
									ELSE C.dtInforceDateTIN
								END
			FROM dbo.Un_Unit U1
			JOIN dbo.Un_Convention C ON C.ConventionID = U1.ConventionID
			JOIN dbo.Un_Unit U2 ON U2.ConventionID = C.ConventionID
			WHERE U1.UnitID = @iOUTUnitID
			GROUP BY U1.UnitID, C.dtInforceDateTIN) V ON V.UnitID = U.UnitID
	WHERE U.UnitID = @iOUTUnitID	

	-- Recherche des informations avec le TIN (External = OUT)
	SELECT 
		@iOUTExternalPlanID = E.ExternalPlanID,
		@vcOUTOtherConventionNo = C.ConventionNo,
		@dtOUTOtherConvention = U.InForceDate, 
		@fTINUnitQty = U.UnitQty,
		@cTINPlanTypeID = P.PlanTypeID,
		@bOUTEligibleForCESG = P.bEligibleForCESG,
		@bOUTEligibleForCLB = P.bEligibleForCLB,
		@fTINFeeSplitByUnit = M.FeeSplitByUnit,
		@fTINFeeByUnit = M.FeeByUnit,
		@bTINIsContestWinner = ISNULL(SS.bIsContestWinner,0)
	FROM dbo.Un_Unit U
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	JOIN Un_Plan P ON P.PlanID = M.PlanID
	JOIN Un_ExternalPlan E ON E.ExternalPlanGovernmentRegNo = P.PlanGovernmentRegNo
	LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
	WHERE U.UnitID = @iTINUnitID	

	-- Calcul la somme des cotisations, frais, assurances souscripteur, assurance bénéficiaire et taxes sur l'assurance sur le OUT
	SELECT 
		@fOUTCotisation = SUM(ISNULL(Cotisation,0)),
		@fOUTFee = SUM(ISNULL(Fee,0)),
		@fSubscInsur = SUM(ISNULL(SubscInsur,0)),
		@fBenefInsur = SUM(ISNULL(BenefInsur,0)),
		@fTaxOnInsur = SUM(ISNULL(TaxOnInsur,0))
	FROM Un_Cotisation C
	JOIN Un_Oper O ON O.OperID = C.OperID
	WHERE O.OperDate <= @ReductionDate
		AND C.UnitID = @iOUTUnitID

	-- Calcul la somme des cotisations et frais sur le TIN
	SELECT 
		@fTINCotisation = SUM(ISNULL(Cotisation,0)),
		@fTINFee = SUM(ISNULL(Fee,0))
	FROM Un_Cotisation C
	JOIN Un_Oper O ON O.OperID = C.OperID
	WHERE O.OperDate <= @ReductionDate
		AND C.UnitID = @iTINUnitID

	--Intérêt souscrit(IND) ou intérêt RI (COL)
	SELECT @fINM = SUM(ConventionOperAmount)
	FROM Un_ConventionOper CO
	JOIN Un_Oper O ON O.OperID = CO.OperID
	WHERE CO.ConventionID = @iConventionID
		AND O.OperDate <= @ReductionDate
		AND CO.ConventionOperTypeID = 'INM'

	--Intérêt TIN
	SELECT @fTINInt = SUM(ConventionOperAmount)
	FROM Un_ConventionOper CO
	JOIN Un_Oper O ON O.OperID = CO.OperID
	WHERE CO.ConventionID = @iConventionID
		AND O.OperDate <= @ReductionDate
		AND CO.ConventionOperTypeID = 'ITR'

	--Intérêt SCEE
	SELECT @fCESGInt = SUM(ConventionOperAmount)
	FROM Un_ConventionOper CO
	JOIN Un_Oper O ON O.OperID = CO.OperID
	WHERE CO.ConventionID = @iConventionID
		AND O.OperDate <= @ReductionDate
		AND CO.ConventionOperTypeID = 'INS'

	--Intérêt PCEE TIN
	SELECT @fCESPTINInt = SUM(ConventionOperAmount)
	FROM Un_ConventionOper CO
	JOIN Un_Oper O ON O.OperID = CO.OperID
	WHERE CO.ConventionID = @iConventionID
		AND O.OperDate <= @ReductionDate
		AND CO.ConventionOperTypeID = 'IST'

	--Intérêt CLB
	SELECT @fCLBInt = SUM(ConventionOperAmount)
	FROM Un_ConventionOper CO
	JOIN Un_Oper O ON O.OperID = CO.OperID
	WHERE CO.ConventionID = @iConventionID
		AND O.OperDate <= @ReductionDate
		AND CO.ConventionOperTypeID = 'IBC'

	--Intérêt SCEE+
	SELECT @fACESGInt = SUM(ConventionOperAmount)
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
		AND O.OperDate <= @ReductionDate		

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
		AND O.OperDate <= @ReductionDate
	
	IF EXISTS (
			SELECT *
			FROM dbo.Un_Unit U
			JOIN Un_CESP CE ON CE.ConventionID = U.ConventionID
			JOIN Un_Oper O ON O.OperID = CE.OperID
			JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
			WHERE UnitID = @iOUTUnitID
				AND OT.GovernmentTransTypeID = 13 -- PAE
				AND CE.fACESG <> 0
			)
		SET @bACESGPaid = 1
	ELSE
		SET @bACESGPaid = 0

	SET @fINM = ISNULL(@fINM,0)
	SET @fTINInt = ISNULL(@fTINInt,0)
	SET @fCESG = ISNULL(@fCESG,0)
	SET @fCESGInt = ISNULL(@fCESGInt,0)
	SET @fCESPTINInt = ISNULL(@fCESPTINInt,0)
	SET @fCLB = ISNULL(@fCLB,0)
	SET @fCLBInt = ISNULL(@fCLBInt,0)
	SET @fACESG = ISNULL(@fACESG,0)
	SET @fACESGInt = ISNULL(@fACESGInt,0)
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

	-- Recherche la date de blocage
	SELECT  @dtLastVerif = LastVerifDate 		
	FROM Un_Def

	IF @RESType = 3
		BEGIN		-- Information pour le transfert BEC seulement
			SELECT 
				vcBlob = 
				ISNULL(CAST(@iSameBenef AS VARCHAR(10)), '') + ',' + 
				ISNULL(CAST(@iOUTExternalPlanID AS VARCHAR(10)), '') + ',' + 
				ISNULL(CAST(@iTINExternalPlanID AS VARCHAR(10)), '') + ',' + 
				ISNULL(@vcOUTOtherConventionNo, '') + ',' + 
				ISNULL(@vcTINOtherConventionNo, '') + ',' + 
				ISNULL(CONVERT(VARCHAR(25), @dtTINOtherConvention, 121), '') + ',' + 
				ISNULL(CAST(@bOUTEligibleForCESG AS VARCHAR(1)), '') + ',' + 
				ISNULL(CAST(@bOUTEligibleForCLB AS VARCHAR(1)), '') + ',' + 
				ISNULL(CAST(0 AS VARCHAR(1)), '') + ',' + 
				ISNULL(CAST(0 AS VARCHAR(1)), '') + ',' + 
				ISNULL(CAST(0 AS VARCHAR(1)), '') + ',' + 
				ISNULL(CAST(0 AS VARCHAR(1)), '') + ',' + 
				ISNULL(CAST(@iNbDeposit AS VARCHAR(10)), '') + ',' + 
				ISNULL(CAST(@fOUTPmtRate AS VARCHAR(10)), '') + ',' + 
				ISNULL(@cOUTPlanTypeID, '') + ',' + 
				ISNULL(@cTINPlanTypeID, '') + ',' + 	
				ISNULL(CAST(0 AS VARCHAR(1)), '') + ',' + 
				ISNULL(CAST(0 AS VARCHAR(1)), '') + ',' + 
				ISNULL(CAST(0 AS VARCHAR(1)), '') + ',' + 
				ISNULL(CAST(0 AS VARCHAR(1)), '') + ',' + 
				ISNULL(CAST(@fSubscInsur AS VARCHAR(10)), '') + ',' + 
				ISNULL(CAST(@fBenefInsur AS VARCHAR(10)), '') + ',' + 
				ISNULL(CAST(@fTaxOnInsur AS VARCHAR(10)), '') + ',' + 
				ISNULL(CAST(@fINM AS VARCHAR(10)), '') + ',' + 				
				ISNULL(CAST(0 AS VARCHAR(1)), '') + ',' + 				
				ISNULL(CAST(0 AS VARCHAR(1)), '') + ',' + 				
				ISNULL(CAST(0 AS VARCHAR(1)), '') + ',' + 			
				ISNULL(CAST(0 AS VARCHAR(1)), '') + ',' + 				
				ISNULL(CAST(0 AS VARCHAR(1)), '') + ',' + 			
				ISNULL(CAST(@fCLB AS VARCHAR(10)), '') + ',' + 				
				ISNULL(CAST(@fCLBInt AS VARCHAR(10)), '') + ',' + 				
				ISNULL(CAST(@fCESPTINInt AS VARCHAR(10)), '') + ',' + 			
				ISNULL(CAST(@fNoCESGCotBefore98 AS VARCHAR(10)), '') + ',' + 		
				ISNULL(CAST(@fNoCESGCot98AndAfter AS VARCHAR(10)), '') + ',' + 		
				ISNULL(CAST(0 AS VARCHAR(1)), '') + ',' + 			
				ISNULL(CAST(@fYearBnfCot AS VARCHAR(10)), '') + ',' + 			
				ISNULL(CAST(0 AS VARCHAR(1)), '') + ',' + 					
				ISNULL(CONVERT(VARCHAR(25), @dtLastVerif, 121), '') + ',' + 			
				ISNULL(CAST(@bACESGPaid AS VARCHAR(1)), '') + ',' + 
				ISNULL(CONVERT(VARCHAR(25), @dtOUTOtherConvention, 121), '') + ',' + 
				ISNULL(CAST(@bPendingApplication AS VARCHAR(1)), '') + ',' + 	
				ISNULL(CAST(@bTINIsContestWinner AS VARCHAR(1)), '') + CHAR(13) + CHAR(10)
		END
	ELSE
		BEGIN	-- Information pour le transfert complet
			SELECT
				iSameBenef				= @iSameBenef,
				iOUTExternalPlanID		= @iOUTExternalPlanID,
				iTINExternalPlanID		= @iTINExternalPlanID,
				vcOUTOtherConventionNo	= @vcOUTOtherConventionNo,
				vcTINOtherConventionNo	= @vcTINOtherConventionNo,
				dtTINOtherConvention	= @dtTINOtherConvention,
				bOUTEligibleForCESG		= @bOUTEligibleForCESG,
				bOUTEligibleForCLB		= @bOUTEligibleForCLB,
				fOUTUnitQty				= @fOUTUnitQty,
				fTINUnitQty				= @fTINUnitQty,
				fTINFeeSplitByUnit		= @fTINFeeSplitByUnit,
				fTINFeeByUnit			= @fTINFeeByUnit,
				iNbDeposit				= @iNbDeposit,
				fOUTPmtRate				= @fOUTPmtRate,
				cOUTPlanTypeID			= @cOUTPlanTypeID,
				cTINPlanTypeID			= @cTINPlanTypeID,	
				fOUTCotisation			= @fOUTCotisation,
				fTINCotisation			= @fTINCotisation,
				fOUTFee					= @fOUTFee,
				fTINFee					= @fTINFee,
				fSubscInsur				= @fSubscInsur,
				fBenefInsur				= @fBenefInsur,
				fTaxOnInsur				= @fTaxOnInsur,
				fINM					= @fINM,				
				fTINInt					= @fTINInt,				
				fCESG					= @fCESG,				
				fCESGInt				= @fCESGInt,			
				fACESG					= @fACESG,				
				fACESGInt				= @fACESGInt,			
				fCLB					= @fCLB,				
				fCLBInt					= @fCLBInt,				
				fCESPTINInt				= @fCESPTINInt,			
				fNoCESGCotBefore98		= @fNoCESGCotBefore98,		
				fNoCESGCot98AndAfter	= @fNoCESGCot98AndAfter,		
				fCESGCot				= @fCESGCot,			
				fYearBnfCot				= @fYearBnfCot,			
				fBnfCot					= @fBnfCot,					
				dtLastVerif				= @dtLastVerif,			
				bACESGPaid				= @bACESGPaid,
				dtOUTOtherConvention	= @dtOUTOtherConvention,
				bPendingApplication		= @bPendingApplication,	
				bTINIsContestWinner		= @bTINIsContestWinner
		END

	IF @@ERROR <> 0
		SET @iReturn = -1

	RETURN @iReturn
END


