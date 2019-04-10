/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_OperOUT
Description         :	Retourne tout les objets attachés à un transfert OUT.
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
									Un_ConventionOper
										ConventionOperTypeID CHAR (3)
										ConventionOperID 		INTEGER
										OperID 					INTEGER
										ConventionID 			INTEGER
										ConventionOperAmount	MONEY
										ConventionNo			VARCHAR (75)
										SubscriberName			VARCHAR (87)
										BeneficiaryName		VARCHAR (87)
									Un_OtherAccountOper
										OtherAccountOperID		INTEGER
										OperID						INTEGER
										OtherAccountOperAmount	MONEY
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
									Un_OUT
										OperID	INTEGER
										ExternalPlanID	INTEGER
										tiBnfRelationWithOtherConvBnf	TINYINT
										vcOtherConventionNo	VARCHAR(15)
										tiREEEType	TINYINT
										bEligibleForCESG	BIT
										bEligibleForCLB	BIT
										bOtherContratBnfAreBrothers	BIT
										fYearBnfCot	MONEY
										fBnfCot	MONEY
										fNoCESGCotBefore98	MONEY
										fNoCESGCot98AndAfter	MONEY
										fCESGCot	MONEY
										fCESG	MONEY
										fCLB	MONEY
										fAIP	MONEY
										fMarketValue	MONEY
										ExternalPlanGovernmentRegNo	NVARCHAR(10)
										CompanyName	VARCHAR(75)
										Address	VARCHAR(75)
										City	VARCHAR(100)
										Statename	VARCHAR(75)
										CountryID	CHAR(4)
										CountryName	VARCHAR(75)
										ZipCode	VARCHAR(10)

								@ReturnValue :
									> 0 : Réussite : ID du blob qui contient les objets
									<= 0 : Erreurs.
Note                :	ADX0000992	IA	2006-05-23	ALain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_OperOUT] (
	@OperID INTEGER ) -- ID de l’opération de transfert de out
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
	-- Un_UnitReduction;UnitReductionID;UnitID;ReductionConnectID;ReductionDate;UnitQty;FeeSumByUnit;SubscInsurSumByUnit;UnitReductionReasonID;UnitReductionReason;NoChequeReasonID;NoChequeReason;
	-- Boucle : Un_Cotisation;CotisationID;OperID;UnitID;EffectDate;Cotisation;Fee;BenefInsur;SubscInsur;TaxOnInsur;ConventionID;ConventionNo;SubscriberName;BeneficiaryName;InForceDate;UnitQty;
	-- Boucle : Un_ConventionOper;ConventionOperTypeID;ConventionOperID;OperID;ConventionID;ConventionOperAmount;ConventionNo;SubscriberName;BeneficiaryName;
	-- Boucle : Un_OtherAccountOper;OtherAccountOperID;OperID;OtherAccountOperAmount;
	-- Un_OUT;OperID;ExternalPlanID;tiBnfRelationWithOtherConvBnf;vcOtherConventionNo;tiREEEType;bEligibleForCESG;bEligibleForCLB;bOtherContratBnfAreBrothers;fYearBnfCot;fBnfCot;fNoCESGCotBefore98;fNoCESGCot98AndAfter;fCESGCot;fCESG;fCLB;fAIP;fMarketValue;ExternalPlanGovernmentRegNo;CompanyName;Address;City;Statename;CountryID;CountryName;ZipCode

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
				@OperIDOfOUT INTEGER,
				@OperIDOfTFR INTEGER

			IF EXISTS (
					SELECT OperID
					FROM Un_Oper
					WHERE OperID = @OperID
						AND OperTypeID = 'OUT' )
			BEGIN
				-- L'opération passé en paramètre est le OUT
				SET @OperIDOfOUT = @OperID
				-- Va chercher l'opération TFR
				SET @OperIDOfTFR = 0
				SELECT
					@OperIDOfTFR = Ct2.OperID
				FROM Un_Cotisation Ct
				JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
				JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID  AND URC2.CotisationID <> URC.CotisationID
				JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
				JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID
				WHERE Ct.OperID = @OperID
					AND O2.OperTypeID = 'TFR'
					AND Ct2.OperID <> @OperID
			END
			ELSE
			BEGIN
				-- L'opération passé en paramètre est le TFR
				SET @OperIDOfTFR = @OperID
				-- Va chercher l'opération OUT
				SET @OperIDOfOUT = 0
				SELECT
					@OperIDOfOUT = Ct2.OperID
				FROM Un_Cotisation Ct
				JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
				JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID  AND URC2.CotisationID <> URC.CotisationID
				JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
				JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID
				WHERE Ct.OperID = @OperID
					AND O2.OperTypeID = 'OUT'
					AND Ct2.OperID <> @OperID

				-- Si on n'a pas retrouvé l'opération OUT on retourne une erreur
				IF @OperIDOfOUT = 0
					SET @iResult = -3
			END

			IF @iResult > 0
			BEGIN
				-- Crée un pointeur sur le blob qui servira lors des mises à jour.
				SELECT @pBlob = TEXTPTR(txBlob)
				FROM CRI_Blob
				WHERE iBlobID = @iBlobID

				SET @vcBlob = ''

				-- Début opération OUT --
				-- Va chercher les données de l'opération (Un_Oper)
				EXECUTE SL_UN_WriteOperInBlob @OperIDOfOUT, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

				-- Va chercher les données du lien d'annulation de l'opération s'il y en a un (Un_OperCancelation)
				IF @iResult > 0
					EXECUTE SL_UN_WriteOperCancelationInBlob @OperIDOfOUT, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

				-- Va chercher les données des cotisations de l'opération s'il y en a (Un_Cotisation)
				IF @iResult > 0
					EXECUTE SL_UN_WriteCotisationInBlob @OperIDOfOUT, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

				-- Va chercher les données des opérations sur conventions de l'opération s'il y en a (Un_ConventionOper)
				IF @iResult > 0
					EXECUTE SL_UN_WriteConventionOperInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

				-- Va chercher les données de la réduction d'unités de l'opération s'il y en a un (Un_ChequeSuggestion)
				IF @iResult > 0
					EXECUTE SL_UN_WriteChequeSuggestionInBlob @OperIDOfOUT, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT


				-- Va chercher les données de la réduction d'unités de l'opération s'il y en a un (Un_UnitReduction)
				IF @iResult > 0
					EXECUTE SL_UN_WriteUnitReductionInBlob @OperIDOfOUT, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

				-- Va chercher les données des opérations sur conventions de l'opération s'il y en a (Un_OtherAccountOper)
				IF @iResult > 0
					EXECUTE SL_UN_WriteOtherAccountOperInBlob @OperIDOfOUT, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

				-- Va chercher les données des opérations OUT s'il y en a (Un_OUT)
				IF @iResult > 0
					EXECUTE SL_UN_WriteOUTInBlob @OperIDOfOUT, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT
				-- Fin opération OUT --
			

				-- Opération TFR --
				IF @OperIDOfTFR > 0
				AND @iResult > 0
				BEGIN
					-- Va chercher les données de l'opération (Un_Oper)
					EXECUTE SL_UN_WriteOperInBlob @OperIDOfTFR, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

					-- Va chercher les données des cotisations de l'opération s'il y en a (Un_Cotisation)
					IF @iResult > 0
						EXECUTE SL_UN_WriteCotisationInBlob @OperIDOfTFR, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

					-- Va chercher les données des opérations sur conventions de l'opération s'il y en a (Un_ConventionOper)
					IF @iResult > 0
						EXECUTE SL_UN_WriteConventionOperInBlob @OperIDOfTFR, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

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
			END -- IF @OperIDOfOUT = 0
		END -- IF @iResult <= 0 ... ELSE
	END -- IF NOT EXISTS ( ... ELSE 

	IF @iResult > 0
		EXECUTE SL_CRI_Blob @iResult

	RETURN @iResult
END

