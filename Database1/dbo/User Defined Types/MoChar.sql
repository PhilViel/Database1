﻿CREATE TYPE [dbo].[MoChar]
    FROM CHAR (1) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoChar] TO PUBLIC;

