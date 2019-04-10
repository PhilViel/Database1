/****************************************************************************************************
 * Copyrights (c) 2008 Gestion Universitas inc
 * 
 * Code du service             : psSECU_RechercherUsager
 * Nom du service              : Recherche usager suivant le nom, prénom ou son LoginNameID
 * But                         : Recherche usager suivant le nom, prénom ou son LoginNameID pour le module de sécurité 
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
 * Exemple d'appel 
 *				EXECUTE dbo.[psSECU_RechercherUsager] 'ppeau'
 *
 * Historique des modification : Date       Programmeur              Description                          Référence
 *                               ---------- ------------------------ ------------------------------------ -------------------
 *                               2008-08-15 Patrice Péau             Création du document                 
 *								 2009-06-15 Jean-François Gauthier	 Élimination du OUTPUT sur le paramètre
 *								 2009-06-19	Jean-François Gauthier	 Alias, commentaire, formatage de la requête
 ****************************************************************************************************************************/
CREATE PROCEDURE [dbo].[psSECU_RechercherUsager] 
	@vcNomUsager VARCHAR(255)
AS
	BEGIN	
		SET NOCOUNT ON
		SELECT 
			h.LastName + ', ' + h.FirstName AS UserName,
			h.HumanID ,
			h.FirstName ,
			h.LastName ,
			u.LoginNameID ,
			u.UserID ,
			u.CodeID ,
			u.TerminatedDate,
			s1.ConnectStart 
		FROM 
			dbo.Mo_Human h
			INNER JOIN dbo.Mo_User u 
				ON h.HumanID = u.UserID
			LEFT OUTER JOIN (
							SELECT	UserID, MAX(ConnectStart) AS ConnectStart
							FROM	dbo.Mo_Connect	
							GROUP BY UserID
							) AS s1 
				ON (u.UserID = s1.UserID)
		WHERE 	
			(
				h.FirstName		LIKE '%'+@vcNomUsager+'%'					OR
				h.LastName		LIKE '%'+@vcNomUsager+'%'					OR
				h.LastName		+ ', ' + H.FirstName  = ''+@vcNomUsager+''	OR
				h.LastName		+ ' ' + H.FirstName  = ''+@vcNomUsager+''	OR
				h.FirstName		+ ', ' + H.LastName  = ''+@vcNomUsager+''	OR
				h.FirstName		+ ' ' + H.LastName  = ''+@vcNomUsager+''	OR
				u.LoginNameID	LIKE '%'+@vcNomUsager+'%'  
			) 
		ORDER BY 
			h.FirstName, 
			h.LastName 
	END
