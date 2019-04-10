CREATE TYPE [dbo].[UnTreatmentDay]
    FROM SMALLINT NOT NULL;


GO
GRANT REFERENCES
    ON TYPE::[dbo].[UnTreatmentDay] TO PUBLIC;

