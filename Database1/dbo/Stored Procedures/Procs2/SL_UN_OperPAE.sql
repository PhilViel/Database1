/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_OperPAE
Description         :	Retourne tout les objets attachés à un transfert de frais.
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
									
									Un_ConventionOper
										ConventionOperTypeID CHAR (3)
										ConventionOperID 		INTEGER
										OperID 				INTEGER
										ConventionID 			INTEGER
										ConventionOperAmount		MONEY
										ConventionNo			VARCHAR (75)
										SubscriberName			VARCHAR (87)
										BeneficiaryName			VARCHAR (87)
									
									Un_ScholarshipPmt
										ScholarshipPmtID	INTEGER
										OperID			INTEGER
										ScholarshipID		INTEGER
										CollegeID		INTEGER
										CompanyName		VARCHAR(75)
										ProgramID		INTEGER
										ProgramDesc		VARCHAR(75)
										StudyStart		DATETIME
										ProgramYear		INTEGER
										ProgramLength		INTEGER
										RegistrationProof	BIT
										SchoolReport		BIT
										EligibilityQty		INTEGER
										CaseOfJanuary		BIT
										EligibilityConditionID	CHAR(3)
									
									Mo_Cheque
										OperID			INTEGER
										iOperationID		INTEGER

									Un_PlanOper
										PlanOperID		INTEGER
										OperID			INTEGER
										PlanID			INTEGER
										PlanOperTypeID		CHAR(3)
										PlanOperAmount		MONEY
										PlanDesc		VARCHAR(75)
										PlanGovernmentRegNo	NVARCHAR(10)

								@ReturnValue :
									> 0 : Réussite : ID du blob qui contient les objets
									<= 0 : Erreurs.
Note                :	ADX0001007	IA	2006-05-30	Alain Quirion
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_OperPAE] (
	@OperID INTEGER ) -- ID de l’opération de transfert de frais
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
	-- Boucle : Un_ConventionOper;ConventionOperTypeID;ConventionOperID;OperID;ConventionID;ConventionOperAmount;ConventionNo;SubscriberName;BeneficiaryName;
	-- Un_ScholarshipPmt;ScholarshipPmtID;OperID;ScholarshipID;CollegeID;CompanyName;ProgramID;ProgramDesc;StudyStart;ProgramYear;ProgramLength;RegistrationProof;SchoolReport;EligibilityQty;CaseOfJanuary;EligibilityConditionID
	-- Mo_Cheque;OperID;iOperationID;
	-- Un_PlanOper;PlanOperID;OperID;PlanID;PlanOperTypeID;PlanOperAmount;PlanDesc;PlanGovernmentRegNo


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
				@OperIDOfPAE INTEGER,
				@OperIDOfRGC INTEGER

			IF EXISTS (
					SELECT OperID
					FROM Un_Oper
					WHERE OperID = @OperID
						AND OperTypeID = 'PAE' )
			BEGIN
				-- L'opération passé en paramètre est le PAE
				SET @OperIDOfPAE = @OperID
				-- Va chercher l'opération RGC
				SET @OperIDOfRGC = 0
				SELECT
					@OperIDOfRGC = SP2.OperID
				FROM Un_ScholarshipPmt SP
				JOIN Un_ScholarshipPmt SP2 ON SP2.ScholarshipID = SP.ScholarshipID
				JOIN Un_Oper O2 ON O2.OperID = SP2.OperID
				WHERE SP.OperID = @OperID
					AND O2.OperTypeID = 'RGC'
			END
			ELSE
			BEGIN
				-- L'opération passé en paramètre est le TFR
				SET @OperIDOfRGC = @OperID
				-- Va chercher l'opération RES
				SET @OperIDOfPAE = 0
				SELECT
					@OperIDOfPAE = SP2.OperID
				FROM Un_ScholarshipPmt SP
				JOIN Un_ScholarshipPmt SP2 ON SP2.ScholarshipID = SP.ScholarshipID
				JOIN Un_Oper O2 ON O2.OperID = SP2.OperID
				WHERE SP.OperID = @OperID
					AND O2.OperTypeID = 'PAE'

				-- Si on n'a pas retrouvé l'opération PAE on retourne une erreur
				IF @OperIDOfPAE = 0
					SET @iResult = -3
			END

			-- Crée un pointeur sur le blob qui servira lors des mises à jour.
			SELECT @pBlob = TEXTPTR(txBlob)
			FROM CRI_Blob
			WHERE iBlobID = @iBlobID

			SET @vcBlob = ''

			-- Opération PAE --
			-- Va chercher les données de l'opération (Un_Oper)
			IF @iResult > 0
				EXECUTE SL_UN_WriteOperInBlob @OperIDOfPAE, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

			-- Va chercher les données du lien d'annulation de l'opération s'il y en a un (Un_OperCancelation)
			IF @iResult > 0
				EXECUTE SL_UN_WriteOperCancelationInBlob @OperIDOfPAE, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

			-- Va chercher les données des opérations sur conventions de l'opération s'il y en a (Un_ConventionOper)
			IF @iResult > 0
				EXECUTE SL_UN_WriteConventionOperInBlob @OperIDOfPAE, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

			-- Un_ScholarshipPmt PAE
			IF @iResult > 0
				EXECUTE SL_UN_WritePAEInBlob @OperIDOfPAE, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT
	
			-- Mo_Cheque
			IF @iResult > 0
				EXECUTE SL_UN_WriteChequeInBlob @OperIDOfPAE, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

			-- Un_PlanOper
			IF @iResult > 0
				EXECUTE SL_UN_WritePlanOperInBlob @OperIDOfPAE, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT
			-- Fin opération PAE --

			-- Opération RGC --
			IF @OperIDOfRGC > 0
			AND @iResult > 0
			BEGIN
				-- Va chercher les données de l'opération (Un_Oper)
				EXECUTE SL_UN_WriteOperInBlob @OperIDOfRGC, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

				-- Va chercher les données des opérations sur conventions de l'opération s'il y en a (Un_ConventionOper)
				IF @iResult > 0
					EXECUTE SL_UN_WriteConventionOperInBlob @OperIDOfRGC, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

				-- Un_ScholarshipPmt PAE
				IF @iResult > 0
					EXECUTE SL_UN_WritePAEInBlob @OperIDOfRGC, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

				-- Mo_Cheque
				IF @iResult > 0
					EXECUTE SL_UN_WriteChequeInBlob @OperIDOfRGC, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT
			END	
			-- Fin opération RGC --

			SELECT @iBlobLength = DATALENGTH(txBlob)
			FROM CRI_Blob
			WHERE iBlobID = @iBlobID

			UPDATETEXT CRI_Blob.txBlob @pBlob @iBlobLength 0 @vcBlob 

			IF @@ERROR <> 0
				SET @iResult = -12
		END -- IF @iResult <= 0 ... ELSE
	END -- IF NOT EXISTS ( ... ELSE 

	IF @iResult > 0
		EXECUTE SL_CRI_Blob @iResult

	RETURN @iResult
END

