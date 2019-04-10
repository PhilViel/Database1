/****************************************************************************************************
 * Copyrights (c) 2008 Gestion Universitas inc
 * 
 * Code du service             : psSECU_ObtenirGroupesDroit
 * Nom du service              : Renvoie la liste des groupes ayant le droit passé en paramètre
 * But                         : Renvoie la liste des groupes ayant le droit passé en paramètre pour le module sécurité
 * Facette                     : Module securité
 * Reférence                   : non disponible
 * 
 * Parametre d'entrée          : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               @iID_Droit                          Id du droit
 * 
 *
 * Parametre de sortie         : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               *                                   Tous les champs du SELECT
 * 
 * Historique des modification : Date       Programmeur              Description                          Référence
 *                               ---------- ------------------------ ------------------------------------ -------------------
 *                               2008-07-24 Thierry Sombreffe        Création du document                 ???
 * 
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psSECU_ObtenirGroupesDroit] 
	@iID_Droit MOID -- Identifiant unique du droit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT 
		UG.UserGroupDesc, 
		UG.UserGroupID 
	FROM Mo_UserGroup UG
	LEFT JOIN Mo_UserGroupRight UGR ON UGR.UserGroupID=UG.UserGroupID
	WHERE UGR.RightID=@iID_Droit

END
