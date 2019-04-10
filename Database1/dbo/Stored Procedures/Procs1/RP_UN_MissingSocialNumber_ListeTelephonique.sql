/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas Inc.
Nom                 :	RP_UN_MissingSocialNumber_ListeTelephonique
Description         :	Liste téléphonique du Rapport des numéros d'assurance social manquant

Exemple d'appel :
		EXECUTE dbo.RP_UN_MissingSocialNumber_ListeTelephonique 2, 'ALL', '2008-01-01', '2009-12-31', 0, ''

Valeurs de retours  :	
Note                :	2018-08-23	Donald Huppé	création 
						2018-10-12	Donald Huppé	jira prod 12435 : exclure les 20 ans et plus et les RIN

exec RP_UN_MissingSocialNumber_ListeTelephonique	 1,'ALL','2016-10-01','2018-08-31',0,'F'
									

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_MissingSocialNumber_ListeTelephonique] (	
												@ConnectID		INT,
												@Type			VARCHAR(3),		-- Type de recherche 'ALL' = Tous les représentants, 'DIR' = Tous les représentants du directeur, 'REP' Représentant unique
												@StartDate		DATETIME,		-- Date de début de l'interval
												@EndDate		DATETIME,		-- Date de fin de l'interval
												@RepID			INT = 0,		-- ID Unique du Rep
												@cTypeRapport	CHAR(1)	= NULL	-- Type de rapport
												)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	IF LTRIM(RTRIM(@cTypeRapport)) = ''
		BEGIN
			SET @cTypeRapport = NULL
		END

	SET @dtBegin = GETDATE()

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
	-- Fin de la préparation du filtre des représetants 

	CREATE table #TmpTable (
				SubscriberID INT,
				Langue varchar(1),
				ConventionID int,
				--InForceDate datetime,
				--DateVigueurLegale datetime,
				ConventionNo varchar(15), 
				SubscriberFirstName varchar(100) , 
				SubscriberLastName varchar(100), 
				--SubscriberName varchar(100) , 
				SubscriberSIN varchar(3),
				BeneficiaryID INT,
				BeneficiaryName varchar(100),
				BeneficiarySIN varchar(3),
				Phone1 varchar(25),
				PhoneCell varchar(25), 
				Rep varchar(100),
				--Epargne money, 
				--Frais money, 
				--Unit int,
				bFormulaireRecu varchar(3),
				NoSection int,
				LastName varchar(50), 
				FirstName varchar(35),
				SCEEAnnexeBPRespRequise varchar(3),
				SCEEAnnexeBPRespRecue varchar(3),
				SCEEAnnexeBTuteurRequise varchar(3),
				SCEEAnnexeBTuteurRecue varchar(3),
				SCEEAnnexeBConfTuteurRecue varchar(3),
				SCEEAnnexeBConfPRespRecue varchar(3)			
				)

	insert INTO #TmpTable
	SELECT		--2009-12-17 : NAS BENEFICIARE OU NAS SOUSCRIPTEUR ABSENT
		--InForceDate = dbo.fn_Mo_DateNoTime(DT.InForceDate) , 
		c.SubscriberID,
		Langue = CASE WHEN hs.LangID = 'ENU' THEN 'A' ELSE 'F' END,
		C.ConventionID,
		--InForceDate = /*DateVigueurLegale*/ dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID),
		C.ConventionNo, 
		SubscriberFirstName = HS.FirstName , 
		SubscriberLastName = HS.LastName,  
		SubscriberSIN  = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HS.SocialNumber, HS.IsCompany), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						 END,
		c.BeneficiaryID,
		BeneficiaryName = HB.LastName + ', ' + HB.FirstName,
		BeneficiarySIN = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HB.SocialNumber, ''), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						 END,
		Phone1 = ISNULL(telMaison.vcTelephone,''), 
		PhoneCell = ISNULL(telCell.vcTelephone,''), 
		--Phone1 = dbo.fn_Mo_FormatPhoneNo(ISNULL(telMaison.vcTelephone,''), ISNULL(Ad.cID_Pays,'CAN')) , 
		Rep = ISNULL(R.LastName,'') + ', ' + ISNULL(R.FirstName,''),
		--T.Epargne , 
		--T.Frais , 
		--T.Unit,
		bFormulaireRecu =	CASE	WHEN C.SCEEFormulaire93Recu = 0 THEN 'Non'
									ELSE 'Oui'
							END,
		NoSection	=	1 ,
		HS.LastName, 
		HS.FirstName,
		SCEEAnnexeBPRespRequise = CASE	WHEN C.SCEEAnnexeBPRespRequise = 0 THEN 'Non'
									ELSE 'Oui'
							END,
		SCEEAnnexeBPRespRecue = CASE	WHEN C.SCEEAnnexeBPRespRecue = 0 THEN 'Non'
									ELSE 'Oui'
							END,
		SCEEAnnexeBTuteurRequise = CASE	WHEN C.SCEEAnnexeBTuteurRequise = 0 THEN 'Non'
									ELSE 'Oui'
							END,
		SCEEAnnexeBTuteurRecue = CASE	WHEN C.SCEEAnnexeBTuteurRecue = 0 THEN 'Non'
									ELSE 'Oui'
							END,
		SCEEAnnexeBConfTuteurRecue = CASE	WHEN ISNULL(CAST(C.SCEEAnnexeBConfTuteurRecue AS INT),-1) = 1 THEN 'Oui'
									ELSE 'Non'
							END,
		SCEEAnnexeBConfPRespRecue = CASE	WHEN ISNULL(CAST(C.SCEEAnnexeBConfPRespRecue AS INT),-1) = 1 THEN 'Oui'
									ELSE 'Non'
							END
	FROM 
		Un_Convention C
		
		JOIN ( -- Un convention sans NAS est TRA (on fait ceci pour fitrer au maximum avant de filtrer finalement sur DateVigueurLegale)
			select 
				Cs.conventionid ,
				ccs.startdate,
				cs.ConventionStateID
			from 
				un_conventionconventionstate cs
				join (
					select 
					conventionid,
					startdate = max(startDate)
					from un_conventionconventionstate
					--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= '2011-10-31' -- Si je veux l'état à une date précise 
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						and cs.ConventionStateID in ('TRA') -- je veux les convention qui ont cet état
			) css on C.conventionid = css.conventionid
		
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		JOIN dbo.Mo_Human HS ON S.SubscriberID = HS.HumanID
		JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
		JOIN #TB_Rep F ON F.RepID = S.RepID
		JOIN dbo.Mo_Human R ON R.HumanID = S.RepID
		left join tblGENE_Adresse ad on hs.AdrID = ad.iID_Adresse
		left join tblGENE_Telephone telMaison on hs.HumanID = telMaison.iID_Source and getdate() BETWEEN telMaison.dtDate_Debut and isnull(telMaison.dtDate_Fin,'9999-12-31') and telMaison.iID_Type = 1 --and telMaison.bPublic = 1
		left join tblGENE_Telephone telCell on hs.HumanID = telCell.iID_Source and getdate() BETWEEN telCell.dtDate_Debut and isnull(telCell.dtDate_Fin,'9999-12-31') and telCell.iID_Type = 2 --and telMaison.bPublic = 1

			
	WHERE 

		(ISNULL(HS.SocialNumber, '') = '' OR ISNULL(HB.SocialNumber,'') = '')

	UNION ALL

	SELECT
		-- 2009-12-17 : FORMULAIRE NON RECU
		--InForceDate = dbo.fn_Mo_DateNoTime(DT.InForceDate) , 
		c.SubscriberID,
		Langue = CASE WHEN hs.LangID = 'ENU' THEN 'A' ELSE 'F' END,
		C.ConventionID,
		--InForceDate = /*DateVigueurLegale*/ dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID),
		C.ConventionNo, 
		SubscriberFirstName = HS.FirstName , 
		SubscriberLastName = HS.LastName,  
		SubscriberSIN  = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HS.SocialNumber, HS.IsCompany), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						 END,
		c.BeneficiaryID,
		BeneficiaryName = HB.LastName + ', ' + HB.FirstName,
		BeneficiarySIN = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HB.SocialNumber, ''), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						 END,
		Phone1 = ISNULL(telMaison.vcTelephone,''), 
		PhoneCell = ISNULL(telCell.vcTelephone,''),
		Rep = ISNULL(R.LastName,'') + ', ' + ISNULL(R.FirstName,''),
		--T.Epargne , 
		--T.Frais , 
		--T.Unit,
		bFormulaireRecu =	CASE	WHEN C.SCEEFormulaire93Recu = 0 THEN 'Non'
									ELSE 'Oui'
							END,
		NoSection = 2,
		HS.LastName, 
		HS.FirstName,
		SCEEAnnexeBPRespRequise = CASE	WHEN C.SCEEAnnexeBPRespRequise = 0 THEN 'Non'
									ELSE 'Oui'
							END,
		SCEEAnnexeBPRespRecue = CASE	WHEN C.SCEEAnnexeBPRespRecue = 0 THEN 'Non'
									ELSE 'Oui'
							END,
		SCEEAnnexeBTuteurRequise = CASE	WHEN C.SCEEAnnexeBTuteurRequise = 0 THEN 'Non'
									ELSE 'Oui'
							END,
		SCEEAnnexeBTuteurRecue = CASE	WHEN C.SCEEAnnexeBTuteurRecue = 0 THEN 'Non'
									ELSE 'Oui'
							END,
		SCEEAnnexeBConfTuteurRecue = CASE	WHEN ISNULL(CAST(C.SCEEAnnexeBConfTuteurRecue AS INT),-1) = 1 THEN 'Oui'
									ELSE 'Non'
							END,
		SCEEAnnexeBConfPRespRecue = CASE	WHEN ISNULL(CAST(C.SCEEAnnexeBConfPRespRecue AS INT),-1) = 1 THEN 'Oui'
									ELSE 'Non'
							END
	FROM 
		Un_Convention C
		JOIN ( 
			select 
				Cs.conventionid ,
				ccs.startdate,
				cs.ConventionStateID
			from 
				un_conventionconventionstate cs
				join (
					select 
					conventionid,
					startdate = max(startDate)
					from un_conventionconventionstate
					--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= '2011-10-31' -- Si je veux l'état à une date précise 
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
			) css on C.conventionid = css.conventionid
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		JOIN dbo.Mo_Human HS ON S.SubscriberID = HS.HumanID
		JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
		JOIN #TB_Rep F ON F.RepID = S.RepID
		JOIN dbo.Mo_Human R ON R.HumanID = S.RepID
		left join tblGENE_Adresse ad on hs.AdrID = ad.iID_Adresse
		left join tblGENE_Telephone telMaison on hs.HumanID = telMaison.iID_Source and getdate() BETWEEN telMaison.dtDate_Debut and isnull(telMaison.dtDate_Fin,'9999-12-31') and telMaison.iID_Type = 1 --and telMaison.bPublic = 1
		left join tblGENE_Telephone telCell on hs.HumanID = telCell.iID_Source and getdate() BETWEEN telCell.dtDate_Debut and isnull(telCell.dtDate_Fin,'9999-12-31') and telCell.iID_Type = 2 --and telMaison.bPublic = 1
			
	WHERE 
		c.bFormulaireRecu = 0

	UNION ALL

	SELECT
		c.SubscriberID,
		Langue = CASE WHEN hs.LangID = 'ENU' THEN 'A' ELSE 'F' END,
		C.ConventionID,
		C.ConventionNo, 
		SubscriberFirstName = HS.FirstName , 
		SubscriberLastName = HS.LastName, 
		SubscriberSIN  = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HS.SocialNumber, HS.IsCompany), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						 END,
		c.BeneficiaryID,
		BeneficiaryName = HB.LastName + ', ' + HB.FirstName,
		BeneficiarySIN = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HB.SocialNumber, ''), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						 END,
		Phone1 = ISNULL(telMaison.vcTelephone,''), 
		PhoneCell = ISNULL(telCell.vcTelephone,''),
		Rep = ISNULL(R.LastName,'') + ', ' + ISNULL(R.FirstName,''),
		bFormulaireRecu =	CASE	WHEN C.SCEEFormulaire93Recu = 0 THEN 'Non'
									ELSE 'Oui'
							END,
		NoSection = 3,
		HS.LastName, 
		HS.FirstName,
		SCEEAnnexeBPRespRequise = CASE	WHEN C.SCEEAnnexeBPRespRequise = 0 THEN 'Non'
									ELSE 'Oui'
							END,
		SCEEAnnexeBPRespRecue = CASE	WHEN C.SCEEAnnexeBPRespRecue = 0 THEN 'Non'
									ELSE 'Oui'
							END,
		SCEEAnnexeBTuteurRequise = CASE	WHEN C.SCEEAnnexeBTuteurRequise = 0 THEN 'Non'
									ELSE 'Oui'
							END,
		SCEEAnnexeBTuteurRecue = CASE	WHEN C.SCEEAnnexeBTuteurRecue = 0 THEN 'Non'
									ELSE 'Oui'
							END,
		SCEEAnnexeBConfTuteurRecue = CASE	WHEN ISNULL(CAST(C.SCEEAnnexeBConfTuteurRecue AS INT),-1) = 1 THEN 'Oui'
									ELSE 'Non'
							END,
		SCEEAnnexeBConfPRespRecue = CASE	WHEN ISNULL(CAST(C.SCEEAnnexeBConfPRespRecue AS INT),-1) = 1 THEN 'Oui'
									ELSE 'Non'
							END
	FROM 
		Un_Convention C
		JOIN ( 
			select 
				Cs.conventionid ,
				ccs.startdate,
				cs.ConventionStateID
			from 
				un_conventionconventionstate cs
				join (
					select 
					conventionid,
					startdate = max(startDate)
					from un_conventionconventionstate
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
			) css on C.conventionid = css.conventionid
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
		JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
		JOIN #TB_Rep F ON F.RepID = S.RepID
		JOIN dbo.Mo_Human R ON R.HumanID = S.RepID
		left join tblGENE_Adresse ad on hs.AdrID = ad.iID_Adresse
		left join tblGENE_Telephone telMaison on hs.HumanID = telMaison.iID_Source and getdate() BETWEEN telMaison.dtDate_Debut and isnull(telMaison.dtDate_Fin,'9999-12-31') and telMaison.iID_Type = 1 --and telMaison.bPublic = 1
		left join tblGENE_Telephone telCell on hs.HumanID = telCell.iID_Source and getdate() BETWEEN telCell.dtDate_Debut and isnull(telCell.dtDate_Fin,'9999-12-31') and telCell.iID_Type = 2 --and telMaison.bPublic = 1

	WHERE 
			(
			   (
				C.SCEEAnnexeBPRespRequise  = 1 
				AND ( C.SCEEAnnexeBPRespRecue  = 0	OR  ISNULL(CAST(SCEEAnnexeBConfPRespRecue AS INT),-1) = 0)
				) 
			OR  (
				C.SCEEAnnexeBTuteurRequise = 1 
				AND (C.SCEEAnnexeBTuteurRecue = 0	OR  ISNULL(CAST(SCEEAnnexeBConfTuteurRecue AS INT),-1) = 0)
				)
			)

	ORDER BY 
		NoSection,
		HS.LastName, 
		HS.FirstName,
		C.ConventionNo

	IF @cTypeRapport = 'F' 
		BEGIN
		UPDATE #TmpTable SET NoSection = 0
		END

	SELECT *
	FROM (
		SELECT DISTINCT 
			T.SubscriberID,
			Langue,
			InForceDate =dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(T.ConventionID),
			--ConventionNo, 

			SubscriberFirstName, 
			SubscriberLastName, 
			SubscriberSIN,
			BeneficiaryName,
			BeneficiarySIN,
			Phone1, 
			PhoneCell,
			--Rep,
			--Epargne, 
		--	Frais, 
		--	Unit,
			bFormulaireRecu,
			NoSection,
			t.LastName, 
			t.FirstName,
			--epg.SubscriberID,
			SCEEAnnexeBPRespRequise,
			SCEEAnnexeBPRespRecue,
			SCEEAnnexeBTuteurRequise,
			SCEEAnnexeBTuteurRecue,
			SCEEAnnexeBConfTuteurRecue,
			SCEEAnnexeBConfPRespRecue 
		FROM 
			#TmpTable T
			JOIN (
				SELECT 
					c1.SubscriberID,
					U.ConventionID,
					Epargne = SUM(ISNULL(Cotisation,0)), 
					Frais = SUM(ISNULL(Fee,0)), 
					Unit = COUNT(DISTINCT U.UnitID)
				FROM dbo.Un_Unit U 
				JOIN dbo.Un_Convention c1 on u.ConventionID = c1.ConventionID
				join (select distinct ConventionID from  #TmpTable) t on t.ConventionID = u.ConventionID
				JOIN un_cotisation CO ON U.UnitID = Co.UnitID
				JOIN un_Oper O ON Co.operid = o.operid
				GROUP BY U.ConventionID,c1.SubscriberID
				) epg ON epg.ConventionID = T.ConventionID 
			join Mo_Human hb on hb.HumanID = t.BeneficiaryID
			LEFT JOIN (
				SELECT DISTINCT C.ConventionID
				FROM dbo.Un_Convention C
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, @EndDate) RIN ON RIN.UnitID = U.UnitID
				WHERE 1=1
					AND ISNULL(RIN.iStatut_RIN, 0) IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
				) RIN ON RIN.ConventionID = t.ConventionID
		WHERE 1=1
			and dbo.fn_Mo_Age(hb.BirthDate,@EndDate) < 20
			AND RIN.ConventionID IS NULL
		) v
	WHERE v.InForceDate between @StartDate AND @EndDate
	ORDER BY 
		NoSection,
		InForceDate,
		LastName, 
		FirstName

END


