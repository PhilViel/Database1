CREATE TYPE [dbo].[UnProjectionType]
    FROM SMALLINT NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnProjectionType] TO PUBLIC;

