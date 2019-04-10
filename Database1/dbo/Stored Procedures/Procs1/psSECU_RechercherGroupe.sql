/****************************************************************************************************
 * Copyrights (c) 2008 Gestion Universitas inc
 * 
 * Code du service             : psSECU_RechercherGroupe
 * Nom du service              : Renvoie la liste des groupes
 * But                         : Renvoie la liste des groupes par leur UserGroupID ou UserGroupDesc
 * Facette                     : Module securité
 * Reférence                   : non disponible
 * 
 * Parametre d'entrée          : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               @iUserGroupID                       UserGroupID du groupe recherché
 *                               @vcUserGroupDesc                    UserGroupDesc du groupe recherché
 *				EXECUTE [dbo].[psSECU_RechercherGroupe] '', ''
 *
 * Parametre de sortie         : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               *                                   Tous les champs du SELECT
 * 
 * Historique des modification : Date       Programmeur              Description                          Référence
 *                               ---------- ------------------------ ------------------------------------ -------------------
 *                               2008-08-20 Patrice Péau             Création du document                 ???
 *								 2010-02-25	Jean-François Gauthier	 Modification afin qu'une valeur vide corresponde à NULL
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psSECU_RechercherGroupe]
		@iUserGroupID MoID,
		@vcUserGroupDesc MoLongDesc
AS
BEGIN
	SET NOCOUNT ON;

	SELECT 
		UserGroupID, UserGroupDesc
	FROM  
		Mo_UserGroup
	WHERE 
		(NULLIF(@iUserGroupID,0) IS NULL OR UserGroupID = @iUserGroupID) 
		AND	
		(NULLIF(@vcUserGroupDesc,'') IS NULL OR UserGroupDesc = @vcUserGroupDesc) 

END
