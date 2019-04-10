CREATE TYPE [dbo].[UnRepContestType]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnRepContestType] TO PUBLIC;

