/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	SL_UN_RepRole
Description         :	Procédure de sélection de tous les rôles des représentants
Valeurs de retours  :	DataSet :
						   		RepRoleID	CHAR(3)		Chaîne unique de trois caractères identifiant le rôle.
									RepRoleDesc	VARCHAR(75)	Le rôle.
								@ReturnValue :
									> 0 : [Réussite]
									<= 0 : [Échec].
Note                :	ADX0000995	IA	2006-05-19	Mireya Gonthier		Création								
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepRole]( 
	@RepRoleID VARCHAR(3) ) -- Chaîne unique de trois caractères identifiant le rôle. ('' = Tous)
AS
BEGIN
	SELECT 
		RepRoleID,
		RepRoleDesc
	FROM Un_RepRole
	WHERE @RepRoleID = ''
		OR @RepRoleID = RepRoleID
	ORDER BY RepRoleDesc
END

