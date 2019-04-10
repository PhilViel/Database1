CREATE TYPE [dbo].[MoOptionCode]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoOptionCode] TO PUBLIC;

