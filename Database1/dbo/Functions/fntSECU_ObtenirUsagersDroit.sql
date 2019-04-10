/****************************************************************************************************
 * Copyrights (c) 2008 Gestion Universitas inc
 * 
 * Code du service             : fntSECU_ObtenirUsagersDroit
 * Nom du service              : Renvoie la liste des usagers qui ont ce droit
 * But                         : Renvoie la liste des usagers qui ont ce droit
 * Facette                     : Module securité
 * Reférence                   : non disponible
 * 
 * Parametre d'entrée          : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               @iID_Droit                          Identificateur du droit
 * 
 *
 * Parametre de sortie         : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               *                                   Tous les champs du SELECT
 * 
 * Historique des modification : Date       Programmeur              Description                          Référence
 *                               ---------- ------------------------ ------------------------------------ -------------------
 *                               2009-03-19 Jean-Francois Arial      Création du document                 ???
 * 
 ****************************************************************************************************************************/
CREATE FUNCTION dbo.fntSECU_ObtenirUsagersDroit
                (
					@iID_Droit MoID 	-- Id du droit
				)

RETURNS TABLE 
AS
RETURN 
(

	SELECT DISTINCT 
		H.LastName, 
		H.FirstName, 
		UGD.UserID, 
		1 as HeritageGroupe
	FROM mo_usergroupright UGR
	LEFT JOIN Mo_UserGroupDtl UGD on UGD.usergroupID = UGR.UserGroupID
	LEFT JOIN dbo.Mo_Human H on H.HumanID = UGD.UserID
	LEFT JOIN Mo_UserRight UR on (UR.UserID = H.HumanID and UR.RightID = @iID_Droit)
	WHERE UGR.RightID = @iID_Droit AND (UR.Granted > 0 OR UR.Granted is null)

	UNION

	SELECT DISTINCT 
		H.LastName, 
		H.FirstName, 
		UR.UserID, 
		0 as HeritageGroupe
	FROM Mo_UserRight UR
	LEFT JOIN dbo.Mo_Human H on H.HumanID = UR.UserID
	WHERE RightID = @iID_Droit AND UR.Granted > 0	
)


