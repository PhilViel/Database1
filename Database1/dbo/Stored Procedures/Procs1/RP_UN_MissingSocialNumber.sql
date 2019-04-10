/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_MissingSocialNumber
Description         :	Rapport des numéros d'assurance social manquant

Exemple d'appel :
		EXECUTE dbo.RP_UN_MissingSocialNumber 2, 'ALL', '2008-01-01', '2009-12-31', 0, ''

Valeurs de retours  :	
Note                :	ADX0000199	2004-06-14 	UP	Bruno Lapointe	
									2008-12-10  Patrick Robitaille		-	Afficher Oui/Non au lieu du NAS selon qu'il est
																			valide ou non et afficher le nom du bénéficiaire
									2009-12-16	Jean-François Gauthier	-	Ajout du paramètre concernant le type de rapport et de la colonne bFormulaireRecu
									2009-12-17	Jean-François Gauthier	-	Ajout du Union ALL et de la requête concernant le type 'F'
									2010-01-07	Jean-François Gauthier	-	Modification afin de mettre à NULL le paramètre @cTypeRapport s'il est passé à vide
									2010-08-05	Donald Huppé			-	Enlever les champs dupliqués dans le select
									2012-09-28	Donald Huppé			glpi 7338
									2014-08-15	Donald Huppé			glpi 12121 : Dans la section pour les formulaire manquant, sortir seulement les conv REE ou TRA
									2015-02-05	Donald Huppé			modifications pour améliorer performance : placer fnCONV_ObtenirEntreeVigueurObligationLegale à la fin, calcul de Epargne, Frais, unit à la fin
									2015-02-20	Donald Huppé			glpi 13616 : Ajout de SubscriberID
									2015-05-21	Donald Huppé			glpi 14644 : enlever la clause : and telMaison.bPublic = 1.  Ce champ est mis à 0 par erreur avec la propo. 
									2016-12-13  Maxime Martel           Ajout des champs annexe B pour le tuteur et principal responsable
									2017-05-30	Donald Huppé			jira prod-5048 : Ajout de SCEEAnnexeBConfTuteurRecue et SCEEAnnexeBConfPRespRecue
									2017-06-05	Donald Huppé			Ajustement de SCEEAnnexeBConfTuteurRecue et SCEEAnnexeBConfPRespRecue. On met Oui si 0, sinon on met Non. Càd :  NULL ne veut pas dire Non
exec RP_UN_MissingSocialNumber 1,'ALL','2016-01-01','2017-01-23',0,'F'
exec RP_UN_MissingSocialNumber 1,'REP','2017-05-01','2017-06-01',149653,'F'
									
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_MissingSocialNumber] (	
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
				ConventionID int,
				--InForceDate datetime,
				--DateVigueurLegale datetime,
				ConventionNo varchar(15), 
				SubscriberName varchar(100) , 
				SubscriberSIN varchar(3),
				BeneficiaryName varchar(100),
				BeneficiarySIN varchar(3),
				Phone1 varchar(25), 
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
		C.ConventionID,
		--InForceDate = /*DateVigueurLegale*/ dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID),
		C.ConventionNo, 
		SubscriberName = HS.LastName + ', ' + HS.FirstName , 
		SubscriberSIN  = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HS.SocialNumber, HS.IsCompany), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						 END,
		BeneficiaryName = HB.LastName + ', ' + HB.FirstName,
		BeneficiarySIN = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HB.SocialNumber, ''), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						 END,
		Phone1 = dbo.fn_Mo_FormatPhoneNo(ISNULL(telMaison.vcTelephone,''), ISNULL(Ad.cID_Pays,'CAN')) , 
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

		--LEFT JOIN dbo.Mo_Human R ON R.HumanID = S.RepID
		--LEFT JOIN dbo.Mo_Adr A ON A.AdrID = HS.AdrID
		--JOIN (
		--	SELECT 
		--		U.ConventionID,
		--		Epargne = SUM(ISNULL(Cotisation,0)), 
		--		Frais = SUM(ISNULL(Fee,0)), 
		--		Unit = COUNT(DISTINCT U.UnitID)
		--	FROM dbo.Un_Unit U 
		--	LEFT JOIN un_cotisation CO ON U.UnitID = Co.UnitID
		--	LEFT JOIN un_Oper O ON Co.operid = o.operid
		--	GROUP BY U.ConventionID) T ON C.ConventionID = T.ConventionID 
			
	/*	
		JOIN (
			SELECT 
				InForceDate = MIN(U.InForceDate), 
				SignatureDate = MIN(U.SignatureDate),
				U.ConventionID
			FROM dbo.Un_Unit U
			JOIN Un_Modal M ON M.ModalID = U.ModalID
			WHERE 1=1
				--AND InForceDate >= @StartDate
  				--AND InForceDate < @EndDate + 1
  				AND ISNULL(TerminatedDate,0) <= 0 
  				AND ISNULL(IntReimbDate,0) <= 0
			GROUP BY ConventionID) DT ON DT.ConventionID = C.ConventionID
	*/		
			
	WHERE 

		(ISNULL(HS.SocialNumber, '') = '' OR ISNULL(HB.SocialNumber,'') = '')

	UNION ALL

	SELECT
		-- 2009-12-17 : FORMULAIRE NON RECU
		--InForceDate = dbo.fn_Mo_DateNoTime(DT.InForceDate) , 
		C.ConventionID,
		--InForceDate = /*DateVigueurLegale*/ dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID),
		C.ConventionNo, 
		SubscriberName = HS.LastName + ', ' + HS.FirstName , 
		SubscriberSIN  = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HS.SocialNumber, HS.IsCompany), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						 END,
		BeneficiaryName = HB.LastName + ', ' + HB.FirstName,
		BeneficiarySIN = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HB.SocialNumber, ''), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						 END,
		Phone1 = dbo.fn_Mo_FormatPhoneNo(ISNULL(telMaison.vcTelephone,''), ISNULL(Ad.cID_Pays,'CAN')) , 
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

		--LEFT JOIN dbo.Mo_Adr A ON A.AdrID = HS.AdrID

		--JOIN (
		--	SELECT 
		--		U.ConventionID,
		--		Epargne = SUM(ISNULL(Cotisation,0)), 
		--		Frais = SUM(ISNULL(Fee,0)), 
		--		Unit = COUNT(DISTINCT U.UnitID)
		--	FROM dbo.Un_Unit U 
		--	LEFT JOIN un_cotisation CO ON U.UnitID = Co.UnitID
		--	LEFT JOIN un_Oper O ON Co.operid = o.operid
		--	GROUP BY U.ConventionID) T ON c.ConventionID = T.ConventionID 
	/*		
		JOIN (
			SELECT 
				InForceDate = MIN(U.InForceDate), 
				SignatureDate = MIN(U.SignatureDate),
				U.ConventionID
			FROM dbo.Un_Unit U
			JOIN Un_Modal M ON M.ModalID = U.ModalID
			WHERE 1=1
				--AND InForceDate >= @StartDate
  				--AND InForceDate < @EndDate + 1
				AND ISNULL(TerminatedDate,0) <= 0 
				AND ISNULL(IntReimbDate,0) <= 0
			GROUP BY ConventionID) DT ON DT.ConventionID = C.ConventionID
	*/
			
	WHERE 
		c.bFormulaireRecu = 0
	
	UNION ALL

	SELECT
		
		C.ConventionID,
		C.ConventionNo, 
		SubscriberName = HS.LastName + ', ' + HS.FirstName , 
		SubscriberSIN  = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HS.SocialNumber, HS.IsCompany), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						 END,
		BeneficiaryName = HB.LastName + ', ' + HB.FirstName,
		BeneficiarySIN = CASE
							WHEN dbo.FN_CRI_CheckSin(ISNULL(HB.SocialNumber, ''), 0) = 1 THEN
								'Oui'
							ELSE
								'Non'
						 END,
		Phone1 = dbo.fn_Mo_FormatPhoneNo(ISNULL(telMaison.vcTelephone,''), ISNULL(Ad.cID_Pays,'CAN')) , 
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
	WHERE 
		   (
			C.SCEEAnnexeBPRespRequise  = 1 
			AND ( C.SCEEAnnexeBPRespRecue  = 0	OR  ISNULL(CAST(SCEEAnnexeBConfPRespRecue AS INT),-1) = 0)
			) 
		OR  (
			C.SCEEAnnexeBTuteurRequise = 1 
			AND (C.SCEEAnnexeBTuteurRecue = 0	OR  ISNULL(CAST(SCEEAnnexeBConfTuteurRecue AS INT),-1) = 0)
			)
		--OR  SCEEAnnexeBConfTuteurRecue = 0
		--OR  SCEEAnnexeBConfPRespRecue  = 0
	ORDER BY 
		NoSection,
		HS.LastName, 
		HS.FirstName,
		C.ConventionNo

	IF @cTypeRapport = 'F' 
		BEGIN
		UPDATE #TmpTable SET NoSection = 0
		END

	SELECT DISTINCT 
		InForceDate =dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(T.ConventionID),
		ConventionNo, 
		SubscriberName, 
		SubscriberSIN,
		BeneficiaryName,
		BeneficiarySIN,
		Phone1, 
		Rep,
		Epargne, 
		Frais, 
		Unit,
		bFormulaireRecu,
		NoSection,
		LastName, 
		FirstName,
		epg.SubscriberID,
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
	WHERE dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(T.ConventionID) between @StartDate AND @EndDate
	ORDER BY 
		NoSection,
		dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(T.ConventionID),
		LastName, 
		FirstName,
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
				'Rapport des NAS manquants selon le type : ' + CAST(@Type AS VARCHAR) + ' entre le ' + CAST(@StartDate AS VARCHAR) + ' et le ' + CAST(@EndDate AS VARCHAR),
				'RP_UN_MissingSocialNumber',
				'EXECUTE RP_UN_MissingSocialNumber @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @Type ='+CAST(@Type AS VARCHAR)+
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+
				', @EndDate ='+CAST(@EndDate AS VARCHAR)+	
				', @RepID ='+CAST(@RepID AS VARCHAR)
	END	
END


