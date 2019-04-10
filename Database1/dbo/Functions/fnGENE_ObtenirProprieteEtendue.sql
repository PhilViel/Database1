/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnGENE_ObtenirProprieteEtendue
Nom du service		: Obtenir une propriété étendue de la base de données
But 				: Retourner la valeur d’une propriété étendue de la base de données.
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@vcCode_Propriete			Code permettant de connaître la valeur de la propriété recherchée.

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							@vcValeur_Propriete					Valeur retournant le contenu de la propriété demandée.
Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2008-09-10		Josée Parent				Création du service							
		2008-09-15		Patrice Péau				Modification du type de la valeur de retour pour CSharp
		2008-09-18		Josée Parent				Modification du type de donnée de la valeur de retour et de
													son nom.
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ObtenirProprieteEtendue]
(	
	@vcCode_Propriete VARCHAR(30)
)
RETURNS VARCHAR(255)
AS
BEGIN
	--Valeur de retour
	DECLARE @vcValeur_Propriete VARCHAR(255);

	SET @vcValeur_Propriete = NULL;

	--Si le code de propriété est 'SERVEUR_SQL' on retourne le nom du serveur.
	IF @vcCode_Propriete = 'SERVEUR_SQL'
	BEGIN
		SET @vcValeur_Propriete = (SELECT @@servername);
	END
	ELSE
	BEGIN
		--Si le code de propriété est 'NOM_BD' on retourne le nom de la Base de Donnée.
		IF @vcCode_Propriete = 'NOM_BD'
		BEGIN
			SET @vcValeur_Propriete =  (SELECT DB_NAME() as [Current Database]);
		END
		ELSE
		BEGIN
			-- Sinon on retourne la valeur du code de propriété demandé.
			SET @vcValeur_Propriete =  (SELECT CONVERT(VARCHAR,value) FROM fn_listextendedproperty(@vcCode_Propriete, default, default, default, default, default, default));
		END
	END

	RETURN @vcValeur_Propriete;
END;







