﻿CREATE TYPE [dbo].[MoAdress]
    FROM VARCHAR (75) NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoAdress] TO PUBLIC;

