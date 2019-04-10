CREATE PROCEDURE SMo_AttributeType
 (@ConnectID     MoID,
  @TypeClassName VarChar(5000))
AS
BEGIN
  IF (@TypeClassName = 'OBJ')
    SELECT DISTINCT AttributeTypeClassName
    FROM Mo_AttributeType;
  ELSE
    IF (@TypeClassName = 'ALL')
      SELECT *
      FROM Mo_AttributeType
      ORDER BY AttributeTypeClassName;
    ELSE
      SELECT T.*
      FROM Mo_AttributeType T,
        fn_Mo_StringTable(@TypeClassName) S
      WHERE (Val = T.AttributeTypeClassName);
END;

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_AttributeType] TO PUBLIC
    AS [dbo];

