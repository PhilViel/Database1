﻿CREATE TYPE [dbo].[MoAdrType]
    FROM CHAR (1) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoAdrType] TO PUBLIC;

