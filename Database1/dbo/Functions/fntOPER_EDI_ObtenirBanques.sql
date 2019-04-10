/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fntOPER_EDI_ObtenirBanques
Nom du service  : Obtenir la description des banques
But             : Récupérer les informations descriptives des institutions financières.
                  Ce service utilisé principalement en liaison avec le champ tiID_EDI_Banque
                  de la table tblOPER_RDI_Depots.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      Aucun

Paramètres de sortie: @tblOPER_Banques
        Paramètre(s)             Champ(s)                                 Description
        ------------------------ ---------------------------------------  ---------------------------
        tiID_EDI_Banque          tblOPER_EDI_Banques.tiID_EDI_Banque      Identiant unique de la banque
        vcCode_Banque            tblOPER_EDI_Banques.vcCode_Banque        Code unique de 3 caratères de la banque
        vcDescription_Court      tblOPER_EDI_Banques.vcDescription_Court  Description courte du nom de l'institution
        vcDescription_long       tblOPER_EDI_Banques.vcDescription_long   Description longue du nom de l'institution

Exemple d’appel     : SELECT * FROM [dbo].[fntOPER_EDI_ObtenirBanques]()

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-05-18     Danielle Côté                       Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_EDI_ObtenirBanques]()
RETURNS @tblOPER_Banques
        TABLE
        (tiID_EDI_Banque     INT
        ,vcCode_Banque       VARCHAR(3)
        ,vcDescription_Court VARCHAR(35)
        ,vcDescription_long  VARCHAR(100)
        )

BEGIN

   INSERT INTO @tblOPER_Banques
   SELECT tiID_EDI_Banque
         ,vcCode_Banque
         ,vcDescription_Court
         ,vcDescription_Long
     FROM tblOPER_EDI_Banques 

   RETURN
END 
