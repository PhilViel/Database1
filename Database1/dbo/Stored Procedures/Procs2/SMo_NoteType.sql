CREATE  PROCEDURE SMo_NoteType
 (@ConnectID     MoID,
  @TypeClassName VarChar(5000))
AS
BEGIN
  IF (@TypeClassName = 'OBJ')
    SELECT DISTINCT NoteTypeClassName
    FROM Mo_NoteType;
  ELSE
    IF (@TypeClassName = 'ALL') OR (@TypeClassName IS NULL)
      SELECT *
      FROM Mo_NoteType
    ELSE
      SELECT
        T.NoteTypeID,
        T.NoteTypeClassName,
        T.NoteTypeDesc,
        T.NoteTypeLogText,
        T.NoteTypeAllowObject
      FROM Mo_NoteType T,
        fn_Mo_StringTable(@TypeClassName) S
      WHERE (S.Val = T.NoteTypeClassName)
      ORDER BY T.NoteTypeClassName, T.NoteTypeDesc;
END;

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_NoteType] TO PUBLIC
    AS [dbo];

