/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc

Code du service : SL_UN_DefaultCotisationForOper
Nom du service  : Procédure retournant le montant en frais, épargnes, assurances souscripteur, assurance
                  bénéficiaire et taxes pour une liste de groupes d'unités

Paramètres d’entrée : Paramètre         Description
                      ----------------  -----------------------------------
                      @IDsType          Donne le type de ID (SUB = SubscriberID, GUN = UnitID, CON = ConventionID)
                      @iBlobID          Liste de IDs séparé par des virgules (CRI_Blob)
                      @OperTypeID       Type d'opération
                      @OperDate         Date de l'opération

Paramètres de sortie: Paramètre   Champ(s)        Description
                      ----------- --------------- ---------------------------
                      UnitID                      ID unique du groupe d'unités
                      ConventionID                ID unique de la convention
                      ConventionNo                Numéro de convention
                      SubscriberName              Nom, Prénom du souscripteur
                      BeneficiaryName             Nom, Prénom du bénéficiaire
                      InForceDate                 Date de vigueur
                      UnitQty                     Nombre d'unité du groupe d'unités
                      EffectDate                  Date effective
                      Cotisation                  Montant de cotisation
                      Fee                         Montant de frais
                      SubscInsur                  Montant d'assurance souscripteur
                      BenefInsur                  Montant d'assurance bénéficiaire
                      TaxOnInsur                  Montant de taxes sur l'assurance
                      mMontantAjout               Montant maximum disponible RDI
                      iID_RDI_Paiement            Identifiant unique du paiement

Historique des modifications:
               Date            Programmeur         Description
               ------------    ------------------- ---------------------------
               2004-07-13      Bruno Lapointe      Création
ADX0000705 BR  2004-07-23      Bruno Lapointe      Bug report
ADX0000558 IA  2004-11-19      Bruno Lapointe      Ajout des valeurs de retours SubscriberName et 
                                                   BeneficiaryName
ADX0001336 BR  2005-03-15      Bruno Lapointe      Par défaut il y est une cotisation pour les RET 
                                                   même si le montant souscrit du groupe d'unités est
                                                   atteint ou que le groupe d'unités est résilié.
ADX0001391 BR  2005-04-12      Bruno Lapointe      Pas de frais négatif
ADX0002066 BR  2006-08-24      Mireya Gonthier     Gestion pour les opérations AJU
ADX0001183 IA  2006-10-12      Bruno Lapointe      Ajout du SubscriberID
ADX0001357 IA  2007-06-04      Alain Quirion       Ajout du champ bIsContestWinner
               2010-03-03      Danielle Côté       Ajout du type d'opération RDI
               2010-12-06      Danielle Côté       Modifier la structure pour que si la requête principale ne 
                                                   retourne rien, un enregistrement "bidon" s'affiche pour les RDI
               2013-12-10      Donald Huppé        GLPI 10658 :
													exlure les conventions IND 
													exlure les convention transférées RIO
													exclure les CPT (capital atteint)
               2018-03-19      Pierre-Luc Simard   Exclure les unités ayant un RIN partiel ou complet
			   2018-09-07	   Maxime Martel	   JIRA MP-699 Ajout de OpertypeID COU
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_DefaultCotisationForOper] 
(
   @IDsType    VARCHAR(3)
  ,@iBlobID  INTEGER
  ,@OperTypeID VARCHAR(3)
  ,@OperDate   DATETIME
)
AS
BEGIN

   -- Bâtis une table des groupes d'unités avec la liste de IDs passer en paramètre  
   CREATE TABLE #Unit 
         (UnitID INTEGER PRIMARY KEY)

   -------------------------------------------------------------------------------------
   -- Pour le type d'opération RDI : le blob n'est pas utilisé
   -- Le paramètre @iBlobID contient le ID de l'utilisateur à l'entrée
   -- Exemple d’appel pour RDI : (prérequis données présentes dans la table tblTEMP_RDI_Paiements)
   -- EXEC [dbo].[SL_UN_DefaultCotisationForOper] NULL,575752,'RDI','2010-03-03'
   -------------------------------------------------------------------------------------
   DECLARE 
      @mMontantAjout MONEY
     ,@iID_RDI_Paiement INT
     ,@iID_Utilisateur INT
   SET @mMontantAjout    = 0
   SET @iID_RDI_Paiement = 0
   SET @iID_Utilisateur  = 0
   
   IF @IDsType = 'SUB'
   BEGIN
      INSERT INTO #Unit
      SELECT DISTINCT U.UnitID
        FROM dbo.Un_Unit U
        JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
        join Un_Plan p ON C.PlanID = p.PlanID
        JOIN dbo.FN_CRI_BlobToIntegerTable(@iBlobID) T ON T.iVal = C.SubscriberID
        left join tblOPER_OperationsRIO r ON C.ConventionID = r.iID_Convention_Source and r.bRIO_Annulee = 0 and r.bRIO_QuiAnnule = 0
        left join (
			select 
				us.unitid,
				uus.startdate,
				us.UnitStateID
			from 
				Un_UnitunitState us
				join (
					select 
					unitid,
					startdate = max(startDate)
					from un_unitunitstate
					--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= '2010-06-01'
					group by unitid
					) uus on uus.unitid = us.unitid 
						and uus.startdate = us.startdate 
						and us.UnitStateID in ('CPT')
			)uss on U.UnitID = uss.UnitID
		------------GLPI 10658 --------------
       where 
		p.PlanTypeID <> 'IND' -- exlure les conventions IND 
		and r.iID_Convention_Source is null -- exlure les conventions transférées RIO
		and uss.UnitID is null -- exclure les CPT (capital atteint)
		--------------------------------------
   END
   ELSE IF @IDsType = 'CON'
   BEGIN
      INSERT INTO #Unit
      SELECT DISTINCT U.UnitID
        FROM dbo.Un_Unit U
        JOIN dbo.FN_CRI_BlobToIntegerTable(@iBlobID) T ON T.iVal = U.ConventionID
   END
   ELSE IF @IDsType = 'GUN'
   BEGIN
      INSERT INTO #Unit
      SELECT DISTINCT iVal
        FROM dbo.FN_CRI_BlobToIntegerTable(@iBlobID)
   END
   ELSE IF @IDsType IS NULL AND @OperTypeID = 'RDI'
   BEGIN   
      -- La valeut du ID utilisateur est passé dans le paramètre qui contient le BLOB normalement
      SET @iID_Utilisateur = @iBlobID
      
      -- Insertion des unités
      INSERT INTO #Unit
      SELECT DISTINCT U.UnitID
        FROM dbo.Un_Unit U
        JOIN dbo.fntTEMP_RDI_ObtenirDonneePaiement(@iID_Utilisateur) T ON T.iConventionID = U.ConventionID
        
      -- Récupération du montant disponible
      SELECT @mMontantAjout    = T.mMontantAjout
            ,@iID_RDI_Paiement = T.iID_RDI_Paiement
        FROM dbo.fntTEMP_RDI_ObtenirDonneePaiement(@iID_Utilisateur) T
   END
 
   -------------------------------------------------------------------------------------
   -- Un SELECT COUNT(*) est fait sur la requête d'affichage.
   -- Si ne retourne rien pour entres autres une des causes suivantes :   
   -- 1.Pas les groupes d'unité dont le montant est souscrit
   -- 2.Pas de groupe d'unités totalement résilié
   -- 3.Pas de fin de paiement forcée
   -- 4.Groupe d'unités doit être activé
   -- prévoir un affichage bidon pour RDI
   -- Dans un contexte d'optimisation, il faudrait refaire cette requête !
   -------------------------------------------------------------------------------------   
   IF (SELECT COUNT(*)
        FROM dbo.Un_Unit U
        JOIN #Unit T ON T.UnitID = U.UnitID
        JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
        JOIN Un_Modal M ON M.ModalID = U.ModalID
        JOIN Un_Plan P ON P.PlanID = M.PlanID
        JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
        JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
        JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
        LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
        LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
        LEFT JOIN Mo_State St ON St.StateID = S.StateID
             -- Retourne le total des cotisations et de frais par unité
        LEFT JOIN (SELECT Ct.UnitID
                         ,Cotisation = SUM(Ct.Cotisation)
                         ,Fee = SUM(Ct.Fee)
                     FROM Un_Cotisation Ct
                     JOIN Un_Oper O ON O.OperID = Ct.OperID
                     LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
                    WHERE ((O.OperTypeID = 'CPA' AND ISNULL(OBF.OperID, 0) > 0) OR O.OperDate < = GETDATE())
                    GROUP BY CT.UnitID
                  ) Ct ON Ct.UnitID = U.UnitID
        LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, GETDATE()) RIN ON RIN.UnitID = U.UnitID
       WHERE (@OperTypeID NOT IN ('CPA','PRD','CHQ','AJU','RDI','COU')
            OR (ISNULL(Ct.Cotisation + Ct.Fee,0) < ROUND(M.PmtRate * U.UnitQty,2) * M.PmtQty
                AND U.TerminatedDate IS NULL
                AND ((ISNULL(U.PmtEndConnectID,0) = 0
                AND U.ActivationConnectID IS NOT NULL)
                OR @IDsType = 'GUN')))
            AND (C.PlanID = 4 OR ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3)) -- Exclure les groupes d'unités avec un RIN partiel ou complet
          ) > 0
   BEGIN
      SELECT U.UnitID
            ,C.ConventionID
            ,C.ConventionNo
            ,C.SubscriberID
            ,SubscriberName  = HS.LastName +', '+HS.FirstName
            ,BeneficiaryName = HB.LastName +', '+HB.FirstName
            ,U.InForceDate
            ,U.UnitQty
            ,EffectDate = @OperDate
            ,Cotisation = 
             CASE
               WHEN @OperTypeID IN ('CPA','PRD','CHQ','RDI','COU') THEN
                  CASE 
                     WHEN (dbo.FN_UN_EstimatedFee( -- Montant de frais total
                           ISNULL(Ct.Cotisation+Ct.Fee,0) + ROUND(M.PmtRate * U.UnitQty,2),
                           U.UnitQty, M.FeeSplitByUnit, M.FeeByUnit) - ISNULL(Ct.Fee,0)) >= 0 THEN 
                           ROUND(M.PmtRate * U.UnitQty,2) - -- Montant d'un dépôt en cotisations et frais combinés
                           (dbo.FN_UN_EstimatedFee(
                           ISNULL(Ct.Cotisation+Ct.Fee,0) + ROUND(M.PmtRate * U.UnitQty,2),
                           U.UnitQty, M.FeeSplitByUnit, M.FeeByUnit) -  ISNULL(Ct.Fee,0)) -- Déduit les frais déjà déposé
                     ELSE ROUND(M.PmtRate * U.UnitQty,2)
                  END
               ELSE 0
            END
           ,Fee = 
            CASE
               WHEN @OperTypeID IN ('CPA','PRD','CHQ','RDI','COU') THEN
                  CASE 
                     WHEN (dbo.FN_UN_EstimatedFee( -- Calcul le montant de frais total
                           ISNULL(Ct.Cotisation+Ct.Fee,0) + ROUND(M.PmtRate * U.UnitQty,2),
                           U.UnitQty, M.FeeSplitByUnit, M.FeeByUnit) - ISNULL(Ct.Fee,0)) >= 0 THEN 
                           dbo.FN_UN_EstimatedFee(
                           ISNULL(Ct.Cotisation+Ct.Fee,0) + ROUND(M.PmtRate * U.UnitQty,2),
                           U.UnitQty, M.FeeSplitByUnit, M.FeeByUnit) - ISNULL(Ct.Fee,0) -- Déduit les frais déjà déposé
                     ELSE 0
                  END
               ELSE 0
            END
           ,SubscInsur = 
            CASE
               WHEN @OperTypeID IN ('CPA','PRD','CHQ','RDI','COU') THEN
                  CASE U.WantSubscriberInsurance
                     WHEN 0 THEN 0
                     ELSE ROUND(M.SubscriberInsuranceRate * U.UnitQty,2)
                  END
               ELSE 0
            END
           ,BenefInsur = 
            CASE
               WHEN @OperTypeID IN ('CPA','PRD','CHQ','RDI','COU') THEN
                    ISNULL(BI.BenefInsurRate,0)
               ELSE 0
            END
           ,TaxOnInsur = 
            CASE
 WHEN @OperTypeID IN ('CPA','PRD','CHQ','RDI','COU') THEN
                  CASE U.WantSubscriberInsurance
                     WHEN 0 THEN dbo.FN_CRQ_TaxRounding(ISNULL(BI.BenefInsurRate,0) * ISNULL(St.StateTaxPct,0))
                     ELSE dbo.FN_CRQ_TaxRounding((ROUND(M.SubscriberInsuranceRate * U.UnitQty,2) + ISNULL(BI.BenefInsurRate,0)) * ISNULL(St.StateTaxPct,0))
                  END
               ELSE 0
            END
           ,bIsContestWinner = ISNULL(SS.bIsContestWinner,0)
           ,mMontantAjout = @mMontantAjout
           ,iID_RDI_Paiement = @iID_RDI_Paiement
       FROM dbo.Un_Unit U
       JOIN #Unit T ON T.UnitID = U.UnitID
       JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
       JOIN Un_Modal M ON M.ModalID = U.ModalID
       JOIN Un_Plan P ON P.PlanID = M.PlanID
       JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
       JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
       JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
       LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
       LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID
       LEFT JOIN Mo_State St ON St.StateID = S.StateID
            -- Retourne le total des cotisations et de frais par unité
       LEFT JOIN (SELECT Ct.UnitID
                        ,Cotisation = SUM(Ct.Cotisation)
                        ,Fee = SUM(Ct.Fee)
                    FROM Un_Cotisation Ct
                    JOIN Un_Oper O ON O.OperID = Ct.OperID
                    LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
                   WHERE ((O.OperTypeID = 'CPA' AND ISNULL(OBF.OperID, 0) > 0) OR O.OperDate < = GETDATE())
                   GROUP BY CT.UnitID
                 ) Ct ON Ct.UnitID = U.UnitID
        LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, GETDATE()) RIN ON RIN.UnitID = U.UnitID
      WHERE (@OperTypeID NOT IN ('CPA','PRD','CHQ','AJU','RDI','COU')
            OR (ISNULL(Ct.Cotisation + Ct.Fee,0) < ROUND(M.PmtRate * U.UnitQty,2) * M.PmtQty -- Pas les groupes d'unité dont le montant est souscrit
                AND U.TerminatedDate IS NULL          -- Pas de groupe d'unités totalement résilié
                AND ((ISNULL(U.PmtEndConnectID,0) = 0 -- Pas de fin de paiement forcée
                AND U.ActivationConnectID IS NOT NULL)-- Groupe d'unités doit être activé
                OR @IDsType = 'GUN')))
        AND (C.PlanID = 4 OR ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3)) -- Exclure les groupes d'unités avec un RIN partiel ou complet
   END
   ELSE
   BEGIN   
      -- Si le numéro de convention entré par le déposant est incorrect, 
      -- OU si la requête principale ne retourne rien, simuler en enregistrement pour RDI
      IF @OperTypeID = 'RDI'
      BEGIN
         CREATE TABLE #Un_Unit
               (UnitID INT PRIMARY KEY
               ,InForceDate DATETIME
               ,UnitQty INT)

         CREATE TABLE #Un_Convention 
               (ID INT PRIMARY KEY
               ,conventionID INT
               ,conventionNo VARCHAR(25)
               ,subscriberid INT)

         INSERT INTO #Un_Unit VALUES (0,GETDATE(),0)
 
         IF NOT EXISTS (SELECT 1 FROM #Unit)
         BEGIN
            -- Si le numéro de convention fourni par le déposant est invalide 
            INSERT INTO #Un_Convention VALUES (0,0,'Non trouvé',0)
         END
         ELSE
         BEGIN
            -- Si le numéro de convention fourni par le déposant est valide mais ne permet pas d'ajout
            INSERT INTO #Un_Convention VALUES (0,0,'Non autorisé',0)
         END
         
         SELECT U.UnitID
               ,C.ConventionID
               ,C.ConventionNo
               ,C.SubscriberID
               ,SubscriberName  = ''
               ,BeneficiaryName = ''
               ,U.InForceDate
               ,U.UnitQty
               ,EffectDate = @OperDate
               ,Cotisation = 0
               ,Fee = 0
               ,SubscInsur = 0
               ,BenefInsur = 0
               ,TaxOnInsur = 0
               ,bIsContestWinner = 'false'
               ,mMontantAjout = @mMontantAjout
               ,iID_RDI_Paiement = @iID_RDI_Paiement
           FROM #Un_Unit U
           JOIN #Un_Convention C ON C.ID = U.UnitID
      
         DROP TABLE #Un_Unit
         DROP TABLE #Un_Convention         
      END 

   END

   DROP TABLE #Unit 

   DELETE 
     FROM CRI_Blob
    WHERE iBlobID = @iBlobID
    
   -- Enlever les informations dans la table temporaire
   DELETE FROM tblTEMP_RDI_Paiements 
    WHERE iID_Utilisateur = @iID_Utilisateur

END