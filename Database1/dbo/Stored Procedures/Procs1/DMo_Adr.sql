
CREATE PROCEDURE [dbo].[DMo_Adr]
 (@ConnectID    MoID,
  @AdrID        MoIDOption)
AS
BEGIN
  DECLARE
    @SourceID   MoID,
    @AdrTypeID  MoAdrType;

  IF (NOT (@AdrID IS NULL) )
  BEGIN
    IF EXISTS (SELECT *
               FROM dbo.Mo_Adr 
               WHERE (AdrID = @AdrID) )
    BEGIN
      BEGIN TRANSACTION

      SELECT
        @SourceID = SourceID,
        @AdrTypeID = AdrTypeID
      FROM dbo.Mo_Adr 
      WHERE (AdrID = @AdrID);

      IF @AdrTypeID= 'H'
        UPDATE dbo.Mo_Human SET
          AdrID = (SELECT MAX(AdrID)
                   FROM dbo.Mo_Adr 
                   WHERE (SourceID = @SourceID)
                     AND (AdrTypeID = @AdrTypeID)
                     AND (AdrID <> @AdrID)
                     AND (InForce = (SELECT MAX(InForce)
                                     FROM dbo.Mo_Adr 
                                     WHERE (InForce <= GETDATE())
                                       AND (SourceID = @SourceID)
                                       AND (AdrTypeID = @AdrTypeID)
                                       AND (AdrID  <> @AdrID)))  )
        WHERE AdrID = @AdrID;
      ELSE
        UPDATE Mo_Dep SET
          AdrID = (SELECT MAX(AdrID)
                   FROM dbo.Mo_Adr 
                   WHERE (SourceID = @SourceID)
                     AND (AdrTypeID = @AdrTypeID)
                     AND (AdrID <> @AdrID)
                     AND (InForce = (SELECT MAX(InForce)
                                     FROM dbo.Mo_Adr 
                                     WHERE (InForce <= GETDATE())
                                       AND (SourceID = @SourceID)
                                       AND (AdrTypeID = @AdrTypeID)
                                       AND (AdrID  <> @AdrID)))  )
        WHERE AdrID = @AdrID;

      DELETE FROM dbo.Mo_Adr 
      WHERE (AdrID = @AdrID);

      IF (@@ERROR = 0)
      BEGIN
        COMMIT TRANSACTION;
        RETURN (@AdrID);
      END
      ELSE
      BEGIN
        ROLLBACK TRANSACTION;
        RETURN (0);
      END
    END
    ELSE
      RETURN (@AdrID);
  END
  ELSE
    RETURN (1);
END;



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[DMo_Adr] TO PUBLIC
    AS [dbo];

