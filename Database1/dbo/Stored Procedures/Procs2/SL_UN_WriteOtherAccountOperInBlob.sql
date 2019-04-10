/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_WriteOtherAccountOperInBlob
Description         :	Retourne les objets Un_OtherAccountOper correspondant au OperID dans le blob du pointeur(@pBlob) 
								ou le champs texte(@vcBlob).
Valeurs de retours  :	Type d’objet traité être dans le blob :
									Un_OtherAccountOper
										OtherAccountOperID		INTEGER
										OperID						INTEGER
										OtherAccountOperAmount	MONEY
								@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0000861	IA	2006-03-30	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_WriteOtherAccountOperInBlob] (
	@OperID INTEGER, -- ID de l’opération
	@iBlobID INTEGER, -- ID du blob dans lequel on écrit
	@pBlob BINARY(16), -- Pointeur sur le blob
	@vcBlob VARCHAR(8000) OUTPUT, -- Contient le texte des objets à insérer dans le blob
	@iResult INTEGER OUTPUT ) -- Variable résultat
AS
BEGIN
	-- Boucle : Un_OtherAccountOper;OtherAccountOperID;OperID;OtherAccountOperAmount;

	DECLARE
		-- Variables de l'objet d'opération sur autre compte
		@OtherAccountOperID INTEGER,
		@OtherAccountOperAmount MONEY

	-- Curseur de détail des objets d'opérations sur autre compte (Un_OtherAccountOper)
	DECLARE crWrite_Un_OtherAccountOper CURSOR FOR
		SELECT 
			O.OtherAccountOperID,
			O.OtherAccountOperAmount
		FROM Un_OtherAccountOper O
		WHERE O.OperID = @OperID
	
	-- Ouvre le curseur
	OPEN crWrite_Un_OtherAccountOper

	-- Va chercher la première opération sur autre compte
	FETCH NEXT FROM crWrite_Un_OtherAccountOper
	INTO
		@OtherAccountOperID,
		@OtherAccountOperAmount

	WHILE (@@FETCH_STATUS = 0)
	  AND (@iResult > 0)
	BEGIN
		-- S'il n'y pas assez d'espace disponible dans la variable, on inscrit le contenu de la variable dans le blob et on vide la variable par la suite
		IF LEN(@vcBlob) > 7800
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

		-- Inscrit l'opération sur autre compte dans le blob
		-- Un_OtherAccountOper;OtherAccountOperID;OperID;OtherAccountOperAmount;
		SET @vcBlob =
			@vcBlob+
			'Un_OtherAccountOper;'+
			CAST(@OtherAccountOperID AS VARCHAR)+';'+
			CAST(@OperID AS VARCHAR)+';'+
			CAST(@OtherAccountOperAmount AS VARCHAR)+';'+
			CHAR(13)+CHAR(10)

		-- Passe à la prochaine opération sur autre compte
		FETCH NEXT FROM crWrite_Un_OtherAccountOper
		INTO
			@OtherAccountOperID,
			@OtherAccountOperAmount
	END -- WHILE (@@FETCH_STATUS = 0) de crWrite_Un_OtherAccountOper
	
	-- Détruit le curseur d'opérations sur conventions
	CLOSE crWrite_Un_OtherAccountOper
	DEALLOCATE crWrite_Un_OtherAccountOper

	RETURN @iResult
END

