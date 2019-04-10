/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_Region
Description         :	Procédure de sauvegarde d’ajout et modification de région.
Valeurs de retours  :	@ReturnValue :
									> 0 : La sauvegarde a réussie.  La valeur de retour correspond à l’iRegionID de la région sauvegardée.
									<= 0 : La sauvegarde a échouée.
Note                :	ADX0000730	IA	2005-07-06	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_Region] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@iRegionID INTEGER, -- ID de la région à sauvegarder, 0 pour ajouter.
	@vcRegion VARCHAR(75) ) -- Région (Nom).
AS
BEGIN
	IF @iRegionID = 0
	BEGIN
		INSERT INTO Un_Region (
			vcRegion )
		VALUES (
			@vcRegion )

		IF @@ERROR = 0
		BEGIN
			SET @iRegionID = SCOPE_IDENTITY()
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_Region', @iRegionID, 'I', ''
		END
		ELSE
			SET @iRegionID = -1
	END
	ELSE
	BEGIN
		UPDATE Un_Region
		SET
			vcRegion = @vcRegion
		WHERE iRegionID = @iRegionID

		IF @@ERROR = 0
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_Region', @iRegionID, 'U', ''
		ELSE
			SET @iRegionID = -2
	END

	RETURN @iRegionID
END

