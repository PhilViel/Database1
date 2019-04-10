/****************************************************************************************************
 * Copyrights (c) 2008 Gestion Universitas inc
 * 
 * Code du service             : psSECU_ObtenirDroitsExclusif
 * Nom du service              : Recuperation des droits exclusif d'un usager
 * But                         : Recuperation des droits exclusif d'un usager pour le module securité
 * Facette                     : Module securité
 * Reférence                   : non disponible
 * 
 * Parametre d'entrée          : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               @iUserID                            Id du droit
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
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psSECU_ObtenirDroitsExclusif]
	@iUserID MoID
AS
BEGIN

	SET NOCOUNT ON;

	SELECT 
		Mo_UserRight.UserID,
		Mo_UserRight.Granted,
		Mo_Right.RightID,
		Mo_Right.RightTypeID, 
		Mo_Right.RightCode,
		Mo_Right.RightDesc,
		Mo_Right.RightVisible
	FROM Mo_UserRight 
	INNER JOIN Mo_Right ON Mo_UserRight.RightID = Mo_Right.RightID	
	WHERE MO_UserRight.UserID = @iUserID

END
