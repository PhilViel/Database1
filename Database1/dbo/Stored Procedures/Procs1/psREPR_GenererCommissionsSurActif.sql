/************************************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc
Code du service:	psREPR_GenererCommissionsSurActif
Nom du service:		Générer les commissions sur l'actif
But:						Calculer les commissions sur l'actif, pour les groupes d'unités admissibles, à une date donnée.
Facette:					REPR

Paramètres d’entrée	:	Paramètre						Description
									--------------------------	-----------------------------------------------------------------
		  							dDateCalcul					Date du calcul (Normalement le premier du mois)
									
Exemple d’appel:	EXEC psREPR_GenererCommissionsSurActif '2016-04-01'
			
Paramètres de sortie:		Table						Champ							Description
		  							-------------------------	--------------------------- 	---------------------------------
									S/O							iCode_Retour					Code de retour standard

Historique des modifications:
						2016-05-24	Pierre-Luc Simard		Création du service
                        2016-06-10  Pierre-Luc Simard       Retrait des validations sur les montants > 0
                                                            Mettre le champ mMontant_ComActif à 0$ si négatif
                        2016-06-15  Pierre-Luc Simard       L'arrondi a été retiré pour se faire par convention, via une vue
                        2016-06-21  Pierre-Luc Simard       Ajout de paramètre lors de l'appel de la fonction fntCONV_ObtenirGroupeUniteAdmissibleCommissionActif
                        2017-06-14  Pierre-Luc Simard       Exclure les représentants inactifs du calcul
************************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_GenererCommissionsSurActif] (
    @dDateCalcul DATE)
AS
BEGIN

    DECLARE
        @iResult INTEGER,
        @dtEpargne_Debut DATE,
        @dtEpargne_Fin DATE,
        @Taux_Avant_Echeance FLOAT,
        @Taux_Apres_Echeance FLOAT,
        @iAgeBenef INT,
        @dtSignature DATETIME

    SET @iResult = 1
    SET @dtEpargne_Debut = CAST(CAST(DATEPART(MONTH,DATEADD(MONTH, -1, @dDateCalcul)) AS VARCHAR)+'-01-'+CAST(DATEPART(YEAR,DATEADD(MONTH, -1, @dDateCalcul)) AS VARCHAR) AS DATE)
    SET @dtEpargne_Fin = CAST(CAST(DATEPART(MONTH, @dDateCalcul) AS VARCHAR)+'-01-'+CAST(DATEPART(YEAR, @dDateCalcul) AS VARCHAR) AS DATE)
    --SET @dtEpargne_Debut = CAST(CAST(DATEPART(MONTH,DATEADD(MONTH, -2, @dDateCalcul)) AS VARCHAR)+'-01-'+CAST(DATEPART(YEAR,DATEADD(MONTH, -2, @dDateCalcul)) AS VARCHAR) AS DATE)
    --SET @dtEpargne_Fin = CAST(CAST(DATEPART(MONTH,DATEADD(MONTH, -1, @dDateCalcul)) AS VARCHAR)+'-01-'+CAST(DATEPART(YEAR,DATEADD(MONTH, -1, @dDateCalcul)) AS VARCHAR) AS DATE)
    SET @Taux_Avant_Echeance = CONVERT(FLOAT, dbo.fnGENE_ObtenirParametre('CONV_TAUX_COMM_ACTIF_AVANT_ECHEANCE', @dDateCalcul, NULL, NULL, NULL, NULL, NULL))
    SET @Taux_Apres_Echeance = CONVERT(FLOAT, dbo.fnGENE_ObtenirParametre('CONV_TAUX_COMM_ACTIF_APRES_ECHEANCE', @dDateCalcul, NULL, NULL, NULL, NULL, NULL))
    SET @Taux_Avant_Echeance = CASE WHEN @Taux_Avant_Echeance IN (-1, -2) THEN 0 ELSE @Taux_Avant_Echeance END 
    SET @Taux_Apres_Echeance = CASE WHEN @Taux_Apres_Echeance IN (-1, -2) THEN 0 ELSE @Taux_Apres_Echeance END 
    SET @iAgeBenef = dbo.fnGENE_ObtenirParametre('CONV_AGE_MIN_BENEF_COMM_ACTIF', GETDATE(), NULL, NULL, NULL, NULL, NULL)
    SET @dtSignature = dbo.fnGENE_ObtenirParametre('CONV_DATE_SIGNATURE_MIN_COMM_ACTIF', GETDATE(), NULL, NULL, NULL, NULL, NULL)

    SELECT
        U.UnitID,
        U.iID_RepComActif,
        Epargne_Debut = ISNULL(ED.Epargne_Debut, 0), 
        Epargne_Periode = ISNULL(EP.Epargne_Periode, 0),
        Epargne_Fin = ISNULL(EF.Epargne_Fin, 0),
        Epargne_Calcul = (ISNULL(ED.Epargne_Debut, 0) + ISNULL(EF.Epargne_Fin, 0)) / 2, -- Moyenne du solde au début et à la fin de la période
        bTaux_ApresEchenance =
            CASE WHEN @dDateCalcul > dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust) 
		    THEN 1
		    ELSE 0
		    END 
    INTO #tUnit
    FROM dbo.fntCONV_ObtenirGroupeUniteAdmissibleCommissionActif(DATEADD(DAY, -1, @dDateCalcul), NULL, @iAgeBenef, @dtSignature) UA 
    JOIN dbo.Un_Unit U ON U.UnitID = UA.UnitID
    JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
    JOIN Un_Plan P ON P.PlanID = C.PlanID
    JOIN Un_Modal M ON M.ModalID = U.ModalID
    JOIN Un_Rep R ON R.RepID = U.iID_RepComActif 
    LEFT JOIN (-- Solde de l'épargne au début
        SELECT 
            CT.UnitID,
            Epargne_Debut = SUM(CT.Cotisation)
        FROM Un_Cotisation CT 
        JOIN Un_Oper O ON O.OperID = CT.OperID
        WHERE O.OperDate < @dtEpargne_Debut
        GROUP BY CT.UnitID 
        --HAVING SUM(CT.Cotisation) > 0 -- Le solde au début doit être supérieur à 0$
    ) ED ON ED.UnitID = U.UnitID
    LEFT JOIN (-- Épargne entrée ou sortie pendant la période
        SELECT 
            CT.UnitID,
            Epargne_Periode = SUM(CT.Cotisation)
        FROM Un_Cotisation CT 
        JOIN Un_Oper O ON O.OperID = CT.OperID
        WHERE O.OperDate >= @dtEpargne_Debut 
            AND O.OperDate < @dtEpargne_Fin
        GROUP BY CT.UnitID 
    ) EP ON EP.UnitID = U.UnitID
    LEFT JOIN (-- Solde de l'épargne à la fin 
        SELECT 
            CT.UnitID,
            Epargne_Fin = SUM(CT.Cotisation)
        FROM Un_Cotisation CT 
        JOIN Un_Oper O ON O.OperID = CT.OperID
        WHERE O.OperDate < @dtEpargne_Fin
        GROUP BY CT.UnitID 
    ) EF ON EF.UnitID = U.UnitID
    WHERE (ISNULL(ED.Epargne_Debut, 0) + ISNULL(EF.Epargne_Fin, 0)) / 2 > 0
        AND (R.BusinessStart IS NOT NULL AND ISNULL(R.BusinessEnd, DATEADD(DAY, 1, @dDateCalcul)) > @dDateCalcul) -- Exclure les représentants inactifs
    ------------------------
    BEGIN TRANSACTION
    ------------------------

        INSERT INTO tblREPR_CommissionsSurActif(
            UnitID,
            RepID,
            dDate_Calcul,
            mEpargne_SoldeDebut,
            mEpargne_Periode,
            mEpargne_SoldeFin,
            mEpargne_Calcul,
            dTaux_Calcul,
            bTaux_ApresEcheance,
            mMontant_ComActif)
        SELECT 
            U.UnitID,
            U.iID_RepComActif,
            @dDateCalcul,
            U.Epargne_Debut, 
            U.Epargne_Periode,
            U.Epargne_Fin,
            U.Epargne_Calcul,
            U.Taux,
            U.bTaux_ApresEchenance,
            mMontant_ComActif = CASE WHEN U.mMontant_ComActif < 0 THEN 0 ELSE mMontant_ComActif END 
        FROM (
            SELECT 
                U.UnitID,
                U.iID_RepComActif, 
                U.Epargne_Debut, 
                U.Epargne_Periode,
                U.Epargne_Fin,
                U.Epargne_Calcul,
                Taux = CASE WHEN U.bTaux_ApresEchenance = 1 THEN @Taux_Apres_Echeance ELSE @Taux_Avant_Echeance END, 
                bTaux_ApresEchenance,
                mMontant_ComActif = U.Epargne_Calcul / 12 * CASE WHEN U.bTaux_ApresEchenance = 1 THEN @Taux_Apres_Echeance ELSE @Taux_Avant_Echeance END
                --mMontant_ComActif = CAST(U.Epargne_Calcul / 12 * CASE WHEN U.bTaux_ApresEchenance = 1 THEN @Taux_Apres_Echeance ELSE @Taux_Avant_Echeance END AS DECIMAL(7,2))
            FROM #tUnit U
            ) U 
        --WHERE U.mMontant_ComActif > 0
  
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