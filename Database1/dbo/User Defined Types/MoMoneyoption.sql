CREATE TYPE [dbo].[MoMoneyoption]
    FROM MONEY NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[MoMoneyoption] TO PUBLIC;

