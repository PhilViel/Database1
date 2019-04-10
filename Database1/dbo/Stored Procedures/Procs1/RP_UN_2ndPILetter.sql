/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                : 	RP_UN_2ndPILetter
Description        : 	Document : Lettre de deuxième provision insuffisante
Valeurs de retours : 	Dataset :
									Date 								VARCHAR(25)		Ce sera la date à laquelle la lettre aura été 
																							commandée dans le format suivant : « 12 décembre 
																							2005 » ou « December 12, 2005 » selon la langue 
																							du souscripteur.
									Appel1							VARCHAR(75)		« Monsieur », « Madame », « Madam » ou « Sir » 
																							selon le sexe et la langue du souscripteur.
									Appel2							VARCHAR(75)		« Mr », « Mrs » selon le sexe et la langue 
																							anglaise du souscripteur.  
									Destinataire					VARCHAR(87)		Prénom et nom du souscripteur qui a causé l’effet 
																							retourné. (Ex : Éric Ranger)
									Adresse							VARCHAR(75)		Numéro civique, rue et numéro d’appartement du 
																							souscripteur.
									Ville								VARCHAR(100)	Ville du souscripteur.
									Province							VARCHAR(75)		Province du souscripteur.
									Code_Postal						VARCHAR(10)		Code postal du souscripteur.
									No_convention					VARCHAR(75)		Numéro de la plus vieille convention du dépôt qui 
																							a été retourné.
									Date_prelevement				VARCHAR(25)		Date d’opération du dépôt retourné dans le format 
																							suivant : 12 décembre 2005 ou December 12, 2005.
									Nbre_mois_retard				INTEGER			Nombre de mois de retard en chiffre.
									Montant_cheque					VARCHAR(75)		Montant du dépôt qui a été retourné, multiplié par 
																							trois (pour couvrir les deux mois de retard et le 
																							mois suivant).
									Mois_a_couvrir					VARCHAR(75)		Le nom en lettre du mois de la date d’opération du 
																							dépôt qui a été retourné ainsi que du mois qui le 
																							précédait et du mois prochain selon la langue du 
																							souscripteur. (Ex : juillet, août et septembre / 
																							July, August and September).
									An_Mois_a_couvrir				VARCHAR(4)		L'année du dernier mois à couvrir.
									Date_premier_PI				VARCHAR(25)		Plus petite date d’opération des effets retournés.
																							(Ex : prélèvement 1 le 20 juillet retourné le 23 
																							juillet et prélèvement 2 le 20 août retourné le 24 
																							août. Il sera affiché la date du prélèvement 1 
																							soit le 20 juillet).
									Date_reponse					VARCHAR(25)		Date d’opération du dépôt, qui a été retourné, 
																							additionnée d’un mois.
									Nom_representant				VARCHAR(87)		Prénom et nom du représentant du souscripteur. 
																							(Ex : Francine Adam)
									Vos_Votre_Convention_Maj	VARCHAR(20)		« Vos conventions » s’il y a plus d’une convention 
																							et « Votre convention » s’il n’y en n’a qu’une. Le 
																							premier « V » sera en majuscule.
									vos_votre_convention_min	VARCHAR(20)		« vos conventions » s’il y a plus d’une convention 
																							et « votre convention » s’il n’y en n’a qu’une. Le 
																							premier « v » sera en minuscule.
									agreement_s						VARCHAR(15)	 	« agreements » s’il y a plus d’une convention et 
																							« agreement » s’il n’y en n’a qu’une. Le « a » 
																							sera en minuscule.
									is_are							VARCHAR(5)	 	« are » s’il y a plus d’une convention et « is » 
																							s’il n’y en n’a qu’une. La première lettre du mot 
																							sera en minuscule.
									Tel_Souscripteur				VARCHAR(30)		Numéro de téléphone à la maison du souscripteur 
																							dans le format suivant : 4186518975.
									présente_nt						VARCHAR(15)	 	« présentent » si le souscripteur a plus d’une 
																							convention et « présente » s’il a une seule 
																							convention. En français seulement.
								@ReturnValue :
	                      	>0  : Tout à fonctionné
									<=0 : Erreur SQL
										-1 :  Pas de template d'entré ou en vigueur pour ce type de document
										-2 :  Pas de document(s) de généré(s)
Note                :	ADX0000800	IA	2006-02-01	Bruno Lapointe		Création
								ADX0001929	BR 2006-08-04	Bruno Lapointe		Fait un lien entre l'opération et le docuement.
												2008-05-12	Pierre-Luc Simard	Ajout du champ An_Mois_a_couvrir pour indiquer l'année du dernier des mois à couvrir.
												2008-09-25	Josée Parent		Ne pas produire de DataSet pour les documents commandés
												2018-09-07	Maxime Martel		JIRA MP-699 Ajout de OpertypeID COU
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_2ndPILetter] (
	@ConnectID INTEGER, -- ID de connexion de l’usager
	@ConventionID INTEGER, -- ID de la convention (0 si le paramètre @OperID doit être utilisé).
	@OperID INTEGER, -- ID de l’opération NSF
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = produire, 2 = produire et créer un historique dans la gestion des documents.
AS
BEGIN
	DECLARE 
		@dtToday DATETIME,
		@iDocTypeID INTEGER,
		@iNbre_mois_retard INTEGER,
		@dtDate_premier_PI DATETIME,
		@vcConventionNo VARCHAR(75),
		@fMontant_cheque MONEY,
		@bJustOneConv BIT

	SET @dtToday = GETDATE()

	-- Si on demande la lettre pour une convention, on va chercher le ID de la dernière opération NSF de cette convention
	IF @ConventionID > 0
		SELECT @OperID = MAX(O.OperID)
		FROM dbo.Un_Unit U
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN Mo_BankReturnLink BL ON BL.BankReturnCodeID = O.OperID AND BL.BankReturnTypeID = '901'
		JOIN Un_Oper OS ON OS.OperID = BL.BankReturnSourceCodeID -- Opération source du NSF
		-- S'assure qu'il y a bien 2 PI
		JOIN Un_Cotisation Ct2 ON Ct2.UnitID = U.UnitID
		JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID
		JOIN Mo_BankReturnLink BL2 ON BL2.BankReturnCodeID = O2.OperID AND BL2.BankReturnTypeID = '901'
		WHERE O2.OperDate BETWEEN DATEADD(MONTH,-1,OS.OperDate) AND O.OperDate
			AND O2.OperID <> O.OperID
			AND O.OperTypeID = 'NSF'
			AND U.ConventionID = @ConventionID

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

	-- Va chercher la date de la première premier PI
	SELECT @dtDate_premier_PI = MIN(O.OperDate)
	FROM Un_Oper O
	JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
	JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
	JOIN dbo.Un_Unit U2 ON U2.ConventionID = U.ConventionID
	JOIN Un_Cotisation Ct2 ON Ct2.UnitID = U2.UnitID
	JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID AND O2.OperID = @OperID
	JOIN Mo_BankReturnLink BL ON BL.BankReturnSourceCodeID = O.OperID AND BL.BankReturnTypeID = '901'
	JOIN (
		SELECT 
			U.ConventionID,
			OperDate = MAX(O.OperDate)
		FROM Un_Oper O
		JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		JOIN dbo.Un_Unit U2 ON U2.ConventionID = U.ConventionID
		JOIN Un_Cotisation Ct2 ON Ct2.UnitID = U2.UnitID
		JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID AND O2.OperID = @OperID
		LEFT JOIN Mo_BankReturnLink BL ON BL.BankReturnSourceCodeID = O.OperID AND BL.BankReturnTypeID = '901'
		WHERE O.OperDate < O2.OperDate
			AND BL.BankReturnCodeID IS NULL
			AND O.OperTypeID IN ('CPA', 'CHQ', 'PRD', 'COU')
		GROUP BY U.ConventionID
		) V ON V.ConventionID = U.ConventionID AND O.OperDate > V.OperDate

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

	-- Va chercher le nombre de dépôt en retard.
	SELECT @iNbre_mois_retard = 
		MAX(
			CASE 
				WHEN iNbDepTheo-iNbDepReel < 0 THEN 0
			ELSE iNbDepTheo-iNbDepReel
			END
			)
	FROM (
		SELECT 
			U.UnitID,
			iNbDepTheo = 
				CASE 
					WHEN U.UnitQty <> 0 THEN
						dbo.fn_Un_EstimatedNumberOfDepositSinceBeginning(O.OperDate,DAY(C.FirstPmtDate), M.PmtByYearID, M.PmtQty, U.InForceDate)
				ELSE 0
				END,
			iNbDepReel = 
				CASE 
					WHEN U.UnitQty <> 0 THEN
						SUM(Ct2.Cotisation+Ct2.Fee) / ROUND(M.PmtRate * U.UnitQty,2)
				ELSE 0
				END
		FROM Un_Oper O 
		JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID
		JOIN Un_Cotisation Ct2 ON Ct2.UnitID = U.UnitID
		JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID AND O2.OperDate <= O.OperDate
		WHERE O.OperID = @OperID
		GROUP BY
			U.UnitID,
			O.OperDate,
			C.FirstPmtDate,
			M.PmtByYearID,
			M.PmtQty,
			U.InForceDate,
			M.PmtRate,
			U.UnitQty
		) V

	-- Table temporaire qui contient le certificat
	CREATE TABLE #t2ndPILetter(
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
		No_convention VARCHAR(75), -- Numéro de la plus vieille convention du dépôt qui a été retourné.
		Date_prelevement VARCHAR(25), -- Date d’opération du dépôt retourné dans le format suivant : 12 décembre 2005 ou December 12, 2005.
		Nbre_mois_retard INTEGER, -- Nombre de mois de retard en chiffre.
		Montant_cheque VARCHAR(75), -- Montant du dépôt qui a été retourné, multiplié par trois (pour couvrir les deux mois de retard et le mois suivant).
		Mois_a_couvrir VARCHAR(75), -- Le nom en lettre du mois de la date d’opération du dépôt qui a été retourné ainsi que du mois qui le précédait et du mois prochain selon la langue du souscripteur. (Ex : juillet, août et septembre / July, August and September).
		An_Mois_a_couvrir VARCHAR(4), -- L'année du dernier mois à couvrir.
		Date_premier_PI VARCHAR(25), -- Plus petite date d’opération des effets retournés.  (Ex : prélèvement 1 le 20 juillet retourné le 23 juillet et prélèvement 2 le 20 août retourné le 24 août. Il sera affiché la date du prélèvement 1 soit le 20 juillet).
		Date_reponse VARCHAR(25), -- Date d’opération du dépôt, qui a été retourné, additionnée d’un mois.
		Nom_representant VARCHAR(87), -- Prénom et nom du représentant du souscripteur. (Ex : Francine Adam)
		Vos_Votre_Convention_Maj VARCHAR(20), -- « Vos conventions » s’il y a plus d’une convention et « Votre convention » s’il n’y en n’a qu’une. Le premier « V » sera en majuscule.
		vos_votre_convention_min VARCHAR(20), -- « vos conventions » s’il y a plus d’une convention et « votre convention » s’il n’y en n’a qu’une. Le premier « v » sera en minuscule.
		agreement_s VARCHAR(15), -- « agreements » s’il y a plus d’une convention et « agreement » s’il n’y en n’a qu’une. Le « a » sera en minuscule.
		is_are VARCHAR(5), -- « are » s’il y a plus d’une convention et « is » s’il n’y en n’a qu’une. La première lettre du mot sera en minuscule.
		Tel_Souscripteur VARCHAR(30), -- Numéro de téléphone à la maison du souscripteur dans le format suivant : 4186518975.
		présente_nt VARCHAR(15), -- « présentent » si le souscripteur a plus d’une convention et « présente » s’il a une seule convention. En français seulement.
		NomDestinataire VARCHAR(50),
		PrenomDestinataire VARCHAR(35)
	)

	-- Va chercher le bon type de document
	SELECT 
		@iDocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = '2ndPILetter'

	-- Remplis la table temporaire
	INSERT INTO #t2ndPILetter
		SELECT DISTINCT
			T.DocTemplateID,
			HS.LangID,
			Date = dbo.fn_Mo_DateToLongDateStr(@dtToday, HS.LangID), -- Ce sera la date à laquelle la lettre aura été commandée dans le format suivant : « 12 décembre 2005 » ou « December 12, 2005 » selon la langue du souscripteur.
			Appel1 = SxS.LongSexName, -- « Monsieur », « Madame », « Madam » ou « Sir » selon le sexe et la langue du souscripteur.
			Appel2 = A2.ShortSexName, -- « Mr », « Mrs » selon le sexe et la langue anglaise du souscripteur.  
			Destinataire = HS.FirstName + ' ' + HS.LastName, -- Prénom et nom du souscripteur à qui on envoie l’accusé réception. (Ex : Éric Ranger)
			Adresse = AdS.Address, -- Numéro civique, rue et numéro d’appartement du souscripteur.
			Ville = AdS.City, -- Ville du souscripteur.
			Province = AdS.Statename, -- Province du souscripteur.
			Code_Postal = dbo.fn_Mo_FormatZIP(AdS.ZipCode, AdS.CountryID), -- Code postal du souscripteur.
			No_convention = @vcConventionNo, -- Numéro de la plus vieille convention du dépôt qui a été retourné.
			Date_prelevement = dbo.fn_Mo_DateToLongDateStr(O.OperDate, HS.LangID), -- Date d’opération du dépôt retourné dans le format suivant : 12 décembre 2005 ou December 12, 2005.
			Nbre_mois_retard = @iNbre_mois_retard, -- Nombre de mois de retard en chiffre.
			Montant_cheque = dbo.fn_Mo_MoneyToStr(@fMontant_cheque*3, HS.LangID, 1), -- Montant du dépôt qui a été retourné, multiplié par trois (pour couvrir les deux mois de retard et le mois suivant).
			Mois_a_couvrir = 
				dbo.fn_Mo_TranslateMonthToStr(DATEADD(MONTH, -1, O.OperDate), HS.LangID)+', '+
				dbo.fn_Mo_TranslateMonthToStr(O.OperDate, HS.LangID)+
				CASE 
					WHEN HS.LangID = 'FRA' THEN ' et '
				ELSE ' and '
				END+
				dbo.fn_Mo_TranslateMonthToStr(DATEADD(MONTH, 1, O.OperDate), HS.LangID), -- Le nom en lettre du mois de la date d’opération du dépôt qui a été retourné ainsi que du mois qui le précédait et du mois prochain selon la langue du souscripteur. (Ex : juillet, août et septembre / July, August and September).
			An_Mois_a_couvrir = CAST(YEAR(DATEADD(MONTH, 1, O.OperDate)) AS VARCHAR(4)), -- L'année du dernier mois à couvrir.
			Date_premier_PI = dbo.fn_Mo_DateToLongDateStr(@dtDate_premier_PI, HS.LangID), -- Plus petite date d’opération des effets retournés.  (Ex : prélèvement 1 le 20 juillet retourné le 23 juillet et prélèvement 2 le 20 août retourné le 24 août. Il sera affiché la date du prélèvement 1 soit le 20 juillet).
			Date_reponse = dbo.fn_Mo_DateToLongDateStr(DATEADD(MONTH, 1, O.OperDate), HS.LangID), -- Date d’opération du dépôt, qui a été retourné, additionnée d’un mois.
			Nom_representant = HR.FirstName + ' ' + HR.LastName, -- Prénom et nom du représentant du souscripteur. (Ex : Francine Adam)
			Vos_Votre_Convention_Maj =
				CASE 
					WHEN @bJustOneConv = 1 THEN 'Votre convention'
				ELSE 'Vos conventions'
				END, -- « Vos conventions » s’il y a plus d’une convention et « Votre convention » s’il n’y en n’a qu’une. Le premier « V » sera en majuscule.
			vos_votre_convention_min =
				CASE 
					WHEN @bJustOneConv = 1 THEN 'votre convention'
				ELSE 'vos conventions'
				END, -- « vos conventions » s’il y a plus d’une convention et « votre convention » s’il n’y en n’a qu’une. Le premier « v » sera en minuscule.
			agreement_s =
				CASE 
					WHEN @bJustOneConv = 1 THEN 'agreement'
				ELSE 'agreements'
				END, -- « agreements » s’il y a plus d’une convention et « agreement » s’il n’y en n’a qu’une. Le « a » sera en minuscule.
			is_are =
				CASE 
					WHEN @bJustOneConv = 1 THEN 'is'
				ELSE 'are'
				END, -- « are » s’il y a plus d’une convention et « is » s’il n’y en n’a qu’une. La première lettre du mot sera en minuscule.
			Tel_Souscripteur = AdS.Phone1, -- Numéro de téléphone à la maison du souscripteur dans le format suivant : 4186518975.
			présente_nt =
				CASE 
					WHEN @bJustOneConv = 1 THEN 'présente'
				ELSE 'présentent'
				END, -- « présentent » si le souscripteur a plus d’une convention et « présente » s’il a une seule convention. En français seulement.
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
				ISNULL(Date_prelevement,'')+';'+
				ISNULL(CAST(Nbre_mois_retard AS VARCHAR(10)),'')+';'+
				ISNULL(Montant_cheque,'')+';'+
				ISNULL(Mois_a_couvrir,'')+';'+
				ISNULL(An_Mois_a_couvrir,'')+';'+
				ISNULL(Date_premier_PI,'')+';'+
				ISNULL(Date_reponse,'')+';'+
				ISNULL(Nom_representant,'')+';'+
				ISNULL(Vos_Votre_Convention_Maj,'')+';'+
				ISNULL(vos_votre_convention_min,'')+';'+
				ISNULL(agreement_s,'')+';'+
				ISNULL(is_are,'')+';'+
				ISNULL(Tel_Souscripteur,'')+';'+
				ISNULL(présente_nt,'')+';'
			FROM #t2ndPILetter

		-- Fait un lien entre le document et la convention pour que retrouve le document 
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
			No_convention, -- Numéro de la plus vieille convention du dépôt qui a été retourné.
			Date_prelevement, -- Date d’opération du dépôt retourné dans le format suivant : 12 décembre 2005 ou December 12, 2005.
			Nbre_mois_retard, -- Nombre de mois de retard en chiffre.
			Montant_cheque, -- Montant du dépôt qui a été retourné, multiplié par trois (pour couvrir les deux mois de retard et le mois suivant).
			Mois_a_couvrir, -- Le nom en lettre du mois de la date d’opération du dépôt qui a été retourné ainsi que du mois qui le précédait et du mois prochain selon la langue du souscripteur. (Ex : juillet, août et septembre / July, August and September).
			An_Mois_a_couvrir, -- L'année du dernier mois à couvrir
			Date_premier_PI, -- Plus petite date d’opération des effets retournés.  (Ex : prélèvement 1 le 20 juillet retourné le 23 juillet et prélèvement 2 le 20 août retourné le 24 août. Il sera affiché la date du prélèvement 1 soit le 20 juillet).
			Date_reponse, -- Date d’opération du dépôt, qui a été retourné, additionnée d’un mois.
			Nom_representant, -- Prénom et nom du représentant du souscripteur. (Ex : Francine Adam)
			Vos_Votre_Convention_Maj, -- « Vos conventions » s’il y a plus d’une convention et « Votre convention » s’il n’y en n’a qu’une. Le premier « V » sera en majuscule.
			vos_votre_convention_min, -- « vos conventions » s’il y a plus d’une convention et « votre convention » s’il n’y en n’a qu’une. Le premier « v » sera en minuscule.
			agreement_s, -- « agreements » s’il y a plus d’une convention et « agreement » s’il n’y en n’a qu’une. Le « a » sera en minuscule.
			is_are, -- « are » s’il y a plus d’une convention et « is » s’il n’y en n’a qu’une. La première lettre du mot sera en minuscule.
			Tel_Souscripteur, -- Numéro de téléphone à la maison du souscripteur dans le format suivant : 4186518975.
			présente_nt -- « présentent » si le souscripteur a plus d’une convention et « présente » s’il a une seule convention. En français seulement.
		FROM #t2ndPILetter 
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
			FROM #t2ndPILetter)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	DROP TABLE #t2ndPILetter
END