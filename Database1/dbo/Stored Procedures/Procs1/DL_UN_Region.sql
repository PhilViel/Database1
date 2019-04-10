/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_Region
Description         :	Procédure de suppression de région.
Valeurs de retours  :	@ReturnValue :
									>0 :	La suppression a réussie.  La valeur de retour correspond à l’iRegionID de la région
											supprimée.
									<=0 :	La suppression a échouée.
										-1 :	« Vous ne pouvez supprimer cette région car elle est utilisée dans des
												établissements d’enseignements! ».
 Note                :	ADX0000730	IA	2005-07-06	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_Region] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@iRegionID INTEGER ) -- ID de la région à supprimer.
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = @iRegionID

	IF EXISTS (
		SELECT CollegeID
		FROM Un_College
		WHERE iRegionID = @iRegionID
		)
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		DELETE
		FROM Un_Region
		WHERE iRegionID = @iRegionID

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	RETURN @iResult
END

