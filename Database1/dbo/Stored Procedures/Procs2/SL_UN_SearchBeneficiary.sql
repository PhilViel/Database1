/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchBeneficiary
Description         :	Procédure de recherche de bénéficiaire.
Valeurs de retours  :	Dataset :
									BeneficiaryID	INTEGER			ID du tuteur, correspond au HumanID.
									FirstName		VARCHAR(35)		Prénom du tuteur
									LastName			VARCHAR(50)		Nom
									SocialNumber	VARCHAR(75)		Numéro d’assurance sociale
									Address			VARCHAR(75)		# civique, rue et # d’appartement.
									City 				VARCHAR(100)	Ville
									Statename		VARCHAR(75)		Province
									ZipCode			VARCHAR(10)		Code postal
									Phone1			VARCHAR(27)		Tél. résidence
									BirthDate		DATETIME			Date de naissance
									tiCESPState		TINYINT			État des pré-validations PCEE

Exemple d'appel :
		
		DECLARE @i INT
		EXECUTE @i = dbo.SL_UN_SearchBeneficiary 2, 'LNa', '%Sombreffe%', 0
		PRINT @i
	
Note                :						IA	2004-05-05	Dominic Létourneau	Migration de l'ancienne procedure selon les nouveaux standards
											IA	2004-05-13	Dominic Létourneau	Critère de recherche sur date de naissance entre 2 dates
								ADX0000553	BR	2004-06-09	Bruno Lapointe			Correction
								ADX0000831	IA	2006-03-21	Bruno Lapointe			Adaptation des conventions pour PCEE 4.3
								ADX0001185	IA	2006-11-22	Bruno Lapointe			Optimisation
								ADX0001234	IA	2007-03-14	Alain Quirion			Ajout de champs pour la recherche dans la fusion
												2008-11-17	Donald Huppé			Recherche par "PHO" : On recherche maintenant dans tous les champs de numéro de téléphone
												2008-12-11	Pierre-Luc Simard		Recherche par nom et prénom sans tenir compte des accents
												2009-11-06	Jean-François Gauthier	Ajout de plusieurs champs de retour
												2009-11-09	Jean-François Gauthier	Ajout du nom / prénom du tuteur
												2010-01-29	Jean-François Gauthier	Ajout du critère de recherche IDs afin de chercher avec l'identifiant du bénéficiaire
												2010-02-03	Jean-François Gauthier	Remplacement du champ vcPCGNASOrNE par vcPCGSINorEN
																					et correction d'un alias en double.
												2011-07-28	Christian Chénard		Ajout de la recherche par courriel
												2014-08-04	Maxime Martel			Supprime les caractères non affichable lors de copier coller
****************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchBeneficiary] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@SearchType CHAR(3), -- Type de recherche: LNa(Nom, prénom), FNa(Prénom, nom), SNu(Nas), Pho(Telephone), BDa(Date de naissance), IDs (Identifiant unique)
	@Search VARCHAR(87), -- Critère de recherche
	@RepID INTEGER = 0) -- Identifiant unique du représentant (0 pour tous)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT

	SET @dtBegin = GETDATE()
	SET @Search = dbo.fnGENE_RetirerCaracteresNonAffichable(@Search)
	
	DECLARE @tSearchBenef TABLE (
		HumanID INTEGER PRIMARY KEY)

	-- Nom, prénom
	IF @SearchType = 'LNa'
		INSERT INTO @tSearchBenef
			SELECT HumanID
			FROM dbo.Mo_Human
			WHERE LastName + ', ' + FirstName COLLATE French_CI_AI LIKE @Search
	-- Prénom, nom
	ELSE IF @SearchType = 'FNa'
		INSERT INTO @tSearchBenef
			SELECT HumanID
			FROM dbo.Mo_Human
			WHERE FirstName + ', ' + LastName COLLATE French_CI_AI LIKE @Search
	-- Numéro d'assurance social
	ELSE IF @SearchType = 'SNu'
		INSERT INTO @tSearchBenef
			SELECT HumanID
			FROM dbo.Mo_Human
			WHERE SocialNumber LIKE @Search
	-- Numéro de téléphone résidentiel
	ELSE IF @SearchType = 'Pho'
		INSERT INTO @tSearchBenef
			SELECT H.HumanID
			FROM dbo.Mo_Adr A
			JOIN dbo.Mo_Human H ON A.AdrID = H.AdrID
			WHERE A.Phone1 LIKE @Search 
				or A.Phone2 like @Search 
				or A.Fax like @Search 
				or A.Mobile like @Search 
				or A.WattLine like @Search 
				or A.OtherTel like @Search 
				or A.Pager like @Search
	-- Date de naissance
	ELSE IF @SearchType = 'BDa'
		INSERT INTO @tSearchBenef
			SELECT HumanID
			FROM dbo.Mo_Human
			WHERE BirthDate 	BETWEEN CONVERT(DATETIME, LEFT(@Search, 10))
								AND CONVERT(DATETIME, RIGHT(@Search, 10))
	-- Courrier électronique
	ELSE IF @SearchType = 'Mai'
		INSERT INTO @tSearchBenef
			SELECT HumanID
			FROM dbo.Mo_Human H
			JOIN dbo.Mo_Adr A ON H.AdrID = A.AdrID
			WHERE A.EMail like '%' + @Search + '%'
	-- Code postal
	ELSE IF @SearchType = 'Zip'
		INSERT INTO @tSearchBenef
			SELECT H.HumanID
			FROM dbo.Mo_Adr A
			JOIN dbo.Mo_Human H ON A.AdrID = H.AdrID
			WHERE A.ZipCode LIKE @Search
	-- Identifiant unique		-- 2010-01-29 : JFG : AJOUT
	ELSE 
		IF @SearchType = 'IDs'
			BEGIN
				INSERT INTO @tSearchBenef
				(HumanID)
				VALUES
				(CAST(@Search AS INT))
			END

	IF @RepID = 0
	BEGIN
		-- Recherche des bénéficiaires selon les critères passés en paramètre
		SELECT 
			B.BeneficiaryID,
			H.OrigName,
			H.Initial,
			H.LastName,
			H.FirstName,
			SocialNumber = ISNULL(H.SocialNumber, ''),
			Address = ISNULL(A.Address, ''),
			City = ISNULL(A.City, '') ,
			Statename = ISNULL(A.Statename, ''),
			ZipCode = ISNULL(A.ZipCode, ''),
			Phone1 = ISNULL(A.Phone1, ''),
			BirthDate = dbo.FN_CRQ_IsDateNull(H.BirthDate),
			DeathDate = dbo.FN_CRQ_IsDateNull(H.DeathDate),
			CountryName = ISNULL(Co.CountryName, ''),
			B.tiCESPState,
			-- 2009-11-06 : JFG : NOUVEAUX CHAMPS
			H.OrigName, 
			H.SexID, 
			H.[LangID],
			H.CivilID, 
			A.CountryID, 
			A.Email,
			A.Phone1,
			A.Phone2,
			A.OtherTel,
			A.Fax,
			A.Mobile,
			A.Pager,
			B.tiPCGType,
			B.vcPCGLastName, 
			B.vcPCGFirstName, 
			B.vcPCGSINorEN, 
			B.CaseOfJanuary, 
			B.EligibilityQty, 
			B.StudyStart,
			B.ProgramLength, 
			B.ProgramYear,
			B.BirthCertificate, 
			B.RegistrationProof, 
			B.GovernmentGrantForm,
			B.PersonalInfo, 
			B.SchoolReport, 
			p.ProgramDesc,
			CollegeName		= cie.CompanyName,
			sNEQ			= H.StateCompanyNo,
			H.ResidID,
			TutorLastName	= h2.LastName,
			TutorFirstName	= h2.FirstName
		FROM 
			@tSearchBenef t
			INNER JOIN dbo.Un_Beneficiary B 
				ON t.HumanID = B.BeneficiaryID
			INNER JOIN dbo.Mo_Human H 
				ON B.BeneficiaryID = H.HumanID
			LEFT OUTER JOIN dbo.Mo_Adr A 
				ON H.AdrID = A.AdrID
			LEFT OUTER JOIN dbo.Mo_Country Co 
				ON Co.CountryID = A.CountryID
			LEFT OUTER JOIN dbo.Un_Program p
				ON p.ProgramId = B.ProgramID
			LEFT OUTER JOIN	dbo.Un_College c
				ON c.CollegeID = B.CollegeID
			LEFT OUTER JOIN dbo.Mo_Company cie
				ON c.CollegeID = cie.CompanyID
			LEFT OUTER JOIN dbo.Mo_Human h2
				ON B.iTutorID = h2.HumanID
		GROUP BY -- On utilise un GROUP BY car le DISTINCT ne peut être utilisé dans ce cas-ci (les colonnes ne sont pas tous présentes dans le ORDER BY)
			B.BeneficiaryID, 
			H.OrigName,
			H.Initial,
			H.LastName, 
			H.FirstName, 
			H.SocialNumber, 
			A.Address, 
			A.City,
			A.Statename, 
			A.ZipCode,
			A.Phone1,
			H.BirthDate,
			H.DeathDate,
			Co.CountryName,
			B.tiCESPState,
			H.OrigName, 
			H.SexID, 
			H.[LangID],
			H.CivilID, 
			A.CountryID, 
			A.Email,
			A.Phone1,
			A.Phone2,
			A.OtherTel,
			A.Fax,
			A.Mobile,
			A.Pager,
			B.tiPCGType,
			B.TutorName,
			B.vcPCGLastName, 
			B.vcPCGFirstName, 
			B.vcPCGSINorEN, 
			B.CaseOfJanuary, 
			B.EligibilityQty, 
			B.StudyStart,
			B.ProgramLength, 
			B.ProgramYear,
			B.BirthCertificate, 
			B.RegistrationProof, 
			B.GovernmentGrantForm,
			B.PersonalInfo, 
			B.SchoolReport, 
			p.ProgramDesc,
			cie.CompanyName,
			H.StateCompanyNo,
			H.ResidID,
			h2.LastName,
			h2.FirstName
		ORDER BY 
			CASE @SearchType
				WHEN 'LNa' THEN H.LastName 
				WHEN 'Pho' THEN A.Phone1 
				WHEN 'SNu' THEN H.SocialNumber 
				WHEN 'FNa' THEN H.FirstName 
				WHEN 'BDa' THEN CONVERT(VARCHAR(10), H.BirthDate, 126)
				WHEN 'Zip' THEN A.ZipCode
			END,
			CASE @SearchType
				WHEN 'LNa' THEN H.FirstName
				ELSE H.LastName 
			END,
			CASE 
				WHEN @SearchType IN ('LNa', 'FNa') THEN H.SocialNumber
				ELSE H.FirstName
			END,
			H.SocialNumber
	END
	ELSE
	BEGIN
	-- Création d'une table temporaire
		CREATE TABLE #tRep (
			RepID INTEGER PRIMARY KEY)

		-- Insère tous les représentants sous un rep dans la table temporaire
		INSERT #tRep
			EXECUTE SL_UN_BossOfRep @RepID

		-- Recherche des bénéficiaires selon les critères passés en paramètre
		SELECT 
			B.BeneficiaryID,
			H.OrigName,
			H.Initial,
			H.LastName,
			H.FirstName,
			SocialNumber = ISNULL(H.SocialNumber, ''),
			Address = ISNULL(A.Address, ''),
			City = ISNULL(A.City, '') ,
			Statename = ISNULL(A.Statename, ''),
			ZipCode = ISNULL(A.ZipCode, ''),
			Phone1 = ISNULL(A.Phone1, ''),
			BirthDate = dbo.FN_CRQ_IsDateNull(H.BirthDate),
			DeathDate = dbo.FN_CRQ_IsDateNull(H.DeathDate),
			CountryName = ISNULL(Co.CountryName, ''),
			B.tiCESPState,
			-- 2009-11-06 : JFG : NOUVEAUX CHAMPS
			H.OrigName, 
			H.SexID, 
			H.[LangID],
			H.CivilID, 
			A.CountryID, 
			A.Email,
			A.Phone1,
			A.Phone2,
			A.OtherTel,
			A.Fax,
			A.Mobile,
			A.Pager,
			B.tiPCGType,
			B.TutorName,
			B.vcPCGLastName, 
			B.vcPCGFirstName, 
			B.vcPCGSINorEN, 
			B.CaseOfJanuary, 
			B.EligibilityQty, 
			B.StudyStart,
			B.ProgramLength, 
			B.ProgramYear,
			B.BirthCertificate, 
			B.RegistrationProof, 
			B.GovernmentGrantForm,
			B.PersonalInfo, 
			B.SchoolReport, 
			p.ProgramDesc,
			CollegeName = cie.CompanyName,
			sNEQ		= H.StateCompanyNo,
			H.ResidID,
			TutorLastName	= h2.LastName,
			TutorFirstName	= h2.FirstName
		FROM 
			@tSearchBenef t
			INNER JOIN dbo.Un_Beneficiary B 
				ON t.HumanID = B.BeneficiaryID
			INNER JOIN dbo.Mo_Human H 
				ON B.BeneficiaryID = H.HumanID
			INNER JOIN dbo.Un_Convention C 
				ON C.BeneficiaryID = B.BeneficiaryID
			INNER JOIN dbo.Un_Subscriber S 
				ON C.SubscriberID = S.SubscriberID
			LEFT OUTER JOIN dbo.Mo_Adr A 
				ON H.AdrID = A.AdrID
			LEFT OUTER JOIN Mo_Country Co 
				ON Co.CountryID = A.CountryID
			INNER JOIN #tRep R 
				ON S.RepID = R.RepID OR R.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
			LEFT OUTER JOIN dbo.Un_Program p
				ON p.ProgramId = B.ProgramID
			LEFT OUTER JOIN	dbo.Un_College col
				ON col.CollegeID = B.CollegeID
			LEFT OUTER JOIN dbo.Mo_Company cie
				ON col.CollegeID = cie.CompanyID
			LEFT OUTER JOIN dbo.Mo_Human h2
				ON B.iTutorID = h2.HumanID
		GROUP BY -- On utilise un GROUP BY car le DISTINCT ne peut être utilisé dans ce cas-ci (les colonnes ne sont pas tous présentes dans le ORDER BY)
			B.BeneficiaryID, 
			H.OrigName,
			H.Initial,
			H.LastName, 
			H.FirstName, 
			H.SocialNumber, 
			A.Address, 
			A.City,
			A.Statename, 
			A.ZipCode,
			A.Phone1,
			H.BirthDate,
			H.DeathDate,
			Co.CountryName,
			B.tiCESPState,
			H.OrigName, 
			H.SexID, 
			H.[LangID],
			H.CivilID, 
			A.CountryID, 
			A.Email,
			A.Phone1,
			A.Phone2,
			A.OtherTel,
			A.Fax,
			A.Mobile,
			A.Pager,
			B.tiPCGType,
			B.TutorName,
			B.vcPCGLastName, 
			B.vcPCGFirstName, 
			B.vcPCGSINorEN, 
			B.CaseOfJanuary, 
			B.EligibilityQty, 
			B.StudyStart,
			B.ProgramLength, 
			B.ProgramYear,
			B.BirthCertificate, 
			B.RegistrationProof, 
			B.GovernmentGrantForm,
			B.PersonalInfo, 
			B.SchoolReport, 
			p.ProgramDesc,
			cie.CompanyName,
			H.StateCompanyNo,
			H.ResidID,
			h2.LastName,
			h2.FirstName
		ORDER BY 
			CASE @SearchType
				WHEN 'LNa' THEN H.LastName 
				WHEN 'Pho' THEN A.Phone1 
				WHEN 'SNu' THEN H.SocialNumber 
				WHEN 'FNa' THEN H.FirstName 
				WHEN 'BDa' THEN CONVERT(VARCHAR(10), H.BirthDate, 126)
			END,
			CASE @SearchType
				WHEN 'LNa' THEN H.FirstName
				ELSE H.LastName 
			END,
			CASE 
				WHEN @SearchType IN ('LNa', 'FNa') THEN H.SocialNumber
				ELSE H.FirstName
			END,
			H.SocialNumber

		-- Suppression table temporaire
		DROP TABLE #tRep 
	END

	SET @dtEnd = GETDATE()
	SELECT @siTraceSearch = siTraceSearch FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceSearch
		-- Insère une trace de l'ewxécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceSearch.
		INSERT INTO Un_Trace (
				ConnectID, -- ID de connexion de l’usager
				iType, -- Type de trace (1 = recherche, 2 = rapport)
				fDuration, -- Temps d’exécution de la procédure
				dtStart, -- Date et heure du début de l’exécution.
				dtEnd, -- Date et heure de la fin de l’exécution.
				vcDescription, -- Description de l’exécution (en texte)
				vcStoredProcedure, -- Nom de la procédure stockée
				vcExecutionString ) -- Ligne d’exécution (inclus les paramètres)
			SELECT
				@ConnectID,
				1,
				DATEDIFF(SECOND, @dtBegin, @dtEnd),
				@dtBegin,
				@dtEnd,
				'Recherche de bénéficiaire par '+
					CASE @SearchType
						WHEN 'LNa' THEN 'nom, prénom : ' 
						WHEN 'Pho' THEN 'téléphone : ' 
						WHEN 'SNu' THEN 'NAS : '
						WHEN 'FNa' THEN 'prénom, nom : ' 
						WHEN 'BDa' THEN 'date de naissance : '
						WHEN 'Mai' THEN 'courriel : '
					END + @Search,
				'SL_UN_SearchBeneficiary',
				'EXECUTE SL_UN_SearchBeneficiary @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @SearchType = '+@SearchType+
					', @Search = '+@Search+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END




