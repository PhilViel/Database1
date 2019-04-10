/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service     : fntREPR_ObtenirEpargneTotal
Nom du service      : Obtenir l'epargne cumulee total pour un ou pour tous les représentants
But                 : Retourner la somme de l'epargne sur les convention des representants
Facette             : REPR

Paramètres d’entrée :   
    Paramètre                         Description
    ------------------------    -----------------------------------------------------------------
    RepID                       Identifiant du représentant
    dtDate                      Date pour laquelle on souhaite obtenir le calcul de l'épargne

Exemple d’appel : 
    SELECT * from dbo.[fntREPR_ObtenirEpargneTotale] (DEFAULT, DEFAULT)
    SELECT * from dbo.[fntREPR_ObtenirEpargneTotale] (149665, '2017-05-01')

Historique des modifications:
    Date        Programmeur         Description
    ----------  ------------------  --------------------------------------------------------------------
    2017-06-07  Guehel Bouanga      Création du service
    2017-08-21	Steeve Picard		Optimisation
*********************************************************************************************************************/
CREATE FUNCTION dbo.fntREPR_ObtenirEpargneTotale
(
	@RepID INT = NULL,
    @dtDate DATE = NULL
)
RETURNS TABLE
AS RETURN
    SELECT 
        S.RepID,
        Epargne = SUM(CT.Cotisation) 
    FROM 
        Un_Subscriber S
        JOIN Un_Convention C ON S.SubscriberID = C.SubscriberID
        JOIN Un_Unit U ON U.ConventionID = C.ConventionID
        JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID 
        JOIN Un_Oper O ON O.OperID = CT.OperID
        JOIN fntCONV_ObtenirStatutUnitEnDate_PourTous(@dtDate, NULL) US ON US.UnitID = U.UnitID
    WHERE 
        S.RepID = ISNULL(@RepID, S.RepID)
        AND O.OperDate <= ISNULL(@dtDate, GETDATE()) 
        AND CHARINDEX(US.UnitStateID, 'REE,TRA,BRS,CPT,EPG,PAE,RCS,RIN', 1) <> 0
    GROUP BY 
        S.RepID
