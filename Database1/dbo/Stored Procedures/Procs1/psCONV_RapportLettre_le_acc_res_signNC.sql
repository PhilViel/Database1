/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_acc_res_signNC
Nom du service		: Générer la lettre de résiliaton le_acc_res_signNC
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportLettre_le_acc_res_signNC 'U-20091203068,R-20091203092,R-20091223049'


Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2018-12-07		Donald Huppé						Création du service
		2018-12-10		Donald Huppé						Ajout de NbBenef et ListeBenef
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_acc_res_signNC] 
	@ListeConv varchar(max)
AS
BEGIN
	DECLARE
		@today datetime,
		@SubscriberID integer,
		@nbSouscripteur integer,
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
		SELECT @nbSouscripteur = count(DISTINCT c.SubscriberID)
		FROM dbo.Un_Convention c join #tbConv t ON c.ConventionNo = t.ConventionNo 
	end
	else
	BEGIN
		set @nbSouscripteur = 0
	END

	SELECT @SubscriberID = MAX(c.SubscriberID)
	FROM dbo.Un_Convention c 
	JOIN #tbConv t ON c.ConventionNo = t.ConventionNo 


	CREATE TABLE #tbFrais (
		SoldeFrais MONEY
			)

	-- Retrouver les RES
	INSERT INTO #tbFrais
	SELECT
		SoldeFrais = SUM(ct.Fee)
	FROM Un_Unit U
	JOIN Un_Convention c on u.ConventionID = c.ConventionID
	JOIN #tbConv T ON T.ConventionNo = C.ConventionNo
	JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID

	SELECT distinct
		humanID = S.SubscriberID,
		Adresse = ad.Address,
		Ville = ad.City,
		CodePostal = dbo.fn_Mo_FormatZIP( ad.ZipCode,ad.CountryID),
		Province = ad.StateName,
		SouscNom = HS.LastName,
		SouscPrenom = HS.FirstName,
		Langue = HS.LangID,
		appelLong = sex.LongSexName,
		appelCourt = sex.ShortSexName,
		HS.SexID,
		nomRep = HR.firstName + ' ' + HR.lastName,
		sexRep = HR.SexID,
		NbConv = @nbConv,
		NbSouscripteur = @nbSouscripteur,
		NbUnite,
		MontantFraisTheorique = NbUnite * 200,
		SoldeFrais,
		DateLimite = DATEADD(MONTH,1,GETDATE()),
		noConv = (SELECT STUFF((    SELECT ', ' + t.ConventionNo + ' (' + h.FirstName + ')'  AS [text()]
                        FROM #tbConv t 
						JOIN dbo.Un_Convention c ON t.ConventionNo = c.ConventionNo 
						JOIN dbo.Mo_Human h	ON c.BeneficiaryID = h.HumanID  
						ORDER BY C.BeneficiaryID
						FOR XML PATH('')
                        ), 1, 2, '' )
					),
		noConvOnly = (SELECT STUFF((    SELECT ', ' + t.ConventionNo  AS [text()]
                        FROM #tbConv t 
						JOIN dbo.Un_Convention c ON t.ConventionNo = c.ConventionNo 
						JOIN dbo.Mo_Human h	ON c.BeneficiaryID = h.HumanID  
						FOR XML PATH('')
                        ), 1, 2, '' )
					),
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](s.SubscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','')
							+ case HS.langID when 'FRA' then '_le_acc_res_signNC' when 'ENU' then '_le_acc_res_signNC_ang' end,
		NbBenef,
		ListeBenef = (SELECT (    SELECT DISTINCT  ' (' + h.FirstName + ')'  AS [text()]
                        FROM #tbConv t 
						JOIN dbo.Un_Convention c ON t.ConventionNo = c.ConventionNo 
						JOIN dbo.Mo_Human h	ON c.BeneficiaryID = h.HumanID  
						--ORDER BY C.BeneficiaryID
						FOR XML PATH('')
                        )
					)
	FROM dbo.Un_Subscriber S
	--JOIN Un_Convention C ON C.SubscriberID = S.SubscriberID
	--JOIN #tbConv T ON T.ConventionNo = C.ConventionNo
	JOIN dbo.Mo_Human HS on S.SubscriberID = HS.HumanID
	JOIN Mo_Sex sex ON sex.SexID = HS.SexID AND sex.LangID = HS.LangID
	JOIN Mo_Adr ad on ad.AdrID = HS.AdrID
	JOIN dbo.Mo_Human HR on S.RepID = HR.HumanID
	JOIN (
			SELECT NbUnite = SUM(U1.UnitQty), NbBenef = COUNT(DISTINCT C1.BeneficiaryID)
			FROM UN_UNIT U1
			JOIN Un_Convention C1 ON C1.ConventionID = U1.ConventionID
			JOIN #tbConv T ON T.ConventionNo = C1.ConventionNo
		) n on 1=1
	JOIN #tbFrais F ON 1=1
	WHERE S.SubscriberID = @SubscriberID


END


