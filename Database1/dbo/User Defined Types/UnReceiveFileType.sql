CREATE TYPE [dbo].[UnReceiveFileType]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnReceiveFileType] TO PUBLIC;

