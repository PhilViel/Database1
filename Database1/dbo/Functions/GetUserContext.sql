CREATE FUNCTION [dbo].[GetUserContext] ()
RETURNS VARCHAR(128)
AS
BEGIN
	DECLARE @UserContext VARCHAR(128),
			@Pos int = 128

	SET @UserContext = IsNull(Convert(VARCHAR(128), CONTEXT_INFO()), '')

	SET @Pos = CharIndex(CHAR(0), @UserContext, 1)
	IF @Pos > 0
		SET @UserContext = SubString(@UserContext, 1, @Pos - 1)

	IF RTrim(@UserContext) = ''
		SET @UserContext = SUSER_NAME()

    RETURN RTrim(@UserContext)
END
