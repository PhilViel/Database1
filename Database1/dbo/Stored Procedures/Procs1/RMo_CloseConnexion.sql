CREATE PROCEDURE RMo_CloseConnexion
/* Fermeture d'une connexion */
  (@ConnectID           MoID)
AS
BEGIN
  BEGIN TRANSACTION

  UPDATE Mo_Connect SET
    ConnectEnd = GetDate()
  WHERE (ConnectID = @ConnectID);

  IF (@@ERROR = 0)
    COMMIT TRANSACTION
  ELSE
    ROLLBACK TRANSACTION

  IF (@@ERROR <> 0)
    RETURN (0);

  RETURN (1);
END;

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[RMo_CloseConnexion] TO PUBLIC
    AS [dbo];

