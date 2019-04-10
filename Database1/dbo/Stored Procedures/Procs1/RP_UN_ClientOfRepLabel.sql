/****************************************************************************************************
Copyrights (c) 2007 Gestion Universitas Inc.
Nom                 :	RP_UN_ClientOfRepLabel
Description         :	Procédure stockée du rapport : Étiquettes des clients des représentants
Valeurs de retours  :	Dataset 
Note                :	ADX0001206	IA	2007-01-09	Bruno Lapointe		Optimisation.
						2009-08-13	Donald Huppé  Inscrire "'*** Adresse perdue ***'" dans adresse si AddressLost = 1

exec RP_UN_ClientOfRepLabel 1, 'REP', 149497
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ClientOfRepLabel] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@Type VARCHAR(3), -- Type de recherche 'ALL' = Tous les représentants, 'DIR' = Tous les représentants du directeur, 'REP' Représentant unique
	@RepID INTEGER) -- ID Unique du Rep
AS
BEGIN
	-- Retourne les unités vendus dans une période par régime et groupé par représentant et agence
	DECLARE 
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	CREATE TABLE #TB_Rep (
		RepID INTEGER PRIMARY KEY
	)

	IF @Type = 'ALL'
		INSERT INTO #TB_Rep
			SELECT 
				RepID
			FROM Un_Rep
	ELSE IF @Type = 'DIR'
		INSERT INTO #TB_Rep
			EXEC SP_SL_UN_RepOfBoss @RepID
	ELSE IF @Type = 'REP'
		INSERT INTO #TB_Rep
		VALUES (@RepID)

	SELECT DISTINCT 
		R.RepCode, 
		RepName = RH.LastName+ ', '+RH.FirstName, 
		R.RepID, 
		Transfert = 
			CASE
				WHEN T.SubscriberID IS NULL THEN 0
			ELSE 1
			END, 
		Subscriber = SH.LastName + ' ' + SH.FirstName, 
		S.SubscriberID,
		Address = case when S.AddressLost = 0 then SA.Address else '*** adresse perdue ***' end ,  --select * FROM dbo.Un_Subscriber 
		City  = case when S.AddressLost = 0 then SA.City else '' end , 
		StateName = case when S.AddressLost = 0 then SA.StateName else '' end, 
		CountryName = case when S.AddressLost = 0 then Co.CountryName else '' end, 
		ZipCode = case when S.AddressLost = 0 then SA.ZipCode else '' end
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	JOIN dbo.Mo_Human SH ON S.SubscriberID = SH.HumanID
	JOIN Un_Rep R ON S.RepID = R.RepID
	JOIN dbo.Mo_Human RH ON R.RepID = RH.HumanID
	JOIN Un_Plan P ON C.PlanID = P.PlanID
	JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
	JOIN dbo.Mo_Adr SA ON SH.AdrID = SA.AdrID
	JOIN Un_Modal M ON U.ModalID = M.ModalID
	LEFT JOIN ( -- Va chercher les souscripteurs qui sont des clients transféré.
		SELECT DISTINCT
			S.SubscriberID
		FROM dbo.Un_Subscriber S
		JOIN dbo.Un_Convention C ON C.SubscriberID = S.SubscriberID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID AND S.RepID <> U.RepID
		) T ON T.SubscriberID = S.SubscriberID
	LEFT JOIN Mo_Country Co ON SA.CountryID = Co.CountryID
	JOIN #TB_Rep TR ON TR.RepID = R.RepID -- Filtre les représentants
	WHERE ISNULL(U.TerminatedDate, 0) < 1 
	  AND ISNULL(U.IntReimbDate, 0) < 1
	ORDER BY 
		RH.LastName+ ', '+RH.FirstName, 
		R.RepID,
		case when S.AddressLost = 0 then SA.ZipCode else '' end,
		SH.LastName + ' ' + SH.FirstName, 
		S.SubscriberID,
		case when S.AddressLost = 0 then SA.Address else '*** adresse perdue ***' end, 
		case when S.AddressLost = 0 then SA.City else '' end , 
		case when S.AddressLost = 0 then SA.StateName else '' end, 
		case when S.AddressLost = 0 then Co.CountryName else '' end

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
		-- Insère une trace de l'ewxécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceReport.
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
				2,
				DATEDIFF(MILLISECOND, @dtBegin, @dtEnd)/1000,
				@dtBegin,
				@dtEnd,
				'Étiquettes des clients des représentants',
				'RP_UN_ClientOfRepLabel',
				'EXECUTE RP_UN_ClientOfRepLabel @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @Type = '+@Type+
					', @RepID = '+CAST(@RepID AS VARCHAR)

END


