
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_WriteWithdrawalReasonInBlob
Description         :	Retourne l'objet Un_WithdrawalReason correspondant au OperID dans le blob du pointeur @pBlob 
						ou le champs texte @vcBlob.

Valeurs de retours  :	Type d’objet traité être dans le blob :
									Un_WithdrawalReason
										OperID 						INTEGER
										WithdrawalReasonID			INTEGER
										tiCESP400WithdrawReasonID	INTEGER
										vcCESP400WithdrawReason		VARCHAR(200)
								@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.

Note                :	ADX0000862	IA	2006-03-31	Bruno Lapointe		Création
						ADX0001123	IA	2006-10-06	Alain Quirion		Modification : Ajout de	tiCESP400WithdrawReasonID
						ADX0001290	IA	2007-06-11	Alain Quirion		Ajout de vcCESP400WithdrawReason
*********************************************************************************************************************/
CREATE PROCEDURE dbo.SL_UN_WriteWithdrawalReasonInBlob (
	@OperID INTEGER, -- ID de l’opération
	@iBlobID INTEGER, -- ID du blob dans lequel on écrit
	@pBlob BINARY(16), -- Pointeur sur le blob
	@vcBlob VARCHAR(8000) OUTPUT, -- Contient le texte des objets à insérer dans le blob
	@iResult INTEGER OUTPUT ) -- Varible résultat
AS
BEGIN
	-- Un_WithdrawalReason;OperID;WithdrawalReasonID;tiCESP400WithdrawReasonID;vcCESP400WithdrawReason

	-- Traite les liens d'annulation
	IF EXISTS (
			SELECT OperID
			FROM Un_WithdrawalReason
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

		-- Inscrit les liens d'annulation de l'opération dans le blob
		-- Un_WithdrawalReason;OperID;WithdrawalReasonID;
		SELECT 
			@vcBlob = 
				@vcBlob +
				'Un_WithdrawalReason;'+
				CAST(@OperID AS VARCHAR)+';'+
				CAST(W.WithdrawalReasonID AS VARCHAR)+';'+				
				CAST(W.tiCESP400WithdrawReasonID AS VARCHAR)+';'+
				C4W.vcCESP400WithdrawReason+';'+
				CHAR(13)+CHAR(10)
		FROM Un_WithdrawalReason W
		JOIN Un_CESP400WithdrawReason C4W ON C4W.tiCESP400WithDrawReasonID = W.tiCESP400WithDrawReasonID
		WHERE OperID = @OperID
	END

	RETURN @iResult
END

