/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom			: IU_UN_RepBossHistory
Description		: Procédure d’insertion et de mise à jour d’un type d’ajustement ou de retenu
Valeurs de retours	: 
			@ReturnValue :
					> 0 : [Réussite]
					<= 0 : [Échec].	

Note			: ADX0000990	IA	2006-05-19	Alain Quirion			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_RepChargeType] (
@RepChargeTypeID CHAR(3),
@RepChargeTypeDesc VARCHAR(75),
@RepChargeTypeComm BIT) 
AS
BEGIN
	DECLARE @iReturn INTEGER
	SET @iReturn = 1

	IF NOT EXISTS (SELECT RepChargeTypeID
			FROM Un_RepChargeType
			WHERE RepChargeTypeID = @RepChargeTypeID)
	BEGIN
		INSERT INTO Un_RepChargeType (
			RepChargeTypeID,
			RepChargeTypeDesc,
			RepChargeTypeVisible,
			RepChargeTypeComm)
		VALUES (
			@RepChargeTypeID,
			@RepChargeTypeDesc,
			1,			-- Les insertions et mises à jour sont toujours visbiles lorqu'ajouté par l'usager
			@RepChargeTypeComm)

		IF (@@ERROR <> 0)
			SET @iReturn = -1
	END
	ELSE
	BEGIN
		UPDATE Un_RepChargeType 
		SET
			RepChargeTypeDesc = @RepChargeTypeDesc,
			RepChargeTypeComm = @RepChargeTypeComm
		WHERE RepChargeTypeID = @RepChargeTypeID

		IF (@@ERROR <> 0)
			SET @iReturn = -1		
	END

	RETURN @iReturn 
END


