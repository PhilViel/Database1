/************************************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc
Code du service:	psREPR_GenererCommissionsSuivi
Nom du service:		Générer les commissions de suivi
But:						Calculer les commissions de suivi au représentant éligible à une date donnée.
Facette:					REPR

Paramètres d’entrée	:	Paramètre						Description
									--------------------------	-----------------------------------------------------------------
		  							dDateCalcul					Date du calcul (Normalement le premier du mois)
									
Exemple d’appel:	EXEC psREPR_GenererCommissionsSuivi '2016-11-01'
			
Paramètres de sortie:		Table						Champ							Description
		  							-------------------------	--------------------------- 	---------------------------------
									S/O							iCode_Retour					Code de retour standard

Historique des modifications:
						2017-05-30	Maxime Martel		Création du service

************************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_GenererCommissionsSuivi] (
    @dDateCalcul DATE)
AS
BEGIN
    

    DECLARE
        @iResult INTEGER,
        @Taux_Avant_Echeance FLOAT,
        @Taux_Apres_Echeance FLOAT,
        @dtEpargne_Debut DATE,
        @dtEpargne_Fin DATE

    SET @iResult = 1
    
    SET @dtEpargne_Debut = CAST(CAST(DATEPART(MONTH,DATEADD(MONTH, -1, @dDateCalcul)) AS VARCHAR)+'-01-'+CAST(DATEPART(YEAR,DATEADD(MONTH, -1, @dDateCalcul)) AS VARCHAR) AS DATE)
    SET @dtEpargne_Fin = CAST(CAST(DATEPART(MONTH, @dDateCalcul) AS VARCHAR)+'-01-'+CAST(DATEPART(YEAR, @dDateCalcul) AS VARCHAR) AS DATE)

    -----------------------------------------------------------------------------
    -- Obtenir les taux avant et après échéance pour la commission de suivi
    -----------------------------------------------------------------------------

    SET @Taux_Avant_Echeance = CONVERT(FLOAT, dbo.fnGENE_ObtenirParametre('CONV_TAUX_AVANT_ECHEANCE_COMM_SUIVI', @dDateCalcul, NULL, NULL, NULL, NULL, NULL))
    SET @Taux_Apres_Echeance = CONVERT(FLOAT, dbo.fnGENE_ObtenirParametre('CONV_TAUX_APRES_ECHEANCE_COMM_SUIVI', @dDateCalcul, NULL, NULL, NULL, NULL, NULL))
    SET @Taux_Avant_Echeance = CASE WHEN @Taux_Avant_Echeance IN (-1, -2) THEN 0 ELSE @Taux_Avant_Echeance END 
    SET @Taux_Apres_Echeance = CASE WHEN @Taux_Apres_Echeance IN (-1, -2) THEN 0 ELSE @Taux_Apres_Echeance END 
    
  
    -----------------------------------------------------------------------------
    -- Obtenir les unités admissible à la rémunération sur l'actif
    -----------------------------------------------------------------------------

    CREATE TABLE #uniteRemunActif(unitId int not null)

    IF dbo.fnGENE_ObtenirParametre('CONV_AGE_MIN_BENEF_COMM_ACTIF', @dDateCalcul, NULL, NULL, NULL, NULL, NULL) NOT IN ('-1', '-2') 
			AND dbo.fnGENE_ObtenirParametre('CONV_DATE_SIGNATURE_MIN_COMM_ACTIF', @dDateCalcul, NULL, NULL, NULL, NULL, NULL) NOT IN ('-1', '-2')
		BEGIN 
			DECLARE
				@iAgeBenef INT = dbo.fnGENE_ObtenirParametre('CONV_AGE_MIN_BENEF_COMM_ACTIF', @dDateCalcul, NULL, NULL, NULL, NULL, NULL),
				@dtSignature DATETIME = dbo.fnGENE_ObtenirParametre('CONV_DATE_SIGNATURE_MIN_COMM_ACTIF', @dDateCalcul, NULL, NULL, NULL, NULL, NULL)
            
            INSERT INTO #uniteRemunActif
            SELECT unite.UnitID
			FROM dbo.fntCONV_ObtenirGroupeUniteAdmissibleCommissionActif(@dDateCalcul, null, @iAgeBenef, @dtSignature) unite
        END


    -----------------------------------------------------------------------------
    -- Obtenir les représentants eligible à la rémunération de suivi
    -----------------------------------------------------------------------------
      SELECT * 
      INTO #representantEligibleCommissionSuivi
      FROM dbo.fntREPR_ObtenirEligibiliteCommissionsSuivi (NULL, @dDateCalcul) RepEligible
      WHERE RepEligible.EstELigible = 1 AND RepEligible.EstBloque = 0

    -----------------------------------------------------------------------------
    -- Obtenir l'épargne en début et fin de période excluant les groupe d'unité
    -- de la rémunération sur l'actif
    -----------------------------------------------------------------------------
      SELECT
            unite.UnitID,
            rep.RepID,
            Epargne_Debut = ISNULL(ED.Epargne_Debut, 0), 
            Epargne_Periode = ISNULL(EP.Epargne_Periode, 0),
            Epargne_Fin = ISNULL(EF.Epargne_Fin, 0),
            Epargne_Calcul = (ISNULL(ED.Epargne_Debut, 0) + ISNULL(EF.Epargne_Fin, 0)) / 2, -- Moyenne du solde au début et à la fin de la période
            bTaux_ApresEchenance =
               CASE WHEN @dDateCalcul > dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, unite.InForceDate, P.IntReimbAge, unite.IntReimbDateAdjust) 
		       THEN 1
		       ELSE 0
		       END 
      INTO #tUnit
      FROM #representantEligibleCommissionSuivi rep
      JOIN un_subscriber s on s.RepID = rep.RepID
      JOIN dbo.Un_Convention C ON C.SubscriberID = s.SubscriberID
      JOIN
      (
         SELECT * FROM un_unit u 
         WHERE u.UnitID NOT IN (
            SELECT * 
            FROM #uniteRemunActif
         )
      ) unite ON unite.ConventionID = C.ConventionID
      JOIN fntCONV_ObtenirStatutUnitEnDate_PourTous(@dDateCalcul, NULL) US ON US.UnitID = unite.UnitID
      JOIN Un_Plan P ON P.PlanID = C.PlanID
      JOIN Un_Modal M ON M.ModalID = unite.ModalID
      LEFT JOIN (-- Solde de l'épargne au début
         SELECT 
            CT.UnitID,
            Epargne_Debut = SUM(CT.Cotisation)
         FROM Un_Cotisation CT 
         JOIN Un_Oper O ON O.OperID = CT.OperID
         WHERE O.OperDate < @dtEpargne_Debut
         GROUP BY CT.UnitID 
      ) ED ON ED.UnitID = unite.UnitID
      LEFT JOIN (-- Épargne entrée ou sortie pendant la période
         SELECT 
            CT.UnitID,
            Epargne_Periode = SUM(CT.Cotisation)
         FROM Un_Cotisation CT 
         JOIN Un_Oper O ON O.OperID = CT.OperID
         WHERE O.OperDate >= @dtEpargne_Debut 
            AND O.OperDate < @dtEpargne_Fin
         GROUP BY CT.UnitID 
      ) EP ON EP.UnitID = unite.UnitID
      LEFT JOIN (-- Solde de l'épargne à la fin 
         SELECT 
            CT.UnitID,
            Epargne_Fin = SUM(CT.Cotisation)
         FROM Un_Cotisation CT 
         JOIN Un_Oper O ON O.OperID = CT.OperID
         WHERE O.OperDate < @dtEpargne_Fin
         GROUP BY CT.UnitID 
      ) EF ON EF.UnitID = unite.UnitID
      WHERE (ISNULL(ED.Epargne_Debut, 0) + ISNULL(EF.Epargne_Fin, 0)) / 2 > 0
        AND CHARINDEX(US.UnitStateID, 'REE,TRA,BRS,CPT,EPG,PAE,RCS,RIN', 1) <> 0


    -----------------------------------------------------------------------------
    -- Calcul du montant de la commission de suivi et insertion dans la table
    -----------------------------------------------------------------------------

      ------------------------
      BEGIN TRANSACTION
      ------------------------

      INSERT INTO tblREPR_CommissionsSuivi(
         dDate_Calcul,
         RepID,
         UnitID,
         mEpargne_SoldeDebut,
         mEpargne_Periode,
         mEpargne_SoldeFin,
         mEpargne_Calcul,
         dTaux_Calcul,
         bTaux_ApresEcheance,
         mMontant_ComSuivi)
      SELECT  
         @dDateCalcul,
         U.repid,
         U.UnitID,
         U.Epargne_Debut, 
         U.Epargne_Periode,
         U.Epargne_Fin,
         U.Epargne_Calcul,
         U.Taux,
         U.bTaux_ApresEchenance,
         mMontant_ComSuivi = CASE WHEN U.mMontant_ComSuivi < 0 THEN 0 ELSE mMontant_ComSuivi END 
      FROM (
         SELECT 
               U.UnitID,
               U.repid, 
               U.Epargne_Debut, 
               U.Epargne_Periode,
               U.Epargne_Fin,
               U.Epargne_Calcul,
               Taux = CASE WHEN U.bTaux_ApresEchenance = 1 THEN @Taux_Apres_Echeance ELSE @Taux_Avant_Echeance END, 
               bTaux_ApresEchenance,
               mMontant_ComSuivi = U.Epargne_Calcul / 12 * CASE WHEN U.bTaux_ApresEchenance = 1 THEN @Taux_Apres_Echeance ELSE @Taux_Avant_Echeance END
         FROM #tUnit U
         ) U 
  
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