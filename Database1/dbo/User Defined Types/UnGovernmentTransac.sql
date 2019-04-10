CREATE TYPE [dbo].[UnGovernmentTransac]
    FROM VARCHAR (500) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnGovernmentTransac] TO PUBLIC;

