/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	IU_CRI_Blob
Description 		:	Procedure d'insertion d'un blob temporaire
Valeurs de retour	:	<= 0 : Code de message d'erreur
								-10000 = Erreur SQL en creation
								-10001 = Erreur SQL en modification
							>0 : Traitement correct, ID du blob sauvegardé
Note					:	ADX0000714	IA	2005-09-16	Bruno Lapointe		Création
*************************************************************************************************/
CREATE PROCEDURE dbo.IU_CRI_Blob (
	@iBlobID INTEGER, -- Identifiant unique du blob
	@txBlob TEXT) -- Blob temporaire
AS
BEGIN
	IF @iBlobID = 0 -- Le dossier n'est pas existant; il sera donc créé
	BEGIN
		INSERT CRI_Blob (
			txBlob)
		VALUES (
			@txBlob)
		-- Gestion d'erreur
		IF @@ERROR = 0
			SET @iBlobID = SCOPE_IDENTITY( )	
		ELSE
			SET @iBlobID = -10000		
	END 
	ELSE 
	BEGIN -- Le blob est existant et sera modifié
		UPDATE CRI_Blob
		SET txBlob = @txBlob
		WHERE iBlobID = @iBlobID

		-- Gestion d'erreur
		IF @@ERROR <> 0 
			SET @iBlobID = -10001
	END
	RETURN @iBlobID 
END
