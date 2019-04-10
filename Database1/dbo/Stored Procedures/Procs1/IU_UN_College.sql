
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_College
Description         :	Procédure de sauvegarde d’ajout ou modification d’établissement d’enseignement.
Valeurs de retours  :	@ReturnValue :
									> 0 : La sauvegarde a réussie.
									<= 0 : La sauvegarde a échouée
Note                :	ADX0000730	IA	2005-06-13	Bruno Lapointe		Création
						ADX0001159	IA	2007-02-12	Alain Quirion		Modification : Att2
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_College (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@CollegeID INTEGER, -- Identifiant unique du collège
	@CollegeTypeID CHAR(2), -- Type de collège : 01 = Université, 02 = Cégep/Collège communautaire, 03 = Établissement privé, 04 = Autre.
	@EligibilityConditionID CHAR(3), -- Condition d’éligibilité aux bourses : 'UNK'=Inconnu, 'YEA'=Années, 'CRS'=Cours, 'CDT'=Crédits, 'SES'=Sessions, '3MT’=Trimestres/crédits
	@CollegeCode VARCHAR(75), -- Code désignant l’établissement
	@iSectorID INTEGER, -- ID du secteur.
	@iRegionID INTEGER, -- ID de la région.
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
	-----------------
	BEGIN TRANSACTION
	-----------------

	IF ISNULL(@DepType,'') = ''
		SET @DepType = 'A'

	IF ISNULL(@iSectorID,0) <= 0 
		SET @iSectorID = NULL
	IF ISNULL(@iRegionID,0) <= 0 
		SET @iRegionID = NULL

	EXECUTE @CollegeID = IU_CRQ_Company
		@ConnectID,
		@CollegeID,
		@CompanyName,
		@LangID, 
		@WebSite,
		@StateTaxNumber,
		@CountryTaxNumber,
		@EndBusiness,
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
		@Email,
		@Att2

	IF @CollegeID > 0
	BEGIN
		IF NOT EXISTS (
			SELECT
				CollegeID
			FROM Un_College 
			WHERE CollegeID = @CollegeID )
		BEGIN
			INSERT INTO Un_College (
				CollegeID,
				CollegeTypeID,
				EligibilityConditionID,
				CollegeCode,
				iSectorID,
				iRegionID )
			VALUES (
				@CollegeID,
				@CollegeTypeID,
				@EligibilityConditionID,
				@CollegeCode,
				@iSectorID, -- ID du secteur.
				@iRegionID) -- ID de la région.
  
			IF @@ERROR = 0
				EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_College', @CollegeID, 'I', ''
			ELSE
				SET @CollegeID = -1
		END
		ELSE
		BEGIN
			UPDATE Un_College SET
				CollegeID = @CollegeID,
				CollegeTypeID = @CollegeTypeID,
				EligibilityConditionID = @EligibilityConditionID,
				CollegeCode = @CollegeCode,
				iSectorID = @iSectorID,
				iRegionID = @iRegionID
			WHERE CollegeID = @CollegeID

			IF @@ERROR = 0
				EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_College', @CollegeID, 'U',''
			ELSE
				SET @CollegeID = -2
		END
	END

	IF @CollegeID > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @CollegeID
END

