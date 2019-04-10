CREATE TYPE [dbo].[MoLedgerType]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoLedgerType] TO PUBLIC;

