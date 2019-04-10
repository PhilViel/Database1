/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service     : fnREPR_ObtenirEpargneTotal
Nom du service      : Obtenir l'epargne cumulee total pour un représentant
But                 : Retourner la somme de l'epargne sur les convention d'un representant
Facette             : REPR

Paramètres d’entrée :   
    Paramètre                         Description
    ------------------------    -----------------------------------------------------------------
    RepID                       Identifiant du représentant
    dtDate                      Date pour laquelle on souhaite obtenir le calcul de l'épargne

Exemple d’appel : 
    SELECT 
        RepID, 
        dbo.fnREPR_ObtenirEpargneTotale(RepID, NULL)
    FROM un_Rep 
    WHERE RepID = 149665

    SELECT dbo.fnREPR_ObtenirEpargneTotale(149477, NULL)

Historique des modifications:
    Date            Programmeur             Description
    ----------  ------------------  ---------------------------------------------------------------------
    2017-06-07  Guehel Bouanga      Création du service
    2017-06-09  Maxime Martel       retourner 0 si la fonction fntREPR_ObtenirEpargneTotale retourne NULL
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fnREPR_ObtenirEpargneTotale]( 
	@RepID INT,
	@dtDate DATE = NULL)							
RETURNS MONEY
AS
	BEGIN
		DECLARE @mEpargne MONEY
 		SELECT @mEpargne = Epargne from dbo.[fntREPR_ObtenirEpargneTotale] (@RepID, ISNULL(@dtDate, GETDATE()))
        RETURN ISNULL(@mEpargne,0)
	END