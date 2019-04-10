CREATE TYPE [dbo].[MoFirmStatus]
    FROM CHAR (1) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoFirmStatus] TO PUBLIC;

