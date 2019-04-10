/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_FolderLabel
Description         :	Étiquettes de dossiers
Valeurs de retours  :	Dataset de données
Note                :					2004-06-18 	Bruno Lapointe	Création 
				 ADX0001075	BR	2004-09-10 	Bruno Lapointe	Correction : utiliser le ActivationConnectID au lieu du 
											ValidationConnectID									
							2006-05-15 	Mireya Gonthier	Renommée SP_RP_UN_FolderLabel pour RP_UN_FolderLabel
											Modification	Remplacer la date du 1 novembre  par le 1 septembre dans les documents de l'émission.		
				ADX0001114	IA	2006-11-17	Alain Quirion	Gestion des deux périodes de calcul de date estimée de RI (FN_UN_EstimatedIntReimbDate)
				ADX0001206	IA	2006-12-20	Alain Quirion	Optimisation
								2008-02-22	Pierre-Luc Simard	Ajout d'espace devant les noms pour aligner correctement les données sur le rapport
																puisque nous n'avons pas accès à celui-ci pour le modifier directement
								2008-06-23	Jean-Francois Arial	Ajout du paramètre pour le type de convention
								2009-10-15	Donald Huppé	Ajout de l'id du souscripteur (concaténé avec son nom) - GLPI 2418
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_FolderLabel] (
	@ConnectID INTEGER,
	@StartDate DATETIME, -- Date de début de la période
	@EndDate DATETIME, -- Date de fin de la période
	@iTypeConvention INTEGER)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	IF @iTypeConvention IS NULL
		SET @iTypeConvention = 0

	SET @dtBegin = GETDATE()

		SELECT 
			SubscriberName = '     '+S.LastName+', '+S.FirstName + ' (' + cast(C.SubscriberID as varchar(7)) + ')', -- Nom du souscripteur et son ID
			BeneficiaryName = '     '+B.LastName+', '+B.FirstName, -- Nom du bénéficiaire
			EstimatedIntReimbDate = CAST(MONTH(dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust)) AS VARCHAR(2))+'/'+
											CAST(YEAR(dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust)) AS VARCHAR(4)), -- Date estimé de remboursement intégral
			C.YearQualif,-- Année de qualification
			C.ConventionNo -- Numéro de convention
		FROM dbo.Un_Unit U
		JOIN Mo_Connect Cn ON Cn.ConnectID = U.ActivationConnectID
		JOIN (
			SELECT
				U.ConventionID,
				UnitID = MIN(U.UnitID) 
			FROM dbo.Un_Unit U
			JOIN (
				SELECT 
					ConventionID,
					InForceDate = MIN(InForceDate)
				FROM dbo.Un_Unit 
				GROUP BY ConventionID
				) I ON I.ConventionID = U.ConventionID AND I.InForceDate = U.InForceDate
			JOIN Mo_Connect Cn ON Cn.ConnectID = U.ActivationConnectID
			GROUP BY U.ConventionID
			) U1 ON U1.UnitID = U.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID
		JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
		JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
		WHERE Cn.ConnectStart >= @StartDate
	  		AND Cn.ConnectStart < @EndDate + 1 AND
			(@iTypeConvention = 0 OR
			 (@iTypeConvention = 1 AND C.ConventionID NOT IN (SELECT iID_Convention_Destination
											FROM tblOPER_OperationsRIO
											WHERE bRIO_Annulee = 0)) OR
			 (@iTypeConvention = 2 AND C.ConventionID IN (SELECT iID_Convention_Destination
											FROM tblOPER_OperationsRIO
											WHERE bRIO_Annulee = 0)))
		ORDER BY 
			SubscriberName, 
			BeneficiaryName, 
			ConventionNo

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
				'Rapport des étiquettes de dossier entre le ' + CAST(@StartDate AS VARCHAR) + ' et le ' + CAST(@EndDate AS VARCHAR),
				'RP_UN_FolderLabel',
				'EXECUTE RP_UN_FolderLabel @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+
				', @EndDate ='+CAST(@EndDate AS VARCHAR)
	END	
END


