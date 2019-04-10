
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_OperRET
Description         :	Retourne tout les objets attachés à un retrait.
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
										BeneficiaryName			VARCHAR (87)
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
										BeneficiaryName			VARCHAR (87)
									Un_WithdrawalReason
										OperID 					INTEGER
										WithdrawalReasonID		INTEGER
									Un_ChequeSuggestion
										ChequeSuggestionID 		INTEGER
										OperID					INTEGER
										HumanID					INTEGER
										FirstName				VARCHAR (35)
										OrigName				VARCHAR (75)
										Initial					VARCHAR (4)
										LastName				VARCHAR (50)
										BirthDate				DATETIME
										DeathDate				DATETIME
										SexID					CHAR (1)
										LangID					CHAR (3)
										CivilID					CHAR (1)
										SocialNumber			VARCHAR (75)
										ResidID					CHAR (1)
										ResidName				VARCHAR (75)
										DriverLicenseNo			VARCHAR (75)
										WebSite					VARCHAR (75)
										CompanyName				VARCHAR (75)
										CourtesyTitle			VARCHAR (35)
										UsingSocialNumber		BIT
										SharePersonalInfo		BIT
										MarketingMaterial		BIT
										IsCompany				BIT
										InForce					DATETIME
										AdrTypeID				CHAR (1)
										SourceID				INTEGER
										Address					VARCHAR (75)
										City					VARCHAR (100)
										StateName				VARCHAR (75)
										CountryID				CHAR (4)
										CountryName				VARCHAR (75)
										ZipCode					VARCHAR (10)
										Phone1					VARCHAR (27)
										Phone2					VARCHAR (27)
										Fax						VARCHAR (15)
										Mobile					VARCHAR (15)
										WattLine				VARCHAR (27)
										OtherTel				VARCHAR (27)
										Pager					VARCHAR (15)
										Email					VARCHAR (100)
										SuggestionAccepted		BIT
								@ReturnValue :
									> 0 : Réussite : ID du blob qui contient les objets
									<= 0 : Erreurs.

Note                :	ADX0000862	IA	2006-03-31	Bruno Lapointe		Création
						ADX0001290	IA	2007-05-25	Alain Quirion		Modification : Ajout de l'objet Un_ChequeSuggestion
*********************************************************************************************************************/
CREATE PROCEDURE dbo.SL_UN_OperRET (
	@OperID INTEGER ) -- ID de l’opération de retrait
AS
BEGIN
	-- Valeurs de retours
	-- >0  : Bien fonctionné, retour le BlobID du blob temporaire qui contient l'information
	-- <=0 : Erreurs
	--		-1 : Pas d'opération
	--		-2 : Blob pas inséré
	--		-3 à -15 : Erreur à l'écriture dans le blob

	-- Un_Oper;OperID;OperTypeID;OperDate;ConnectID;OperTypeDesc;OperTotal;Status;
	-- Un_ChequeSuggestion;ChequeSuggestionID;OperID;HumanID;FirstName;OrigName;Initial;LastName;BirthDate;DeathDate;SexID;LangID;CivilID;SocialNumber;ResidID;ResidName;DriverLicenseNo;WebSite;CompanyName;CourtesyTitle;UsingSocialNumber;SharePersonalInfo;MarketingMaterial;IsCompany;InForce;AdrTypeID;SourceID;Address;City;StateName;CountryID;CountryName;ZipCode;Phone1;Phone2;Fax;Mobile;WattLine;OtherTel;Pager;Email;SuggestionAccepted;	
	-- Un_WithdrawalReason;OperID;WithdrawalReasonID;
	-- Un_OperCancelation;OperSourceID;OperID;
	-- Boucle : Un_Cotisation;CotisationID;OperID;UnitID;EffectDate;Cotisation;Fee;BenefInsur;SubscInsur;TaxOnInsur;ConventionID;ConventionNo;SubscriberName;BeneficiaryName;InForceDate;UnitQty;
	-- Boucle : Un_ConventionOper;ConventionOperTypeID;ConventionOperID;OperID;ConventionID;ConventionOperAmount;ConventionNo;SubscriberName;BeneficiaryName;

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

			-- Va chercher les données de la proposition de modification de chèque de l'opération s'il y en a un (Un_ChequeSuggestion)
				IF @iResult > 0
					EXECUTE SL_UN_WriteChequeSuggestionInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

			-- Va chercher les données de la raison du retrait de l'opération (Un_WithdrawalReason)
			IF @iResult > 0
				EXECUTE SL_UN_WriteWithdrawalReasonInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

			-- Va chercher les données du lien d'annulation de l'opération s'il y en a un (Un_OperCancelation)
			IF @iResult > 0
				EXECUTE SL_UN_WriteOperCancelationInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

			-- Va chercher les données des cotisations de l'opération s'il y en a (Un_Cotisation)
			IF @iResult > 0
				EXECUTE SL_UN_WriteCotisationInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

			-- Va chercher les données des opérations sur conventions de l'opération s'il y en a (Un_ConventionOper)
			IF @iResult > 0
				EXECUTE SL_UN_WriteConventionOperInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

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

