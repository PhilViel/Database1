CREATE TYPE [dbo].[UnScholarshipStatus]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnScholarshipStatus] TO PUBLIC;

