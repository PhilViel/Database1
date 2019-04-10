/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psOPER_EDI_ImporterRDI_Automatique
Nom du service  : Vérifier importation automatique.
But             : Vérifier si l'importation du fichier RDI doit être faite.
                  Si le fichier existe, ne pas lancer le traitement.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------

Paramètres de sortie: Paramètre Champ(s)
                      --------- --------------

Exemple d’appel     : EXECUTE [dbo].[psOPER_EDI_ImporterRDI_Automatique]

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-09-15      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_EDI_ImporterRDI_Automatique]
AS
BEGIN
   -------------------------------------------------------------------------
   -- Lancer la job seulement si le fichier n'existe pas dans UniAccès
   -------------------------------------------------------------------------    
   DECLARE @vcNom_Fichier VARCHAR(50)   
   SET @vcNom_Fichier = [dbo].[fnOPER_RDI_GenererNomFichier]()

   IF NOT EXISTS (SELECT 1
                    FROM tblOPER_EDI_Fichiers f,
                         tblOPER_EDI_StatutsFichier s
                   WHERE UPPER(vcNom_Fichier) = UPPER(@vcNom_Fichier)
                     AND f.tiID_EDI_Statut_Fichier = s.tiID_EDI_Statut_Fichier
                     AND s.vcCode_Statut <> 'ERR')
   BEGIN 
      EXECUTE [dbo].[psOPER_EDI_ImporterRDI] 'RDI', 2
   END
END
