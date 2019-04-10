/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_SubAndBenByAdr
Description         :	Procédure stockée du rapport : Liste des adresses avec le nom des souscripteurs et des bénéficiaires (ancien rapport Excel de MacrosListesClientsBilingue.xls)
Valeurs de retours  :	Dataset
Note                :	Donald Huppé	Création	2009-11-24
						Maxime Martel	ajout de l'option "tous" pour les directeurs des agences 2013-08-07
exec GU_RP_SubAndBenByAdr2 1, 149551, 149602

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_SubAndBenByAdr] (	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@RepID INTEGER,
	@userID integer = null ) -- Limiter les résultats selon un représentant ou un directeur
AS
BEGIN

	create table #tb_rep (
		repID integer primary key)
	
	declare @rep bit = 0

	if @userID is not null
	begin
		-- Insère tous les représentants sous un rep dans la table temporaire			
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

	end
	else
	begin
		if @RepID <> 0
		begin
			insert into #tb_rep
				exec sl_un_bossofRep @repId
		end
		else
		begin
			insert into #tb_rep
				select repid from un_rep
		end
	end

	-- Les souscripteurs
	SELECT  
		R.RepCode, 
		RLastName = HR.LastName , 
		RFirstName = HR.FirstName ,
		-- Le rang du souscripteur par adresse - sert à la colonne souscripteur dans le tableau croisé 
		RANKSub = RANK() OVER (PARTITION BY 
										SAdr.Address,
										SUBSTRING(replace(replace(SAdr.ZipCode,' ',''),'-',''),1,3) + ' ' + SUBSTRING(replace(replace(SAdr.ZipCode,' ',''),'-',''),4,3)
								ORDER BY 
										s.subscriberid),
		s.subscriberid,
		SLastName = HS.LastName, 
		SFirstName = HS.FirstName , 
		SAddress = SAdr.Address , 
		SCity = SAdr.City, 
		SStateName = SAdr.StateName, 
		SZipCode = SUBSTRING(replace(replace(SAdr.ZipCode,' ',''),'-',''),1,3) + ' ' + SUBSTRING(replace(replace(SAdr.ZipCode,' ',''),'-',''),4,3),
		SPhone1 = SAdr.Phone1,
		SPhone2 = SAdr.Phone2,
		SLangName = CASE SLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(SLang.LangName, 'Unknown') END
	into #tmpSous
	FROM dbo.Un_Convention C 
		JOIN (
			SELECT 
				Cs.conventionid ,
				ccs.startdate,
				cs.ConventionStateID
			FROM 
				un_conventionconventionstate cs
				JOIN (
					SELECT 
					conventionid,
					startdate = max(startDate)
					FROM un_conventionconventionstate
					GROUP BY conventionid
					) ccs ON ccs.conventionid = cs.conventionid 
						AND ccs.startdate = cs.startdate 
						AND cs.ConventionStateID in ('REE','TRA')
			) css ON css.conventionid = c.conventionid
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		JOIN dbo.Mo_Human HS ON S.SubscriberID = HS.HumanID
		JOIN dbo.Mo_Adr SAdr ON HS.AdrID = SAdr.AdrID 
		JOIN Un_Rep R ON S.RepID = R.RepID 
		JOIN #tb_rep rr ON r.repid = rr.repid
		JOIN dbo.Mo_Human HR ON R.RepID = HR.HumanID
		LEFT JOIN Mo_Lang SLang ON HS.LangID = SLang.LangID
	WHERE S.AddressLost = 0
	GROUP BY
		s.subscriberid,
		HS.LastName, 
		HS.FirstName , 
		SAdr.Address , 
		SAdr.City, 
		SAdr.StateName, 
		SUBSTRING(replace(replace(SAdr.ZipCode,' ',''),'-',''),1,3) + ' ' + SUBSTRING(replace(replace(SAdr.ZipCode,' ',''),'-',''),4,3),
		SAdr.Phone1,
		SAdr.Phone2,
		CASE SLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(SLang.LangName, 'Unknown') END, 
		R.RepCode, 
		HR.LastName , 
		HR.FirstName , 
		R.RepID

	-- Les bénéficiaires
	SELECT  
		R.RepCode, 
		RLastName = HR.LastName , 
		RFirstName = HR.FirstName ,
		-- Le rang du bénéficiaire par adresse - sert à la colonne bénéficiaire dans le tableau croisé 
		RANKBen = RANK() OVER (PARTITION BY 
										BAdr.Address,
										SUBSTRING(replace(replace(BAdr.ZipCode,' ',''),'-',''),1,3) + ' ' + SUBSTRING(replace(replace(BAdr.ZipCode,' ',''),'-',''),4,3) 
								ORDER BY 
										C.BeneficiaryId),
		C.BeneficiaryId,
		BFirstName = HB.FirstName,
		BLastName = HB.LastName,
		BAddress = BAdr.Address , 
		BCity = BAdr.City, 
		BStateName = BAdr.StateName, 
		BZipCode = SUBSTRING(replace(replace(BAdr.ZipCode,' ',''),'-',''),1,3) + ' ' + SUBSTRING(replace(replace(BAdr.ZipCode,' ',''),'-',''),4,3),
		BPhone1 = BAdr.Phone1,
		BPhone2 = BAdr.Phone2,
		BLangName = CASE BLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(BLang.LangName, 'Unknown') END
	into #tmpBen
	FROM dbo.Un_Convention C 
		JOIN (
			SELECT 
				Cs.conventionid ,
				ccs.startdate,
				cs.ConventionStateID
			FROM 
				un_conventionconventionstate cs
				JOIN (
					SELECT 
					conventionid,
					startdate = max(startDate)
					FROM un_conventionconventionstate
					GROUP BY conventionid
					) ccs ON ccs.conventionid = cs.conventionid 
						AND ccs.startdate = cs.startdate 
						AND cs.ConventionStateID in ('REE','TRA') 
			) css ON css.conventionid = c.conventionid
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		JOIN dbo.Mo_Human HB ON C.BeneficiaryId = HB.HumanID
		JOIN dbo.Mo_Adr BAdr ON HB.AdrID = BAdr.AdrID 
		JOIN Un_Rep R ON S.RepID = R.RepID 
		JOIN #tb_rep rr ON r.repid = rr.repid
		JOIN dbo.Mo_Human HR ON R.RepID = HR.HumanID
		LEFT JOIN Mo_Lang BLang ON HB.LangID = BLang.LangID
	WHERE S.AddressLost = 0
	GROUP BY
		R.RepCode, 
		HR.LastName , 
		HR.FirstName ,
		C.BeneficiaryId,
		HB.FirstName,
		HB.LastName,
		BAdr.Address , 
		BAdr.City, 
		BAdr.StateName, 
		SUBSTRING(replace(replace(BAdr.ZipCode,' ',''),'-',''),1,3) + ' ' + SUBSTRING(replace(replace(BAdr.ZipCode,' ',''),'-',''),4,3),
		BAdr.Phone1,
		BAdr.Phone2,
		CASE BLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(BLang.LangName, 'Unknown') END

	SELECT  
		RepCode, 
		RLastName, 
		RFirstName,
		RANKSub,
		RANKBen = null,
		SLastName, 
		SFirstName, 
		BLastName = null,
		BFirstName = null,
		Adresse = SAddress, 
		City = SCity, 
		StateName = SStateName, 
		ZipCode = SZipCode,
		Phone1 = SPhone1,
		Phone2 = SPhone2,
		LangName = SLangName
	FROM #tmpSous

	UNION

	SELECT  
		RepCode, 
		RLastName, 
		RFirstName,
		RANKSub = null,
		RANKBen,
		SLastName = null, 
		SFirstName = null, 
		BLastName,
		BFirstName,
		Adresse = BAddress, 
		City = BCity, 
		StateName = BStateName, 
		ZipCode = BZipCode,
		Phone1 = BPhone1,
		Phone2 = BPhone2,
		LangName = BLangName
	FROM #tmpBen

	ORDER BY RepCode,Adresse

End


