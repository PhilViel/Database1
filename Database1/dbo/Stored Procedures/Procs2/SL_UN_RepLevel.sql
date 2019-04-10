/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	SL_UN_RepLevel
Description         :	Procédure de sélection de la liste des niveaux des représentants. 	
			@RepRoleID = '' retourne tous les niveaux des représentants	
			@RepLevelID = 0 retourne tous les niveaux des représentants
Valeurs de retours  :	Dataset de données
				RepLevelID		INTEGER(4)	ID unique du niveau.
				LevelDesc		VARCAHR(75)	[Description du niveau.]
				LevelShortDesc		VARCHAR(75)	[Description abrégée du niveau.]
				TargetUnit		INTEGER(4)	[Nombre de nouvelles ventes d'unités minimum pour être éligible à ce niveau.]
				ConservationRate	DECIMAL(10,4)	[Pourcentage de conservation minimum pour être éligible à ce niveau.]
Note                :	ADX0000993		IA		2006-05-19	Mireya Gonthier			Création				
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepLevel] ( 
	@RepLevelID MoID,
	@RepRoleID MoOptionCode) 
AS 
BEGIN   
	-- @RepLevelID <> 0 on retourne les informations pour le RepLevelID spécifié. 
	IF @RepLevelID <> 0
	BEGIN
		SELECT      
			L.RepLevelID,     
			L.RepRoleID,     
			L.LevelDesc,     
			L.TargetUnit,     
			L.ConservationRate,     
			R.RepRoleDesc,     
			L.LevelShortDesc   
		FROM Un_RepLevel L   
		JOIN Un_RepRole R ON R.RepRoleID = L.RepRoleID 
		WHERE @RepLevelID = RepLevelID
		ORDER BY L.LevelDesc
	END
	ELSE	
	-- @RepRoleID = '', on retourne tous les niveaux des représentants pour tous les roles des représentants
	IF @RepRoleID = ''
	BEGIN
		SELECT      
			L.RepLevelID,     
			L.RepRoleID,     
			L.LevelDesc,     
			L.TargetUnit,     
			L.ConservationRate,     
			R.RepRoleDesc,     
			L.LevelShortDesc   
		FROM Un_RepLevel L   
		JOIN Un_RepRole R ON R.RepRoleID = L.RepRoleID 
		ORDER BY L.LevelDesc
	END
	ELSE
	BEGIN
	--On retourne tous les niveaux des représentants correspondant à un role donné. 
		SELECT      
			L.RepLevelID,     
			L.RepRoleID,     
			L.LevelDesc,     
			L.TargetUnit,     
			L.ConservationRate,     
			R.RepRoleDesc,     
			L.LevelShortDesc   
		FROM Un_RepLevel L   
		JOIN Un_RepRole R ON R.RepRoleID = L.RepRoleID 
		WHERE @RepRoleID = L.RepRoleID
		ORDER BY L.LevelDesc
	END
END



