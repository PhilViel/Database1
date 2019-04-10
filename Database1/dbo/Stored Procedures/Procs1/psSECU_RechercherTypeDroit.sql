/****************************************************************************************************
 * Copyrights (c) 2008 Gestion Universitas inc
 * 
 * Code du service             : psSECU_RechercherTypeDroit
 * Nom du service              : Renvoie un type de droit par RightTypeID avec ces droits liés
 * But                         : Renvoie un type de droit par RightTypeID avec ces droits liés pour le module de sécurité 
 * Facette                     : Module securité
 * Reférence                   : non disponible
 * 
 * Parametre d'entrée          : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               @iRightTypeID                       RightTypeID du type recherché
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
CREATE PROCEDURE [dbo].[psSECU_RechercherTypeDroit] 
	@iRightTypeID MoID	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT   
		RightTypeDesc, 
		RightVisible, 
		RightDesc, 
		RightCode, 
		RightID, 
		Mo_RightType.RightTypeID
	FROM Mo_Right 
	INNER JOIN Mo_RightType ON Mo_Right.RightTypeID = Mo_RightType.RightTypeID  
	WHERE Mo_RightType.RightTypeID = @iRightTypeID

END
