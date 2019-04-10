CREATE PROCEDURE DMo_NoteWithClassName
 (@ConnectID            MoID,
  @NoteCodeID           MoID,
  @NoteTypeClassName    MoNoteDescOption)
AS
BEGIN
  BEGIN TRANSACTION

  SELECT
    val as ClassName
  INTO #ClassNameTable
  FROM fn_Mo_StringTable(@NoteTypeClassName);

  DELETE FROM Mo_Note
  WHERE NoteID IN ( SELECT NoteID
                    FROM Mo_Note N
                    INNER JOIN Mo_NoteType T ON (T.NoteTypeID=N.NoteTypeID)
                    INNER JOIN #ClassNameTable C ON (C.ClassName=T.NoteTypeClassName)
                    WHERE NoteCodeID=@NoteCodeID )

  IF (@@ERROR = 0)
  BEGIN
    COMMIT TRANSACTION
    RETURN (@NoteCodeID);
  END
  ELSE
  BEGIN
    ROLLBACK TRANSACTION
    RETURN (0);
  END
END;
