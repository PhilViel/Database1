/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_PlanClassAccessToDir
Description         :	
Valeurs de retours  :	Dataset 
Note                :	2009-06-15	Donald Huppé

exec GU_RP_PlanClassAccessToDir '000,000-001,000-002,000-003,000-004,000-006,000-007,000-008,000-009,000-010,001,1,100-001,100-002,101,101-100,101-200,101-300,101-400,102,102-100,102-101,102-200,102-210,102-220,103,103-100,103-110,103-120,103-200,103-210,103-220,103-300,103-310,103-320,103-400,103-410,103-420,103-500,103-510,103-520,103-600,103-610,103-611,103-612,103-620,103-621,103-622,103-630,103-631,103-632,103-640,103-641,103-642,103-643,103-650,103-651,103-652,103-660,103-661,103-662,103-670,103-671,103-672,103-700,103-710,103-720,104,104-100,104-101,104-102,104-103,104-104,104-105,104-106,104-107,104-110,104-111,104-112,104-113,104-114,104-200,105,105-100,105-200,106,106-100,106-200,106-400,106-500,2,201,201-100,201-101,201-110,201-111,201-112,201-113,201-114,201-115,201-116,201-117,201-118,201-119,201-120,201-121,201-122,201-123,201-124,201-125,201-126,201-127,201-128,201-129,201-130,201-131,201-132,201-133,201-134,201-135,201-136,201-137,201-138,201-139,201-200,201-210,201-211,201-212,201-220,201-230,201-240,201-300,201-310,201-320,201-330,201-340,201-350,201-351,201-352,201-353,201-354,201-355,201-400,201-401,201-410,201-411,201-412,201-413,201-414,201-415,201-420,201-421,201-430,201-431,201-432,201-433,201-434,201-440,201-441,201-442,201-450,201-451,201-452,201-453,201-454,201-455,201-500,201-501,201-510,201-520,201-521,201-522,201-523,201-524,201-525,201-526,201-527,201-528,201-529,201-530,201-540,201-550,201-560,201-570,202,202-100,202-110,202-120,202-130,202-140,202-200,3,301,302,302-100,302-101,302-102,302-103,302-104,302-105,302-106,302-107,302-108,302-109,302-200,302-201,302-202,302-203,302-204,302-205,302-206,302-207,302-208,302-209,303,303-001,303-002,303-003,303-100,303-200,303-300,304,304-100,304-101,304-102,304-103,304-104,304-105,304-106,304-107,304-108,304-109,304-200,304-201,304-202,304-203,304-204,304-205,304-206,304-207,304-208,304-209,305,305-100,305-200,305-300,306,306-100,306-200,306-300,307,307-100,307-200,307-210,307-220,307-300,307-400,307-500,307-600,4,401,401-100,401-101,401-200,401-201,401-202,401-203,401-204,401-206,401-207,401-208,401-209,401-300,401-400,401-410,401-411,401-412,401-413,401-414,401-415,401-416,401-500,401-510,401-520,401-600,401-601,401-602,401-610,401-620,401-630,402,402-100,402-200,402-300,402-400,403,403-100,403-110,403-111,403-112,403-113,403-114,403-115,403-117,403-118,403-119,403-120,403-130,403-140,403-150,403-200,403-201,403-202,403-210,403-211,403-220,403-300,403-400,403-500,403-501,403-502,403-503,403-504,403-510,403-511,403-512,403-513,404,404-100,404-200,405,405-100,405-110,405-120,405-130,405-140,405-141,405-142,405-200,405-300,406,406-100,406-110,406-111,406-112,406-120,406-121,406-122,406-200,406-210,406-211,406-212,406-220,406-221,406-222,406-230,406-231,406-232,5,501,501-001,501-002,501-003,501-004,501-005,502,502-001,502-002,502-003,502-004,503,503-100,503-101,503-102,503-103,503-200,504,504-100,504-200,504-300,505,505-100,505-101,505-102,505-103,505-104,505-105,505-106,505-107,505-200,505-210,505-211,505-212,505-220,505-230,505-300,505-400,506,507,507-001,507-002,507-003,507-004,508,508-001,508-002,508-100,508-101,508-102,509,509-001,509-002,509-003,509-004,509-100,509-101,509-102,509-103,509-104,509-105,509-106,509-110,509-111,509-112,509-113,509-114,509-115,509-120,509-121,509-122,509-123,509-124,509-200,509-210,509-211,509-212,509-213,509-214,509-220,509-230,509-231,509-232,509-233,509-240,6,601,601-100,601-110,601-120,602,602-001,602-002,602-003,602-004,602-005,602-100,602-110,602-120,603,603-010,603-020,603-030,603-040,603-100,7,701,701-001,701-100,701-200,701-201,701-300,701-301,701-310,702,702-100,702-101,702-102,702-103,702-200,702-201,702-300,702-310,702-320,702-400,702-410,702-411,702-412,702-413,702-414,702-415,702-420,702-421,702-422,702-423,702-424,702-430,702-431,702-432,702-440,702-441,702-450,702-451,702-452,702-453,703,703-001,703-002,703-100,703-101,703-102,703-103,703-200,703-210,703-211,703-212,703-213,703-214,703-215,703-216,703-217,703-220,703-221,703-222,703-223,703-330,703-300,703-301,703-302,703-303,703-310,703-311,703-312,703-320,703-400,703-401,703-402,703-403,703-404,703-500,703-600,703-700,703-701,703-702,8,800,801,802-100,802-200,802-210,802-220,802-221,802-222,802-230,802'

exec GU_RP_PlanClassAccessToDir '000,000-001,000-002,000-003,000-004,000-006,000-007,000-008,000-009,000-010,001,1,100-001,100-002,101,101-100,101-200,101-300,101-400,102,102-100,102-101,102-200,201-434'

exec GU_RP_PlanClassAccessToDir '201-434'
*********************************************************************************************************************/
CREATE procedure [dbo].[GU_RP_PlanClassAccessToDir] 
	( @ListOfDossier varchar(5000)) 

as 
BEGIN

	--declare @ListOfDossier varchar(5000)
	--set @ListOfDossier = '100-001,100-002'

	DECLARE @NbOfItem int
	DECLARE @ItemPos int
	DECLARE @ItemPosPrec int
	DECLARE @Item varchar(255)
	DECLARE @cmd varchar(3000)
	DECLARE @Usager varchar (4000)
	DECLARE @NoDossier varchar(255)
	DECLARE @Groupe varchar(255)

	DECLARE @tParamDossier TABLE (
								NoDossier varchar(2000)
							)

	DECLARE @tGroupeDossiers TABLE (
								NoDossier varchar(255),
								Groupe varchar(255),
								TypeAcces varchar(1)
							)

	DECLARE @tGroupeUsager TABLE (
								Groupe varchar(255),
								Usager varchar(255)
							)


	-- Mettre les répertoire demandé dans une table
	if @ListOfDossier not like '%,'
	begin
		set @ListOfDossier = @ListOfDossier + ','
	end
	set @ItemPos = 1
	set @ItemPosPrec = 1
	set @NbOfItem = 0

	while @ItemPos > 0 --and @NbOfItem < 25
	begin
		set @NbOfItem = @NbOfItem + 1
		set @ItemPos = CHARINDEX( ',', @ListOfDossier, @ItemPosPrec)
		set @item = SUBSTRING ( @ListOfDossier ,@ItemPosPrec , @ItemPos  - @ItemPosPrec )
		set @ItemPosPrec = @ItemPos + 1
		set @ItemPos = CHARINDEX ( ',' , @ListOfDossier , @ItemPos + 1 )
		insert into @tParamDossier select ltrim(rtrim(@item))
	end


	-- Retrouver les groupes R associés aux Dossiers demandés
	DECLARE MyCursor CURSOR FOR

		SELECT NoDossier from @tParamDossier

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @NoDossier

	WHILE @@FETCH_STATUS = 0
	BEGIN
		--print 'Retrouver les groupes R :' + @NoDossier
		SET @cmd = 'dsget group "CN=' + @NoDossier + '-R,OU=GroupesDossiers,DC=gestion,DC=universitas" -members'
		INSERT INTO @tGroupeDossiers (Groupe)
		EXEC XP_CMDSHELL @cmd

		update @tGroupeDossiers set NoDossier = @NoDossier, TypeAcces = 'R' where NoDossier is null

		FETCH NEXT FROM MyCursor INTO @NoDossier
	END
	CLOSE MyCursor
	DEALLOCATE MyCursor	

	delete from @tGroupeDossiers where (groupe is null)

	update @tGroupeDossiers set Groupe = substring(Groupe,5, PATINDEX ( '%,OU%' , Groupe ) - 5 ) WHERE Groupe LIKE '"CN%'


	-- Retrouver les groupes W associés aux Dossiers demandés
	DECLARE MyCursor CURSOR FOR

		SELECT NoDossier from @tParamDossier

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @NoDossier

	WHILE @@FETCH_STATUS = 0
	BEGIN

		--print 'Retrouver les groupes W :' + @NoDossier

		SET @cmd = 'dsget group "CN=' + @NoDossier + '-W,OU=GroupesDossiers,DC=gestion,DC=universitas" -members'
		INSERT INTO @tGroupeDossiers (Groupe)
		EXEC XP_CMDSHELL @cmd
		--print @NoDossier
		update @tGroupeDossiers set NoDossier = @NoDossier, TypeAcces = 'W' where NoDossier is null

		FETCH NEXT FROM MyCursor INTO @NoDossier
	END
	CLOSE MyCursor
	DEALLOCATE MyCursor	

	delete from @tGroupeDossiers where (groupe is null)

	update @tGroupeDossiers set Groupe = substring(Groupe,5, PATINDEX ( '%,OU%' , Groupe ) - 5 ) WHERE Groupe LIKE '"CN%'



	-- Retrouver les groupes A associés aux Dossiers demandés
	DECLARE MyCursor CURSOR FOR

		SELECT NoDossier from @tParamDossier

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @NoDossier

	WHILE @@FETCH_STATUS = 0
	BEGIN
		--print 'Retrouver les groupes A :' + @NoDossier

		SET @cmd = 'dsget group "CN=' + @NoDossier + '-A,OU=GroupesDossiers,DC=gestion,DC=universitas" -members'
		INSERT INTO @tGroupeDossiers (Groupe)
		EXEC XP_CMDSHELL @cmd

		update @tGroupeDossiers set NoDossier = @NoDossier, TypeAcces = 'A' where NoDossier is null

		FETCH NEXT FROM MyCursor INTO @NoDossier
	END
	CLOSE MyCursor
	DEALLOCATE MyCursor	

	delete from @tGroupeDossiers where (groupe is null)

	update @tGroupeDossiers set Groupe = substring(Groupe,5, PATINDEX ( '%,OU%' , Groupe ) - 5 ) WHERE Groupe LIKE '"CN%'


	-- Retrouver les Usagers associés aux Groupes 
	DECLARE MyCursor CURSOR FOR

		SELECT distinct Groupe from @tGroupeDossiers

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @Groupe

	WHILE @@FETCH_STATUS = 0
	BEGIN
		print '***usagers associé au groupe :' + @Groupe
		SET @cmd = 'dsget group "CN=' + @Groupe + ',OU=Groupes,OU=Utilisateurs,DC=gestion,DC=universitas" -members'
		INSERT INTO @tGroupeUsager (Usager)
		EXEC XP_CMDSHELL @cmd

		update @tGroupeUsager set Groupe = @Groupe where Groupe is null

		FETCH NEXT FROM MyCursor INTO @Groupe
	END
	CLOSE MyCursor
	DEALLOCATE MyCursor	

	delete from @tGroupeUsager where Usager is null or usager not like '"CN%'

	update @tGroupeUsager set Usager = substring(Usager,5, PATINDEX ( '%,OU%' , Usager ) - 5 )



	-- Retrouver tous les répertoires
	declare @tDirectory TABLE (
								FullPath varchar(2000),
								Dossier varchar(500), 
								NoDossier varchar(20), 
								Niveau integer
							)


	-- Faire un Dir des niveau 1 séparément car on ne veut pas faire une DIR du 8 car il est trop gros pour des répertoire qu'on ne veut pas de toute façon (ex :relevé de dépot)
	SET @cmd = 'DIR \\gestas2\PlandeClassification\000_PANIER_DE_CLASSEMENT /AD /B /S'
	INSERT INTO @tDirectory (FullPath)
	EXEC XP_CMDSHELL @cmd

	SET @cmd = 'DIR \\gestas2\PlandeClassification\001_DOC_SEMI-ACTIFS /AD /B /S'
	INSERT INTO @tDirectory (FullPath)
	EXEC XP_CMDSHELL @cmd

	SET @cmd = 'DIR \\gestas2\PlandeClassification\1_GOUVERNANCE_ET_AFFAIRES_CORPO /AD /B /S'
	INSERT INTO @tDirectory (FullPath)
	EXEC XP_CMDSHELL @cmd

	SET @cmd = 'DIR \\gestas2\PlandeClassification\2_ADMINISTRATION_GENERALE /AD /B /S'
	INSERT INTO @tDirectory (FullPath)
	EXEC XP_CMDSHELL @cmd

	SET @cmd = 'DIR \\gestas2\PlandeClassification\3_COMM_ET_REL_PUB /AD /B /S'
	INSERT INTO @tDirectory (FullPath)
	EXEC XP_CMDSHELL @cmd

	SET @cmd = 'DIR \\gestas2\PlandeClassification\4_GESTION_RH /AD /B /S'
	INSERT INTO @tDirectory (FullPath)
	EXEC XP_CMDSHELL @cmd

	SET @cmd = 'DIR \\gestas2\PlandeClassification\5_COMPTABILITE_ET_INFO_FINANCIERES /AD /B /S'
	INSERT INTO @tDirectory (FullPath)
	EXEC XP_CMDSHELL @cmd

	SET @cmd = 'DIR \\gestas2\PlandeClassification\6_GESTION_BIENS_ET_SERVICES /AD /B /S'
	INSERT INTO @tDirectory (FullPath)
	EXEC XP_CMDSHELL @cmd

	SET @cmd = 'DIR \\gestas2\PlandeClassification\7_VENTES_ET_MARK /AD /B /S'
	INSERT INTO @tDirectory (FullPath)
	EXEC XP_CMDSHELL @cmd


	update @tDirectory set Dossier = ltrim(rtrim(SUBSTRING(FullPath,  len(FullPath)-PATINDEX('%\%',REVERSE(FullPath)) + 2  , 300   )))
	update @tDirectory set Niveau = len(FullPath) - len(REPLACE(FullPath, '\', '')) - 3

	-- Supprimer tous les répertoire qui ne commence pas par 3 chiffre OU que le 4ieme caractère n'est par - ou _
	delete from @tDirectory where (isnumeric(substring(Dossier,1,3))=0 OR substring(Dossier,4,1) not in ('-','_'))

	-- NoDossier de type 100
	update @tDirectory set NoDossier  = substring(Dossier,1,3) where isnumeric(substring(Dossier,1,3)) = 1 and isnumeric(substring(Dossier,5,3)) = 0
	-- NoDossier de type 100-001
	update @tDirectory set NoDossier  = substring(Dossier,1,7) where isnumeric(substring(Dossier,1,3)) = 1 and isnumeric(substring(Dossier,5,3)) = 1

	--update @tDirectory set FullPath = Substring(FullPath,32,5000)

	-- Les répertoire de premier niveau et le réperoire 800
	insert into @tDirectory values ('\\gestas2\PlandeClassification\000_PANIER_DE_CLASSEMENT','000_PANIER_DE_CLASSEMENT','000',1)
	insert into @tDirectory values ('\\gestas2\PlandeClassification\001_DOC_SEMI-ACTIFS','001_DOC_SEMI-ACTIFS','001',1)
	insert into @tDirectory values ('\\gestas2\PlandeClassification\1_GOUVERNANCE_ET_AFFAIRES_CORPO','1_GOUVERNANCE_ET_AFFAIRES_CORPO','1',1)
	insert into @tDirectory values ('\\gestas2\PlandeClassification\2_ADMINISTRATION_GENERALE','2_ADMINISTRATION_GENERALE','2',1)
	insert into @tDirectory values ('\\gestas2\PlandeClassification\3_COMM_ET_REL_PUB','3_COMM_ET_REL_PUB','3',1)
	insert into @tDirectory values ('\\gestas2\PlandeClassification\4_GESTION_RH','4_GESTION_RH','4',1)
	insert into @tDirectory values ('\\gestas2\PlandeClassification\5_COMPTABILITE_ET_INFO_FINANCIERES','5_COMPTABILITE_ET_INFO_FINANCIERES','5',1)
	insert into @tDirectory values ('\\gestas2\PlandeClassification\6_GESTION_BIENS_ET_SERVICES','6_GESTION_BIENS_ET_SERVICES','6',1)
	insert into @tDirectory values ('\\gestas2\PlandeClassification\7_VENTES_ET_MARK','7_VENTES_ET_MARK','7',1)
	insert into @tDirectory values ('\\gestas2\PlandeClassification\8_SERVICES_A_LA_CLIENTELE','8_SERVICES_A_LA_CLIENTELE','8',1)
	insert into @tDirectory values ('\\gestas2\PlandeClassification\800_SERVICES_AVANT_ADHESION','800_SERVICES_AVANT_ADHESION','800',2)
	insert into @tDirectory values ('\\gestas2\PlandeClassification\801_SERVICE_APRES_VENTE','801_SERVICE_APRES_VENTE','801',2)
	insert into @tDirectory values ('\\gestas2\PlandeClassification\802_GESTION_DES_CONTRATS','802_GESTION_DES_CONTRATS','802',2)
	insert into @tDirectory values ('\\gestas2\PlandeClassification\802-100_SOUSCRIPTEUR','802-100_SOUSCRIPTEUR','802-100',3)

	insert into @tDirectory values ('\\gestas2\PlandeClassification\802-200_OPERATION_ADMIN','802-200_OPERATION_ADMIN','802-200',3)

	insert into @tDirectory values ('\\gestas2\PlandeClassification\802-200_OPERATION_ADMIN\802-210_AJUSTEMENT_CONTRAT','802-210_AJUSTEMENT_CONTRAT','802-210',4)
	insert into @tDirectory values ('\\gestas2\PlandeClassification\802-200_OPERATION_ADMIN\802-220_SUIVI_DOSSIER_PARTICULIER','802-220_SUIVI_DOSSIER_PARTICULIER','802-220',4)

	insert into @tDirectory values ('\\gestas2\PlandeClassification\802-200_OPERATION_ADMIN\802-220_SUIVI_DOSSIER_PARTICULIER\802-221_DELEGATION_SOLDE','802-221_DELEGATION_SOLDE','802-221',5)
	insert into @tDirectory values ('\\gestas2\PlandeClassification\802-200_OPERATION_ADMIN\802-220_SUIVI_DOSSIER_PARTICULIER\802-222_CONTRIBUTION_POSTHUME','802-222_CONTRIBUTION_POSTHUME','802-222',5)

	insert into @tDirectory values ('\\gestas2\PlandeClassification\802-200_OPERATION_ADMIN\802-230_OUTILS_SUIVIS_TRAVAIL','802-230_OUTILS_SUIVIS_TRAVAIL','802-230',4)

	insert into @tDirectory values ('\\gestas2\PlandeClassification\808_SUBVENTIONS_PROV_ET_FED','808_SUBVENTIONS_PROV_ET_FED','808',2)


	select 
		DR.NoDossier,DR.Dossier, GD.Groupe, GD.TypeAcces, GU.Usager
	from 
		@tParamDossier D
		join @tDirectory DR on D.NoDossier = DR.NoDossier
		join @tGroupeDossiers GD on D.NoDossier = GD.NoDossier
		join @tGroupeUsager GU on GD.Groupe = GU.Groupe

	UNION -- Si le dossier n'a pas de groupe associé, alors on l'ajoute dans la liste pour montrer dans le rapport
		select DR.NoDossier,DR.Dossier, Groupe = NULL, TypeAcces = NULL, Usager = NULL
		from @tParamDossier D
		join @tDirectory DR on D.NoDossier = DR.NoDossier
		where D.NoDossier not in (select NoDossier from @tGroupeDossiers)
	order by DR.NoDossier, GD.Groupe, GD.TypeAcces, GU.Usager


	--select * from @tDirectory order by FullPath



End

