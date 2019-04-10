CREATE TYPE [dbo].[UnRepaymentReason]
    FROM SMALLINT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnRepaymentReason] TO PUBLIC;

