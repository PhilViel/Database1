/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fntOPER_RDI_RechercherDepots
Nom du service  : Structurer les dépôts.
But             : Organise l’information sur les dépôts dans le but de faciliter la recherche
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      Aucun

Paramètres de sortie: @tblOPER_RDI_Depots
        Paramètre(s)             Champ(s)                                 Description
        ------------------------ ---------------------------------------  ---------------------------
        iID_RDI_Depot            tblOPER_RDI_Depots.iID_RDI_Depot         Identifiant unique d'un dépôt
        dtDate_Importation       tblOPER_EDI_Fichiers.dtDate_Creation     Date d'importation des données dans la BD
        dtDate_Depot             tblOPER_RDI_Depots.dtDate_Depot          Date du dépôt du montant dans le compte de GUI
        tiID_EDI_Banque          tblOPER_EDI_Banques.tiID_EDI_Banque      Identifiant unique d'une banque
        vcInstitution_Financière tblOPER_EDI_Banques.vcDescription_Court  Description courte du nom de la banque
        vcNo_Cheque              tblOPER_RDI_Depots.vcNo_Cheque           Numéro de suivi de la banque du déposant
        vcNo_Trace               tblOPER_RDI_Depots.vcNo_Trace            Numéro de suivi du fournisseur de services RBC 
        mMontant_Depot           tblOPER_RDI_Depots.mMontant_Depot        Montant du dépôt 
        mMontant_Assigne         [dbo].[fnOPER_RDI_CalculerMontantAssigneDepot](@tblOPER_RDI_Depots.iID_RDI_Depot)
                                 Montant relié à une(des) opération(s)
        mMontant_Solde           tblOPER_RDI_Depots.mMontant_Depot - mMontant_Assigne
                                 Le montant du dépôt moins le montant assigné
        tiID_RDI_Statut_Depot    tblOPER_RDI_Depots.tiID_RDI_Statut_Depot Statut du dépôt
        vcCode_Statut            tblOPER_RDI_StatutsDepot.vcCode_Statut   Code de statut de dépôt
        vcDescription            tblOPER_RDI_StatutsDepot.vcDescription   Description du statut de dépôt

Exemple d’appel     : SELECT * FROM dbo.fntOPER_RDI_RechercherDepots(1169)

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-01-26      Danielle Côté                       Création du service
        2011-02-28      Danielle Côté                       Appel d'une fonction au lieu de la vérification
                                                            dans la requête que le fichier n'est pas en erreur
        2016-05-16      Steeve Picard                       Ajout du paramètre «@iID_RDI_Depot» à la fonction
                                                            Optimisation pour retrouver les montants «mMontant_Assigne & mMontant_Solde»

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_RDI_RechercherDepots]
(
    @iID_RDI_Depot INT = NULL
)
RETURNS @tblOPER_RDI_Depots
        TABLE
        (iID_RDI_Depot                INT
        ,dtDate_Importation           DATETIME
        ,dtDate_Depot                 DATETIME
        ,tiID_EDI_Banque              TINYINT
        ,vcInstitution_Financiere     VARCHAR(35)
        ,vcNo_Cheque                  VARCHAR(30)
        ,vcNo_Trace                   VARCHAR(30)
        ,mMontant_Depot               MONEY
        ,mMontant_Assigne             MONEY
        ,mMontant_Solde               MONEY
        ,tiID_RDI_Statut_Depot        TINYINT
        ,vcCode_Statut                VARCHAR(3)
        ,vcDescription                VARCHAR(50))
BEGIN

   DECLARE
      @tiID_RDI_Statut_Depot  TINYINT

   INSERT INTO @tblOPER_RDI_Depots 
              (iID_RDI_Depot
              ,dtDate_Importation
              ,dtDate_Depot
              ,tiID_EDI_Banque
              ,vcInstitution_Financiere
              ,vcNo_Cheque
              ,vcNo_Trace
              ,mMontant_Depot
              --,mMontant_Assigne
              --,mMontant_Solde
              ,tiID_RDI_Statut_Depot
              ,vcCode_Statut
              ,vcDescription)
        SELECT DEP.iID_RDI_Depot
              ,FIC.dtDate_Creation
              ,DEP.dtDate_Depot
              ,BNQ.tiID_EDI_Banque
              ,BNQ.vcDescription_Court
              ,DEP.vcNo_Cheque
              ,DEP.vcNo_Trace
              ,DEP.mMontant_Depot
              --,(dbo.fnOPER_RDI_CalculerMontantAssigneDepot(DEP.iID_RDI_Depot,NULL))
              --,(DEP.mMontant_Depot - (dbo.fnOPER_RDI_CalculerMontantAssigneDepot(DEP.iID_RDI_Depot,NULL)))
              ,DEP.tiID_RDI_Statut_Depot
              ,STA.vcCode_Statut
              ,STA.vcDescription
          FROM tblOPER_RDI_Depots DEP
          JOIN tblOPER_EDI_Fichiers     FIC ON FIC.iID_EDI_Fichier = DEP.iID_EDI_Fichier
          JOIN tblOPER_EDI_Banques      BNQ ON BNQ.tiID_EDI_Banque = DEP.tiID_EDI_Banque
          JOIN tblOPER_RDI_StatutsDepot STA ON STA.tiID_RDI_Statut_Depot = DEP.tiID_RDI_Statut_Depot
         WHERE (@iID_RDI_Depot IS NULL OR DEP.iID_RDI_Depot = @iID_RDI_Depot)
           AND dbo.fnOPER_EDI_ObtenirStatutFichier(DEP.iID_EDI_Fichier) <> 'ERR'

    UPDATE @tblOPER_RDI_Depots
       SET mMontant_Assigne = dbo.fnOPER_RDI_CalculerMontantAssigneDepot(iID_RDI_Depot, NULL)

    UPDATE @tblOPER_RDI_Depots
       SET mMontant_Solde = mMontant_Depot - mMontant_Assigne

   RETURN
END
