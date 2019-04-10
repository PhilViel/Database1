/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                : 	RP_UN_ClosedAccountLetter
Description        : 	Document : Lettre d’effet retourné pour raison de compte fermé
Valeurs de retours : 	Dataset :
									Date 						VARCHAR(25)		Ce sera la date à laquelle la lettre aura été commandée 
																					dans le format suivant : « 12 décembre 2005 » ou 
																					« December 12, 2005 » selon la langue du souscripteur.
									Appel1					VARCHAR(75)		« Monsieur », « Madame », « Madam » ou « Sir » selon le 
																					sexe et la langue du souscripteur.
									Appel2					VARCHAR(75)		« Mr », « Mrs » selon le sexe et la langue anglaise du 
																					souscripteur.  
									Destinataire			VARCHAR(87)		Prénom et nom du souscripteur qui a causé l’effet 
																					retourné. (Ex : Éric Ranger)
									Adresse					VARCHAR(75)		Numéro civique, rue et numéro d’appartement du 
																					souscripteur.
									Ville						VARCHAR(100)	Ville du souscripteur.
									Province					VARCHAR(75)		Province du souscripteur.
									Code_Postal				VARCHAR(10)		Code postal du souscripteur.
									No_convention			VARCHAR(75)		Numéro de la plus vieille convention du dépôt qui a été 
																					retourné. (Ex : prélèvement 1 le 20 juillet retourné le 
																					23 juillet. La date sera le « 20 juillet 2005 »).
									Date_cheque				VARCHAR(25)		Date d’opération du dépôt retourné. (Ex : prélèvement 1 
																					le 20 juillet retourné le 23 juillet. La date sera le 
																					« 20 juillet 2005 » ou July 20, 2005 si le souscripteur 
																					est anglophone).
									Montant_cheque			VARCHAR(20)		Montant du dépôt retourné, multiplié par deux. (Ex : 
																					pour un dépôt total de 50.00$, 10.00$ sur cinq 
																					conventions, le montant sera 100.00$ (50.00$ * 2))
									Mois_a_couvrir			VARCHAR(15)		Le nom en lettre du mois de la date d’opération du dépôt 
																					retourné et du suivant selon la langue du souscripteur. 
																					(Ex : juillet et août / July and August).
									An_Mois_a_couvrir		VARCHAR(4)		L'année des dernier mois à couvrir.
									Nom_representant		VARCHAR(87)		Prénom et nom du représentant du souscripteur. 
																					(Ex : Francine Adam)
									vos_votre_convention	VARCHAR(20)		« vos conventions » s’il y a plus d’une convention et 
																					« votre convention » s’il n’y en n’a qu’une. Le premier 
																					« v » sera en minuscule.
									agreement_s				VARCHAR(15)		« agreements » s’il y a plus d’une convention et 
																					« agreement » s’il n’y en n’a qu’une. Le « a » sera en 
																					minuscule. En anglais seulement.
								@ReturnValue :
	                      	>0  : Tout à fonctionné
									<=0 : Erreur SQL
										-1 :  Pas de template d'entré ou en vigueur pour ce type de document
										-2 :  Pas de document(s) de généré(s)
Note                :	ADX0000801	IA	2006-02-03	Bruno Lapointe		Création
								ADX0001929	BR 2006-08-04	Bruno Lapointe		Fait un lien entre l'opération et le docuement.
												2008-05-12	Pierre-Luc Simard	Ajout du champ An_Mois_a_couvrir pour indiquer l'année des mois à couvrir
												2008-09-25	Josée Parent		Ne pas produire de DataSet pour les documents commandés
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ClosedAccountLetter] (
	@ConnectID INTEGER, -- ID de connexion de l’usager
	@ConventionID INTEGER, -- ID de la convention (0 si le paramètre @OperID doit être utilisé).
	@OperID INTEGER, -- ID de l’opération NSF
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = produire, 2 = produire et créer un historique dans la gestion des documents.
AS
BEGIN
	DECLARE 
		@dtToday DATETIME,
		@iDocTypeID INTEGER,
		@vcConventionNo VARCHAR(75),
		@fMontant_cheque MONEY,
		@bJustOneConv BIT

	SET @dtToday = GETDATE()

	-- Si on demande la lettre pour une convention, on va chercher le ID de la dernière opération NSF de cette convention
	IF @ConventionID > 0
	BEGIN 
		SET @OperID = 0

		SELECT @OperID = MAX(O.OperID)
		FROM dbo.Un_Unit U
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Mo_BankReturnLink BL ON BL.BankReturnCodeID = O.OperID AND BL.BankReturnTypeID = '905'
		WHERE O.OperTypeID = 'NSF'
			AND U.ConventionID = @ConventionID
	END

	-- Va chercher le numéro de la plus vieille convention
	SELECT @vcConventionNo = C.ConventionNo
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	JOIN (
		SELECT UnitID = MIN(U.UnitID)
		FROM dbo.Un_Unit U
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN (
			SELECT InForceDate = MIN(U.InForceDate)
			FROM dbo.Un_Unit U
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			WHERE O.OperID = @OperID
			) V ON V.InForceDate = U.InForceDate
		WHERE O.OperID = @OperID
		) V ON V.UnitID = U.UnitID

	-- Détermine s'il n'y qu'une convention ou plusieurs
	IF (	SELECT COUNT(DISTINCT U.ConventionID) 
			FROM dbo.Un_Unit U
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			WHERE O.OperID = @OperID	) = 1
		SET @bJustOneConv = 1
	ELSE
		SET @bJustOneConv = 0

	-- Va chercher le montant du chèque
	SELECT @fMontant_cheque = SUM(Ct.Cotisation+Ct.Fee+Ct.SubscInsur+Ct.BenefInsur+Ct.TaxOnInsur)+ISNULL(CO.fInt,0)
	FROM Un_Oper O
	JOIN Mo_BankReturnLink BL ON BL.BankReturnCodeID = O.OperID
	JOIN Un_Oper O2 ON O2.OperID = BL.BankReturnSourceCodeID
	JOIN Un_Cotisation Ct ON Ct.OperID = O2.OperID
	LEFT JOIN (
		SELECT 
			O2.OperID,
			fInt = SUM(CO.ConventionOperAmount)
		FROM Un_Oper O
		JOIN Mo_BankReturnLink BL ON BL.BankReturnCodeID = O.OperID
		JOIN Un_Oper O2 ON O2.OperID = BL.BankReturnSourceCodeID
		JOIN Un_ConventionOper CO ON CO.OperID = O.OperID
		WHERE O.OperID = @OperID
		GROUP BY O2.OperID
		) CO ON CO.OperID = O2.OperID
	WHERE O.OperID = @OperID
	GROUP BY CO.fInt

	-- Table temporaire qui contient le certificat
	CREATE TABLE #tClosedAccountLetter(
		DocTemplateID INTEGER, -- ID du template de document
		LangID VARCHAR(3), -- Code de 3 lettres représentant la langue du document, soit la langue du souscripteur
		Date VARCHAR(25), -- Ce sera la date à laquelle la lettre aura été commandée dans le format suivant : « 12 décembre 2005 » ou « December 12, 2005 » selon la langue du souscripteur.
		Appel1 VARCHAR(75), -- « Monsieur », « Madame », « Madam » ou « Sir » selon le sexe et la langue du souscripteur.
		Appel2 VARCHAR(75), -- « Mr », « Mrs » selon le sexe et la langue anglaise du souscripteur.  
		Destinataire VARCHAR(87), -- Prénom et nom du souscripteur qui a causé l’effet retourné. (Ex : Éric Ranger)
		Adresse VARCHAR(75), -- Numéro civique, rue et numéro d’appartement du souscripteur.
		Ville VARCHAR(100), -- Ville du souscripteur.
		Province VARCHAR(75), -- Province du souscripteur.
		Code_Postal VARCHAR(10), -- Code postal du souscripteur.
		No_convention VARCHAR(75), -- Numéro de la plus vieille convention du dépôt qui a été retourné. (Ex : prélèvement 1 le 20 juillet retourné le 23 juillet. La date sera le « 20 juillet 2005 »).
		Date_cheque VARCHAR(25), -- Date d’opération du dépôt retourné. (Ex : prélèvement 1 le 20 juillet retourné le 23 juillet. La date sera le « 20 juillet 2005 » ou July 20, 2005 si le souscripteur est anglophone).
		Montant_cheque VARCHAR(20), -- Montant du dépôt retourné, multiplié par deux. (Ex : pour un dépôt total de 50.00$, 10.00$ sur cinq conventions, le montant sera 100.00$ (50.00$ * 2))
		Mois_a_couvrir VARCHAR(30), -- Le nom en lettre du mois de la date d’opération du dépôt retourné et du suivant selon la langue du souscripteur. (Ex : juillet et août / July and August).
		An_Mois_a_couvrir VARCHAR(4), -- L'année des derniers mois à couvrir
		Nom_representant VARCHAR(87), -- Prénom et nom du représentant du souscripteur. (Ex : Francine Adam)
		vos_votre_convention VARCHAR(20), -- « vos conventions » s’il y a plus d’une convention et « votre convention » s’il n’y en n’a qu’une. Le premier « v » sera en minuscule.
		agreement_s VARCHAR(15), -- « agreements » s’il y a plus d’une convention et « agreement » s’il n’y en n’a qu’une. Le « a » sera en minuscule. En anglais seulement.
		NomDestinataire VARCHAR(50),
		PrenomDestinataire VARCHAR(35)
	)

	-- Va chercher le bon type de document
	SELECT 
		@iDocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'ClosedAccountLetter'

	-- Remplis la table temporaire
	INSERT INTO #tClosedAccountLetter
		SELECT DISTINCT
			T.DocTemplateID,
			HS.LangID,
			Date = dbo.fn_Mo_DateToLongDateStr(@dtToday, HS.LangID), -- Ce sera la date à laquelle la lettre aura été commandée dans le format suivant : « 12 décembre 2005 » ou « December 12, 2005 » selon la langue du souscripteur.
			Appel1 = SxS.LongSexName, -- « Monsieur », « Madame », « Madam » ou « Sir » selon le sexe et la langue du souscripteur.
			Appel2 = A2.ShortSexName, -- « Mr », « Mrs » selon le sexe et la langue anglaise du souscripteur.  
			Destinataire = HS.FirstName + ' ' + HS.LastName, -- Prénom et nom du souscripteur qui a causé l’effet retourné. (Ex : Éric Ranger)
			Adresse = AdS.Address, -- Numéro civique, rue et numéro d’appartement du souscripteur.
			Ville = AdS.City, -- Ville du souscripteur.
			Province = AdS.Statename, -- Province du souscripteur.
			Code_Postal = dbo.fn_Mo_FormatZIP(AdS.ZipCode, AdS.CountryID), -- Code postal du souscripteur.
			No_convention = @vcConventionNo, -- Numéro de la plus vieille convention du dépôt qui a été retourné. (Ex : prélèvement 1 le 20 juillet retourné le 23 juillet. La date sera le « 20 juillet 2005 »).
			Date_cheque = dbo.fn_Mo_DateToLongDateStr(O.OperDate, HS.LangID), -- Date d’opération du dépôt retourné. (Ex : prélèvement 1 le 20 juillet retourné le 23 juillet. La date sera le « 20 juillet 2005 » ou July 20, 2005 si le souscripteur est anglophone).
			Montant_cheque = dbo.fn_Mo_MoneyToStr(@fMontant_cheque*2, HS.LangID, 1), -- Montant du dépôt retourné, multiplié par deux. (Ex : pour un dépôt total de 50.00$, 10.00$ sur cinq conventions, le montant sera 100.00$ (50.00$ * 2))
			Mois_a_couvrir = 
				dbo.fn_Mo_TranslateMonthToStr(O.OperDate, HS.LangID)+
				CASE 
					WHEN HS.LangID = 'FRA' THEN ' et '
				ELSE ' and '
				END+
				dbo.fn_Mo_TranslateMonthToStr(DATEADD(MONTH, 1, O.OperDate), HS.LangID), -- Le nom en lettre du mois de la date d’opération du dépôt retourné et du suivant selon la langue du souscripteur. (Ex : juillet et août / July and August).
			An_Mois_a_couvrir = CAST(YEAR(DATEADD(MONTH, 1, O.OperDate)) AS VARCHAR(4)), -- L'année des derniers mois à couvrir.
			Nom_representant = HR.FirstName + ' ' + HR.LastName, -- Prénom et nom du représentant du souscripteur. (Ex : Francine Adam)
			vos_votre_convention = 
				CASE 
					WHEN @bJustOneConv = 1 THEN 'votre convention'
				ELSE 'vos conventions'
				END, -- « vos conventions » s’il y a plus d’une convention et « votre convention » s’il n’y en n’a qu’une. Le premier « v » sera en minuscule.
			agreement_s =
				CASE 
					WHEN @bJustOneConv = 1 THEN 'agreement'
				ELSE 'agreements'
				END, -- « agreements » s’il y a plus d’une convention et « agreement » s’il n’y en n’a qu’une. Le « a » sera en minuscule. En anglais seulement.
			NomDestinataire = HS.LastName,
			PrenomDestinataire = HS.FirstName
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
		JOIN Mo_Sex SxS ON HS.LangID = SxS.LangID AND HS.SexID = SxS.SexID
		JOIN Mo_Sex A2 ON 'ENU' = A2.LangID AND HS.SexID = A2.SexID
		JOIN dbo.Mo_Adr AdS ON AdS.AdrID = HS.AdrID
		JOIN dbo.Mo_Human HR ON HR.HumanID = S.RepID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper ONSF ON ONSF.OperID = Ct.OperID
		JOIN Mo_BankReturnLink BL ON BL.BankReturnCodeID = ONSF.OperID
		JOIN Un_Oper O ON O.OperID = BL.BankReturnSourceCodeID
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
		WHERE ONSF.OperID = @OperID

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
				ISNULL(No_convention,''),
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
				ISNULL(No_convention,'')+';'+
				ISNULL(Date_cheque,'')+';'+
				ISNULL(Montant_cheque,'')+';'+
				ISNULL(Mois_a_couvrir,'')+';'+
				ISNULL(An_Mois_a_couvrir,'')+';'+
				ISNULL(Nom_representant,'')+';'+
				ISNULL(vos_votre_convention,'')+';'+
				ISNULL(agreement_s,'')+';'
			FROM #tClosedAccountLetter

		-- Fait un lient entre le document et la convention pour que retrouve le document 
		-- dans l'historique des documents de la convention
		INSERT INTO CRQ_DocLink 
			SELECT
				tC.ConventionID,
				1,
				D.DocID
			FROM CRQ_Doc D 
			JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
			CROSS JOIN (
				SELECT DISTINCT U.ConventionID
				FROM Un_Cotisation Ct
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				WHERE Ct.OperID = @OperID
				) tC
			LEFT JOIN CRQ_DocLink L ON L.DocLinkID = tC.ConventionID AND L.DocLinkType = 1 AND L.DocID = D.DocID
			WHERE L.DocID IS NULL
			  AND T.DocTypeID = @iDocTypeID
			  AND D.DocOrderTime = @dtToday
			  AND D.DocOrderConnectID = @ConnectID	

		-- Fait un lien entre le document et l'opération pour pouvoir supprimer le document si on supprime l'opération
		INSERT INTO CRQ_DocLink 
			SELECT
				@OperID,
				10,
				D.DocID
			FROM CRQ_Doc D 
			JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
			LEFT JOIN CRQ_DocLink L ON L.DocLinkID = @OperID AND L.DocLinkType = 10 AND L.DocID = D.DocID
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
			Destinataire, -- Prénom et nom du souscripteur qui a causé l’effet retourné. (Ex : Éric Ranger)
			Adresse, -- Numéro civique, rue et numéro d’appartement du souscripteur.
			Ville, -- Ville du souscripteur.
			Province, -- Province du souscripteur.
			Code_Postal, -- Code postal du souscripteur.
			No_convention, -- Numéro de la plus vieille convention du dépôt qui a été retourné. (Ex : prélèvement 1 le 20 juillet retourné le 23 juillet. La date sera le « 20 juillet 2005 »).
			Date_cheque, -- Date d’opération du dépôt retourné. (Ex : prélèvement 1 le 20 juillet retourné le 23 juillet. La date sera le « 20 juillet 2005 » ou July 20, 2005 si le souscripteur est anglophone).
			Montant_cheque, -- Montant du dépôt retourné, multiplié par deux. (Ex : pour un dépôt total de 50.00$, 10.00$ sur cinq conventions, le montant sera 100.00$ (50.00$ * 2))
			Mois_a_couvrir, -- Le nom en lettre du mois de la date d’opération du dépôt retourné et du suivant selon la langue du souscripteur. (Ex : juillet et août / July and August).
			An_Mois_a_couvrir, -- L'année des derniers mois à couvrir
			Nom_representant, -- Prénom et nom du représentant du souscripteur. (Ex : Francine Adam)
			vos_votre_convention, -- « vos conventions » s’il y a plus d’une convention et « votre convention » s’il n’y en n’a qu’une. Le premier « v » sera en minuscule.
			agreement_s -- « agreements » s’il y a plus d’une convention et « agreement » s’il n’y en n’a qu’une. Le « a » sera en minuscule. En anglais seulement.
		FROM #tClosedAccountLetter 
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
			FROM #tClosedAccountLetter)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	DROP TABLE #tClosedAccountLetter
END


