﻿CREATE TYPE [dbo].[UnBenefLinkType]
    FROM SMALLINT NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnBenefLinkType] TO PUBLIC;

