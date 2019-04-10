/****************************************************************************************************
 * Copyrights (c) 2008 Gestion Universitas inc
 * 
 * Code du service             : fn_HaveRight
 * Nom du service              : Obtenir l’accessibilité d’un utilisateur à un droit
 * But                         : Permet aux applications de déterminer si l’utilisateur en cours possède un droit spécifique au contexte de l’application.
 * Facette                     : S/O
 * Reférence                   : S/O
 * 
 * Parametre d'entrée          : Parametre                           Description 
 *                               ----------------------------------- --------------------------------------------
 *                               ConnectID							 Identifiant de la connexion de l'utilisateur
 *                               RightCode							 Code du droit<
 * 
 * Exemple :					SELECT [dbo].[fn_HaveRight](207005,'IQEE_FICHIERS_SUPPRIMER')
 *
 * Parametre de sortie         : Parametre                           Description 
 *                               ----------------------------------- -------------------------------------------------
 *                               Accessibilite                       0 : Faux, 1 : Vrai, Indicateur de l’accessibilité
 *																	 de l’utilisateur au droit.
 * 
 * Historique des modification : Date       Programmeur              Description                          Référence
 *                               ---------- ------------------------ ------------------------------------ -------------------
 *                               2008-10-03 Éric Deshaies            Modification de la fonction originale
 *																	 qui ne tenait pas compte du retrait
 *																	 d'un droit lorsque le droit était
 *																	 obtenue via un groupe.
 * 
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fn_HaveRight] 
(	
	@ConnectID	MoID,
	@RightCode	MoDesc
)
RETURNS INT -- On retourne un integer, @Accessibilite 0 : Faux, 1 : Vrai, Indicateur de l’accessibilité de l’utilisateur au droit.
AS
BEGIN
	IF (
		SELECT COUNT(*)
		FROM Mo_Connect C
			 JOIN Mo_User U ON U.UserID = C.UserID,
			 Mo_Right R
		WHERE C.ConnectID = @ConnectID 
		  AND UPPER(R.RightCode) = UPPER(@RightCode)
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








