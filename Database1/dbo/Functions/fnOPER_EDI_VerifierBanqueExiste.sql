/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fnOPER_EDI_VerifierBanqueExiste
Nom du service  : Vérifier l'existence de la banque.
But             : Vérifier l'existence de la banque dans la table de référence de 
                  la base de données.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      @vcDescription_Court       Description courte du nom de la banque 
                                                 tel que dans le fichier

Paramètres de sortie: Table               Champs          Description
                      ------------------- --------------- ----------------------------
                      tblOPER_EDI_Banques tiID_EDI_Banque Identifiant unique de la banque 

Exemple d’appel     : SELECT [dbo].[fnOPER_EDI_VerifierBanqueExiste]('ROYAL DIRECT')

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-01-25      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnOPER_EDI_VerifierBanqueExiste]
(
   @vcDescription_Court VARCHAR(35)
)
RETURNS TINYINT
AS
BEGIN

   DECLARE
      @tiID_EDI_Banque TINYINT

   -- Rendre conforme le contenu du paramètre
   SET @vcDescription_Court = LTRIM(LTRIM(@vcDescription_Court))  

   IF EXISTS (SELECT 1
                FROM tblOPER_EDI_Banques
               WHERE UPPER(vcDescription_Court) = UPPER(@vcDescription_Court))
   BEGIN
      SELECT @tiID_EDI_Banque = tiID_EDI_Banque
        FROM tblOPER_EDI_Banques
       WHERE UPPER(vcDescription_Court) = UPPER(@vcDescription_Court)
   END
   ELSE
   BEGIN
      SET @tiID_EDI_Banque = 0
   END

   RETURN @tiID_EDI_Banque

END 
