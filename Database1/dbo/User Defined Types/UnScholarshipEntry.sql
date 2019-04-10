CREATE TYPE [dbo].[UnScholarshipEntry]
    FROM CHAR (1) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnScholarshipEntry] TO PUBLIC;

