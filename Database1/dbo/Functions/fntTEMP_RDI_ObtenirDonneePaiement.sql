/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fntTEMP_RDI_ObtenirDonneePaiement
Nom du service  : Obtenir les données d'un paiement
But             : Récupérer l’information mise dans la table temporaire des paiements.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- ------------------------------------
                      @iID_Utilisateur           ID de l'utilisateur

Paramètres de sortie: @tblTEMP_RDI_ObtenirDonneePaiement
Paramètre(s)             Champ(s)                                 Description
------------------------ ---------------------------------------  -----------
iID_RDI_Paiement         tblTEMP_RDI_Paiements.iID_RDI_Paiement   Identifiant unique d'un paiement
iID_RDI_Depot            tblTEMP_RDI_Paiements.iID_RDI_Depot      Identifiant unique du dépôt associé au paiement
mMontantAjout            tblTEMP_RDI_Paiements.mMontantAjout      Solde disponible
vcNo_Document            tblTEMP_RDI_Paiements.vcNo_Document      Numéro de document entré par le déposant
iID_Utilisateur          tblTEMP_RDI_Paiements.iID_Utilisateur    Valeur du paramètre d'entrée
iConventionID            tblTEMP_RDI_Paiements.iConventionID      = Un_Convention.ConventionID

Exemple d’appel     : SELECT * FROM [dbo].[fntTEMP_RDI_ObtenirDonneePaiement](575752)

Historique des modifications:
        Date            Programmeur                        Description
        ------------    ---------------------------------- --------------------------
        2010-03-02      Danielle Côté                      Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntTEMP_RDI_ObtenirDonneePaiement]
(
   @iID_Utilisateur INT
)
RETURNS @tblTEMP_RDI_ObtenirDonneePaiement
        TABLE
        (iID_RDI_Paiement INT
        ,iID_RDI_Depot    INT
        ,mMontantAjout    MONEY
        ,vcNo_Document    VARCHAR(30)
        ,iID_Utilisateur  INT
        ,iConventionID    INT)
BEGIN

   DECLARE
      @vcNo_Document VARCHAR(15)
     ,@iConventionID INT
     
   SET @iConventionID = 0

   -- Récupérer le no de la convention
   SELECT @vcNo_Document = SUBSTRING(vcNo_Document,1,15)
     FROM tblTEMP_RDI_Paiements
    WHERE iID_Utilisateur = @iID_Utilisateur 

   -- Obtenir le ID de la convention
   SELECT @iConventionID = ConventionID
     FROM dbo.Un_Convention 
    WHERE UPPER(ConventionNo) = UPPER(@vcNo_Document)
   
   INSERT INTO @tblTEMP_RDI_ObtenirDonneePaiement
              (iID_RDI_Paiement
              ,iID_RDI_Depot
              ,mMontantAjout
              ,vcNo_Document
              ,iID_Utilisateur
              ,iConventionID)
        SELECT iID_RDI_Paiement
              ,iID_RDI_Depot
              ,mMontantAjout
              ,vcNo_Document
              ,iID_Utilisateur
              ,@iConventionID
          FROM tblTEMP_RDI_Paiements
         WHERE vcNo_Document = @vcNo_Document
           AND iID_Utilisateur = @iID_Utilisateur
           AND mMontantAjout > 0

   RETURN

END 


