﻿CREATE TYPE [dbo].[MoLang]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoLang] TO PUBLIC;
