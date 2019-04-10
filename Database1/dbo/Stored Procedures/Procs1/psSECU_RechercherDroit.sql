/****************************************************************************************************
 * Copyrights (c) 2008 Gestion Universitas inc
 * 
 * Code du service             : psSECU_RechercherDroit
 * Nom du service              : Renvoie la liste des droits ayant les caracteres pass‚ en paramètre
 * But                         : Renvoie la liste des droits ayant les caracteres pass‚ en paramètre pour le module de securité
 * Facette                     : Module securité
 * Reférence                   : non disponible
 *
 * Exemple d'appel			   :
 *								 EXEC dbo.psSECU_RechercherDroit 'bénéficiaire',1
 * 
 * Parametre d'entrée          : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               @vcNomDroit                         Nom du droit
 *								 @iTypeRecherche					 NULL OU 1	=> Recherche par description
 *																	 2			=> Recherche par code	
 *
 *
 * Parametre de sortie         : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               *                                   Tous les champs du SELECT
 * 
 * Historique des modification : Date       Programmeur              Description                          Référence
 *                               ---------- ------------------------ ------------------------------------ -------------------
 *                               2008-08-15 Patrice Péau             Création du document                 
 *								 2009-06-19	Jean-François Gauthier	 Alias, commentaire, formatage de la requête
 *								 2009-07-03 Jean-François Gauthier	 Remplacement de RightDesc par RightCode dans le WHERE
								 2010-03-22	Jean-François Gauthier	 Ajout d'un paramètre permettant de spécifier sur quel champ
																	 se fera la recherche.
 ****************************************************************************************************************************/
CREATE PROCEDURE [dbo].[psSECU_RechercherDroit] 
								(
								@vcNomDroit			MoLongDesc 						-- Nom du droit
								,@iTypeRecherche	INT		= NULL					-- Type de recherche
								)	
AS
	BEGIN
		SET NOCOUNT ON

		IF ISNULL(@iTypeRecherche,1) = 1
			BEGIN
				SELECT   
					rt.RightTypeDesc, 
					r.RightVisible, 
					r.RightDesc, 
					r.RightCode, 
					r.RightID, 
					rt.RightTypeID
				FROM 
					dbo.Mo_Right r
					INNER JOIN 
						dbo.Mo_RightType rt
							ON r.RightTypeID = rt.RightTypeID  
				WHERE 
					r.RightDesc LIKE '%'+@vcNomDroit+'%'
					
				ORDER BY 
					rt.RightTypeDesc, 
					rt.RightTypeID,
					r.RightDesc
			END
		ELSE
			BEGIN
				SELECT   
					rt.RightTypeDesc, 
					r.RightVisible, 
					r.RightDesc, 
					r.RightCode, 
					r.RightID, 
					rt.RightTypeID
				FROM 
					dbo.Mo_Right r
					INNER JOIN 
						dbo.Mo_RightType rt
							ON r.RightTypeID = rt.RightTypeID  
				WHERE 
					r.RightCode LIKE '%'+@vcNomDroit+'%'
				ORDER BY 
					rt.RightTypeDesc, 
					rt.RightTypeID,
					r.RightDesc
			END
	END
