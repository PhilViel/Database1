CREATE TYPE [dbo].[MoInitial]
    FROM VARCHAR (4) NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoInitial] TO PUBLIC;

