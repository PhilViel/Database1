CREATE TYPE [dbo].[MoFamilyRole]
    FROM CHAR (1) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoFamilyRole] TO PUBLIC;

