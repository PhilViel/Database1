CREATE TYPE [dbo].[MoBitOption]
    FROM BIT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoBitOption] TO PUBLIC;

