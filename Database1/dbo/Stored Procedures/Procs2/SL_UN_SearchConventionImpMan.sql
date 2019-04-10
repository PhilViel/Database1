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
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchConventionImpMan
Description         :	Procédure pour la recherche de convention pour importation manuelle aux bourses.
Valeurs de retours  :	Dataset :
									ConventionID		INTEGER		ID de la convention.
									ConventionNo		VARCHAR(75)	Numéro de convention.
									SubscriberID		INTEGER		ID du souscripteur.
									BeneficiaryName	VARCHAR(77)	Nom, prénom du bénéficiaire.
									SubscriberName		VARCHAR(77)	Nom, prénom du souscripteur.
									BeneficiaryID		INTEGER		ID du bénéficiaire.
Note                :	ADX0000704	IA	2005-07-05	Bruno Lapointe		Création
								ADX0001809	BR	2006-01-03	Bruno Lapointe		Permettre l'importation manuelle des convnetions
																							dont les groupes d'unités sont en remboursement
																							intégral versés aussi.
								ADX0001185	IA	2006-12-05	Bruno Lapointe		Optimisation
                                                2018-01-25  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchConventionImpMan] (	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@vcSearchType VARCHAR(3),  -- Type de recherche : BNa = Nom, prénom du bénéficiaire.	CNo = Numéro de convention. 
										-- SNa = Nom, prénom du souscripteur.
	@vcSearch VARCHAR(100)) -- Valeur recherché selon le @vcSearchType.
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT

	SET @dtBegin = GETDATE()

	DECLARE @tSearchConvFirst TABLE (
		ConventionID INTEGER PRIMARY KEY )

	IF @vcSearchType = 'SNa'
		-- Souscripteur
		INSERT INTO @tSearchConvFirst
			SELECT C.ConventionID
			FROM dbo.Mo_Human H
			JOIN dbo.Un_Convention C ON C.SubscriberID = H.HumanID
			WHERE ISNULL(H.LastName,'') + ', ' + ISNULL(H.FirstName,'') LIKE @vcSearch
	ELSE IF @vcSearchType = 'BNa'
		-- Bénéficiaire
		INSERT INTO @tSearchConvFirst
			SELECT C.ConventionID
			FROM dbo.Mo_Human H
			JOIN dbo.Un_Convention C ON C.BeneficiaryID = H.HumanID
			WHERE ISNULL(H.LastName,'') + ', ' + ISNULL(H.FirstName,'') LIKE @vcSearch
	ELSE IF @vcSearchType = 'CNo'
		-- No convention
		INSERT INTO @tSearchConvFirst
			SELECT 
				ConventionID
			FROM dbo.Un_Convention 
			WHERE ConventionNo LIKE @vcSearch

	DECLARE @tSearchConv TABLE (
		ConventionID INTEGER PRIMARY KEY )

	INSERT INTO @tSearchConv
		SELECT DISTINCT C.ConventionID
		FROM @tSearchConvFirst tC
		JOIN dbo.Un_Convention C ON C.ConventionID = tC.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		LEFT JOIN Un_Scholarship Sc ON Sc.ConventionID = C.ConventionID
		WHERE U.TerminatedDate IS NULL -- Pas annulé
			AND P.PlanTypeID = 'COL' -- Plan collectif seulement
			AND Sc.ScholarshipID IS NULL -- Pas déjà importé

	SELECT
		C.ConventionID, -- ID de la convention.
		C.ConventionNo, -- Numéro de convention.
		C.SubscriberID, -- ID du souscripteur.
		BeneficiaryName = ISNULL(HB.LastName, '') + ', ' + ISNULL(HB.FirstName, ''), -- Nom, prénom du bénéficiaire.
		SubscriberName = 
			CASE
				WHEN HS.IsCompany = 1 THEN ISNULL(HS.LastName, '')
			ELSE ISNULL(HS.LastName, '') + ', ' + ISNULL(HS.FirstName, '')
			END, -- Nom, prénom du souscripteur.
		C.BeneficiaryID -- ID du bénéficiaire.
	FROM @tSearchConv tC
	JOIN dbo.Un_Convention C ON C.ConventionID = tC.ConventionID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
	JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
	LEFT JOIN (
		SELECT DISTINCT ConventionID
		FROM dbo.Un_Unit 
		WHERE TerminatedDate IS NULL
			AND UnitID NOT IN (
				SELECT 
					U.UnitID
				FROM @tSearchConv tC
				JOIN dbo.Un_Unit U ON U.ConventionID = tC.ConventionID
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Modal M ON M.ModalID = U.ModalID
				JOIN Un_Plan P ON P.PlanID = M.PlanID
				WHERE U.TerminatedDate IS NULL
				GROUP BY
					U.UnitID,
					U.UnitQty,
					U.PmtEndConnectID,
					U.IntReimbDate,
					M.PmtRate,
					M.PmtQty
				HAVING SUM(Ct.Cotisation+Ct.Fee) = ROUND(U.UnitQty * M.PmtRate,2) * M.PmtQty -- Capital atteint
					OR U.PmtEndConnectID > 0 -- Capital atteint du à un arrêt de paiement forcé
					OR U.IntReimbDate IS NOT NULL -- Remboursement intégral versé
				)
		) V ON V.ConventionID = C.ConventionID
	JOIN (
		SELECT DISTINCT U.ConventionID
		FROM @tSearchConv tC
		JOIN dbo.Un_Unit U ON U.ConventionID = tC.ConventionID
		WHERE U.TerminatedDate IS NULL
		) U ON U.ConventionID = C.ConventionID
	LEFT JOIN Un_Scholarship Sc ON Sc.ConventionID = C.ConventionID
	WHERE Sc.ScholarshipID IS NULL -- Pas déjà importé
		AND P.PlanTypeID = 'COL' -- Plan collectif seulement
		 AND V.ConventionID IS NULL -- Montant souscrit atteint seulement
	ORDER BY C.ConventionNo

	SET @dtEnd = GETDATE()
	SELECT @siTraceSearch = siTraceSearch FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceSearch
		-- Insère une trace de l'ewxécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceSearch.
		INSERT INTO Un_Trace (
				ConnectID, -- ID de connexion de l’usager
				iType, -- Type de trace (1 = recherche, 2 = rapport)
				fDuration, -- Temps d’exécution de la procédure
				dtStart, -- Date et heure du début de l’exécution.
				dtEnd, -- Date et heure de la fin de l’exécution.
				vcDescription, -- Description de l’exécution (en texte)
				vcStoredProcedure, -- Nom de la procédure stockée
				vcExecutionString ) -- Ligne d’exécution (inclus les paramètres)
			SELECT
				@ConnectID,
				1,
				DATEDIFF(SECOND, @dtBegin, @dtEnd), -- Temps en seconde
				@dtBegin,
				@dtEnd,
				'Recherche de convention pour imp. manuelle par '+
					CASE @vcSearchType
						WHEN 'BNa' THEN 'bénéficiaire : ' 
						WHEN 'SNa' THEN 'souscripteur : ' 
						WHEN 'CNo' THEN 'convention : '
					END + @vcSearch,
				'SL_UN_SearchConventionImpMan',
				'EXECUTE SL_UN_SearchConventionImpMan @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @vcSearchType = '+@vcSearchType+
					', @vcSearch = '+@vcSearch
    */
END