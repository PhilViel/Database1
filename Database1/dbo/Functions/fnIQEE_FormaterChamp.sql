/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : fnIQEE_FormaterChamp
Nom du service  : Formater un champ d’un fichier de l’IQÉÉ 
But             : Formater un champ pour la création d’un fichier de l’IQÉÉ.
Facette         : IQÉÉ

Paramètres d’entrée :    
    Paramètre               Description
    --------------------    -----------------------------------------------------------------
    vaValeur                Valeur du champ à formater
    cType                   Type de la valeur à formater.
                                « A » = Données alphabétiques.
                                « X » = Tout caractère alphanumérique imprimable
                                « D » = Champ de type Date/Time qui sera converti en numérique.
                                « 9 » = Tout chiffre.
    siLongueur              Longueur de la chaine de caractères ou de la partie entière d’un nombre.
    tiDecimale              Longueur de la partie décimale d’un nombre.

Exemple d’appel :
    SELECT replace([dbo].[fnIQEE_FormaterChamp](NULL, '9', 9, 0), ' ', '_') 
    SELECT replace([dbo].[fnIQEE_FormaterChamp](NULL, 'A', 5, 0) , ' ', '_')
    SELECT replace([dbo].[fnIQEE_FormaterChamp](NULL, 'D', 8, 0) , ' ', '_')
    SELECT replace([dbo].[fnIQEE_FormaterChamp](NULL, 'X', 9, 0) , ' ', '_')
    SELECT [dbo].[fnIQEE_FormaterChamp]('-127788', '9', 9, 0)
    SELECT [dbo].[fnIQEE_FormaterChamp]('2017-09-20 8:30:59', 'D', 8, 0)
    SELECT [dbo].[fnIQEE_FormaterChamp]('abc123efg789', 'A', 8, 0)

Paramètres de sortie:
    Champ                   Description
    --------------------    ----------------------------------------------------------------
    vcChamp                 Valeur formatée selon le type et la longueur.

Historique des modifications:
    Date        Programmeur                 Description                                
    ----------  ------------------------    -----------------------------------------------------
    2008-05-28  Éric Deshaies               Création du service                            
    2017-09-14  Steeve Picard               Ajustement pour le padding de la valeur de retour
                                            Le paramètre «@siLongueur» est total incluant la partie «@tiDecimale»
    2018-02-02  Steeve Picard               Correction sur la valeur retourné si la valeur du paramètre est NULL dans les cas où @cType est '9' ou 'D'
****************************************************************************************************/
CREATE FUNCTION dbo.fnIQEE_FormaterChamp
(
    @vaValeur SQL_VARIANT,
    @cType CHAR(1),
    @siLongueur SMALLINT,
    @tiDecimale TINYINT = NULL
)
RETURNS VARCHAR(1000)
AS
BEGIN
    DECLARE
        @vcValeur VARCHAR(1000) = '',
        @iCompteur INT

    -- Si la longueur du champ est plus grand que 0
    IF ISNULL(@siLongueur, 0) <= 0
        RETURN 'Le paramètre «@siLongueur» doit être plus que 0'
    IF ISNULL(@tiDecimale, 0) >= @siLongueur
        RETURN 'Le paramètre «@tiDecimale» doit être plus petit que «@siLongueur»'

    --IF @vaValeur IS NULL
    --    RETURN SPACE(@siLongueur)

    -- Traiter les champs Alphanumériques
    IF @cType = 'X'
        BEGIN
            -- Convertion du variant en string
            SET @vcValeur = CAST(ISNULL(@vaValeur, '') AS VARCHAR(1000))

            -- Ajuster la longueur en supprimant les escpace du début
            SET @vcValeur = LEFT(LTRIM(@vcValeur) + SPACE(@siLongueur), @siLongueur)
        END

    -- Traiter les champs Numériques
    IF @cType = '9'
        BEGIN
            DECLARE
                @mMontant MONEY,
                @bNegatif BIT = 0

            IF @tiDecimale IS NULL
                SET @tiDecimale = 0

            -- Convertion du variant
            SET @mMontant = CAST(ISNULL(@vaValeur, 0) AS MONEY)

            -- Valeur absolue du nombre
            IF @mMontant < 0
                BEGIN
                    SET @bNegatif = 1
                    SET @mMontant = ABS(@mMontant)
                END

            -- Reconvertion en varchar(@siLongueur) en retirant le point s'il y a lieu
            SET @vcValeur = RIGHT(REPLACE(REPLACE(STR(@mMontant, @siLongueur + @tiDecimale + 1, @tiDecimale), '.', ''), ' ', '0'), @siLongueur)

            -- Mettre le signe négatif s'il le nombre ne paramètre est négatif
            IF @bNegatif = 1
                SET @vcValeur = STUFF(@vcValeur, 1, 1, '-')
        END

    -- Traiter les champs Dates
    IF @cType = 'D'
        BEGIN
            DECLARE @dtDate DATETIME

            -- Convertion du variant
            SET @dtDate = CAST(ISNULL(@vaValeur, 0) AS DATETIME)
            
            -- Formater la date
            SET @vcValeur = LEFT(REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(20), @dtDate, 120), '-', ''), ':', ''), ' ', ''), @siLongueur)
        END

    -- Traiter les champs Alphabétiques
    IF @cType = 'A'
        BEGIN
            -- Convertion du variant
            SET @vcValeur = LTRIM(CAST(ISNULL(@vaValeur,'') AS VARCHAR(1000)))

            -- Retirer les caractères invalides
            SET @iCompteur = PATINDEX('%[^A-Z]%',@vcValeur)
            WHILE @iCompteur > 0
                BEGIN
                    SET @vcValeur = STUFF(@vcValeur, @iCompteur, 1, '')
                    SET @iCompteur = PATINDEX('%[^A-Z]%',@vcValeur)
                END

            -- Trimmer ou ralonger pour atteindre la longueur désiré du champ
            SET @vcValeur = LEFT(@vcValeur + SPACE(@siLongueur), @siLongueur)
        END

    -- Retourner la valeur
    RETURN @vcValeur
END
