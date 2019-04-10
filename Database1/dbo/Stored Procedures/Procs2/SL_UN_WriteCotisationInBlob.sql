/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_WriteCotisationInBlob
Description         :	Retourne les objets Un_Cotisation correspondant au OperID dans le blob du pointeur(@pBlob) 
								ou le champs texte(@vcBlob).
Valeurs de retours  :	Type d’objet traité être dans le blob :
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
										SubscriberID 			INTEGER
										SubscriberName			VARCHAR (87)
										BeneficiaryName			VARCHAR (87)
										InForceDate				DATETIME
										UnitQty					MONEY
										bIsContestWinner		BIT
								@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	
						ADX0000847	IA	2006-03-28	Bruno Lapointe		Création								
						ADX0001183	IA	2006-10-12	Bruno Lapointe		Ajout du SubscriberID
						ADX0002520	BR	2007-08-20	Alain Quirion		Ajout de bIsContestWinner
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_WriteCotisationInBlob] (
	@OperID INTEGER, -- ID de l’opération
	@iBlobID INTEGER, -- ID du blob dans lequel on écrit
	@pBlob BINARY(16), -- Pointeur sur le blob
	@vcBlob VARCHAR(8000) OUTPUT, -- Contient le texte des objets à insérer dans le blob
	@iResult INTEGER OUTPUT ) -- Varible résultat
AS
BEGIN
	-- Boucle : Un_Cotisation;CotisationID;OperID;UnitID;EffectDate;Cotisation;Fee;BenefInsur;SubscInsur;TaxOnInsur;ConventionID;ConventionNo;SubscriberName;BeneficiaryName;InForceDate;UnitQty;

	DECLARE
		-- Variables de l'objet cotisation
		@CotisationID INTEGER,
		@UnitID INTEGER,
		@EffectDate DATETIME,
		@Cotisation MONEY,
		@Fee MONEY,
		@BenefInsur MONEY,
		@SubscInsur MONEY,
		@TaxOnInsur MONEY,
		@ConventionID INTEGER,
		@ConventionNo VARCHAR(75),
		@SubscriberID INTEGER,
		@SubscriberName VARCHAR(87),
		@BeneficiaryName VARCHAR(87),
		@InForceDate DATETIME,
		@UnitQty MONEY,
		@bIsContestWinner BIT

	-- Curseur de détail des objets cotisations (Un_Cotisation)
	DECLARE crWrite_Un_Cotisation CURSOR FOR
		SELECT 
			Ct.CotisationID,
			Ct.UnitID,
			Ct.EffectDate,
			Ct.Cotisation,
			Ct.Fee,
			Ct.BenefInsur,
			Ct.SubscInsur,
			Ct.TaxOnInsur,
			C.ConventionID,
			C.ConventionNo,
			C.SubscriberID,
			SubscriberName = 
				CASE 
					WHEN S.IsCompany = 1 THEN S.LastName
				ELSE S.LastName+', '+S.FirstName
				END,
			BeneficiaryName = B.LastName+', '+B.FirstName,
			U.InForceDate,
			U.UnitQty,
			bIsContestWinner = ISNULL(SS.bIsContestWinner,0)
		FROM Un_Cotisation Ct
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
		JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
		WHERE Ct.OperID = @OperID
					
	-- Ouvre le curseur
	OPEN crWrite_Un_Cotisation
			
	-- Va chercher la première cotisation
	FETCH NEXT FROM crWrite_Un_Cotisation
	INTO
		@CotisationID,
		@UnitID,
		@EffectDate,
		@Cotisation,
		@Fee,
		@BenefInsur,
		@SubscInsur,
		@TaxOnInsur,
		@ConventionID,
		@ConventionNo,
		@SubscriberID,
		@SubscriberName,
		@BeneficiaryName,
		@InForceDate,
		@UnitQty,
		@bIsContestWinner
	
	WHILE (@@FETCH_STATUS = 0)
	  AND (@iResult > 0)
	BEGIN
		-- S'il n'y pas assez d'espace disponible dans la variable, on inscrit le contenu de la variable dans le blob et on vide la variable par la suite
		IF LEN(@vcBlob) > 7200
		BEGIN
			DECLARE
				@iBlobLength INTEGER

			SELECT @iBlobLength = DATALENGTH(txBlob)
			FROM CRI_Blob
			WHERE iBlobID = @iBlobID

			UPDATETEXT CRI_Blob.txBlob @pBlob @iBlobLength 0 @vcBlob 

			IF @@ERROR <> 0
				SET @iResult = -15

			SET @vcBlob = ''
		END

		-- Inscrit la cotisation dans le blob
		-- Un_Cotisation;CotisationID;OperID;UnitID;EffectDate;Cotisation;Fee;BenefInsur;SubscInsur;TaxOnInsur;ConventionID;ConventionNo;SubscriberID;SubscriberName;BeneficiaryName;InForceDate;UnitQty;
		SET @vcBlob =
			@vcBlob+
			'Un_Cotisation;'+
			CAST(@CotisationID AS VARCHAR)+';'+
			CAST(@OperID AS VARCHAR)+';'+
			CAST(@UnitID AS VARCHAR)+';'+
			CONVERT(CHAR(10), @EffectDate, 20)+';'+
			CAST(@Cotisation AS VARCHAR)+';'+
			CAST(@Fee AS VARCHAR)+';'+
			CAST(@BenefInsur AS VARCHAR)+';'+
			CAST(@SubscInsur AS VARCHAR)+';'+
			CAST(@TaxOnInsur AS VARCHAR)+';'+
			CAST(@ConventionID AS VARCHAR)+';'+
			@ConventionNo+';'+
			CAST(@SubscriberID AS VARCHAR)+';'+
			@SubscriberName+';'+
			@BeneficiaryName+';'+
			CONVERT(CHAR(10), @InForceDate, 20)+';'+
			CAST(CAST(@UnitQty AS FLOAT) AS VARCHAR)+';'+
			CAST(@bIsContestWinner AS VARCHAR)+';'+
			CHAR(13)+CHAR(10)

		-- Passe à la prochaine cotisation
		FETCH NEXT FROM crWrite_Un_Cotisation
		INTO
			@CotisationID,
			@UnitID,
			@EffectDate,
			@Cotisation,
			@Fee,
			@BenefInsur,
			@SubscInsur,
			@TaxOnInsur,
			@ConventionID,
			@ConventionNo,
			@SubscriberID,
			@SubscriberName,
			@BeneficiaryName,
			@InForceDate,
			@UnitQty,
			@bIsContestWinner
	END -- WHILE (@@FETCH_STATUS = 0) de crWrite_Un_Cotisation
	
	-- Détruit le curseur des cotisations
	CLOSE crWrite_Un_Cotisation
	DEALLOCATE crWrite_Un_Cotisation

	RETURN @iResult
END


