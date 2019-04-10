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

Paramètres de sortie: Paramètre Champ(s)         Description
                      --------- --------------   -------------------------------------


Exemple d’appel     : EXECUTE [dbo].[psCONV_ObtenirPlanPourParametreDeRapport]

Historique des modifications:
				Date        Programmeur         Description
				----------  ------------------  --------------------------------------
				2011-11-24  Donald Huppé        Création du service
                2018-11-08  Pierre-Luc Simard   Utilsiation du nom complet du plan

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirPlanPourParametreDeRapport]
AS
BEGIN
   SET NOCOUNT ON

select 
	PlanID,
	PlanDesc
from (

	SELECT
		ORDRE = 1,
		PlanID,
		PlanDesc = NomPlan
	FROM Un_Plan

	UNION
	
	SELECT
		ORDRE = 0,
		PlanID = 0,
		PlanDesc = 'Tous les plans'
	) V
order by 
	Ordre,
	PlanDesc

          
END