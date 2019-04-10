/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnOPER_ObtenirTypesOperationConvCategorie
Nom du service		: Obtenir les types d'opération sur convention d'une catégorie
But 				: Obtenir les codes des types d'opération sur convention faisant parties d'une catégorie d'opérations.
Facette				: OPER

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						vcCode_Categorie			Code de la catégorie d'opérations.

Exemple d’appel		:	SELECT [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('RIO-TRANSFERT-TRANSAC-CONVENTION')

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						tblOPER_OperationsCategorie	cID_Type_Oper_Convention		Liste des codes des types d'opération
																					sur les conventions.
																					S’il n’y a qu’un seul code dans
																					la catégorie, le service retourne
																					directement le code.
																					Exemple : « IBC »
																					Si la catégorie retourne plus d’un
																					code, le service retourne les codes
																					séparés par des virgules en gardant
																					une virgule au début et une virgule
																					à la fin de la chaîne pour prévenir
																					de confondre les codes qui seraient
																					similaire.
																					Exemple : « ,IS+,IST,INS, »
Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-07-13		Éric Deshaies						Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]
(
	@vcCode_Categorie VARCHAR(100)
)
RETURNS VARCHAR(200)
AS
BEGIN
	DECLARE @vcListe VARCHAR(200),
			@vcTMP CHAR(3),
			@iCompteur INT

	-- Rechercher les codes de la catégorie en paramètre
	DECLARE curOperations_Categorie CURSOR FOR
		SELECT OC.cID_Type_Oper_Convention
		FROM tblOPER_CategoriesOperation CO
		     JOIN tblOPER_OperationsCategorie OC ON OC.iID_Categorie_Oper = CO.iID_Categorie_Oper
												AND OC.cID_Type_Oper_Convention IS NOT NULL
		WHERE CO.vcCode_Categorie = @vcCode_Categorie
		  
	SET @vcListe = ''
	SET @iCompteur = 0

	OPEN curOperations_Categorie
	FETCH NEXT FROM curOperations_Categorie INTO @vcTMP
	WHILE @@FETCH_STATUS = 0
		BEGIN
			-- Assembler les codes trouvés dans une liste
			SET @vcListe = @vcListe + @vcTMP + ','
			SET @iCompteur = @iCompteur + 1

			FETCH NEXT FROM curOperations_Categorie INTO @vcTMP
		END
	CLOSE curOperations_Categorie
	DEALLOCATE curOperations_Categorie

	-- Mettre une virgule avant la liste s'il y a plusieurs codes
	IF @iCompteur > 1
		SET @vcListe = ','+@vcListe

	-- Enlever la virgule à la fin de la liste s'il n'y a qu'un seul code
	IF @iCompteur = 1
		SET @vcListe = SUBSTRING(@vcListe,1,LEN(@vcListe)-1)

	-- Retourner la liste des codes
	RETURN @vcListe
END

