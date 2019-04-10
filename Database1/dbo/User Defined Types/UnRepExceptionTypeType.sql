CREATE TYPE [dbo].[UnRepExceptionTypeType]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnRepExceptionTypeType] TO PUBLIC;

