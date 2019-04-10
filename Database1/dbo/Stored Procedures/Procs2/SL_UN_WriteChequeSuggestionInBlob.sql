/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_WriteChequeSuggestionInBlob
Description         :	Retourne l'objet Un_ChequeSuggestion correspondant au OperID dans le blob du pointeur @pBlob 
								ou le champs texte @vcBlob.
Valeurs de retours  :	Type d’objet traité être dans le blob :
									Un_ChequeSuggestion
										ChequeSuggestionID 	INTEGER
										OperID					INTEGER
										HumanID					INTEGER
										FirstName				VARCHAR (35)
										OrigName					VARCHAR (75)
										Initial					VARCHAR (4)
										LastName					VARCHAR (50)
										BirthDate				DATETIME
										DeathDate				DATETIME
										SexID						CHAR (1)
										LangID					CHAR (3)
										CivilID					CHAR (1)
										SocialNumber			VARCHAR (75)
										ResidID					CHAR (1)
										ResidName				VARCHAR (75)
										DriverLicenseNo		VARCHAR (75)
										WebSite					VARCHAR (75)
										CompanyName				VARCHAR (75)
										CourtesyTitle			VARCHAR (35)
										UsingSocialNumber		BIT
										SharePersonalInfo		BIT
										MarketingMaterial		BIT
										IsCompany				BIT
										InForce					DATETIME
										AdrTypeID				CHAR (1)
										SourceID					INTEGER
										Address					VARCHAR (75)
										City						VARCHAR (100)
										StateName				VARCHAR (75)
										CountryID				CHAR (4)
										CountryName				VARCHAR (75)
										ZipCode					VARCHAR (10)
										Phone1					VARCHAR (27)
										Phone2					VARCHAR (27)
										Fax						VARCHAR (15)
										Mobile					VARCHAR (15)
										WattLine					VARCHAR (27)
										OtherTel					VARCHAR (27)
										Pager						VARCHAR (15)
										Email						VARCHAR (100)
										SuggestionAccepted	BIT
								@ReturnValue :
									> 0 : Réussite
									<= 0 : Erreurs.
Note                :	ADX0000861	IA	2006-03-30	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_WriteChequeSuggestionInBlob] (
	@OperID INTEGER, -- ID de l’opération de proposition de modification de chèque
	@iBlobID INTEGER, -- ID du blob dans lequel on écrit
	@pBlob BINARY(16), -- Pointeur sur le blob
	@vcBlob VARCHAR(8000) OUTPUT, -- Contient le texte des objets à insérer dans le blob
	@iResult INTEGER OUTPUT ) -- Varible résultat
AS
BEGIN
	-- Un_ChequeSuggestion;ChequeSuggestionID;OperID;HumanID;FirstName;OrigName;Initial;LastName;BirthDate;DeathDate;SexID;LangID;CivilID;SocialNumber;ResidID;ResidName;DriverLicenseNo;WebSite;CompanyName;CourtesyTitle;UsingSocialNumber;SharePersonalInfo;MarketingMaterial;IsCompany;InForce;AdrTypeID;SourceID;Address;City;StateName;CountryID;CountryName;ZipCode;Phone1;Phone2;Fax;Mobile;WattLine;OtherTel;Pager;Email;SuggestionAccepted;

	-- Inscrit le détail des objets d'opérations (Un_OperCancelation)
	DECLARE
		-- Variable de l'objet de lien d'annulation
		@OperSourceID INTEGER

	-- Traite les liens d'annulation
	IF EXISTS (
			SELECT OperID
			FROM Un_ChequeSuggestion
			WHERE OperID = @OperID) AND
		(@iResult > 0)
	BEGIN
		-- Si Il n'y pas assez d'espace disponible dans la variable, on inscrit le contenu de la variable dans le blob et on vide la variable par la suite
		IF LEN(@vcBlob) > 7000
		BEGIN
			DECLARE
				@iBlobLength INTEGER

			SELECT @iBlobLength = DATALENGTH(txBlob)
			FROM CRI_Blob
			WHERE iBlobID = @iBlobID

			UPDATETEXT CRI_Blob.txBlob @pBlob @iBlobLength 0 @vcBlob 

			IF @@ERROR <> 0
				SET @iResult = -11

			SET @vcBlob = ''
		END

		-- Inscrit la proposition de modification de chèque dans le blob
		-- Un_ChequeSuggestion;ChequeSuggestionID;OperID;HumanID;FirstName;OrigName;Initial;LastName;BirthDate;DeathDate;SexID;LangID;CivilID;SocialNumber;ResidID;ResidName;DriverLicenseNo;WebSite;CompanyName;CourtesyTitle;UsingSocialNumber;SharePersonalInfo;MarketingMaterial;IsCompany;InForce;AdrTypeID;SourceID;Address;City;StateName;CountryID;CountryName;ZipCode;Phone1;Phone2;Fax;Mobile;WattLine;OtherTel;Pager;Email;SuggestionAccepted;
		SELECT
			@vcBlob = 
				@vcBlob +
				'Un_ChequeSuggestion;'+
				CAST(CS.ChequeSuggestionID AS VARCHAR)+';'+
				CAST(@OperID AS VARCHAR)+';'+
				CAST(CS.iHumanID AS VARCHAR)+';'+
				ISNULL(H.FirstName,'')+';'+
				ISNULL(H.OrigName,'')+';'+
				ISNULL(H.Initial,'')+';'+
				ISNULL(H.LastName,'')+';'+
				LTRIM(ISNULL(CONVERT(CHAR(10), dbo.FN_CRQ_IsDateNull(H.BirthDate), 20),''))+';'+
				LTRIM(ISNULL(CONVERT(CHAR(10), dbo.FN_CRQ_IsDateNull(H.DeathDate), 20),''))+';'+
				H.SexID+';'+
				H.LangID+';'+
				H.CivilID+';'+
				ISNULL(H.SocialNumber,'')+';'+
				LTRIM(ISNULL(H.ResidID,''))+';'+
				ISNULL(R.CountryName,'')+';'+
				ISNULL(H.DriverLicenseNo,'')+';'+
				ISNULL(H.WebSite,'')+';'+
				ISNULL(H.CompanyName,'')+';'+
				ISNULL(H.CourtesyTitle,'')+';'+
				CAST(H.UsingSocialNumber AS VARCHAR)+';'+
				CAST(H.SharePersonalInfo AS VARCHAR)+';'+
				CAST(H.MarketingMaterial AS VARCHAR)+';'+
				CAST(H.IsCompany AS VARCHAR)+';'+
				LTRIM(ISNULL(CONVERT(CHAR(10), dbo.FN_CRQ_IsDateNull(A.InForce), 20),''))+';'+
				LTRIM(ISNULL(A.AdrTypeID,''))+';'+
				CAST(ISNULL(A.SourceID,0) AS VARCHAR)+';'+
				ISNULL(A.Address,'')+';'+
				ISNULL(A.City,'')+';'+
				ISNULL(A.StateName,'')+';'+
				LTRIM(ISNULL(A.CountryID,''))+';'+
				ISNULL(C.CountryName,'')+';'+
				ISNULL(A.ZipCode,'')+';'+
				dbo.fn_Mo_FormatPhoneNo(A.Phone1, A.CountryID)+';'+
				dbo.fn_Mo_FormatPhoneNo(A.Phone2, A.CountryID)+';'+
				dbo.fn_Mo_FormatPhoneNo(A.Fax, A.CountryID)+';'+
				dbo.fn_Mo_FormatPhoneNo(A.Mobile, A.CountryID)+';'+
				dbo.fn_Mo_FormatPhoneNo(A.WattLine, A.CountryID)+';'+
				dbo.fn_Mo_FormatPhoneNo(A.OtherTel, A.CountryID)+';'+
				dbo.fn_Mo_FormatPhoneNo(A.Pager, A.CountryID)+';'+
				ISNULL(A.EMail,'')+';'+
				CAST(CS.SuggestionAccepted AS VARCHAR)+';'+CHAR(13)+CHAR(10)
		FROM Un_ChequeSuggestion CS
		JOIN dbo.Mo_Human H ON H.HumanID = CS.iHumanID
		LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
		LEFT JOIN Mo_Country R ON R.CountryID = H.ResidID
		LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
		WHERE CS.OperID = @OperID
	END

	RETURN @iResult
END


