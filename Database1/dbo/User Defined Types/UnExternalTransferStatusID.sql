CREATE TYPE [dbo].[UnExternalTransferStatusID]
    FROM VARCHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnExternalTransferStatusID] TO PUBLIC;

