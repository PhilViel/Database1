﻿CREATE TYPE [dbo].[MoCity]
    FROM VARCHAR (100) NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoCity] TO PUBLIC;

