/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                : 	RP_UN_TerminatedNotice
Description        : 	Document : Avis de résiliation
Valeurs de retours : 	Dataset :
									Date 					VARCHAR(25)		Ce sera la date à laquelle la lettre aura été commandée 
																				dans le format suivant : « 12 décembre 2005 » ou  
																				« December 12, 2005 » selon la langue du souscripteur.
									Appel1				VARCHAR(75)		« Monsieur », « Madame », « Madam » ou « Sir » selon le
																				sexe et la langue du souscripteur.
									Appel2				VARCHAR(75)		« Mr », « Mrs » selon le sexe et la langue anglaise du 
																				souscripteur.  
									Souscripteur		VARCHAR(87)		Prénom et nom du souscripteur qui a causé l’effet 
																				retourné. (Ex : Éric Ranger)
									Adresse				VARCHAR(75)		Numéro civique, rue et numéro d’appartement du 
																				souscripteur.
									Ville					VARCHAR(100)	Ville du souscripteur.
									Province				VARCHAR(75)		Province du souscripteur.
									Code_Postal			VARCHAR(10)		Code postal du souscripteur.
									Nos_conventions	VARCHAR(1000)	Numéros des conventions qui sont le sujet de l’avis (ceux 
																				sélection dans la fenêtre ci-dessous). Chaque # de 
																				convention seront séparés par une virgule.
									Montant_Frais		VARCHAR(75)		Montant total des frais des conventions.
									Montant_Epargne	VARCHAR(75)		Montant total des épargnes des conventions.
									Nom_representant	VARCHAR(87)		Prénom et nom du représentant du souscripteur. (Ex : 
																				Francine Adam)
									agreement_s			VARCHAR(15)	 	« agreements » s’il y a plus d’une convention et 
																				« agreement » s’il n’y en n’a qu’une. Le « a » sera en 
																				minuscule.
									convention_s		VARCHAR(15)	 	« conventions » s’il y a plus d’une convention et 
																				« convention » s’il n’y en n’a qu’une. Le premier caractère 
																				sera en minuscule.
									la_les				VARCHAR(5)	 	« les » s’il y a plus d’une convention et « la » s’il n’y 
																				en n’a qu’une. Le premier caractère sera en minuscule.
									votre_vos			VARCHAR(10)	 	« vos » s’il y a plus d’une convention et « votre » s’il 
																				n’y en n’a qu’une. Le premier caractère sera en minuscule.
									Tel_Souscripteur	VARCHAR(30)		Numéro de téléphone à la maison du souscripteur dans le 
																				format suivant : 4186518975.
									IDSouscripteur		INTEGER			Identifiant unique du souscripteur
									Appel3				VARCHAR(75)		« Mr », « Mrs » selon le sexe et la langue anglaise du 
																				souscripteur plus le nom.  
									
								@ReturnValue :
	                      	>0  : Tout à fonctionné
									<=0 : Erreur SQL
										-1 :  Pas de template d'entré ou en vigueur pour ce type de document
										-2 :  Pas de document(s) de généré(s)
Note                :	ADX0000799	IA	2006-01-31	Bruno Lapointe		Création
										2008-09-25	Josée Parent		Ne pas produire de DataSet pour les documents 
																		commandés
										2009-04-15	Pierre-Luc Simard	Ne pas tenir compte des paiements anticipés
						GLPI6399		2011-11-21  Eric Michaud		Ajout de l'id souscripteur et de Appel3
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_TerminatedNotice] (
	@ConnectID INTEGER, -- ID de connexion de l’usager
	@vcConventionIDs VARCHAR(1000), -- IDs des conventions séparés par des virgules.
	@DocAction INTEGER ) -- ID de l'action (0 = commander le document, 1 = produire, 2 = produire et créer un historique 
								-- dans la gestion des documents.
AS
BEGIN
	DECLARE 
		@dtToday DATETIME,
		@iDocTypeID INTEGER,
		@vcUserName VARCHAR(77),
		@vcConventionNo VARCHAR(75),
		@vcConventionNos VARCHAR(2000),
		@bJustOneConv BIT

	SET @dtToday = GETDATE()

	-- Crée une table temporaire contenant lesid de convention qui sont le sujet de l'avis.
	CREATE TABLE #tConventions (
		ConventionID INTEGER PRIMARY KEY )

	INSERT INTO #tConventions
		SELECT Val
		FROM dbo.FN_CRQ_IntegerTable(@vcConventionIDs)

	-- Détermine s'il n'y qu'une convention ou plusieurs
	IF (SELECT COUNT(ConventionID) FROM #tConventions) = 1
		SET @bJustOneConv = 1
	ELSE
		SET @bJustOneConv = 0

	-- Fait une liste des numéros des conventions séparés par une virgule et une espace.
	SET @vcConventionNos = ''

	DECLARE crConventionNo CURSOR FOR
		SELECT C.ConventionNo
		FROM #tConventions tC
		JOIN dbo.Un_Convention C ON C.ConventionID = tC.ConventionID
		ORDER BY C.ConventionNo

	OPEN crConventionNo

	FETCH NEXT FROM crConventionNo
	INTO @vcConventionNo

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @vcConventionNos = ''
			SET @vcConventionNos = @vcConventionNo
		ELSE
			SET @vcConventionNos = @vcConventionNos + ', ' + @vcConventionNo

		FETCH NEXT FROM crConventionNo
		INTO @vcConventionNo
	END

	CLOSE crConventionNo
	DEALLOCATE crConventionNo

	-- Table temporaire qui contient le certificat
	CREATE TABLE #tTerminatedNotice(
		DocTemplateID INTEGER, -- ID du template de document
		LangID VARCHAR(3), -- Code de 3 lettres représentant la langue du document, soit la langue du souscripteur
		Date VARCHAR(25), -- Ce sera la date à laquelle la lettre aura été commandée dans le format suivant : « 12 décembre 2005 » ou « December 12, 2005 » selon la langue du souscripteur.
		Appel1 VARCHAR(75), -- « Monsieur », « Madame », « Madam » ou « Sir » selon le sexe et la langue du souscripteur.
		Appel2 VARCHAR(75), -- « Mr », « Mrs » selon le sexe et la langue anglaise du souscripteur.  
		Souscripteur VARCHAR(87), -- Prénom et nom du souscripteur qui a causé l’effet retourné. (Ex : Éric Ranger)
		Adresse VARCHAR(75), -- Numéro civique, rue et numéro d’appartement du souscripteur.
		Ville VARCHAR(100), -- Ville du souscripteur.
		Province VARCHAR(75), -- Province du souscripteur.
		Code_Postal VARCHAR(10), -- Code postal du souscripteur.
		Nos_conventions VARCHAR(1000), -- Numéros des conventions qui sont le sujet de l’avis (ceux sélection dans la fenêtre ci-dessous). Chaque # de convention seront séparés par une virgule.
		Montant_Frais VARCHAR(75), -- Montant total des frais des conventions.
		Montant_Epargne VARCHAR(75), -- Montant total des épargnes des conventions.
		Nom_representant VARCHAR(87), -- Prénom et nom du représentant du souscripteur. (Ex : Francine Adam)
		agreement_s VARCHAR(15), -- « agreements » s’il y a plus d’une convention et « agreement » s’il n’y en n’a qu’une. Le « a » sera en minuscule.
		convention_s VARCHAR(15), -- « conventions » s’il y a plus d’une convention et « convention » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
		la_les VARCHAR(5), -- « les » s’il y a plus d’une convention et « la » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
		votre_vos VARCHAR(10), -- « vos » s’il y a plus d’une convention et « votre » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
		Tel_Souscripteur VARCHAR(30), -- Numéro de téléphone à la maison du souscripteur dans le format suivant : 4186518975.
		NomDestinataire VARCHAR(50),
		PrenomDestinataire VARCHAR(35),
		SubscriberID integer,
		Appel3 VARCHAR(75) -- « Mr », « Mrs » selon le sexe et la langue anglaise du souscripteur et le nom.  		
	)

	-- Va chercher le bon type de document
	SELECT 
		@iDocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'TerminatedNotice'

	-- Remplis la table temporaire
	INSERT INTO #tTerminatedNotice
		SELECT
			T.DocTemplateID,
			HS.LangID,
			Date = dbo.fn_Mo_DateToLongDateStr(GETDATE(), HS.LangID), -- Date du jour.
			Appel1 = SxS.LongSexName, -- « Monsieur », « Madame », « Madam » ou « Sir » selon le sexe et la langue du souscripteur.
			Appel2 = A2.ShortSexName, -- « Mr », « Mrs » selon le sexe et la langue anglaise du souscripteur.  
			Souscripteur = HS.FirstName + ' ' + HS.LastName, -- Prénom et nom du souscripteur qui a causé l’effet retourné. (Ex : Éric Ranger)
			Adresse = AdS.Address, -- Numéro civique, rue et numéro d’appartement du souscripteur.
			Ville = AdS.City, -- Ville du souscripteur.
			Province = AdS.Statename, -- Province du souscripteur.
			Code_Postal = dbo.fn_Mo_FormatZIP(AdS.ZipCode, AdS.CountryID), -- Code postal du souscripteur.
			Nos_conventions = @vcConventionNos, -- Numéros des conventions qui sont le sujet de l’avis (ceux sélection dans la fenêtre ci-dessous). Chaque # de convention seront séparés par une virgule.
			Montant_Frais = dbo.fn_Mo_MoneyToStr(SUM(Ct.Fee), HS.LangID, 1), -- Montant total des frais des conventions.
			Montant_Epargne = dbo.fn_Mo_MoneyToStr(SUM(Ct.Cotisation), HS.LangID, 1), -- Montant total des épargnes des conventions.
			Nom_representant = HR.FirstName + ' ' + HR.LastName, -- Prénom et nom du représentant du souscripteur. (Ex : Francine Adam)
			agreement_s =
				CASE 
					WHEN @bJustOneConv = 1 THEN 'agreement'
				ELSE 'agreements'
				END, -- « agreements » s’il y a plus d’une convention et « agreement » s’il n’y en n’a qu’une. Le « a » sera en minuscule.
			convention_s =
				CASE 
					WHEN @bJustOneConv = 1 THEN 'convention'
				ELSE 'conventions'
				END, -- « conventions » s’il y a plus d’une convention et « convention » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
			la_les =
				CASE 
					WHEN @bJustOneConv = 1 THEN 'la'
				ELSE 'les'
				END, -- « les » s’il y a plus d’une convention et « la » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
			votre_vos =
				CASE 
					WHEN @bJustOneConv = 1 THEN 'votre'
				ELSE 'vos'
				END, -- « vos » s’il y a plus d’une convention et « votre » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
			Tel_Souscripteur = AdS.Phone1, -- Numéro de téléphone à la maison du souscripteur dans le format suivant : 4186518975.
			NomDestinataire = HS.LastName,
			PrenomDestinataire = HS.FirstName,
			SubscriberID = S.SubscriberID,
			Appel3 = A2.ShortSexName + ' ' + HS.LastName -- « Mr », « Mrs » selon le sexe et la langue anglaise du souscripteur.  
		FROM #tConventions tC
		JOIN dbo.Un_Convention C ON C.ConventionID = tC.ConventionID
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
		JOIN Mo_Sex SxS ON HS.LangID = SxS.LangID AND HS.SexID = SxS.SexID
		JOIN Mo_Sex A2 ON 'ENU' = A2.LangID AND HS.SexID = A2.SexID
		JOIN dbo.Mo_Adr AdS ON AdS.AdrID = HS.AdrID
		JOIN dbo.Mo_Human HR ON HR.HumanID = S.RepID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID 
		JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
			SELECT 
				LangID,
				DocTypeID,
				DocTemplateTime = MAX(DocTemplateTime)
			FROM CRQ_DocTemplate
			WHERE DocTypeID = @iDocTypeID
				AND (DocTemplateTime < @dtToday)
			GROUP BY
				LangID,
				DocTypeID
			) DT ON DT.LangID = HS.LangID
		JOIN CRQ_DocTemplate T ON DT.DocTypeID = T.DocTypeID AND DT.DocTemplateTime = T.DocTemplateTime AND T.LangID = HS.LangID
		WHERE Ct.EffectDate <= @dtToday
		GROUP BY 
			T.DocTemplateID,
			HS.LangID,
			SxS.LongSexName,
			A2.ShortSexName,
			HS.FirstName,
			HS.LastName,
			AdS.Address,
			AdS.City,
			AdS.Statename,
			AdS.ZipCode,
			AdS.CountryID,
			HR.FirstName,
			HR.LastName,
			AdS.Phone1,
			S.SubscriberID

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
				@dtToday,
				ISNULL(Nos_conventions,''),
				ISNULL(NomDestinataire+', '+PrenomDestinataire,''),
				'',
				ISNULL(LangID,'')+';'+
				ISNULL(Date,'')+';'+
				ISNULL(Appel1,'')+';'+
				ISNULL(Appel2,'')+';'+
				ISNULL(Souscripteur,'')+';'+
				ISNULL(Adresse,'')+';'+
				ISNULL(Ville,'')+';'+
				ISNULL(Province,'')+';'+
				ISNULL(Code_Postal,'')+';'+
				ISNULL(Nos_conventions,'')+';'+
				ISNULL(Montant_Frais,'')+';'+
				ISNULL(Montant_Epargne,'')+';'+
				ISNULL(Nom_representant,'')+';'+
				ISNULL(agreement_s,'')+';'+
				ISNULL(convention_s,'')+';'+
				ISNULL(la_les,'')+';'+
				ISNULL(votre_vos,'')+';'+
				ISNULL(Tel_Souscripteur,'')+';'+
			    cast(SubscriberID as varchar(15))+';'+
				ISNULL(Appel3,'')+';'
			FROM #tTerminatedNotice

		-- Fait un lient entre le document et la convention pour que retrouve le document 
		-- dans l'historique des documents de la convention
		INSERT INTO CRQ_DocLink 
			SELECT
				tC.ConventionID,
				1,
				D.DocID
			FROM CRQ_Doc D 
			JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
			CROSS JOIN #tConventions tC
			LEFT JOIN CRQ_DocLink L ON L.DocLinkID = tC.ConventionID AND L.DocLinkType = 1 AND L.DocID = D.DocID
			WHERE L.DocID IS NULL
			  AND T.DocTypeID = @iDocTypeID
			  AND D.DocOrderTime = @dtToday
			  AND D.DocOrderConnectID = @ConnectID	

		IF @DocAction = 2
			-- Dans le cas que l'usager a choisi imprimer et garder la trace dans la gestion 
			-- des documents, on indique qu'il a déjà été imprimé pour ne pas le voir dans 
			-- la queue d'impression
			INSERT INTO CRQ_DocPrinted(DocID, DocPrintConnectID, DocPrintTime)
				SELECT
					D.DocID,
					@ConnectID,
					@dtToday
				FROM CRQ_Doc D 
				JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
				LEFT JOIN CRQ_DocPrinted P ON P.DocID = D.DocID AND P.DocPrintConnectID = @ConnectID AND P.DocPrintTime = @dtToday
				WHERE P.DocID IS NULL
				  AND T.DocTypeID = @iDocTypeID
				  AND D.DocOrderTime = @dtToday
				  AND D.DocOrderConnectID = @ConnectID					
	END

	IF @DocAction <> 0 -- Ne pas produire de DataSet pour les documents non commandés - Josée Parent
	BEGIN
		-- Produit un dataset pour la fusion
		SELECT 
			DocTemplateID, -- ID du template de document
			LangID, -- Code de 3 lettres représentant la langue du document, soit la langue du souscripteur
			Date, -- Ce sera la date à laquelle la lettre aura été commandée dans le format suivant : « 12 décembre 2005 » ou « December 12, 2005 » selon la langue du souscripteur.
			Appel1, -- « Monsieur », « Madame », « Madam » ou « Sir » selon le sexe et la langue du souscripteur.
			Appel2, -- « Mr », « Mrs » selon le sexe et la langue anglaise du souscripteur.  
			Souscripteur, -- Prénom et nom du souscripteur qui a causé l’effet retourné. (Ex : Éric Ranger)
			Adresse, -- Numéro civique, rue et numéro d’appartement du souscripteur.
			Ville, -- Ville du souscripteur.
			Province, -- Province du souscripteur.
			Code_Postal, -- Code postal du souscripteur.
			Nos_conventions, -- Numéros des conventions qui sont le sujet de l’avis (ceux sélection dans la fenêtre ci-dessous). Chaque # de convention seront séparés par une virgule.
			Montant_Frais, -- Montant total des frais des conventions.
			Montant_Epargne, -- Montant total des épargnes des conventions.
			Nom_representant, -- Prénom et nom du représentant du souscripteur. (Ex : Francine Adam)
			agreement_s, -- « agreements » s’il y a plus d’une convention et « agreement » s’il n’y en n’a qu’une. Le « a » sera en minuscule.
			convention_s, -- « conventions » s’il y a plus d’une convention et « convention » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
			la_les, -- « les » s’il y a plus d’une convention et « la » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
			votre_vos, -- « vos » s’il y a plus d’une convention et « votre » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
			Tel_Souscripteur, -- Numéro de téléphone à la maison du souscripteur dans le format suivant : 4186518975.
			SubscriberID,
			Appel3
		FROM #tTerminatedNotice 
		WHERE @DocAction IN (1,2)
	END

	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM CRQ_DocTemplate
			WHERE DocTypeID = @iDocTypeID
				AND DocTemplateTime < @dtToday )
		RETURN -1 -- Pas de template d'entré ou en vigueur pour ce type de document
	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM #tTerminatedNotice)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	DROP TABLE #tTerminatedNotice
END


