/********************************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc
Nom                 :	psREPR_GenererCommissionsSuiviEligibilite
Description         :	Permet de déterminer l'éligibilité d'un représentant à la commission de suivi et d'enregistrer
                        le tout dans la table tblREPR_CommissionsSuiviEligibilite.
Valeurs de retours  :	Dataset 
Note                :	2017-05-31	Pierre-Luc Simard			Création

exec psREPR_GenererCommissionsSuiviEligibilite '2017-06-01'

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_GenererCommissionsSuiviEligibilite] (
    @dDateEligibilite DATE)
AS
BEGIN
    DECLARE 
        @mEpargne_Limite_Inf MONEY,
        @mEpargne_Limite_Sup MONEY,
        @iAnciennete_Min INT,
        @iResult INTEGER

    SET @iResult = 1

    SET @mEpargne_Limite_Inf = CONVERT(FLOAT, dbo.fnGENE_ObtenirParametre('CONV_ACTIF_SEUIL_EXCLUSION_COMM_SUIVI', @dDateEligibilite, NULL, NULL, NULL, NULL, NULL))
    SET @mEpargne_Limite_Sup = CONVERT(FLOAT, dbo.fnGENE_ObtenirParametre('CONV_ACTIF_MIN_COMM_SUIVI', @dDateEligibilite, NULL, NULL, NULL, NULL, NULL))
    SET @iAnciennete_Min = CONVERT(FLOAT, dbo.fnGENE_ObtenirParametre('CONV_NB_MOIS_COMM_SUIVI', GETDATE(), NULL, NULL, NULL, NULL, NULL))
    SET @mEpargne_Limite_Inf = CASE WHEN @mEpargne_Limite_Inf IN (-1, -2) THEN 0 ELSE @mEpargne_Limite_Inf END 
    SET @mEpargne_Limite_Sup = CASE WHEN @mEpargne_Limite_Sup IN (-1, -2) THEN 0 ELSE @mEpargne_Limite_Sup END
    SET @iAnciennete_Min = CASE WHEN @iAnciennete_Min IN (-1, -2) THEN 0 ELSE @iAnciennete_Min END

    BEGIN TRANSACTION
    
    ;WITH CTE_Rep AS (
        SELECT
            R.RepID ,
            R.BusinessStart,
            R.BusinessEnd,
            EstDirecteur = CASE WHEN D.RepID IS NOT NULL THEN 1 ELSE 0 END, 
            EstInactif = CASE WHEN R.BusinessStart IS NULL OR ISNULL(R.BusinessEnd, @dDateEligibilite) < @dDateEligibilite THEN 1 ELSE 0 END, 
            EstBloqueCommissionSuivi = R.EstBloqueCommissionSuivi,
            Epargne = ISNULL(CT.Epargne, 0),
            EpargneMinNonAtteint =  CASE 
                                        WHEN ISNULL(CT.Epargne, 0) >= @mEpargne_Limite_Sup THEN 0 
                                        WHEN ISNULL(CT.Epargne, 0) >= @mEpargne_Limite_Inf AND ISNULL(EL.EstEligible, 0) = 1 THEN 0
                                        ELSE 1
                                    END, 
            Anciennete = ISNULL(DATEDIFF(MONTH, R.BusinessStart, @dDateEligibilite), 0),
            AncienneteMinNonAtteinte = CASE WHEN DATEADD(MONTH, @iAnciennete_Min, R.BusinessStart) < @dDateEligibilite THEN 0 ELSE 1 END,
            --AncienneteMinNonAtteinte = CASE WHEN ISNULL(DATEDIFF(MONTH, R.BusinessStart, @dDateEligibilite), 0) >= @iAnciennete_Min THEN 0 ELSE 1 END,
            EstEligiblePrecedement = EL.EstEligible,
            EstDirecteurPrecedement = EL.EstDirecteur,
            EstInactifPrecedement = EL.EstInactif,
            EstBloquePrecedement = EL.EstBloque,
            EpargneMinNonAtteintPrecedement = EL.EpargneMinNonAtteint,
            AncienneteMinNonAtteintePrecedement = EL.AncienneteMinNonAtteinte
        FROM Un_Rep R
        LEFT JOIN (-- Solde de l'épargne 
            SELECT 
                S.RepID,
                Epargne = SUM(CT.Cotisation)
            FROM Un_Convention C
            JOIN Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            JOIN Un_Unit U ON U.ConventionID = C.ConventionID
            JOIN fntCONV_ObtenirStatutUnitEnDate_PourTous(@dDateEligibilite, NULL) US ON US.UnitID = U.UnitID
            JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID 
            JOIN Un_Oper O ON O.OperID = CT.OperID
            WHERE CHARINDEX(US.UnitStateID, 'REE,TRA,BRS,CPT,EPG,PAE,RCS,RIN', 1) <> 0
                AND O.OperDate < @dDateEligibilite
            GROUP BY S.RepID
            ) CT ON CT.RepID = R.RepID
        LEFT JOIN dbo.fntREPR_ObtenirEligibiliteCommissionsSuivi (DEFAULT, @dDateEligibilite) EL ON EL.RepID = R.RepID -- Dernière éligibilité
        LEFT JOIN ( -- Liste des directeurs
            SELECT DISTINCT 
                RLH.RepID
            FROM Un_RepLevelHist RLH 
            JOIN Un_RepLevel RL ON RL.RepLevelID = RLH.RepLevelID
            WHERE RL.RepRoleID = 'DIR'
                AND RLH.StartDate < @dDateEligibilite 
                AND ISNULL(RLH.EndDate, DATEADD(DAY, 1, @dDateEligibilite)) > @dDateEligibilite
            ) D ON D.RepID = R.RepID
        ),
    CTE_RepEligibilite AS (
        SELECT 
            R.RepID,
            R.BusinessStart,
            R.BusinessEnd,
            R.EstDirecteur,
            R.EstInactif,
            R.EstBloqueCommissionSuivi,
            R.Epargne,
            R.EpargneMinNonAtteint,
            R.Anciennete,
            R.AncienneteMinNonAtteinte,
            R.EstEligiblePrecedement,
            R.EstDirecteurPrecedement,
            R.EstInactifPrecedement,
            R.EstBloquePrecedement,
            R.EpargneMinNonAtteintPrecedement,
            R.AncienneteMinNonAtteintePrecedement, 
            EstEligible = CASE WHEN R.EstDirecteur = 0 AND R.EstInactif = 0 AND R.EpargneMinNonAtteint = 0 AND R.AncienneteMinNonAtteinte = 0 THEN 1 ELSE 0 END
        FROM CTE_Rep R
        )
        INSERT INTO tblREPR_CommissionsSuiviEligibilite(
            DateEligibilite ,
            RepID ,
            EstEligible ,
            EstDirecteur ,
            EstInactif ,
            EstBloque ,
            EpargneMinNonAtteint ,
            AncienneteMinNonAtteinte)
        SELECT 
            @dDateEligibilite,
            R.RepID,
            R.EstEligible, 
            R.EstDirecteur,
            R.EstInactif,
            R.EstBloqueCommissionSuivi,
            R.EpargneMinNonAtteint,
            R.AncienneteMinNonAtteinte
        FROM CTE_RepEligibilite R
        WHERE R.EstEligible <> ISNULL(R.EstEligiblePrecedement, 0)
            OR R.EstDirecteur <> ISNULL(R.EstDirecteurPrecedement, 0)
            OR R.EstInactif <> ISNULL(R.EstInactifPrecedement, 0)
            OR R.EstBloqueCommissionSuivi <> ISNULL(R.EstBloquePrecedement, 0)
            OR R.EpargneMinNonAtteint <> ISNULL(R.EpargneMinNonAtteintPrecedement, 0)
            OR R.AncienneteMinNonAtteinte <> ISNULL(R.AncienneteMinNonAtteintePrecedement, 0)

    IF @@ERROR <> 0
		SET @iResult = -1
    
    IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @iResult
END