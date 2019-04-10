/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_UsersByGroup
Description         :	Donne la liste des usagers contenus dans le(s) groupe(s) passé(s) en paramètre(s)
Valeurs de retours  :	Dataset 
Note                :	2009-06-15	Donald Huppé
						2015-10-13	Pierre-Luc Simard	Ajout du paramètre vcPath
														Obtenir tous les groupes si aucun paramètre n'est saisit		
                        2016-11-08  Pierre-Luc Simard   Correction pour limiter la liste aux groupes sélectionnés

exec GU_RP_UsersByGroup 'xxx,Adj_Formation,Adj_Ventes_MKT,Adjointe_SAC,Admin_BD,Admin_SYS,Affaires_Corpo,Agente_Ventes_MKT,Prog_SQL'

exec GU_RP_UsersByGroup 'Adj_Ventes_MKT,Adjointe_SAC,Direction_ADJ,Finances_ADM,RH_Affaires_Corpo_Adj,Agents_SAC'

exec GU_RP_UsersByGroup 'Adj_Ventes_MKT'

exec GU_RP_UsersByGroup 'Adj_Ventes_MKT', 'OU=Groupes,OU=Utilisateurs,DC=gestion,DC=universitas'

exec GU_RP_UsersByGroup 'Proacces_AgentAuVente', 'OU=Proacces,OU=Utilisateurs,DC=gestion,DC=universitas'

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_UsersByGroup] ( 
	@ListOfGroup varchar(5000) = '',
	@vcPath VARCHAR(250) = 'OU=Groupes,OU=Utilisateurs,DC=gestion,DC=universitas'
	) 
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


	CREATE TABLE #tParamGroupe (
								Groupe varchar(255)
							)

	DECLARE @tGroupeUsager TABLE (
								Groupe varchar(255),
								Usager varchar(255)
							)
	
	IF ISNULL(@ListOfGroup, '') <> ''
	BEGIN 
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
			insert into #tParamGroupe select ltrim(rtrim(@item))
		END
	END 
	ELSE
	BEGIN 
		INSERT INTO #tParamGroupe
			EXEC GU_SL_PlanClassGroupe @vcPath 	
	END
		
	
	-- Retrouver les Usagers associés aux Groupes 
	DECLARE MyCursor CURSOR FOR

		SELECT distinct Groupe from #tParamGroupe

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @Groupe

	WHILE @@FETCH_STATUS = 0
	BEGIN
		---print '***usagers associé au groupe :' + @Groupe
		--SET @cmd = 'dsget group "CN=' + @Groupe + ',OU=Groupes,OU=Utilisateurs,DC=gestion,DC=universitas" -members'
		SET @cmd = 'dsget group "CN=' + @Groupe + ',' + @vcPath + '" -members'
		--SET @cmd = 'dsget "' + @vcPath + '" -members'
		INSERT INTO @tGroupeUsager (Usager)
		EXEC XP_CMDSHELL @cmd

		update @tGroupeUsager set Groupe = @Groupe where Groupe is null

		FETCH NEXT FROM MyCursor INTO @Groupe
	END
	CLOSE MyCursor
	DEALLOCATE MyCursor	

	delete from @tGroupeUsager where Usager is null or usager not like '"CN%'

	update @tGroupeUsager set Usager = substring(Usager,5, PATINDEX ( '%,OU%' , Usager ) - 5 )
	
	select * from @tGroupeUsager order by Groupe, Usager
	
	
End
