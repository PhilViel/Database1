/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service     : fntREPR_ObtenirDirecteurRepresentant
Nom du service      : Obtenir le directeur pour un ou pour tous les représentants
But                 : Retourner le directeur ayant le plus haut pourcentage, pour chacun des représentant, à la date demandée
Facette             : REPR

Paramètres d’entrée :   
    Paramètre                         Description
    ------------------------    -----------------------------------------------------------------
    @RepID                      Identifiant du représentant
    @EnDateDu                   Date pour laquelle on souhaite obtenir les directeurs

Exemple d’appel : 
    SELECT * from dbo.[fntREPR_ObtenirDirecteurRepresentant] (DEFAULT, DEFAULT)
    SELECT * from dbo.[fntREPR_ObtenirDirecteurRepresentant] (149665, '2017-05-01')

Historique des modifications:
    Date        Programmeur         Description
    ----------  ------------------  --------------------------------------------------------------------
    2017-06-19  Pierre-Luc Simard   Création du service
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntREPR_ObtenirDirecteurRepresentant]
(
    @RepID INT = NULL,
	@EnDateDu DATE = NULL
)
RETURNS TABLE
AS RETURN
    SELECT
        R.RepID,
        BossID = ISNULL(B.BossID, 149876) -- Siège Social
    FROM Un_Rep R
    LEFT JOIN (
        SELECT
            RB.RepID ,
            BossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
        FROM Un_RepBossHist RB
        JOIN (
            SELECT
                RepID ,
                RepBossPct = MAX(RepBossPct)
            FROM Un_RepBossHist RB
            WHERE RB.RepID = ISNULL(@RepID, RB.RepID)
                AND RepRoleID = 'DIR'
                AND StartDate IS NOT NULL
                AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, ISNULL(@EnDateDu, GETDATE()), 120), 10)
                AND (EndDate IS NULL 
                    OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, ISNULL(@EnDateDu, GETDATE()), 120), 10))
            GROUP BY RepID
            ) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
        WHERE RB.RepID = ISNULL(@RepID, RB.RepID)
            AND RB.RepRoleID = 'DIR'
            AND RB.StartDate IS NOT NULL
            AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, ISNULL(@EnDateDu, GETDATE()), 120), 10)
            AND (RB.EndDate IS NULL
                 OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, ISNULL(@EnDateDu, GETDATE()), 120), 10))
        GROUP BY RB.RepID
        ) B ON R.RepID = b.RepID
    WHERE R.RepID = ISNULL(@RepID, R.RepID)