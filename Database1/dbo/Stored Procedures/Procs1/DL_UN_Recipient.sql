/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                : 	DL_UN_Recipient
Description        : 	Procédure de suppression de destinataire
Valeurs de retours : 	@ReturnValue :
									> 0 : La suppression a réussie.  La valeur de retour correspond au iRecipientID du
											destinataire supprimé.
									<=0 : La suppression a échouée.
										-1 : Le destinataire est utilisé dans la proposition de modification de chèque pré-défini
										-2 : Le destinataire est utilisé dans une proposition de modification de chèque
Note                :	ADX0000754	IA	2005-10-04	Bruno Lapointe		Création
												2014-05-01	Pierre-Luc Simard	Retrait du log des téléphone Pager et Wattline
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_Recipient] (
	@ConnectID INTEGER, -- ID Unique de connexion
	@iRecipientID INTEGER ) -- ID du tuteur à supprimer, correspond au HumanID.
AS
BEGIN
	DECLARE
		@iResult INTEGER,
		@IsCompany BIT,
		-- Variable du caractère séparateur de valeur du blob
		@cSep CHAR(1)

	SET @cSep = CHAR(30)
	SET @iResult = @iRecipientID

	-----------------
	BEGIN TRANSACTION
	-----------------

	IF EXISTS (
		SELECT *
		FROM Un_ChqSuggestionMostUse
		WHERE iHumanID = @iRecipientID
		)
		SET @iResult = -1

	IF @iResult > 0
	AND EXISTS (
		SELECT *
		FROM Un_ChequeSuggestion
		WHERE iHumanID = @iRecipientID
		)
		SET @iResult = -2

	IF @iResult > 0
	BEGIN		
		-- Insère un log de l'objet supprimé.
		INSERT INTO CRQ_Log (
			ConnectID,
			LogTableName,
			LogCodeID,
			LogTime,
			LogActionID,
			LogDesc,
			LogText)
			SELECT
				@ConnectID,
				'Un_Recipient',
				@iRecipientID,
				GETDATE(),
				LA.LogActionID,
				LogDesc = 'Destinataire : ' + CASE H.IsCompany
									WHEN 0 THEN ISNULL(H.LastName,'') + ', '+ISNULL(H.FirstName,'')
									WHEN 1 THEN ISNULL(H.LastName,'')
								END,
				LogText =
					CASE 
						WHEN ISNULL(H.FirstName,'') = '' THEN ''
					ELSE 'FirstName'+@cSep+H.FirstName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.LastName,'') = '' THEN ''
					ELSE 'LastName'+@cSep+H.LastName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.OrigName,'') = '' THEN ''
					ELSE 'OrigName'+@cSep+H.OrigName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.Initial,'') = '' THEN ''
					ELSE 'Initial'+@cSep+H.Initial+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.BirthDate,0) <= 0 THEN ''
					ELSE 'BirthDate'+@cSep+CONVERT(CHAR(10), H.BirthDate, 20)+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.DeathDate,0) <= 0 THEN ''
					ELSE 'DeathDate'+@cSep+CONVERT(CHAR(10), H.DeathDate, 20)+@cSep+CHAR(13)+CHAR(10)
					END+
					'LangID'+@cSep+H.LangID+@cSep+L.LangName+@cSep+CHAR(13)+CHAR(10)+
					'SexID'+@cSep+H.SexID+@cSep+S.SexName+@cSep+CHAR(13)+CHAR(10)+
					'CivilID'+@cSep+H.CivilID+@cSep+CS.CivilStatusName+@cSep+CHAR(13)+CHAR(10)+
					CASE 
						WHEN ISNULL(H.SocialNumber,'') = '' THEN ''
					ELSE 'SocialNumber'+@cSep+H.SocialNumber+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.ResidID,'') = '' THEN ''
					ELSE 'ResidID'+@cSep+H.ResidID+@cSep+R.CountryName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.DriverLicenseNo,'') = '' THEN ''
					ELSE 'DriverLicenseNo'+@cSep+H.DriverLicenseNo+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.WebSite,'') = '' THEN ''
					ELSE 'WebSite'+@cSep+H.WebSite+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.CompanyName,'') = '' THEN ''
					ELSE 'CompanyName'+@cSep+H.CompanyName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(H.CourtesyTitle,'') = '' THEN ''
					ELSE 'CourtesyTitle'+@cSep+H.CourtesyTitle+@cSep+CHAR(13)+CHAR(10)
					END+
					'UsingSocialNumber'+@cSep+CAST(ISNULL(H.UsingSocialNumber,1) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(H.UsingSocialNumber,1) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					'SharePersonalInfo'+@cSep+CAST(ISNULL(H.SharePersonalInfo,1) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(H.SharePersonalInfo,1) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					'MarketingMaterial'+@cSep+CAST(ISNULL(H.MarketingMaterial,1) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(H.MarketingMaterial,1) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					'IsCompany'+@cSep+CAST(ISNULL(H.IsCompany,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(H.IsCompany,0) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					CASE 
						WHEN ISNULL(A.Address,'') = '' THEN ''
					ELSE 'Address'+@cSep+A.Address+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.City,'') = '' THEN ''
					ELSE 'City'+@cSep+A.City+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.StateName,'') = '' THEN ''
					ELSE 'StateName'+@cSep+A.StateName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.CountryID,'') = '' THEN ''
					ELSE 'CountryID'+@cSep+A.CountryID+@cSep+C.CountryName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.ZipCode,'') = '' THEN ''
					ELSE 'ZipCode'+@cSep+A.ZipCode+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.Phone1,'') = '' THEN ''
					ELSE 'Phone1'+@cSep+A.Phone1+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.Phone2,'') = '' THEN ''
					ELSE 'Phone2'+@cSep+A.Phone2+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.Fax,'') = '' THEN ''
					ELSE 'Fax'+@cSep+A.Fax+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(A.Mobile,'') = '' THEN ''
					ELSE 'Mobile'+@cSep+A.Mobile+@cSep+CHAR(13)+CHAR(10)
					END+/*
					CASE 
						WHEN ISNULL(A.WattLine,'') = '' THEN ''
					ELSE 'WattLine'+@cSep+A.WattLine+@cSep+CHAR(13)+CHAR(10)
					END+*/
					CASE 
						WHEN ISNULL(A.OtherTel,'') = '' THEN ''
					ELSE 'OtherTel'+@cSep+A.OtherTel+@cSep+CHAR(13)+CHAR(10)
					END+/*
					CASE 
						WHEN ISNULL(A.Pager,'') = '' THEN ''
					ELSE 'Pager'+@cSep+A.Pager+@cSep+CHAR(13)+CHAR(10)
					END+*/
					CASE 
						WHEN ISNULL(A.EMail,'') = '' THEN ''
					ELSE 'EMail'+@cSep+A.EMail+@cSep+CHAR(13)+CHAR(10)
					END
				FROM Un_Recipient T
				JOIN dbo.Mo_Human H ON H.HumanID = T.iRecipientID
				JOIN Mo_Lang L ON L.LangID = H.LangID
				JOIN Mo_Sex S ON S.LangID = H.LangID AND S.SexID = H.SexID
				JOIN Mo_CivilStatus CS ON CS.LangID = H.LangID AND CS.SexID = H.SexID AND CS.CivilStatusID = H.CivilID
				JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'D'
				LEFT JOIN Mo_Country R ON R.CountryID = H.ResidID
				LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
				LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
				WHERE T.iRecipientID = @iRecipientID

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	IF @iResult > 0
	BEGIN
		DELETE 
		FROM Un_Recipient
		WHERE iRecipientID = @iRecipientID

		IF @@ERROR <> 0
			SET @iResult = -4
	END

	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @iResult
END


