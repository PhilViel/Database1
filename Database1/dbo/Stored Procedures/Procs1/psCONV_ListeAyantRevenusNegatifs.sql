/****************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc.

Code du service     : psCONV_ListeAyantRevenusNegatifs
Nom du service      : Liste des Conventions avec revenus negatifs
But 						: Retourner la liste des conventions ayant un solde de revenus negatifs
Facette					: OPER

Paramètres d’entrée    :    
    Paramètre                 Description
    --------------------		------------------------------------------------------------------------------------------
	@StartDate				Plus petite date d'entrée en vigueur retournée. Si omis, la date du 1er jour du mois sera utilisé
    @EndDate					Plus grande date d'entrée en vigueur retournée. Si omis, la date du jour sera utilisé
	@EtatConvention		Si specifié, retourne uniquement les conventions dans cet état. Si laissé vide, retourne toutes les conventions.

Exemple d’appel     :   EXEC dbo.psCONV_ListeAyantRevenusNegatifs '2015-10-22', '2015-11-10'
						EXEC dbo.psCONV_ListeAyantRevenusNegatifs '2015-10-22', '2015-11-10', 'FRM'

Historique des modifications:
    Date				Programmeur				Description																Référence
    ----------		--------------------		---------------------------------------------------------		--------------
    2016-02-25	Dominique Pothier		Création
	2016-03-02	Dominique Pothier		Ajout du parametre "Etat Convention"
	2016-03-15	Dominique Pothier		Ajout de deux colonnes: etat premier groupe unité et raison fermeture
	2016-04-06	Pierre-Luc Simard		Optimisation
**********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ListeAyantRevenusNegatifs] (
	@StartDate      DATE = NULL, 
    @EndDate        DATE = NULL,
	@EtatConvention CHAR(3) = NULL 
) AS
BEGIN
	IF @EndDate IS NULL
       SET @EndDate = GetDate()

    IF @StartDate IS NULL
        SET @StartDate =  '0001-01-01'
	
	-- Liste des conventions ayant un solde de revenus négatif
	SELECT
		C.ConventionID,
		C.ConventionNo,
		C.SubscriberID,
		CS.ConventionStateID,
		PlanID,
		RF.vcRaison_Fermeture
	INTO #tConvSelection
	FROM dbo.Un_Convention C
	JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(GETDATE(), NULL) CS ON C.ConventionID = CS.conventionID
	LEFT JOIN tblCONV_RaisonFermeture RF ON RF.iID_Raison_Fermeture = C.iID_Raison_Fermeture
	WHERE C.dtEntreeEnVigueur BETWEEN @StartDate AND @EndDate
		AND (CS.ConventionStateID = @EtatConvention
			OR @EtatConvention IS NULL)

	SELECT 
		C.ConventionID,
        C.ConventionNo,
        C.SubscriberID,
        C.ConventionStateID,
        C.PlanID,
		C.vcRaison_Fermeture,
		C.RevenusBEC,
		C.RevenusSCEE,
		C.RevenusSCEE_Plus,
		C.RevenusPCEE_TIN,
		C.RevenusIQEE,
		C.RevenusIQEE_Plus,
		C.RevenusEpargne
	INTO #tConv
	FROM (	
		SELECT 
			C.ConventionID,
			C.ConventionNo,
			C.SubscriberID,
			C.ConventionStateID,
			C.PlanID,
			C.vcRaison_Fermeture,
			RevenusBEC = SUM(CASE CO.ConventionOperTypeID WHEN 'IBC' THEN CO.ConventionOperAmount ELSE 0 END),
			RevenusSCEE = SUM(CASE CO.ConventionOperTypeID WHEN 'INS' THEN CO.ConventionOperAmount ELSE 0 END),
			RevenusSCEE_Plus = SUM(CASE CO.ConventionOperTypeID WHEN 'IS+' THEN CO.ConventionOperAmount ELSE 0 END),
			RevenusPCEE_TIN = SUM(CASE WHEN CHARINDEX(CO.ConventionOperTypeID, 'IST,ITR,III,IQI', 1) > 0 THEN CO.ConventionOperAmount ELSE 0 END),
			RevenusIQEE = SUM(CASE WHEN CHARINDEX(CO.ConventionOperTypeID, 'ICQ,MIM, IIQ', 1) > 0 THEN CO.ConventionOperAmount ELSE 0 END),
			RevenusIQEE_Plus = SUM(CASE CO.ConventionOperTypeID WHEN 'IMQ' THEN CO.ConventionOperAmount ELSE 0 END),
			RevenusEpargne = SUM(CASE WHEN CHARINDEX (CO.ConventionOperTypeID, 'INM', 1) > 0 THEN CO.ConventionOperAmount ELSE 0 END)
		FROM #tConvSelection C
		JOIN (
				SELECT 
					CO.ConventionID,
					CO.ConventionOperTypeID,
					ConventionOperAmount = SUM(CO.ConventionOperAmount)
				FROM Un_ConventionOper CO
				GROUP BY 
					CO.ConventionID,
					CO.ConventionOperTypeID
				) CO ON CO.ConventionID = C.ConventionID
		WHERE CHARINDEX(CO.ConventionOperTypeID, 'IBC,INS,IS+,IST,III,ICQ,MIM,IIQ,IQI,IMQ,INM,ITR', 1) > 0
		GROUP BY
			C.ConventionID,
			C.ConventionNo,
			C.SubscriberID,
			C.ConventionStateID,
			C.PlanID,
			C.vcRaison_Fermeture
		) C
	WHERE C.RevenusBEC < 0
		OR C.RevenusSCEE < 0
		OR C.RevenusSCEE_Plus < 0
		OR C.RevenusPCEE_TIN < 0
		OR C.RevenusIQEE < 0
		OR C.RevenusIQEE_Plus < 0
		OR C.RevenusEpargne < 0

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
		C.RevenusBEC, 
		C.RevenusIQEE, 
		C.RevenusIQEE_Plus,
		C.RevenusSCEE, 
		C.RevenusSCEE_Plus, 
		C.RevenusPCEE_TIN,
		C.RevenusEpargne,
		C.vcRaison_Fermeture
    FROM #tConv C
    JOIN #tPremierGroupeUnite U ON U.ConventionID = C.ConventionID
    JOIN Un_ConventionState CS ON CS.ConventionStateID = C.ConventionStateID
	ORDER BY C.ConventionNo

	DROP TABLE #tConvSelection
	DROP TABLE #tConv
    DROP TABLE #tPremierGroupeUnite
END
