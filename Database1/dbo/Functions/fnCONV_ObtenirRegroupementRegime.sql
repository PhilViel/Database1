/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fnCONV_ObtenirRegroupementRegime
Nom du service  : Obtenir regroupement régime
But             : Obtenir le regroupement d'un régime
Facette         : CONV

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      @iID_Regime                Identifiant du régime

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -------------------------------------
                      @iID_Regroupement_Regime   Identifiant du regroupement du régime

Exemple d’appel     : SELECT [dbo].[fnCONV_ObtenirRegroupementRegime](4)

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-06-03     Danielle Côté                       Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_ObtenirRegroupementRegime]
(
   @iID_Regime INT
)
RETURNS INT
AS
BEGIN

   DECLARE
      @iID_Regroupement_Regime INT

   SELECT @iID_Regroupement_Regime = iID_Regroupement_Regime
     FROM Un_Plan
    WHERE PlanID = @iID_Regime

   RETURN @iID_Regroupement_Regime

END 
