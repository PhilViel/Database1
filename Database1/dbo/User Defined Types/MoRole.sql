﻿CREATE TYPE [dbo].[MoRole]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoRole] TO PUBLIC;
