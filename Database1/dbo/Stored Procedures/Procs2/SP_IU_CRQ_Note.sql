

/****************************************************************************************************
Code de service		:		SP_IU_CRQ_Note
Nom du service		:		SP_IU_CRQ_Note
But					:		Insertion/modification d'une note.
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@ConnectID					-- Id unique de la connection de l'usager
						@NoteID						-- ID Unqiue de la note
						@NoteTypeID					-- ID Unique du type note
						@NoteCodeID					-- ID Unique de l'objet qui a la note
						@NoteText					-- La note
						

Exemple d'appel:
					
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													@ResultID (@NoteID)

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2004-06-01					Bruno Lapointe							Création
		2009-09-24					Jean-François Gauthier					Remplacement du @@Identity par Scope_Identity()
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[SP_IU_CRQ_Note] (
	@ConnectID INTEGER, -- Id unique de la connection de l'usager
	@NoteID INTEGER, -- ID Unqiue de la note
   @NoteTypeID INTEGER, -- ID Unique du type note
   @NoteCodeID INTEGER, -- ID Unique de l'objet qui a la note
	@NoteText TEXT) -- La note
AS
BEGIN
	DECLARE
		@ResultID INTEGER

	SET @ResultID = 0
	
	IF @NoteID = 0
	BEGIN
		INSERT INTO Mo_Note (
			NoteTypeID,
			NoteCodeID,
			ConnectID,
			NoteText)
		VALUES (
			@NoteTypeID,
			@NoteCodeID,
			@ConnectID,
			@NoteText)

		IF @@ERROR = 0
		BEGIN
			SELECT @ResultID = SCOPE_IDENTITY()
			EXEC IMo_Log @ConnectID, 'Mo_Note', @ResultID, 'I', ''
		END
	END
	ELSE
	BEGIN
		UPDATE Mo_Note SET
			NoteTypeID = @NoteTypeID,
			NoteCodeID = @NoteCodeID,
			ConnectID = @ConnectID,
			NoteText = @NoteText
		WHERE (NoteID = @NoteID)

		IF @@ERROR = 0
		BEGIN
			SET @ResultID = @NoteID
			EXEC IMo_Log @ConnectID, 'Mo_Note', @NoteID, 'U', ''
		END
	END

	RETURN @ResultID
END;
