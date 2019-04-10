/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	psGENE_MAJDernierChangementAdresse
Description 	:	Sauvegarde d'ajout ou de mise à jour d'adresse.	
exec psGENE_MAJDernierChangementAdresse '2011-01-01','H',606191,'sfgsdf','Beauport,Québec','QC','CAN'

Notes :			2011-11-23	Eric Michaud	Création
*******************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_MAJDernierChangementAdresse] (
	@InForce DATETIME,
	@AdrTypeID CHAR(1),
	@SourceID INTEGER,
	@Address VARCHAR(75) = NULL,
	@City VARCHAR(100) = NULL,
	@StateName VARCHAR(75) = NULL,
	@CountryID CHAR(4) = NULL,
	@ZipCode VARCHAR(10) = NULL,
	@Phone1 VARCHAR(27) = NULL,
	@Phone2 VARCHAR(27) = NULL,
	@Mobile VARCHAR(27) = NULL,
	@SourceModifID INTEGER)
AS
BEGIN
	DECLARE
		@DateNull DATETIME,
--		@OldInForce DATETIME,
--		@OldAddress VARCHAR(75),
--		@OldCity VARCHAR(75),
--		@OldStateName VARCHAR(75),
--		@OldCountryID CHAR(4),
--		@OldZipCode VARCHAR(10),
--		@OldPhone1 VARCHAR(27),
--		@OldPhone2 VARCHAR(27),
		@OldFax VARCHAR(15),
--		@OldMobile VARCHAR(27),
		@OldWattLine VARCHAR(27),
		@OldOtherTel VARCHAR(27),
		@OldPager VARCHAR(15),
		@OldEMail VARCHAR(100),
		@Fax VARCHAR(15),
		@WattLine VARCHAR(27),
		@OtherTel VARCHAR(27),
		@Pager VARCHAR(15),
		@EMail VARCHAR(100)
	
	-- Met les valeurs
	SET @Phone1 = dbo.FN_CRQ_GetNumberOfStringOnly(@Phone1)
	SET @Phone2 = dbo.FN_CRQ_GetNumberOfStringOnly(@Phone2)
	SET @Mobile = dbo.FN_CRQ_GetNumberOfStringOnly(@Mobile)

	IF RTRIM(@StateName) = ''
		SET @StateName = NULL

	IF RTRIM(@City) = ''
		SET @City = NULL

	SELECT distinct
--		@OldAddress = Address,
--		@OldCity = City,
--		@OldStateName = StateName,
--		@OldCountryID = CountryID,
--		@OldZipCode = ZipCode,
--		@OldPhone1 = Phone1,
--		@OldPhone2 = Phone2,
		@OldFax = Fax,
--		@OldMobile = Mobile,
		@OldWattLine = WattLine,
		@OldOtherTel = OtherTel,
		@OldPager = Pager,
		@OldEMail = EMail
	FROM dbo.Mo_Adr 
	WHERE AdrID = (	SELECT DISTINCT max(ad.adrID)
					FROM dbo.mo_Human Hu 
						left JOIN dbo.Mo_Adr  ad on hu.humanId = ad.sourceID
					WHERE hu.humanId = @SourceID 
						AND ad.InForce = (SELECT distinct max(ad.InForce)
											FROM dbo.mo_Human Hu 
											left JOIN dbo.Mo_Adr  ad on hu.humanId = ad.sourceID
											WHERE  hu.humanId = @SourceID))

--	IF LTRIM(RTRIM(ISNULL(@Address, ''))) = '' 
--	BEGIN
--		SET @Address = @OldAddress
--		SET @StateName = @OldStateName
--	END
--	IF LTRIM(RTRIM(ISNULL(@StateName, ''))) = '' 
--		SET @StateName = @OldStateName

--	IF LTRIM(RTRIM(ISNULL(@City, ''))) = '' SET @City = @OldCity
--	IF LTRIM(RTRIM(ISNULL(@CountryID, ''))) = '' SET @CountryID = @OldCountryID
--	IF LTRIM(RTRIM(ISNULL(@ZipCode, ''))) = '' SET @ZipCode = @OldZipCode
--	IF LTRIM(RTRIM(ISNULL(@Phone1, ''))) = '' SET @Phone1 = @OldPhone1
--	IF LTRIM(RTRIM(ISNULL(@Phone2, ''))) = '' SET @Phone2 = @OldPhone2
	IF LTRIM(RTRIM(ISNULL(@Fax, ''))) = '' SET @Fax = @OldFax
--	IF LTRIM(RTRIM(ISNULL(@Mobile, ''))) = '' SET @Mobile = @OldMobile
	IF LTRIM(RTRIM(ISNULL(@WattLine, ''))) = '' SET @WattLine = @OldWattLine
	IF LTRIM(RTRIM(ISNULL(@OtherTel, ''))) = '' SET @OtherTel = @OldOtherTel
	IF LTRIM(RTRIM(ISNULL(@Pager, ''))) = '' SET @Pager = @OldPager
	IF LTRIM(RTRIM(ISNULL(@EMail, ''))) = '' SET @EMail = @OldEMail
		
	------------------------------------------------------------------------
	-- Recherche d'une fusion existante pour le nom de ville en paramètre --
	------------------------------------------------------------------------
/*	IF EXISTS (
			SELECT *
			FROM Mo_CityFusion F
			LEFT JOIN Mo_State S ON S.StateID = F.StateID
			JOIN Mo_City C ON C.CityID = F.CityID
			WHERE F.OldCityName = @City
			  AND C.CountryID = @CountryID			 
			  AND ISNULL(S.StateName,'') = ISNULL(@StateName,''))
	BEGIN
		SELECT 
			@City = C.CityName
		FROM Mo_CityFusion F
		LEFT JOIN Mo_State S ON S.StateID = F.StateID
		JOIN Mo_City C ON C.CityID = F.CityID		
		WHERE F.OldCityName = @City
			AND C.CountryID = @CountryID	
			AND ISNULL(S.StateName,'') = ISNULL(@StateName,'')
	END*/

	DECLARE @iID_Utilisateur_Systeme INT
	SELECT TOP 1 @iID_Utilisateur_Systeme = CASE WHEN S.SubscriberID IS NOT NULL THEN MCS.ConnectID ELSE MCb.ConnectID END
	FROM dbo.Mo_Human H
			LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
			LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
			JOIN tblGENE_TypesParametre TPS ON TPS.vcCode_Type_Parametre = 'GENE_AUTHENTIFICATION_SOUSC_CONNECTID' 
			JOIN tblGENE_Parametres PS ON TPS.iID_Type_Parametre = PS.iID_Type_Parametre
			JOIN tblGENE_TypesParametre TPB ON TPB.vcCode_Type_Parametre = 'GENE_AUTHENTIFICATION_BENEF_CONNECTID'
			JOIN tblGENE_Parametres PB ON TPB.iID_Type_Parametre = PB.iID_Type_Parametre
			JOIN Mo_Connect MCS ON PS.vcValeur_Parametre = MCS.ConnectID
			JOIN Mo_Connect MCB ON PB.vcValeur_Parametre = MCB.ConnectID
	WHERE H.HumanID = @SourceModifID

	--IF datediff(dd,GETDATE(),@InForce) >= 1 
	DELETE
	FROM dbo.Mo_Adr  
	WHERE SourceID = @SourceID AND
--		 datediff(dd,getdate(),InForce) >= 0
		 datediff(dd,dateadd(dd,1,getdate()),InForce) >= 0

	INSERT INTO dbo.Mo_Adr  (
		InForce,
		AdrTypeID,
		SourceID,
		Address,
		City,
		StateName,
		CountryID,
		ZipCode,
		Phone1,
		Phone2,
		Fax,
		Mobile,
		WattLine,
		OtherTel,
		Pager,
		EMail,
		ConnectID)
	VALUES (
		@InForce,
		@AdrTypeID,
		@SourceID,
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
		@iID_Utilisateur_Systeme)

/*	SELECT InForce = @InForce,
		AdrTypeID = @AdrTypeID,
		SourceID = @SourceID,
		Address = @Address,
		City = @City,
		StateName = @StateName,
		CountryID = @CountryID,
		ZipCode = @ZipCode,
		Phone1 = @Phone1,
		Phone2 = @Phone2,
		Fax = @Fax,
		Mobile = @Mobile,
		WattLine = @WattLine,
		OtherTel = @OtherTel,
		Pager = @Pager,
		EMail = @EMail
		
	IF @@ERROR = 0
		RETURN IDENT_CURRENT('Mo_Adr')
	ELSE
		RETURN 0*/

	IF datediff(dd,@InForce,GETDATE()) = 0 
		exec SP_TT_CRQ_PostDatedAddress	@SourceID
		
END


