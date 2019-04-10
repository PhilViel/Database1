CREATE TYPE [dbo].[MoRefStatus]
    FROM CHAR (1) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoRefStatus] TO PUBLIC;

