/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_SL_PlanClassGroupe
Description         :	
Valeurs de retours  :	Dataset 
Note                :	2009-06-15	Donald Huppé
						2015-10-13	Pierre-Luc Simard		Ajout du paramètre vcPath

exec GU_SL_PlanClassGroupe
exec GU_SL_PlanClassGroupe 'OU=Groupes,OU=Utilisateurs,DC=gestion,DC=universitas'
exec GU_SL_PlanClassGroupe 'OU=Proacces,OU=Utilisateurs,DC=gestion,DC=universitas'
*********************************************************************************************************************/
CREATE procedure [dbo].[GU_SL_PlanClassGroupe] 
	(@vcPath VARCHAR(250) = 'OU=Groupes,OU=Utilisateurs,DC=gestion,DC=universitas')

as 
BEGIN


DECLARE @cmd varchar(100)

	DECLARE @tGroupe TABLE (
								Groupe varchar(255)
							)

	--SET @cmd = 'dsquery group "OU=Groupes,OU=Utilisateurs,DC=gestion,DC=universitas"'
	SET @cmd = 'dsquery group "' + @vcPath + '"'
	INSERT INTO @tGroupe (Groupe)
	EXEC XP_CMDSHELL @cmd


	delete from @tGroupe where Groupe is null or Groupe not like '"CN%'

	update @tGroupe set Groupe = substring(Groupe,5, PATINDEX ( '%,OU%' , Groupe ) - 5 )

	delete from @tGroupe where Groupe in ('All_Deny_M','All_UserGroups','AllRead')
	
	select * from @tGroupe order by Groupe

end




