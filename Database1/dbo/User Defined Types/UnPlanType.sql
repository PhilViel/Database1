﻿CREATE TYPE [dbo].[UnPlanType]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnPlanType] TO PUBLIC;

