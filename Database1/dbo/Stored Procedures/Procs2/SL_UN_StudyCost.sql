/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_StudyCost
Description         :	Procédure qui renvoi la liste des coûts des études pour touts les années en ordre décroissant.
Valeurs de retours  :	Dataset :
					iYearQualif	INTEGER		Année de qualification
					fStudyCost	MONEY		Coût des études

Note                :	ADX0001158	IA	2006-10-10	Alain Quirion		Création
										2010-10-04  Jean-Francois Arial	Ajout du champ pour les coûts des études au Canada
**********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_StudyCost]
AS
BEGIN
	SELECT
		iYearQualif = YearQualif,
		fStudyCost = StudyCost,
		fStudyCostCA = StudyCostCA
	FROM Un_StudyCost
	ORDER BY YearQualif DESC
END
