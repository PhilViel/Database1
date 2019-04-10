
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_Bank
Description         :	Procédure de sauvegarde d’ajout ou modification de succursale.
Valeurs de retours  :	@ReturnValue :
									>0 :	La sauvegarde a réussie.  La valeur de retour correspond au BankID de la succursale
											sauvegardée.
									<=0 :	La sauvegarde a échouée.
Note                :	ADX0000721	IA	2005-07-08	Bruno Lapointe		Création
						ADX0001159	IA	2007-02-12	Alain Quirion		Modification : Att2
						glpi 8692		2012-12-06	Donald Huppé		Forcer @DepType = 'A' quand une adresse fournie
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_Bank] (
	@ConnectID INTEGER, -- Identifiant unique de la connexion de l’usager.	
	@BankID INTEGER, -- ID unique de la succursale.
	@BankTypeID INTEGER, -- ID unique de l’institution financière.
	@BankTransit VARCHAR(75), -- Transit de la succursale.
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
	@EMail VARCHAR(100)) -- Courriel
AS
BEGIN
	-----------------
	BEGIN TRANSACTION
	-----------------

	IF ISNULL(@DepType,'') = '' 
		OR ISNULL(@Address,'') <> '' -- Uniaccès passe @DepType = 'U' lors de la mise à jour d'une adresse de banque.  Au lieu de corriger uniaccès, j'adapte la sp pour mettre A quand une adresse est passée en paramètre
		SET @DepType = 'A'

	EXECUTE @BankID = IU_CRQ_Company
		@ConnectID,
		@BankID,
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
		@EMail,
		''

	IF @BankID > 0
	BEGIN
		IF NOT EXISTS (
			SELECT
				BankID
			FROM Mo_Bank 
			WHERE BankID = @BankID )
		BEGIN
			INSERT INTO Mo_Bank (
				BankID,
				BankTypeID,
				BankTransit )
			VALUES (
				@BankID,
				@BankTypeID,
				@BankTransit) -- ID de la région.
  
			IF @@ERROR = 0
				EXECUTE SP_IU_CRQ_Log @ConnectID, 'Mo_Bank', @BankID, 'I', ''
			ELSE
				SET @BankID = -1
		END
		ELSE
		BEGIN
			UPDATE Mo_Bank SET
				BankID = @BankID,
				BankTypeID = @BankTypeID,
				BankTransit = @BankTransit
			WHERE BankID = @BankID

			IF @@ERROR = 0
				EXECUTE SP_IU_CRQ_Log @ConnectID, 'Mo_Bank', @BankID, 'U',''
			ELSE
				SET @BankID = -2
		END
	END

	IF @BankID > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @BankID
END

