/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CRI_CheckSin
Description 		:	Retourne si le NAS passe le calcul de coefficient 10 ou 10 amélioré selon s'il ne s'agit pas 
							d'une compagnie et est composé de 9 chiffres
Valeurs de retour	:	Table temporaire
Note					:	ADX0000709	IA	2006-11-13	Bruno Lapointe		Création
											2008-03-28	Pierre-Luc Simard	Le NAS peut maintenant débuté par 0 ou 3
*******************************************************************************************************************/
CREATE FUNCTION [dbo].[FN_CRI_CheckSin] (
	@vcSin VARCHAR(75), -- ID de processus de la procédure stockée qui appel la fonction
	@bIsCompany BIT ) -- Indique S'il s'agit d'une compagnie, si oui, c'est le calcul de coefficient 10 qui est appliqué
							-- et non le calcul de coefficient 10 amélioré. 
RETURNS BIT
BEGIN
	DECLARE
		@bResult BIT,
		@iPos INTEGER,
		@iNumber INTEGER,
		@iTotalFirstStep MONEY,
		@VerifNumber INTEGER

	SET @bResult = 1 
	SET @iPos = 1
	SET @iTotalFirstStep = 0

	IF	@vcSin IS NULL
		OR LEN(@vcSin) <> 9
		OR (SUBSTRING(@vcSin, 1, 1) = '8' AND @bIsCompany = 0) --IN ('0','3','8') AND @bIsCompany = 0) -- Le '0' et le '3' ont été enlevés de la liste d'exclusion selon les nouvelles normes.
		SET @bResult = 0
	ELSE IF	NOT SUBSTRING ( @vcSin, 1, 1 ) BETWEEN '0' AND '9'
			OR NOT SUBSTRING ( @vcSin, 2, 1 ) BETWEEN '0' AND '9'
			OR NOT SUBSTRING ( @vcSin, 3, 1 ) BETWEEN '0' AND '9'
			OR NOT SUBSTRING ( @vcSin, 4, 1 ) BETWEEN '0' AND '9'
			OR NOT SUBSTRING ( @vcSin, 5, 1 ) BETWEEN '0' AND '9'
			OR NOT SUBSTRING ( @vcSin, 6, 1 ) BETWEEN '0' AND '9'
			OR NOT SUBSTRING ( @vcSin, 7, 1 ) BETWEEN '0' AND '9'
			OR NOT SUBSTRING ( @vcSin, 8, 1 ) BETWEEN '0' AND '9'
			OR NOT SUBSTRING ( @vcSin, 9, 1 ) BETWEEN '0' AND '9'
		SET @bResult = 0

	IF @bResult = 1
	BEGIN
		WHILE @iPos < 9
		BEGIN
			SET @iNumber = CAST(SUBSTRING(@vcSin, @iPos, 1) AS INTEGER)
	
			IF @iPos IN (2,4,6,8)
				SET @iNumber = @iNumber * 2
	
			IF @iNumber > 9
				SET @iNumber = FLOOR(@iNumber / 10) + (@iNumber % 10)
	
			SET @iTotalFirstStep = @iTotalFirstStep + @iNumber
			SET @iPos = @iPos + 1
		END
	
		SET @VerifNumber = ABS(@iTotalFirstStep - ( CEILING(@iTotalFirstStep / 10) * 10 ))

		IF @VerifNumber <> CAST(SUBSTRING(@vcSin, 9, 1) AS INTEGER)
			SET @bResult = 0
	END

	RETURN @bResult
END


