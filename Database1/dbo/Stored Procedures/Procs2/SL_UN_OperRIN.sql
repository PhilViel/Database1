/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_OperRIN
Description         :	Retourne tout les objets attachés à un remboursement intégral.
Valeurs de retours  :	Dataset :
									iBlobID	INTEGER	ID du blob
									dtBlob	DATETIME	Date d'insertion du blob.
									txBlob	TEXT		Blob contenant les objets
								Type d’objet pouvant être dans le blob :
									Un_Oper
										OperID 					INTEGER
										OperTypeID 				CHAR (3)
										OperDate 				DATETIME	
										ConnectID 				INTEGER
										OperTypeDesc 			VARCHAR (75)
										OperTotal				MONEY
										Status 					TINYINT	
									Un_OperCancelation
										OperSourceID 			INTEGER
										OperID 					INTEGER
									Mo_Cheque
										OperID					INTEGER
										iOperationID			INTEGER
									Un_IntReimb
										IntReimbID				INTEGER
										UnitID					INTEGER
										CollegeID				INTEGER
										CompanyName				VARCHAR (75)
										ProgramID				INTEGER
										ProgramDesc				VARCHAR (75)
										IntReimbDate			DATETIME
										StudyStart				DATETIME
										ProgramYear				INTEGER
										ProgramLength			INTEGER
										CESGRenonciation		BIT
										FullRIN					BIT
									Un_Cotisation
										CotisationID			INTEGER
										OperID					INTEGER
										UnitID					INTEGER
										EffectDate				DATETIME
										Cotisation				MONEY
										Fee						MONEY
										BenefInsur				MONEY
										SubscInsur				MONEY
										TaxOnInsur				MONEY
										ConventionID			INTEGER
										ConventionNo			VARCHAR (75)
										SubscriberName			VARCHAR (87)
										BeneficiaryName		VARCHAR (87)
										InForceDate				DATETIME
										UnitQty					MONEY
									Un_OtherAccountOper
										OtherAccountOperID		INTEGER
										OperID						INTEGER
										OtherAccountOperAmount	MONEY
								@ReturnValue :
									> 0 : Réussite : ID du blob qui contient les objets
									<= 0 : Erreurs.
Note                :	ADX0000829	IA	2006-04-03	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_OperRIN] (
	@OperID INTEGER ) -- ID de l’opération de remboursement intégral
AS
BEGIN
	-- Valeurs de retours
	-- >0  : Bien fonctionné, retour le BlobID du blob temporaire qui contient l'information
	-- <=0 : Erreurs
	--		-1 : Pas d'opération
	--		-2 : Blob pas inséré
	--		-3 à -15 : Erreur à l'écriture dans le blob

	-- Un_Oper;OperID;OperTypeID;OperDate;ConnectID;OperTypeDesc;OperTotal;Status;
	-- Un_OperCancelation;OperSourceID;OperID;
	-- Un_IntReimb;IntReimbID;UnitID;CollegeID;CompanyName;ProgramID;ProgramDesc;IntReimbDate;StudyStart;ProgramYear;ProgramLength;CESGRenonciation;FullRIN;
	-- Mo_Cheque;OperID;iOperationID;
	-- Boucle : Un_Cotisation;CotisationID;OperID;UnitID;EffectDate;Cotisation;Fee;BenefInsur;SubscInsur;TaxOnInsur;ConventionID;ConventionNo;SubscriberName;BeneficiaryName;InForceDate;UnitQty;
	-- Boucle : Un_OtherAccountOper;OtherAccountOperID;OperID;OtherAccountOperAmount;

	DECLARE
		@iResult INTEGER,
		@iBlobID INTEGER

	-- Valide que la liste de IDs n'est pas vide
	IF NOT EXISTS (
			SELECT OperID
			FROM Un_Oper
			WHERE OperID = @OperID )
		SET @iResult = -1 -- Pas d'opération
	ELSE
	BEGIN
		-- Insère le blob temporaire sans texte.
		EXECUTE @iBlobID = IU_CRI_Blob 0, ''

		-- Vérifie que le blob est bien inséré
		IF @iBlobID <= 0
			SET @iResult = -2 -- Erreur à l'insertion du blob
		ELSE
		BEGIN
			SET @iResult = @iBlobID

			-- Inscrit le détail des objets d'opérations (Un_Oper)
			DECLARE 
				@pBlob BINARY(16),
				@vcBlob VARCHAR(8000),
				@iBlobLength INTEGER,
				@OperIDOfRIN INTEGER,
				@OperIDOfTFR INTEGER

			IF EXISTS (
					SELECT OperID
					FROM Un_Oper
					WHERE OperID = @OperID
						AND OperTypeID = 'RIN' )
			BEGIN
				-- L'opération passé en paramètre est le RIN
				SET @OperIDOfRIN = @OperID
				-- Va chercher l'opération TFR
				SET @OperIDOfTFR = 0
				SELECT
					@OperIDOfTFR = IRO2.OperID
				FROM Un_IntReimbOper IRO
				JOIN Un_IntReimbOper IRO2 ON IRO2.IntReimbID = IRO.IntReimbID AND IRO2.OperID <> IRO.OperID
				JOIN Un_Oper O ON O.OperID = IRO2.OperID
				WHERE IRO.OperID = @OperID
					AND O.OperTypeID = 'TFR'
			END
			ELSE
			BEGIN
				-- L'opération passé en paramètre est le TFR
				SET @OperIDOfTFR = @OperID
				-- Va chercher l'opération RIN
				SET @OperIDOfRIN = 0
				SELECT
					@OperIDOfRIN = IRO2.OperID
				FROM Un_IntReimbOper IRO
				JOIN Un_IntReimbOper IRO2 ON IRO2.IntReimbID = IRO.IntReimbID AND IRO2.OperID <> IRO.OperID
				JOIN Un_Oper O ON O.OperID = IRO2.OperID
				WHERE IRO.OperID = @OperID
					AND O.OperTypeID = 'RIN'

				-- Si on n'a pas retrouvé l'opération RES on retourne une erreur
				IF @OperIDOfRIN = 0
					SET @iResult = -3
			END

			IF @iResult > 0
			BEGIN
				-- Crée un pointeur sur le blob qui servira lors des mises à jour.
				SELECT @pBlob = TEXTPTR(txBlob)
				FROM CRI_Blob
				WHERE iBlobID = @iBlobID
	
				SET @vcBlob = ''
	
				-- Opération RIN --
				-- Va chercher les données de l'opération (Un_Oper)
				EXECUTE SL_UN_WriteOperInBlob @OperIDOfRIN, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT
	
				-- Va chercher les données du lien d'annulation de l'opération s'il y en a un (Un_OperCancelation)
				IF @iResult > 0
					EXECUTE SL_UN_WriteOperCancelationInBlob @OperIDOfRIN, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT
	
				-- Va chercher les données du remboursement intégral de l'opération s'il y en a un (Un_IntReimb)
				IF @iResult > 0
					EXECUTE SL_UN_WriteIntReimbInBlob @OperIDOfRIN, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT
	
				-- Va chercher les données du chèque de l'opération s'il y en a un (Mo_Cheque)
				IF @iResult > 0
					EXECUTE SL_UN_WriteChequeInBlob @OperIDOfRIN, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT
	
				-- Va chercher les données des cotisations de l'opération s'il y en a (Un_Cotisation)
				IF @iResult > 0
					EXECUTE SL_UN_WriteCotisationInBlob @OperIDOfRIN, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT
				-- Fin opération RIN --
	
				-- Opération TFR --
				IF @OperIDOfTFR > 0
				AND @iResult > 0
				BEGIN
					-- Va chercher les données de l'opération (Un_Oper)
					EXECUTE SL_UN_WriteOperInBlob @OperIDOfTFR, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

					-- Va chercher les données des cotisations de l'opération s'il y en a (Un_Cotisation)
					IF @iResult > 0
						EXECUTE SL_UN_WriteCotisationInBlob @OperIDOfTFR, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

					-- Va chercher les données des opérations sur conventions de l'opération s'il y en a (Un_OtherAccountOper)
					IF @iResult > 0
						EXECUTE SL_UN_WriteOtherAccountOperInBlob @OperIDOfTFR, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

				END	
				-- Fin opération TFR --

				SELECT @iBlobLength = DATALENGTH(txBlob)
				FROM CRI_Blob
				WHERE iBlobID = @iBlobID
	
				UPDATETEXT CRI_Blob.txBlob @pBlob @iBlobLength 0 @vcBlob 
	
				IF @@ERROR <> 0
					SET @iResult = -12
			END
		END -- IF @iResult <= 0 ... ELSE
	END -- IF NOT EXISTS ( ... ELSE 

	IF @iResult > 0
		EXECUTE SL_CRI_Blob @iResult

	RETURN @iResult
END

