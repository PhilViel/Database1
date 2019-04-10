/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_c_dev_rin
Nom du service		: Générer la lettre de devancement de rin 
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_c_dev_rin 'U-20090128015', 0
						EXEC psCONV_RapportLettre_le_c_dev_rin 'U-20031204038, U-20060111018', 0
						EXEC psCONV_RapportLettre_le_c_dev_rin 'C-20020128001', 0


Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2018-12-11		Donald Huppé						Création du service
		2018-12-20		Donald Huppé						Correction lorsque plus qu'un RIN par gr. d'unité
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_c_dev_rin] 
	@ListeConv varchar(max),
	@INC MONEY
AS
BEGIN
	DECLARE
		@today datetime,
		@SubscriberID integer,
		@nbSouscripteur integer,
		@nbBeneficiaire integer,
		@nbConvListe integer,
		@nbConv integer
			
	set @today = GETDATE()


	SET @ListeConv = UPPER(LTRIM(RTRIM(ISNULL(@ListeConv,''))))

	CREATE TABLE #tbConv (
		ConventionNo varchar(15) PRIMARY KEY)

	INSERT INTO #tbConv (ConventionNo)
		SELECT Val
		FROM fn_Mo_StringTable(@ListeConv)

	SELECT @nbConvListe = count(*) FROM #tbConv
	select @nbConv = count(*) FROM dbo.Un_Convention c join #tbConv t ON c.ConventionNo = t.ConventionNo

	if @nbConvListe = @nbConv
	begin
		SELECT 
			@nbSouscripteur = count(DISTINCT c.SubscriberID),
			@nbBeneficiaire = count(DISTINCT c.BeneficiaryID)
		FROM dbo.Un_Convention c join #tbConv t ON c.ConventionNo = t.ConventionNo 
	end
	else
	BEGIN
		set @nbSouscripteur = 0
	END

	SELECT @SubscriberID = MAX(c.SubscriberID)
	FROM dbo.Un_Convention c 
	JOIN #tbConv t ON c.ConventionNo = t.ConventionNo 

	SELECT
		C.ConventionNo

		,MontantSouscrit = SUM(CONVERT(MONEY, (ROUND( (U.UnitQty) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment))
		,MontantSouscrit_Periodique = SUM(
			CONVERT(
				MONEY, CASE WHEN M.PmtQty > 1 THEN  (ROUND( (U.UnitQty) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment ELSE 0 END
				)
			)
		,MontantDepot_Periodique = SUM(CASE WHEN M.PmtQty > 1 THEN ROUND( (U.UnitQty) * M.PmtRate,2) ELSE 0 END)
		,DateRIOriginale = MAX(dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, NULL))
		,DateRINReel = MAX(DateRINReel)
		,MontantRIN = -SUM(UniteMontantRIN)
		,MontantRIN_Periodique = -SUM(CASE WHEN M.PmtQty > 1 THEN UniteMontantRIN ELSE 0 END)

		,NbDepotRestant = CASE 
						WHEN SUM(CASE WHEN M.PmtQty > 1 THEN ROUND( (U.UnitQty) * M.PmtRate,2) ELSE 0 END) > 0 THEN
							 (
							--MS.MontantSouscrit_Periodique 
							SUM(
								CONVERT(
									MONEY, CASE WHEN M.PmtQty > 1 THEN  (ROUND( (U.UnitQty) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment ELSE 0 END
									)
								)
							- 
							--MS.MontantRIN_Periodique
							(-SUM(CASE WHEN M.PmtQty > 1 THEN UniteMontantRIN ELSE 0 END))
							) 
							/ 
							--MS.MontantDepot_Periodique
							SUM(CASE WHEN M.PmtQty > 1 THEN ROUND( (U.UnitQty) * M.PmtRate,2) ELSE 0 END)
						ELSE 0
						END
	INTO #MS
	FROM 
		Un_Convention C
		JOIN #tbConv T ON T.ConventionNo = C.ConventionNo
		JOIN Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN (
			SELECT U1.UnitID, UniteMontantRIN = SUM(CT1.Cotisation + CT1.Fee), DateRINReel = MAX(O1.OperDate)
			FROM 
				Un_Convention C1
				JOIN #tbConv T1 ON T1.ConventionNo = C1.ConventionNo
				JOIN Un_Unit U1 ON U1.ConventionID = C1.ConventionID
				JOIN Un_Modal M1 ON M1.ModalID = U1.ModalID
				JOIN Un_Plan P1 ON P1.PlanID = C1.PlanID
				JOIN Un_Cotisation CT1 ON CT1.UnitID = U1.UnitID
				JOIN Un_Oper O1 ON O1.OperID = CT1.OperID
			WHERE O1.OperTypeID = 'RIN'
			GROUP by u1.UnitID
			)RIN ON RIN.UnitID = U.UnitID
	WHERE 1=1
	GROUP BY c.conventionno

	SELECT distinct
		humanID = S.SubscriberID,
		Adresse = ad.Address,
		Ville = ad.City,
		CodePostal = dbo.fn_Mo_FormatZIP( ad.ZipCode,ad.CountryID),
		Province = ad.StateName,
		SouscNom = HS.LastName,
		SouscPrenom = HS.FirstName,
		Langue = HS.LangID,
		AppelLong = sex.LongSexName,
		AppelCourt = sex.ShortSexName,
		HS.SexID,
		nomRep = HR.firstName + ' ' + HR.lastName,
		sexRep = HR.SexID,
		nbConv = @nbConv,
		NbSouscripteur = @nbSouscripteur,
		NbBeneficiaire = @nbBeneficiaire,

		MS.MontantSouscrit,
		MS.DateRIOriginale,
		DateRIOriginale_TXT = dbo.fn_mo_DateToLongDateStr(MS.DateRIOriginale,HS.LangID),
		
		MS.DateRINReel,
		DateRINReel_TXT = dbo.fn_mo_DateToLongDateStr(MS.DateRINReel,HS.LangID),
		MS.MontantRIN,
		MS.NbDepotRestant,

		noConv = (SELECT STUFF((    SELECT ', ' + t.ConventionNo  AS [text()]
                        FROM #tbConv t 
						JOIN dbo.Un_Convention c ON t.ConventionNo = c.ConventionNo 
						JOIN dbo.Mo_Human h	ON c.BeneficiaryID = h.HumanID  
						FOR XML PATH('')
                        ), 1, 2, '' )
					) + 
					(SELECT (    SELECT DISTINCT  ' (' + h.FirstName + ')'  AS [text()]
                        FROM #tbConv t 
						JOIN dbo.Un_Convention c ON t.ConventionNo = c.ConventionNo 
						JOIN dbo.Mo_Human h	ON c.BeneficiaryID = h.HumanID  
						FOR XML PATH('')
                        )
					) ,
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](s.SubscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case HS.langID when 'FRA' then '_le_c_dev_rin' when 'ENU' then '_le_c_dev_rin_ang' end
	FROM dbo.Un_Subscriber S
	JOIN (
		SELECT
			MontantSouscrit = SUM(MontantSouscrit),
			DateRIOriginale = MAX(DateRIOriginale),
			DateRINReel = MAX(DateRINReel),
			MontantRIN = SUM(MontantRIN),
			NbDepotRestant = MAX(NbDepotRestant)
		FROM #MS
			) MS ON 1=1
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	JOIN Mo_Sex sex ON sex.SexID = HS.SexID AND sex.LangID = HS.LangID
	JOIN Mo_Adr ad on ad.AdrID = HS.AdrID
	JOIN dbo.Mo_Human HR on S.RepID = HR.HumanID
	WHERE S.SubscriberID = @SubscriberID


END