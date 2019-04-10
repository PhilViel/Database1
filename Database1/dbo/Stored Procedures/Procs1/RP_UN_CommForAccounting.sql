﻿/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_CommForAccounting
Description         :	PROCEDURE DU RAPPORT DES COMMISSIONS POUR ÉCRITURE COMPTABLE
Valeurs de retours  :	@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	
				ADX0000847		IA	2004-04-20 	Dominic Létourneau	Migration ancienne stored procedure selon nouveaux standards			
				ADX0001206		IA	2006-12-12	Alain Quirion			Optimisation
				ADX0002694		UR	2007-04-11	Bruno Lapointe			Afficher la date de fin d'affaire seulement si elle est 
																					antérieure ou égale à la date du traitement de commissions
																					sélectionné.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_CommForAccounting] (
	@ConnectID INTEGER,
	@RepTreatmentID INTEGER) -- Numéro du traitement des commissions
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	DECLARE @RepTreatmentDate MoDate
	
	-- Lecture de la date du traitement choisi
	SELECT @RepTreatmentDate = RepTreatmentDate
	FROM Un_Reptreatment
	WHERE RepTreatmentID = @RepTreatmentID
	
	-- Retrouve les dossiers qui seront affichés dans le rapport
	SELECT
		S.RepTreatmentDate,
		Statut = CASE WHEN R.BusinessEnd < RT.RepTreatmentDate THEN 'Inactif' ELSE 'Actif' END,
		S.RepID,
		R.RepCode,
		S.RepName,
		S.NewAdvance,	
		S.CommAndBonus,
		S.Adjustment,
		S.Retenu,
		S.ChqNet,
		S.Advance,	
		TerminatedAdvance = ISNULL(AVR.AVRAmount,0) ,
		SpecialAdvance = ISNULL(SA.Amount,0) ,
		TotalAdvance = ISNULL(S.Advance,0) + ISNULL(SA.Amount,0) + ISNULL(AVR.AVRAmount,0) ,
		S.CoveredAdvance,
		CommissionFee = S.CommAndBonus + S.Adjustment + S.CoveredAdvance,
		BusinessEnd =
			CASE 
				WHEN R.BusinessEnd >= RT.RepTreatmentDate THEN NULL
			ELSE R.BusinessEnd
			END
	FROM Un_Dn_RepTreatmentSumary S
	JOIN Un_Rep R ON S.RepId = R.RepID
	JOIN (-- Retrouve tous les représentants ayant eu des commissions de chaque traitement de l'année à ce jour 
					SELECT DISTINCT
						ReptreatmentID,
						RepID
					FROM Un_Dn_RepTreatment 
					-----
					UNION
					-----
					-- Retrouve aussi tous les représentants ayant eu des charges de chaque traitement des commissions de l'année à ce jour 
					SELECT DISTINCT
						RepTreatmentID,
						RepID
					FROM Un_RepCharge
				) T 
		ON S.RepTreatmentID = T.RepTreatmentID 
		AND S.RepID = T.RepID
	JOIN Un_RepTreatment RT 
		ON RT.RepTreatmentID = S.RepTreatmentID 
		AND RT.RepTreatmentDate = S.RepTreatmentDate
	LEFT JOIN (-- Retrouve les montants d'avances sur résiliations par représentant 
				SELECT
					RepID,
					AVRAmount = SUM(RepChargeAmount)
				FROM Un_RepCharge
				WHERE RepChargeTypeID = 'AVR'
					AND RepChargeDate <= @RepTreatmentDate
				GROUP BY RepID
			) AVR 
		ON AVR.RepID = S.RepID
	LEFT JOIN (-- Retrouve les montants d'avance spéciale par représentants 
				SELECT
					RepID,
					Amount = SUM(Amount)
				FROM Un_SpecialAdvance
				WHERE EffectDate <= @RepTreatmentDate
				GROUP BY RepID
			) SA 
		ON SA.RepID = S.RepID
	WHERE RT.RepTreatmentID = @RepTreatmentID
	ORDER BY
		Statut,
		R.RepCode,
		RepName,
		S.RepID,
		S.RepTreatmentDate,
		S.RepTreatmentID

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
				'Rapport des commissions pour la comptabilité selon le numéro de traitement '+CAST(@RepTreatmentID AS VARCHAR),
				'RP_UN_CommForAccounting',
				'EXECUTE RP_UN_CommForAccounting @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @RepTreatmentID ='+CAST(@RepTreatmentID AS VARCHAR)			
	END	
END
