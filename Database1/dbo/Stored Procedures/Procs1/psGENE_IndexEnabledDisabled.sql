/****************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc
Nom         :   psGENE_IndexEnabledDisabled 
Description :   Désactive ou réactive les indexes d'une table.

Paramètre d'entrée :   
    Paramètre       Description
    ------------    --------------------------------------------------------------------------------
    @objectname     Nom de la table sur laquelle portera l'action sur ces indexes
    @switch         Action à porter sur les indexes
                        = 0     Désactive (défaut)
                        <> 0    Réactive
Historique :
    Date        Programmeur         Description
    ----------  ----------------    ----------------------------------------------------------------
    2016-10-11  Steeve Picard       Création du service (Basé à partir de celui de Wilfred Van Dijk)
****************************************************************************************************/
CREATE PROCEDURE dbo.psGENE_IndexEnabledDisabled(
    @objectname SYSNAME,
    @switch     BIT = 0
) AS
BEGIN
    DECLARE @SQLCmd NVARCHAR(512);
    DECLARE @action NVARCHAR(16);
    DECLARE @counter INT = 0;
    DECLARE @debug BIT = 0;

    IF @switch = 0
        SET @action = ' disable;';
    ELSE
        SET @action = ' rebuild;';

    DECLARE c_toggle_index CURSOR
        FOR SELECT 'alter index '+QUOTENAME(name)+' on '+QUOTENAME(@objectname)+@action
            FROM sys.indexes
            WHERE type_desc = 'nonclustered'
                AND is_unique = 0
                AND is_primary_key = 0
                AND is_unique_constraint = 0
                AND is_disabled = @switch
                AND object_id = OBJECT_ID(@objectname);

    OPEN c_toggle_index;

    FETCH NEXT FROM c_toggle_index INTO @SQLCmd;
    WHILE @@fetch_status = 0
    BEGIN
        SET @counter = @counter + 1;
        IF @debug = 0
            EXEC (@SQLCmd);
        ELSE
            PRINT @SQLCmd;

        FETCH NEXT FROM c_toggle_index INTO @SQLCmd;
    END;

    CLOSE c_toggle_index;
    DEALLOCATE c_toggle_index;
END;
