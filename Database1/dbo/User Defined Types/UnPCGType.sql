﻿CREATE TYPE [dbo].[UnPCGType]
    FROM TINYINT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnPCGType] TO PUBLIC;

