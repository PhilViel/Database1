/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service  : fntREPR_ObtenirEligibiliteCommissionsSuivi
Nom du service	 : Obtenir l'éligibilité à commission de suivi
But 			 : Retourner le détail de l'éligibilité des représentants à une date donnée
Facette		     : REPR

Paramètres d’entrée	:   
    Paramètre				    Description
    ------------------------    -----------------------------------------------------------------
    RepID                       Identifiant du représentant
    dtDate			            Date pour laquelle on souhaite obtenir le détail de l'éligibilité

Exemple d’appel : 
    SELECT * from dbo.fntREPR_ObtenirEligibiliteCommissionsSuivi (DEFAULT, DEFAULT)
    SELECT * from dbo.fntREPR_ObtenirEligibiliteCommissionsSuivi (149665, '2017-05-01')


Historique des modifications:
    Date		Programmeur		    Description
    ----------  ------------------  ---------------------------------------------------------------------
    2017-05-31  Pierre-Luc Simard   Création du service
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntREPR_ObtenirEligibiliteCommissionsSuivi]
(
	@RepID INT = NULL,
    @dtDate DATE = NULL
)
RETURNS TABLE
AS RETURN
    WITH CTE_Rep AS (
        SELECT 
            idEligibilite,
            DateEligibilite,
            RepID,
            EstEligible,
            EstDirecteur,
            EstInactif,
            EstBloque,
            EpargneMinNonAtteint,
            AncienneteMinNonAtteinte,
            Row_Num = ROW_NUMBER() OVER(PARTITION BY RepID ORDER BY DateEligibilite DESC) 
        FROM tblREPR_CommissionsSuiviEligibilite
        WHERE DateEligibilite <= ISNULL(@dtDate, GETDATE()) 
            AND RepID = ISNULL(@RepID, RepID)
        )
    SELECT *
    FROM CTE_Rep
    WHERE Row_Num = 1