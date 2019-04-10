/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 					:	SL_UN_SearchConventionPrevalError 
Description 		:	Recherche des conventions en erreur de pré-validations
Valeurs de retour	:	Dataset :
							ConventionID		INTEGER		ID de la convention.
							ConventionNo		VARCHAR(75)	Numéro de convention.
							SubscriberID		INTEGER		ID du souscripteur.
							SubscriberName		VARCHAR(87)	Nom, prénom du souscripteur.
							BeneficiaryID		INTEGER		ID du bénéficiaire.
							BeneficiaryName	VARCHAR(87)	Nom, prénom du bénéficiaire.
							tiSousCESPState	TINYINT		État PCEE du souscripteur
							tiBenefCESPState	TINYINT		État PCEE du bénéficiaire
							InForceDate			DATETIME		Date d’entrée en vigueur de la convention
Note			:		ADX0001330	IA	2007-04-03	Bruno Lapointe		Création
*************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchConventionPrevalError] (
	@ConnectID INTEGER, -- ID de connexion de l’usager qui fait la recherche	
	@cSearchType CHAR(3), -- Type de recherche : CNV = Numéro de convention, VIG = Date d’entrée en vigueur de la convention, NOS = À ne pas envoyer au PCEE.
	@vcSearch VARCHAR(87), -- Critères de recherche
	@dtStart	DATETIME, -- Date de début de la période (VIG)
	@dtEnd	DATETIME ) -- Date de fin de la période (VIG)
AS
BEGIN
	DECLARE
		@dtTraceBegin DATETIME,
		@dtTraceEnd DATETIME,
		@siTraceSearch SMALLINT

	SET @dtTraceBegin = GETDATE()

	DECLARE @tSearchConv TABLE (
		ConventionID INTEGER PRIMARY KEY )

	IF @cSearchType = 'CNV'
	BEGIN
		-- Nom, prénom
		INSERT INTO @tSearchConv
			SELECT 
				ConventionID
			FROM dbo.Un_Convention 
			WHERE ConventionNo LIKE @vcSearch
				AND tiCESPState = 0 -- Ne passe pas les pré-validations
	END
	ELSE IF @cSearchType = 'VIG'
	BEGIN
		-- Nom, prénom
		INSERT INTO @tSearchConv
			SELECT 
				C.ConventionID
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			WHERE C.tiCESPState = 0 -- Ne passe pas les pré-validations
			GROUP BY 
				C.ConventionID
			HAVING MIN(U.InForceDate) BETWEEN @dtStart AND @dtEnd
	END
	ELSE IF @cSearchType = 'NOS'
	BEGIN
		-- Nom, prénom
		INSERT INTO @tSearchConv
			SELECT 
				ConventionID
			FROM dbo.Un_Convention 
			WHERE bSendToCESP = 0
	END

	SELECT
		C.ConventionID, -- ID de la convention.
		C.ConventionNo, -- Numéro de convention.
		C.SubscriberID, -- ID du souscripteur.
		SubscriberName = HS.Lastname + ', ' + HS.FirstName, -- Nom, prénom du souscripteur.
		C.BeneficiaryID, -- ID du bénéficiaire.
		BeneficiaryName = HB.Lastname + ', ' + HB.FirstName, -- Nom, prénom du bénéficiaire.
		tiSousCESPState = S.tiCESPState, -- État PCEE du souscripteur
		tiBenefCESPState = B.tiCESPState, -- État PCEE du bénéficiaire
		InForceDate = MIN(U.InForceDate) -- Date d’entrée en vigueur de la convention
	FROM @tSearchConv SC
	JOIN dbo.Un_Convention C ON SC.ConventionID = C.ConventionID
	JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
	JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	WHERE	( ISNULL(HB.SocialNumber,'') <> '' -- NAS du bénéficaiire présent
			OR @cSearchType = 'NOS'
			)
		AND C.ConventionID IN ( -- Convention avec au moins un groupe d'unités qui est ni résilié ni en remboursement intégral
				SELECT DISTINCT ConventionID
				FROM dbo.Un_Unit 
				WHERE TerminatedDate IS NULL -- ni résilié
					AND IntReimbDate IS NULL -- ni en remboursement intégral
				)
	GROUP BY
		C.ConventionID,
		C.ConventionNo,
		C.SubscriberID,
		HS.Lastname,
		HS.FirstName,
		C.BeneficiaryID,
		HB.Lastname,
		HB.FirstName,
		S.tiCESPState,
		B.tiCESPState
	ORDER BY C.ConventionNo -- Par ordre de numéro de convention
	
	SET @dtTraceEnd = GETDATE()
	SELECT @siTraceSearch = siTraceSearch FROM Un_Def

	IF DATEDIFF(SECOND, @dtTraceBegin, @dtTraceEnd) > @siTraceSearch
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
				DATEDIFF(SECOND, @dtTraceBegin, @dtTraceEnd), -- Temps en seconde
				@dtTraceBegin,
				@dtTraceEnd,
				'Recherche de convention en erreur de pré-validations '+
					CASE @cSearchType
						WHEN 'CNV' THEN 'par convention : ' + @vcSearch
						WHEN 'VIG' THEN 'par date d''entrée en vigueur : ' + @vcSearch
						WHEN 'NOS' THEN 'à ne pas envoyer au PCEE'
					END,
				'SL_UN_SearchConventionPrevalError',
				'EXECUTE SL_UN_SearchConventionPrevalError @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @cSearchType = '+@cSearchType+
					', @vcSearch = '+@vcSearch+
					', @dtStart = '+CAST(@dtStart AS VARCHAR)+
					', @dtEnd = '+CAST(@dtEnd AS VARCHAR)
END


