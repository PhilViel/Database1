/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnGENE_RemplacerStrNull
Nom du service		: Remplacer null ou chaîne vide
But 				: Remplacer la valeur d'un champ null ou vide par une nouvelle valeur.
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				vaValeurEntree				Valeur du champ à remplacer
						vaValeurSortie				Valeur de remplacement

Exemple d’appel		:	SELECT [dbo].[fnGENE_RemplacerStrNull]('', 'X')
						SELECT [dbo].[fnGENE_RemplacerStrNull]('Y', 'X')

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							@vcValeurSortie					Nouvelle valeur suite au remplacement 
																					si nécessaire

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-05-10		Pierre-Luc Simard					Création du service							

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_RemplacerStrNull]
(
	@vcValeurEntree VARCHAR(1000),	
	@vcValeurSortie VARCHAR(1000)
)	
RETURNS VARCHAR(1000)
AS
BEGIN
	
	SET @vcValeurEntree = LTRIM(RTRIM(@vcValeurEntree))

	-- Si la longueur du champ est plus grand que 0
	IF @vcValeurEntree IS NOT NULL AND LEN(@vcValeurEntree) > 0
		BEGIN
			SET @vcValeurSortie = @vcValeurEntree
			-- Retourner la valeur originale
			RETURN @vcValeurSortie
		END

	--  Retourner  si la taille est 0
	RETURN @vcValeurSortie
END

