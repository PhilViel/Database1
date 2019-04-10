/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fntOPER_RDI_RechercherEncaissements
Nom du service  : Structurer les opérations RDI
But             : Organise l’information sur les encaissements qui proviennent des 
                  type d'opération RDI
                  Ce service est dérivé de RP_UN_DailyOperCashing
                  OPER005 - Rapport réception dépôts informatisé.doc
                  La particularité des opérations RDI c'est qu'elles sont reliées à un 
                  paiement.  Il peut y avoir une ou plusieurs opérations faites à partir d'un paiement.
                  Il y aussi la notion de solde, lorsqu'un paiement n'est pas totalement assigné
                  par une(des) opération(s). Le paiement fait partie d'un dépôt qui contient 
                  une ou plusieurs paiements.  Le dépôt est fait par la banque dans le compte de GUI.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @dtDate_Debut              Date du début du rapport
                      @dtDate_Fin                Date de fin du rapport

Paramètres de sortie: @tblOPER_Encaissements
Paramètre(s)             Champ(s)                                       Description
------------------------ ---------------------------------------        ---------------------------
iID_Encaissement         IDENTITY(1,1)                                  Identifiant unique de la table temporaire
iID_Utilisateur          Mo_User.UserID                                 Identifiant unique de l'utilisateur responsable de l'opération
vcNom_Utilisateur        Mo_Human.LastName + Mo_Human.FirstName         Nom complet de l'utilisateur responsable de l'opération
                         qui correspond au Mo_User.UserID
iID_RDI_Depot            tblOPER_RDI_Depots.iID_RDI_Depot               Identifiant unique du dépôt
dtDate_Depot             tblOPER_RDI_Depots.dtDate_Depot                Date du dépôt
tiID_EDI_Banque          tblOPER_RDI_Depots.tiID_EDI_Banque             Identifiant unique de la banque
vcNo_Trace               tblOPER_RDI_Depots.vcNo_Trace                  No de trace de la banque
iID_RDI_Paiement         tblOPER_RDI_Paiement.iID_RDI_Paiement          Identifiant unique du paiement
dtDate_Oper              Un_Oper.OperDate                               Date de l'opération
vcID_OperType            Un_Oper.OperTypeID OU 'HIS'                    Identifiant unique (en caractères) du type d'opération
vcDesc_OperType          Un_OperType.OperTypeDesc  OU 'Historique'      Description du type d'opération
vcPlan_Desc              Un_Plan.planDesc                               Description du régime
vcRegroup_Desc           tblCONV_RegroupementsRegimes.vcDescription     Description du regroupement de régime
vcNo_Convention          tblOPER_RDI_Paiement.vcNo_Document             Numéro de convention
                         s'il s'agit d'une opération à zéro
                         Un_Convention.ConventionNo
                         s'il s'agit d'une opération dans UniAccès
dtDateEffect_Conv        Un_Convention.dtDateEffect_Conv                Date d'effet de la convention
vcNom_Souscripteur       tblOPER_RDI_Paiements.vcNom_Deposant           Nom complet du souscripteur/déposant
                         s'il s'agit d'une opération à zéro
                         Mo_Human.LastName + Mo_Human.FirstName
                         s'il s'agit d'une opération dans UniAccès
mCotisation              Un_Cotisation.Cotisation                       Montant épargne
mFrais                   Un_Cotisation.Fee                              Montant frais
mAssBenef                Un_Cotisation.BenefInsur                       Montant assurance bénéficiaire
mAssSous      Un_Cotisation.SubscInsur                       Montant assurance souscripteur
mAssTax                  Un_Cotisation.TaxOnInsur                       Montant taxes sur assurance
mINC                     Un_ConventionOper.ConventionOperAmount         Montant intérêts chargés au souscripteur
mTotal                   Addition de                                    Montant Total de l'opération
                         mCotisation/mFrais/mAssBenef/mAssSous/mAssTax/mINC
mSous_APayer             mTotal en négatif                              Montant qui représente les mouvements dans le compte souscripteur à payer
mA_Assigner              mPaiement_Lu moins                             Montant qui représente le solde à assigner sur le paiement
                         fnOPER_RDI_CalculerMontantAssignePaiement à la date de fin du rapport
mPaiement_Calcule        mTotal + mA_Assigner                           Montant du paiement calculé par opération (rapport)
mPaiement_Lu             tblOPER_RDI_Paiement.mMontant_Paiement_Final   Montant du paiement réel dans la BD (sert au calcul)
iNbreOperation           SELECT count(*) FROM                           Nombre d'opération relié à un paiement
                         fntOPER_RDI_ObtenirDonneeOperation

Exemple d’appel     : SELECT * FROM [dbo].[fntOPER_RDI_RechercherEncaissements]('2010-03-17','2010-03-17')

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-04-20     Danielle Côté                       Création du service
        2011-02-28     Danielle Côté                       Ajout de la validation de fichier "non en erreur"

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_RDI_RechercherEncaissements]
(  
   @dtDate_Debut      DATETIME
  ,@dtDate_Fin        DATETIME
)
RETURNS @tblOPER_Encaissements
        TABLE
        (iID_Encaissement   INT IDENTITY(1,1)
        ,iID_Utilisateur    INT
        ,vcNom_Utilisateur  VARCHAR(100)
        ,iID_RDI_Depot      INT
        ,dtDate_Creation    DATETIME
        ,dtDate_Depot       DATETIME
        ,tiID_EDI_Banque    TINYINT
        ,vcNo_Trace         VARCHAR(30)
        ,iID_RDI_Paiement   INT
        ,dtDate_Oper        DATETIME
        ,vcID_OperType      VARCHAR(3)
        ,vcDesc_OperType    VARCHAR(75)
        ,vcPlan_Desc        VARCHAR(75)
        ,vcRegroup_Desc     VARCHAR(50)
        ,iClassement_regime INT
        ,vcNo_Convention    VARCHAR(32)
        ,dtDateEffect_Conv  DATETIME
        ,vcNom_Souscripteur VARCHAR(100)
        ,mCotisation        MONEY
        ,mFrais             MONEY
        ,mAssBenef          MONEY
        ,mAssSous           MONEY
        ,mAssTax            MONEY
        ,mINC               MONEY
        ,mTotal             MONEY
        ,mSous_APayer       MONEY
        ,mA_Assigner        MONEY
        ,mPaiement_Calcule  MONEY
        ,mPaiement_Lu       MONEY
        ,iNbreOperation     INT
        )
BEGIN

   SET @dtDate_Debut = [dbo].[fn_Mo_DateNoTime](@dtDate_Debut)
   SET @dtDate_Fin   = [dbo].[fn_Mo_DateNoTime](@dtDate_Fin)

   DECLARE 
      @iID_Encaissement INT
     ,@iID_RDI_Depot    INT
     ,@iID_Paiement     INT
     ,@mSolde           MONEY
     ,@mPaiement        MONEY

   ------------------------------------------------------------------
   -- Création des tables temporaires @Convention et @Oper
   -- @Convention contient les ID convention et la date effective
   -- @Oper contient les ID opération pour tous les types
   ------------------------------------------------------------------
   DECLARE @Convention 
           TABLE
          (iID_Convention    INT PRIMARY KEY
          ,dtDateEffect_Conv DATETIME)

   DECLARE @Oper
           TABLE
          (OperID            INT PRIMARY KEY)

   ------------------------------------------------------------------
   -- Insertion des ID convention et simulation de la date 
   -- effective pour les conventions transitoires qui ont date NULL
   ------------------------------------------------------------------
   INSERT INTO @Convention 
         (iID_Convention
         ,dtDateEffect_Conv)
   SELECT ConventionID
         ,EffectDate =
          CASE 
             WHEN dtRegStartDate IS NULL THEN @dtDate_Fin + 1
             ELSE dtRegStartDate
          END
     FROM dbo.Un_Convention WITH(NOLOCK)

   ------------------------------------------------------------------
   -- Identifier les dépôts touchés
   -- 1-Sélection des dépôts dont les paiements sont liés à des 
   -- opérations de la période (BETWEEN @dtDate_Debut AND @dtDate_Fin)
   -- 2-Sélection des dépôts dont tous les paiements sont en attente 
   -- et ont été créés dans UniAccès dans la période ( ... = 0)
   ------------------------------------------------------------------
   DECLARE curID_Depot CURSOR FOR
      SELECT DISTINCT(D.iID_RDI_Depot)
        FROM tblOPER_RDI_Depots D
        JOIN tblOPER_RDI_Paiements P ON P.iID_RDI_Depot = D.iID_RDI_Depot
        LEFT JOIN tblOPER_RDI_Liens L ON L.iID_RDI_Paiement = P.iID_RDI_Paiement
        LEFT JOIN Un_Oper O ON O.OperID = L.OperID
       WHERE [dbo].[fn_Mo_DateNoTime](O.OperDate) BETWEEN @dtDate_Debut AND @dtDate_Fin
     -------  
       UNION
     -------
      SELECT DISTINCT(D.iID_RDI_Depot)
        FROM tblOPER_RDI_Depots D
        JOIN tblOPER_EDI_Fichiers F ON F.iID_EDI_Fichier = D.iID_EDI_Fichier
       WHERE [dbo].[fn_Mo_DateNoTime](F.dtDate_Creation) BETWEEN @dtDate_Debut AND @dtDate_Fin
         AND [dbo].[fnOPER_RDI_CalculerMontantAssigneDepot](D.iID_RDI_Depot,@dtDate_Fin) = 0
         AND [dbo].[fnOPER_EDI_ObtenirStatutFichier](D.iID_EDI_Fichier) <> 'ERR'

   OPEN curID_Depot
   FETCH NEXT FROM curID_Depot INTO @iID_RDI_Depot
   WHILE @@FETCH_STATUS = 0
   BEGIN
      ------------------------------------------------------------------
      -- Insertion des opérations sur les dépôts sélectionnés (= @iID_RDI_Depot)
      -- Cumule les opérations historiques et ceux de la période (<= @dtDate_Fin)
      ------------------------------------------------------------------ 
      INSERT INTO @Oper
            (OperID)
      SELECT L.OperID
        FROM tblOPER_RDI_Paiements P
        JOIN tblOPER_RDI_Liens L ON L.iID_RDI_Paiement = P.iID_RDI_Paiement
        LEFT JOIN Un_Oper O ON O.OperID = L.OperID
       WHERE P.iID_RDI_Depot = @iID_RDI_Depot
         AND [dbo].[fn_Mo_DateNoTime](O.OperDate) <= @dtDate_Fin

      INSERT INTO @tblOPER_Encaissements
            (iID_RDI_Depot
            ,dtDate_Creation
            ,dtDate_Depot
            ,tiID_EDI_Banque 
            ,vcNo_Trace
            ,iID_RDI_Paiement
            ,dtDate_Oper
            ,vcID_OperType
            ,vcDesc_OperType
            ,vcPlan_Desc
            ,vcRegroup_Desc
            ,iClassement_Regime
            ,vcNo_Convention
            ,vcNom_Souscripteur
            ,mCotisation
            ,mFrais
            ,mAssBenef
            ,mAssSous
            ,mAssTax
            ,mINC
            ,mTotal
            ,mSous_APayer
            ,mA_Assigner
            ,mPaiement_Calcule
            ,mPaiement_Lu
            )
      SELECT iID_RDI_Depot      = D.iID_RDI_Depot
            ,dtDate_Depot       = F.dtDate_Creation
            ,dtDate_Depot       = D.dtDate_Depot
            ,tiID_EDI_Banque    = D.tiID_EDI_Banque
            ,vcNo_Trace         = D.vcNo_Trace
            ,iID_RDI_Paiement   = P.iID_RDI_Paiement
            ,dtDate_Oper        = D.dtDate_Depot
            ,vcID_OperType      = 'RDI'
            ,vcDesc_OperType    = 'Opération à zéro'
            ,vcPlan_Desc        = 
             CASE
                WHEN L.planDesc IS NULL THEN 'ND'
       ELSE L.planDesc
             END
            ,vcRegroup_Desc     = 
             CASE
                WHEN R.vcDescription IS NULL THEN 'ND'
                ELSE R.vcDescription
             END
            ,iClassement_Regime = 
             CASE
                WHEN L.OrderOfPlanInReport IS NULL THEN 99
                ELSE L.OrderOfPlanInReport
             END
            ,vcNo_Convention    =
             CASE
                WHEN C.ConventionNo IS NULL THEN RTRIM(LTRIM(P.vcNo_Document))
                ELSE RTRIM(LTRIM(C.ConventionNo))
             END
            ,vcNom_Souscripteur = [dbo].[fnCONV_FormaterNom](P.vcNom_Deposant)
            ,mCotisation        = 0
            ,mFrais             = 0
            ,mAssBenef          = 0
            ,mAssSous           = 0
            ,mAssTax            = 0
            ,mINC               = 0
            ,mTotal             = 0
            ,mSous_APayer       = 0
            ,mA_Assigner        = 0
            ,mPaiement_Calcule  = 0
            ,mPaiement_Lu       = P.mMontant_Paiement_Final
        FROM tblOPER_RDI_Paiements P
        JOIN tblOPER_RDI_Depots D ON D.iID_RDI_Depot = P.iID_RDI_Depot
         AND P.iID_RDI_Depot = @iID_RDI_Depot 
         AND [dbo].[fnOPER_RDI_CalculerMontantAssignePaiement](P.iID_RDI_Paiement,@dtDate_Fin) = 0
        JOIN tblOPER_EDI_Fichiers F ON F.iID_EDI_Fichier = D.iID_EDI_Fichier
        LEFT JOIN dbo.Un_Convention C ON RTRIM(LTRIM(C.ConventionNo)) = RTRIM(LTRIM(P.vcNo_Document))
        LEFT JOIN Un_Plan L ON L.PlanID = C.PlanID
        LEFT JOIN tblCONV_RegroupementsRegimes R ON R.iID_Regroupement_Regime = L.iID_Regroupement_Regime
       WHERE P.iID_RDI_Paiement 
         NOT IN (SELECT iID_RDI_Paiement I
                   FROM tblOPER_RDI_Liens E
                   JOIN Un_Oper P ON P.OperID = E.OperID
                  WHERE [dbo].[fn_Mo_DateNoTime](P.OperDate) <= @dtDate_Fin)

      FETCH NEXT FROM curID_Depot INTO @iID_RDI_Depot
   END
   CLOSE curID_Depot
   DEALLOCATE curID_Depot

   ------------------------------------------------------------------
   -- Insertion des opérations
   ------------------------------------------------------------------
   INSERT INTO @tblOPER_Encaissements 
         (iID_Utilisateur
         ,vcNom_Utilisateur
         ,iID_RDI_Depot
         ,dtDate_Creation
         ,dtDate_Depot
         ,tiID_EDI_Banque
         ,vcNo_Trace
         ,iID_RDI_Paiement
         ,dtDate_Oper
         ,vcID_OperType
         ,vcDesc_OperType
         ,vcPlan_Desc
         ,vcRegroup_Desc
         ,iClassement_Regime
         ,vcNo_Convention
         ,dtDateEffect_Conv
         ,vcNom_Souscripteur
         ,mCotisation
         ,mFrais     
         ,mAssBenef  
         ,mAssSous   
         ,mAssTax       
         ,mINC             
         ,mTotal
         ,mPaiement_Lu
         ,iNbreOperation
         )
   SELECT iID_Utilisateur    = DTL.iID_Utilisateur
         ,vcNom_Utilisateur  = DTL.vcNom_Utilisateur
         ,iID_RDI_Depot      = DEP.iID_RDI_Depot
         ,dtDate_Creation    = F.dtDate_Creation
         ,dtDate_Depot       = DEP.dtDate_Depot
         ,tiID_EDI_Banque    = DEP.tiID_EDI_Banque
         ,vcNo_Trace         = DEP.vcNo_Trace
         ,iID_RDI_Paiement   = DTL.iID_RDI_Paiement
         ,dtDate_Oper        = DTL.dtDate_Oper
         ,vcID_OperType      = DTL.vcID_OperType
         ,vcDesc_OperType    = OPT.OperTypeDesc
         ,vcPlan_Desc        = 
          CASE
             WHEN PLN.PlanDesc IS NULL THEN 'ND'
             ELSE PLN.PlanDesc
          END
         ,vcRegroup_Desc     = 
          CASE
             WHEN RRG.vcDescription IS NULL THEN 'ND'
             ELSE RRG.vcDescription
          END
         ,iClassement_Regime = 
          CASE
             WHEN PLN.OrderOfPlanInReport IS NULL THEN 99
             ELSE PLN.OrderOfPlanInReport
          END
         ,vcNo_Convention    = CON.ConventionNo
         ,dtDateEffect_Conv  = DTL.dtDateEffect_Conv
         ,vcNom_Souscripteur =
          CASE
             WHEN HUM.IsCompany = 0 THEN
                RTRIM(HUM.LastName) + ',' + RTRIM(HUM.FirstName)
                ELSE RTRIM(HUM.LastName)
          END
         ,mCotisation = SUM(DTL.mCotisation)
         ,mFrais      = SUM(DTL.mFrais)
         ,mAssBenef   = SUM(DTL.mAssBenef)
         ,mAssSous    = SUM(DTL.mAssSous)
         ,mAssTax     = SUM(DTL.mAssTax)
         ,mINC        = SUM(DTL.mINC)
         ,mTotal      = SUM(DTL.mCotisation)  + SUM(DTL.mFrais)   + 
                        SUM(DTL.mAssBenef)    + SUM(DTL.mAssSous) + 
                        SUM(DTL.mAssTax)      + SUM(DTL.mINC)
         ,mPaiement_Lu= DTL.mPaiement
         ,iNbreOperation =
          CASE
             WHEN DTL.iID_RDI_Paiement = 0 THEN 0
             ELSE (SELECT count(*) 
                     FROM [dbo].[fntOPER_RDI_ObtenirDonneeOperation](DTL.iID_RDI_Paiement))
          END
     FROM 
         (
         SELECT iID_Utilisateur   = S.UserID
               ,vcNom_Utilisateur = RTRIM(H.LastName) + ', ' + RTRIM(H.FirstName)
               ,iID_RDI_Depot     = P.iID_RDI_Depot
               ,iID_RDI_Paiement  = P.iID_RDI_Paiement
               ,dtDate_Oper       = O.OperDate
               ,vcID_OperType     = O.OperTypeID
               ,iID_Convention    = U.ConventionID
               ,dtDateEffect_Conv = F.dtDateEffect_Conv
               ,mPaiement         = P.mMontant_Paiement_Final
               ,mCotisation       = C.Cotisation
               ,mFrais            = C.Fee
               ,mAssBenef         = C.BenefInsur
               ,mAssSous          = C.SubscInsur
               ,mAssTax           = C.TaxOnInsur
               ,mINC              = 0
           FROM Un_Cotisation C WITH(NOLOCK)
           JOIN dbo.Un_Unit       U WITH(NOLOCK) ON U.UnitID = C.UnitID
           JOIN @Convention   F ON F.iID_Convention = U.ConventionID
           JOIN @Oper         T ON T.OperID = C.OperID
           JOIN Un_Oper       O WITH(NOLOCK) ON O.OperID = T.OperID
           JOIN Mo_Connect    N WITH(NOLOCK) ON N.ConnectID = O.ConnectID
           JOIN Mo_User       S WITH(NOLOCK) ON S.UserID = N.UserID
           JOIN dbo.Mo_Human      H WITH(NOLOCK) ON H.HumanID = S.UserID
           LEFT JOIN tblOPER_RDI_Liens     L WITH(NOLOCK) ON L.OperID = T.OperId
           LEFT JOIN tblOPER_RDI_Paiements P WITH(NOLOCK) ON P.iID_RDI_paiement = L.iID_RDI_paiement
         ---------
         UNION ALL 
         ---------
         SELECT iID_Utilisateur   = S.UserID
               ,vcNom_Utilisateur = RTRIM(H.LastName) + ', ' + RTRIM(H.FirstName)
               ,iID_RDI_Depot     = P.iID_RDI_Depot
               ,iID_RDI_Paiement  = P.iID_RDI_Paiement
               ,dtDate_Oper       = O.OperDate
               ,vcID_OperType     = O.OperTypeID
               ,iID_Convention    = C.ConventionID
               ,dtDateEffect_Conv = F.dtDateEffect_Conv
               ,mPaiement         = P.mMontant_Paiement_Final
               ,mCotisation       = 0
               ,mFrais            = 0
               ,mAssBenef         = 0
               ,mAssSous          = 0
               ,mAssTax           = 0
               ,mINC              = CASE WHEN C.ConventionOperTypeID = 'INC' THEN C.ConventionOperAmount ELSE 0 END
           FROM Un_ConventionOper C WITH(NOLOCK)
           JOIN @Convention       F ON F.iID_Convention = C.ConventionID
           JOIN @Oper             T ON T.OperID = C.OperID
           JOIN Un_Oper           O WITH(NOLOCK) ON O.OperID = T.OperID
           JOIN Mo_Connect        N WITH(NOLOCK) ON N.ConnectID = O.ConnectID
           JOIN Mo_User           S WITH(NOLOCK) ON S.UserID = N.UserID
           JOIN dbo.Mo_Human          H WITH(NOLOCK) ON H.HumanID = S.UserID
           LEFT JOIN tblOPER_RDI_Liens     L WITH(NOLOCK) ON L.OperID = T.OperId
     LEFT JOIN tblOPER_RDI_Paiements P WITH(NOLOCK) ON P.iID_RDI_paiement = L.iID_RDI_paiement
          WHERE (C.ConventionOperTypeID = 'INC')
            AND (C.ConventionOperAmount <> 0)
         ) DTL
     JOIN Un_OperType   OPT WITH(NOLOCK) ON OPT.OperTypeID = DTL.vcID_OperType
     JOIN dbo.Un_Convention CON WITH(NOLOCK) ON CON.ConventionID = DTL.iID_Convention
     JOIN Un_Plan       PLN WITH(NOLOCK) ON PLN.PlanID = CON.PlanID
     JOIN tblCONV_RegroupementsRegimes RRG WITH(NOLOCK) ON RRG.iID_Regroupement_Regime = PLN.iID_Regroupement_Regime
     JOIN dbo.Mo_Human      HUM WITH(NOLOCK) ON HUM.HumanID = CON.SubscriberID
     LEFT JOIN tblOPER_RDI_Depots DEP WITH(NOLOCK) ON DEP.iID_RDI_Depot = DTL.iID_RDI_Depot
     LEFT JOIN tblOPER_EDI_Fichiers F ON F.iID_EDI_Fichier = DEP.iID_EDI_Fichier
    GROUP BY DTL.dtDate_Oper
            ,DTL.iID_Utilisateur
            ,DTL.vcNom_Utilisateur
            ,DTL.vcID_OperType
            ,OPT.OperTypeDesc
            ,DTL.iID_Convention
            ,CON.ConventionNo
            ,PLN.PlanDesc
            ,RRG.vcDescription
            ,DEP.iID_RDI_Depot
            ,DTL.iID_RDI_Paiement
            ,HUM.LastName
            ,HUM.FirstName
            ,HUM.IsCompany
            ,DTL.mPaiement
            ,DTL.dtDateEffect_Conv
            ,DEP.tiID_EDI_Banque
            ,DEP.dtDate_Depot
            ,DEP.vcNo_Trace
				,PLN.OrderOfPlanInReport
            ,F.dtDate_Creation
   -- les opérations dont le résultat est à zéro doivent apparaîtrent
   --HAVING SUM(DTL.mCotisation) <> 0  
       --OR SUM(DTL.mFrais)      <> 0 ...
       
   ------------------------------------------------------------------
   -- Lorsque le nombre d'opération relié à un paiement est > 0,
   -- établir celui qui contiendra le solde à payer s'il y a lieu.
   -- Pour ce faire, choisir l'opération la plus récente en
   -- prendrant l'enregistrement ayant MAX(date) pour
   -- Un paiement sur 1 convention, deux oper à deux dates différentes
   -- OU en
   -- prendrant l'enregistrement ayant MAX(Convention) pour
   -- Un paiement sur 2 conventions, deux oper à la même date
   ------------------------------------------------------------------

   -- On recherche les paiements reliés à des opérations 
   -- multiples (iNbreOperation > 1) afin de déterminer
   -- le montant à assigner
   DECLARE cur_Encaissement CURSOR FOR
      SELECT iID_RDI_Paiement 
            ,mPaiement_Lu
        FROM @tblOPER_Encaissements
       WHERE iNbreOperation > 1

   OPEN cur_Encaissement
   FETCH NEXT FROM cur_Encaissement INTO @iID_Paiement, @mPaiement
   WHILE @@FETCH_STATUS = 0
   BEGIN
      -- Identifier s'il reste un solde à assigner
      SET @mSolde = @mPaiement - [dbo].[fnOPER_RDI_CalculerMontantAssignePaiement](@iID_Paiement,@dtDate_Fin)

      -- Le paiement est totalement assigné, fixer le 
      -- montant à assigner à zéro pour toutes les opérations
      IF @mSolde = 0
      BEGIN
         UPDATE @tblOPER_Encaissements
            SET mA_Assigner = 0
               ,iNbreOperation = 1
          WHERE iID_RDI_Paiement = @iID_Paiement
      END
      -- Il reste un solde à assigner, sélectionner l'enregistrement
      -- sur lequel le solde à assigner sera imputé
      IF @mSolde > 0
      BEGIN
         SELECT @iID_Encaissement = E1.iID_Encaissement
           FROM @tblOPER_Encaissements E1
          INNER JOIN
        (SELECT iID_RDI_Paiement
               ,MAX(dtDate_Oper) as dtDate_Oper 
           FROM @tblOPER_Encaissements 
          GROUP BY iID_RDI_Paiement) E2
             ON E1.dtDate_Oper = E2.dtDate_Oper 
          INNER JOIN
        (SELECT iID_RDI_Paiement
               ,MAX(vcNo_Convention) as vcNo_Convention 
           FROM @tblOPER_Encaissements 
          GROUP BY iID_RDI_Paiement) E3
             ON E1.vcNo_Convention  = E3.vcNo_Convention
            AND E1.iID_RDI_Paiement = E2.iID_RDI_Paiement
AND E2.iID_RDI_Paiement = E3.iID_RDI_Paiement
            AND E1.iID_RDI_Paiement = @iID_Paiement

         UPDATE @tblOPER_Encaissements
            SET mA_Assigner = @mSolde
               ,iNbreOperation = 1
          WHERE iID_Encaissement = @iID_Encaissement
      END

      FETCH NEXT FROM cur_Encaissement INTO @iID_Paiement, @mPaiement
   END
         
   CLOSE cur_Encaissement
   DEALLOCATE cur_Encaissement

   -- Il reste un solde à assigner, mais l'opération n'est
   -- pas celle qui affiche le solde
   UPDATE @tblOPER_Encaissements
      SET mA_Assigner = 0
         ,iNbreOperation = -1
    WHERE iNbreOperation > 1

   -- Fixer le montant à assigner aux opérations simples (1 paiement/1 oper)
   -- en soustrayant le montant déjà assigné du paiement reçu
   UPDATE @tblOPER_Encaissements
      SET mA_Assigner = mPaiement_Lu - [dbo].[fnOPER_RDI_CalculerMontantAssignePaiement](iID_RDI_Paiement,@dtDate_Fin)
    WHERE iNbreOperation = 1

   -- Étalir le montant de la colonne "Montant à assigner"
   -- S'il n'y a pas d'opération (NULL) le solde à assigner 
   -- correspond au montant du paiement reçu
   UPDATE @tblOPER_Encaissements
      SET mA_Assigner = mPaiement_Lu
    WHERE iNbreOperation IS NULL	 

   -- Établir le montant de la colonne "Souscripteur à payer"
   UPDATE @tblOPER_Encaissements
      SET mSous_APayer = - (mTotal)

   -- Calcul final du paiement à afficher dans le rapport
   UPDATE @tblOPER_Encaissements
      SET mPaiement_Calcule = mTotal + mA_Assigner
 
   -- Une date d'opération ne peut être antérieure à la date de création du fichier.
   -- Dans le cas d'une opération à zéro qui utilise la date du dépôt, si celle-ci
   -- est plus petite que la date de création du fichier, remplacer.
   UPDATE @tblOPER_Encaissements
      SET dtDate_Oper = dtDate_Creation
    WHERE dtDate_Oper < dtDate_Creation   

   -- Toutes les opérations dont la date est plus petite que la date de début
   -- sont des opérations "historique"
   UPDATE @tblOPER_Encaissements
      SET vcID_OperType = 'HIS'
    WHERE dtDate_Oper < @dtDate_Debut

   RETURN 
END 


