CREATE TYPE [dbo].[UnGovernmentRegNo]
    FROM NVARCHAR (10) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnGovernmentRegNo] TO PUBLIC;

