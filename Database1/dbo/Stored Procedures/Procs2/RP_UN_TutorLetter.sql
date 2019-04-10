/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                : 	RP_UN_TutorLetter
Description        : 	Rapport de fusion word des lettres de l'émission pour tuteur
Valeurs de retours : 	>0  : Tout à fonctionné
									Dataset :
											DocTemplateID				INTEGER			ID du template du document
											LangID						CHAR(3)			Langue du tuteur
											Date							VARCHAR(35)		Date du jour.
											TitreTuteur					VARCHAR(75)		Ce sera monsieur, madame, Mr ou Ms selon le sexe et la langue du tuteur.
											NomTuteur					VARCHAR(50)		Nom de famille du tuteur.
											PrenomTuteur				VARCHAR(35)		Prénom du tuteur.
											AdresseTuteur				VARCHAR(75)		Adresse du tuteur, incluant le numéro civique, le nom de la rue et le numéro d’appartement s’il y a lieu.
											VilleTuteur					VARCHAR(100)	Ville du tuteur.
											ProvinceTuteur 			VARCHAR(75)		Province du tuteur.
											CodePostalTuteur			VARCHAR(10)		Code postal du tuteur.
											TitreSouscripteur			VARCHAR(75)		Ce sera monsieur, madame, Mr ou Ms selon le sexe du souscripteur et la langue du tuteur.
											NomSouscripteur			VARCHAR(50)		Nom de famille du souscripteur.
											PrenomSouscripteur		VARCHAR(35)		Prénom du souscripteur.
											AdresseSouscripteur		VARCHAR(75)		Adresse du souscripteur, incluant le numéro civique, le nom de la rue et le numéro d’appartement s’il y a lieu.
											VilleSouscripteur			VARCHAR(100)	Ville du souscripteur.
											ProvinceSouscripteur		VARCHAR(75)		Province du souscripteur.
											CodePostalSouscripteur	VARCHAR(10)		Code postal du souscripteur.
											NomBeneficiaire			VARCHAR(50)		Nom du bénéficiaire.
											PrenomBeneficiaire		VARCHAR(35)		Prénom du bénéficiaire.
											DateConvention				VARCHAR(35)		Date d’entrée en vigueur de la convention.
											NoConvention				VARCHAR(75)		Numéro de la convention.
											Regime						VARCHAR(75)		Régime de la convention (Universitas, REEEFLEX, Sélect 2000 Plan B, etc.)
											DescriptifRepresentant	VARCHAR(75)	 	« La représentante » ou « Le représentant » selon le sexe du représentant.  Toujours en français.
											TitreRepresentant			VARCHAR(75)		Ce sera monsieur, madame, Mr ou Ms selon le sexe du représentant du souscripteur et la langue du tuteur.
											TitreCoursRepresentant	VARCHAR(75)		Ce sera M, Mme, Mr ou Ms selon le sexe du représentant du souscripteur et la langue du tuteur.
											NomRepresentant			VARCHAR(50)		Nom de famille du représentant du souscripteur.
											PrenomRepresentant		VARCHAR(35)		Prénom du représentant de souscripteur.
											PronomRepresentant		VARCHAR(5)		elle, lui, her ou his selon le sexe du représentant du souscripteur et la langue du tuteur.
											TelephoneRepresentant	VARCHAR(27)		Téléphone du représentant de souscripteur.
                      	<=0 : Erreur SQL
									-1 :  Pas de template d'entré ou en vigueur pour ce type de document
									-2 :  Pas de document(s) de généré(s)
Note                :	ADX0000691	IA	2005-05-06	Bruno Lapointe		Création
								ADX0001761	BR	2005-11-17	Bruno Lapointe		Correction titre souscripteur, tuteur et représentant
								ADX0001910	BR	2006-05-05	Bruno Lapointe		Géré le sexe et la langue null sur le représentant du souscripteur.
												2008-07-17	Pierre-Luc Simard	Modification pour ne plus retourner de dataset inutilement 
																				si le document n'est pas généré immédiatement	
												2008-09-25	Josée Parent		Ne pas produire de DataSet pour les documents 
																				commandés
												2015-03-26	Donald Huppé		Inscrire le téléphone d'affaire du rep au lieu du téléphone à la maison
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_TutorLetter] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@ConventionID INTEGER, -- ID de la convention  
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN

	DECLARE 
		@Today DATETIME,
		@DocTypeID INTEGER,
		@UserName VARCHAR(77)

	SET @Today = GetDate()	

	-- Table temporaire qui contient le certificat
	CREATE TABLE #TutorLetter(
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		Date VARCHAR(30), -- Date du jour.
		TitreTuteur	VARCHAR(75), -- Ce sera monsieur, madame, Mr ou Ms selon le sexe et la langue du tuteur.
		NomTuteur VARCHAR(50), -- Nom de famille du tuteur.
		PrenomTuteur VARCHAR(35), -- Prénom du tuteur.
		AdresseTuteur VARCHAR(75), -- Adresse du tuteur, incluant le numéro civique, le nom de la rue et le numéro d’appartement s’il y a lieu.
		VilleTuteur VARCHAR(100), -- Ville du tuteur.
		ProvinceTuteur VARCHAR(75), -- Province du tuteur.
		CodePostalTuteur VARCHAR(10), -- Code postal du tuteur.
		TitreSouscripteur VARCHAR(75), -- Ce sera monsieur, madame, Mr ou Ms selon le sexe du souscripteur et la langue du tuteur.
		NomSouscripteur VARCHAR(50), -- Nom de famille du souscripteur.
		PrenomSouscripteur VARCHAR(35), -- Prénom du souscripteur.
		AdresseSouscripteur VARCHAR(75), -- Adresse du souscripteur, incluant le numéro civique, le nom de la rue et le numéro d’appartement s’il y a lieu.
		VilleSouscripteur VARCHAR(100), -- Ville du souscripteur.
		ProvinceSouscripteur VARCHAR(75), -- Province du souscripteur.
		CodePostalSouscripteur VARCHAR(10), -- Code postal du souscripteur.
		NomBeneficiaire VARCHAR(50), -- Nom du bénéficiaire.
		PrenomBeneficiaire VARCHAR(35), -- Prénom du bénéficiaire.
		DateConvention VARCHAR(30), -- Date d’entrée en vigueur de la convention.
		NoConvention VARCHAR(75), -- Numéro de la convention.
		Regime VARCHAR(75), -- Régime de la convention (Universitas, REEEFLEX, Sélect 2000 Plan B, etc.)
		DescriptifRepresentant VARCHAR(75), -- « La représentante » ou « Le représentant » selon le sexe du représentant.  Toujours en français.
		TitreRepresentant VARCHAR(75), -- Ce sera monsieur, madame, Mr ou Ms selon le sexe du représentant du souscripteur et la langue du tuteur.
		TitreCoursRepresentant VARCHAR(75), -- Ce sera M, Mme, Mr ou Ms selon le sexe du représentant du souscripteur et la langue du tuteur.
		NomRepresentant VARCHAR(50), -- Nom de famille du représentant du souscripteur.
		PrenomRepresentant VARCHAR(35), -- Prénom du représentant de souscripteur.
		PronomRepresentant VARCHAR(5), -- elle, lui, her ou his selon le sexe du représentant du souscripteur et la langue du tuteur.
		TelephoneRepresentant VARCHAR(40) -- Téléphone du représentant de souscripteur.
	)

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'TutorLetter'

	-- Remplis la table temporaire
	INSERT INTO #TutorLetter
		SELECT
			T.DocTemplateID,
			HT.LangID,
			Date = dbo.fn_Mo_DateToLongDateStr(GETDATE(), HT.LangID), -- Date du jour.
			TitreTuteur	= 
				CASE
					WHEN SxT.LangID = 'ENU' THEN SxT.ShortSexName
				ELSE SxT.LongSexName
				END, -- Ce sera monsieur, madame, Mr ou Ms selon le sexe et la langue du tuteur.
			NomTuteur = HT.LastName, -- Nom de famille du tuteur.
			PrenomTuteur = HT.FirstName, -- Prénom du tuteur.
			AdresseTuteur = AdT.Address, -- Adresse du tuteur, incluant le numéro civique, le nom de la rue et le numéro d’appartement s’il y a lieu.
			VilleTuteur = AdT.City, -- Ville du tuteur.
			ProvinceTuteur = AdT.StateName, -- Province du tuteur.
			CodePostalTuteur = dbo.fn_Mo_FormatZIP(AdT.ZipCode, AdT.CountryID), -- Code postal du tuteur.
			TitreSouscripteur = 
				CASE
					WHEN SxS.LangID = 'ENU' THEN SxS.ShortSexName
				ELSE SxS.LongSexName
				END, -- Ce sera monsieur, madame, Mr ou Ms selon le sexe du souscripteur et la langue du tuteur.
			NomSouscripteur = HS.LastName, -- Nom de famille du souscripteur.
			PrenomSouscripteur = HS.FirstName, -- Prénom du souscripteur.
			AdresseSouscripteur = AdS.Address, -- Adresse du souscripteur, incluant le numéro civique, le nom de la rue et le numéro d’appartement s’il y a lieu.
			VilleSouscripteur = AdS.City, -- Ville du souscripteur.
			ProvinceSouscripteur = AdS.StateName, -- Province du souscripteur.
			CodePostalSouscripteur = dbo.fn_Mo_FormatZIP(AdS.ZipCode, AdS.CountryID), -- Code postal du souscripteur.
			NomBeneficiaire = HB.LastName, -- Nom du bénéficiaire.
			PrenomBeneficiaire = HB.FirstName, -- Prénom du bénéficiaire.
			DateConvention = dbo.fn_Mo_DateToLongDateStr(V.InForceDate, HT.LangID), -- Date d’entrée en vigueur de la convention.
			NoConvention = C.ConventionNo, -- Numéro de la convention.
			Regime = P.PlanDesc, -- Régime de la convention (Universitas, REEEFLEX, Sélect 2000 Plan B, etc.)
			DescriptifRepresentant =
					CASE
						WHEN HR.SexID = 'F' THEN 'La représentante'
					ELSE 'Le représentant'
					END, -- « La représentante » ou « Le représentant » selon le sexe du représentant.  Toujours en français.
			TitreRepresentant = 
				CASE
					WHEN SxR.LangID = 'ENU' THEN SxR.ShortSexName
				ELSE SxR.LongSexName
				END, -- Ce sera monsieur, madame, Mr ou Ms selon le sexe du représentant du souscripteur et la langue du tuteur.
			TitreCoursRepresentant = SxR.ShortSexName, -- Ce sera M, Mme, Mr ou Ms selon le sexe du représentant du souscripteur et la langue du tuteur.
			NomRepresentant = HR.LastName, -- Nom de famille du représentant du souscripteur.
			PrenomRepresentant = HR.FirstName, -- Prénom du représentant de souscripteur.
			PronomRepresentant =
				CASE
					WHEN SxT.LangID = 'ENU' AND HR.SexID = 'F' THEN 'her'
					WHEN SxT.LangID = 'ENU' THEN 'his'
					WHEN SxT.LangID = 'FRA' AND HR.SexID = 'F' THEN 'elle'
					WHEN SxT.LangID = 'FRA' THEN 'lui'
				END, -- elle, lui, her ou his selon le sexe du représentant du souscripteur et la langue du tuteur
			TelephoneRepresentant = dbo.FN_CRQ_FormatPhoneNo(AdR.Phone2, AdR.CountryID) -- Téléphone du représentant de souscripteur.
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		JOIN dbo.Mo_Human HT ON HT.HumanID = B.iTutorID
		JOIN Mo_Sex SxT ON HT.LangID = SxT.LangID AND HT.SexID = SxT.SexID
		JOIN dbo.Mo_Adr AdT ON AdT.AdrID = HT.AdrID
		JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
		JOIN Mo_Sex SxS ON HT.LangID = SxS.LangID AND HS.SexID = SxS.SexID
		JOIN dbo.Mo_Adr AdS ON AdS.AdrID = HS.AdrID
		JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
		JOIN dbo.Mo_Human HR ON HR.HumanID = S.RepID
		LEFT JOIN Mo_Sex SxR ON HT.LangID = SxR.LangID AND HR.SexID = SxR.SexID
		LEFT JOIN dbo.Mo_Adr AdR ON AdR.AdrID = HR.AdrID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN (
			SELECT
				ConventionID,
				InForceDate = MIN(InForceDate)
			FROM dbo.Un_Unit 
			GROUP BY ConventionID
			) V ON V.ConventionID = C.ConventionID
		JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
			SELECT 
				LangID,
				DocTypeID,
				DocTemplateTime = MAX(DocTemplateTime)
			FROM CRQ_DocTemplate
			WHERE DocTypeID = @DocTypeID
				AND (DocTemplateTime < @Today)
			GROUP BY
				LangID,
				DocTypeID
			) DT ON DT.LangID = HS.LangID
		JOIN CRQ_DocTemplate T ON DT.DocTypeID = T.DocTypeID AND DT.DocTemplateTime = T.DocTemplateTime AND T.LangID = HT.LangID
		WHERE C.ConventionID = @ConventionID

	-- Gestion des documents
	IF @DocAction IN (0,2)
	BEGIN

		-- Crée le document dans la gestion des documents
		INSERT INTO CRQ_Doc (
				DocTemplateID,
				DocOrderConnectID,
				DocOrderTime,
				DocGroup1,
				DocGroup2,
				DocGroup3,
				Doc)
			SELECT 
				DocTemplateID,
				@ConnectID,
				@Today,
				ISNULL(NoConvention,''),
				ISNULL(NomTuteur,'')+', '+ISNULL(PrenomTuteur,''),
				ISNULL(NomSouscripteur,'')+', '+ISNULL(PrenomSouscripteur,''),
				ISNULL(LangID,'')+';'+
				ISNULL(Date,'')+';'+
				ISNULL(TitreTuteur,'')+';'+
				ISNULL(NomTuteur,'')+';'+
				ISNULL(PrenomTuteur,'')+';'+
				ISNULL(AdresseTuteur,'')+';'+
				ISNULL(VilleTuteur,'')+';'+
				ISNULL(ProvinceTuteur,'')+';'+
				ISNULL(CodePostalTuteur,'')+';'+
				ISNULL(TitreSouscripteur,'')+';'+
				ISNULL(NomSouscripteur,'')+';'+
				ISNULL(PrenomSouscripteur,'')+';'+
				ISNULL(AdresseSouscripteur,'')+';'+
				ISNULL(VilleSouscripteur,'')+';'+
				ISNULL(ProvinceSouscripteur,'')+';'+
				ISNULL(CodePostalSouscripteur,'')+';'+
				ISNULL(NomBeneficiaire,'')+';'+
				ISNULL(PrenomBeneficiaire,'')+';'+
				ISNULL(DateConvention,'')+';'+
				ISNULL(NoConvention,'')+';'+
				ISNULL(Regime,'')+';'+
				ISNULL(DescriptifRepresentant,'')+';'+
				ISNULL(TitreRepresentant,'')+';'+
				ISNULL(TitreCoursRepresentant,'')+';'+
				ISNULL(NomRepresentant,'')+';'+
				ISNULL(PrenomRepresentant,'')+';'+
				ISNULL(PronomRepresentant,'')+';'+
				ISNULL(TelephoneRepresentant,'')+';'
			FROM #TutorLetter

		-- Fait un lient entre le document et la convention pour que retrouve le document 
		-- dans l'historique des documents de la convention
		INSERT INTO CRQ_DocLink 
			SELECT
				C.ConventionID,
				1,
				D.DocID
			FROM CRQ_Doc D 
			JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
			JOIN dbo.Un_Convention C ON C.ConventionNo = D.DocGroup1
			LEFT JOIN CRQ_DocLink L ON L.DocLinkID = C.ConventionID AND L.DocLinkType = 1 AND L.DocID = D.DocID
			WHERE L.DocID IS NULL
			  AND T.DocTypeID = @DocTypeID
			  AND D.DocOrderTime = @Today
			  AND D.DocOrderConnectID = @ConnectID	

		IF @DocAction = 2
			-- Dans le cas que l'usager a choisi imprimer et garder la trace dans la gestion 
			-- des documents, on indique qu'il a déjà été imprimé pour ne pas le voir dans 
			-- la queue d'impression
			INSERT INTO CRQ_DocPrinted(DocID, DocPrintConnectID, DocPrintTime)
				SELECT
					D.DocID,
					@ConnectID,
					@Today
				FROM CRQ_Doc D 
				JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
				LEFT JOIN CRQ_DocPrinted P ON P.DocID = D.DocID AND P.DocPrintConnectID = @ConnectID AND P.DocPrintTime = @Today
				WHERE P.DocID IS NULL
				  AND T.DocTypeID = @DocTypeID
				  AND D.DocOrderTime = @Today
				  AND D.DocOrderConnectID = @ConnectID					
	END

	IF @DocAction <> 3 AND @DocAction <> 0
	BEGIN
		-- Produit un dataset pour la fusion
			SELECT 
				DocTemplateID,
				LangID,
				Date, -- Date du jour.
				TitreTuteur, -- Ce sera monsieur, madame, Mr ou Ms selon le sexe et la langue du tuteur.
				NomTuteur, -- Nom de famille du tuteur.
				PrenomTuteur, -- Prénom du tuteur.
				AdresseTuteur, -- Adresse du tuteur, incluant le numéro civique, le nom de la rue et le numéro d’appartement s’il y a lieu.
				VilleTuteur, -- Ville du tuteur.
				ProvinceTuteur, -- Province du tuteur.
				CodePostalTuteur, -- Code postal du tuteur.
				TitreSouscripteur, -- Ce sera monsieur, madame, Mr ou Ms selon le sexe du souscripteur et la langue du tuteur.
				NomSouscripteur, -- Nom de famille du souscripteur.
				PrenomSouscripteur, -- Prénom du souscripteur.
				AdresseSouscripteur, -- Adresse du souscripteur, incluant le numéro civique, le nom de la rue et le numéro d’appartement s’il y a lieu.
				VilleSouscripteur, -- Ville du souscripteur.
				ProvinceSouscripteur, -- Province du souscripteur.
				CodePostalSouscripteur, -- Code postal du souscripteur.
				NomBeneficiaire, -- Nom du bénéficiaire.
				PrenomBeneficiaire, -- Prénom du bénéficiaire.
				DateConvention, -- Date d’entrée en vigueur de la convention.
				NoConvention, -- Numéro de la convention.
				Regime, -- Régime de la convention (Universitas, REEEFLEX, Sélect 2000 Plan B, etc.)
				DescriptifRepresentant, -- « La représentante » ou « Le représentant » selon le sexe du représentant.  Toujours en français.
				TitreRepresentant, -- Ce sera monsieur, madame, Mr ou Ms selon le sexe du représentant du souscripteur et la langue du tuteur.
				TitreCoursRepresentant, -- Ce sera M, Mme, Mr ou Ms selon le sexe du représentant du souscripteur et la langue du tuteur.
				NomRepresentant, -- Nom de famille du représentant du souscripteur.
				PrenomRepresentant, -- Prénom du représentant de souscripteur.
				PronomRepresentant, -- elle, lui, her ou his selon le sexe du représentant du souscripteur et la langue du tuteur.
				TelephoneRepresentant -- Téléphone du représentant de souscripteur.
			FROM #TutorLetter 
			WHERE @DocAction IN (1,2)
	END
    
	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM CRQ_DocTemplate
			WHERE DocTypeID = @DocTypeID
				AND DocTemplateTime < @Today )
		RETURN -1 -- Pas de template d'entré ou en vigueur pour ce type de document
	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM #TutorLetter)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	-- RETURN VALUE
	---------------
	-- >0  : Tout ok
	-- <=0 : Erreurs
	-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
	-- 	-2 : Pas de document(s) de généré(s)

	DROP TABLE #TutorLetter
END


