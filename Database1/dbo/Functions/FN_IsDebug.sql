/****************************************************************************************************
Code de service :   FN_IsDebug
Nom du service  :   FN_IsDebug
But             :   Indique si on veut les «PRINT» de debuggage

Parametres d'entrée :
        Parametres          Description
        ----------          ----------------

Exemple d'appel:
        IF dbo.FN_IsDebug() <> 0 PRINT 'Debug Mode'

Parametres de sortie : Indicateur booléen

Historique des modifications :
    Date         Programmeur             Description
    ----------  --------------------    --------------------------------------------------------
    2015-08-13  Steeve Picard           Création de la fonction
    2018-01-03  Steeve Picard           Utilisation de la variable «@UserContext»
****************************************************************************************************/
CREATE FUNCTION dbo.FN_IsDebug() RETURNS bit AS
BEGIN
	DECLARE @Result bit = 0,
            @UserContext VARCHAR(128) = UPPER(dbo.GetUserContext())

	IF @UserContext = 'DEBUG' --OR APP_NAME() LIKE 'Microsoft SQL Server Management Studio - Query'
		SET @Result = 1

	IF @UserContext = 'IQEE'
		SET @Result = 0
		 
	RETURN @Result
END
