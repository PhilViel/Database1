CREATE TYPE [dbo].[MoLastNameoption]
    FROM VARCHAR (50) NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoLastNameoption] TO PUBLIC;

