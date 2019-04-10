/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_Sector
Description         :	Procédure de suppression de secteur.
Valeurs de retours  :	@ReturnValue :
									>0 :	La suppression a réussie.  La valeur de retour correspond à l’iSectorID du secteur
											supprimé.
									<=0 :	La suppression a échouée.
										-1 :	« Vous ne pouvez supprimer ce secteur car il est utilisé par une ou des
												établissements d’enseignement! ».  
Note                :	ADX0000730	IA	2005-07-06	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_Sector] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@iSectorID INTEGER ) -- ID du secteur à supprimer.
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = @iSectorID

	IF EXISTS (
		SELECT CollegeID
		FROM Un_College
		WHERE iSectorID = @iSectorID
		)
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		DELETE
		FROM Un_Sector
		WHERE iSectorID = @iSectorID

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	RETURN @iResult
END

