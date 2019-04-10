/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_StudyCost 
Description         :	Procédure qui supprime un coût des études pour une année de qualification.
Valeurs de retours  :	@ReturnValue :
					> 0 : [Réussite]
					<= 0 : [Échec].
Note                :	ADX0001158	IA	2006-10-10	Alain Quirion		Création
**********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_StudyCost](
@iYearQualif INTEGER)		-- Année de qualification
AS
BEGIN
	DECLARE @iReturn INTEGER

	SET @iReturn = 1
	
	IF EXISTS(SELECT * FROM Un_StudyCost WHERE YearQualif = @iYearQualif)
	BEGIN
		DELETE 
		FROM Un_StudyCost
		WHERE YearQualif = @iYearQualif

		IF @@ERROR <> 0
			SET @iReturn = -1
	END
	
	RETURN @iReturn
END

