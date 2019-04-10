
CREATE PROCEDURE [dbo].[psGENE_EnregistreNoteHTML]
	(
	@iID_Note	INT,
	@tTexte		TEXT
	)
AS
	BEGIN
		SET NOCOUNT ON

		DECLARE @iStatut INT

		BEGIN TRY
			UPDATE 
				dbo.tblGENE_Note
			SET 
				tTexte = @tTexte,
				dtDateModification = GETDATE()
			WHERE 
				iID_Note = @iID_Note

			SET @iStatut = 1
		END TRY
		BEGIN CATCH
			SET @iStatut = -1
		END CATCH

		RETURN @iStatut
	END
