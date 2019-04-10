/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc
Nom                 :	SP_ExportTableToExcelWithColumns
						
Description         :	Pour le rapport des droits Du Logiciel UniAcces
Paramètres			:	

Valeurs de retours  :	Fichier Excel généré
							
Note                :	2009-02-11	Donald Huppé		Création
						2011-05-04	Pierre-Luc Simard	Ajout des paramètres vcCode et bEntete
						2017-02-24	Donald Huppé		Le paramètre @file_name varchar(100) passe à varchar(100)
						2018-06-08	Donald Huppé		Ajout du paramètre @Separateur avec valeur par défaut comme celle qui était utilisé avant cet ajout, soit ";"
														Dans le but de pouvoir inscrire une virgule pour les poste anglais de la comptabilité
-- exec SP_ExportTableToExcelWithColumns 'univBase_Profil', 'TMPRightList', '\\gestas2\dhuppe$\RightList.csv'

DROP PROC SP_ExportTableToExcelWithColumns_SepareVirgule

****************************************************************************************************/
CREATE procedure [dbo].[SP_ExportTableToExcelWithColumns]
(
		@db_name varchar(100),
		@table_name varchar(100), 
		@file_name varchar(500),
		@vcCode varchar (50) = NULL, -- RAW = AINSI, 65001 = UTF-8
		@bEntete bit = 1,
		@Separateur varchar(1) = ';'
)

	as

begin

	declare 
		@columns varchar(8000), 
		@columns2 varchar(8000), 
		@sql varchar(8000), 
		@sql2 varchar(8000), 
		@data_file varchar(100),
		@Col_Name varchar(255),
		@i int

	--Créer un nom de fichier bidon pour y mettre les données
	select @data_file=substring(@file_name,1,len(@file_name)-charindex('\',reverse(@file_name)))+'\data_file.xls'
	PRINT @bEntete
	IF @bEntete = 1
	BEGIN 
		PRINT @bEntete
		set @columns = ''
		set @columns2 = ''

		DECLARE MyCursor CURSOR FOR
			select column_name from information_schema.columns where table_name=@table_name	
		OPEN MyCursor
		FETCH NEXT FROM MyCursor INTO @Col_Name

		set @i = 0
		WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Ici, dans le cas où il y aurait beaucoup de noms de colonne, on met ça dans 2 variables au besoin
			if len(@columns) < 7800
				begin
				set @columns = @columns + case when @i > 0 then ',' else '' end + 'a' + cast(@i as varchar(4)) + '=''''' + REPLACE(@Col_Name,'''',' ') + ''''''
				end
			else
 				begin
				set @columns2 = @columns2 + ',' + 'a' + cast(@i as varchar(4)) + '=''''' + REPLACE(@Col_Name,'''',' ') + ''''''
				end
			set @i = @i + 1
			FETCH NEXT FROM MyCursor INTO @Col_Name
		END
		CLOSE MyCursor
		DEALLOCATE MyCursor
	
		--inscrire les nom des colonnes dans le fichier Excel
		set @sql='exec master..xp_cmdshell ''bcp " select * from (select ' + @columns 
		set @sql2 = @columns2 + ') as t" queryout "' + @file_name + '" -t"'+@Separateur+'" -c -T -C "' + ISNULL(@vcCode, 'RAW') + '"'''
		exec(@sql+@sql2)
	END

	--Mettre les données de la table dans le fichier bidon
	set @sql='exec master..xp_cmdshell ''bcp "select * from '+@db_name+'..'+@table_name+'" queryout "'+@data_file+'" -t"'+@Separateur+'" -c -T -C "' + ISNULL(@vcCode, 'RAW') + '"'''
	exec(@sql)

	--Copier les données du fichier bidon dans le fichier Excel (à la suite des entêtes de colonnes
	set @sql= 'exec master..xp_cmdshell ''type '+@data_file+' >> '+@file_name+''''
	exec(@sql)

	--Détruire le fichier bidon 
	set @sql= 'exec master..xp_cmdshell ''del '+@data_file+''''
	exec(@sql)

end
