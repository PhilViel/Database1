/****************************************************************************************************

	Fonction DE FORMATAGE DES NUMÉROS DE TÉLÉPHONE

*********************************************************************************
	29-04-2004 Dominic Létourneau
		Migration de l'ancienne fonction selon les nouveaux standards
*********************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_FormatPhoneNo (
	@PhoneNo MoDesc, -- Numéro de téléphone en string
	@Country MoCountry) -- Identifiant du pays (Ex: CAN = Canada)
RETURNS MoDesc
AS

BEGIN

	DECLARE
		@PhoneNoStr MoDesc, 
		@RegionalCode Modesc,
		@LastDigits Modesc,
		@FirstDigits MoDesc,
		@Position MoID
	
	-- Validation du numéro de téléphone passé en paramètre
	IF @PhoneNo IS NULL
		RETURN('')
	
	-- Initialisation des variables
	SELECT 
		@PhoneNoStr = UPPER(REPLACE(RTRIM(LTRIM(@PhoneNo)), ' ', '')),
		@RegionalCode = '',
		@LastDigits = '',
		@FirstDigits = '',
		@Position = DATALENGTH(@PhoneNoStr)
	
	-- Si le numéro de téléphone est canadien et qu'il a au moins 6 caractères et au plus 11 caractères
	IF @Country = 'CAN' AND @Position > 6 AND @Position < 11
	BEGIN
	
		WHILE @Position > 0 -- On boucle à travers le numéro de téléphone
		BEGIN
		
			IF DATALENGTH(@LastDigits) < 4 -- On extrait les 4 dernieres chiffres
				SET @LastDigits = SUBSTRING(@PhoneNoStr, @Position, 1) + @LastDigits
			ELSE IF DATALENGTH(@FirstDigits) < 3 -- On extrait les 3 premiers chiffres
				SET @FirstDigits = SUBSTRING(@PhoneNoStr, @Position, 1) + @FirstDigits
			ELSE IF DATALENGTH(@RegionalCode) < 3 -- On extrait le code régional
				SET @RegionalCode = SUBSTRING(@PhoneNoStr, @Position, 1) + @RegionalCode
		
			SET @Position = @Position - 1  

		END
				
		IF @RegionalCode <> '' --  S'il y a un code régional
			SET @RegionalCode = '(' + @RegionalCode + ')' -- On lui ajoute les parenthèses
		
		-- Regroupement des différentes sections du numéro de téléphone le bon formattage
		SET @PhoneNoStr = @RegionalCode + SPACE(1) + @FirstDigits +'-'+ @LastDigits
	
	END
	ELSE -- Le numéro de téléphone n'est pas standard ou n'est pas canadien 
		SET @PhoneNoStr = @PhoneNo -- On retourne le numéro tel qu'on l'a reçu
	
	RETURN(@PhoneNoStr) -- Retour de la fonction

END

