/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_Program
Description         :	Procédure de sauvegarde d’ajout ou modification de programme.
Valeurs de retours  :	@ReturnValue :
									> 0 :	La sauvegarde a réussie.  La valeur de retour correspond au ProgramID du programme 
											sauvegardé.
									<= 0:	La sauvegarde a échouée.
Note                :	ADX0000730	IA	2005-06-22	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_Program] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@ProgramID INTEGER, -- Identifiant unique du programme
	@ProgramDesc VARCHAR(75) ) -- Nom du programme.
AS
BEGIN
	IF @ProgramID = 0
	BEGIN
		INSERT INTO Un_Program (
			ProgramDesc )
		VALUES (
			@ProgramDesc )

		IF @@ERROR = 0
		BEGIN
			SET @ProgramID = SCOPE_IDENTITY()
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_Program', @ProgramID, 'I', ''
		END
		ELSE
			SET @ProgramID = -1
	END
	ELSE
	BEGIN
		UPDATE Un_Program
		SET
			ProgramDesc = @ProgramDesc
		WHERE ProgramID = @ProgramID

		IF @@ERROR = 0
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_Program', @ProgramID, 'U', ''
		ELSE
			SET @ProgramID = -1
	END

	RETURN @ProgramID
END

