CREATE TYPE [dbo].[MoUserState]
    FROM CHAR (1) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoUserState] TO PUBLIC;

