/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_WriteAvailableFeeUseInBlob
Description         :	Retourne l'objet Un_AvailableFeeUse correspondant au OperID dans le blob du pointeur @pBlob ou les champs texte @vcBlob
Valeurs de retours  :	Type d’objet traité être dans le blob :
									Un_AvailableFeeUse
									iAvailableFeeUseID
									ConventionOperID
									UnitReductionID
									OperID
									fUnitQtyUse
									dtInforecDate
									fUnitQty
						@ReturnValue :
							> 0 : Réussite
							<= 0 : Erreurs.
Note                :	ADX0001119	IA	2006-11-01	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_WriteAvailableFeeUseInBlob] (
	@OperID INTEGER, -- ID de l’opération TFR
	@iBlobID INTEGER, -- ID du blob dans lequel on écrit
	@pBlob BINARY(16), -- Pointeur sur le blob
	@vcBlob VARCHAR(8000) OUTPUT, -- Contient le texte des objets à insérer dans le blob
	@iResult INTEGER OUTPUT ) -- Varible résultat
AS
BEGIN
	-- BOUCLE : Un_AvaibleFeeUse;iAvailableFeeUseID;UnitReductionID;ConventionOperID;OperID;fUnitQtyUse;fAvailableUnit;fFeeSumByUnit;dtInforceDate;fUnitQty

	-- Traite les frais disponibles utilisés
	IF EXISTS (
			SELECT OperID
			FROM Un_AvailableFeeUse
			WHERE OperID = @OperID) AND
		(@iResult > 0)
	BEGIN
		DECLARE
			@iAvailableFeeUseID INTEGER,
			@UnitReductionID INTEGER,
			@ConventionOperID INTEGER,
			@iOperID INTEGER,
			@fUnitQtyUse MONEY,			
			@fAvailableUnit MONEY,
			@fFeeSumByUnit MONEY,
			@dtInforceDate DATETIME,
			@fUnitQty MONEY

		DECLARE CUR_AvailableFeeUse CURSOR FOR
		SELECT 
			A.iAvailableFeeUseID,
			A.UnitReductionID,
			CO.ConventionOperID,
			A.OperID,
			A.fUnitQtyUse,			
			fAvailableUnit = UR.UnitQty - ISNULL(V.SumUnitQtyUse,0) + A.fUnitQtyUse,
			UR.FeeSumByUnit,
			U.InforceDate,
			U.UnitQty
		FROM Un_AvailableFeeUse A
		JOIN Un_UnitReduction UR ON A.UnitReductionID = UR.UnitReductionID	
		LEFT JOIN (
				SELECT 
					SumUnitQtyUse = SUM(fUnitQtyUse),
					A.UnitReductionID
				FROM Un_AvailableFeeUse A
				JOIN Un_UnitReduction UR ON A.UnitReductionID = UR.UnitReductionID
				GROUP BY A.UnitReductionID) V ON V.UnitReductionID = UR.UnitReductionID
		JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID	 
		JOIN Un_ConventionOper CO ON CO.OperID = A.OperID AND CO.ConventionID = U.ConventionID
		WHERE A.OperID = @OperID

		OPEN CUR_AvailableFeeUse
		
		FETCH NEXT FROM CUR_AvailableFeeUse
		INTO 
			@iAvailableFeeUseID,
			@UnitReductionID,
			@ConventionOperID,
			@iOperID,
			@fUnitQtyUse,			
			@fAvailableUnit,
			@fFeeSumByUnit,
			@dtInforceDate,
			@fUnitQty

		WHILE @@FETCH_STATUS = 0
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
	
			-- Inscrit les données du TFR de l'opération dans le blob
			SELECT 
				@vcBlob = 
					@vcBlob +
					'Un_AvailableFeeUse;'+
					CAST(@iAvailableFeeUseID AS VARCHAR)+';'+
					CAST(@UnitReductionID AS VARCHAR)+';'+
					CAST(@ConventionOperID AS VARCHAR)+';'+
					CAST(@iOperID AS VARCHAR)+';'+
					CAST(CAST(@fUnitQtyUse AS FLOAT) AS VARCHAR)+';'+					
					CAST(CAST(@fAvailableUnit AS FLOAT) AS VARCHAR)+';'+
					CAST(CAST(@fFeeSumByUnit AS FLOAT) AS VARCHAR)+';'+	
					LTRIM(ISNULL(CONVERT(CHAR(10), dbo.FN_CRQ_IsDateNull(@dtInforceDate), 20),''))+';'+
					CAST(CAST(@fUnitQty AS FLOAT) AS VARCHAR)+';'+	
					CHAR(13)+CHAR(10)
			
			FETCH NEXT FROM CUR_AvailableFeeUse
			INTO 
				@iAvailableFeeUseID,
				@UnitReductionID,
				@ConventionOperID,
				@iOperID,
				@fUnitQtyUse,			
				@fAvailableUnit,
				@fFeeSumByUnit,
				@dtInforceDate,
				@fUnitQty
		END

		CLOSE CUR_AvailableFeeUse
		DEALLOCATE CUR_AvailableFeeUse
	END

	RETURN @iResult
END


