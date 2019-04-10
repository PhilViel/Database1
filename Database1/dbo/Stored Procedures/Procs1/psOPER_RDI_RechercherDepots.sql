/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_RDI_RechercherDepots
Nom du service  : Rechercher les dépôts.
But             : Rechercher les dépôts selon les critères de sélection de l'utilisateur.
Facette         : OPER

Paramètres d’entrée :
Paramètre                  Description
-------------------------- --------------------------------------------------------------------------
@cID_Langue                Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
                           Le français est la langue par défaut si elle n’est pas spécifiée.
@dtDate_Creation_Debut     Date de début de création/importation du fichier.  Si elle est vide,
                           toutes les dates de création sont considérées ou jusqu’à la date de
                           fin si elle est non vide.
@dtDate_Creation_Fin       Date de fin de création/importation du fichier.  Si elle est vide,
                           toutes les dates de création sont considérées ou à partir de la date de
                           début si elle est non vide.
@dtDate_Depot_Debut        Date de début du dépôt.  Si elle est vide, toutes les dates de dépôts
                           sont considérées ou jusqu’à la date de fin si elle est non vide.
@dtDate_Depot_Fin          Date de fin du dépôt.  Si elle est vide, toutes les dates de dépôts
                           sont considérées ou à partir de la date de début si elle est non vide.
@tiID_EDI_Banque           Identifiant unique de la banque.  S'il est vide, toutes les banques sont
                           considérées.
@vcNo_Cheque               Numéro de trace de la banque du déposant. S'il est vide, tous les
                           numéros de traces sont considérés.
@mMontant_Depot            Montant du dépôts.  S'il est vide, tous les montants sont considérés.
@tiID_RDI_Statut_Depot     Identifiant unique du statut du dépôt.  S'il est vide, tous les statuts
                           de dépôts sont considérés.

Paramètres de sortie: 
Paramètre                 Champ(s)                                              Description
------------------------- ----------------------------------------              ---------------------------
iID_RDI_Depot             fntOPER_RDI_RechercherDepots.iID_RDI_Depot            Identifiant unique d'un dépôt
dtDate_Importation        fntOPER_RDI_RechercherDepots.dtDate_Importation       Date d'importation des données dans la BD
dtDate_Depot              fntOPER_RDI_RechercherDepots.dtDate_Depot             Date du dépôt du montant dans le compte de GUI.
vcInstitution_Financiere  fntOPER_RDI_RechercherDepots.vcInstitution_Financiere Nom de l'institution financière.
vcNo_Cheque               fntOPER_RDI_RechercherDepots.vcNo_Cheque              Numéro de suivi de la banque du déposant.
vcNo_Trace                fntOPER_RDI_RechercherDepots.vcNo_Trace               Numéro de suivi du fournisseur de services RBC.
mMontant_Depot            fntOPER_RDI_RechercherDepots.mMontant_Depot           Montant du dépôt.
mMontant_Assigne          fntOPER_RDI_RechercherDepots.mMontant_Assigne         Montant total relié à une (des) opération(s).
mMontant_Solde            fntOPER_RDI_RechercherDepots.mMontant_Solde           Le montant du dépôt moins le montant assigné.
tiID_RDI_Statut_Depot     fntOPER_RDI_RechercherDepots.iID_RDI_Statut_Depot     Identifiant unique du statut de dépôt

Exemple d’appel     : EXECUTE [dbo].[psOPER_RDI_RechercherDepots] NULL,'2016-01-23','2016-06-26',NULL,NULL,NULL,NULL,NULL,5

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-02-02      Danielle Côté                      Création du service
        2016-06-10      Steeve Picard                      Éliminer la requête dynamique

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RDI_RechercherDepots]
(
   @cID_Langue            VARCHAR(3)
  ,@dtDate_Creation_Debut DATETIME
  ,@dtDate_Creation_Fin   DATETIME
  ,@dtDate_Depot_Debut    DATETIME
  ,@dtDate_Depot_Fin      DATETIME
  ,@tiID_EDI_Banque       TINYINT
  ,@vcNo_Cheque           VARCHAR(30)
  ,@mMontant_Depot        MONEY
  ,@tiID_RDI_Statut_Depot TINYINT
)
AS
BEGIN

   -- Établir des valeurs minimums
   IF @cID_Langue IS NULL
      SET @cID_Langue = 'FRA'

   IF @tiID_EDI_Banque IS NULL
      SET @tiID_EDI_Banque = 0

   IF @mMontant_Depot IS NULL
      SET @mMontant_Depot = 0

   IF @tiID_RDI_Statut_Depot IS NULL
      SET @tiID_RDI_Statut_Depot = 0

   SET NOCOUNT ON

   -- Requête de base
   SELECT iID_RDI_Depot
         ,dtDate_Importation
         ,dtDate_Depot
         ,vcInstitution_Financiere
         ,vcNo_Cheque
         ,vcNo_Trace
         ,mMontant_Depot
         ,mMontant_Assigne
         ,mMontant_Solde
         ,tiID_RDI_Statut_Depot
         ,vcDescription
    FROM dbo.fntOPER_RDI_RechercherDepots(NULL) 
    WHERE iID_RDI_Depot > 0
      AND (@dtDate_Creation_Debut IS NULL
           OR Cast(dtDate_Importation as Date) >= Cast(@dtDate_Creation_Debut as Date)
          )
      AND (@dtDate_Creation_Fin IS NULL
           OR Cast(dtDate_Importation as Date) <= Cast(@dtDate_Creation_Fin as Date)
          )
      AND (@dtDate_Depot_Debut IS NULL
           OR Cast(dtDate_Depot as Date) <= Cast(@dtDate_Depot_Debut as Date)
          )
      AND (@dtDate_Depot_Fin IS NULL
           OR Cast(dtDate_Depot as Date) <= Cast(@dtDate_Depot_Fin as Date)
          )
      AND (@tiID_EDI_Banque = 0
           OR tiID_EDI_Banque = @tiID_EDI_Banque
          )
      AND (@vcNo_Cheque IS NULL
           OR vcNo_Cheque = @vcNo_Cheque
          )
      AND (@mMontant_Depot = 0
           OR mMontant_Depot = @mMontant_Depot
          )
      AND ( @tiID_RDI_Statut_Depot = 0
            OR @tiID_RDI_Statut_Depot = tiID_RDI_Statut_Depot
            OR @tiID_RDI_Statut_Depot = 5 AND tiID_RDI_Statut_Depot IN (2, 3, 4)
           )
    ORDER BY dtDate_Importation desc, dtDate_Depot desc, vcInstitution_Financiere

END 
