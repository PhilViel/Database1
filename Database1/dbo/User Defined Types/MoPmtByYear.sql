﻿CREATE TYPE [dbo].[MoPmtByYear]
    FROM SMALLINT NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoPmtByYear] TO PUBLIC;

