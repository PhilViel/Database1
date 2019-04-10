/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_SpecialAdvance
Description         :	Procédure de suppression de secteur.
Valeurs de retours  :	@ReturnValue :
									>0 :	La suppression a réussie.  La valeur de retour correspond à l’iSectorID du secteur
											supprimé.
									<=0 :	La suppression a échouée.
										-1 :	« Vous ne pouvez supprimer ce secteur car il est utilisé par une ou des
												établissements d’enseignement! ».  
Note                :	ADX0000735	IA	2005-07-19	Pierre-Michel Bussière		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_SpecialAdvance] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@SpecialAdvanceID INTEGER ) -- ID du secteur à supprimer.
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = @SpecialAdvanceID

	IF @iResult > 0
	BEGIN
		DELETE
		FROM Un_SpecialAdvance
		WHERE SpecialAdvanceID = @SpecialAdvanceID

		IF @@ERROR <> 0
			SET @iResult = -1
	END

	RETURN @iResult
END

