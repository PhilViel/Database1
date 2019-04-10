/****************************************************************************************************
 * Copyrights (c) 2008 Gestion Universitas inc
 * 
 * Code du service             : fnSECU_ObtenirAccessibiliteDroitUtilisateur
 * Nom du service              : Obtenir l’accessibilité d’un utilisateur à un droit
 * But                         : Permet aux applications de déterminer si l’utilisateur en cours possède un droit spécifique au contexte de l’application.
 * Facette                     : SECU
 * Reférence                   : P171U - SERVICES DU NOYAU DE LA FACETTE
 * 
 * Parametre d'entrée          : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               @iID_Utilisateur                    UserID de l'utilisateur
 *                               @vcCode_Droit						 Code du droit
 *                                                                   
 *
 * Parametre de sortie         : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               @Accessibilite                      0 : Faux, 1 : Vrai, Indicateur de l’accessibilité de l’utilisateur au droit.
 * 
 * Historique des modification : Date       Programmeur              Description                          Référence
 *                               ---------- ------------------------ ------------------------------------ -------------------
 *                               2008-09-09 Patrice Péau             Création du document                 ???
 * 
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fnSECU_ObtenirAccessibiliteDroitUtilisateur] 
(	
	@iID_Utilisateur varchar(255), -- UserID de l'utilisateur
	@vcCode_Droit varchar(255)     -- Code du droit
)

RETURNS int -- On retourne un integer, @Accessibilite 0 : Faux, 1 : Vrai, Indicateur de l’accessibilité de l’utilisateur au droit.
AS
BEGIN
	IF (
		SELECT COUNT(*)
		FROM Mo_User U,
			 Mo_Right R
		WHERE U.UserID = @iID_Utilisateur 
		  AND UPPER(R.RightCode) = UPPER(@vcCode_Droit)
		  AND (1 = ISNULL((SELECT Granted
						   FROM Mo_UserRight UR
						   WHERE UR.UserID = U.UserID AND
								 UR.RightID = R.RightID),0)
			  OR
			   EXISTS(SELECT *
					  FROM Mo_UserGroupDtl UGD
						   JOIN Mo_UserGroupRight UGR ON UGR.UserGroupID = UGD.UserGroupID AND
														 UGR.RightID = R.RightID
					  WHERE UGD.UserID = U.UserID AND
							1 = ISNULL((SELECT Granted
										FROM Mo_UserRight UR
										WHERE UR.UserID = U.UserID AND
										UR.RightID = R.RightID),1)))
		) = 1
	RETURN (1) -- Vrai
  RETURN (0);  -- Faux
END





