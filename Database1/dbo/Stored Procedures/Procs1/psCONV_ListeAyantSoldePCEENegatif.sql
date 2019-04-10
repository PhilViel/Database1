/****************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc.

Code du service        : psCONV_ListeAyantSoldePCEENegatif
Nom du service        : Liste des Conventions avec PCEE negatif
But                   : Retourner la liste des conventions ayant un solde PCEE negatif
Facette                : OPER

Paramètres d’entrée    :    
    Paramètre                    Description
    --------------------    ------------------------------------------------------------------------------------------
	@StartDate               Plus petite date d'entrée en vigueur retournée. Si omis, la date du 1er jour du mois sera utilisé
    @EndDate                 Plus grande date d'entrée en vigueur retournée. Si omis, la date du jour sera utilisé
	@EtatConvention          Si specifié, retourne uniquement les conventions dans cet état. Si laissé vide, retourne toutes les conventions.

Exemple d’appel     :   EXEC dbo.psCONV_ListeAyantSoldePCEENegatif '1960-01-01', '2015-11-10'

Historique des modifications:
    Date				Programmeur            Description																Référence
    ----------		--------------------		---------------------------------------------------------		--------------
    2016-02-29	Dominique Pothier		Création
	2016-03-02	Dominique Pothier		Ajout du parametre "Etat Convention"
	2016-03-15	Dominique Pothier		Ajout de deux colonnes: etat premier groupe unité et raison fermeture
	2016-04-06	Pierre-Luc Simard		Optimisation
**********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ListeAyantSoldePCEENegatif] (
	@StartDate     DATE = NULL, 
    @EndDate       DATE = NULL,
	@EtatConvention CHAR(3) = NULL
) AS
BEGIN
	IF @EndDate IS NULL
       SET @EndDate = GetDate()

    IF @StartDate IS NULL
        SET @StartDate =  '0001-01-01'
	
	-- Liste des conventinos ayant un solde de PCEE négatif
	SELECT 
		C.ConventionID,
        C.ConventionNo,
        C.SubscriberID,
        C.ConventionStateID,
        C.PlanID,
		C.vcRaison_Fermeture,
        C.SoldeSCEE,
		C.SoldeSCEE_Plus,
		C.SoldeBEC 
	INTO #tConv
	FROM (
		SELECT
			C.ConventionID,
			C.ConventionNo,
			C.SubscriberID,
			C.ConventionStateID,
			C.PlanID,
			C.vcRaison_Fermeture,
			SoldeSCEE =  SUM(PCEE.fCESG),
			SoldeSCEE_Plus = SUM(PCEE.fACESG),
			SoldeBEC = SUM(PCEE.fCLB)
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
		JOIN Un_CESP PCEE on PCEE.ConventionID = C.ConventionID
		GROUP BY
			C.ConventionID,
			C.ConventionNo,
			C.SubscriberID,
			C.ConventionStateID,
			C.PlanID,
			C.vcRaison_Fermeture
		) C
	WHERE C.SoldeSCEE < 0
		OR SoldeSCEE_Plus < 0
		OR SoldeBEC < 0

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
		C.SoldeSCEE,
		C.SoldeSCEE_Plus,
		C.SoldeBEC,
        C.vcRaison_Fermeture
    FROM #tConv C
    JOIN #tPremierGroupeUnite U ON U.ConventionID = C.ConventionID
    JOIN Un_ConventionState CS ON CS.ConventionStateID = C.ConventionStateID
	ORDER BY C.ConventionNo

	DROP TABLE #tConv
    DROP TABLE #tPremierGroupeUnite
END
