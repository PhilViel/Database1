/************************************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc
Code du service:	psREPR_GenererRepriseCommissionsSurBEC
Nom du service:		Générer les reprises de commissions sur le BEC
But:				Calculer les reprises de commissions sur le BEC, pour les groupes d'unités déjà commissionés, à une date donnée.
Facette:					REPR

Paramètres d’entrée	:	Paramètre						Description
						--------------------------	-----------------------------------------------------------------
		  				dDateCalcul					Date du calcul (Normalement le premier du mois)
									
Exemple d’appel:	EXEC psREPR_GenererRepriseCommissionsSurBEC '2018-11-30'
			
Paramètres de sortie:		Table						Champ							Description
		  					-------------------------	--------------------------- 	---------------------------------
							S/O							iCode_Retour					Code de retour standard

Historique des modifications:
						2018-11-06	Donald Huppé			Création du service

************************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_GenererRepriseCommissionsSurBEC] (
    @dDateCalcul DATE)
AS
BEGIN

    DECLARE
        @iResult INTEGER,
		@iDelai_Interdiction_COL INT

    SET @iResult = 1
	SET @iDelai_Interdiction_COL = CONVERT(FLOAT, dbo.fnGENE_ObtenirParametre('REPR_BONI_BEC_PERIODE_INTERDICTION_COL', @dDateCalcul, NULL, NULL, NULL, NULL, NULL))
 

	SELECT DISTINCT
		CB.RepID,
		CB.RepRoleID,
		U.UnitID,
		CB.BeneficiaryID,
		mMontant_ComBEC = CB.mMontant_ComBEC * -1
	INTO #REPRISE
	FROM tblREPR_CommissionsBEC CB
	JOIN Un_Unit U ON U.UnitID = CB.UnitID
	JOIN (
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
			H.BeneficiaryID = CB.BeneficiaryID 
			AND H.ConventionStateID IN ('TRA','REE')
			AND (
				-- CONTRAT DEVENU REE DANS LES 90 JOURS SUIVANT LA SIGNATURE DU IBEC
				H.StartDate BETWEEN U.SignatureDate AND DATEADD(DAY,@iDelai_Interdiction_COL/*90*/,U.SignatureDate)
				OR
				-- contrat COL pendant la signature du IBEC
				U.SignatureDate BETWEEN H.StartDate AND H.EndDate
				)
	WHERE 1=1

 
	SELECT * FROM #REPRISE


	IF EXISTS (SELECT 1 FROM #REPRISE)

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
				dDate_Calcul = @dDateCalcul,
				RepID,
				RepRoleID,
				UnitID,
				BeneficiaryID,
				mMontant_ComBEC		 
			FROM #REPRISE

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