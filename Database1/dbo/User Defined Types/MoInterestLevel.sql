CREATE TYPE [dbo].[MoInterestLevel]
    FROM CHAR (1) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoInterestLevel] TO PUBLIC;

