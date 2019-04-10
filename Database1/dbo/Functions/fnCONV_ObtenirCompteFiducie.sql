/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : fnCONV_ObtenirCompteFiducie
Nom du service  : Obtenir compte fiducie
But             : Obtenir le numéro de compte de la fiducie à partir de l'identifiant
                  du regroupement de régime.
Facette         : CONV

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      @iID_Regroupement_Regime   Identifiant unique du regroupement de régime

Paramètres de sortie: Paramètre                  Description
                      -------------------------- -------------------------------------
                @vcCode_Compte_Comptable_Fiducie Numéro du compte comptable

Exemple d’appel     : SELECT [dbo].[fnCONV_ObtenirCompteFiducie](1)

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ---------------------------------- ---------------------------
        2010-06-03     Danielle Côté                       Création du service

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_ObtenirCompteFiducie]
(
   @iID_Regroupement_Regime INT
)
RETURNS VARCHAR(12)
AS
BEGIN

   DECLARE
      @vcCode_Compte_Comptable_Fiducie VARCHAR(12)

   SELECT @vcCode_Compte_Comptable_Fiducie = vcCode_Compte_Comptable_Fiducie
     FROM tblCONV_RegroupementsRegimes
    WHERE iID_Regroupement_Regime = @iID_Regroupement_Regime

   RETURN @vcCode_Compte_Comptable_Fiducie

END 
