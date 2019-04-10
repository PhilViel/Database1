CREATE TYPE [dbo].[MoOptionCodeOption]
    FROM CHAR (3) NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoOptionCodeOption] TO PUBLIC;

