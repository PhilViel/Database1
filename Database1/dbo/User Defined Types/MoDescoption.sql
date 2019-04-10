CREATE TYPE [dbo].[MoDescoption]
    FROM VARCHAR (75) NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoDescoption] TO PUBLIC;

