﻿CREATE TYPE [dbo].[MoMoney]
    FROM MONEY NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoMoney] TO PUBLIC;
