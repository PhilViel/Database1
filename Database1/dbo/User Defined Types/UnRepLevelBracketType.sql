CREATE TYPE [dbo].[UnRepLevelBracketType]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnRepLevelBracketType] TO PUBLIC;

