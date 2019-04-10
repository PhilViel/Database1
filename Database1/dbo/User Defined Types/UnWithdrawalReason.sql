CREATE TYPE [dbo].[UnWithdrawalReason]
    FROM SMALLINT NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnWithdrawalReason] TO PUBLIC;

