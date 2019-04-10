CREATE TYPE [dbo].[MoLogaction]
    FROM CHAR (1) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoLogaction] TO PUBLIC;

