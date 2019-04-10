/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psCONV_ObtenirRegroupementsRegimes
Nom du service  : Obtenir les regroupements de régimes
But             : Obtenir les regroupements de régimes selon la langue de l’utilisateur.
Facette         : CONV

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      cID_Langue                 Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
                                                 Le français est la langue par défaut si elle n’est pas spécifiée.

Paramètres de sortie: Paramètre Champ(s)         Description
                      --------- --------------   -------------------------------------
                      Tous les champs de la table « tblCONV_RegroupementsRegimes ».  Les régimes sont
                      triées en ordre alphabétique de la description.

Exemple d’appel     : EXECUTE [dbo].[psCONV_ObtenirRegroupementsRegimes] 'FRA'

Historique des modifications:
               Date          Programmeur        Description
               ------------  ------------------ --------------------------------------
               2010-05-25    Éric Deshaies      Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirRegroupementsRegimes]
(
   @cID_Langue CHAR(3)
)
AS
BEGIN
   -- Considérer le français comme la langue par défaut
   IF @cID_Langue IS NULL
      SET @cID_Langue = 'FRA'

   SET NOCOUNT ON

   -- Retourner les regroupements de régimes
   SELECT RR.iID_Regroupement_Regime
         ,RR.vcCode_Regroupement
         ,CASE 
             ISNULL(dbo.fnGENE_ObtenirParametre('TRADUCTION',NULL,'tblCONV_RegroupementsRegimes','vcDescription',
                                                RR.iID_Regroupement_Regime,@cID_Langue,NULL),'-2')
             WHEN '-2' THEN RR.vcDescription
             ELSE dbo.fnGENE_ObtenirParametre('TRADUCTION',NULL,'tblCONV_RegroupementsRegimes','vcDescription',
                                              RR.iID_Regroupement_Regime,@cID_Langue,NULL)
          END AS vcDescription
         ,RR.vcCode_Compte_Comptable_Fiducie
     FROM tblCONV_RegroupementsRegimes RR
    ORDER BY 
          CASE 
             ISNULL(dbo.fnGENE_ObtenirParametre('TRADUCTION',NULL,'tblCONV_RegroupementsRegimes','vcDescription',
                                                RR.iID_Regroupement_Regime,@cID_Langue,NULL),'-2')
             WHEN '-2' THEN RR.vcDescription
             ELSE dbo.fnGENE_ObtenirParametre('TRADUCTION',NULL,'tblCONV_RegroupementsRegimes','vcDescription',
                                              RR.iID_Regroupement_Regime,@cID_Langue,NULL)
          END
END

