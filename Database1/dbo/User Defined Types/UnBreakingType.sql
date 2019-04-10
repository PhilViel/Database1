CREATE TYPE [dbo].[UnBreakingType]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnBreakingType] TO PUBLIC;

