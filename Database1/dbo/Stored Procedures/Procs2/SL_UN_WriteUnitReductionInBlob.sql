/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_WriteUnitReductionInBlob
Description         :	Retourne l'objet Un_UnitReduction correspondant au OperID dans le blob du pointeur @pBlob 
								ou le champs texte @vcBlob.
Valeurs de retours  :	Type d’objet traité être dans le blob :
									Un_UnitReduction
										UnitReductionID			INTEGER
										UnitID						INTEGER
										ReductionConnectID		INTEGER
										ReductionDate				DATETIME
										UnitQty						MONEY
										FeeSumByUnit				MONEY
										SubscInsurSumByUnit		MONEY
										UnitReductionReasonID	INTEGER
										UnitReductionReason		VARCHAR (75)
										NoChequeReasonID			INTEGER
										NoChequeReason				VARCHAR (75)
								@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0000861	IA	2006-03-30	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_WriteUnitReductionInBlob] (
	@OperID INTEGER, -- ID de l’opération de la réduction d'unités
	@iBlobID INTEGER, -- ID du blob dans lequel on écrit
	@pBlob BINARY(16), -- Pointeur sur le blob
	@vcBlob VARCHAR(8000) OUTPUT, -- Contient le texte des objets à insérer dans le blob
	@iResult INTEGER OUTPUT ) -- Varible résultat
AS
BEGIN
	-- Un_UnitReduction;UnitReductionID;UnitID;ReductionConnectID;ReductionDate;UnitQty;FeeSumByUnit;SubscInsurSumByUnit;UnitReductionReasonID;UnitReductionReason;NoChequeReasonID;NoChequeReason;
	IF EXISTS (
			SELECT UR.UnitReductionID
			FROM Un_UnitReduction UR
			JOIN Un_UnitReductionCotisation URC ON URC.UnitReductionID = UR.UnitReductionID
			JOIN Un_Cotisation Ct ON Ct.CotisationID = URC.CotisationID
			WHERE Ct.OperID = @OperID ) AND
		(@iResult > 0)
	BEGIN
		-- Si Il n'y pas assez d'espace disponible dans la variable, on inscrit le contenu de la variable dans le blob et on vide la variable par la suite
		IF LEN(@vcBlob) > 7000
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

		-- Inscrit la réduction d'unités dans le blob
		-- Un_UnitReduction;UnitReductionID;UnitID;ReductionConnectID;ReductionDate;UnitQty;FeeSumByUnit;SubscInsurSumByUnit;UnitReductionReasonID;UnitReductionReason;NoChequeReasonID;NoChequeReason;
		SELECT DISTINCT
			@vcBlob = 
				@vcBlob +
				'Un_UnitReduction;'+
				CAST(UR.UnitReductionID AS VARCHAR)+';'+
				CAST(UR.UnitID AS VARCHAR)+';'+
				CAST(UR.ReductionConnectID AS VARCHAR)+';'+
				CONVERT(CHAR(10), UR.ReductionDate, 20)+';'+
				CAST(CAST(UR.UnitQty AS FLOAT) AS VARCHAR)+';'+
				CAST(UR.FeeSumByUnit AS VARCHAR)+';'+
				CAST(UR.SubscInsurSumByUnit AS VARCHAR)+';'+
				CAST(ISNULL(UR.UnitReductionReasonID,0) AS VARCHAR)+';'+
				ISNULL(URR.UnitReductionReason,'')+';'+
				CAST(ISNULL(UR.NoChequeReasonID,0) AS VARCHAR)+';'+
				ISNULL(UCR.NoChequeReason,'')+';'+CHAR(13)+CHAR(10)
		FROM Un_UnitReduction UR
		JOIN Un_UnitReductionCotisation URC ON URC.UnitReductionID = UR.UnitReductionID
		JOIN Un_Cotisation Ct ON Ct.CotisationID = URC.CotisationID
		LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
		LEFT JOIN Un_NoChequeReason UCR ON UCR.NoChequeReasonID = UR.NoChequeReasonID
		WHERE Ct.OperID = @OperID
	END

	RETURN @iResult
END

