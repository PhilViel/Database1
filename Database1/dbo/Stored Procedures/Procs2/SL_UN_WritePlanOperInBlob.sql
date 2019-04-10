/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_WritePlanOperInBlob
Description         :	Retourne l'objet Un_ScholarshipPmt correspondant au OperID dans le blob du pointeur @pBlob 
								ou le champs texte @vcBlob.
Valeurs de retours  :	Type d’objet traité être dans le blob :
									Un_PlanOper
										PlanOperID		INTEGER
										OperID			INTEGER
										PlanID			INTEGER
										PlanOperTypeID		CHAR(3)
										PlanOperAmount		MONEY
										PlanDesc		VARCHAR(75)
										PlanGovernmentRegNo	NVARCHAR(10)

								@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0001007	IA	2006-05-30	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_WritePlanOperInBlob] (
	@OperID INTEGER, -- ID de l’opération de chèque
	@iBlobID INTEGER, -- ID du blob dans lequel on écrit
	@pBlob BINARY(16), -- Pointeur sur le blob
	@vcBlob VARCHAR(8000) OUTPUT, -- Contient le texte des objets à insérer dans le blob
	@iResult INTEGER OUTPUT ) -- Varible résultat
AS
BEGIN
	--Un_PlanOper;PlanOperID;OperID;PlanID;PlanOperTypeID;PlanOperAmount;PlanDesc;PlanGovernmentRegNo

	-- Traite les Un_PlanOper
	IF EXISTS (
			SELECT OperID
			FROM Un_PlanOper
			WHERE OperID = @OperID) AND
		(@iResult > 0)
	BEGIN
		-- Si Il n'y pas assez d'espace disponible dans la variable, on inscrit le contenu de la variable dans le blob et on vide la variable par la suite
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

		-- Inscrit les données du Un_PlanOper de l'opération dans le blob
		SELECT 
			@vcBlob = 
				@vcBlob +
				'Un_PlanOper;'+
				CAST(PO.PlanOperID AS VARCHAR)+';'+
				CAST(@OperID AS VARCHAR)+';'+
				CAST(PO.PlanID AS VARCHAR)+';'+
				CAST(PO.PlanOperTypeID AS VARCHAR)+';'+
				CAST(ISNULL(PO.PlanOperAmount,0) AS VARCHAR)+';'+
				CAST(P.PlanDesc AS VARCHAR)+';'+
				CAST(P.PlanGovernmentRegNo AS VARCHAR)+';'+	
				CHAR(13)+CHAR(10)
		FROM Un_PlanOper PO
		JOIN Un_Plan P ON P.PlanID = PO.PlanID
		WHERE OperID = @OperID
	END

	RETURN @iResult
END

