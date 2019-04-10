/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service : fnGENE_ObtenirPlusPetiteValeurMonetaire
Nom du service  : Obtenir la valeur monétaire la plus petite
But             : Obtenir la valeur monétaire la plus petite
                 
Facette         : GENE

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      @mValeur1                  Première valeur monétaire 
					  @mValeur2                  Deuxième valeur monétaire 


Paramètres de sortie: Paramètre                  Description
                      -------------------------- -------------------------------------
                      @mResultat				 Valeur minimum

Exemple d’appel     : SELECT dbo.fnGENE_ObtenirPlusPetiteValeurMonetaire(150.5, 200)
					  	
Historique des modifications:
        Date            Programmeur                        Description
        ------------    ---------------------------------- ---------------------------
        2018-05-17      Maxime Martel					   Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ObtenirPlusPetiteValeurMonetaire]
(
   @mValeur1 MoMoney,
   @mValeur2 MoMoney
)
RETURNS MoMoney
AS
BEGIN
	RETURN (0.5 * ((@mValeur1 + @mValeur2) - abs(@mValeur1 - @mValeur2))) 
END