/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_WriteChequeInBlob
Description         :	Retourne l'objet Un_OperLinkToCHQOperation correspondant au OperID dans le blob du pointeur @pBlob 
								ou le champs texte @vcBlob.
Valeurs de retours  :	Type d’objet traité être dans le blob :
									Mo_Cheque
										OperID			INTEGER
										iOperationID	INTEGER
								@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0000861	IA	2006-04-03	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_WriteChequeInBlob] (
	@OperID INTEGER, -- ID de l’opération
	@iBlobID INTEGER, -- ID du blob dans lequel on écrit
	@pBlob BINARY(16), -- Pointeur sur le blob
	@vcBlob VARCHAR(8000) OUTPUT, -- Contient le texte des objets à insérer dans le blob
	@iResult INTEGER OUTPUT ) -- Varible résultat
AS
BEGIN
	-- Mo_Cheque;OperID;iOperationID;
	IF EXISTS (
			SELECT OperID
			FROM Un_OperLinkToCHQOperation
			WHERE OperID = @OperID) AND
		(@iResult > 0)
	BEGIN
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

		-- Inscrit le chèque de l'opération dans le blob
		-- Mo_Cheque;OperID;iOperationID;
		SELECT 
			@vcBlob = 
				@vcBlob +
				'Mo_Cheque;'+
				CAST(@OperID AS VARCHAR)+';'+
				CAST(iOperationID AS VARCHAR)+';'+CHAR(13)+CHAR(10)
		FROM Un_OperLinkToCHQOperation
		WHERE OperID = @OperID
	END

	RETURN @iResult
END

