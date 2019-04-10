CREATE TYPE [dbo].[UnInsurType]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnInsurType] TO PUBLIC;

