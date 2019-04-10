/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchConventionWithNSF
Description         :	Recherche des conventions qui ont eu un NSF dans une période.
Valeurs de retours  :	Dataset :
					BankReturnFileName	VARCHAR(75)	Nom du fichier de retour de la banque
					ConventionID		INTEGER		ID de la convention.
					ConventionNo		VARCHAR(75)	Numéro de convention.
					SubscriberID		INTEGER		ID du souscripteur.
					Subscriber		VARCHAR(87)	Nom, prénom du souscripteur.
					Breaking 		VARCHAR(3)	Indique si la convention est en arrêt de paiement
					BankReturnTypeID	CHAR(3)		Code de 3 caractères indentifiant le type d'effet retourné
					Amount			MONEY		Montant du NSF
					NSFDate			DATETIME	Date de l'opération NSF
					WithdrawalDate		DATETIME	Date du prélèvement revenu en effet retourné

Note                :	ADX0000831	IA	2006-04-06	Bruno Lapointe		Création
						2006-12-01	Alain Quirion		Optimisation
						2008-09-23	Josée Parent		Correction du calcul du montant pour ajouter les Intérêts.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchConventionWithNSF] (
	@ConnectID INTEGER,
	@FromDate DATETIME, 	-- Début de la période
	@ToDate DATETIME, 	-- Fin de la période
	@RepID INTEGER = 0) 	-- Limiter les résultats selon un représentant, 0 pour tous
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT

	SET @dtBegin = GETDATE()

	CREATE TABLE #TB_Rep (
		RepID INTEGER PRIMARY KEY)

	-- Insère tous les représentants sous un rep dans la table temporaire
	INSERT #TB_Rep
		EXEC SL_UN_BossOfRep @RepID

	CREATE TABLE #tOperNSF(
		OperID INTEGER PRIMARY KEY)

	INSERT INTO #tOperNSF
		SELECT O.OperID
		FROM Un_Oper O
		WHERE O.OperTypeID = 'NSF'
			AND O.OperDate >= @FromDate
			AND O.OperDate < @ToDate + 1

	SELECT 
		BankReturnFileName = ISNULL(BRF.BankReturnFileName,'Manuel'),
		C.ConventionID, 
		C.ConventionNo,
		C.SubscriberID,
		Subscriber =
			CASE 
				WHEN S.IsCompany = 1 THEN S.LastName
				ELSE S.LastName + ', ' + S.FirstName
			END,
		Breaking =
			CASE ISNULL(Brk.ConventionID,0)
				WHEN 0 THEN 'NO'
				ELSE 'YES'
			END,
		BRL.BankReturnTypeID,
		Amount = Ct.Cotisation + Ct.Fee + Ct.SubscInsur + Ct.BenefInsur + Ct.TaxOnInsur + ISNULL(INC.Interests,0),
		NSFDate = dbo.fn_Mo_DateNoTime(O.OperDate),
		WithdrawalDate = dbo.fn_Mo_DateNoTime(RO.OperDate)
	FROM #tOperNSF ONSF
	JOIN Un_Oper O ON O.OperID = ONSF.OperID 
	JOIN Un_Cotisation Ct ON O.OperID = Ct.OperID
	JOIN dbo.Un_Unit U ON Ct.UnitID = U.UnitID
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN dbo.Un_Subscriber Su ON Su.SubscriberID = C.SubscriberID
	JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
	JOIN Mo_BankReturnLink BRL ON BRL.BankReturnCodeID = O.OperID
	JOIN Un_Oper RO ON RO.OperID = BRL.BankReturnSourceCodeID
	LEFT JOIN Mo_BankReturnFile BRF ON BRF.BankReturnFileID = BRL.BankReturnFileID
	LEFT JOIN Un_Breaking BRK ON BRK.ConventionID = C.ConventionID AND BRK.BreakingStartDate = BRF.BankReturnFileDate
	LEFT JOIN #TB_Rep B ON Su.RepID = B.RepID --OR @RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
	--LEFT JOIN Un_ConventionOper CO ON CO.OperID = O.OperID
	LEFT JOIN ( --Ajouter les intérêts INC - Josée Parent
		SELECT
			CO.ConventionID,
			CO.OperID,
			Interests = SUM(CO.ConventionOperAmount)
		FROM Un_ConventionOper CO
		WHERE CO.ConventionOperTypeID = 'INC'
		GROUP BY 
			CO.ConventionID,
			CO.OperID
		) INC ON INC.ConventionID = C.ConventionID AND INC.OperID = O.OperID
	WHERE B.RepID IS NOT NULL OR @RepID = 0
	ORDER BY 
		ISNULL(BRF.BankReturnFileName,'Manuel'), 
		O.OperDate,
		C.ConventionNo, 
		S.LastName, 
		ISNULL(S.FirstName,'')

	SET @dtEnd = GETDATE()
	SELECT @siTraceSearch = siTraceSearch FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceSearch
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
				1,				
				DATEDIFF(SECOND, @dtBegin, @dtEnd),
				@dtBegin,
				@dtEnd,
				'Recherche de convention avec effet retourné entre le '+ CAST(@FromDate AS VARCHAR) + ' et le ' + CAST(@ToDate AS VARCHAR),
				'SL_UN_SearchConventionWithNSF',
				'EXECUTE SL_UN_SearchConventionWithNSF @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
					', @FromDate ='+CAST(@FromDate AS VARCHAR)+	
					', @ToDate ='+CAST(@ToDate AS VARCHAR)+	
					', @RepID ='+CAST(@RepID AS VARCHAR)
	END	

	DROP TABLE #tOperNSF

	-- FIN DES TRAITEMENTS
	RETURN 0
END


