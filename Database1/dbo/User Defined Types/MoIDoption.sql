CREATE TYPE [dbo].[MoIDoption]
    FROM INT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoIDoption] TO PUBLIC;

