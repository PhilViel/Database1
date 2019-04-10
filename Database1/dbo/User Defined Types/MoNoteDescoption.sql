CREATE TYPE [dbo].[MoNoteDescoption]
    FROM VARCHAR (5000) NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoNoteDescoption] TO PUBLIC;

