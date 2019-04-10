/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	DL_UN_RepRole
Description         :	Procédure de suppression d’un niveau des rôles des représentants. 
Valeurs de retours  :	@ReturnValue :
									> 0 : [Réussite]
									<= 0 : [Échec]
										-1	: « Un ou plusieurs niveaux faisant parti de ce rôle sont utilisés dans les commissions! »
										-2 : « Un ou plusieurs niveaux faisant parti de ce rôle sont utilisés dans des historiques de niveaux des représentants! »
Note                :	ADX0000995	IA 	2006-05-19	Mireya Gonthier			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_RepRole] (
	@ConnectID MoID,
	@RepRoleID MoOptionCode)
AS
BEGIN
	DECLARE
		@iResult MoIDOption

	SET @iResult = 1
	
	IF EXISTS (
		SELECT L.RepRoleID
		FROM Un_RepLevel L
		JOIN Un_RepBusinessBonus B ON B.RepLevelID = L.RepLevelID
		WHERE L.RepRoleID = @RepRoleID
		-----
		UNION
		-----
		SELECT RepRoleID
		FROM Un_RepBusinessBonusCfg
		WHERE RepRoleID = @RepRoleID
		-----
		UNION
		-----
		SELECT L.RepRoleID
		FROM Un_RepLevel L
		JOIN Un_RepCommission C ON C.RepLevelID = L.RepLevelID
		WHERE L.RepRoleID = @RepRoleID
		-----
		UNION
		-----
		SELECT RepRoleID
		FROM Un_RepConservBonusCfg
		WHERE RepRoleID = @RepRoleID
		-----
		UNION
		-----
		SELECT RepRoleID
		FROM Un_RepConservRateCfg
		WHERE RepRoleID = @RepRoleID
		-----
		UNION
		-----
		SELECT L.RepRoleID
		FROM Un_RepLevel L
		JOIN Un_RepException E ON E.RepLevelID = L.RepLevelID
		WHERE L.RepRoleID = @RepRoleID
		)
		SET @iResult = -1

	IF EXISTS (
		SELECT RepRoleID
		FROM Un_RepBossHist
		WHERE RepRoleID = @RepRoleID
		-----
		UNION
		-----
		SELECT L.RepRoleID
		FROM Un_RepLevel L
		JOIN Un_RepLevelHist H ON H.RepLevelID = L.RepLevelID
		WHERE L.RepRoleID = @RepRoleID
		)
		SET @iResult = -2

	-----------------
	BEGIN TRANSACTION
	-----------------

	IF @iResult = 1
	BEGIN
		DELETE Un_RepLevelBracket
		FROM Un_RepLevelBracket B
		JOIN Un_RepLevel L ON L.RepLevelID = B.RepLevelID
		WHERE L.RepRoleID = @RepRoleID

		IF @@ERROR <> 0
			SET @iResult = -10
	END

	IF @iResult = 1
	BEGIN
		DELETE
		FROM Un_RepLevel
		WHERE RepRoleID = @RepRoleID

		IF @@ERROR <> 0
			SET @iResult = -11
	END

	IF @iResult = 1
	BEGIN
		DELETE
		FROM Un_RepRole
		WHERE RepRoleID = @RepRoleID

		IF @@ERROR <> 0
			SET @iResult = -12
	END

	IF @iResult = 1
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @iResult
END

