/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                : 	DL_UN_Rep
Description        : 	Suppression de représentant
Valeurs de retours : 	>0  : Tout à fonctionné
                      	<=0 : Erreur SQL
									-1 : 	Erreur à la création du log
									-2 : 	Erreur à la suppression du représentant
									-3 : 	Le représentant ne doit avoir ni clients ni ventes.
									-4 : 	Le représentant ne doit pas avoir reçu des avances, avances spéciales, 
											des commissions ou des bonis. 
									-5 : 	Le représentant ne doit pas avoir d’ajustements.
									-6 : 	Le représentant ne doit pas avoir d’historique de supérieurs ou de niveaux.
									-7 : 	Le représentant ne doit pas avoir d’exception sur commissions.
Note                :	ADX0000697	IA	2005-05-05	Bruno Lapointe		Création
								ADX0001697	BR	2005-10-31	Bruno Lapointe			-5 = Erreur d'ajustements.
														2014-03-06	Pierre-Luc Simard		Retrait du log des téléphone Pager et Wattline
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_Rep] (
	@ConnectID INTEGER, -- ID Unique de connexion
	@RepID INTEGER ) -- ID du représentant à supprimer, correspond au HumanID.
AS
BEGIN
	DECLARE
		@iResult INTEGER,
		-- Variable du caractère séparateur de valeur du blob
		@cSep CHAR(1)

	SET @cSep = CHAR(30)
	SET @iResult = @RepID

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- -3 : 	Le représentant ne doit avoir ni clients ni ventes
	IF @iResult > 0
	AND EXISTS (
		SELECT SubscriberID
		FROM dbo.Un_Subscriber 
		WHERE RepID = @RepID
		UNION
		SELECT UnitID
		FROM dbo.Un_Unit 
		WHERE RepID = @RepID
			OR RepResponsableID = @RepID
		)
		SET @iResult = -3

	-- -4 : 	Le représentant ne doit pas avoir reçu des avances, avances spéciales, des commissions ou des bonis.
	IF @iResult > 0
	AND EXISTS (
		SELECT RepID
		FROM Un_RepCommission
		WHERE RepID = @RepID
		UNION
		SELECT RepID
		FROM Un_RepBusinessBonus
		WHERE RepID = @RepID
		UNION
		SELECT RepID
		FROM Un_SpecialAdvance
		WHERE RepID = @RepID
		)
		SET @iResult = -4

	-- -5 : 	Le représentant ne doit pas avoir d’ajustements.
	IF @iResult > 0
	AND EXISTS (
		SELECT RepID
		FROM Un_RepCharge
		WHERE RepID = @RepID
		)
		SET @iResult = -5

	-- -6 : 	Le représentant ne doit pas avoir d’historique de supérieurs ou de niveaux.
	IF @iResult > 0
	AND EXISTS (
		SELECT RepID
		FROM Un_RepLevelHist
		WHERE RepID = @RepID
		UNION
		SELECT RepID
		FROM Un_RepBossHist
		WHERE RepID = @RepID
		)
		SET @iResult = -6

	-- -7 : 	Le représentant ne doit pas avoir d’exception sur commissions.
	IF @iResult > 0
	AND EXISTS (
		SELECT RepID
		FROM Un_RepException
		WHERE RepID = @RepID
		)
		SET @iResult = -7

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
				'Un_Rep',
				@RepID,
				GETDATE(),
				LA.LogActionID,
				LogDesc = 'Représentant : '+H.LastName+', '+H.FirstName,
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
					'ResidID'+@cSep+H.ResidID+@cSep+Re.CountryName+@cSep+CHAR(13)+CHAR(10)+
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
					END+
					CASE 
						WHEN ISNULL(R.RepCode,'') = '' THEN ''
					ELSE 'RepCode'+@cSep+R.RepCode+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(R.RepLicenseNo,'') = '' THEN ''
					ELSE 'RepLicenseNo'+@cSep+R.RepLicenseNo+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(R.BusinessStart,0) <= 0 THEN ''
					ELSE 'BusinessStart'+@cSep+CONVERT(CHAR(10), R.BusinessStart, 20)+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(R.BusinessEnd,0) <= 0 THEN ''
					ELSE 'BusinessEnd'+@cSep+CONVERT(CHAR(10), R.BusinessEnd, 20)+@cSep+CHAR(13)+CHAR(10)
					END
				FROM Un_Rep R
				JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
				JOIN Mo_Lang L ON L.LangID = H.LangID
				JOIN Mo_Sex S ON S.LangID = H.LangID AND S.SexID = H.SexID
				JOIN Mo_CivilStatus CS ON CS.LangID = H.LangID AND CS.SexID = H.SexID AND CS.CivilStatusID = H.CivilID
				JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'D'
				JOIN Mo_Country Re ON Re.CountryID = H.ResidID
				LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
				LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
				WHERE R.RepID = @RepID

		IF @@ERROR <> 0
			SET @iResult = -1
	END

	IF @iResult > 0
	BEGIN
		DELETE 
		FROM Un_Rep
		WHERE RepID = @RepID

		IF @@ERROR <> 0
			SET @iResult = -2
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


