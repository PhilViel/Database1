CREATE TYPE [dbo].[MoCountry]
    FROM CHAR (4) NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoCountry] TO PUBLIC;

