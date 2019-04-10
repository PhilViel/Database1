/****************************************************************************************************
Copyrights (c) 2013 Gestion Universitas inc.

Code du service :			fnGENE_RechercherTexteSansAccent
Nom du service :			Rechercher une chaîne de caractères dans une autre, sans tenir compte des accents
But :								Rechercher une chaîne de caractères dans une autre, sans tenir compte des accents

Facette         :               GENE

Paramètres d’entrée :		Paramètre						Description
									--------------------------	-------------------------------------
									@vcSource					Chaîne de caractères dans laquelle on effectue la recherche
									@vcValueur_Recherche	Chaîne de caractères recherchée

Paramètres de sortie:		Paramètre						Description
									--------------------------	-------------------------------------
									@return							Indique si la chaîne a été trouvée (1 = Trouvée, 2 = Non-trouvée)

Exemple d’appel     :		SELECT dbo.fnGENE_RechercherTexteSansAccent('Cote', 'té')
										--Retourne 1
									SELECT dbo.fnGENE_RechercherTexteSansAccent('Coté', 'to')
										--Retourne 0

Historique des modifications:
    Date        Programmeur                 Description
    ----------  ------------------------    ---------------------------
    2013-06-20  Pierre-Luc Simard           Création du service
    2013-12-04  Pierre-Luc Simard           Utilisation des la collation Latin1_General_100_CI_AI pour les Ç
    2014-08-25  Pierre-Luc Simard           Utilisation de variables locales et de valeurs par défaut pour corriger le problème en production. 
    2016-06-01  Steeve Picard               Changement du collation pour prendre le même que celui de la BD mais accent sensitive
    2018-08-02  Steeve Picard               Utilistation de «PatIndex» au lieu de «CharIndex» pour utiliser les patterns
    2018-09-13  Steeve Picard               Remplacer les cédiles « Ç » par « C » car ne sont pas considérer par « IA : Incensitive Accent »

ATTENTION!! Pour Proacces, on doit refaire continuellement la fonction pour que ça fonctionne. 
            Si elle ets modifiée, on doit donc aussi modifier le traitement sur le serveur en production lors du déploiement.

**************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_RechercherTexteSansAccent] 
(
    @vcSource varchar(2000),
    @vcValeur_Recherche varchar(2000)
) 
RETURNS BIT
AS
BEGIN
    DECLARE 
		@return AS BIT = 0,
		@Source varchar(2000) = REPLACE(LOWER(@vcSource), 'ç', 'c'),
        @Valeur_Recherche varchar(2000) = '%' + REPLACE(REPLACE(LOWER(@vcValeur_Recherche), 'ç', 'c'), ' ', '%')+ '%'

                                         --Latin1_General_100_CI_AI
    --IF CHARINDEX(@Valeur_Recherche COLLATE SQL_Latin1_General_CP1_CI_AI, @Source COLLATE SQL_Latin1_General_CP1_CI_AI) > 0 
    IF PATINDEX(@Valeur_Recherche COLLATE SQL_Latin1_General_CP1_CI_AI, @Source COLLATE SQL_Latin1_General_CP1_CI_AI) > 0 
      SET @return = 1
    RETURN @return
END
