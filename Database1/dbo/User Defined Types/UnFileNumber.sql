﻿CREATE TYPE [dbo].[UnFileNumber]
    FROM SMALLINT NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnFileNumber] TO PUBLIC;
