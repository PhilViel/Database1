﻿CREATE TYPE [dbo].[MoNoteDesc]
    FROM VARCHAR (5000) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoNoteDesc] TO PUBLIC;

