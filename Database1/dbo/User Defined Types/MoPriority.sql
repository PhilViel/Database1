﻿CREATE TYPE [dbo].[MoPriority]
    FROM SMALLINT NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoPriority] TO PUBLIC;

