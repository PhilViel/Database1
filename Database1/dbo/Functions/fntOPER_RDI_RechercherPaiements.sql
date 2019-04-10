/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fntOPER_RDI_RechercherPaiements
Nom du service  : Structurer les paiements
But             : Organise l’information sur les paiements dans le but de faciliter la recherche
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      Aucun

Paramètres de sortie: @tblOPER_RDI_Paiements
        Paramètre(s)             Champ(s)                                 Description
        ------------------------ ---------------------------------------  ---------------------------
        iID_RDI_Paiement         tblOPER_RDI_Paiements.iID_RDI_Paiement   Identifiant unique d'un paiement
        iID_RDI_Depot            tblOPER_RDI_Paiements.iID_RDI_Depot      Identifiant unique du dépôt associé au paiement
        vcNom_Deposant           tblOPER_RDI_Paiements.vcNom_Deposant     Nom du déposant
        vcNo_Document            tblOPER_RDI_Paiements.vcNo_Document      Numéro de document entré par le déposant
        vcSouscripteur           Mo_Human.lastName + Mo_Human.firstName   Nom et prénom du souscripteur
        vcNo_Oper                tblOPER_RDI_Paiements.vcNo_Oper          Numéro de l'opération du paiement
        mMontant_Paiement        tblOPER_RDI_Paiements.mMontant_Paiement  Montant du paiement final
        mMontant_Assigne         [dbo].[fnOPER_RDI_CalculerMontantAssignePaiement](@tblOPER_RDI_Paiements.iID_RDI_Paiement)
                                 Montant relié à une(des) opération(s)
        mMontant_Solde           tblOPER_RDI_Paiements.mMontant_Paiement - mMontant_Assigne
                                 Le montant du paiement moins le montant assigné

Exemple d’appel     : SELECT * FROM [dbo].[fntOPER_RDI_RechercherPaiements](1169)

Historique des modifications:
        Date            Programmeur                        Description
        ------------    ---------------------------------- ---------------------------
        2010-02-15      Danielle Côté                      Création du service
        2011-02-28      Danielle Côté                      Ajout de l'exclusion de fichier en erreur
        2016-05-16      Steeve Picard                      Ajout du paramètre «@iID_RDI_Depot» à la fonction
                                                           Optimisation pour retrouver les montants «mMontant_Assigne & mMontant_Solde»
                                                           Ajout des 2 nouveaux champs «tiID_RDI_Raison_Paiement» & «vcDescription_Raison» de la table «tblOPER_RDI_Paiements»
****************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_RDI_RechercherPaiements]
(
    @iID_RDI_Depot INT
)
RETURNS @tblOPER_RDI_Paiements
        TABLE
        (iID_RDI_Paiement    INT
        ,iID_RDI_Depot       INT
        ,vcNom_Deposant      VARCHAR(35)
        ,vcNo_Document       VARCHAR(30)
        ,vcSouscripteur      VARCHAR(50)
        ,vcNo_Oper           VARCHAR(50)
        ,mMontant_Paiement   MONEY
        ,mMontant_Assigne    MONEY
        ,mMontant_Solde      MONEY
        ,tiID_RDI_Raison_Paiement TINYINT
        ,vcDescription_Raison VARCHAR(100)
    )
BEGIN

   INSERT INTO @tblOPER_RDI_Paiements
              (iID_RDI_Paiement
              ,iID_RDI_Depot
              ,vcNom_Deposant
              ,vcNo_Document
              ,vcSouscripteur
              ,vcNo_Oper
              ,mMontant_Paiement
              --,mMontant_Assigne
              --,mMontant_Solde
              ,tiID_RDI_Raison_Paiement
              ,vcDescription_Raison
            )
        SELECT PAI.iID_RDI_Paiement
              ,PAI.iID_RDI_Depot
              ,dbo.fnCONV_FormaterNom(PAI.vcNom_Deposant)
              ,PAI.vcNo_Document
              ,dbo.fn_Mo_HumanName(CON.subscriberID)
              ,PAI.vcNo_Oper
              ,PAI.mMontant_Paiement_Final
              --,([dbo].[fnOPER_RDI_CalculerMontantAssignePaiement](PAI.iID_RDI_Paiement,NULL))
              --,(PAI.mMontant_Paiement_Final - ([dbo].[fnOPER_RDI_CalculerMontantAssignePaiement](PAI.iID_RDI_Paiement,NULL)))
              ,PAI.tiID_RDI_Raison_Paiement
              ,PAI.vcDescription_Raison
          FROM tblOPER_RDI_Paiements PAI
          JOIN tblOPER_RDI_Depots DEP ON DEP.iID_RDI_Depot = PAI.iID_RDI_Depot
          LEFT JOIN dbo.Un_Convention CON ON RTRIM(LTRIM(CON.ConventionNo)) = PAI.vcNo_Document
         WHERE PAI.iID_RDI_Depot = @iID_RDI_Depot
           AND dbo.fnOPER_EDI_ObtenirStatutFichier(DEP.iID_EDI_Fichier) <> 'ERR'

    UPDATE @tblOPER_RDI_Paiements
       SET mMontant_Assigne = dbo.fnOPER_RDI_CalculerMontantAssignePaiement(iID_RDI_Paiement, NULL)

    UPDATE @tblOPER_RDI_Paiements
       SET mMontant_Solde = mMontant_Paiement - mMontant_Assigne

   RETURN
END


