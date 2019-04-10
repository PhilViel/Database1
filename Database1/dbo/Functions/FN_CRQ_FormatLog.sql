/****************************************************************************************************

	Fonction DE FORMATTAGE DE LOG

*********************************************************************************
	17-05-2004 Dominic Létourneau
		Migration de la fonction selon les nouveaux standards
*********************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_FormatLog (
	@TableName VARCHAR(75), -- Nom de table
	@ColumnName VARCHAR(75), -- Nom de la colonne
	@OldValue VARCHAR(75), -- Ancienne valeur
	@NewValue VARCHAR(75)) -- Nouvelle valeur
RETURNS VARCHAR(75)
AS

BEGIN

	DECLARE @Result MoDesc
	
	IF (ISNULL(@OldValue, '') = '' AND ISNULL(@NewValue, '') = '') OR @OldValue = @NewValue
		SET @Result = ''
	ELSE
	BEGIN	

		IF @ColumnName = 'NEW' OR @ColumnName = 'DEL' OR @ColumnName = 'MODIF'
		BEGIN 
			SET @OldValue = ''
	
			IF @ColumnName = 'NEW' 
				SET @Result = 'New in table ' + @TableName
			ELSE IF @ColumnName = 'DEL'
				SET @Result = 'Deleted in table '+ @TableName
			ELSE IF @ColumnName = 'MODIF'
				SET @Result = 'Modification in table ' + @TableName

		END -- IF @ColumnName = 'NEW' OR @ColumnName = 'DEL' OR @ColumnName = 'MODIF'
		ELSE
		BEGIN
			IF EXISTS(SELECT ColumnName FROM Mo_ColumnDesc WHERE UPPER(TableName) = UPPER(@TableName) AND UPPER(ColumnName) = UPPER(@ColumnName))
				SELECT @Result = ColumnDesc
				FROM Mo_ColumnDesc 
				WHERE UPPER(TableName) = UPPER(@TableName)
					AND UPPER(ColumnName) = UPPER(@ColumnName)
			ELSE 
				SET @Result = '' 
		END
		
		IF @OldValue <> ''
			SET @Result = @Result + ' : ( ' + LTRIM(RTRIM(@OldValue)) + ' ) -> ( ' + LTRIM(RTRIM(@NewValue)) + ' )' + CHAR(13)
		ELSE
			SET @Result = @Result + ' : ' + LTRIM(RTRIM(@NewValue))+ CHAR(13)

	END -- IF (ISNULL(@OldValue, '') = '' AND ISNULL(@NewValue, '') = '') OR @OldValue = @NewValue
	
	RETURN(@Result) 

END

