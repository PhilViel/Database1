/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_MissingRHDSC
Description         :	Rapport des Formulaire RHDSC manquant (intégré au rapport "NAS Manquant")
Valeurs de retours  :	
Note                :	2009-10-08	Donald Huppé	Création

exec RP_UN_MissingRHDSC 1 ,'ALL', '2008-01-01' , '2010-12-31', 0
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_MissingRHDSC] (	
	@ConnectID INTEGER,
	@Type VARCHAR(3), -- Type de recherche 'ALL' = Tous les représentants, 'DIR' = Tous les représentants du directeur, 'REP' Représentant unique
	@StartDate DATETIME, -- Date de début de l'interval
	@EndDate DATETIME, -- Date de fin de l'interval
	@RepID INTEGER)
AS
BEGIN

	-- Préparation du filtre des représetants 
	CREATE TABLE #TB_Rep (
		RepID INTEGER PRIMARY KEY
	)

	IF @Type = 'ALL' -- Si tout les représentants
		INSERT INTO #TB_Rep
			SELECT 
				RepID
			FROM Un_Rep
	ELSE IF @Type = 'DIR' -- Si agence
		INSERT INTO #TB_Rep
			EXEC SL_UN_BossOfRep @RepID
	ELSE IF @Type = 'REP' -- Si un représentant
		INSERT INTO #TB_Rep
		VALUES (@RepID)

	SELECT 
		InForceDate = dbo.fn_Mo_DateNoTime(DT.InForceDate) , 
		C.ConventionNo, 
		bFormulaireRecu = 'Non',
		SubscriberName = HS.LastName + ', ' + HS.FirstName , 
		BeneficiaryName = HB.LastName + ', ' + HB.FirstName,
		Phone1 = dbo.fn_Mo_FormatPhoneNo(ISNULL(A.Phone1,''), ISNULL(A.CountryID,'CAN')) , 
		Rep = ISNULL(R.LastName,'') + ', ' + ISNULL(R.FirstName,''),
		T.Epargne , 
		T.Frais , 
		T.Unit
	FROM dbo.Un_Convention C 
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	JOIN dbo.Mo_Human HS ON S.SubscriberID = HS.HumanID
	JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
	JOIN #TB_Rep F ON F.RepID = S.RepID
	LEFT JOIN dbo.Mo_Human R ON R.HumanID = S.RepID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = HS.AdrID
	JOIN (
		SELECT 
			InForceDate = MIN(U.InForceDate), 
			SignatureDate = MIN(U.SignatureDate),
			U.ConventionID
		FROM dbo.Un_Unit U
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		WHERE InForceDate >= @StartDate
		  	AND InForceDate < @EndDate + 1
		  	AND ISNULL(TerminatedDate,0) <= 0 
		  	AND ISNULL(IntReimbDate,0) <= 0
		GROUP BY ConventionID
		) DT ON DT.ConventionID = C.ConventionID
	JOIN (
		SELECT 
			U.ConventionID,
			Epargne = SUM(ISNULL(Cotisation,0)), 
			Frais = SUM(ISNULL(Fee,0)), 
			Unit = COUNT(DISTINCT U.UnitID)
		FROM dbo.Un_Unit U 
		LEFT JOIN un_cotisation CO ON U.UnitID = Co.UnitID
		LEFT JOIN un_Oper O ON Co.operid = o.operid
		GROUP BY U.ConventionID
		) T ON DT.ConventionID = T.ConventionID 
	WHERE (C.bFormulaireRecu = 0)
	---(ISNULL(HS.SocialNumber, '') = '' OR ISNULL(HB.SocialNumber,'') = '')
	ORDER BY 
		DT.InForceDate, 
		HS.LastName, 
		HS.FirstName,
		C.ConventionNo

End


