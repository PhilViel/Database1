﻿CREATE TYPE [dbo].[MoBitTrue]
    FROM BIT NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoBitTrue] TO PUBLIC;

