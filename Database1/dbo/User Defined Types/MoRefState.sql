﻿CREATE TYPE [dbo].[MoRefState]
    FROM CHAR (1) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoRefState] TO PUBLIC;

