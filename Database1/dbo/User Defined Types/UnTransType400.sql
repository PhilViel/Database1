﻿CREATE TYPE [dbo].[UnTransType400]
    FROM SMALLINT NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnTransType400] TO PUBLIC;

