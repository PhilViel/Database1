CREATE TYPE [dbo].[MoSeparatorOption]
    FROM CHAR (1) NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoSeparatorOption] TO PUBLIC;

