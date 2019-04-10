/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas Inc.
Nom                 :	psREPR_RapportAdmissibleCommissionsSuivi
Description         :	Procédure stockée du rapport pour l,admissibilité des représentants à la commissions de suivi
Valeurs de retours  :	Dataset 
Note                :	

Historique:    
    2017-06-20  Philippe Dube-Tremblay  Création de procédure stockée.

Exemple d’appel : 
    exec psREPR_RapportAdmissibleCommissionsSuivi '2017-05-01', DEFAULT
    exec psREPR_RapportAdmissibleCommissionsSuivi '2017-05-01', 149469
	
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_RapportAdmissibleCommissionsSuivi]
    @Date DATETIME,
    @IdRepresentant INTEGER = NULL
AS
BEGIN
    
    ;WITH CTE_Rep AS (
        SELECT 
            RE.RepID,
            RE.DateEligibilite,
            RE.EstEligible,
            RE.EstBloque,
            RE.EpargneMinNonAtteint,
            RE.AncienneteMinNonAtteinte,
            DR.BossID
        FROM fntREPR_ObtenirEligibiliteCommissionsSuivi(NULL, @Date) RE
        JOIN dbo.fntREPR_ObtenirDirecteurRepresentant(NULL, @Date) DR ON DR.RepID = RE.RepID
        WHERE (RE.RepID = ISNULL(@IdRepresentant, RE.RepID) 
                OR DR.BossID = ISNULL(@IdRepresentant, DR.BossID))
            AND RE.EstDirecteur = 0
            AND RE.EstInactif = 0
    ) 
    SELECT 
        DirecteurID = CR.BossID,
        DirecteurCode = D.RepCode,
        Directeur = HD.LastName + ', ' + HD.FirstName,
        RepID = CR.RepID,
        R.RepCode,
        Representant = HR.LastName + ', ' + HR.FirstName,
        NombreMoisActivite = DATEDIFF(MONTH, R.BusinessStart, DATEADD(SECOND, -1, @Date)),
        Date36MoisAtteint = DATEADD(MONTH, 36, R.BusinessStart),
        CR.DateEligibilite,
        CR.EstEligible,
        CR.EstBloque,
        CR.EpargneMinNonAtteint,
        CR.AncienneteMinNonAtteinte,
        ObjectifAtteint = EA.EpargneMinAtteint,
        SousObjectif = ENA.Date_EpargneMinNonAtteint,
        ActifSousGestion = ISNULL(ET.Epargne, 0) 
    FROM CTE_Rep CR                
    JOIN Un_Rep R ON R.RepID = CR.RepID
    JOIN Mo_Human HR ON HR.HumanID = R.RepID
    JOIN Un_Rep D ON D.RepID = CR.BossID
    JOIN Mo_Human HD ON HD.HumanID = D.RepID
    LEFT JOIN dbo.fntREPR_ObtenirEpargneTotale(NULL, DATEADD(SECOND, -1, @Date)) ET ON ET.RepID = CR.RepID
    LEFT JOIN (
        SELECT
            E.RepID,
            EpargneMinAtteint = MAX(E.DateEligibilite)
        FROM tblREPR_CommissionsSuiviEligibilite E
        JOIN CTE_Rep CR ON CR.RepID = E.RepID
        WHERE E.DateEligibilite <= @Date
            AND E.EpargneMinNonAtteint = 0
            AND ISNULL((
                SELECT TOP 1
                    EpargneMinNonAtteint 
                FROM tblREPR_CommissionsSuiviEligibilite ENA
                WHERE ENA.RepID = E.RepID
                    AND ENA.DateEligibilite < E.DateEligibilite
                ORDER BY ENA.DateEligibilite DESC 
                ), 1) = 1
        GROUP BY E.RepID
        ) EA ON EA.RepID = CR.RepID
    LEFT JOIN (
        SELECT
            E.RepID,
            Date_EpargneMinNonAtteint = MAX(E.DateEligibilite)
        FROM tblREPR_CommissionsSuiviEligibilite E
        JOIN CTE_Rep CR ON CR.RepID = E.RepID
        WHERE E.DateEligibilite <= @Date
            AND E.EpargneMinNonAtteint = 1
            AND (
                SELECT TOP 1
                    EpargneMinNonAtteint 
                FROM tblREPR_CommissionsSuiviEligibilite ENA
                WHERE ENA.RepID = E.RepID
                    AND ENA.DateEligibilite < E.DateEligibilite
                ORDER BY ENA.DateEligibilite DESC 
                ) = 0
        GROUP BY E.RepID   
        ) ENA ON ENA.RepID = CR.RepID

END