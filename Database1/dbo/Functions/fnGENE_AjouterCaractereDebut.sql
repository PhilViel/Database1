/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		: fnGENE_AjouterCaractereDebut
Nom du service		: Ajouter des caractères au début d'un champ jusqu'à la longueur demandé
But 				: Formater une chaîne pour une longueur fixe
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@Chaine					    Chaîne à formater
						@NbCaractere				Nombre de caractères que la chaîne doit avoir
						@Caractere					Caractère à ajouter pour remplir la chaîne

Exemple d’appel		:	SELECT dbo.fnGENE_AjouterCaractereDebut('Test', 10, ' ')

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							vcChamp							Valeur formatée selon le caractère 
                                                                                    demandé et la longueur.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2017-07-20      Pierre-Luc Simard                   Création du service							
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_AjouterCaractereDebut](
      @Chaine VARCHAR(8000)
     ,@NbCaractere INT
     ,@Caractere CHAR(1) = ' ')
RETURNS VARCHAR(8000)
AS
BEGIN
    RETURN STUFF(@Chaine, 1, 0, REPLICATE(@Caractere, @NbCaractere - LEN(@Chaine)))
END
