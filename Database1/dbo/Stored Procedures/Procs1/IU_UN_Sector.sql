/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_Sector
Description         :	Procédure de sauvegarde d’ajout et modification de secteur.
Valeurs de retours  :	@ReturnValue :
									> 0 : La sauvegarde a réussie.  La valeur de retour correspond à l’iSectorID du secteur sauvegardé.
									<= 0 : La sauvegarde a échouée.
Note                :	ADX0000730	IA	2005-07-06	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_Sector] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@iSectorID INTEGER, -- ID du secteur à sauvegarder, 0 pour ajouter.
	@vcSector VARCHAR(75) ) -- Secteur (Nom).
AS
BEGIN
	IF @iSectorID = 0
	BEGIN
		INSERT INTO Un_Sector (
			vcSector )
		VALUES (
			@vcSector )

		IF @@ERROR = 0
		BEGIN
			SET @iSectorID = SCOPE_IDENTITY()
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_Sector', @iSectorID, 'I', ''
		END
		ELSE
			SET @iSectorID = -1
	END
	ELSE
	BEGIN
		UPDATE Un_Sector
		SET
			vcSector = @vcSector
		WHERE iSectorID = @iSectorID

		IF @@ERROR = 0
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_Sector', @iSectorID, 'U', ''
		ELSE
			SET @iSectorID = -2
	END

	RETURN @iSectorID
END

