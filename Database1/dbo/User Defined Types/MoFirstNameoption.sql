CREATE TYPE [dbo].[MoFirstNameoption]
    FROM VARCHAR (35) NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoFirstNameoption] TO PUBLIC;

