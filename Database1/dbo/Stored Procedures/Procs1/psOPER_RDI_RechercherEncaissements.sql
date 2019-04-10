/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_RDI_RechercherEncaissements
Nom du service  : Rechercher les encaissements.
But             : Rechercher les encaissements selon les critères de sélection de l'utilisateur.
                  OPER005 - Rapport réception dépôts informatisé.doc
Facette         : OPER

Paramètres d’entrée :
Paramètre                  Description
-------------------------- ------------------------------------------------------------
iID_Utilisateur            Identifiant unique de l'utilisateur connecté
dtDate_Debut               Date du début du rapport
dtDate_Fin                 Date de fin du rapport
vcID_StatutConv            Statut des conventions 'REEE' ou 'TRA'

Paramètres de sortie:
Paramètre           Champ(s)                                               Description
------------------- ------------------------------------------------------ -------------------
iID_RDI_Depot       fntOPER_RDI_RechercherEncaissements.iID_RDI_Depot      Identifiant unique du dépôt
dtDate_depot        fntOPER_RDI_RechercherEncaissements.dtDate_depot       Date du dépôt
vcBanque            fntOPER_EDI_ObtenirBanques.vcBanque                    Nom court de l'institution financière
vcNo_Trace          fntOPER_EDI_ObtenirBanques.vcNo_Trace                  Numéro de trace de la banque
iID_RDI_Paiement    fntOPER_RDI_RechercherEncaissements.iID_RDI_Paiement   Identifiant unique du paiement
vcID_OperType       fntOPER_RDI_RechercherEncaissements.vcID_OperType      Identifiant unique (en caractères) du type d'opération
dtDate_Oper         fntOPER_RDI_RechercherEncaissements.dtDate_Oper        Date de l'opération
vcPlan_Desc         fntOPER_RDI_RechercherEncaissements.vcPlan_Desc        Description du régime
vcRegroup_Desc      fntOPER_RDI_RechercherEncaissements.vcRegroup_Desc     Description du regroupement de régime
vcNo_Convention     fntOPER_RDI_RechercherEncaissements.vcNo_Convention    Numéro de la convention
vcNom_Souscripteur  fntOPER_RDI_RechercherEncaissements.vcNom_Souscripteur Nom du souscripteur
mCotisation         fntOPER_RDI_RechercherEncaissements.mCotisation        Montant épargne
mFrais              fntOPER_RDI_RechercherEncaissements.mFrais             Montant frais
mAssBenef           fntOPER_RDI_RechercherEncaissements.mAssBenef          Montant assurance du bénéficiaire
mAssSous            fntOPER_RDI_RechercherEncaissements.mAssSous           Montant assurance du souscripteur
mAssTax             fntOPER_RDI_RechercherEncaissements.mAssTax            Montant assurance taxes
mINC                fntOPER_RDI_RechercherEncaissements.mINC               Montant intérêts chargés au souscripteur
mTotal              fntOPER_RDI_RechercherEncaissements.mTotal             Total de tous les montants précédents
mSous_APayer        fntOPER_RDI_RechercherEncaissements.mSous_APayer       Montant de l'opération "Souscripteur à payer"
vcA_Assigner        fntOPER_RDI_RechercherEncaissements.vcA_Assigner       Montant solde du paiement à assigner
mPaiement           fntOPER_RDI_RechercherEncaissements.mPaiement          Montant du paiement relié à l'opération

Exemple d’appel     : EXECUTE [dbo].[psOPER_RDI_RechercherEncaissements] 575757,'2010-03-24','2010-03-30','REEE'

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-04-15      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RDI_RechercherEncaissements]
(
   @iID_Utilisateur   INT
  ,@dtDate_Debut      DATETIME
  ,@dtDate_Fin        DATETIME
  ,@vcID_StatutConv   VARCHAR(4)
)
AS
BEGIN

   DECLARE
      @siTraceRapport SMALLINT
     ,@dtDebut        DATETIME
     ,@dtFin          DATETIME

   SET @dtDebut = GETDATE()

   -- Établir les valeurs minimums
   IF @vcID_StatutConv IS NULL
      SET @vcID_StatutConv = 'REEE'

   SET NOCOUNT ON

   DECLARE 
      @vcSQL NVARCHAR(4000)
     ,@vcParametre NVARCHAR(1000)

   -- Requête de base
   SET @vcSQL = 
     N'SELECT E.iID_RDI_Depot as iID_RDI_Depot
             ,E.dtDate_Depot as dtDate_depot
             ,B.vcDescription_Court as vcBanque
             ,E.vcNo_Trace as vcNo_Trace
             ,E.iID_RDI_Paiement as iID_RDI_Paiement
             ,E.vcID_OperType as vcID_OperType
             ,E.dtDate_Oper as dtDate_Oper
             ,E.vcPlan_Desc as Regime
             ,E.vcRegroup_Desc as GrRegime
             ,E.iClassement_Regime as OrderOfPlanInReport
             ,E.vcNo_Convention as vcNo_Convention
             ,E.vcNom_Souscripteur as vcNom_Souscripteur
             ,E.mCotisation as mCotisation
             ,E.mFrais as mFrais
             ,E.mAssBenef as mAssBenef
             ,E.mAssSous as mAssSous
             ,E.mAssTax as mAssTax
             ,E.mINC as mINC
             ,E.mTotal as mTotal
             ,E.mSous_APayer as mSous_APayer
				 ,E.mA_Assigner
             ,vcA_Assigner =
              CASE
                 WHEN iNbreOperation = -1 THEN '' *''
                 ELSE '' ''
              END
             ,E.mPaiement_Calcule as mPaiement
         FROM [dbo].[fntOPER_RDI_RechercherEncaissements](@dtDate_Debut,@dtDate_Fin) E
         JOIN [dbo].[fntOPER_EDI_ObtenirBanques]() B ON B.tiID_EDI_Banque = E.tiID_EDI_Banque '

   -- S'il s'agit de conventions transitoires
   IF @vcID_StatutConv = 'TRA'
   BEGIN
      SET @vcSQL = @vcSQL +
        N'WHERE ((dtDate_Oper >= dbo.fn_Mo_DateNoTime(dtDateEffect_Conv)) 
             OR (dtDateEffect_Conv < ''2003-01-01'') 
             OR (dtDateEffect_Conv IS NULL)) '
   END

   SET @vcSQL = @vcSQL +
     N'ORDER BY iID_RDI_Depot, vcID_OperType, vcNom_Souscripteur, vcNo_Convention, dtDate_Oper'

   SET @vcParametre =
     N'@dtDate_Debut DATETIME
      ,@dtDate_Fin   DATETIME'

   EXECUTE sp_Executesql
           @vcSQL
          ,@vcParametre
          ,@dtDate_Debut
          ,@dtDate_Fin

   SET NOCOUNT OFF

   ------------------------------------------------------------------
   -- Insertion d'un log dans la table Un_Trace
   ------------------------------------------------------------------
   SET @dtFin = GETDATE()
   SELECT @siTraceRapport = siTraceReport
     FROM Un_Def

   IF DATEDIFF(SECOND, @dtDebut, @dtFin) > @siTraceRapport
   BEGIN
      INSERT INTO
             Un_Trace
            (ConnectID          -- ID de connexion de l’usager
            ,iType              -- Type de trace (1 = recherche, 2 = rapport)
            ,fDuration          -- Temps d’exécution de la procédure
            ,dtStart            -- Date et heure du début de l’exécution.
            ,dtEnd              -- Date et heure de la fin de l’exécution.
            ,vcDescription      -- Description de l’exécution (en texte)
            ,vcStoredProcedure  -- Nom de la procédure stockée
            ,vcExecutionString) -- Ligne d’exécution (inclus les paramètres)
      SELECT @iID_Utilisateur
            ,2
            ,DATEDIFF(SECOND, @dtDebut, @dtFin)
            ,@dtDebut
            ,@dtFin
            ,'Opérations journalières (Encaissements) Dépôts informatisés entre le ' + CAST(@dtDate_Debut AS VARCHAR) + ' et le ' + CAST(@dtDate_Fin AS VARCHAR)
            ,'psOPER_RDI_RechercherEncaissements'
            ,'EXECUTE [dbo].[psOPER_RDI_RechercherEncaissements] @iID_Utilisateur =' + CAST(@iID_Utilisateur AS VARCHAR)+
             ', @dtDate_Debut = ' + CAST(@dtDate_Debut AS VARCHAR)+
             ', @dtDate_Fin = ' + CAST(@dtDate_Fin AS VARCHAR)  +
             ', @vcID_StatutConv = ' + @vcID_StatutConv
   END

END

