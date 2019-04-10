CREATE TYPE [dbo].[MoCharoption]
    FROM CHAR (1) NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoCharoption] TO PUBLIC;

