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

Exemple d’appel     : SELECT * FROM dbo.vwOPER_RDI_RechercherDepots

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2016-05-16      Steeve Picard                       Remplace la fntOPER_RDI_RechercherDepots afin de rester compatible 
****************************************************************************************************/
CREATE VIEW dbo.vwOPER_RDI_RechercherDepots as
    SELECT iID_RDI_Depot
          ,dtDate_Importation
          ,dtDate_Depot
          ,tiID_EDI_Banque
          ,vcInstitution_Financiere
          ,vcNo_Cheque
          ,vcNo_Trace
          ,mMontant_Depot
          ,dbo.fnOPER_RDI_CalculerMontantAssigneDepot(iID_RDI_Depot, NULL) as mMontant_Assigne
          ,mMontant_Depot - dbo.fnOPER_RDI_CalculerMontantAssigneDepot(iID_RDI_Depot,NULL) as mMontant_Solde
          ,tiID_RDI_Statut_Depot
          ,vcCode_Statut
          ,vcDescription  
    FROM (
            SELECT iID_RDI_Depot
                  ,dtDate_Importation
                  ,dtDate_Depot
                  ,tiID_EDI_Banque
                  ,vcInstitution_Financiere
                  ,vcNo_Cheque
                  ,vcNo_Trace
                  ,mMontant_Depot
                  ,tiID_RDI_Statut_Depot
                  ,vcCode_Statut
                  ,vcDescription  
            FROM  fntOPER_RDI_RechercherDepots(NULL)
    ) X
