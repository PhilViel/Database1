
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas
Nom                 :	IU_CRQ_Dep
Description         :	Procédure de sauvegarde d’ajout ou modification de département dans une compagnie.
Valeurs de retours  :	@ReturnValue :
									> 0 : La sauvegarde a réussie.
									<= 0 : La sauvegarde a échouée
Note                :	ADX0000730	IA	2005-06-13	Bruno Lapointe		Création
						ADX0001159	IA	2007-02-12	Alain Quirion		Modification : Att2
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_CRQ_Dep (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@DepID INTEGER, -- Identifiant unique du département
	@CompanyID INTEGER, -- Identifiant unique de la compagnie
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
	@Email VARCHAR(100),  -- Courriel
	@Att2 VARCHAR(150))	--Contact #2
AS
BEGIN
	DECLARE
		@iResultID INTEGER,
		@AdrID MoIDOption,
		@AdrTypeID MoAdrType

	SET @iResultID = 1

	IF @CompanyID = 0
	OR @CompanyID IS NULL
		SET @iResultID = -1

	IF ISNULL(@DepID,0) <= 0 AND @iResultID > 0
	BEGIN
		INSERT INTO Mo_Dep (
			CompanyID,
			DepType,
			Att,
			Att2 )
		VALUES (
			@CompanyID,
			@DepType,
			@Att,
			@Att2 )

		IF @@ERROR = 0
		BEGIN
			SET @DepID = SCOPE_IDENTITY()
			SET @iResultID = @DepID
			SET @AdrID = 0
		END
		ELSE
	      SET @iResultID = -2
	END
	ELSE
	BEGIN
		UPDATE Mo_Dep SET
			CompanyID = @CompanyID,
			Att = @Att,
			Att2 = @Att2
		WHERE DepID = @DepID

		SELECT @AdrID = AdrID
		FROM Mo_Dep
		WHERE DepID = @DepID

		IF ISNULL(@AdrID,0) <=0
			SET @AdrID = 0
	END
	SET @AdrTypeID = 'C'

	-- Création de l'adresse
	EXECUTE @AdrID = SP_IU_CRQ_Adr
		@ConnectID,
		@AdrID,
		@InForce,
		@AdrTypeID,
		@DepID,
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
		@Email

	-- Si l'adresse n'a jamais été enregistrer dans le département
	IF @AdrID <> 0
	BEGIN
		UPDATE Mo_Dep SET
			AdrID = @AdrID
		WHERE DepID = @DepID

		IF @@ERROR <> 0
			SET @iResultID = -3
		ELSE
			SET @iResultID = @DepID
	END

	RETURN @iResultID
END

