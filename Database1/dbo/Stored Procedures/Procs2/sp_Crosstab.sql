create PROCEDURE [dbo].[sp_Crosstab]
    @DBFetch varchar(4000), -- Données dont on veut faire un sommaire (Peut être une table, un SELECT, une vue, une fonction, etc.) 
    @DBWhere varchar(2000) = NULL, -- Option: Ajout d'une clause WHERE pour filtrer les données
    @DBPivot varchar(4000) = NULL, -- Option: Entête des colonnes si on veut spécifier d'autres valeurs que les celles du champs DBField (Séparés par des | ) (Le nombre de valeurs doit correspondre au nombre de colonnes)
    @DBField varchar(100), -- Champs utilisé pour les regroupements par colonne, la valeur sera l'entête de la colonne si rien n'est spécifié dans DBPivot
    @PCField varchar(100), -- Champ à calculé avec la fonction du champ PCBuild
    @PCBuild varchar( 20), -- Fonction (COUNT, SUM, MIN, MAX, AVG) 
    @PCAdmin varchar( 20) = NULL, -- Option: Nom de la colonne si la valeur est NULL 
    @DBAdmin int = 0, -- Option: Indique si d'autres colonnes calculées doivent être ajouté (Par exemple, si PCBuild = SUM, 1 = Ajout d'un grand total, 2 = Ajout des colonne COUNT MIN et MAX, 3 = Ajout de toutes ces colonnes  
    @DBTable varchar(100) = NULL, -- Option: Nom de la table dans laquelle on veut enregistrer les données au lieu de retourner un dataset
    @DBWrite varchar(160) = NULL, -- Option: Nom de la base de données à utiliser si différent de celle en cours
    @DBUltra bit = 0 -- Option: Indique si la table qui contient les résultats doit être supprimé avant (0) ou simplement mise à jour (1)
AS

SET NOCOUNT ON

DECLARE @Return int
DECLARE @Retain int
DECLARE @Status int

SET @Status = 0

DECLARE @TPre varchar(10)

DECLARE @TDo3 tinyint
DECLARE @TDo4 tinyint

SET @TPre = 'tbl'

SET @TDo3 = LEN(@TPre)
SET @TDo4 = LEN(@TPre) + 1

DECLARE @DBAE varchar(40)

DECLARE @Task varchar(8000)

DECLARE @Bank varchar(4000)

DECLARE @Cash varchar(2000)

DECLARE @Rich varchar(2000)

DECLARE @DBAI varchar(4000)
DECLARE @DBAO varchar(8000)
DECLARE @DBAU varchar(2000)

DECLARE @Name varchar(100)
DECLARE @Same varchar(100)

DECLARE @Home varchar(160)

DECLARE @Some varchar(20)

DECLARE @Work int

DECLARE @Wink int

SET @DBAE = '##Crosstab' + RIGHT(CONVERT(varchar(10),@@SPID+100000),5)

SET @Task = 'IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE name = ' + CHAR(39) + @DBAE + CHAR(39) + ') DROP TABLE ' + @DBAE

EXECUTE (@Task)

CREATE TABLE #DBAT (Work int IDENTITY(1,1), Name varchar(100))

SET @Bank = @TPre + @DBFetch

IF NOT EXISTS (SELECT * FROM sysobjects WHERE RTRIM(type) = 'U' AND name = @Bank)

    BEGIN

    SET @Bank = CASE WHEN LEFT(@DBFetch,6) = 'SELECT' THEN '(' + @DBFetch + ')' ELSE @DBFetch END
    SET @Bank = REPLACE(@Bank,         CHAR(94),CHAR(39))
    SET @Bank = REPLACE(@Bank,CHAR(45)+CHAR(45),CHAR(32))
    SET @Bank = REPLACE(@Bank,CHAR(47)+CHAR(42),CHAR(32))

    END

IF @DBWhere IS NOT NULL

    BEGIN

    SET @Cash = REPLACE(@DBWhere,'WHERE'       ,CHAR(32))
    SET @Cash = REPLACE(@Cash,         CHAR(94),CHAR(39))
    SET @Cash = REPLACE(@Cash,CHAR(45)+CHAR(45),CHAR(32))
    SET @Cash = REPLACE(@Cash,CHAR(47)+CHAR(42),CHAR(32))

    END

SET @DBField = REPLACE(@DBField,CHAR(32),CHAR(95))

SET @PCField = REPLACE(@PCField,CHAR(32),CHAR(95))

SET @PCBuild = REPLACE(@PCBuild,CHAR(32),CHAR(95))

SET @PCAdmin = REPLACE(@PCAdmin,CHAR(32),CHAR(95))

SET @DBTable = REPLACE(@DBTable,CHAR(32),CHAR(95))

SET @DBWrite = REPLACE(@DBWrite,CHAR(32),CHAR(95))

SET @DBWhere = CASE WHEN @DBWhere IS NULL THEN '' ELSE ' WHERE (' + @Cash + ') AND 0 = 0' END

SET @Some = ISNULL(@PCAdmin,'NA')

SET @Task = 'SELECT * INTO ' + @DBAE + ' FROM ' + @Bank + ' AS T WHERE 0 = 1'

IF @Status = 0 EXECUTE (@Task) SET @Return = @@ERROR

IF @Status = 0 SET @Status = @Return

IF @DBPivot IS NOT NULL

    BEGIN

    IF LEFT(@DBPivot,6) <> 'SELECT'

        BEGIN

        SET @Wink = 1

        SET @Work = CHARINDEX('|',(@DBPivot)+'|')

        WHILE @Work > 0

            BEGIN

            SET @Name = SUBSTRING(@DBPivot,@Wink,@Work-@Wink)

            INSERT #DBAT (Name) VALUES (@Name)

            SET @Wink = @Work + 1

            SET @Work = CHARINDEX('|',(@DBPivot)+'|',@Wink)

            END

        END

    ELSE

        BEGIN

        SET @Task = 'INSERT #DBAT (Name) ' + @DBPivot

        SET @Task = REPLACE(@Task,         CHAR(94),CHAR(39))
        SET @Task = REPLACE(@Task,CHAR(45)+CHAR(45),CHAR(32))
        SET @Task = REPLACE(@Task,CHAR(47)+CHAR(42),CHAR(32))

        IF @Status = 0 EXECUTE (@Task) SET @Return = @@ERROR

        IF @Status = 0 SET @Status = @Return

        END

    END

ELSE

    BEGIN

    SET @Task = '   INSERT #DBAT (Name)'
              + '   SELECT CONVERT(varchar(100),' + @DBField + ')'
              + '     FROM ' + @Bank + ' AS T ' + @DBWhere
              + ' GROUP BY CONVERT(varchar(100),' + @DBField + ')'
              + ' ORDER BY 1'

    IF @Status = 0 EXECUTE (@Task) SET @Return = @@ERROR

    IF @Status = 0 SET @Status = @Return

    END

UPDATE #DBAT SET Name = @Some WHERE Name IS NULL

SET @DBAI = ''

SET @DBAO = ''

SET @Rich = ''

 DECLARE Fields CURSOR FAST_FORWARD FOR
  SELECT C.name
    FROM tempdb.dbo.sysobjects AS O
    JOIN tempdb.dbo.syscolumns AS C
      ON C.id = O.id
     AND C.name != @DBField
     AND C.name != @PCField
     AND O.name  = @DBAE
ORDER BY C.colid

SET @Retain = @@ERROR IF @Status = 0 SET @Status = @Retain

OPEN Fields

SET @Retain = @@ERROR IF @Status = 0 SET @Status = @Retain

FETCH NEXT FROM Fields INTO @Same

SET @Retain = @@ERROR IF @Status = 0 SET @Status = @Retain

WHILE @@FETCH_STATUS = 0 AND @Status = 0

    BEGIN

    SET @DBAI = @DBAI + ', ' +  @Same

    FETCH NEXT FROM Fields INTO @Same

    SET @Retain = @@ERROR IF @Status = 0 SET @Status = @Retain

    END

CLOSE Fields DEALLOCATE Fields

SET @DBAI = SUBSTRING(@DBAI,3,4000)

 DECLARE Fields CURSOR FAST_FORWARD FOR
  SELECT  Name
    FROM #DBAT
ORDER BY  Work

OPEN Fields

FETCH NEXT FROM Fields INTO @Same

WHILE @@FETCH_STATUS = 0 AND @Status = 0

    BEGIN

    IF LEN(@DBAO) < 7900 - LEN(@DBField) - LEN(@PCField) - LEN(@Same) - LEN(@Same)

        BEGIN

        SET @DBAO = @DBAO + ', ' + @PCBuild + '(CASE WHEN ISNULL(CONVERT(varchar(100),' + @DBField + '),'
                          + CHAR(39) + @Some + CHAR(39) + ') = '
                          + CHAR(39) + @Same + CHAR(39) + ' THEN '
                          + @PCField + ' ELSE NULL END) AS '
                          + CHAR(91) + @Same + CHAR(93)

        END
        ELSE
        BEGIN

        SET @Status = 50000

        END

    FETCH NEXT FROM Fields INTO @Same

    END

CLOSE Fields DEALLOCATE Fields

IF @DBAdmin IN (1,3) SET @Rich = @Rich + ', ' + @PCBuild + '(' + @PCField + ') AS All_' + @PCBuild

IF @DBAdmin IN (2,3) SET @Rich = @Rich + ', COUNT('            + @PCField + ') AS All_COUNT'

IF @DBAdmin IN (2,3) SET @Rich = @Rich + ',   MIN('            + @PCField + ') AS All_MIN'

IF @DBAdmin IN (2,3) SET @Rich = @Rich + ',   MAX('            + @PCField + ') AS All_MAX'

SET ANSI_WARNINGS OFF

SET @Home = ''

SET @Name = ''

IF @DBTable IS NOT NULL

    BEGIN

    SET @Name = @DBTable

    IF LEFT(@Name,2) = '##'

        BEGIN

        IF @DBUltra = 0

            BEGIN

            SET @Task = 'IF EXISTS (SELECT * FROM   tempdb.dbo.sysobjects WHERE name = ' + CHAR(39) + @Name + CHAR(39) + ') DROP TABLE ' +         @Name

            IF @Status = 0 EXECUTE (@Task) SET @Return = @@ERROR

            IF @Status = 0 SET @Status = @Return

            END

        END

    ELSE

        BEGIN

        IF @DBWrite IS NOT NULL SET @Home = @DBWrite + '.dbo.'

        IF @DBUltra = 0

            BEGIN

            SET @Task = 'IF EXISTS (SELECT * FROM ' + @Home + 'sysobjects WHERE name = ' + CHAR(39) + @Name + CHAR(39) + ') DROP TABLE ' + @Home + @Name

            IF @Status = 0 EXECUTE (@Task) SET @Return = @@ERROR

            IF @Status = 0 SET @Status = @Return

            END

        END

    END

IF @DBTable IS NOT NULL

    BEGIN

    IF @DBUltra = 0

        BEGIN

        IF @Status = 0 EXECUTE ( '   SELECT ' + @DBAI + @DBAO + @Rich
                               + '     INTO ' + @Home + @Name
                               + '     FROM ' + @Bank + ' AS T ' + @DBWhere
                               + ' GROUP BY ' + @DBAI
                               + ' ORDER BY ' + @DBAI ) SET @Return = @@ERROR

        IF @Status = 0 SET @Status = @Return

        END

    ELSE

        BEGIN

        IF @Status = 0 EXECUTE ( '   INSERT ' + @Home + @Name
                               + '   SELECT ' + @DBAI + @DBAO + @Rich
                               + '     FROM ' + @Bank + ' AS T ' + @DBWhere
                               + ' GROUP BY ' + @DBAI
                               + ' ORDER BY ' + @DBAI ) SET @Return = @@ERROR

        IF @Status = 0 SET @Status = @Return

        END

    END

ELSE

    BEGIN

    IF @Status = 0 EXECUTE ( '   SELECT ' + @DBAI + @DBAO + @Rich
                           + '     FROM ' + @Bank + ' AS T ' + @DBWhere
                           + ' GROUP BY ' + @DBAI
                           + ' ORDER BY ' + @DBAI ) SET @Return = @@ERROR

    IF @Status = 0 SET @Status = @Return

    END

SET ANSI_WARNINGS ON

SET @Task = 'IF EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE name = ' + CHAR(39) + @DBAE + CHAR(39) + ') DROP TABLE ' + @DBAE

EXECUTE (@Task)

DROP TABLE #DBAT

SET NOCOUNT OFF

RETURN (@Status)

