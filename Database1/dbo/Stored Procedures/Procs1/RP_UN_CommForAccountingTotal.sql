/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_CommForAccountingTotal
Description         :	PROCEDURE DU RAPPORT DES COMMISSIONS POUR ÉCRITURE COMPTABLE
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	
				ADX0000847	IA	2004-04-20 	Dominic Létourneau	Migration ancienne stored procedure selon nouveaux standards			
				ADX0001206	IA	2006-12-12	Alain Quirion		Optimisation
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_CommForAccountingTotal] (
	@ConnectID INTEGER,
	@RepTreatmentID INTEGER) -- Numéro du traitement des commissions
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	DECLARE @YearFirstRepTreatmentID INTEGER --ID unique du premier traitement des commissions de l'année
	
	-- Retrouve le premier traitement des commissions de l'année
	SELECT @YearFirstRepTreatmentID = MIN(RepTreatmentID)
	FROM Un_Reptreatment R
	JOIN (-- Retrouve l'année du traitement des commissions spécifié en paramètre 
		SELECT RepTreatmentYear = YEAR(RepTreatmentDate)
		FROM Un_Reptreatment
		WHERE RepTreatmentID = @RepTreatmentID) T ON YEAR(R.RepTreatmentDate) = T.RepTreatmentYear -- même année
	
	-- Lecture des totaux cumulatif du rapport
	SELECT 
		NewAdvance,
		CommAndBonus,
		Adjustment,
		Retenu,
		ChqNet,		
		CoveredAdvance,
		CommissionFee = CommAndBonus + Adjustment + CoveredAdvance
	FROM (-- Retrouve tous les totaux sauf le CommissionFee qui est un sous-produit des totaux retrouvés
		SELECT
			NewAdvance = SUM(S.NewAdvance) ,
			CommAndBonus = SUM(S.CommAndBonus) ,
			Adjustment = SUM(S.Adjustment) ,
			Retenu = SUM(S.Retenu) ,
			ChqNet = SUM(S.ChqNet) ,
			CoveredAdvance = SUM(S.CoveredAdvance) 
		FROM Un_Dn_RepTreatmentSumary S
		JOIN Un_Rep R ON S.RepId = R.RepID
		JOIN (-- Retrouve tous les représentants ayant eu des commissions de chaque traitement de l'année à ce jour
			SELECT DISTINCT
				ReptreatmentID,
				RepID
			FROM Un_Dn_RepTreatment
			WHERE RepTreatmentID BETWEEN @YearFirstRepTreatmentID AND @RepTreatmentID
			-----
			UNION
			-----
			-- Retrouve aussi tous les représentants ayant eu des charges de chaque traitement des commissions de l'année à ce jour
			SELECT DISTINCT
				RepTreatmentID,
				RepID
			FROM Un_RepCharge
			WHERE RepTreatmentID BETWEEN @YearFirstRepTreatmentID AND @RepTreatmentID) T ON S.RepTreatmentID = T.RepTreatmentID AND S.RepID = T.RepID
			JOIN Un_RepTreatment RT ON RT.RepTreatmentID = S.RepTreatmentID AND RT.RepTreatmentDate = S.RepTreatmentDate
			WHERE RT.RepTreatmentID BETWEEN @YearFirstRepTreatmentID AND @RepTreatmentID) U -- tous les traitements depuis le début de l'année
	
	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

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
				'Rapport des commissions totales pour la comptabilité selon le numéro de traitement '+CAST(@RepTreatmentID AS VARCHAR),
				'RP_UN_CommForAccountingTotal',
				'EXECUTE RP_UN_CommForAccountingTotal @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @RepTreatmentID ='+CAST(@RepTreatmentID AS VARCHAR)			
	END	
END

