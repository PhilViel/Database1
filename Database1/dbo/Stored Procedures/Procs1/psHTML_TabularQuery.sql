-- =============================================
-- Author:	david.gugg for SQL Server Central
-- Create date: 02/14/2014
-- Description:	This stored procedure will send an email from the database with the query results as an html table in the email.
-- =============================================
CREATE PROCEDURE dbo.psHTML_TabularQuery
(
	@qSELECT NVARCHAR(100), --The select part of the sql statement, which can include top X
	@fieldlist NVARCHAR(MAX), --Pipe delimited list of fields, which can include aliases
	@qFROM NVARCHAR(MAX), --The from part of the sql statment, which can include joins
	@qWHERE NVARCHAR(MAX) = '', --The where part of the sql statement
	@qGroupBy NVARCHAR(MAX) = '',--The group by clause
	@qHaving NVARCHAR(MAX) = '',--The having clause
	@qOrderBy NVARCHAR(MAX) = '', --The order by part of the sql statement
    @xml NVARCHAR(MAX) OUTPUT
)

AS
BEGIN

	--Declare initial variable.
	DECLARE @body NVARCHAR(MAX)
	DECLARE @sql NVARCHAR(MAX)
	DECLARE @resultexist NVARCHAR(MAX)
	DECLARE @tblfieldheader NVARCHAR(MAX) = ''
	DECLARE @tempfield NVARCHAR(MAX) = ''
	CREATE TABLE #Fields (ID INT IDENTITY(1,1),field NVARCHAR(MAX))
	DECLARE @i INT = 1, @j INT = 0, @SendEmail INT
	DECLARE @splitcnt INT
	DECLARE @fieldcount INT  
  
	--Find the number of fields in the query  
	--Loop through the fields and put each on into the #Fields temp table as a new record
	INSERT INTO #Fields ( field ) 
    SELECT strField FROM dbo.fntGENE_SplitIntoTable(@fieldlist,'|') 
    WHERE LEN(strField) > 0
	
	SET @fieldcount = @@ROWCOUNT

	--Start setting up the sql statement for the query.
	SET @sql = @qSELECT
	--Loop through the #Fields table to get the field list
	WHILE @i <= @fieldcount
		BEGIN
			SELECT @tempfield = field FROM #Fields WHERE ID = @i
			--------------------------------------------------------------------------------------------------------------------------------------------------------------
			--This next section is required in case a field is aliased.  For the xml, we need to get rid of the aliases, the table header will only require the aliases.
			--NULL values need to be shown as a string = 'NULL' or the html table will just skip the cell and all values after that in the row will be shifted left.
			---------------------------------------------------------------------------------------------------------------------------------------------------------------
			IF RIGHT(@tempfield,1) = ']' OR CHARINDEX(' as ',@tempfield) = 0
				BEGIN
					--Set the xml field to be the entire field name
					SET @sql = @sql + ' ISNULL(CAST(' + @tempfield + ' AS NVARCHAR(4000)),''NULL'') AS ''td'','''','
					--Set the table header field to be the entire field name
					SET @tblfieldheader = @tblfieldheader + '<th>' + @tempfield + '</th>'
				END          
			ELSE 
				BEGIN
					--Set the xml field to be the field name minus the alias
					SET @sql = @sql + ' ISNULL(CAST(' + LEFT(@tempfield,LEN(@tempfield) - (CHARINDEX(' sa ',REVERSE(@tempfield))+3)) + ' AS NVARCHAR(4000)),''NULL'') AS ''td'','''','
					--Set the table header field to be the field name's alias
					SET @tblfieldheader = @tblfieldheader + '<th>' + RIGHT(@tempfield,CHARINDEX(' sa ',REVERSE(@tempfield))-1) + '</th>'
				END
			--Increment the counter.
			SET @i += 1
		END
	--Trim the extra four characters of the end of @sql.      
	SET @sql = LEFT(@sql, LEN(@sql)-4)
	--Add the from, where, group by, having, and order by clause to the select statement.
	SET @sql = @sql + ' ' + @qFROM + ' ' + @qWHERE + ' ' +  @qGroupBy + ' ' + @qHaving + ' ' + @qOrderBy
	--Put the set xml command around the sql statement.
	SET @sql = 'SET @XML = CAST(( ' + @sql + ' FOR XML PATH(''tr''),ELEMENTS ) AS NVARCHAR(MAX))'
	--Run the sql that will create the xml.

	EXEC sp_executesql @sql, N'@xml nvarchar(max) output', @xml OUTPUT
	--Drop the fields temp table.
	DROP TABLE #Fields
END
