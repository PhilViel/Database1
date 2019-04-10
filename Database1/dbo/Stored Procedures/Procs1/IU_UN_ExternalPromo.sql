
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas
Nom                 :	IU_UN_ExternalPromo
Description         :	Procédure qui renvoi la liste des promoteurs externes
Valeurs de retours  :	Dataset :
							ExternalPromoID		INTEGER			ID du promoteur externe
							CompanyName			VARCHAR(75)		Nom du promoteur externe
							LangID				CHAR(3)			ID de la langue
							WebSite				VARCHAR(75)		Site web du promoteur
							EndBusiness			DATETIME		Date de fermeture du promoteur externe
							AdrID				INTEGER			ID de l’adresse du promoteur
							CountryID			INTEGER			ID du pays
							AdrTypeID			INTEGER			ID du type d’adresse
							Address				VARCHAR(75)		Adresse du promoteur
							City				VARCHAR(100)	Ville
							StateName			VARCHAR(75)		État/Province
							ZipCode				VARCHAR(10)		Code postal ou zip code
							Phone1 				VARCHAR(27)		Premier téléphone
							Phone2				VARCHAR(27)		Second téléphone
							Fax					VARCHAR(15)		Fax
							Mobile				VARCHAR(15)		Cellulaire
							WattLine			VARCHAR(27)	
							OtherTel			VARCHAR(27)		Autre téléphone
							Pager				VARCHAR(15)		Paget
							Email				VARCHAR(100)	Courriel
							Att					VARCHAR(75)		Nom du premier contact
							Att2				VARCHAR(75)		Nom du second contact
				
Note                :	ADX0001159	IA	2007-02-09	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_ExternalPromo(
	@ConnectID INTEGER,				-- ID de connexion
	@ExternalPromoID INTEGER,		--	ID du promoteur externe (<=0 Insertion)
	@CompanyName VARCHAR(75),		--	Nom du promoteur externe
	@LangID	CHAR(3),				--	ID de la langue
	@WebSite VARCHAR(75),			--	Site web
	@EndBusiness DATETIME,			--	Date de fermeture du promoteur externe
	@AdrID INTEGER,					--	ID de l’adresse du promoteur
	@CountryID CHAR(3),				--	ID du pays
	@AdrTypeID CHAR(1),				--	ID du type d’adresse
	@Address VARCHAR(75),			--	Adresse du promoteur
	@City VARCHAR(100),				--	Ville
	@StateName VARCHAR(75),			--	État/Province
	@ZipCode VARCHAR(10),			--	Code postal ou zip code
	@Phone1 VARCHAR(27),			--	Premier téléphone
	@Phone2	VARCHAR(27),			--	Second téléphone
	@Fax VARCHAR(15),				--	Fax
	@Mobile	VARCHAR(15),			--	Cellulaire
	@WattLine VARCHAR(27),			--	Numéro sans frais
	@OtherTel VARCHAR(27),			--	Autre téléphone
	@Pager VARCHAR(15),				--	Téléavertisseur
	@Email VARCHAR(100),			--	Courriel
	@Att VARCHAR(150),				--	Nom du premier contact
	@Att2 VARCHAR(150))				--	Nom du second contact
AS
BEGIN
	DECLARE @iResult INTEGER,
			@Today DATETIME,
			@DepType CHAR(1)

	SET @Today = dbo.FN_CRQ_DateNoTime(GETDATE())

	SET @iResult = 1

	BEGIN TRANSACTION

	IF @ExternalPromoID > 0
		SELECT TOP 1 @DepType = ISNULL(DepType,'U')
		FROM Mo_Dep D
		JOIN Un_ExternalPromo EP ON EP.ExternalPromoID = D.CompanyID
		WHERE EP.ExternalPromoID = @ExternalPromoID
	ELSE 
		SET @DepType = 'U'
	
	--Insertion ou mise à jour de la compagnie et du département
	EXECUTE @ExternalPromoID = IU_CRQ_Company
									@ConnectID,
									@ExternalPromoID,
									@CompanyName,
									@LangID, 
									@WebSite,
									NULL,
									NULL,
									@EndBusiness,
									@DepType,
									@Att,
									@Today,
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

	IF @ExternalPromoID <= 0
		SET @iResult = -1
		
	IF NOT EXISTS(	SELECT * 
					FROM Un_ExternalPromo 
					WHERE ExternalPromoID = @ExternalPromoID)
			AND @iResult > 0
	BEGIN
			INSERT INTO Un_ExternalPromo(ExternalPromoID)
			VALUES(@ExternalPromoID)

			IF @@ERROR <> 0
				SET @iResult = -2
			ELSE 
				SET @iResult = @ExternalPromoID			
	END
	ELSE IF @iResult > 0
	BEGIN
		SET @iResult = @ExternalPromoID
	END 

	IF @iResult > 0
		COMMIT TRANSACTION
	ELSE
		ROLLBACK TRANSACTION

	RETURN @iResult
END

