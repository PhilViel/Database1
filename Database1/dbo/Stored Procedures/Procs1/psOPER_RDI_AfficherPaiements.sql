/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_RDI_AfficherPaiements
Nom du service  : Afficher le détail d'un dépôt.
But             : Afficher tous les paiements d'un dépôt.
Facette         : OPER

Paramètres d’entrée :
Paramètre                  Description
-------------------------- --------------------------------------------------------------------------
@cID_Langue                Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
                           Le français est la langue par défaut si elle n’est pas spécifiée.
@iID_RDI_Depot             Identifiant unique d'un dépôt

Paramètres de sortie: 
Paramètre                 Champ(s)                                              Description
------------------------- ----------------------------------------------------- ---------------------------
vcInstitution_Financiere  fntOPER_RDI_RechercherDepots.vcInstitution_Financiere Description courte du nom de la banque
mMontant_Depot            fntOPER_RDI_RechercherDepots.mMontant_Depot           Montant du dépôt
mMontant_Assigne_Depot    fntOPER_RDI_RechercherDepots.mMontant_Assigne         Montant relié à une(des) opération(s) sur le dépôt
mMontant_Solde_Depot      fntOPER_RDI_RechercherDepots.mMontant_Solde           Le montant du paiement moins le montant assigné  
vcDescription             fntOPER_RDI_RechercherDepots.vcDescription            Description du statut du dépôt
iID_RDI_Depot             fntOPER_RDI_RechercherPaiements.iID_RDI_Depot         Identifiant unique du dépôt associé au paiement
iID_RDI_Paiement          fntOPER_RDI_RechercherPaiements.iID_RDI_Paiement      Identifiant unique d''un paiement
dtDate_Depot              fntOPER_RDI_RechercherDepots.dtDate_Depot             Date du dépôt du montant dans le compte de GUI
vcNom_Deposant            fntOPER_RDI_RechercherPaiements.vcNom_Deposant        Nom du déposant
vcNo_Document             fntOPER_RDI_RechercherPaiements.vcNo_Document         Numéro de document entré par le déposant
vcSouscripteur            fntOPER_RDI_RechercherPaiements.vcSouscripteur        Nom et prénom du souscripteur
vcNo_Oper                 fntOPER_RDI_RechercherPaiements.vcNo_Oper             Numéro de l'opération du paiement
mMontant_Paiement         fntOPER_RDI_RechercherPaiements.mMontant_Paiement     Montant du paiement final
mMontant_Assigne_Paiement fntOPER_RDI_RechercherPaiements.mMontant_Assigne      Montant relié à une(des) opération(s) sur le paiement
mMontant_Solde_Paiement   fntOPER_RDI_RechercherPaiements.mMontant_Solde        Le montant du paiement moins le montant assigné

Exemple d’appel     : EXECUTE dbo.psOPER_RDI_AfficherPaiements NULL,42

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-02-15      Danielle Côté                      Création du service
        2016-05-16      Steeve Picard                      Ajout du paramètre «@iID_RDI_Depot» aux fonctions «fntOPER_RDI_RechercherPaiements & fntOPER_RDI_RechercherDepots»
                                                           Ajout de 2 nouveaux champs retournés «tiID_RDI_Raison_Paiement» & «vcDescription_Raison»
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RDI_AfficherPaiements]
(
   @cID_Langue    CHAR(3)
  ,@iID_RDI_Depot INT
)
AS
BEGIN

   IF @cID_Langue IS NULL
      SET @cID_Langue = 'FRA'

   SELECT DEP.vcInstitution_Financiere as vcInstitution_Financiere
         ,DEP.mMontant_Depot as mMontant_Depot
         ,DEP.mMontant_Assigne as mMontant_Assigne_Depot
         ,DEP.mMontant_Solde as mMontant_Solde_Depot         
         ,DEP.vcDescription as vcDescription
         ,PAI.iID_RDI_Depot as iID_RDI_Depot
         ,PAI.iID_RDI_Paiement as iID_RDI_Paiement
         ,DEP.dtDate_Depot as dtDate_Depot
         ,PAI.vcNom_Deposant as vcNom_Deposant
         ,PAI.vcNo_Document as vcNo_Document
         ,PAI.vcSouscripteur as vcSouscripteur
         ,PAI.vcNo_Oper as vcNo_Oper
         ,PAI.mMontant_Paiement as mMontant_Paiement
         ,PAI.mMontant_Assigne as mMontant_Assigne_Paiement
         ,PAI.mMontant_Solde as mMontant_Solde_Paiement         
         ,PAI.tiID_RDI_Raison_Paiement
         ,PAI.vcDescription_Raison
     FROM dbo.fntOPER_RDI_RechercherPaiements(@iID_RDI_Depot) PAI
          JOIN dbo.fntOPER_RDI_RechercherDepots(@iID_RDI_Depot) DEP ON DEP.iID_RDI_Depot = PAI.iID_RDI_Depot
    --WHERE PAI.iID_RDI_Depot = @iID_RDI_Depot
    ORDER BY PAI.vcNom_Deposant

END 
