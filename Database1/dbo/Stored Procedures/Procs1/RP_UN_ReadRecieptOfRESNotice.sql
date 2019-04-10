/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                : 	RP_UN_ReadRecieptOfRESNotice
Description        : 	Document : Accusé réception d’avis de résiliation
Valeurs de retours : 	Dataset :
									Date 					VARCHAR(25)		Ce sera la date à laquelle la lettre aura été commandée 
																				dans le format suivant : « 12 décembre 2005 » ou 
																				« December 12, 2005 » selon la langue du souscripteur.
									Appel1				VARCHAR(75)		« Monsieur », « Madame », « Madam » ou « Sir » selon le 
																				sexe et la langue du souscripteur.
									Appel2				VARCHAR(75)		« Mr », « Mrs » selon le sexe et la langue anglaise du 
																				souscripteur.  
									Destinataire		VARCHAR(87)		Prénom et nom du souscripteur à qui on envoie l’accusé 
																				réception. (Ex : Éric Ranger)
									Adresse				VARCHAR(75)		Numéro civique, rue et numéro d’appartement du 
																				souscripteur.
									Ville					VARCHAR(100)	Ville du souscripteur.
									Province				VARCHAR(75)		Province du souscripteur.
									Code_Postal			VARCHAR(10)		Code postal du souscripteur.
									No_s_convention_s	VARCHAR(1000)	Numéros de la ou des conventions sélectionnées 
																				préalablement dans la liste. Chaque # de convention 
																				seront séparés par une virgule.
									convention_s		VARCHAR(15)		Quand le nombre de conventions sélectionnées sera de plus 
																				de un, alors ce sera « conventions », sinon ce sera 
																				« convention ». Quand le souscripteur sera anglais, ce 
																				sera « agreements » ou « agreement ».
									Nbre_unites			VARCHAR(20)		Nombre total d’unités de la ou des conventions 
																				sélectionnées.
									Unite_s				VARCHAR(10)		Quand la valeur de « Nbre_unites » sera plus élevée que 
																				un, alors ce sera « unités », sinon ce sera « unité ». 
																				Quand le souscripteur sera anglais, ce sera « units » ou 
																				« unit ».
									Montant_frais		VARCHAR(20)		Montant total des frais de la ou des conventions.
									Montant_epargne	VARCHAR(20)		Montant total d’épargne de la ou des conventions.
									la_les				VARCHAR(5)		« les » s’il y a plus d’une convention et « la » s’il n’y 
																				en n’a qu’une. Le premier caractère sera en minuscule.
									suivante_s			VARCHAR(10)		« suivantes » s’il y a plus d’une convention et 
																				« suivante » s’il n’y en n’a qu’une. Le premier caractère 
																				sera en minuscule.
									votre_vos			VARCHAR(10)		« vos » s’il y a plus d’une convention et « votre » s’il 
																				n’y en n’a qu’une. Le premier caractère sera en minuscule.
									s_eleve_nt			VARCHAR(15)		« s’élèvent » s’il y a plus d’une convention et 
																				« s’élève » s’il n’y en n’a qu’une. Le premier caractère 
																				sera en minuscule.
									IDSouscripteur		INTEGER			Identifiant unique du souscripteur
									Appel3				VARCHAR(75)		« Mr », « Mrs » selon le sexe et la langue anglaise du 
																				souscripteur plus le nom.  
								@ReturnValue :
	                      	>0  : Tout à fonctionné
									<=0 : Erreur SQL
										-1 :  Pas de template d'entré ou en vigueur pour ce type de document
										-2 :  Pas de document(s) de généré(s)
Note                :	ADX0000803	IA	2006-02-01	Bruno Lapointe		Création
			ADX0002033	BR	2006-07-18	Mireya Gonthier		Modification	
										2008-09-25	Josée Parent		Ne pas produire de DataSet pour les documents 
																		commandés
						GLPI6399		2011-11-21  Eric Michaud		Ajout de l'id souscripteur et de Appel3
						GLPI6983		2012-02-10  Eric Michaud		Modification pour suivie des modifications
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ReadRecieptOfRESNotice] (
	@ConnectID INTEGER, -- ID de connexion de l’usager
	@vcConventionIDs VARCHAR(1000), -- IDs des conventions séparés par des virgules.
	@DocAction INTEGER ) -- ID de l'action (0 = commander le document, 1 = produire, 2 = produire et créer un historique 
								-- dans la gestion des documents.
AS
BEGIN
	DECLARE 
		@dtToday DATETIME,
		@iDocTypeID INTEGER,
		@fUnitQty MONEY,
		@vcConventionNo VARCHAR(75),
		@vcConventionNos VARCHAR(2000),
		@iID_Utilisateur INT,
		@bJustOneConv BIT

	SET @dtToday = GETDATE()

    SELECT TOP 1 @iID_Utilisateur = USR.UserID
    FROM Mo_Connect CON 
		INNER JOIN Mo_User USR ON USR.UserID = CON.UserID
    WHERE CON.ConnectID = @ConnectID;

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

	SELECT @fUnitQty = SUM(U.UnitQty)
	FROM #tConventions tC
	JOIN dbo.Un_Unit U ON U.ConventionID = tC.ConventionID

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
	CREATE TABLE #tReadRecieptOfRESNotice(
		DocTemplateID INTEGER, -- ID du template de document
	--------------------------------
		LangID VARCHAR(3), -- Code de 3 lettres représentant la langue du document, soit la langue du souscripteur
		Date VARCHAR(25), -- Ce sera la date à laquelle la lettre aura été commandée dans le format suivant : « 12 décembre 2005 » ou « December 12, 2005 » selon la langue du souscripteur.
		Appel1 VARCHAR(75), -- « Monsieur », « Madame », « Madam » ou « Sir » selon le sexe et la langue du souscripteur.
		Appel2 VARCHAR(75), -- « Mr », « Mrs » selon le sexe et la langue anglaise du souscripteur.  
		Destinataire VARCHAR(87), -- Prénom et nom du souscripteur à qui on envoie l’accusé réception. (Ex : Éric Ranger)
		Adresse VARCHAR(75), -- Numéro civique, rue et numéro d’appartement du souscripteur.
		Ville VARCHAR(100), -- Ville du souscripteur.
		Province VARCHAR(75), -- Province du souscripteur.
		Code_Postal VARCHAR(10), -- Code postal du souscripteur.
		No_s_convention_s VARCHAR(1000), -- Numéros de la ou des conventions sélectionnées préalablement dans la liste. Chaque # de convention seront séparés par une virgule.
		convention_s VARCHAR(15), -- Quand le nombre de conventions sélectionnées sera de plus de un, alors ce sera « conventions », sinon ce sera « convention ». Quand le souscripteur sera anglais, ce sera « agreements » ou « agreement ».
		Nbre_unites VARCHAR(20), -- Nombre total d’unités de la ou des conventions sélectionnées.
		Unite_s VARCHAR(10), -- Quand la valeur de « Nbre_unites » sera plus élevée que un, alors ce sera « unités », sinon ce sera « unité ». Quand le souscripteur sera anglais, ce sera « units » ou « unit ».
		Montant_frais VARCHAR(20), -- Montant total des frais de la ou des conventions.
		Montant_epargne VARCHAR(20), -- Montant total d’épargne de la ou des conventions.
		la_les VARCHAR(5), -- « les » s’il y a plus d’une convention et « la » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
		suivante_s VARCHAR(10), -- « suivantes » s’il y a plus d’une convention et « suivante » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
		votre_vos VARCHAR(10), -- « vos » s’il y a plus d’une convention et « votre » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
		s_eleve_nt VARCHAR(15), -- « s’élèvent » s’il y a plus d’une convention et « s’élève » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
		NomDestinataire VARCHAR(50),
		PrenomDestinataire VARCHAR(35),
		SubscriberID integer,
		Appel3 VARCHAR(75) -- « Mr », « Mrs » selon le sexe et la langue anglaise du souscripteur et le nom.  		
	)

	-- Va chercher le bon type de document
	SELECT 
		@iDocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'ReadRecieptOfRESNot'

	-- Remplis la table temporaire
	INSERT INTO #tReadRecieptOfRESNotice
		SELECT
			T.DocTemplateID,
			HS.LangID,
			Date = dbo.fn_Mo_DateToLongDateStr(GETDATE(), HS.LangID), -- Ce sera la date à laquelle la lettre aura été commandée dans le format suivant : « 12 décembre 2005 » ou « December 12, 2005 » selon la langue du souscripteur.
			Appel1 = SxS.LongSexName, -- « Monsieur », « Madame », « Madam » ou « Sir » selon le sexe et la langue du souscripteur.
			Appel2 = A2.ShortSexName, -- « Mr », « Mrs » selon le sexe et la langue anglaise du souscripteur.  
			Destinataire = HS.FirstName + ' ' + HS.LastName, -- Prénom et nom du souscripteur à qui on envoie l’accusé réception. (Ex : Éric Ranger)
			Adresse = AdS.Address, -- Numéro civique, rue et numéro d’appartement du souscripteur.
			Ville = AdS.City, -- Ville du souscripteur.
			Province = AdS.Statename, -- Province du souscripteur.
			Code_Postal = dbo.fn_Mo_FormatZIP(AdS.ZipCode, AdS.CountryID), -- Code postal du souscripteur.
			No_s_convention_s = @vcConventionNos, -- Numéros de la ou des conventions sélectionnées préalablement dans la liste. Chaque # de convention seront séparés par une virgule.
			convention_s =
				CASE 
					WHEN @bJustOneConv = 1 AND HS.LangID = 'FRA' THEN 'convention'
					WHEN @bJustOneConv = 0 AND HS.LangID = 'FRA' THEN 'conventions'
					WHEN @bJustOneConv = 1 AND HS.LangID = 'ENU' THEN 'agreement'
					WHEN @bJustOneConv = 0 AND HS.LangID = 'ENU' THEN 'agreements'
				ELSE ''
				END, -- Quand le nombre de conventions sélectionnées sera de plus de un, alors ce sera « conventions », sinon ce sera « convention » . Quand le souscripteur sera anglais, ce sera « agreements » ou « agreement ».
			
			Nbre_unites = dbo.fn_Mo_FloatToStr(@fUnitQty, HS.LangID, 3, 0), -- Nombre total d’unités de la ou des conventions sélectionnées.
			Unite_s =
				CASE 
					WHEN @fUnitQty > 1 AND HS.LangID = 'FRA' THEN 'unités'
					WHEN @fUnitQty <= 1 AND HS.LangID = 'FRA' THEN 'unité'
					WHEN @fUnitQty > 1 AND HS.LangID = 'ENU' THEN 'units'
					WHEN @fUnitQty <= 1 AND HS.LangID = 'ENU' THEN 'unit'
				ELSE ''
				END, -- Quand la valeur de « Nbre_unites » sera plus élevée que un, alors ce sera « unités », sinon ce sera « unité ». Quand le souscripteur sera anglais, ce sera « units » ou « unit ».
			Montant_frais = dbo.fn_Mo_MoneyToStr(SUM(Ct.Fee), HS.LangID, 1), -- Montant total des frais de la ou des conventions.
			Montant_epargne = dbo.fn_Mo_MoneyToStr(SUM(Ct.Cotisation), HS.LangID, 1), -- Montant total d’épargne de la ou des conventions.
			la_les =
				CASE 
					WHEN @bJustOneConv = 1 THEN 'la'
				ELSE 'les'
				END, -- « les » s’il y a plus d’une convention et « la » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
			suivante_s =
				CASE 
					WHEN @bJustOneConv = 1 THEN 'suivante'
				ELSE 'suivantes'
				END, -- « suivantes » s’il y a plus d’une convention et « suivante » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
			votre_vos =
				CASE 
					WHEN @bJustOneConv = 1 THEN 'votre'
				ELSE 'vos'
				END, -- « vos » s’il y a plus d’une convention et « votre » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
			s_eleve_nt =
				CASE 
					WHEN @bJustOneConv = 1 THEN 's’élève'
				ELSE 's’élèvent'
				END,  -- « s’élèvent » s’il y a plus d’une convention et « s’élève » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
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
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
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
		WHERE (	( O.OperTypeID = 'CPA' 
			 		AND OBF.OperID IS NOT NULL
					)
				OR O.OperDate <= GETDATE()
				)
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
				ISNULL(No_s_convention_s,''),
				ISNULL(NomDestinataire+', '+PrenomDestinataire,''),
				'',
				ISNULL(LangID,'')+';'+
				ISNULL(Date,'')+';'+
				ISNULL(Appel1,'')+';'+
				ISNULL(Appel2,'')+';'+
				ISNULL(Destinataire,'')+';'+
				ISNULL(Adresse,'')+';'+
				ISNULL(Ville,'')+';'+
				ISNULL(Province,'')+';'+
				ISNULL(Code_Postal,'')+';'+
				ISNULL(No_s_convention_s,'')+';'+
				ISNULL(convention_s,'')+';'+
				ISNULL(Nbre_unites,'')+';'+
				ISNULL(Unite_s,'')+';'+
				ISNULL(Montant_frais,'')+';'+
				ISNULL(Montant_epargne,'')+';'+
				ISNULL(la_les,'')+';'+
				ISNULL(suivante_s,'')+';'+
				ISNULL(votre_vos,'')+';'+
				ISNULL(s_eleve_nt,'')+';'+
			    cast(SubscriberID as varchar(15))+';'+
				ISNULL(Appel3,'')+';'
			FROM #tReadRecieptOfRESNotice

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
	
	IF @DocAction <> 0
	BEGIN
		-- Produit un dataset pour la fusion
		SELECT 
			DocTemplateID, -- ID du template de document
			LangID, -- Code de 3 lettres représentant la langue du document, soit la langue du souscripteur
			Date, -- Ce sera la date à laquelle la lettre aura été commandée dans le format suivant : « 12 décembre 2005 » ou « December 12, 2005 » selon la langue du souscripteur.
			Appel1, -- « Monsieur », « Madame », « Madam » ou « Sir » selon le sexe et la langue du souscripteur.
			Appel2, -- « Mr », « Mrs » selon le sexe et la langue anglaise du souscripteur.  
			Destinataire, -- Prénom et nom du souscripteur à qui on envoie l’accusé réception. (Ex : Éric Ranger)
			Adresse, -- Numéro civique, rue et numéro d’appartement du souscripteur.
			Ville, -- Ville du souscripteur.
			Province, -- Province du souscripteur.
			Code_Postal, -- Code postal du souscripteur.
			No_s_convention_s, -- Numéros de la ou des conventions sélectionnées préalablement dans la liste. Chaque # de convention seront séparés par une virgule.
			convention_s, -- Quand le nombre de conventions sélectionnées sera de plus de un, alors ce sera « conventions », sinon ce sera « convention ». Quand le souscripteur sera anglais, ce sera « agreements » ou « agreement ».
			Nbre_unites, -- Nombre total d’unités de la ou des conventions sélectionnées.
			Unite_s, -- Quand la valeur de « Nbre_unites » sera plus élevée que un, alors ce sera « unités », sinon ce sera « unité ». Quand le souscripteur sera anglais, ce sera « units » ou « unit ».
			Montant_frais, -- Montant total des frais de la ou des conventions.
			Montant_epargne, -- Montant total d’épargne de la ou des conventions.
			la_les, -- « les » s’il y a plus d’une convention et « la » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
			suivante_s, -- « suivantes » s’il y a plus d’une convention et « suivante » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
			votre_vos, -- « vos » s’il y a plus d’une convention et « votre » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
			s_eleve_nt, -- « s’élèvent » s’il y a plus d’une convention et « s’élève » s’il n’y en n’a qu’une. Le premier caractère sera en minuscule.
			SubscriberID,
			Appel3
		FROM #tReadRecieptOfRESNotice 
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
			FROM #tReadRecieptOfRESNotice)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
	BEGIN
		DECLARE
			@Today DATETIME

		SET @Today = dbo.FN_CRQ_DateNoTime(GETDATE())

		-- Supprime les arrêts de paiement actif en date du jour qui ne sont pas de type RES (Résiliation) ou RNA (Résiliation sans NAS)
		DELETE Un_Breaking
		FROM Un_Breaking
		JOIN #tConventions C ON Un_Breaking.ConventionID = C.ConventionID 
		WHERE Un_Breaking.BreakingTypeID NOT IN ('RES', 'RNA')
			AND Un_Breaking.BreakingStartDate >= @Today

		-- Met fin au arrêt de paiement actif qui ne sont pas de type RES (Résiliation) ou RNA (Résiliation sans NAS)
		UPDATE Un_Breaking
		SET BreakingEndDate = @Today-1,
			iID_Utilisateur_Modification	= @iID_Utilisateur,
			dtDate_Modification_Operation	= @dtToday
		FROM Un_Breaking B
		JOIN #tConventions C ON B.ConventionID = C.ConventionID 
		WHERE B.BreakingTypeID NOT IN ('RES', 'RNA')
			AND @Today BETWEEN B.BreakingStartDate AND ISNULL(B.BreakingEndDate,@Today)

		-- Inscrit un arrêt de paiement au besoin S'il y en a pas d'actif.
		INSERT INTO Un_Breaking (
				ConventionID,
				BreakingTypeID,
				BreakingStartDate,
				BreakingReason,
				iID_Utilisateur_Creation,			
				dtDate_Creation_Operation,			
				iID_Utilisateur_Modification,		
				dtDate_Modification_Operation)		
 			SELECT
				C.ConventionID,
				'RES',
				@Today,
				'Accusé réception d''avis de résiliation',
				@iID_Utilisateur,			
				@dtToday,			
				NULL,								
				NULL								
			FROM #tConventions C
			LEFT JOIN Un_Breaking B ON B.ConventionID = C.ConventionID 
											AND B.BreakingTypeID IN ('RES', 'RNA')
											AND @Today BETWEEN B.BreakingStartDate AND ISNULL(B.BreakingEndDate,@Today)
			WHERE B.ConventionID IS NULL

		RETURN 1 -- Tout a bien fonctionné
	END

	DROP TABLE #tReadRecieptOfRESNotice
END


