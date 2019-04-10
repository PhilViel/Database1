/****************************************************************************************************
 * Copyrights (c) 2008 Gestion Universitas inc
 * 
 * Code du service             : fntSECU_RechercherDroit
 * Nom du service              : Renvoie la liste des droits ayant les caracteres passé en paramètre
 * But                         : Renvoie la liste des droits ayant les caracteres passé en paramètre pour le module de securité
 * Facette                     : Module securité
 * Reférence                   : non disponible
 * 
 * Parametre d'entrée          : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               @vcNomDroit                         Nom du droit
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
CREATE FUNCTION [dbo].[fntSECU_RechercherDroit]
                (
					@vcNomDroit VARCHAR(250) 	-- Nom du droit
				)

RETURNS TABLE 
AS
RETURN 
(
    SELECT   
		RightTypeDesc, 
		RightVisible, 
		RightDesc, 
		RightCode, 
		RightID, 
		Mo_RightType.RightTypeID
	FROM 
		dbo.Mo_Right 
		INNER JOIN dbo.Mo_RightType 
			ON Mo_Right.RightTypeID = Mo_RightType.RightTypeID  
	WHERE RightCode LIKE '%'+@vcNomDroit+'%'
--	WHERE RightDesc LIKE '%'+@vcNomDroit+'%'
	
)
