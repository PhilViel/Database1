/******************************************************************************
	Supprime une note
 ******************************************************************************
	2004-06-01 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE SP_DL_CRQ_Note (
	@ConnectID INTEGER, -- Id unique de la connection de l'usager
	@NoteID INTEGER) -- ID Unqiue de la note
AS
BEGIN
  DELETE FROM Mo_Note
  WHERE NoteID = @NoteID

  IF (@@ERROR = 0)
  BEGIN
    EXEC IMo_Log @ConnectID, 'Mo_Note', @NoteID, 'D', ''
    RETURN (@NoteID)
  END
  ELSE
    RETURN (0)
END;
