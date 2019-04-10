/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntOPER_ObtenirOperationsCategorie
Nom du service		: Obtenir les opérations d'une catégorie
But 				: Obtenir les codes d'opérations faisant parties d'une catégorie d'opérations.
Facette				: OPER

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						vcCode_Categorie			Code de la catégorie d'opérations.

Exemple d’appel		:	SELECT * FROM [dbo].[fntOPER_ObtenirOperationsCategorie]('RIO-TRANSFERT-TRANSAC-CONVENTION')

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						tblOPER_OperationsCategorie	cID_Type_Oper					Code du type d'opération.
						tblOPER_OperationsCategorie	cID_Type_Oper_Convention		Code du type d'opération sur
																					convention.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-07-13		Éric Deshaies						Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_ObtenirOperationsCategorie]
(
	@vcCode_Categorie VARCHAR(100)
)
RETURNS @tblOPER_OperationsCategorie TABLE
(
	cID_Type_Oper CHAR(3) NULL,
	cID_Type_Oper_Convention CHAR(3) NULL
)
AS
BEGIN
	-- Rechercher les codes de la catégorie en paramètre
	INSERT INTO @tblOPER_OperationsCategorie
	SELECT OC.cID_Type_Oper
		  ,OC.cID_Type_Oper_Convention
	FROM tblOPER_CategoriesOperation CO
		 JOIN tblOPER_OperationsCategorie OC ON OC.iID_Categorie_Oper = CO.iID_Categorie_Oper
	WHERE CO.vcCode_Categorie = @vcCode_Categorie

	-- Retourner les informations
	RETURN 
END

