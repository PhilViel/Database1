CREATE TYPE [dbo].[UnCollegeType]
    FROM CHAR (2) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnCollegeType] TO PUBLIC;

