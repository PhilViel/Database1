CREATE TYPE [dbo].[UnGovernmentShipCode]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnGovernmentShipCode] TO PUBLIC;

