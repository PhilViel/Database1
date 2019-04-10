/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                : DL_UN_Beneficiary
Description        : Suppression de bénéficiaires
Valeurs de retours : >0  : Tout à fonctionné
                      <=0 : Erreur SQL
								-1 : 	Erreur il y a des enregistrements 200 expédiés
								-2 : 	Erreur à la création du log
								-3 : 	Erreur à la suppression des enregistrements 200 non-expédiés
								-4 : 	Erreur à la suppression du bénéficiaire
Note               :						2004-06-08	Bruno Lapointe				Migration
							ADX0000594	IA	2004-11-24	Bruno Lapointe		Log
	        	       	ADX0000692	IA	2005-05-05	Bruno Lapointe			Modification du log suite au changement dans les tuteurs
							ADX0000826	IA	2006-03-14	Bruno Lapointe		Adaptation des bénéficiaires pour PCEE 4.3
							ADX0000798	IA	2006-03-17	Bruno Lapointe		Saisie des principaux responsables
													2010-01-18	Jean-F. Gauthier		Ajout du champ EligibilityConditionID (table Un_Beneficiary) dans la journalisation
													2014-03-06	Pierre-Luc Simard	Retrait du log des téléphone Pager et Wattline
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_Beneficiary] (
	@ConnectID INTEGER, -- ID Unique de connexion
	@BeneficiaryID INTEGER) -- ID Unique du bénéficiaire
AS
BEGIN
	DECLARE
		-- Variable du caractère séparateur de valeur du blob
		@cSep CHAR(1)

	SET @cSep = CHAR(30)

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- S'assure qu'il n'y est pas d'enregistrements 200 expédiés
	IF EXISTS (
		SELECT *
		FROM Un_CESP200
		WHERE HumanID = @BeneficiaryID
			AND tiType = 3
			AND iCESPSendFileID IS NOT NULL
			)
		SET @BeneficiaryID = -1

	IF @BeneficiaryID > 0
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
				'Un_Beneficiary',
				@BeneficiaryID,
				GETDATE(),
				LA.LogActionID,
				LogDesc = 'Bénéficiaire : '+H.LastName+', '+H.FirstName,
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
					END+
					CASE 
						WHEN ISNULL(B.iTutorID,0) = 0 THEN ''
					ELSE 'iTutorID'+@cSep+CAST(B.iTutorID AS VARCHAR(30))+@cSep+T.LastName+', '+T.FirstName+@cSep+CHAR(13)+CHAR(10)
					END+
					'bTutorIsSubscriber'+@cSep+CAST(ISNULL(B.bTutorIsSubscriber,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(B.bTutorIsSubscriber,0) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					'GovernmentGrantForm'+@cSep+CAST(ISNULL(B.GovernmentGrantForm,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(B.GovernmentGrantForm,0) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					'BirthCertificate'+@cSep+CAST(ISNULL(B.BirthCertificate,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(B.BirthCertificate,0) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					'PersonalInfo'+@cSep+CAST(ISNULL(B.PersonalInfo,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(B.PersonalInfo,0) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					CASE 
						WHEN ISNULL(B.ProgramID,0) <= 0 THEN ''
					ELSE 'ProgramID'+@cSep+CAST(B.ProgramID AS VARCHAR)+@cSep+ISNULL(P.ProgramDesc,'')+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(B.CollegeID,0) <= 0 THEN ''
					ELSE 'CollegeID'+@cSep+CAST(B.CollegeID AS VARCHAR)+@cSep+ISNULL(Cy.CompanyName,'')+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(B.StudyStart,0) <= 0 THEN ''
					ELSE 'StudyStart'+@cSep+CONVERT(CHAR(10), B.StudyStart, 20)+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(B.ProgramLength,0) <= 0 THEN ''
					ELSE 'ProgramLength'+@cSep+CAST(B.ProgramLength AS VARCHAR)+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(B.ProgramYear,0) <= 0 THEN ''
					ELSE 'ProgramYear'+@cSep+CAST(B.ProgramYear AS VARCHAR)+@cSep+CHAR(13)+CHAR(10)
					END+
					'RegistrationProof'+@cSep+CAST(ISNULL(B.RegistrationProof,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(B.RegistrationProof,0) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					'SchoolReport'+@cSep+CAST(ISNULL(B.SchoolReport,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(B.SchoolReport,0) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					CASE 
						WHEN ISNULL(B.EligibilityQty,0) <= 0 THEN ''
					ELSE 'EligibilityQty'+@cSep+CAST(B.EligibilityQty AS VARCHAR)+@cSep+CHAR(13)+CHAR(10)
					END+
					'CaseOfJanuary'+@cSep+CAST(ISNULL(B.CaseOfJanuary,0) AS CHAR(1))+@cSep+
					CASE 
						WHEN ISNULL(B.CaseOfJanuary,0) = 1 THEN 'Oui'
					ELSE 'Non'
					END+@cSep+
					CHAR(13)+CHAR(10)+
					CASE
						WHEN ISNULL(B.tiPCGType,1) = 1 AND ISNULL(B.bPCGIsSubscriber,0) = 0 THEN 'tiPCGType'+@cSep+CAST(ISNULL(B.tiPCGType,0) AS VARCHAR)+@cSep+'Personne'+@cSep+CHAR(13)+CHAR(10)
						WHEN ISNULL(B.tiPCGType,1) = 1 THEN 'tiPCGType'+@cSep+CAST(ISNULL(B.tiPCGType,0) AS VARCHAR)+@cSep+'Souscripteur'+@cSep+CHAR(13)+CHAR(10)
						WHEN ISNULL(B.tiPCGType,1) = 2 AND ISNULL(B.bPCGIsSubscriber,0) = 0 THEN 'tiPCGType'+@cSep+CAST(ISNULL(B.tiPCGType,0) AS VARCHAR)+@cSep+'Entreprise'+@cSep+CHAR(13)+CHAR(10)
						WHEN ISNULL(B.tiPCGType,1) = 2 THEN 'tiPCGType'+@cSep+CAST(ISNULL(B.tiPCGType,0) AS VARCHAR)+@cSep+'Souscripteur'+@cSep+CHAR(13)+CHAR(10)
					ELSE ''
					END+
					CASE 
						WHEN ISNULL(B.vcPCGFirstName,'') = '' THEN ''
					ELSE 'vcPCGFirstName'+@cSep+B.vcPCGFirstName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(B.vcPCGLastName,'') = '' THEN ''
					ELSE 'vcPCGLastName'+@cSep+B.vcPCGLastName+@cSep+CHAR(13)+CHAR(10)
					END+
					CASE 
						WHEN ISNULL(B.vcPCGSINOrEN,'') = '' THEN ''
						WHEN ISNULL(B.tiPCGType,1) = 1 THEN 'vcPCGSIN'+@cSep+B.vcPCGSINOrEN+@cSep+CHAR(13)+CHAR(10)
					ELSE 'vcPCGEN'+@cSep+B.vcPCGSINOrEN+@cSep+CHAR(13)+CHAR(10)
					END+
					'tiCESPState'+@cSep+CAST(ISNULL(B.tiCESPState,0) AS VARCHAR)+@cSep+
					CASE ISNULL(B.tiCESPState,0)
						WHEN 1 THEN 'SCEE'
						WHEN 2 THEN 'SCEE et BEC'
						WHEN 3 THEN 'SCEE et SCEE+'
						WHEN 4 THEN 'SCEE, SCEE+ et BEC'
					ELSE ''
					END+@cSep+
					CASE 
						WHEN ISNULL(B.EligibilityConditionID,'') = '' THEN ''
					ELSE ''+@cSep+B.EligibilityConditionID+@cSep+CHAR(13)+CHAR(10)
					END
				FROM dbo.Un_Beneficiary B
				JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
				JOIN Mo_Lang L ON L.LangID = H.LangID
				JOIN Mo_Sex S ON S.LangID = H.LangID AND S.SexID = H.SexID
				JOIN Mo_CivilStatus CS ON CS.LangID = H.LangID AND CS.SexID = H.SexID AND CS.CivilStatusID = H.CivilID
				JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'D'
				JOIN Mo_Country R ON R.CountryID = H.ResidID
				LEFT JOIN Mo_Company Cy ON Cy.CompanyID = B.CollegeID
				LEFT JOIN Un_Program P ON P.ProgramID = B.ProgramID
				LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
				LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
				LEFT JOIN dbo.Mo_Human T ON T.HumanID = B.iTutorID
				WHERE B.BeneficiaryID = @BeneficiaryID

		IF @@ERROR <> 0
			SET @BeneficiaryID = -2
	END

	IF @BeneficiaryID > 0
	BEGIN
		-- Suppression des enregistements 200 non expédiés
		DELETE Un_CESP200
		WHERE HumanID = @BeneficiaryID
			AND tiType = 3
			AND iCESPSendFileID IS NULL

		IF @@ERROR <> 0
			SET @BeneficiaryID = -3
	END

	-- Suppression du bénéficiaire
	IF @BeneficiaryID > 0
	BEGIN
		DELETE 
		FROM dbo.Un_Beneficiary 
		WHERE BeneficiaryID = @BeneficiaryID

		IF @@ERROR <> 0
			SET @BeneficiaryID = -4
	END

	IF @BeneficiaryID > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @BeneficiaryID
END


