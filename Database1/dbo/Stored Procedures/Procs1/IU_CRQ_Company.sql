
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas
Nom                 :	IU_CRQ_Company
Description         :	Procédure de sauvegarde d’ajout ou modification de compagnie.
Valeurs de retours  :	@ReturnValue :
									> 0 : La sauvegarde a réussie.
									<= 0 : La sauvegarde a échouée
Note                :	ADX0000730	IA	2005-06-13	Bruno Lapointe		Création
						ADX0001159	IA	2007-02-12	Alain Quirion		Modification : Att2
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_CRQ_Company (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@CompanyID INTEGER, -- Identifiant unique de la compagnie
	@CompanyName VARCHAR(75), -- Nom de la compagnie
	@LangID CHAR(3), -- Langue (Code)
	@WebSite VARCHAR(100), -- Site Internet
	@StateTaxNumber VARCHAR(75), -- Numéro d’enregistrement à la taxe provinciale (TVQ)
	@CountryTaxNumber VARCHAR(75), -- Numéro d’enregistrement à la taxe fédérale  (TPS)
	@EndBusiness DATETIME, -- Date de fermeture
	@DepType CHAR(1), -- Un caractère désignant le type de département dont il s'agit. ('U'=Inconnu, 'H'=???, 'S'=Succursale, 'A'=Adresse)
	@Att VARCHAR(150), -- Contact
	@InForce DATETIME, -- Date d’entrée en vigueur de l’adresse.
	@Address VARCHAR(75), -- # civique, rue et suite
	@City VARCHAR(100), -- Ville
	@StateName VARCHAR(75), -- Province/État
	@CountryID CHAR(3), -- Pays (Code)
	@ZipCode VARCHAR(10), -- Code postale
	@Phone1 VARCHAR(27), -- Téléphone maison
	@Phone2 VARCHAR(27), -- Téléphone bureau
	@Fax VARCHAR(15), -- Fax
	@Mobile VARCHAR(15), -- Cellulaire
	@WattLine VARCHAR(15), -- Ligne sans frais
	@OtherTel VARCHAR(27), -- Autre numéro
	@Pager VARCHAR(15), -- Paget
	@EMail VARCHAR(100), -- Courriel
	@Att2 VARCHAR(150))	--Contact #2
AS
BEGIN
	DECLARE
		@iResult INTEGER,
		@LogDesc MoNoteDescOption,
		@HeaderLog MoNoteDescOption,
		@DepID MoID,
		@Old_CompanyName MoCompanyName,
		@Old_LangID MoLang,
		@Old_WebSite MoEmail,
		@Old_StateTaxNumber MoDescOption,
		@Old_CountryTaxNumber MoDescOption,
		@Old_EndBusiness MoDateOption

	SET @EndBusiness = dbo.FN_CRQ_IsDateNull(@EndBusiness) 

	-- Initialisation des variables pour le log
	SET @LogDesc = ''

	SET @iResult = @CompanyID

	IF @CompanyID = 0
		SET @HeaderLog = dbo.fn_Mo_FormatLog ('MO_COMPANY', 'NEW', '', @CompanyName)
	ELSE
	BEGIN
		SET @HeaderLog = dbo.fn_Mo_FormatLog ('MO_COMPANY', 'MODIF', '', @CompanyName)
		SELECT
			@Old_CompanyName = CompanyName,
			@Old_LangID = LangID,
			@Old_WebSite = WebSite,
			@Old_StateTaxNumber = StateTaxNumber,
			@Old_CountryTaxNumber = CountryTaxNumber,
			@Old_EndBusiness = EndBusiness
		FROM Mo_Company
		WHERE CompanyID = @CompanyID
	END

	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_COMPANY', 'COMPANYNAME', @Old_CompanyName, @CompanyName)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_COMPANY', 'LANG', @Old_LangID, @LangID)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_COMPANY', 'WEBSITE', @Old_WebSite, @WebSite)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_COMPANY', 'STATETAXNUMBER', @Old_StateTaxNumber, @StateTaxNumber)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_COMPANY', 'COUNTRYTAXNUMBER', @Old_CountryTaxNumber, @CountryTaxNumber)
	SET @LogDesc = @LogDesc + dbo.fn_Mo_FormatLog ('MO_COMPANY', 'ENDBUSINESS', CAST(@Old_EndBusiness AS CHAR), CAST(@EndBusiness AS CHAR))
	IF @LogDesc <> '' SET @LogDesc = @HeaderLog + @LogDesc

	IF @CompanyID = 0
	BEGIN
	    -- On doit créer la compagnie
		SET @DepID = 0

		INSERT INTO Mo_Company (
			CompanyName,
			LangID,
			WebSite,
			StateTaxNumber,
			CountryTaxNumber,
			EndBusiness )
		VALUES (
			@CompanyName,
			@LangID,
			@WebSite,
			@StateTaxNumber,
			@CountryTaxNumber,
			@EndBusiness )

		IF @@ERROR <> 0
			SET @iResult = -1
		ELSE
		BEGIN
			SET @CompanyID = SCOPE_IDENTITY()
			SET @iResult = @CompanyID
		END

		IF @iResult > 0 
		BEGIN
			EXEC SP_IU_CRQ_Log @ConnectID, 'Mo_Company', @CompanyID, 'I', @LogDesc

			EXECUTE @DepID = IU_CRQ_Dep
				@ConnectID,
				@DepID,
				@CompanyID,
				@DepType,
				@Att,
				@InForce,
				@Address,
				@City,
				@StateName,
				@CountryID,
				@ZipCode,
				@Phone1,
				@Phone2,
				@Fax,
				@Mobile,
				@WattLine,
				@OtherTel,
				@Pager,
				@EMail,
				@Att2

			IF @DepID <= 0
			  SET @iResult = -2
		END
	END
	ELSE
	BEGIN
		SELECT @DepID = DepID
		FROM Mo_Dep
		WHERE CompanyID = @CompanyID
			AND DepType = @DepType

		IF @DepID IS NULL
			SET @DepID = 0

		EXECUTE @DepID = IU_CRQ_Dep
			@ConnectID,
			@DepID,
			@CompanyID,
			@DepType,
			@Att,
			@InForce,
			@Address,
			@City,
			@StateName,
			@CountryID,
			@ZipCode,
			@Phone1,
			@Phone2,
			@Fax,
			@Mobile,
			@WattLine,
			@OtherTel,
			@Pager,
			@EMail,
			@Att2

		IF @DepID <= 0
		  SET @iResult = -3

		IF @iResult > 0
		BEGIN
			-- Mis à jour de la compagnie
			UPDATE Mo_Company SET
				CompanyName = @CompanyName,
				LangID = @LangID,
				WebSite = @WebSite,
				StateTaxNumber = @StateTaxNumber,
				CountryTaxNumber = @CountryTaxNumber,
				EndBusiness = @EndBusiness
			WHERE CompanyID = @CompanyID

			IF @@ERROR <> 0 
				SET @iResult = -4
		END

		IF @iResult > 0
		AND @LogDesc <> '' 
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Mo_Company', @CompanyID, 'U', @LogDesc;
  END
  RETURN @iResult
END

