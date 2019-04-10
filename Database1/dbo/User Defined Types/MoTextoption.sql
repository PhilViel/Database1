CREATE TYPE [dbo].[MoTextoption]
    FROM TEXT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoTextoption] TO PUBLIC;

