﻿CREATE TYPE [dbo].[UnPmtType]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnPmtType] TO PUBLIC;
