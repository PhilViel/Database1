/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	SP_IU_CRQ_Blob
Description         :	Sauvegarde de fichier texte (BLOB) temporaire.
Valeurs de retours  :	@ReturnValue :
									>0 :	La sauvegarde a réussie.  La valeur de retour correspond au BlobID du
											fichier texte sauvegardé.
									<=0 :	La sauvegarde a échouée.
Note                :						2004-07-02	Bruno Lapointe		Création
								ADX0001602	BR	2005-10-11	Bruno Lapointe		SCOPE_IDENTITY au lieu de IDENT_CURRENT
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_CRQ_Blob] (
	@BlobID INTEGER, -- Identifiant unique du blob
	@Blob TEXT) -- Blob temporaire
AS
BEGIN
	IF @BlobID = 0
	-- Le dossier n'est pas existant; il sera donc créé
	BEGIN
		INSERT CRQ_Blob (
			Blob)
		VALUES ( 
			@Blob)
	
		-- Gestion d'erreur
		IF @@ERROR = 0
			SET @BlobID = SCOPE_IDENTITY()
	END
	ELSE -- Le dossier est existant et sera modifié
	BEGIN
		UPDATE CRQ_Blob
		SET 
			Blob = @Blob
		WHERE BlobID = @BlobID 

		-- Gestion d'erreur
		IF @@ERROR <> 0
			SET @BlobID = 0
	END

	RETURN @BlobID 

	-- VALEUR DE RETOUR
	-------------------
	-- >0 : ID = id du template et tout a fonctionné
	-- 0 : Erreur SQL
END

