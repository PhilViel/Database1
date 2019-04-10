/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	psCONV_RapportEffetsRetournes basé sur (SL_UN_SearchConventionWithNSF)
Description         :	Recherche des conventions qui ont eu un NSF dans une période.
Valeurs de retours  :	Dataset :
					BankReturnFileName	VARCHAR(75)	Nom du fichier de retour de la banque
					Representant                    Nom du représentant
					ConventionID		INTEGER		ID de la convention.
					ConventionNo		VARCHAR(75)	Numéro de convention.
					SubscriberID		INTEGER		ID du souscripteur.
					Subscriber		VARCHAR(87)	Nom, prénom du souscripteur.
					Breaking 		VARCHAR(3)	Indique si la convention est en arrêt de paiement
					BankReturnTypeID	CHAR(3)		Code de 3 caractères indentifiant le type d'effet retourné
					Amount			MONEY		Montant du NSF
					NSFDate			DATETIME	Date de l'opération NSF
					WithdrawalDate		DATETIME	Date du prélèvement revenu en effet retourné
					phone1                          téléphone maison du souscripteur

Note                :	ADX0000831	IA	2006-04-06	Bruno Lapointe		Création
						2006-12-01	Alain Quirion		Optimisation
						2008-09-23	Josée Parent		Correction du calcul du montant pour ajouter les Intérêts.
						2013-07-17  Maxime Martel		ajout des champs representant et phone1 et ajuster la procédure
														pour le rapport dans proAcces
						exec psCONV_RapportEffetsRetournes '2012-07-17', '2013-07-17', 149602 ,2

						exec psCONV_rapportEffetsRetournes '2013-07-01', '2013-07-31', 439423, 149602
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psConv_RapportEffetsRetournes] (
	@StartDate DATETIME, 	-- Début de la période
	@EndDate DATETIME, 	-- Fin de la période
	@RepID INTEGER = 0, -- Limiter les résultats selon un représentant, 0 pour tous
	@UserID integer --id de la personne qui demande le rapport
	) 	
AS
BEGIN
	
	CREATE TABLE #TB_Rep (
			RepID INTEGER PRIMARY KEY)

	-- Insère tous les représentants sous un rep dans la table temporaire
	declare @rep bit = 0
			
	select @rep = count(distinct repid) from Un_Rep where @UserID = RepID

	if @rep = 1
	begin
		INSERT #TB_Rep
			EXEC SL_UN_BossOfRep @userID
		end
	else
	begin
		INSERT #TB_Rep
			select RepID from Un_Rep
	end

	if @RepID <> 0
	begin
		delete #TB_Rep where RepID <> @RepID
	end

	CREATE TABLE #tOperNSF(
		OperID INTEGER PRIMARY KEY)

	INSERT INTO #tOperNSF
		SELECT O.OperID
		FROM Un_Oper O
		WHERE O.OperTypeID = 'NSF'
			AND O.OperDate >= @StartDate
			AND O.OperDate < @EndDate + 1

	SELECT 
		@rep as estRep,
		RH.LastName + ', ' + RH.FirstName + ' (' + R.RepCode + ')' + CASE WHEN R.BusinessEnd IS NULL THEN '' ELSE ' (Inactif)' END as "Representant",
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
		WithdrawalDate = dbo.fn_Mo_DateNoTime(RO.OperDate),
		A.Phone1
	FROM #tOperNSF ONSF
	JOIN Un_Oper O ON O.OperID = ONSF.OperID 
	JOIN Un_Cotisation Ct ON O.OperID = Ct.OperID
	JOIN dbo.Un_Unit U ON Ct.UnitID = U.UnitID
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN dbo.Un_Subscriber Su ON Su.SubscriberID = C.SubscriberID
	JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
	JOIN dbo.Mo_Adr A ON A.AdrID = S.AdrID
	JOIN Mo_BankReturnLink BRL ON BRL.BankReturnCodeID = O.OperID
	JOIN Un_Oper RO ON RO.OperID = BRL.BankReturnSourceCodeID
	LEFT JOIN Mo_BankReturnFile BRF ON BRF.BankReturnFileID = BRL.BankReturnFileID
	LEFT JOIN Un_Breaking BRK ON BRK.ConventionID = C.ConventionID AND BRK.BreakingStartDate = BRF.BankReturnFileDate
	LEFT JOIN un_rep r on su.RepID = r.RepID 
	LEFT JOIN dbo.Mo_Human RH on r.RepID = rh.HumanID
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
	WHERE R.RepID in (select * from #TB_Rep)
	ORDER BY 
		ISNULL(BRF.BankReturnFileName,'Manuel'), 
		O.OperDate,
		C.ConventionNo, 
		S.LastName, 
		ISNULL(S.FirstName,'')

	DROP TABLE #tOperNSF

	-- FIN DES TRAITEMENTS
	RETURN 0
END


