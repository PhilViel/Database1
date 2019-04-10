CREATE TYPE [dbo].[MoCompanyName]
    FROM VARCHAR (75) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoCompanyName] TO PUBLIC;

