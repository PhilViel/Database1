
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	DL_UN_State
Description 		:	Suppression d'une province
Valeurs de retour	:	@ReturnValue :
							> 0 : [Réussite]
							<= 0 : [Échec].

Notes :		ADX0001280	IA	2007-03-19	Alain Quirion		Création
*********************************************************************************/
CREATE PROCEDURE dbo.DL_UN_State(
	@StateID INTEGER)		--	Identifiant de la province (<0 = Insertion)
AS
BEGIN
	DECLARE @iReturn INTEGER
	
	SET @iReturn = 1

	DELETE
	FROM Mo_State
	WHERE StateID = @StateID

	IF @@ERROR <> 0
		SET @iReturn = -1

	RETURN @iReturn
END

