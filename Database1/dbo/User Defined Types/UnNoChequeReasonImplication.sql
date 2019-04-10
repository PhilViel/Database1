CREATE TYPE [dbo].[UnNoChequeReasonImplication]
    FROM SMALLINT NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnNoChequeReasonImplication] TO PUBLIC;

