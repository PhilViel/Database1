/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psCONV_ObtenirRegroupementsRegimesPourParametreDeRapport
Nom du service  : Obtenir les regroupements de régimes pour le paramètre de rapport
But             : Obtenir les regroupements de régimes selon la langue de l’utilisateur, en plus de la valeur NULL "Sans regroupement de régime".
				  Cela permet de ne pas identifiier de regroupement de régime afin d'extraire les anciennes information non associées à un regroupement de régime
				  (ex : dans le rapport de Chèque par numéro)
Facette         : CONV

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -------------------------------------
                      cID_Langue                 Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
                                                 Le français est la langue par défaut si elle n’est pas spécifiée.

Paramètres de sortie: Paramètre Champ(s)         Description
                      --------- --------------   -------------------------------------
                      iID_Regroupement_Regime	 Id unique du regroupement
                      vcDescription				 La description du regroupement


Exemple d’appel     : EXECUTE [dbo].[psCONV_ObtenirRegroupementsRegimesPourParametreDeRapport] 'FRA'

Historique des modifications:
               Date          Programmeur        Description
               ------------  ------------------ --------------------------------------
               2010-10-27    Donald Huppé       Création du service
				2011-01-05		Donald Huppé	retourner @iID_regroupement_Regime=0(eu lieu de NULL) pour "Sans regroupement de régime"

EXECUTE [dbo].[psCONV_ObtenirRegroupementsRegimesPourParametreDeRapport] 'FRA'
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirRegroupementsRegimesPourParametreDeRapport]
(
   @cID_Langue CHAR(3)
)
AS
BEGIN
   -- Considérer le français comme la langue par défaut
   IF @cID_Langue IS NULL
      SET @cID_Langue = 'FRA'

   SET NOCOUNT ON


	select
		iID_Regroupement_Regime,
		vcDescription

	from (
	   -- Retourner les regroupements de régimes
	   SELECT RR.iID_Regroupement_Regime
			 ,CASE 
				 ISNULL(dbo.fnGENE_ObtenirParametre('TRADUCTION',NULL,'tblCONV_RegroupementsRegimes','vcDescription',
													RR.iID_Regroupement_Regime,@cID_Langue,NULL),'-2')
				 WHEN '-2' THEN RR.vcDescription
				 ELSE dbo.fnGENE_ObtenirParametre('TRADUCTION',NULL,'tblCONV_RegroupementsRegimes','vcDescription',
												  RR.iID_Regroupement_Regime,@cID_Langue,NULL)
			  END AS vcDescription

		 FROM tblCONV_RegroupementsRegimes RR
	   UNION
	   
	   SELECT 
			iID_Regroupement_Regime = 0, 
			vcDescription = 'Sans regroupement de régime'
          
		  ) V
	 order by iID_Regroupement_Regime
          
END

