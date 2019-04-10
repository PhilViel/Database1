CREATE TYPE [dbo].[UnPaymentRequisition]
    FROM VARCHAR (10) NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnPaymentRequisition] TO PUBLIC;

