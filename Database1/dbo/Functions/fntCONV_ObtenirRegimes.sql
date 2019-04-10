/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fntCONV_ObtenirRegimes
Nom du service  : Obtenir régimes d'un regroupement
But             : Obtenir les régimes d'un regroupement
Facette         : CONV

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @iID_Regroupement_Regime   Identifiant du regroupement de régime

Paramètres de sortie: @tblCONV_Regimes
        Paramètre(s)              Champ(s)                                 Description
        ------------------------  ---------------------------------------  ---------------------------
        iID_Plan                  Un_Plan.planID                           Régime

Exemple d’appel     : SELECT * FROM [dbo].[fntCONV_ObtenirRegimes](1)

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-06-01     Danielle Côté                       Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirRegimes]
(
   @iID_Regroupement_Regime INT
)
RETURNS @tblCONV_Regimes
        TABLE
        (iID_Plan INT)

BEGIN

   INSERT INTO @tblCONV_Regimes
   SELECT planID
     FROM Un_Plan
    WHERE iID_Regroupement_Regime = @iID_Regroupement_Regime

   RETURN
END 
