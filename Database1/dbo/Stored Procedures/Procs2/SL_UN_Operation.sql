/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_Operation
Description         :	Procédure de retour du détail d'une opération dans un blob temporaire
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
Note                :	ADX0000510	IA	2004-11-16	Bruno Lapointe		Création
								ADX0000588	IA	2004-11-18	Bruno Lapointe		Gestion des AVC
								ADX0001185	BR	2004-12-13	Bruno Lapointe		Contrat Externe Alphanumérique
								ADX0000625	IA	2005-01-05	Bruno Lapointe		Gestion des RIN
								ADX0000593	IA	2005-01-06	Bruno Lapointe		Gestion des PAE
								ADX0000635	IA	2005-01-11	Bruno Lapointe		Ajout d'une valeur de retour au opération pour
																							les annulations.
								ADX0001259	BR	2005-02-03	Bruno Lapointe		Retour du champs EligibilityConditionID
								ADX0001332	BR	2005-03-14	Bruno Lapointe		Correction bug retour ChequeSuggestion sans adresse
								ADX0000694	IA	2005-06-08	Bruno Lapointe		On va retourner un objet de cheque pour les 
																							opérations RIN qui ont un chèque.
								ADX0000753	IA 2005-10-05	Bruno Lapointe		1. Le codage de l’objet Mo_Cheque dans le blob va 
																							changer pour celui-ci :
																								Mo_Cheque;OperID; 
																							Le but est de seulement informer de la présence d’un
																							chèque, pour déterminer si le bouton de visualisation
																							du chèque doit être disponible (RIN).  
																							2. Le codage de l’objet Un_ChequeSuggestion dans le
																							blob va changer pour celui-ci :
																							Un_ChequeSuggestion;ChequeSuggestionID;OperID;HumanID;
																							FirstName;OrigName;Initial;LastName;BirthDate;
																							DeathDate;SexID;LangID;CivilID;SocialNumber;ResidID;
																							ResidName;DriverLicenseNo;WebSite;CompanyName;
																							CourtesyTitle;UsingSocialNumber;SharePersonalInfo;
																							MarketingMaterial;IsCompany;InForce;AdrTypeID;SourceID;
																							Address;City;StateName;CountryID;CountryName;ZipCode;
																							Phone1;Phone2;Fax;Mobile;WattLine;OtherTel;Pager;Email;
																							SuggestionAccepted;
								ADX0001634	BR	2005-10-21	Bruno Lapointe		Problème avec visualisation PAE lors d'annulation financière.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_Operation] (
	@OperID INTEGER ) -- ID de l’opération
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
	-- Boucle : Un_Cotisation;CotisationID;OperID;UnitID;EffectDate;Cotisation;Fee;BenefInsur;SubscInsur;TaxOnInsur;ConventionID;ConventionNo;SubscriberName;BeneficiaryName;InForceDate;UnitQty;
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
				@iBlobLength INTEGER

			-- Crée un pointeur sur le blob qui servira lors des mises à jour.
			SELECT @pBlob = TEXTPTR(txBlob)
			FROM CRI_Blob
			WHERE iBlobID = @iBlobID

			SET @vcBlob = ''

			-- Va chercher les données de l'opération (Un_Oper)
			EXECUTE SL_UN_WriteOperInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

			-- Va chercher les données du lien d'annulation de l'opération s'il y en a un (Un_OperCancelation)
			IF @iResult > 0
				EXECUTE SL_UN_WriteOperCancelationInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

			-- Va chercher les données des cotisations de l'opération s'il y en a (Un_Cotisation)
			IF @iResult > 0
				EXECUTE SL_UN_WriteCotisationInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

			-- Va chercher les données des opérations sur conventions de l'opération s'il y en a (Un_ConventionOper)
			IF @iResult > 0
				EXECUTE SL_UN_WriteConventionOperInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

			-- Un_ScholarshipPmt PAE
			IF @iResult > 0
				EXECUTE SL_UN_WritePAEInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT
	
			-- Mo_Cheque
			IF @iResult > 0
				EXECUTE SL_UN_WriteChequeInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

			-- Un_PlanOper
			IF @iResult > 0
				EXECUTE SL_UN_WritePlanOperInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

			-- Un_OtherAccountOper
			IF @iResult > 0
				EXECUTE SL_UN_WriteOtherAccountOperInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

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

