/****************************************************************************************************
Copyrights (c) 2013 Gestion Universitas inc.

Code du service :			fnGENE_ComparerTexteSansAccent
Nom du service  :			Comparer deux chaînes de caractères, sans tenir compte des accents
But :								Comparer deux chaînes de caractères, sans tenir compte des accents
                 
Facette :						GENE

Paramètres d’entrée :		Paramètre						Description
									--------------------------	-------------------------------------
									@vcTexte1						Chaîne de caractères 
									@vcTexte2						Chaîne de caractères  

Paramètres de sortie:		Paramètre						Description
									--------------------------	-------------------------------------
									@return							Indique si les chaînes sont identiques (1 = Identique, 2 = Non-identique)

Exemple d’appel     :		SELECT dbo.fnGENE_ComparerTexteSansAccent('Coté', 'Cote')
										Retourne 1
									SELECT dbo.fnGENE_ComparerTexteSansAccent('Coté', 'Cot')
										Retourne 0
                                                                                              
Historique des modifications:
        Date				Programmeur								Description
        ------------		----------------------------------		---------------------------
        2013-06-20	Pierre-Luc Simard                      Création du service
        2013-12-04	Pierre-Luc Simard						Utilisation des la collation Latin1_General_100_CI_AI pour les Ç

**************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ComparerTexteSansAccent]
(
    @vcTexte1 varchar(2000),
    @vcTexte2 varchar(2000)
) 
RETURNS BIT
AS
BEGIN
    DECLARE @return AS BIT
    --IF @vcTexte1 COLLATE SQL_Latin1_General_CP1_CI_AI = @vcTexte2 COLLATE SQL_Latin1_General_CP1_CI_AI
	IF @vcTexte1 COLLATE Latin1_General_100_CI_AI = @vcTexte2 COLLATE Latin1_General_100_CI_AI 
      SET @return = 1
    ELSE
      SET @return = 0
    RETURN @return
END
