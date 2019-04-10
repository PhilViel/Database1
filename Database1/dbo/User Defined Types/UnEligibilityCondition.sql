CREATE TYPE [dbo].[UnEligibilityCondition]
    FROM CHAR (3) NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnEligibilityCondition] TO PUBLIC;

