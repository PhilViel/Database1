CREATE TYPE [dbo].[UnTransactionType]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnTransactionType] TO PUBLIC;

