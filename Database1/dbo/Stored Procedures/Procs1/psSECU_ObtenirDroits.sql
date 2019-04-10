/****************************************************************************************************
 * Copyrights (c) 2008 Gestion Universitas inc
 * 
 * Code du service             : psSECU_ObtenirDroits
 * Nom du service              : Recuperation d'un droit et son type
 * But                         : Recuperation d'un droit et son type pour la classe d'objet Mo_Right pour le module de securité
 * Facette                     : Module securité
 * Reférence                   : non disponible
 * 
 * Parametre d'entrée          : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               @iRightID                           Id du droit
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
CREATE PROCEDURE [dbo].[psSECU_ObtenirDroits]

	@iRightID MoID

AS
BEGIN

	SET NOCOUNT ON;

	SELECT 
		Mo_Right.RightID,
		Mo_Right.RightTypeID,
		Mo_Right.RightCode,
		Mo_Right.RightDesc,
		Mo_Right.RightVisible,
		Mo_RightType.RightTypeID,  
		Mo_RightType.RightTypeDesc
	FROM Mo_Right 
	INNER JOIN Mo_RightType ON Mo_Right.RightTypeID = Mo_RightType.RightTypeID 
	WHERE RightID = @iRightID
	ORDER BY Mo_Right.RightTypeID 

END
