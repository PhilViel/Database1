/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_Beneficiary
Description         :	Procédure de rafraîchissement d’un bénéficiaire.
Valeurs de retours  :	Dataset de données
Note                :	ADX0001067	BR 2004-08-27	Bruno Lapointe		Migration, normalisation et correction.
								ADX0000692	IA	2005-05-04	Bruno Lapointe		Modification des valeurs retournées pours les 
																							tuteurs.
								ADX0000730	IA	2005-06-22	Bruno Lapointe		Enlever le ProgramCode
								ADX0000706	IA	2005-07-13	Bruno Lapointe		Ajout de la valeur de retour bAddressLost
								ADX0000826	IA	2006-03-14	Bruno Lapointe		Adaptation des bénéficiaires pour PCEE 4.3
								ADX0000798	IA	2006-03-17	Bruno Lapointe		Saisie des principaux responsables
												2008-10-02	Patrick Robitaille	Ajout du champ vcNEQ
												2009-02-12  Patrick Robitaille	Ajout du champ vcNIP dans la table Mo_Human
												2009-06-16	Patrick Robitaille	Ajout du champ bBeneficiaire_Accepte_Publipostage
												2010-01-18	Jean-François Gauthier	Ajout du champ EligibilityConditionID (table Un_Beneficiary) en retour
												2012-05-16	Donald Huppé			Ajout de bConsentement_Beneficiaire = B.bConsentement
												2012-07-17	Eric Michaud			Ajout des champs vcDossierBeneficiaire
												2014-02-20	Pierre-Luc Simard	Utilisation du champ bReleve_Papier au lieu de bConsenement
                                                2018-09-26  Pierre-Luc Simard   Ajout de l'audit dans la table tblGENE_AuditHumain
												2018-11-20	Maxime Martel			Utilisation du champ sur le beneficiaire pour EligibilityConditionID
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_Beneficiary] (
	@BeneficiaryID INTEGER)
AS
BEGIN
	SELECT
		B.iTutorID, -- ID du tuteur, correspond au HumanID
		B.bTutorIsSubscriber, -- True : le tuteur est un souscripteur (Un_BeneficiaryID.iTutorID = Un_Subscriber.iTutorID).  False : le tuteur est un tuteur (Un_BeneficiaryID.iTutorID = Un_Tutor.iTutorID).
		TutorLastName = Tuh.LastName, -- Nom du tuteur.
		TutorFirstName = TuH.FirstName, -- Prénom du tuteur.
		B.GovernmentGrantForm,
		B.BirthCertificate,
		B.PersonalInfo, 
		B.ProgramID,
		B.ProgramLength,
		B.ProgramYear,
		B.SchoolReport,  
		B.RegistrationProof, 
		B.StudyStart, 
		B.CaseOfJanuary,  
		B.EligibilityQty,  
		B.CollegeID,  
		B.tiCESPState, -- État du bénéficiaire au niveau des pré-validations. (0 = Rien ne passe, 1 = Seul la SCEE passe, 2 = SCEE et BEC passe, 3 = SCEE et SCEE+ passe et 4 = SCEE, BEC et SCEE+ passe)
		B.bAddressLost, -- Champs boolean indiquant si l'on a perdu l'adresse du bénéficiaire (=0:Non, <>0:Oui).
		tiPCGType =
			CASE 
				WHEN B.tiPCGType = 1 AND B.bPCGIsSubscriber = 0 THEN 0
				WHEN B.tiPCGType = 1 AND B.bPCGIsSubscriber = 1 THEN 1
				WHEN B.tiPCGType = 2 AND B.bPCGIsSubscriber = 1 THEN 2
				WHEN B.tiPCGType = 2 AND B.bPCGIsSubscriber = 0 THEN 3
			END, -- Type de principal responsable. (0=Personne, 1=Souscripteur, 2=Entreprise-Souscripteur, 3=Entreprise)
		B.vcPCGFirstName, -- Prénom du principal responsable s’il s’agit d’un souscripteur ou d’une personne. Nom de l’entreprise principal responsable dans l’autre cas.
		B.vcPCGLastName, -- Nom du principal responsable s’il s’agit d’un souscripteur ou d’une personne.
		B.vcPCGSINOrEN, -- NAS du principal responsable si le type est personne ou souscripteur.  NE si le type est entreprise.
		Co.CollegeTypeID, 
		B.EligibilityConditionID, 
		Co.CollegeCode, 
		CollegeName = CoCo.CompanyName, 
		Prog.ProgramDesc, 
		H.FirstName,
		H.OrigName,
		H.Initial,
		H.LastName,
		BirthDate = dbo.fn_Mo_IsDateNull(H.BirthDate),
		DeathDate = dbo.fn_Mo_IsDateNull(H.DeathDate),
		H.SexID,
		H.LangID,
		H.CivilID,
		H.SocialNumber,
		H.ResidID,
		H.DriverLicenseNo,
		H.WebSite,
		H.CompanyName,
		H.CourtesyTitle,
		H.UsingSocialNumber,
		H.SharePersonalInfo,
		H.MarketingMaterial,
		H.IsCompany,
		vcNIP = ISNULL(H.vcNIP, ''),
		SourceID = A.AdrID,
		A.AdrTypeID,
		A.InForce,
		A.Address,
		A.City,
		A.StateName,
		A.CountryID,
		A.ZipCode,
		Phone1 = dbo.fn_Mo_FormatPhoneNo(A.Phone1, A.CountryID),
		Phone2 = dbo.fn_Mo_FormatPhoneNo(A.Phone2, A.CountryID),
		Fax = dbo.fn_Mo_FormatPhoneNo(A.Fax, A.CountryID),
		Mobile = dbo.fn_Mo_FormatPhoneNo(A.Mobile, A.CountryID),
		WattLine = dbo.fn_Mo_FormatPhoneNo(A.WattLine, A.CountryID),
		OtherTel = dbo.fn_Mo_FormatPhoneNo(A.OtherTel, A.CountryID),
		Pager = dbo.fn_Mo_FormatPhoneNo(A.Pager, A.CountryID),
		A.EMail,
		ResidCountryName = R.CountryName,
		C.CountryName,
		vcNEQ = H.StateCompanyNo,
		bBeneficiaire_Accepte_Publipostage = H.bHumain_Accepte_Publipostage,
		IDConditionEligibleBenef = B.EligibilityConditionID
		,bConsentement_Beneficiaire = ISNULL(B.bReleve_Papier,0)  
		,vcDossierBeneficiaire = GPB.vcValeur_Parametre +'\'+ dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(H.lastname)),1,1)) + '\' + replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(H.lastname)),' ','_')) + '_' + replace(LTRIM(RTRIM(H.firstname)),' ','_') + '_' + cast(H.humanid as varchar(20))),'.',''),',',''),'&','Et')
        ,B.BeneficiaryID
    INTO #tSL_UN_Beneficiary
	FROM dbo.Un_Beneficiary B
	JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
	LEFT JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	LEFT JOIN Un_College Co ON Co.CollegeID = B.CollegeID
	LEFT JOIN Un_Program Prog  ON Prog.ProgramID = B.ProgramID
	LEFT JOIN Mo_Company CoCo ON CoCo.CompanyID = Co.CollegeID
	LEFT JOIN Mo_Country R ON R.CountryID = H.ResidID
	LEFT JOIN Mo_Country C ON C.CountryID = A.CountryID
	LEFT JOIN dbo.Mo_Human TuH ON TuH.HumanID = B.iTutorID
	LEFT JOIN tblGENE_TypesParametre GTPB on GTPB.vcCode_Type_Parametre = 'REPERTOIRE_DOSSIER_CLIENT_BENEFICIAIRE'
	LEFT JOIN tblGENE_Parametres GPB ON GTPB.iID_Type_Parametre = GPB.iID_Type_Parametre
	WHERE BeneficiaryID = @BeneficiaryID

    SELECT * FROM #tSL_UN_Beneficiary

    ----------------
    -- AUDIT - DÉBUT
    ----------------
    BEGIN 
        DECLARE 
            @vcAudit_Utilisateur VARCHAR(75) = dbo.GetUserContext(),
            @vcAudit_Contexte VARCHAR(75) = OBJECT_NAME(@@PROCID)
    
        -- Ajout de l'audit dans la table tblGENE_AuditHumain
        EXEC psGENE_AuditAcces 
            @vcNom_Table = '#tSL_UN_Beneficiary', 
            @vcNom_ChampIdentifiant = 'BeneficiaryID', 
            @vcUtilisateur = @vcAudit_Utilisateur, 
            @vcContexte = @vcAudit_Contexte, 
            @bAcces_Courriel = 1, 
            @bAcces_Telephone = 1, 
            @bAcces_Adresse = 1
    --------------
    -- AUDIT - FIN
    --------------
    END 
END