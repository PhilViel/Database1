

-- Optimisé version 26
CREATE PROC RUn_FormatLog (
@ModificationType MoNoteDescOption,
@OldValue MoNoteDescOption,
@NewValue MoNoteDescOption,
@ResultDesc MoNoteDescOption OUTPUT)
AS
BEGIN

  --Unité
  IF @ModificationType = 'UNITQTY' SET @ResultDesc = 'Nombre d''unités : '
  IF @ModificationType = 'INFORCEDATE' SET @ResultDesc = 'Date de vigueur : '
  IF @ModificationType = 'REPRESENTATIVE' SET @ResultDesc = 'Représentant : '

  IF @OldValue <> ''
    SET @ResultDesc = @ResultDesc + '(' + LTRIM(RTRIM(@OldValue)) + ') -> (' + LTRIM(RTRIM(@NewValue)) + ')' + CHAR(13)
  ELSE
    SET @ResultDesc = @ResultDesc + LTRIM(RTRIM(@NewValue)) + CHAR(13)

END;

