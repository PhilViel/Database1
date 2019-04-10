CREATE TYPE [dbo].[MoLongDescoption]
    FROM VARCHAR (255) NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoLongDescoption] TO PUBLIC;

