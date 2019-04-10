/****************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc.

Code du service		: psConv_ListeAyantSoldeIQEENegatif
Nom du service		: Liste des Conventions avec IQEE negatif
But 						: Retourner la liste des conventions ayant un solde IQEE negatif
Facette					: OPER

Paramètres d’entrée    :    
    Paramètre				Description
    --------------------	------------------------------------------------------------------------------------------
	@StartDate			Plus petite date d'entrée en vigueur retournée. Si omis, la date du 1er jour du mois sera utilisé
    @EndDate				Plus grande date d'entrée en vigueur retournée. Si omis, la date du jour sera utilisé
	@EtatConvention	Si specifié, retourne uniquement les conventions dans cet état. Si laissé vide, retourne toutes les conventions.

Exemple d’appel     :	EXEC dbo.psConv_ListeAyantSoldeIQEENegatif_PLS '1960-01-01', '2015-12-31', NULL
								EXEC dbo.psConv_ListeAyantSoldeIQEENegatif_PLS NULL, NULL, NULL

Historique des modifications:
    Date					Programmeur                Description																Référence
    ----------			--------------------			---------------------------------------------------------		--------------
    2016-02-29		Dominique Pothier			Création
	2016-03-02		Dominique Pothier			Ajout du parametre "Etat Convention"
	2016-03-15		Dominique Pothier			Ajout de deux colonnes: etat premier groupe unité et raison fermeture
	2016-04-06		Pierre-Luc Simard			Optimisation
**********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ListeAyantSoldeIQEENegatif] (
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @EtatConvention CHAR(3) = NULL)
AS
BEGIN
    IF @EndDate IS NULL
        SET @EndDate = GETDATE()

    IF @StartDate IS NULL
        SET @StartDate = '0001-01-01'
	
	-- Liste les conventions ayant un solde négatif d'IQEE
	SELECT 
		C.ConventionID,
        C.ConventionNo,
        C.SubscriberID,
        C.ConventionStateID,
        C.PlanID,
		C.vcRaison_Fermeture,
        C.SoldeIQEE,
        C.SoldeIQEE_Plus
	INTO #tConv
	FROM (
		SELECT
			C.ConventionID,
			C.ConventionNo,
			C.SubscriberID,
			C.ConventionStateID,
			C.PlanID,
			C.vcRaison_Fermeture,
			SoldeIQEE = SUM(CASE CO.ConventionOperTypeID WHEN 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END),
			SoldeIQEE_Plus = SUM(CASE CO.ConventionOperTypeID WHEN 'MMQ'	THEN CO.ConventionOperAmount ELSE 0 END)
		FROM (
			SELECT
				C.ConventionID,
				C.ConventionNo,
				C.SubscriberID,
				CS.ConventionStateID,
				PlanID,
				RF.vcRaison_Fermeture
			FROM dbo.Un_Convention C
			JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(GETDATE(), NULL) CS ON C.ConventionID = CS.conventionID
			LEFT JOIN tblCONV_RaisonFermeture RF ON RF.iID_Raison_Fermeture = C.iID_Raison_Fermeture
			WHERE C.dtEntreeEnVigueur BETWEEN @StartDate AND @EndDate
				AND (CS.ConventionStateID = @EtatConvention
					OR @EtatConvention IS NULL)
			) C
		JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
		WHERE ConventionOperTypeID IN ('CBQ', 'MMQ')
		GROUP BY
			C.ConventionID,
			C.ConventionNo,
			C.SubscriberID,
			C.ConventionStateID,
			C.PlanID,
			C.vcRaison_Fermeture
		) C
	WHERE C.SoldeIQEE < 0
		OR C.SoldeIQEE_Plus <0

    SELECT
        U.ConventionID,
        U.UnitID,
        U.InForceDate,
        US.UnitStateName,
        U.Row
    INTO #tPremierGroupeUnite
    FROM (-- Premier groupe d'unités     
		SELECT 
			U.ConventionID ,
            U.UnitID ,
            U.InForceDate ,
            U.Row 
		FROM (
			SELECT
				U.ConventionID,
				U.UnitID,
				U.InForceDate,
				Row = ROW_NUMBER() OVER (PARTITION BY U.ConventionID ORDER BY U.InForceDate ASC, U.UnitID)
			FROM Un_Unit U
			JOIN #tConv C ON C.ConventionID = U.ConventionID
			) U		
		WHERE U.Row = 1
		) U
	JOIN (-- État du groupe d'unités
		SELECT
			UnitState.UnitID,
			UnitState.UnitStateID,
			States.UnitStateName
		FROM Un_UnitUnitState UnitState
		JOIN (
			SELECT
				UnitState.UnitID,
				MAX(UnitState.StartDate) AS StartDate
			FROM Un_UnitUnitState UnitState
			GROUP BY UnitState.UnitID
			) EtatCourant ON EtatCourant.UnitID = UnitState.UnitID
		JOIN Un_UnitState States ON UnitState.UnitStateID = States.UnitStateID
		WHERE UnitState.StartDate = EtatCourant.StartDate
		) US ON US.UnitID = U.UnitID

    SELECT
        C.ConventionNo,
        C.SubscriberID,
        EtatConvention = CS.ConventionStateName,
        EtatPremierGU = U.UnitStateName,
        DateRin = CASE WHEN C.PlanID <> 4 THEN dbo.fnConv_DateRemboursementIntegralePourConvention(C.ConventionID) END,
        C.SoldeIQEE,
        C.SoldeIQEE_Plus,
        C.vcRaison_Fermeture
    FROM #tConv C
    JOIN #tPremierGroupeUnite U ON U.ConventionID = C.ConventionID
    JOIN Un_ConventionState CS ON CS.ConventionStateID = C.ConventionStateID
	ORDER BY C.ConventionNo

	DROP TABLE #tConv
    DROP TABLE #tPremierGroupeUnite
END
