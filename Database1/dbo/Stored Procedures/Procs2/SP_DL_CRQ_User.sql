/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 : SP_DL_CRQ_User
Description         : Suppression d'usagers
Valeurs de retours  : >0  : Tout à fonctionné
                      <=0 : Erreur SQL
								-1 : 	L'usager c'est déjà connecté, on ne peut donc plus le supprimer
								-2 : 	Erreur à la suppression des notes
								-3 : 	Erreur à la suppression des liens entre l'usager et les groupes d'usagers auxquelles il 
										appartenait.
								-4 : 	Erreur à la suppression des droits de l'usager
								-5 : 	Erreur à la création du log
								-6 : 	Erreur à la suppression de l'usager
Note                : ADX0000591 IA 2004-11-23	Bruno Lapointe			Création
												2014-03-06	Pierre-Luc Simard		Retrait du log des téléphone Pager et Wattline
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_DL_CRQ_User] (
	@ConnectID MoID, -- ID unique de connexion de l'usager qui supprime l'usager
	@UserID MoID) -- ID unique de l'usager
AS
BEGIN
	DECLARE
		@iResultID INTEGER,
		-- Variable du caractère séparateur de valeur du blob
		@cSep CHAR(1)
	
	SET @cSep = CHAR(30)

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- Vérifie si l'usager c'est déjà connecté
	IF EXISTS	(
			SELECT ConnectID
			FROM Mo_Connect
			WHERE UserID = @UserID
					)
		SET @UserID = -1

	IF @UserID > 0
	BEGIN
		-- Suppression des notes sur l'usager
		EXECUTE @iResultID = DMo_NoteWithClassName
			@ConnectID,
			@UserID,
			'TMOUSER,TMOUSERS'

		IF @iResultID <= 0
			SET @UserID = -2
	END

	IF @UserID > 0
	BEGIN
		-- Suppression des liens entre l'usager et les groupes d'usagers auxquelles il appartenait
		DELETE 
		FROM Mo_UserGroupDtl
		WHERE UserID = @UserID

		IF @@ERROR <> 0
			SET @UserID = -3
	END

	IF @UserID > 0
	BEGIN
		-- Suppression des droits de l'usager
		DELETE 
		FROM Mo_UserRight
		WHERE UserID = @UserID

		IF @@ERROR <> 0
			SET @UserID = -4
	END

	IF @UserID > 0
	BEGIN
		-- Insère un log de l'usager supprimé.
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
				JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'D'
				JOIN Mo_Country R ON R.CountryID = H.ResidID
				LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
				LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
				WHERE U.UserID = @UserID

		IF @@ERROR <> 0
			SET @UserID = -5
	END

	IF @UserID > 0
	BEGIN
		-- Suppression de l'usager
		DELETE 
		FROM Mo_User
		WHERE UserID = @UserID

		IF @@ERROR <> 0
			SET @UserID = -6
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


