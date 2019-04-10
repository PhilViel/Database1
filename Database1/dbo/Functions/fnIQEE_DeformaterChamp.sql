/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnIQEE_DeformaterChamp
Nom du service		: Déformater un champ d’un fichier de l’IQÉÉ 
But 				: Déformater un champ pour l'importation d’un fichier de l’IQÉÉ.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				vaValeur					Valeur du champ à déformater
						cType						Type de la valeur à déformater.
													« A » = Données alphabétiques.
													« X » = Tout caractère alphanumérique imprimable
													« D » = Champ de type Date/Time qui sera converti en numérique.
													« 9 » = Tout chiffre.
						siLongueur					Longueur de la chaine de caractères.
						tiDecimale					Longueur de la partie décimale d’un nombre.

Exemple d’appel		:	select [dbo].[fnIQEE_DeformaterChamp]('Deshaies', 'X', 20, 0)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							vcChamp							Valeur formatée selon le type et
																					la longueur.

Historique des modifications:
		Date			Programmeur					Description
		------------	-------------------------   -----------------------------------------------------
		2009-05-12		Éric Deshaies				Création du service							
        2017-08-14      Steeve Picard               Force à retourner la date à «1900-01-01» au minimum car on peut recevoir «00010101» de RQ
        2018-05-08      Steeve Picard               Retourne un type entier si numérique sans décimal
****************************************************************************************************/
CREATE FUNCTION dbo.fnIQEE_DeformaterChamp
(
	@vcValeur VARCHAR(1000),
	@cType CHAR(1),
	@siLongueur SMALLINT,
	@tiDecimale TINYINT
)
RETURNS SQL_VARIANT
AS
BEGIN
	-- Si la valeur est nulle, retourner la même valeur
	IF @vcValeur IS NULL
		RETURN NULL

	-- Traiter les champs Alphanumériques et Alphabétiques
	IF @cType = 'X' OR @cType = 'A'
		BEGIN
			IF @siLongueur IS NULL
				SET @siLongueur = LEN(@vcValeur)

			-- Enlever les espaces à droite et retourner la chaîne
			RETURN SUBSTRING(RTRIM(@vcValeur),1,@siLongueur)
		END

	-- Traiter les champs Numériques
	IF @cType = '9'
		BEGIN
			DECLARE
				@mMontant MONEY,
				@bNegatif BIT

			IF @tiDecimale IS NULL
				SET @tiDecimale = 0

			-- Déterminer si c'est un montant négatif
			IF SUBSTRING(@vcValeur,1,1) = '-'
				BEGIN
					SET @bNegatif = 1
					SET @vcValeur = '0'+SUBSTRING(@vcValeur,2,LEN(@vcValeur)-1)
				END
			ELSE
				SET @bNegatif = 0

			-- Convertir en numérique
			SET @mMontant = CAST(@vcValeur AS MONEY)

			-- Déplacer la virgule selon le nombre de décimale
			IF @tiDecimale > 0
				SET @mMontant = @mMontant / POWER(10,@tiDecimale)

			-- Appliquer le moins pour un montant négatif
			IF @bNegatif = 1
				SET @mMontant = @mMontant * -1

			-- Retourner la valeur
            IF @tiDecimale = 0
            BEGIN 
                IF @mMontant >= 2^31
			        RETURN CAST(@mMontant AS BIGINT)
                ELSE
                    RETURN CAST(@mMontant AS INT)
            END 
            ELSE
                RETURN @mMontant
		END

	-- Traiter les champs Dates
	IF @cType = 'D'
		BEGIN
			DECLARE @dtDate DATETIME2

			-- Convertion en date
			SET @dtDate = CAST(@vcValeur AS DATETIME2)

            IF Year(@dtDate) < 1900
                SET @dtDate = Cast(0 AS datetime) -- Min value of DATETIME is 1753-01-01
			
			-- Retourner la valeur date
			RETURN @dtDate
		END

	--  Retourner la valeur d'entrée si le type est inconnu
	RETURN @vcValeur
END
