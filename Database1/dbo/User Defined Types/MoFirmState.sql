CREATE TYPE [dbo].[MoFirmState]
    FROM CHAR (1) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoFirmState] TO PUBLIC;

