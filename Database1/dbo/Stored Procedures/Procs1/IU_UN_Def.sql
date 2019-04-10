/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_Def
Description         :	Permet de modifier l'enregistrement de configuration de l'application.
Valeurs de retours  :	@ReturnValue :
						>0 :	La sauvegarde a réussie.
						<=0 :	La sauvegarde a échouée.
Note                :				2004-06-08	Bruno Lapointe		Migration et développement point 10.27 : Avis de convention sans NAS
						2004-06-11	Bruno Lapointe		Ajout des champs CRQ
			ADX0000158	IA 	2004-08-27	Bruno Lapointe		12.40 - Ajout du champs BusinessBonusLimit
			ADX0000532	IA	2004-10-12	Bruno Lapointe		12.56 - Ajout des champs NbBankOpenDays et NbOpenDaysForNextTreatment. Suppression du champ OpenDaysForBankTransaction
			ADX0000532	IA	2004-10-22	Bruno Lapointe		12.56 - Suppression des champs NbBankOpenDays et NbOpenDaysForNextTreatment
			ADX0000752	IA	2005-07-27	Bruno Lapointe		17.14 - Renommé
			ADX0001179	IA	2006-10-25	Alain Quirion		Modification : Ajout des champs tiCheckNbMonthBefore et tiCheckNbDayBefore
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_Def] (
	@ConnectID INTEGER, 				-- ID unique de connexion de l'usager qui fait l'opération
	@MaxLifeCotisation MONEY, 			-- C'est le maximum à vie qui peut être cotisé pour un bénéficiaire en REEE (Ex : 42 000$)
	@MaxYearCotisation MONEY, 			-- C'est le maximum par année qui peut être cotisé pour un bénéficiaire en REEE (Ex : 4 000$)
	@MaxLifeGovernmentGrant MONEY, 			-- C'est le maximum à vie qui peut être reçu en subvention pour un bénéficiaire en REEE (Ex : 7 200$)
	@MaxYearGovernmentGrant MONEY, 			-- C'est le maximum par année qui peut être reçu en subvention pour un bénéficiaire en REEE (Ex : 4 000$)
	@ScholarshipMode VARCHAR(3), 			-- C'est le mode actuel des bourses (QUA = mode qualification, PMT = mode paiement)
	@ScholarshipYear INTEGER, 			-- C'est l'année de bourses qui est actuellement traité
	@GovernmentBN VARCHAR(75), 			-- C'est le ID de promoteur qu'a Universitas à la SCÉÉ
	@MaxRepRisk DECIMAL(10,4), 			-- C'est le pourcentage de commissions maximum toléré avant pénalité, si ce maximum est dépassé 
								-- alors le représentant ne ce fait pas tout payer, les avances spéciales sont remboursé par les commissions de services et les 
								-- avances sur résiliation sont remboursé par les avances et avances sur résiliation.  Le pourcentage de commissions c'est les 
								-- avances / les avances + la dépense de commissions
	@LastVerifDate DATETIME, 			-- C'est la date qui barre la base de données.  Aucune opération (Un_Oper) ne peut être inséré, 
								-- modifié ou supprimé si la date d'opération est inférieure ou égal à cette date.
	@MaxPostInForceDate INTEGER, 			-- On ne peut pas ajouter d'unités dont la date de vigueur est inférieur à la date du jour moins ce nombre de mois.
	@MaxSubscribeAmountAjustmentDiff MONEY, 	-- C'est le maximum d'écart qu'on peut mettre entre le montant souscrit réel et celui du relevé de dépôt.
	@ProjectionCount INTEGER, 			-- Nombre de projection de commission à faire par rapport au type de projection
	@ProjectionType SMALLINT, 			-- Type de projection <<Mensuel = 12, Trimestriel = 4, Semi-annuel = 2 et Annuel = 1>>
	@ProjectionOnNextRepTreatment SMALLINT, 	-- Détermine si on a commandé la projection de commission ou non
	@MaxFaceAmount MONEY, 				-- Maximum de capital assuré
	@StartDateForIntAfterEstimatedRI DATETIME, 	-- Détermine à partir de qu'elle date on calcul l'intérêt après la date de remboursement intégral estimée.
	@MonthNoIntAfterEstimatedRI INTEGER, 		-- Détermine le nombre de mois sans intérêt après la date de remboursement intégral estimée
	@CESGWaitingDays INTEGER, 			-- Délai administratif en jours
	@MonthBeforeNoNASNotice INTEGER, 		-- Nombre de mois qu'il faut ajouter à la date de vigueur avant l'envoi d'un avis de convention sans NAS
	@BusinessBonusLimit INTEGER, 			-- Nombre d'années après la date de vigueur des groupes d'unités avant l'expiration des bonis d'affaires.
	@DocMaxSizeInMeg INTEGER, 			-- Maximum en meg pour fichier word généré par la gestion des documents
	@tiCheckNbMonthBefore TINYINT,			-- Nombre de mois maximum pour les chèques pré datés.
	@tiCheckNbDayBefore TINYINT)			-- Nombre de jours maximum pour les chèques pré datés.
AS
BEGIN
	DECLARE 
		@iResult INTEGER
	-- Sauvegarde des options CRQ
	EXECUTE @iResult = SP_IU_CRQ_Def @DocMaxSizeInMeg

	IF @iResult > 0
		-- Sauvegarde des options UN
		UPDATE Un_Def SET
			MaxLifeCotisation = @MaxLifeCotisation,
			MaxYearCotisation = @MaxYearCotisation,
			MaxLifeGovernmentGrant = @MaxLifeGovernmentGrant,
			MaxYearGovernmentGrant = @MaxYearGovernmentGrant,
			ScholarshipMode = @ScholarshipMode,
			ScholarshipYear = @ScholarshipYear,
			GovernmentBN = @GovernmentBN,
			MaxRepRisk = @MaxRepRisk,
			LastVerifDate = @LastVerifDate,
			MaxPostInForceDate = @MaxPostInForceDate,
			MaxSubscribeAmountAjustmentDiff = @MaxSubscribeAmountAjustmentDiff,
			ProjectionCount = @ProjectionCount,
			ProjectionType = @ProjectionType,
			ProjectionOnNextRepTreatment = @ProjectionOnNextRepTreatment,
			MaxFaceAmount = @MaxFaceAmount,
			StartDateForIntAfterEstimatedRI = @StartDateForIntAfterEstimatedRI,
			MonthNoIntAfterEstimatedRI = @MonthNoIntAfterEstimatedRI,
			CESGWaitingDays = @CESGWaitingDays,
			MonthBeforeNoNASNotice = @MonthBeforeNoNASNotice,
			BusinessBonusLimit = @BusinessBonusLimit,
			tiCheckNbMonthBefore = @tiCheckNbMonthBefore,
			tiCheckNbDayBefore = @tiCheckNbDayBefore

	IF @@ERROR = 0 AND @iResult > 0
		RETURN 1 -- Pas d'erreur
	ELSE
		RETURN -1 -- Erreur
END


