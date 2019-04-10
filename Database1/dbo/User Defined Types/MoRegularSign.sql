CREATE TYPE [dbo].[MoRegularSign]
    FROM CHAR (2) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoRegularSign] TO PUBLIC;

