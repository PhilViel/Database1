/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_StudyCost 
Description         :	Procédure qui insère ou met à jour un coût des études pour une année de qualification.
Valeurs de retours  :	@ReturnValue :
					> 0 : [Réussite]
					<= 0 : [Échec].
Note                :	ADX0001158	IA	2006-10-10	Alain Quirion		Création
										2010-10-04  Jean-Francois Arial	Ajout du champ pour les coûts des études au Canada
**********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_StudyCost](
@iYearQualif INTEGER,		-- Année de qualification
@fStudyCost FLOAT,			-- Coût des études au Québec
@fStudyCostCA FLOAT)		-- Coût des études au Canada
AS
BEGIN
	DECLARE @iReturn INTEGER

	SET @iReturn = 1
	
	IF NOT EXISTS(SELECT * FROM Un_StudyCost WHERE YearQualif = @iYearQualif)
	BEGIN
		INSERT INTO Un_StudyCost(YearQualif, StudyCost, StudyCostCA)
		VALUES(@iYearQualif, @fStudyCost, @fStudyCostCA)

		IF @@ERROR <> 0
			SET @iReturn = -1
	END
	ELSE
	BEGIN
		UPDATE Un_StudyCost
		SET StudyCost = @fStudyCost,
			StudyCostCA = @fStudyCostCA
		WHERE YearQualif = @iYearQualif

		IF @@ERROR <> 0
			SET @iReturn = -2
	END
	
	RETURN @iReturn
END
