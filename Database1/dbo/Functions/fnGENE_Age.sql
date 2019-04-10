/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnGENE_Age
Nom du service		: Retourne l'âge selon la date d'anniversaire à une date donnée.
But 				: Calculer l'âge d'une personne.
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				BirthDate					Date de naissance
                        AsDate                      Date à laquelle on évalue l'âge

Exemple d’appel		:	SELECT dbo.fnGENE_Age('2000-01-01', GetDate())


Historique des modifications :
	Date        Programmeur             Description
	----------  --------------------    ------------------------------------------------------------
	2017-11-08	Steeve Picard           Création du service
****************************************************************************************************/
CREATE FUNCTION dbo.fnGENE_Age  
(	
  @BirthDate       Date,
  @AsDate          Date
)
RETURNS int AS
BEGIN
    DECLARE @Age INT = 0

    IF @BirthDate < @AsDate
    BEGIN
        SET @Age = DATEDIFF(YY, @BirthDate, @AsDate) 

        DECLARE @BirthMonth INT = DATEPART(m, @BirthDate),
                @AsMonth INT = DATEPART(m, @AsDate)

        IF @BirthMonth > @AsMonth OR (@BirthMonth = @AsMonth AND DATEPART(d, @BirthDate) > DATEPART(d, @AsDate))
        BEGIN
                SET @Age = @Age - 1
        END
    END 

    RETURN @Age
END
