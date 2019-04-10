/****************************************************************************************************
 * Copyrights (c) 2008 Gestion Universitas inc
 * 
 * Code du service             : psSECU_RechercherGroupeDroit
 * Nom du service              : Renvoie la liste des Groupes recherchés avec leur droits assignés
 * But                         : Renvoie la liste des Groupes recherchés par UserGroupDesc ou UserGroupID avec leur droits assignés pour le module de securité
 * Facette                     : Module securité
 * Reférence                   : non disponible
 * 
 * Parametre d'entrée          : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               @iUserGroupID                       UserGroupID du groupe recherché
 *                               @vcUserGroupDesc                    Nom ou partie du groupe recherché
 * 
 *
 * Parametre de sortie         : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               *                                   Tous les champs du SELECT
 * 
 * Historique des modification : Date       Programmeur              Description                          Référence
 *                               ---------- ------------------------ ------------------------------------ -------------------
 *                               2008-08-15 Patrice Péau             Création du document                 ???
 * 
 ****************************************************************************************************************************/


CREATE PROCEDURE [dbo].[psSECU_RechercherGroupeDroit]
	@iUserGroupID MoID	,
	@vcUserGroupDesc MoLongDesc
AS
BEGIN
	SET NOCOUNT ON;

	SELECT  
			Mo_UserGroup.UserGroupID,
			Mo_UserGroup.UserGroupDesc,
			Mo_Right.RightID,
			Mo_Right.RightTypeID,
			Mo_Right.RightCode,
			Mo_Right.RightDesc,
			Mo_Right.RightVisible
	FROM Mo_UserGroup 
	INNER JOIN Mo_UserGroupRight ON	Mo_UserGroup.UserGroupID = Mo_UserGroupRight.UserGroupID 
	INNER JOIN Mo_Right ON Mo_UserGroupRight.RightID = Mo_Right.RightID
	WHERE (@iUserGroupID IS NULL OR Mo_UserGroup.UserGroupID = @iUserGroupID) 
		AND (@vcUserGroupDesc IS NULL OR Mo_UserGroup.UserGroupDesc LIKE '%'+@vcUserGroupDesc+'%') 
	ORDER BY Mo_UserGroup.UserGroupID

END
