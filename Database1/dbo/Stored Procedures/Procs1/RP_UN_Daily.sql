/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                : 	RP_UN_Daily
Description        : 	Rapport Journalier
Valeurs de retours : 	>0  : Tout à fonctionné
                      	<=0 : Erreur SQL

Note                :		2004-06-29 		Bruno Lapointe		Migration
				2006-12-08	IA	Alain Quirion		Optimisation
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_Daily] (
	@ConnectID INTEGER,
	@OperTypeID CHAR(3),
	@StartDate DATETIME,
	@EndDate DATETIME)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	IF (@OperTypeID <> '')
		SELECT
			OperDate = dbo.fn_Mo_DateNoTime(O.OperDate),
			C.ConventionNo,
			SubscriberName = RTRIM(SH.LastName) + ', ' + RTRIM(SH.FirstName),
			C.YearQualif,
			O.OperTypeID,
			OT.OperTypeDesc,
			Co.Cotisation,
			Co.Fee,
			Co.BenefInsur,
			Co.SubscInsur,
			Co.TaxOnInsur,
			TotalDeposit = Co.Cotisation + Co.Fee + Co.BenefInsur + Co.SubscInsur + Co.TaxOnInsur
		FROM Un_Cotisation Co
		JOIN Un_Oper O ON O.OperID = Co.OperID
		JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
		JOIN dbo.Un_Unit U ON U.UnitID = Co.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN dbo.Mo_Human SH ON SH.HumanID = C.SubscriberID
		WHERE O.OperDate >= @StartDate
		 	AND O.OperDate < @EndDate + 1
		  	AND O.OperTypeID = @OperTypeID
		ORDER BY 
			dbo.fn_Mo_DateNoTime(O.OperDate),
			SH.LastName,
			SH.FirstName,
			C.ConventionNo
	ELSE
		SELECT
			OperDate = dbo.fn_Mo_DateNoTime(O.OperDate),
			C.ConventionNo,
			SubscriberName = RTRIM(SH.LastName) + ', ' + RTRIM(SH.FirstName),
			C.YearQualif,
			O.OperTypeID,
			OT.OperTypeDesc,
			Co.Cotisation,
			Co.Fee,
			Co.BenefInsur,
			Co.SubscInsur,
			Co.TaxOnInsur,
			TotalDeposit = Co.Cotisation + Co.Fee + Co.BenefInsur + Co.SubscInsur + Co.TaxOnInsur
		FROM Un_Cotisation Co
		JOIN Un_Oper O ON O.OperID = Co.OperID
		JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
		JOIN dbo.Un_Unit U ON U.UnitID = Co.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN dbo.Mo_Human SH ON SH.HumanID = C.SubscriberID
		WHERE O.OperDate >= @StartDate
		 	 AND O.OperDate < @EndDate + 1
		ORDER BY 
			dbo.fn_Mo_DateNoTime(O.OperDate),
			O.OperTypeID,
			SH.LastName,
			SH.FirstName,
			C.ConventionNo

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = @siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
	BEGIN
		-- Insère un log de l'objet inséré.
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
				DATEDIFF(SECOND, @dtBegin, @dtEnd),
				@dtBegin,
				@dtEnd,
				'Rapport journalier selon le type d''opération '+CAST(@OperTypeID AS VARCHAR) + ' entre le ' + CAST(@StartDate AS VARCHAR) + ' et le ' + CAST(@EndDate AS VARCHAR),
				'RP_UN_Daily',
				'EXECUTE RP_UN_Daily @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @OperTypeID ='+CAST(@OperTypeID AS VARCHAR)+
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+
				', @EndDate ='+CAST(@EndDate AS VARCHAR)			
	END	
END

/*  Sequence de test - par: JJL - 09-05-2008
	exec [dbo].[RP_UN_Daily] 
	@ConnectID = 1, -- ID de connexion de l’usager
	@OperTypeID = '',
	@StartDate = '2008-03-31',
	@EndDate = '2008-03-31'   
*/


