﻿CREATE TYPE [dbo].[UnReason]
    FROM CHAR (1) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnReason] TO PUBLIC;

