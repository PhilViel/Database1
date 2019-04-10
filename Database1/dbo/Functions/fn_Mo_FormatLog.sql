
--  dbo UDF fn_Mo_FormatLog
--	and returns the description of the modification type 
CREATE FUNCTION dbo.fn_Mo_FormatLog 
(
  @TableName        MoNoteDescOption, 
  @ColumnName	      MoNoteDescOption,
  @OldValue	        MoNoteDescOption,
  @NewValue	        MoNoteDescOption
)  
RETURNS MoNoteDescOption 
AS  
BEGIN
  DECLARE
    @Result MoDesc;

  IF (     (ISNULL(@OldValue, '') = '')
       AND (ISNULL(@NewValue, '') = ''))
    OR 
     (@OldValue = @NewValue)
    SET @Result = ''
  ELSE
  BEGIN	
    IF (@ColumnName = 'NEW') OR (@ColumnName = 'DEL') OR (@ColumnName = 'MODIF')
    BEGIN 
      SET @OldValue = ''
	    IF @ColumnName = 'NEW' 
        SET @Result = 'New in table ' + @TableName
	    ELSE IF @ColumnName = 'DEL'
        SET @Result = 'Deleted in table '+ @TableName
      ELSE IF @ColumnName = 'MODIF'
        SET @Result = 'Modification in table ' + @TableName
    END
    ELSE
    BEGIN
      IF EXISTS( SELECT 
                   ColumnName 
                 FROM Mo_ColumnDesc 
                 WHERE (UPPER(TableName) = UPPER(@TableName))
                   AND (UPPER(ColumnName) = UPPER(@ColumnName)))
        SELECT 
          @Result = ColumnDesc
        FROM Mo_ColumnDesc 
        WHERE (UPPER(TableName) = UPPER(@TableName))
          AND (UPPER(ColumnName) = UPPER(@ColumnName))
      ELSE 
        SET @Result = '' 
    END

	  IF @OldValue <> ''
	    SET @Result = @Result + ' : ( ' + LTRIM(RTRIM(@OldValue)) + ' ) -> ( ' + LTRIM(RTRIM(@NewValue)) + ' )'+CHAR(13)
	  ELSE
	    SET @Result = @Result + ' : ' + LTRIM(RTRIM(@NewValue))+ CHAR(13)
  END

  RETURN(@Result)                  
END

