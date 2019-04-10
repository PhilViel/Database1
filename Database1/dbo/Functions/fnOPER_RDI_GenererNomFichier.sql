/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fnOPER_RDI_GenererNomFichier
Nom du service  : Générer le nom du fichier.
But             : Genère un nom de fichier texte construit avec la date du jour.
Facette         : OPER

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      Aucun

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -----------------------------------
                      @vcResultat                Nom complet du fichier

Exemple d’appel     : SELECT [dbo].[fnOPER_RDI_GenererNomFichier]()

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-01-20      Danielle Côté                       Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnOPER_RDI_GenererNomFichier]
()
RETURNS VARCHAR(50)
AS
BEGIN
   DECLARE
      @vcResultat VARCHAR(50)

   SET @vcResultat =
       LTRIM(STR(YEAR(CURRENT_TIMESTAMP))) +
       LTRIM(REPLICATE('0', 2 - LEN(LTRIM(STR(MONTH(CURRENT_TIMESTAMP))))) +
       LTRIM(STR(MONTH(CURRENT_TIMESTAMP)))) +
       LTRIM(REPLICATE('0', 2 - LEN(LTRIM(STR(DAY(CURRENT_TIMESTAMP))))) +
       LTRIM(STR(DAY(CURRENT_TIMESTAMP)))) + '.txt'         

   RETURN @vcResultat
END 
