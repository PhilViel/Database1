CREATE TYPE [dbo].[MoDateoption]
    FROM DATETIME NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoDateoption] TO PUBLIC;

