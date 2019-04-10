CREATE TYPE [dbo].[UnScholarshipLevel]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnScholarshipLevel] TO PUBLIC;

