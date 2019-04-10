/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 : RP_UN_RepClientList
Description         : Procédure stockée du rapport : Liste de client par représentant
Valeurs de retours  : >0  :	Tout à fonctionné
                      <=0 :	Erreur SQL
								-1	: Erreur lors de la sauvegarde de l'ajout
								-2 : Cette année de qualification est déjà en vigueur pour cette convention
Note                :	ADX0001206	IA	2006-11-06	Bruno Lapointe		Optimisation.

						2009-08-13	Donald Huppé	Inscrire "'*** Adresse perdue ***'" dans adresse si AddressLost = 1
						2015-02-20	Donald Huppé	glpi 13616 : Ajout de SubscriberID

exec RP_UN_RepClientList 1, '2009-01-01','2009-05-01', 0 536198
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepClientList] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@StartDate DATETIME, -- Date de début de la période de vente
	@EndDate DATETIME, -- Date de fin de la période de vente
	@RepID INTEGER) -- ID du représentant dont on veut la liste
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	SELECT
		R.RepID,
		Rep = Hu.LastName + ', ' + Hu.FirstName,
		Subscriber = H.Lastname + ', ' + H.FirstName,
		Address = case when s.AddressLost = 0 then A.Address else '*** Adresse perdue ***' end ,
		Tel = A.Phone1,
		C.ConventionNO,
		InForceDate = MIN(U.InForceDate),
		FirstDepositDate = MIN(ISNULL(U.dtFirstDeposit,@EndDate+1)),
		Unit_Qty = SUM(U.UnitQty),
		c.SubscriberID
	FROM dbo.Un_Unit U
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	JOIN Un_Rep R ON R.RepID = S.RepID
	JOIN dbo.Mo_Human Hu ON R.RepID = Hu.HumanID
	JOIN dbo.Mo_Human H ON S.SubscriberID = H.HumanID
	JOIN dbo.Mo_Adr A ON H.AdrID = A.AdrID
	WHERE U.TerminatedDate IS NULL
		AND U.IntReimbDate IS NULL
		AND (@RepID = S.RepID or @RepID = 0)
	GROUP BY 
		C.ConventionNO,
		R.RepID, 
		Hu.LastName, 
		Hu.FirstName, 
		H.Lastname, 
		H.FirstName, 
		A.Address, 
		A.Phone1,
		s.AddressLost,
		c.SubscriberID
	HAVING MIN(ISNULL(U.dtFirstDeposit,@EndDate+1)) BETWEEN @StartDate AND @EndDate
	ORDER BY 
		Rep, 
		Subscriber

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
				'Liste de client par représentant',
				'RP_UN_RepClientList',
				'EXECUTE RP_UN_RepClientList @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @StartDate = '+CAST(@StartDate AS VARCHAR)+
					', @EndDate = '+CAST(@EndDate AS VARCHAR)+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END

/*  Sequence de test - par: PLS - 09-05-2008
	exec [dbo].[RP_UN_RepClientList] 
	@ConnectID = 1, -- ID de connexion de l'usager
	@StartDate = '2008-05-01', -- Date de début de la période de vente
	@EndDate = '2008-05-31', -- Date de fin de la période de vente
	@RepID = 0 -- ID du représentant dont on veut la liste (0 = Tous)
*/


