/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 : SP_IU_CRQ_User
Description         : Sauvegarde d'ajouts/modifications d'usagers
Valeurs de retours  : >0  :	Tout à fonctionné
                      <=0 :	Erreur SQL
								-1 : 	Erreur à l'insertion du l'humain et de l'adresse
								-2 : 	Le nom d'usager est déjà utilisé
								-3 : 	Erreur à l'insertion de l'usager
								-4 : 	Erreur à la mise à jour de l'usager
								-5 : 	Erreur à l'insertion lors de la création du log
								-6 : 	Erreur à la mise à jour lors de la création du log
Note                : ADX0000591 IA 2004-11-22	Bruno Lapointe			Création
												2014-03-06	Pierre-Luc Simard		Retrait du log des téléphone Pager et Wattline
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_CRQ_User](
	@ConnectID MoID,
	@UserID MoID,
	@FirstName MoFirstName,
	@OrigName MoDescOption,
	@Initial MoInitial,
	@LastName MoLastName,
	@BirthDate MoDateOption,
	@DeathDate MoDateOption,
	@SexID MoSex,
	@LangID MoLang,
	@CivilID MoCivil,
	@SocialNumber MoDescOption,
	@ResidID MoCountry,
	@DriverLicenseNo MoDescOption,
	@WebSite MoDescOption,
	@CompanyName MoDescOption,
	@CourtesyTitle MoFirstNameOption,
	@UsingSocialNumber MoBitTrue,
	@SharePersonalInfo MoBitTrue,
	@MarketingMaterial MoBitTrue,
	@IsCompany MoBitFalse,
	@InForce MoDate,
	@Address MoAdress = NULL,
	@City MoCity = NULL,
	@StateName MoDescOption = NULL,
	@CountryID MoCountry = NULL,
	@ZipCode MoZipCode = NULL,
	@Phone1 MoPhoneExt = NULL,
	@Phone2 MoPhoneExt = NULL,
	@Fax MoPhone = NULL,
	@Mobile MoPhone = NULL,
	@WattLine MoPhoneExt = NULL,
	@OtherTel MoPhoneExt = NULL,
	@Pager MoPhone = NULL,
	@EMail MoEmail = NULL,
	@TerminatedDate MoDateOption,
	@LoginNameID MoLoginName,
	@PassWordID MoLoginName,
	@CodeID MoIDOption)
AS
BEGIN
	DECLARE
		-- Variables contenant les anciennes valeurs pour le log
		@iOldUserID MoID,
		@vcOldFirstName MoFirstName,
		@vcOldOrigName MoDescOption,
		@vcOldInitial MoInitial,
		@vcOldLastName MoLastName,
		@dtOldBirthDate MoDateOption,
		@dtOldDeathDate MoDateOption,
		@cOldSexID MoSex,
		@cOldLangID MoLang,
		@cOldCivilID MoCivil,
		@vcOldSocialNumber MoDescOption,
		@cOldResidID MoCountry,
		@vcOldDriverLicenseNo MoDescOption,
		@vcOldWebSite MoDescOption,
		@vcOldCompanyName MoDescOption,
		@vcOldCourtesyTitle MoFirstNameOption,
		@bOldUsingSocialNumber MoBitTrue,
		@bOldSharePersonalInfo MoBitTrue,
		@bOldMarketingMaterial MoBitTrue,
		@bOldIsCompany MoBitFalse,
		@dtOldInForce MoDate,
		@vcOldAddress MoAdress,
		@vcOldCity MoCity,
		@vcOldStateName MoDescOption,
		@cOldCountryID MoCountry,
		@vcOldZipCode MoZipCode,
		@vcOldPhone1 MoPhoneExt,
		@vcOldPhone2 MoPhoneExt,
		@vcOldFax MoPhone,
		@vcOldMobile MoPhone,
		@vcOldWattLine MoPhoneExt,
		@vcOldOtherTel MoPhoneExt,
		@vcOldPager MoPhone,
		@vcOldEMail MoEmail,
		@dtOldTerminatedDate MoDateOption,
		@vcOldLoginNameID MoLoginName,
		@vcOldPassWordID MoLoginName,
		@iOldCodeID MoIDOption,
		-- Variable du caractère séparateur de valeur du blob
		@cSep CHAR(1)
	
	SET @cSep = CHAR(30)

	SET @LoginNameID = RTRIM(LOWER(@LoginNameID))
	SET @PassWordID = RTRIM(LOWER(@PassWordID))

	IF @TerminatedDate <= 0
		SET @TerminatedDate = NULL

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- Va chercher les anciennes valeurs s'il y en a
	SELECT
		@iOldUserID = U.UserID,
		@vcOldFirstName = H.FirstName,
		@vcOldOrigName = H.OrigName,
		@vcOldInitial = H.Initial,
		@vcOldLastName = H.LastName,
		@dtOldBirthDate = H.BirthDate,
		@dtOldDeathDate = H.DeathDate,
		@cOldSexID = H.SexID,
		@cOldLangID = H.LangID,
		@cOldCivilID = H.CivilID,
		@vcOldSocialNumber = H.SocialNumber,
		@cOldResidID = H.ResidID,
		@vcOldDriverLicenseNo = H.DriverLicenseNo,
		@vcOldWebSite = H.WebSite,
		@vcOldCompanyName = H.CompanyName,
		@vcOldCourtesyTitle = H.CourtesyTitle,
		@bOldUsingSocialNumber = H.UsingSocialNumber,
		@bOldSharePersonalInfo = H.SharePersonalInfo,
		@bOldMarketingMaterial = H.MarketingMaterial,
		@bOldIsCompany = H.IsCompany,
		@dtOldInForce = A.InForce,
		@vcOldAddress = A.Address,
		@vcOldCity = A.City,
		@vcOldStateName = A.StateName,
		@cOldCountryID = A.CountryID,
		@vcOldZipCode = A.ZipCode,
		@vcOldPhone1 = A.Phone1,
		@vcOldPhone2 = A.Phone2,
		@vcOldFax = A.Fax,
		@vcOldMobile = A.Mobile,
		@vcOldWattLine = A.WattLine,
		@vcOldOtherTel = A.OtherTel,
		@vcOldPager = A.Pager,
		@vcOldEMail = A.EMail,
		@dtOldTerminatedDate = U.TerminatedDate,
		@vcOldLoginNameID = U.LoginNameID,
		@vcOldPassWordID = U.PassWordID,
		@iOldCodeID = U.CodeID
	FROM Mo_User U
	JOIN dbo.Mo_Human H ON H.HumanID = U.UserID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	WHERE U.UserID = @UserID
	  AND (	@UserID > 0 
			)

	-- Création de l'Mo_Human et l'Mo_Adresse
	EXECUTE @UserID = SP_IU_CRQ_Human
		@ConnectID,
		@UserID,
		@FirstName,
		@OrigName,
		@Initial,
		@LastName,
		@BirthDate,
		@DeathDate,
		@SexID,
		@LangID,
		@CivilID,
		@SocialNumber,
		@ResidID,
		@DriverLicenseNo,
		@WebSite,
		@CompanyName,
		@CourtesyTitle,
		@UsingSocialNumber,
		@SharePersonalInfo,
		@MarketingMaterial,
		@IsCompany,
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
		@EMail

	IF @UserID <= 0
		SET @UserID = -1

	IF @UserID > 0
	BEGIN
		-- Ajout
		IF NOT EXISTS	(
				SELECT UserID
				FROM Mo_User
				WHERE UserID = @UserID
						)
		BEGIN
			-- Valide que le nom usager ne soit pas déjà utilisé
			IF EXISTS	(
					SELECT UserID
					FROM Mo_User
					WHERE LoginNameID = @LoginNameID
							)
				SET @UserID = -2
			ELSE
			BEGIN
				-- Création de l'utiliateur dans Mo_User
				INSERT INTO Mo_User (
					UserID,
					LoginNameID,
					PassWordID,
					PassWordDate,
					TerminatedDate,
					CodeID)
				VALUES (
					@UserID,
					@LoginNameID,
					dbo.fn_Mo_Encrypt(@PassWordID),
					GETDATE(),
					@TerminatedDate,
					@CodeID)

				IF @@ERROR <> 0
					SET @UserID = -3
				ELSE
				BEGIN
					-- Insère un log de l'objet inséré.
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
							'Mo_User',
							@UserID,
							GETDATE(),
							LA.LogActionID,
							LogDesc = 'Usager : '+H.LastName+', '+H.FirstName,
							LogText =
								'LoginNameID'+@cSep+U.LoginNameID+@cSep+CHAR(13)+CHAR(10)+
								'PassWordID'+@cSep+U.PassWordID+@cSep+CHAR(13)+CHAR(10)+
								CASE 
									WHEN ISNULL(U.TerminatedDate,0) <= 0 THEN ''
								ELSE 'TerminatedDate'+@cSep+CONVERT(CHAR(10), U.TerminatedDate, 20)+@cSep+CHAR(13)+CHAR(10)
								END+
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
								'ResidID'+@cSep+H.ResidID+@cSep+R.CountryName+@cSep+CHAR(13)+CHAR(10)+
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
							FROM Mo_User U
							JOIN dbo.Mo_Human H ON H.HumanID = U.UserID
							JOIN Mo_Lang L ON L.LangID = H.LangID
							JOIN Mo_Sex S ON S.LangID = H.LangID AND S.SexID = H.SexID
							JOIN Mo_CivilStatus CS ON CS.LangID = H.LangID AND CS.SexID = H.SexID AND CS.CivilStatusID = H.CivilID
							JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'I'
							JOIN Mo_Country R ON R.CountryID = H.ResidID
							LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
							LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
							WHERE U.UserID = @UserID

					IF @@ERROR <> 0
						SET @UserID = -5
				END
			END
		END
		ELSE
		-- Modification
		BEGIN
			-- Valide que le nouveau nom usager ne soit pas déjà utilisé.
			IF (	@vcOldLoginNameID <> @LoginNameID
				) 
			AND	EXISTS	(
					SELECT UserID
					FROM Mo_User
					WHERE LoginNameID = @LoginNameID
								)
				SET @UserID = -2

			IF @UserID > 0
			BEGIN
				-- Mise à jour des données de l'utilisateur 
				UPDATE Mo_User 
				SET
					TerminatedDate = @TerminatedDate,
					LoginNameID = @LoginNameID,
					PassWordID = dbo.fn_Mo_Encrypt(@PassWordID),
					PassWordDate = 
						CASE 
							WHEN @vcOldPassWordID <> dbo.fn_Mo_Encrypt(@PassWordID) THEN GETDATE()
						ELSE PassWordDate
						END,
					CodeID = @CodeID
				WHERE UserID = @UserID

				IF @@ERROR <> 0
					SET @UserID = -4
				ELSE
				BEGIN
					IF EXISTS	(
							SELECT UserID
							FROM Mo_User U
							JOIN dbo.Mo_Human H ON H.HumanID = U.UserID
							WHERE U.UserID = @UserID
								AND	(	@vcOldFirstName <> H.FirstName
										OR	@vcOldOrigName <> H.OrigName
										OR @vcOldLastName <> H.LastName
										OR @cOldLangID <> H.LangID
										OR @dtOldTerminatedDate <> U.TerminatedDate
										OR @vcOldLoginNameID <> U.LoginNameID
										OR @vcOldPassWordID <> U.PassWordID
										)
									)
					BEGIN
						-- Insère un log de l'objet modifié.
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
								'Mo_User',
								@UserID,
								GETDATE(),
								LA.LogActionID,
								LogDesc = 'Usager : '+H.LastName+', '+H.FirstName,
								LogText =
									CASE 
										WHEN @vcOldLoginNameID <> U.LoginNameID THEN
											'LoginNameID'+@cSep+@vcOldLoginNameID+@cSep+U.LoginNameID+@cSep+CHAR(13)+CHAR(10)
									ELSE ''
									END+
									CASE
										WHEN dbo.fn_Mo_Encrypt(@vcOldPassWordID) <> U.PassWordID THEN
											'PassWordID'+@cSep+dbo.fn_Mo_Encrypt(@vcOldPassWordID)+@cSep+U.PassWordID+@cSep+CHAR(13)+CHAR(10)
									ELSE ''
									END+
									CASE 
										WHEN ISNULL(@dtOldTerminatedDate,0) <> ISNULL(U.TerminatedDate,0) THEN
											'TerminatedDate'+@cSep+
											CASE 
												WHEN ISNULL(@dtOldTerminatedDate,0) <= 0 THEN ''
											ELSE CONVERT(CHAR(10), @dtOldTerminatedDate, 20)
											END+@cSep+
											CASE 
												WHEN ISNULL(U.TerminatedDate,0) <= 0 THEN ''
											ELSE CONVERT(CHAR(10), U.TerminatedDate, 20)
											END+@cSep+CHAR(13)+CHAR(10)
									ELSE ''
									END+
									CASE 
										WHEN ISNULL(@vcOldFirstName,'') <> ISNULL(H.FirstName,'') THEN
											'FirstName'+@cSep+
											CASE 
												WHEN ISNULL(@vcOldFirstName,'') <> '' THEN ''
											ELSE @vcOldFirstName
											END+@cSep+
											CASE 
												WHEN ISNULL(H.FirstName,'') <> '' THEN ''
											ELSE H.FirstName
											END+@cSep+CHAR(13)+CHAR(10)
									ELSE ''
									END+
									CASE 
										WHEN ISNULL(@vcOldLastName,'') <> ISNULL(H.LastName,'') THEN
											'LastName'+@cSep+
											CASE 
												WHEN ISNULL(@vcOldLastName,'') <> '' THEN ''
											ELSE @vcOldLastName
											END+@cSep+
											CASE 
												WHEN ISNULL(H.LastName,'') <> '' THEN ''
											ELSE H.LastName
											END+@cSep+CHAR(13)+CHAR(10)
									ELSE ''
									END+
									CASE 
										WHEN ISNULL(@vcOldOrigName,'') <> ISNULL(H.OrigName,'') THEN
											'OrigName'+@cSep+
											CASE 
												WHEN ISNULL(@vcOldOrigName,'') <> '' THEN ''
											ELSE @vcOldOrigName
											END+@cSep+
											CASE 
												WHEN ISNULL(H.OrigName,'') <> '' THEN ''
											ELSE H.OrigName
											END+@cSep+CHAR(13)+CHAR(10)
									ELSE ''
									END+
									CASE
										WHEN @cOldLangID <> H.LangID THEN
											'LangID'+@cSep+@cOldLangID+@cSep+H.LangID+@cSep+OL.LangName+@cSep+L.LangName+@cSep+CHAR(13)+CHAR(10)
									ELSE ''
									END
								FROM Mo_User U
								JOIN dbo.Mo_Human H ON H.HumanID = U.UserID
								JOIN Mo_Lang L ON L.LangID = H.LangID
								JOIN Mo_Lang OL ON OL.LangID = @cOldLangID
								JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
								WHERE U.UserID = @UserID

						IF @@ERROR <> 0
							SET @UserID = -6
					END
				END
			END
		END
	END

	IF @UserID > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @UserID
END


