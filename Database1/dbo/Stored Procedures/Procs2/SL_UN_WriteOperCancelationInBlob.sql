/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_WriteOperCancelationInBlob
Description         :	Retourne l'objet Un_OperCancelation correspondant au OperID dans le blob du pointeur @pBlob 
								ou le champs texte @vcBlob.
Valeurs de retours  :	Type d’objet traité être dans le blob :
									Un_OperCancelation
										OperSourceID 			INTEGER
										OperID 					INTEGER
								@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0000847	IA	2006-03-28	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_WriteOperCancelationInBlob] (
	@OperID INTEGER, -- ID de l’opération de chèque
	@iBlobID INTEGER, -- ID du blob dans lequel on écrit
	@pBlob BINARY(16), -- Pointeur sur le blob
	@vcBlob VARCHAR(8000) OUTPUT, -- Contient le texte des objets à insérer dans le blob
	@iResult INTEGER OUTPUT ) -- Varible résultat
AS
BEGIN
	-- Un_OperCancelation;OperSourceID;OperID;

	-- Inscrit le détail des objets d'opérations (Un_OperCancelation)
	DECLARE
		-- Variable de l'objet de lien d'annulation
		@OperSourceID INTEGER

	-- Traite les liens d'annulation
	IF EXISTS (
			SELECT OperID
			FROM Un_OperCancelation
			WHERE OperID = @OperID) AND
		(@iResult > 0)
	BEGIN
		-- Inscrit les liens d'annulation de l'opération dans le blob
		-- Un_OperCancelation;OperSourceID;OperID;
		SELECT 
			@OperSourceID = OperSourceID
		FROM Un_OperCancelation
		WHERE OperID = @OperID

		-- Si Il n'y pas assez d'espace disponible dans la variable, on inscrit le contenu de la variable dans le blob et on vide la variable par la suite
		IF LEN(@vcBlob) > 7900
		BEGIN
			DECLARE
				@iBlobLength INTEGER

			SELECT @iBlobLength = DATALENGTH(txBlob)
			FROM CRI_Blob
			WHERE iBlobID = @iBlobID

			UPDATETEXT CRI_Blob.txBlob @pBlob @iBlobLength 0 @vcBlob 

			IF @@ERROR <> 0
				SET @iResult = -11

			SET @vcBlob = ''
		END

		SET @vcBlob = 
			@vcBlob +
			'Un_OperCancelation;'+
			CAST(@OperSourceID AS VARCHAR)+';'+
			CAST(@OperID AS VARCHAR)+';'+CHAR(13)+CHAR(10)
	END

	RETURN @iResult
END

