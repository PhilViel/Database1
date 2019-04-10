CREATE TYPE [dbo].[UnConventionStatus]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnConventionStatus] TO PUBLIC;

