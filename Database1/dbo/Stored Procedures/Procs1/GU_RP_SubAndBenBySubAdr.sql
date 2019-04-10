/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_SubAndBenBySubAdr
Description         :	Procédure stockée du rapport : Liste des souscripteurs et bénéficiaires par adresse du souscripteur (ancien rapport Excel de MacrosListesClientsBilingue.xls)
Valeurs de retours  :	Dataset
Note                :	Donald Huppé	Création	2009-11-24
						Maxime Martel	ajout de l'option "tous" pour les directeurs des agences 2013-08-07
exec GU_RP_SubAndBenBySubAdr2 1, 0, 2

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_SubAndBenBySubAdr] (	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@RepID INTEGER,
	@UserID integer = null ) -- Limiter les résultats selon un représentant ou un directeur
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
		RANKSub = RANK() OVER (PARTITION BY SAdr.Address,SAdr.ZipCode ORDER BY HS.SexID desc , s.subscriberid),
		s.subscriberid,
		SLastName = HS.LastName, 
		SFirstName = HS.FirstName , 
		SAddress = SAdr.Address , 
		SCity = SAdr.City, 
		SStateName = SAdr.StateName, 
		SCountryID = SAdr.CountryID,
		SZipCode = SAdr.ZipCode,
		SPhone1 = SAdr.Phone1,
		SPhone2 = SAdr.Phone2,
		SSexID = HS.SexID , 
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
		SAdr.CountryID,
		SAdr.ZipCode,
		SAdr.Phone1,
		SAdr.Phone2,
		HS.SexID , 
		CASE SLang.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(SLang.LangName, 'Unknown') END, 
		R.RepCode, 
		HR.LastName , 
		HR.FirstName , 
		R.RepID

	-- Les bénéficiaires
	SELECT  
		-- Le rang du bénéficiaire par adresse - sert à la colonne bénéficiaire dans le tableau croisé 
		RANKBen = RANK() OVER (PARTITION BY SAdr.Address,SAdr.ZipCode ORDER BY C.BeneficiaryId),
		C.BeneficiaryId,
		SAddress = SAdr.Address , 
		SZipCode = SAdr.ZipCode,
		BFirstName = HB.FirstName,
		BLastName = HB.LastName
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
		JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
		JOIN dbo.Mo_Adr SAdr ON HS.AdrID = SAdr.AdrID 
		JOIN Un_Rep R ON S.RepID = R.RepID 
		JOIN #tb_rep rr ON r.repid = rr.repid
		JOIN dbo.Mo_Human HR ON R.RepID = HR.HumanID
		LEFT JOIN Mo_Lang SLang ON HS.LangID = SLang.LangID
	WHERE S.AddressLost = 0
	GROUP BY
		C.BeneficiaryId,
		SAdr.Address , 
		SAdr.ZipCode,
		HB.FirstName,
		HB.LastName

	-- Résultat Final
	SELECT 
		S.*, 
		B.RANKBen,
		BFirstName,
		BLastName
	FROM 
		#tmpSous S
		JOIN #tmpBen B ON S.SAddress = B.SAddress AND S.SZipCode = B.SZipCode
	ORDER BY 
		RepCode,S.SAddress,RANKSub,RANKBen

End


