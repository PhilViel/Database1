CREATE PROCEDURE [dbo].[SMo_HumanAdr]
 (@ConnectID    MoID,
  @HumanID      MoID)
AS
BEGIN

  SELECT A.*
  FROM dbo.Mo_Human H
    JOIN dbo.Mo_Adr A ON (A.AdrID = H.AdrID)
  WHERE (H.HumanID = @HumanID);
  
END;



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_HumanAdr] TO PUBLIC
    AS [dbo];

