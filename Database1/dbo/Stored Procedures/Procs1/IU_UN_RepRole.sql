/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	IU_UN_RepRole
Description         :	Procédure d’insertion et de mise à jour des rôles de représentants. 
			Mise à jour d'un role si la  valeur @RepRoleID passée en paramètre existe déjà dans la table, 
			Ajout d'un role si la valeur @RepRoleID passée en paramètre n'existe pas dans la table. 	
Valeurs de retours  :	@ReturnValue :
				> 0 : [Réussite]
				<= 0 : [Échec].

Note                :	ADX0000995	IA 	2006-05-19	Mireya Gonthier			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_RepRole] (
	@ConnectID MoID,
	@RepRoleID MoOptionCode,
	@RepRoleDesc MoDesc) 
AS
BEGIN
	DECLARE 
		@Result MoID

	-----------------------
	BEGIN TRANSACTION
	-----------------------

	IF NOT EXISTS( 
		SELECT 
                	RepRoleID
		FROM Un_RepRole
		WHERE RepRoleID = @RepRoleID)

  	BEGIN
		INSERT INTO Un_RepRole(
			RepRoleID,
			RepRoleDesc)
		VALUES (
			@RepRoleID,
			@RepRoleDesc)

		IF @@ERROR = 0
		BEGIN
			SET @Result = 1
			EXEC IMo_Log @ConnectID, 'Un_RepRole', 0, 'I', @RepRoleID
		END
		ELSE
			SET @Result = -1
	END
	ELSE
	BEGIN
		UPDATE Un_RepRole 
			SET RepRoleDesc = @RepRoleDesc
		WHERE RepRoleID = @RepRoleID
	
		IF @@ERROR = 0
		BEGIN
			SET @Result = 1
			EXEC IMo_Log @ConnectID, 'Un_RepRole', 0, 'U', @RepRoleID
		END
		ELSE
      			SET @Result = -1
  	END
	IF @Result = -1
		--------------------------
		ROLLBACK TRANSACTION
		--------------------------
 	 ELSE
		--------------------------
    		COMMIT TRANSACTION
		--------------------------
	RETURN @Result 
END


