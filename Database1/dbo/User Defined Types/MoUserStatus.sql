CREATE TYPE [dbo].[MoUserStatus]
    FROM CHAR (1) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoUserStatus] TO PUBLIC;

