/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_PlanClassDirByGroup
Description         :	
Valeurs de retours  :	Dataset 
Note                :	2009-06-15	Donald Huppé

exec GU_RP_PlanClassDirByGroup 'xxx,Adj_Formation,Adj_Ventes_MKT,Adjointe_SAC,Admin_BD,Admin_SYS,Affaires_Corpo,Agente_Ventes_MKT'

exec GU_RP_PlanClassDirByGroup 'Adj_Ventes_MKT,Adjointe_SAC,Direction_ADJ,Finances_ADM,RH_Affaires_Corpo_Adj'

*********************************************************************************************************************/
CREATE procedure [dbo].[GU_RP_PlanClassDirByGroup] 
	( @ListOfGroup varchar(5000)) 

as 
BEGIN

	--declare @ListOfDossier varchar(5000)
	--set @ListOfDossier = '100-001,100-002'

	DECLARE @NbOfItem int
	DECLARE @ItemPos int
	DECLARE @ItemPosPrec int
	DECLARE @Item varchar(3000)
	DECLARE @cmd varchar(3000)
	DECLARE @Groupe varchar(3000)


	DECLARE @tParamGroupe TABLE (
								Groupe varchar(255)
							)

	DECLARE @tGroupeDossiers TABLE (
								NoDossier varchar(255),
								Groupe varchar(255),
								TypeAcces varchar(1)
							)




	-- Mettre les groupes demandés dans une table
	if @ListOfGroup not like '%,'
	begin
		set @ListOfGroup = @ListOfGroup + ','
	end
	set @ItemPos = 1
	set @ItemPosPrec = 1
	set @NbOfItem = 0

	while @ItemPos > 0 
	begin
		set @NbOfItem = @NbOfItem + 1
		set @ItemPos = CHARINDEX( ',', @ListOfGroup, @ItemPosPrec)
		set @item = SUBSTRING ( @ListOfGroup ,@ItemPosPrec , @ItemPos  - @ItemPosPrec )
		set @ItemPosPrec = @ItemPos + 1
		set @ItemPos = CHARINDEX ( ',' , @ListOfGroup , @ItemPos + 1 )
		insert into @tParamGroupe select ltrim(rtrim(@item))
	end

	-- select * from @tParamGroupe
	-- return

	-- Retrouver les Dossiers associés aux groupes demandés
	DECLARE MyCursor CURSOR FOR

		SELECT Groupe from @tParamGroupe

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @Groupe

	WHILE @@FETCH_STATUS = 0
	BEGIN
--print @Groupe		
		SET @cmd = 'dsget group "CN=' + @Groupe + ',OU=Groupes,OU=Utilisateurs,DC=gestion,DC=universitas" -memberof'
--print @cmd
		INSERT INTO @tGroupeDossiers (NoDossier)
		EXEC XP_CMDSHELL @cmd

		delete from @tGroupeDossiers where (noDossier not like '%-R,%' AND noDossier not like '%-W,%' AND noDossier not like '%-A,%') OR isnumeric(substring(noDossier,5,1)) = 0

		update @tGroupeDossiers set 
			Groupe = @Groupe, 
			TypeAcces = case when NoDossier like '%-R%' then 'R' 
							 when NoDossier like '%-W%' then 'W' 
							 when NoDossier like '%-A%' then 'A' 
						else '?'
						end

		where Groupe is null

		FETCH NEXT FROM MyCursor INTO @Groupe
	END
	CLOSE MyCursor
	DEALLOCATE MyCursor	

	delete from @tGroupeDossiers where NoDossier is null

	update @tGroupeDossiers set NoDossier = substring(NoDossier,5, PATINDEX ( '%,OU%' , NoDossier ) - 7 )


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





	select G.NoDossier, G.Groupe, G.TypeAcces , D.Dossier
	from @tGroupeDossiers G
	join @tDirectory D on D.NoDossier = G.NoDossier
	UNION
	Select NoDossier = Null, Groupe, TypeAcces = Null, Dossier = NULL
	from @tParamGroupe
	where groupe not in (select groupe from @tGroupeDossiers)
	order by NoDossier,Groupe,TypeAcces




End

