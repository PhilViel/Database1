/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_OperTIN
Description         :	Retourne tout les objets attachés à un chèque.
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
									Un_TIN
										OperID								INTEGER
										ExternalPlanID						INTEGER
										tiBnfRelationWithOtherConvBnf	TINYINT
										vcOtherConventionNo				VARCHAR(15)
										dtOtherConvention					DATETIME
										tiOtherConvBnfRelation			TINYINT
										bAIP									BIT
										bACESGPaid							BIT
										bBECInclud 							BIT
										bPGInclud							BIT
										fYearBnfCot							MONEY
										fBnfCot								MONEY
										fNoCESGCotBefore98				MONEY
										fNoCESGCot98AndAfter				MONEY
										fCESGCot								MONEY
										fCESG									MONEY
										fCLB									MONEY
										fAIP									MONEY
										fMarketValue						MONEY
										bPendingApplication				BIT
										ExternalPlanGovernmentRegNo	NVARCHAR(10)
										CompanyName							VARCHAR(75)
										Address								VARCHAR(75)
										City									VARCHAR(100)
										Statename							VARCHAR(75)
										CountryID							CHAR(4)
										CountryName							VARCHAR(75)
										ZipCode								VARCHAR(10)
								@ReturnValue :
									> 0 : Réussite : ID du blob qui contient les objets
									<= 0 : Erreurs.
Note                :	ADX0000925	IA	2006-05-08	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_OperTIN] (
	@OperID INTEGER ) -- ID de l’opération de chèque
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
	-- Un_TIN;OperID;ExternalPlanID;tiBnfRelationWithOtherConvBnf;vcOtherConventionNo;dtOtherConvention;tiOtherConvBnfRelation;
		-- bAIP;bACESGPaid;bBECInclud;fYearBnfCot;fBnfCot;fNoCESGCotBefore98;fNoCESGCot98AndAfter;fCESGCot;fCESG;fCLB;fAIP;fMarketValue;
		-- bPendingApplication;ExternalPlanGovernmentRegNo;CompanyName;Address;City;Statename;CountryID;CountryName;ZipCode;
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

			-- Va chercher les données du lien d'annulation de l'opération s'il y en a un (Un_OperCancelation)
			IF @iResult > 0
				EXECUTE SL_UN_WriteOperCancelationInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

			-- Va chercher les données du TIN de l'opération s'il y en a un (Un_TIN)
			IF @iResult > 0
				EXECUTE SL_UN_WriteTINInBlob @OperID, @iBlobID, @pBlob, @vcBlob OUTPUT, @iResult OUTPUT

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

