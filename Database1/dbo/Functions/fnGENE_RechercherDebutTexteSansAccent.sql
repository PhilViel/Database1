/****************************************************************************************************
Copyrights (c) 2013 Gestion Universitas inc.

Code du service :			[fnGENE_RechercherDebutTexteSansAccent]
Nom du service :			Rechercher une chaîne de caractères au début d'une autre, sans tenir compte des accents
But :								Rechercher une chaîne de caractères au début d'une autre, sans tenir compte des accents
                 
Facette         :               GENE

Paramètres d’entrée :		Paramètre						Description
									--------------------------	-------------------------------------
									@vcSource					Chaîne de caractères dans laquelle on effectue la recherche
									@vcValueur_Recherche	Chaîne de caractères recherchée

Paramètres de sortie:		Paramètre						Description
									--------------------------	-------------------------------------
									@return							Indique si la chaîne a été trouvée (1 = Trouvée, 2 = Non-trouvée)

Exemple d’appel     :		SELECT dbo.fnGENE_RechercherDebutTexteSansAccent('Rémi', 'ré')
										-- Retourne 1
									SELECT dbo.fnGENE_RechercherDebutTexteSansAccent('DoRéMi', 'ré')
										-- Retourne 0
                                                                                              
Historique des modifications:
        Date				Programmeur								Description
        ------------     ----------------------------------		---------------------------
        2013-09-09	Pierre-Luc Simard						Création du service
        2013-12-04	Pierre-Luc Simard						Utilisation des la collation Latin1_General_100_CI_AI pour les Ç

**************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_RechercherDebutTexteSansAccent] 
(
    @vcSource varchar(2000),
    @vcValeur_Recherche varchar(2000)
) 
RETURNS BIT
AS
BEGIN
    DECLARE @return AS BIT
	--IF @vcSource COLLATE SQL_Latin1_General_CP1_CI_AI LIKE @vcValeur_Recherche + '%' 
    IF @vcSource COLLATE Latin1_General_100_CI_AI LIKE @vcValeur_Recherche + '%'
      SET @return = 1
    ELSE
      SET @return = 0
    RETURN @return
END


