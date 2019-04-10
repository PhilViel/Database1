/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : IU_UN_Beneficiary
Description         : Sauvegarde d'ajouts/modifications de béneficiaires
Valeurs de retours  : >0  :	Tout à fonctionné
                      <=0 :	Erreur SQL

Note :								2003-05-05	Andr‚ Sanscartier		Modification
									2003-10-15	Bruno Lapointe			Modification (point 768)
									2004-05-21	Dominic Létourneau		Migration de l'ancienne procedure selon les nouveaux standards
					ADX0000590	IA	2004-11-19	Bruno Lapointe			Remplacer IMo_Human par SP_IU_CRQ_Human
					ADX0000594	IA	2004-11-23	Bruno Lapointe			Gestion du log
					ADX0000578	IA	2004-11-24	Bruno Lapointe			Correction des erreurs de prévalidations
					ADX0001177	BR	2004-12-01	Bruno Lapointe			Changement des codes d'erreurs et des validations
					ADX0001221	BR	2005-01-07	Bruno Lapointe			Correction de bug dans le log de modification
					ADX0000692	IA	2005-05-05	Bruno Lapointe			Utiliser le iTutorID et enlever le TutorName.
					ADX0000691	IA	2005-05-06	Bruno Lapointe			Envoi automatique de la lettre d'émission au tuteur sur changement de tuteur.
					ADX0000704	IA	2005-07-05	Bruno Lapointe			Quand la preuve d'inscription est complète, le statut des bourses de la liste reliées à ce bénéficiaire change pour à payer.
					ADX0001603	BR	2005-10-11	Bruno Lapointe			Erreur de sélection de valeurs pour la pré-validation.  Pas de clause WHERE.
					ADX0001762	BR	2005-11-22	Bruno Lapointe			Correction des conditions pour la preuve d'inscription afin de déterminer s'il faut changer le statut des bourses du bénéficiaire
					ADX0000826	IA	2006-03-14	Bruno Lapointe			Adaptation des bénéficiaires pour PCEE 4.3
					ADX0000798	IA	2006-03-17	Bruno Lapointe			Saisie des principaux responsables
					ADX0000848	IA	2006-03-24	Bruno Lapointe			Adaptation des FCB pour PCEE 4.3
					ADX0002064	BR	2006-08-22	Bruno Lapointe			Exclure les conventions résiliées des lettres au tuteur légal.
					ADX0001278	IA	2007-03-19	Alain Quirion			Vérification de la province en plus du pays pour la fusion des villes
								2008-01-08	Pierre-Luc Simard			Ajout des modifications du principal responsable dans la gestion des logs
								2008-09-23  Radu Trandafir              Suppression d'un select superflu qui generait un dataset 
								2008-10-02	Patrick Robitaille			Ajout du paramètre pour le champ NEQ
								2009-06-16	Patrick Robitaille			Ajout du champ bBeneficiaire_Accepte_Publipostage
								2009-11-23	Jean-François Gauthier		Ajout des validations pour le BEC
								2010-01-12	Jean-François Gauthier		Ajout des modifications à Pierre-Luc Simard
								2010-01-19	Jean-François Gauthier		Ajout du champ EligibilityConditionID
								2010-04-16	Jean-François Gauthier		Correctif dans le log qui avant un char(13) de trop
																		Modification du paramètre @cEligibilityConditionID
																		afin de le rendre NULL lorsqu'il est passé vide
								2010-04-26	Pierre Paquet				Ajustement pour la création de la demande de BEC'.
								2010-05-21	Pierre Paquet				Correction: Passer la bonne convention BEC pour la création.
								2010-05-26	Pierre Paquet				Correction: Retirer la validation du type de principal responsable.
																		Correction: Utilisation de TT_UN_CLB pour la création des 400.
								2010-05-27	Pierre Paquet				Correction: Vérifier qu'il n'y a pas déjà une autre convention de cochée BEC.
								2010-08-05	Pierre Paquet				Correction: S'assurer que TT_UN_CESPOfConvention est lancé s'il y a un changement sur le PR.
								2010-09-21	Pierre Paquet				Ajout de la gestion automatique 'Formulaire recu'.
								2010-09-23	Pierre Paquet				Ajout de la gestion des 400-11 a renvoyer pour demande de subvention.
								2010-10-24	Pierre Paquet				Ajout de la validation de la présence du RI sur info du PR.
								2010-11-08	Donald Huppé				Correction du correctif du 2010-04-16 concernant le log.
																		À l'insertion, on ajoute @cSep+CHAR(13)+CHAR(10) seulement au besoin à la suite des valeurs insérées.
																		Et on ne l'ajoute plus à la fin, afin qu'il ne soit pas en double.
								2014-03-06	Pierre-Luc Simard		Retrait du log des téléphone Pager et Wattline
								2014-11-07	Pierre-Luc Simard		Ne plus enregistrer la valeur du champs tiCESPState, qui est maintenant géré par la procédure psCONV_EnregistrerPrevalidationPCEE
								2015-02-13	Pierre-Luc Simard		Ne plus valider l'état du bénéficiaire avant d'appeler la procédure TT_UN_CESPOfConventions
								2015-06-12	Pierre-Luc Simard		Ne plus modifier l'état des bourses pour TPA (À payer)
								2015-09-04	Pierre-Luc Simard		Ne plus générer de lettre au tuteur lors d'un changement
								
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_Beneficiary] (
	@ConnectID INTEGER, -- Identifiant unique de la connection	
	@BeneficiaryID INTEGER,
	@iTutorID INTEGER, -- ID du tuteur. 
	@bTutorIsSubscriber BIT, -- True : le tuteur est un souscripteur (Un_BeneficiaryID.iTutorID = Un_Subscriber.iTutorID).  False : le tuteur est un tuteur (Un_BeneficiaryID.iTutorID = Un_Tutor.iTutorID).
	@GovernmentGrantForm BIT = 0,
	@BirthCertificate BIT = 0,
	@PersonalInfo BIT = 0,
	@ProgramID INTEGER,
	@CollegeID INTEGER,
	@StudyStart DATETIME,
	@ProgramLength INTEGER,
	@ProgramYear INTEGER,
	@RegistrationProof BIT = 0,
	@SchoolReport BIT = 0,
	@EligibilityQty SMALLINT = 0, 
	@CaseOfJanuary BIT = 0,
	@tiPCGType INTEGER, -- Type de principal responsable. (0=Personne, 1=Souscripteur, 2=Souscripteur-Entreprise et 3=Entreprise)
	@vcPCGFirstName VARCHAR(40), -- Pr‚nom du principal responsable s'il s'agit d'un souscripteur ou d'une personne. Nom de l'entreprise principal responsable dans l'autre cas.
	@vcPCGLastName VARCHAR (50), -- Nom du principal responsable s'il s'agit d'un souscripteur ou d'une personne.
	@vcPCGSINOrEN VARCHAR (15), -- NAS du principal responsable si le type est personne ou souscripteur.  NE si le type est entreprise.
	@tiCESPState TINYINT, -- État du bénéficiaire au niveau des pré-validations. (0 = Rien ne passe, 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)
	@FirstName VARCHAR(35),
	@OrigName VARCHAR(75) = NULL,
	@Initial VARCHAR(4) = NULL,
	@LastName VARCHAR(50),
	@BirthDate DATETIME,
	@DeathDate DATETIME,
	@SexID MoSex,
	@LangID MoLang,
	@CivilID MoCivil,
	@SocialNumber VARCHAR(75) = NULL,
	@ResidID CHAR(4),
	@DriverLicenseNo VARCHAR(75) = NULL,
	@WebSite VARCHAR(75) = NULL,
	@CompanyName VARCHAR(75) = NULL,
	@CourtesyTitle VARCHAR(35) = NULL,
	@UsingSocialNumber BIT = 1,
	@SharePersonalInfo BIT = 1,
	@MarketingMaterial BIT = 1,
	@IsCompany BIT = 0,
	@InForce DATETIME,
	@AdrTypeID MoAdrType,
	@SourceID INTEGER = NULL,
	@Address VARCHAR(75) = NULL,
	@City VARCHAR(100) = NULL,
	@StateName VARCHAR(75) = NULL,
	@CountryID CHAR(4) = NULL,
	@ZipCode VARCHAR(10) = NULL,
	@Phone1 VARCHAR(27) = NULL,
	@Phone2 VARCHAR(27) = NULL,
	@Fax VARCHAR(15) = NULL,
	@Mobile VARCHAR(15) = NULL,
	@WattLine VARCHAR(27) = NULL,
	@OtherTel VARCHAR(27) = NULL,
	@Pager VARCHAR(15) = NULL,
	@EMail VARCHAR(100) = NULL,
	@vcNEQ VARCHAR(10),
	@bAcceptePubli BIT = 0,
	@cEligibilityConditionID CHAR(3) = NULL		-- 2010-01-19 : JFG : ajout
	)
AS
BEGIN
	-- Variables de travail
	DECLARE
		@vcStateCode VARCHAR(75),
		@iBeneficiaryID INTEGER,
		@iConventionID INTEGER,
		@iErrorID INTEGER,
		-- Variables contenant les anciennes valeurs pour le log
		@iOldBeneficiaryID INTEGER,
		@vcOldFirstName VARCHAR(35),
		@vcOldOrigName VARCHAR(75),
		@vcOldInitial VARCHAR(4),
		@vcOldLastName VARCHAR(50),
		@dtOldBirthDate DATETIME,
		@dtOldDeathDate DATETIME,
		@cOldSexID MoSex,
		@cOldLangID MoLang,
		@cOldCivilID MoCivil,
		@vcOldSocialNumber VARCHAR(75),
		@cOldResidID CHAR(4),
		@vcOldDriverLicenseNo VARCHAR(75),
		@vcOldWebSite VARCHAR(75),
		@vcOldCompanyName VARCHAR(75),
		@vcOldCourtesyTitle VARCHAR(35),
		@bOldUsingSocialNumber BIT,
		@bOldSharePersonalInfo BIT,
		@bOldMarketingMaterial BIT,
		@bOldIsCompany BIT,
		@dtOldInForce DATETIME,
		@vcOldAddress VARCHAR(75),
		@vcOldCity VARCHAR(100),
		@vcOldStateName VARCHAR(75),
		@cOldCountryID CHAR(4),
		@vcOldZipCode VARCHAR(10),
		@vcOldPhone1 VARCHAR(27),
		@vcOldPhone2 VARCHAR(27),
		@vcOldFax VARCHAR(15),
		@vcOldMobile VARCHAR(15),
		@vcOldWattLine VARCHAR(27),
		@vcOldOtherTel VARCHAR(27),
		@vcOldPager VARCHAR(15),
		@vcOldEmail VARCHAR(100),
		@iOldTutorID INTEGER,
		@bOldTutorIsSubscriber BIT,
		@bOldGovernmentGrantForm BIT,
		@bOldBirthCertificate BIT,
		@bOldPersonalInfo BIT,
		@iOldProgramID INTEGER,
		@iOldCollegeID INTEGER,
		@dtOldStudyStart DATETIME,
		@iOldProgramLength INTEGER,
		@iOldProgramYear INTEGER,
		@bOldRegistrationProof BIT,
		@bOldSchoolReport BIT,
		@siOldEligibilityQty SMALLINT, 
		@bOldCaseOfJanuary BIT, 
		@tiOldPCGType INTEGER, -- Type de principal responsable. (0=Personne, 1=Souscripteur, 2=Entreprise)
		@vcOldPCGFirstName VARCHAR(40), -- Prénom du principal responsable s'il s'agit d'un souscripteur ou d'une personne. Nom de l'entreprise principal responsable dans l'autre cas.
		@vcOldPCGLastName VARCHAR (50), -- Nom du principal responsable s'il s'agit d'un souscripteur ou d'une personne.
		@vcOldPCGSINOrEN VARCHAR (15), -- NAS du principal responsable si le type est personne ou souscripteur.  NE si le type est entreprise.
		@tiOldCESPState TINYINT, -- État du bénéficiaire au niveau des pr‚-validations. (0 = Rien ne passe, 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)
		@bOldPCGIsSubscriber BIT, -- Indique si le principal responsable est un souscripteur
		@vcOldNEQ VARCHAR(10),	-- Numéro d'entreprise du Québec
		@bOldAcceptePubli BIT,
		@cSep CHAR(1),			-- Variable du caractère s‚parateur de valeur du blob
		@cOldEligibilityConditionID CHAR(3) 		-- 2010-01-19 : JFG : ajout

	SET @cSep = CHAR(30)

	-----------------	
	BEGIN TRANSACTION
	-----------------
	-- 2010-04-16 : JFG : Rendre NULL le paramètre s'il est passé vide
	IF LTRIM(RTRIM(@cEligibilityConditionID)) = ''
		BEGIN
			SET @cEligibilityConditionID = NULL
		END

	-- Va chercher les anciennes valeurs s'il y en a
	SELECT
		@iOldBeneficiaryID = B.BeneficiaryID,
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
		@iOldTutorID = B.iTutorID,
		@bOldTutorIsSubscriber = B.bTutorIsSubscriber,
		@bOldGovernmentGrantForm = B.GovernmentGrantForm,
		@bOldBirthCertificate = B.BirthCertificate,
		@bOldPersonalInfo = B.PersonalInfo,
		@iOldProgramID = B.ProgramID,
		@iOldCollegeID = B.CollegeID,
		@dtOldStudyStart = B.StudyStart,
		@iOldProgramLength = B.ProgramLength,
		@iOldProgramYear = B.ProgramYear,
		@bOldRegistrationProof = B.RegistrationProof,
		@bOldSchoolReport = B.SchoolReport,
		@siOldEligibilityQty = B.EligibilityQty, 
		@bOldCaseOfJanuary = B.CaseOfJanuary,
		@tiOldPCGType = tiPCGType, -- Type de principal responsable. (0=Personne, 1=Souscripteur, 2=Entreprise)
		@vcOldPCGFirstName = vcPCGFirstName, -- Prénom du principal responsable s'il s'agit d'un souscripteur ou d'une personne. Nom de l'entreprise principal responsable dans l'autre cas.
		@vcOldPCGLastName = vcPCGLastName, -- Nom du principal responsable s'il s'agit d'un souscripteur ou d'une personne.
		@vcOldPCGSINOrEN = vcPCGSINOrEN, -- NAS du principal responsable si le type est personne ou souscripteur.  NE si le type est entreprise.
		@tiOldCESPState = tiCESPState, -- État du bénéficiaire au niveau des pré-validations. (0 = Rien ne passe, 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)
		@bOldPCGIsSubscriber = bPCGIsSubscriber, -- Indique si le principal responsabele est un souscripteur
		@vcOldNEQ = H.StateCompanyNo,	-- Numéro d'entreprise du Québec
		@bOldAcceptePubli = H.bHumain_Accepte_Publipostage,
		@cOldEligibilityConditionID = B.EligibilityConditionID
	FROM dbo.Un_Beneficiary B
	JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	WHERE B.BeneficiaryID = @BeneficiaryID
	  AND (	@BeneficiaryID > 0 
			)
  
	-- Initialisation des variables
	IF @ProgramID = 0
		SET @ProgramID = NULL
	
	IF @CollegeID = 0
		SET @CollegeID = NULL
	
	IF @iTutorID <= 0
		SET @iTutorID = NULL

	-- Recherche d'une fusion existante pour le nom de ville en paramètre
	IF EXISTS (
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
	END

	-- Création des dossiers dans Mo_Human et Mo_Adresse
	EXECUTE @BeneficiaryID = SP_IU_CRQ_Human
		@ConnectID,
		@BeneficiaryID,
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
		@EMail,
		NULL,
		@vcNEQ,
		@bAcceptePubli
		
	IF @BeneficiaryID > 0
	BEGIN
		SELECT @iBeneficiaryID = BeneficiaryID
		FROM dbo.Un_Beneficiary 
		WHERE BeneficiaryID = @BeneficiaryID

		IF @iBeneficiaryID IS NULL
		BEGIN
			INSERT Un_Beneficiary (
				BeneficiaryID,
				iTutorID,
				bTutorIsSubscriber,
				GovernmentGrantForm,
				BirthCertificate,
				PersonalInfo,
				ProgramID,
				CollegeID,
				StudyStart,
				ProgramLength,
				ProgramYear,
				RegistrationProof,
				SchoolReport,
				EligibilityQty, 
				CaseOfJanuary,
				tiPCGType, 
				vcPCGFirstName,
				vcPCGLastName,
				vcPCGSINOrEN,
				bPCGIsSubscriber,
				tiCESPState,
				EligibilityConditionID)
			VALUES (
				@BeneficiaryID,
				@iTutorID,
				@bTutorIsSubscriber,
				@GovernmentGrantForm,
				@BirthCertificate,
				@PersonalInfo,
				@ProgramID,
				@CollegeID,
				@StudyStart,
				@ProgramLength,
				@ProgramYear,
				@RegistrationProof,
				@SchoolReport,
				@EligibilityQty, 
				@CaseOfJanuary,
				CASE @tiPCGType
					WHEN 0 THEN 1
					WHEN 3 THEN 2
				ELSE @tiPCGType
				END,
				@vcPCGFirstName,
				@vcPCGLastName,
				@vcPCGSINOrEN,
				CASE @tiPCGType -- Si @tiPCGType = 1 ou 2 c'est que c'est un souscripteur
					WHEN 0 THEN 0
					WHEN 1 THEN 1
					WHEN 2 THEN 1
					WHEN 3 THEN 0
				END,
				0, --@tiCESPState, Sera réévalué plus loin par la procédure psCONV_EnregistrerPrevalidationPCEE
				@cEligibilityConditionID)

			IF @@ERROR <> 0
				SET @BeneficiaryID = -1

			-- Mettre à jour l'état des prévalidations du bénéficiaire
			EXEC @iErrorID = psCONV_EnregistrerPrevalidationPCEE @ConnectID, NULL, @BeneficiaryID, NULL, NULL

			IF @iErrorID <= 0 
					SET @BeneficiaryID = -12

			SELECT
				@tiCESPState = tiCESPState
			FROM dbo.Un_Beneficiary B
			WHERE B.BeneficiaryID = @BeneficiaryID

			IF @BeneficiaryID > 0
			BEGIN 
				-- Insère un log de l'objet ins‚r‚.
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
							-- Ne plus inclure ce champ dans le log puisque'il sera recalculeé plus loin par la procédure psCONV_EnregistrerPrevalidationPCEE 
							/*'tiCESPState'+@cSep+CAST(ISNULL(B.tiCESPState,0) AS VARCHAR)+@cSep+
							CASE ISNULL(B.tiCESPState,0)
								WHEN 1 THEN 'SCEE'+@cSep+CHAR(13)+CHAR(10)
								WHEN 2 THEN 'SCEE et BEC'+@cSep+CHAR(13)+CHAR(10)
								WHEN 3 THEN 'SCEE et SCEE+'+@cSep+CHAR(13)+CHAR(10)
								WHEN 4 THEN 'SCEE, SCEE+ et BEC'+@cSep+CHAR(13)+CHAR(10)
							ELSE ''+@cSep+CHAR(13)+CHAR(10)
							END+*/
							CASE 
								WHEN ISNULL(H.StateCompanyNo,'') = '' THEN ''
							ELSE 'NEQ'+@cSep+H.StateCompanyNo+@cSep+CHAR(13)+CHAR(10)
							END+
							
							--+@cSep+CHAR(13)+CHAR(10)+
							
							'bBeneficiaireAcceptePublipostage'+@cSep+CAST(ISNULL(H.bHumain_Accepte_Publipostage,0) AS CHAR(1))+@cSep+
							CASE 
								WHEN ISNULL(H.bHumain_Accepte_Publipostage,0) = 1 THEN 'Oui'+@cSep+CHAR(13)+CHAR(10)
							ELSE 'Non'+@cSep+CHAR(13)+CHAR(10)
							END+--@cSep+CHAR(13)+CHAR(10)+
							
							CASE 
								WHEN ISNULL(B.EligibilityConditionID,'') = '' THEN ''
							ELSE 'cEligibitilityCondtionID'+@cSep+B.EligibilityConditionID+@cSep+CHAR(13)+CHAR(10)
							END
							
							--+@cSep+CHAR(13)+CHAR(10)
						FROM dbo.Un_Beneficiary B
						JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
						JOIN Mo_Lang L ON L.LangID = H.LangID
						JOIN Mo_Sex S ON S.LangID = 'FRA' AND S.SexID = H.SexID
						JOIN Mo_CivilStatus CS ON CS.LangID = 'FRA' AND CS.SexID = H.SexID AND CS.CivilStatusID = H.CivilID
						JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'I'
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
		END
		ELSE -- IF @iBeneficiaryID IS NULL 
		BEGIN
			UPDATE dbo.Un_Beneficiary 
			SET
				iTutorID = @iTutorID,
				bTutorIsSubscriber = @bTutorIsSubscriber,
				GovernmentGrantForm = @GovernmentGrantForm,
				BirthCertificate = @BirthCertificate,
				PersonalInfo = @PersonalInfo,
				ProgramID = @ProgramID,
				CollegeID = @CollegeID,
				StudyStart = @StudyStart,
				ProgramLength = @ProgramLength,
				ProgramYear = @ProgramYear,
				RegistrationProof = @RegistrationProof,
				SchoolReport = @SchoolReport,
				EligibilityQty = @EligibilityQty,
				CaseOfJanuary = @CaseOfJanuary,
				tiPCGType = 
					CASE @tiPCGType
						WHEN 0 THEN 1
						WHEN 3 THEN 2
					ELSE @tiPCGType
					END, 
				vcPCGFirstName = @vcPCGFirstName,
				vcPCGLastName = @vcPCGLastName,
				vcPCGSINOrEN = @vcPCGSINOrEN,
				bPCGIsSubscriber = 
					CASE @tiPCGType
						WHEN 0 THEN 0
						WHEN 1 THEN 1
						WHEN 2 THEN 1
						WHEN 3 THEN 0
					END, 
				--tiCESPState = @tiCESPState, Ne pas mettre à jour ce champ puisqu'il sera recalculé plus loin par la procédure psCONV_EnregistrerPrevalidationPCEE
				EligibilityConditionID = @cEligibilityConditionID	-- 2010-01-19 : JFG : ajout
			WHERE BeneficiaryID = @BeneficiaryID

			IF @@ERROR <> 0
				SET @BeneficiaryID = -3

			-- Mettre à jour l'état des prévalidations du bénéficiaire
			EXEC @iErrorID = psCONV_EnregistrerPrevalidationPCEE @ConnectID, NULL, @BeneficiaryID, NULL, NULL

			IF @iErrorID <= 0 
					SET @BeneficiaryID = -12

			SELECT
				@tiCESPState = tiCESPState
			FROM dbo.Un_Beneficiary B
			WHERE B.BeneficiaryID = @BeneficiaryID

			IF EXISTS	(
					SELECT BeneficiaryID
					FROM dbo.Un_Beneficiary B
					JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
					WHERE B.BeneficiaryID = @BeneficiaryID
						AND	(	@vcOldFirstName <> H.FirstName
								OR	@vcOldOrigName <> H.OrigName
								OR	@vcOldInitial <> H.Initial
								OR @vcOldLastName <> H.LastName
								OR @cOldLangID <> H.LangID
								OR @cOldSexID <> H.SexID
								OR @cOldCivilID <> H.CivilID
								OR @dtOldBirthDate <> H.BirthDate
								OR @dtOldDeathDate <> H.DeathDate
								OR @iOldTutorID <> B.iTutorID
								-- Ajout des modifications du principal responsable dans la gestion des logs
								OR @tiOldPCGType <> B.tiPCGType
								OR ISNULL(@vcOldPCGLastName,'') <> ISNULL(B.vcPCGLastName,'')
								OR ISNULL(@vcOldPCGFirstName,'') <> ISNULL(B.vcPCGLastName,'')
								OR ISNULL(@vcOldPCGSINOrEN,'') <> ISNULL(B.vcPCGSINOrEN,'')
								OR @bOldPCGIsSubscriber <> B.bPCGIsSubscriber
								OR ISNULL(@vcOldNEQ,'') <> ISNULL(H.StateCompanyNo,'')
								OR @bOldAcceptePubli <> H.bHumain_Accepte_Publipostage
								OR @siOldEligibilityQty <> B.EligibilityQty
								OR @cOldEligibilityConditionID <> B.EligibilityConditionID
								)
							)
					AND @BeneficiaryID > 0
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
						'Un_Beneficiary',
						@BeneficiaryID,
						GETDATE(),
						LA.LogActionID,
						LogDesc = 'Bénéficiaire : '+H.LastName+', '+H.FirstName,
						LogText = 
							CASE 
								WHEN ISNULL(@vcOldFirstName,'') <> ISNULL(H.FirstName,'') THEN
									'FirstName'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldFirstName,'') = '' THEN ''
									ELSE @vcOldFirstName
									END+@cSep+
									CASE 
										WHEN ISNULL(H.FirstName,'') = '' THEN ''
									ELSE H.FirstName
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@vcOldLastName,'') <> ISNULL(H.LastName,'') THEN
									'LastName'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldLastName,'') = '' THEN ''
									ELSE @vcOldLastName
									END+@cSep+
									CASE 
										WHEN ISNULL(H.LastName,'') = '' THEN ''
									ELSE H.LastName
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@vcOldOrigName,'') <> ISNULL(H.OrigName,'') THEN
									'OrigName'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldOrigName,'') = '' THEN ''
									ELSE @vcOldOrigName
									END+@cSep+
									CASE 
										WHEN ISNULL(H.OrigName,'') = '' THEN ''
									ELSE H.OrigName
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@vcOldInitial,'') <> ISNULL(H.Initial,'') THEN
									'Initial'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldInitial,'') = '' THEN ''
									ELSE @vcOldInitial
									END+@cSep+
									CASE 
										WHEN ISNULL(H.Initial,'') = '' THEN ''
									ELSE H.Initial
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE
								WHEN @cOldLangID <> H.LangID THEN
									'LangID'+@cSep+@cOldLangID+@cSep+H.LangID+@cSep+OL.LangName+@cSep+L.LangName+@cSep+CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE
								WHEN @cOldSexID <> H.SexID THEN
									'SexID'+@cSep+@cOldSexID+@cSep+H.SexID+@cSep+OS.SexName+@cSep+S.SexName+@cSep+CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE
								WHEN @cOldCivilID <> H.CivilID THEN
									'CivilID'+@cSep+@cOldCivilID+@cSep+H.CivilID+@cSep+OCS.CivilStatusName+@cSep+CS.CivilStatusName+@cSep+CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@dtOldBirthDate,0) <> ISNULL(H.BirthDate,0) THEN
									'BirthDate'+@cSep+
									CASE 
										WHEN ISNULL(@dtOldBirthDate,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), @dtOldBirthDate, 20)
									END+@cSep+
									CASE 
										WHEN ISNULL(H.BirthDate,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), H.BirthDate, 20)
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE 
								WHEN ISNULL(@dtOldDeathDate,0) <> ISNULL(H.DeathDate,0) THEN
									'DeathDate'+@cSep+
									CASE 
										WHEN ISNULL(@dtOldDeathDate,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), @dtOldDeathDate, 20)
									END+@cSep+
									CASE 
										WHEN ISNULL(H.DeathDate,0) <= 0 THEN ''
									ELSE CONVERT(CHAR(10), H.DeathDate, 20)
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE
								WHEN @iOldTutorID <> B.iTutorID THEN
									'iTutorID'+@cSep+CAST(@iOldTutorID AS VARCHAR(30))+@cSep+CAST(B.iTutorID AS VARCHAR(30))+@cSep+OT.LastName+', '+OT.FirstName+@cSep+T.LastName+', '+T.FirstName+@cSep+CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE -- Ajout des modifications du principal responsable dans la gestion des logs. Tout est affich‚ si une des informations est modifi‚e
								WHEN (@bOldPCGIsSubscriber <> B.bPCGIsSubscriber) Or (@tiOldPCGType <> B.tiPCGType) OR 
									 ISNULL(@vcOldPCGLastName,'') <> ISNULL(B.vcPCGLastName,'') OR 
									 ISNULL(@vcOldPCGFirstName,'') <> ISNULL(B.vcPCGFirstName,'') OR 
									 ISNULL(@vcOldPCGSINOrEN,'') <> ISNULL(B.vcPCGSINOrEN,'') OR
									 ISNULL(@vcOldNEQ,'') <> ISNULL(H.StateCompanyNo,'') THEN
									'tiPCGType'+@cSep+
									CASE
										WHEN ISNULL(@tiOldPCGType,1) = 1 AND ISNULL(@bOldPCGIsSubscriber,0) = 0 THEN 
											'Personne'
										WHEN ISNULL(@tiOldPCGType,1) = 1 THEN 
											'Souscripteur'
										WHEN ISNULL(@tiOldPCGType,1) = 2 AND ISNULL(@bOldPCGIsSubscriber,0) = 0 THEN 
											'Entreprise'
										WHEN ISNULL(@tiOldPCGType,1) = 2 THEN 
											'Souscripteur'
									ELSE ''
									END+@cSep+
									CASE
										WHEN ISNULL(B.tiPCGType,1) = 1 AND ISNULL(B.bPCGIsSubscriber,0) = 0 THEN 
											'Personne'
										WHEN ISNULL(B.tiPCGType,1) = 1 THEN 
											'Souscripteur'
										WHEN ISNULL(B.tiPCGType,1) = 2 AND ISNULL(B.bPCGIsSubscriber,0) = 0 THEN 
											'Entreprise'
										WHEN ISNULL(B.tiPCGType,1) = 2 THEN 
											'Souscripteur'
									ELSE ''
									END+
									@cSep+CHAR(13)+CHAR(10)+
									'vcPCGLastName'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldPCGLastName,'') = '' THEN ''
									ELSE @vcOldPCGLastName
									END+@cSep+
									CASE 
										WHEN ISNULL(B.vcPCGLastName,'') = '' THEN ''
									ELSE B.vcPCGLastName
									END+@cSep+
									CHAR(13)+CHAR(10)+
									'vcPCGFirstName'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldPCGFirstName,'') = '' THEN ''
									ELSE @vcOldPCGFirstName
									END+@cSep+
									CASE 
										WHEN ISNULL(B.vcPCGFirstName,'') = '' THEN ''
									ELSE B.vcPCGFirstName
									END+@cSep+
									CHAR(13)+CHAR(10)+
									CASE 
										WHEN ISNULL(B.tiPCGType,1) = 1 THEN 'vcPCGSIN'
									ELSE 'vcPCGEN'
									END+
									@cSep+CAST(ISNULL(@vcOldPCGSINOrEN,0) AS VARCHAR)+@cSep+CAST(ISNULL(B.vcPCGSINOrEN,0) as varchar)+@cSep+CHAR(13)+CHAR(10)+									
									'NEQ'+@cSep+
									CASE 
										WHEN ISNULL(@vcOldNEQ,'') = '' THEN ''
									ELSE @vcOldNEQ
									END+@cSep+
									CASE 
										WHEN ISNULL(H.StateCompanyNo,'') = '' THEN ''
									ELSE H.StateCompanyNo
									END+@cSep+CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE
								WHEN ISNULL(@bOldAcceptePubli, 0) <> ISNULL(H.bHumain_Accepte_Publipostage, 0) THEN
									'bAcceptePublipostage'+@cSep+
									CAST(ISNULL(@bOldAcceptePubli,0) AS VARCHAR)+@cSep+
									CAST(ISNULL(H.bHumain_Accepte_Publipostage,0) AS VARCHAR)+@cSep+									
									CASE
										WHEN ISNULL(@bOldAcceptePubli, 0) = 0 THEN 'Non'
									ELSE 'Oui'
									END+@cSep+
									CASE 
										WHEN ISNULL(H.bHumain_Accepte_Publipostage,0) = 0 THEN 'Non'
									ELSE 'Oui'
									END+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE
								WHEN ISNULL(@siOldEligibilityQty, 0) <> ISNULL(B.EligibilityQty, 0) THEN
									'EligibilityQty'+@cSep+
									CAST(ISNULL(@siOldEligibilityQty,0) AS VARCHAR)+@cSep+
									CAST(ISNULL(B.EligibilityQty,0) AS VARCHAR)+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END+
							CASE
								WHEN ISNULL(@cOldEligibilityConditionID, '') <> ISNULL(B.EligibilityConditionID, 0) THEN
									'EligibilityConditionID'+@cSep+
									CAST(ISNULL(@cOldEligibilityConditionID,'') AS VARCHAR)+@cSep+
									CAST(ISNULL(B.EligibilityConditionID,0) AS VARCHAR)+@cSep+
									CHAR(13)+CHAR(10)
							ELSE ''
							END
						FROM dbo.Un_Beneficiary B
						JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
						JOIN Mo_Lang L ON L.LangID = H.LangID
						JOIN Mo_Lang OL ON OL.LangID = @cOldLangID
						JOIN Mo_Sex S ON S.SexID = H.SexID AND S.LangID = 'FRA'
						JOIN Mo_Sex OS ON OS.SexID = @cOldSexID AND OS.LangID = 'FRA'
						JOIN Mo_CivilStatus CS ON CS.LangID = 'FRA' AND CS.SexID = H.SexID AND CS.CivilStatusID = H.CivilID
						JOIN Mo_CivilStatus OCS ON OCS.LangID = 'FRA' AND OCS.SexID = @cOldSexID AND OCS.CivilStatusID = @cOldCivilID
						JOIN CRQ_LogAction LA ON LA.LogActionShortName = 'U'
						LEFT JOIN dbo.Mo_Human T ON T.HumanID = B.iTutorID
						LEFT JOIN dbo.Mo_Human OT ON OT.HumanID = @iOldTutorID
						WHERE B.BeneficiaryID = @BeneficiaryID

				IF @@ERROR <> 0
					SET @BeneficiaryID = -4
			END
			/*
			-- Lettre d'émission au tuteur légal sur changement de tuteur :
			-- Lorsqu'un bénéficiaire changera de tuteur, qu'il ne sera pas le souscripteur, que sont code postal sera différent 
			-- de celui du souscripteur ou que le lien ne sera pas père/mère et qu'aucun document de type Lettre d'émission 
			-- au tuteur légal n'aura précédemment été commandé (historique) pour cette convention, alors le système en commandera 
			-- un automatiquement.  
			DECLARE cBnfTutorLetter CURSOR FOR
				SELECT DISTINCT C.ConventionID
				FROM dbo.Un_Beneficiary B
				JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
				JOIN dbo.Mo_Human HT ON HT.HumanID = B.iTutorID
				JOIN dbo.Mo_Adr AdT ON AdT.AdrID = HT.AdrID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
				JOIN dbo.Mo_Adr AdS ON AdS.AdrID = HS.AdrID
				WHERE B.BeneficiaryID = @BeneficiaryID -- Filtre sur les conventions de ce bénéficiaire
					AND B.iTutorID <> C.SubscriberID -- Le tuteur n'est pas le souscripteur
					AND @iOldTutorID <> B.iTutorID -- Le tuteur a changé
					AND( C.tiRelationshipTypeID <> 1 -- Le lien n'est pas père/mère
						OR AdS.ZipCode <> AdT.ZipCode -- Le code postal du tuteur est différent de celui du souscripteur
						)
					AND ConventionID NOT IN -- La lettre n'a pas été précédemment commandé pour cette convention.
								(
								SELECT
									C.ConventionID
								FROM CRQ_DocType T
								JOIN CRQ_DocTemplate DT ON DT.DocTypeID = T.DocTypeID
								JOIN CRQ_Doc D ON D.DocTemplateID = DT.DocTemplateID
								JOIN CRQ_DocLink L ON L.DocID = D.DocID AND L.DocLinkType = 1
								JOIN dbo.Un_Convention C ON C.ConventionID = L.DocLinkID
								WHERE T.DocTypeCode = 'TutorLetter'
									AND C.BeneficiaryID = @BeneficiaryID -- Filtre sur les conventions de ce bénéficiaire
								)
					AND ConventionID IN -- Un PRD ou un CPA a été versée
								(
								SELECT DISTINCT
									U.ConventionID
								FROM dbo.Un_Convention C
								JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
								JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
								JOIN Un_Oper O ON O.OperID = Ct.OperID
								WHERE C.BeneficiaryID = @BeneficiaryID -- Filtre sur les conventions de ce bénéficiaire
									AND O.OperTypeID IN ('CPA', 'PRD')
								)
					AND ConventionID NOT IN -- Exclu les conventions fermées
								(
								SELECT 
									T.ConventionID
								FROM (-- Retourne la plus grande date de début d'un état par convention
									SELECT 
										S.ConventionID,
										MaxDate = MAX(S.StartDate)
									FROM dbo.Un_Convention C
									JOIN Un_ConventionConventionState S ON C.ConventionID = S.ConventionID
									WHERE C.BeneficiaryID = @BeneficiaryID
										AND S.StartDate <= GETDATE()
									GROUP BY S.ConventionID
									) T
								JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'‚tat correspondant à la plus grande date par convention
								WHERE CCS.ConventionStateID = 'FRM'
								)

			OPEN cBnfTutorLetter

			FETCH NEXT FROM cBnfTutorLetter
			INTO
				@iConventionID

			WHILE @@FETCH_STATUS = 0 AND @BeneficiaryID > 0
			BEGIN
				-- Lettre d'émission au tuteur légal
				EXECUTE @iErrorID = RP_UN_TutorLetter @ConnectID, @iConventionID, 0

				--SELECT @iErrorID, @iConventionID

				IF @iErrorID <= 0 
					SET @BeneficiaryID = -5

				FETCH NEXT FROM cBnfTutorLetter
				INTO
					@iConventionID
			END

			CLOSE cBnfTutorLetter
			DEALLOCATE cBnfTutorLetter
			*/		
		END
	END
	
	IF @BeneficiaryID > 0
	BEGIN
		-- Gestion de l'historique des NAS
		EXECUTE @iErrorID = TT_UN_HumanSocialNumber @ConnectID, @BeneficiaryID, @SocialNumber
	
		IF @iErrorID < 0 
			SET @BeneficiaryID = -6
	END
	/*
	-- Quand la preuve d'inscription est complète, le statut des bourses de la liste des PAE reliées à ce bénéficiaire 
	-- change pour A payer .
	IF ISNULL(@CollegeID,0) > 0
	AND ISNULL(@StudyStart,0) > 0
	AND ISNULL(@ProgramLength,0) > 0
	AND ISNULL(@ProgramYear,0) > 0
	AND @RegistrationProof <> 0
	AND @SchoolReport <> 0
	AND @BeneficiaryID > 0
	BEGIN
		UPDATE Un_Scholarship
		SET ScholarshipStatusID = 'TPA'
		FROM Un_Scholarship S
		JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
		WHERE C.BeneficiaryID = @BeneficiaryID
			AND S.ScholarshipStatusID IN ('ADM','WAI')
			AND S.ScholarshipID IN 
					(
					SELECT DISTINCT
						ScholarshipID
					FROM Un_ScholarshipStep
					)

		IF @@ERROR <> 0
			SET @BeneficiaryID = -7
	END
	*/
	/* -- Maintenant géré par la procédure psCONV_EnregistrerPrevalidationPCEE
	-- Gestion des enregistrements 100, 200 et 400
	IF @BeneficiaryID > 0
	AND @tiCESPState <> @tiOldCESPState
	BEGIN
		-- Met à jour l'état de pré-validations des conventions du bénéficiaire
		UPDATE dbo.Un_Convention 
		SET tiCESPState = 
				CASE 
					WHEN ISNULL(CS.tiCESPState,1) = 0 
						OR S.tiCESPState = 0 
						OR B.tiCESPState = 0 THEN 0
				ELSE B.tiCESPState
				END
		FROM dbo.Un_Convention 
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = Un_Convention.BeneficiaryID
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = Un_Convention.SubscriberID
		LEFT JOIN dbo.Un_Subscriber CS ON CS.SubscriberID = Un_Convention.CoSubscriberID
		WHERE B.BeneficiaryID = @BeneficiaryID
			AND Un_Convention.tiCESPState <> 
						CASE 
							WHEN ISNULL(CS.tiCESPState,1) = 0 
								OR S.tiCESPState = 0 
								OR B.tiCESPState = 0 THEN 0
						ELSE B.tiCESPState
						END

		IF @@ERROR <> 0
			SET @BeneficiaryID = -8
	END
*/
	-- Si l'on saisi les infos du PR, alors on coche 'Formulaire reçu'
	IF  (
			ISNULL(@vcOldPCGLastName,'') = ''
			AND ISNULL(@vcOldPCGFirstName,'') = ''
			AND ISNULL(@vcOldPCGSINOrEN,'') = ''
		)
		AND (
			ISNULL(@vcPCGLastName,'')<>''
			AND ISNULL(@vcPCGLastName,'')<>''
			AND ISNULL(@vcPCGSINOrEN,'')<>''
			)
		AND ISNULL(@SocialNumber,'') <>'' 
	BEGIN
/*
		UPDATE dbo.Un_Convention 
		SET bFormulaireRecu = 1
		WHERE BeneficiaryID = @BeneficiaryID
	
		UPDATE dbo.Un_Convention 
		SET bCESGRequested = 1
		WHERE bCESGRequested = 0
			AND tiCESPState IN (1,2,3,4) -- État de la convention permet la demande de la SCEE+ 
			AND ConventionID IN ( -- Convention dont l'état n'est pas fermé
					SELECT 
						T.ConventionID
					FROM (-- Retourne la plus grande date de début d'un état par convention
						SELECT 
							S.ConventionID,
							MaxDate = MAX(S.StartDate)
						FROM Un_ConventionConventionState S
						JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
						WHERE C.BeneficiaryID = @BeneficiaryID
						  AND S.StartDate <= GETDATE()
						GROUP BY S.ConventionID
						) T
					JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
					WHERE CCS.ConventionStateID = 'REE' -- La convention est REE.
					)
			AND NOT EXISTS(	SELECT 1 FROM dbo.Un_Unit ut WHERE ut.ConventionID = Un_Convention.ConventionID AND ut.IntReimbDate IS NOT NULL) -- 2010-10-24 PPA: Pas de RI.

		UPDATE dbo.Un_Convention 
		SET bACESGRequested = 1
		WHERE bACESGRequested = 0
			AND tiCESPState IN (3,4) -- État de la convention permet la demande de la SCEE+ 
			AND ConventionID IN ( -- Convention dont l'état n'est pas fermé
					SELECT 
						T.ConventionID
					FROM (-- Retourne la plus grande date de début d'un état par convention
						SELECT 
							S.ConventionID,
							MaxDate = MAX(S.StartDate)
						FROM Un_ConventionConventionState S
						JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
						WHERE C.BeneficiaryID = @BeneficiaryID
						  AND S.StartDate <= GETDATE()
						GROUP BY S.ConventionID
						) T
					JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
					WHERE CCS.ConventionStateID = 'REE' -- La convention est REE.
					)
			AND NOT EXISTS(	SELECT 1 FROM dbo.Un_Unit ut WHERE ut.ConventionID = Un_Convention.ConventionID AND ut.IntReimbDate IS NOT NULL) -- 2010-10-24 PPA: Pas de RI.
			
			-- Demande de BEC suite à l'ajout du principal responsable.
			
			UPDATE dbo.Un_Convention 
			SET bCLBRequested = 1
			WHERE dbo.fnCONV_ObtenirConventionBEC(@BeneficiaryID, 1, NULL) = UN_Convention.ConventionID
				AND @BeneficiaryID NOT IN ( SELECT BeneficiaryID 
											FROM dbo.UN_Convention C
											WHERE C.BeneficiaryID = @BeneficiaryID
											AND C.bCLBRequested = 1)
				AND @BirthDate > '2003-12-31'
*/

-----------------
			-- Déclaration des tables temporaires pour les NAS.
			DECLARE @NASSouscripteur TABLE (vcNAS VARCHAR(75))
			DECLARE @NASBeneficiaire TABLE (vcNAS VARCHAR(75))
			DECLARE @vcLigneBlob VARCHAR(MAX)
			DECLARE @vcLigneBlobCotisation VARCHAR(MAX)
			DECLARE @iCompteLigne INT
			DECLARE @iIDOperCur INT
			DECLARE @iIDCotisationCur INT
			DECLARE @dtDateOperCur DATETIME
			DECLARE @iID_OperTypeBlob VARCHAR(MAX)
			DECLARE @iIDBlob INT
			DECLARE @iIDCotisationBlob INT
			DECLARE @ConventionID INT

				-- Récupération des NAS du bénéficiaire
				INSERT INTO @NASBeneficiaire (vcNAS)
				SELECT SocialNumber
				FROM UN_HumanSocialNumber 
				WHERE HumanID = @BeneficiaryID

				INSERT INTO @NASBeneficiaire (vcNAS)
				SELECT SocialNumber
				FROM dbo.Mo_Human H
				WHERE H.HumanID = @BeneficiaryID

				-- Récupération des NAS du souscripteur
				INSERT INTO @NASSouscripteur (vcNAS)
				SELECT SocialNumber
				FROM UN_HumanSocialNumber 
				WHERE HumanID IN (SELECT subscriberID FROM dbo.Un_Convention WHERE BeneficiaryID = @BeneficiaryID)

				-- Vérifier s'il existe des transactions 400-11 envoyées avant la date du jour dont la subvention n'avait pas été demandée (même bénéficiaire et même souscripteur) Et pas plus vieille que 36 mois.
				-- Si oui, alors on renverse ces transactions et on les envoi à nouveau avec demande de subvention = oui.

				-- Il faut boucler sur chaque convention du bénéficiaire.
				DECLARE curConvention CURSOR LOCAL FAST_FORWARD FOR
					SELECT  
						T.ConventionID
					FROM (-- Retourne la plus grande date de début d'un état par convention
						SELECT 
							S.ConventionID,
							MaxDate = MAX(S.StartDate)
						FROM Un_ConventionConventionState S
						JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
						WHERE C.BeneficiaryID = @BeneficiaryID
						  AND S.StartDate <= GETDATE()
						GROUP BY S.ConventionID
						) T
					JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
					WHERE CCS.ConventionStateID <> 'FRM' -- La convention n'est pas fermée

				OPEN curConvention
				FETCH NEXT FROM curConvention INTO @ConventionID
					WHILE @@FETCH_STATUS = 0
						BEGIN				
						-- Faire la liste des transactions PAR convention.
						DECLARE curBlob	CURSOR LOCAL FAST_FORWARD FOR
							SELECT C4.OperID, C4.CotisationID, C4.dtTransaction, O.OperTypeID 
								FROM UN_CESP400 C4 
								LEFT OUTER JOIN UN_CESP400 R4 ON C4.iCESP400ID = R4.iReversedCESP400id
								LEFT OUTER JOIN UN_Oper O ON C4.OperID = O.OperID
								WHERE 
								C4.ConventionID = @ConventionID
								AND C4.tiCESP400TypeID = 11 --Type cotisation.
								AND C4.bCESPDemand = 0 --Subvention non-demandée.
								AND C4.iCESP800ID IS NULL
								AND C4.vcBeneficiarySIN IN (SELECT vcNAS FROM @NASBeneficiaire) -- Gérer les changements de NAS.
								AND C4.vcSubscriberSINorEN IN (SELECT vcNAS FROM @NASSouscripteur) -- Gérer les changements de NAS.
								AND R4.iCESP400ID IS NULL -- Pas annulé
								AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
								AND DATEDIFF(Month, C4.dtTransaction, GETDATE()) <= 36 -- À revoir avec la notion du 7ème jour du mois suivant.
								AND C4.dtTransaction < GETDATE()
				
						-- INITIALISATION DES VARIABLES CONTENANT LES BLOBS							
						SET @vcLigneBlob			= ''
						SET @vcLigneBlobCotisation	= ''
						SET @iCompteLigne			= 0

						-- CONSTRUCTION DES BLOBS
						OPEN curBlob
						FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur, @iID_OperTypeBlob
							WHILE @@FETCH_STATUS = 0
										BEGIN
											SET @vcLigneBlob			= @vcLigneBlob + 'Un_Oper' + ';' + CAST(@iCompteLigne AS VARCHAR(10)) + ';' + CAST(ISNULL(@iIDOperCur,'') AS VARCHAR(8)) + ';' + CAST(@ConnectID AS VARCHAR(10)) + ';' + CAST(ISNULL(@iID_OperTypeBlob,'') AS VARCHAR(10)) + ';' + ';' + CONVERT(VARCHAR(25), ISNULL(@dtDateOperCur,''), 121) + CHAR(13) + CHAR(10)
											SET @vcLigneBlobCotisation	= @vcLigneBlobCotisation + CAST(ISNULL(@iIDCotisationCur,'') AS VARCHAR(10)) + ','
											FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur, @iID_OperTypeBlob
										END
							CLOSE curBlob
							DEALLOCATE curBlob
		
						IF (RTRIM(LTRIM(@vcLigneBlobCotisation)) <> '' AND RTRIM(LTRIM(@vcLigneBlobCotisation)) <> ',')
						BEGIN
							-- INSERTION DES BLOBS
							EXECUTE @iIDBlob			= dbo.IU_CRI_BLOB 0, @vcLigneBlob
							EXECUTE @iIDCotisationBlob	= dbo.IU_CRI_BLOB 0, @vcLigneBlobCotisation
							
							-- RENVERSEMENT ET RENVOIS DES TRANSACTIONS
							EXEC dbo.IU_UN_ReSendCotisationCESP400 @ConventionID, @iIDCotisationBlob, @iIDBlob, @ConnectID,  1 -- 2010-04-29 : JFG : Ajout de @bSansVerificationPCEE400
						END				

						FETCH NEXT FROM curConvention INTO @ConventionID
						END
				CLOSE curConvention
				DEALLOCATE curConvention
	END

	IF @tiCESPState IN (2,4) -- Éligible au BEC
	AND @tiOldCESPState NOT IN (2,4) -- N'était pas éligible avant
	AND @BeneficiaryID > 0
	AND @iOldBeneficiaryID > 0 -- Édition seulement
	
	BEGIN
		-- Si le bénéficiaire est éligible au BEC (Date de naissance après le 31 décembre 2003 et information du principale responsable 
		-- remplis), on demande le BEC automatiquement pour la plus vieille convention de ce dernier dont la case à cocher SCEE  est
		-- cochée
/*
		UPDATE dbo.Un_Convention 
		SET bCLBRequested = 1
		WHERE dbo.fnCONV_ObtenirConventionBEC(@BeneficiaryID, 1, NULL) = UN_Convention.ConventionID
			AND @BeneficiaryID NOT IN ( SELECT BeneficiaryID 
										FROM dbo.UN_Convention C
										WHERE C.BeneficiaryID = @BeneficiaryID
										AND C.bCLBRequested = 1)
*/
		-- Création des transactions BEC
		DECLARE @iID_ConventionBEC INT
		DECLARE @dtToday DATETIME
		DECLARE @dDateEntreeREEE DATETIME
		-- Récupérer la bonne convention BEC.
		SET @iID_ConventionBEC = (dbo.fnCONV_ObtenirConventionBEC(@BeneficiaryID, 0, NULL))
		SET @dtToday = (GETDATE())
		SET @dDateEntreeREEE = (SELECT dtRegStartDate FROM dbo.UN_Convention WHERE ConventionID = @iID_ConventionBEC)
		
		-- S'il y a une convention BEC et une date dtRegStartDAte, alors on génère la transaction 400.
		IF (@iID_ConventionBEC > 0) AND (dbo.FN_CRQ_DateNoTime(@dDateEntreeREEE) <= @dtToday) -- Ne pas créer de BEC avant la date d'entrée en REEE
		BEGIN
			EXEC TT_UN_CLB @iID_ConventionBEC
		END

		IF @@ERROR <> 0
			SET @BeneficiaryID = -9
	END

	/* -- Maintenant géré par la procédure psCONV_EnregistrerPrevalidationPCEE
	IF @tiCESPState IN (3,4) -- Éligible à la SCEE+
	AND @tiOldCESPState NOT IN (3,4) -- N'était pas éligible avant
	AND @BeneficiaryID > 0
	AND @iOldBeneficiaryID > 0 -- Édition seulement
	
	BEGIN
		-- Si le bénéficiaire est éligible à la SCEE+ (Les informationa du principale responsable sont remplis), on demande la SCEE+
		-- automatiquement pour toutes les conventions de ce dernier dont la case à cocher SCEE est cochée et qui ne sont pas fermées
		UPDATE dbo.Un_Convention 
		SET bACESGRequested = 1
		WHERE bACESGRequested = 0
			AND bCESGRequested = 1 -- Seulement les conventions dont la SCEE est cochée
			AND tiCESPState IN (3,4) -- État de la convention permet la demande de la SCEE+ 
			AND ConventionID IN ( -- Convention dont l'état n'est pas fermé
					SELECT 
						T.ConventionID
					FROM (-- Retourne la plus grande date de début d'un état par convention
						SELECT 
							S.ConventionID,
							MaxDate = MAX(S.StartDate)
						FROM Un_ConventionConventionState S
						JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
						WHERE C.BeneficiaryID = @BeneficiaryID
						  AND S.StartDate <= GETDATE()
						GROUP BY S.ConventionID
						) T
					JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
					WHERE CCS.ConventionStateID <> 'FRM' -- La convention n'est pas fermée
					)
			AND NOT EXISTS(	SELECT 1 FROM dbo.Un_Unit ut WHERE ut.ConventionID = Un_Convention.ConventionID AND ut.IntReimbDate IS NOT NULL) -- 2010-10-24 PPA: Pas de RI.
			
		IF @@ERROR <> 0
			SET @BeneficiaryID = -10
	END
	*/
	IF --@tiCESPState >= 1
	--AND 
	@BeneficiaryID > 0
	AND EXISTS (	SELECT B.BeneficiaryID
						FROM dbo.Un_Beneficiary B
						JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
						JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
						WHERE B.BeneficiaryID = @BeneficiaryID
							-- Vérifie s'il y a des informations modifiés qui affecte les enregistrements 100, 200 ou 400
							OR H.LastName <> @vcOldLastName
							OR H.FirstName <> @vcOldFirstName
							OR H.SocialNumber <> @vcOldSocialNumber
							OR H.SexID <> @cOldSexID
							OR H.BirthDate <> @dtOldBirthDate
							OR H.LangID <> @cOldLangID
							OR A.Address <> @vcOldAddress
							OR A.City <> @vcOldCity
							OR A.Statename <> @vcOldStateName
							OR A.ZipCode <> @vcOldZipCode
							OR A.CountryID <> @cOldCountryID
							OR B.tiCESPState <> @tiOldCESPState
							OR B.iTutorID <> @iOldTutorID
							OR B.tiCESPState <> @tiOldCESPState
							OR B.vcPCGSINOrEN <> @vcOldPCGSINOrEN
							OR B.vcPCGFirstName <> @vcOldPCGFirstName
							OR B.vcPCGLastName <> @vcOldPCGLastName
					)
	BEGIN
		DECLARE 
			@iExecResult INTEGER

		-- Appelle de la procédure stockée qui gère les enregistrements 100, 200, et 400 de toutes les conventions du bénéficiaire.
		EXECUTE @iExecResult = TT_UN_CESPOfConventions @ConnectID, @BeneficiaryID, 0, 0

		IF @iExecResult <= 0
			SET @BeneficiaryID = -11
		
		-- 2009-11-23 : Modification pour la gestion du BEC
		-- Si des informations du principal responsable changent, alors on doit recréer la demande de BEC.
		DECLARE @iIDConventionBEC INT

		-- Obtenir la bonne convention BEC
		SET @iIDConventionBEC = (SELECT dbo.fnCONV_ObtenirConventionBEC (@BeneficiaryID, 0, NULL))

		--IF @iIDConventionBEC IS NOT NULL	-- On a récupéré un BEC Actif sur une convention et les données du responsable principal ont changé
		IF (@iIDConventionBEC > 0) AND				
			(															-- Vérifier s'il y a un changement de principal responsable ou si l'une ou plusieurs données du principal responsable ont changé
				(@vcPCGSINOrEN		<> @vcOldPCGSINOrEN)
				OR
				(@vcPCGFirstName	<> @vcOldPCGFirstName)
				OR
				(@vcPCGLastName		<> @vcOldPCGLastName)
			)

		-- On a récupéré un BEC Actif sur une convention et les données du responsable principal ont changé
			BEGIN							-- Création d'une nouvelle demande de BEC
				EXECUTE @iExecResult = dbo.psPCEE_CreerDemandeBec @iIDConventionBEC		
				
				IF @iExecResult <= 0
					SET @BeneficiaryID = @iExecResult
			END

	END
	
	-- Fin des traitements
	IF @BeneficiaryID > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		---------------------
		ROLLBACK TRANSACTION
		---------------------	
	
	RETURN @BeneficiaryID
END


