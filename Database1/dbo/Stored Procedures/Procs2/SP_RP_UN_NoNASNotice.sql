
/****************************************************************************************************
Code de service		:		SP_RP_UN_NoNASNotice
Nom du service		:		
But					:		Rapport de fusion word 'Avis REE sans NAS avec formulaire'
Description			:		Ce service permet la génération de la lettre 'Avis REE sans NAS avec formulaire'.  Selon les paramètres
							ce service peut créer un rapport en attente dans la queue d'impression, retourner un dataset de données afin 
							de fusionner le document immédiatement ou faire les 2.

Facette				:		CONV
Reférence			:		Document P171U - À COMPLÉTER!

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iID_Connect				Identifiant unique de la connexion
						@iID_Convention				Identifiant unique de la convention
						@DocAction					ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents

Exemple d'appel:
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
						S/O							>0  : Tout ok
													<=0 : Erreurs
													-1 : Pas de template d'entré ou en vigueur pour ce type de document
													-2 : Pas de document(s) de généré(s)                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2004-05-26					Bruno Lapointe          Création 
						2008-09-25					Josée Parent            Ne pas produire de DataSet pour les documents commandés
						2010-03-10					Pierre Paquet			Ajustement de la procédure.
						2010-11-15					Pierre Paquet			Correction: Utilisation du SansNAS.
						2012-09-28					Donald Huppé			glpi 7338 : modif de DateLimiteEnvoi
						2015-02-25					Donald Huppé			glpi 13596 : Ajout de SubscriberID
						2018-08-15					Donald Huppé			changer le délai de 12 à 24 pour DateLimiteEnvoi
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[SP_RP_UN_NoNASNotice] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@ConventionID INTEGER, -- ID de la convention  
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN
	DECLARE 
		@Today DATETIME,
		@DocTypeID INTEGER,
		@UserName VARCHAR(77),
		@NAS VARCHAR(75),
		@Formulaire INT

	SET @Today = GetDate()	

	-- Table temporaire qui contient le certificat
	CREATE TABLE #Notice(
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		ConventionNo VARCHAR(75), 
		FirstName VARCHAR(35), 
		LastName VARCHAR(50),
		Address VARCHAR(75),
		City VARCHAR(100),
		StateName VARCHAR(75),
		ZipCode VARCHAR(75),
		LongSexName VARCHAR(75),
		ShortSexName VARCHAR(75),
		LetterMedDate VARCHAR(75),
--		InForceDay INTEGER,
--		InForceMonth VARCHAR(75),
--		InForceYear INTEGER,
--		LimiteDay INTEGER,
--		LimiteMonth VARCHAR(75),
--		LimiteYear INTEGER,
--		LimiteUpperMonth VARCHAR(75),
--		FRA_Determ VARCHAR(75),
		PrenomBeneficiaire VARCHAR (75),
		NomBeneficiaire VARCHAR (75),
		DateLimiteEnvoi VARCHAR(75),
		FRAInforme VARCHAR(75),
		UserName VARCHAR(77),
		SubscriberID INT
	)

	SELECT @NAS = H.SocialNumber, @Formulaire = C.bFormulaireRecu
	FROM dbo.Un_Convention C
	LEFT JOIN dbo.Mo_Human H ON C.BeneficiaryID = H.HumanID
	WHERE ConventionID = @ConventionID

/*
	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'NoNASNotice'
*/

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	--WHERE (DocTypeCode = 'NoNASNotice' AND (@NAS IS NULL or @NAS = '') AND @Formulaire = 1)
	WHERE (DocTypeCode = 'NoNASNotice' AND (@NAS IS NULL or @NAS = '') AND @Formulaire = 1)
		OR (DocTypeCode = 'SansNASSansForm' AND (@NAS IS NULL or @NAS = '') AND @Formulaire = 0)
		OR (DocTypeCode = 'AvecNASSansForm' AND (@NAS IS NOT NULL or @NAS <> '') AND @Formulaire = 0)
		
	SELECT 
		@UserName = HU.FirstName + ' ' + HU.LastName
	FROM Mo_Connect CO
	JOIN Mo_User U ON (CO.UserID = U.UserID)
	JOIN dbo.Mo_Human HU ON (HU.HumanID = U.UserID)
	WHERE (Co.ConnectID = @ConnectID)

	-- Remplis la table temporaire
	INSERT INTO #Notice
		SELECT 
			T.DocTemplateID,
			HS.LangID,
			C.ConventionNO, 
			HS.FirstName, 
			HS.LastName,
			HA.Address,
			HA.City,
			HA.StateName,
			ZipCode = dbo.fn_Mo_FormatZIP(HA.ZipCode,HA.CountryID),
			S.LongSexName,
			S.ShortSexName,
			LetterMedDate = dbo.fn_Mo_DateToLongDateStr (GetDate(), HS.LangID),
	--		InForceDay = DAY( U.InForceDate),
	--		InForceMonth = dbo.fn_Mo_TranslateMonthToStr(U.InForceDate, HS.LangID),
	--		InForceYear = YEAR(U.InForceDate),
	--		LimiteDay = DAY(U.InForceDate),
	--		LimiteMonth = dbo.fn_Mo_TranslateMonthToStr( U.InForceDate, HS.LangID),
	--		LimiteYear = YEAR(U.InForceDate) + 1,
	--		LimiteUpperMonth = UPPER(dbo.fn_Mo_TranslateMonthToStr( U.InForceDate, HS.LangID)),
	--		FRA_Determ = 
	--			CASE HS.LangID
	--				WHEN 'FRA' THEN 
	--					CASE 
	--						WHEN Month(U.InForceDate) IN (4,8,10) THEN 'd'''
	--					ELSE 'de'
	--					END
	--				ELSE ''
	--			END,
			B.FirstName,
			B.LastName,
			DateLimiteEnvoi = dbo.fn_Mo_DateToLongDateStr (DATEADD(month, 24, dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID)), HS.LangID),
			FRAInforme =
					CASE HS.SexID
							WHEN 'F' THEN 'informée'
							WHEN 'M' THEN 'informé'
					ELSE '???'
				END,

			UserName = @UserName,
			c.SubscriberID
		FROM dbo.Un_Convention C
		JOIN dbo.Mo_Human HS ON (HS.HumanID = C.SubscriberID)
		JOIN dbo.Mo_Human B ON (B.HumanID = C.BeneficiaryID)
		JOIN Mo_Sex S ON (HS.LangID = S.LangID) AND (HS.SexID = S.SexID)
		JOIN dbo.Mo_Adr HA ON (HA.AdrID = HS.AdrID)
		JOIN (
			SELECT 
				U1.ConventionID,
				UnitID = MIN(U1.UnitID), 
				U1.InforceDate 
			FROM dbo.Un_Unit U1 
			WHERE (U1.ConventionID = @ConventionID) 
			GROUP BY U1.ConventionID, U1.InForceDate 
			) U ON (U.ConventionID = C.ConventionID) 
		JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
			SELECT 
				LangID,
				DocTypeID,
				DocTemplateTime = MAX(DocTemplateTime)
			FROM CRQ_DocTemplate
			WHERE (DocTypeID = @DocTypeID)
			  AND (DocTemplateTime < @Today)
			GROUP BY LangID, DocTypeID
			) V ON (V.LangID = HS.LangID)
		JOIN CRQ_DocTemplate T ON (V.DocTypeID = T.DocTypeID) AND (V.DocTemplateTime = T.DocTemplateTime) AND (T.LangID = HS.LangID)
		WHERE (C.ConventionID = @ConventionID)

	-- Gestion des documents
	IF @DocAction IN (0,2)
	BEGIN

		-- Crée le document dans la gestion des documents
		INSERT INTO CRQ_Doc (DocTemplateID, DocOrderConnectID, DocOrderTime, DocGroup1, DocGroup2, DocGroup3, Doc)
			SELECT 
				DocTemplateID,
				@ConnectID,
				@Today,
				ISNULL(ConventionNo,''),
				ISNULL(LastName,'')+', '+ISNULL(FirstName,''),
				'',
				ISNULL(LangID,'')+';'+
				ISNULL(ConventionNo,'')+';'+
				ISNULL(FirstName,'')+';'+
				ISNULL(LastName,'')+';'+
				ISNULL(Address,'')+';'+
				ISNULL(City,'')+';'+
				ISNULL(StateName,'')+';'+
				ISNULL(ZipCode,'')+';'+
				ISNULL(LongSexName,'')+';'+
				ISNULL(ShortSexName,'')+';'+
				ISNULL(LetterMedDate,'')+';'+
		--		ISNULL(CAST(InForceDay AS VARCHAR),'')+';'+
		--		ISNULL(InForceMonth,'')+';'+
		--		ISNULL(CAST(InForceYear AS VARCHAR),'')+';'+
		--		ISNULL(CAST(LimiteDay AS VARCHAR),'')+';'+
		--		ISNULL(LimiteMonth,'')+';'+
		--		ISNULL(CAST(LimiteYear AS VARCHAR),'')+';'+
		--		ISNULL(LimiteUpperMonth,'')+';'+
		--		ISNULL(FRA_Determ,'')+';'+
				ISNULL(PrenomBeneficiaire,'')+';'+
				ISNULL(NomBeneficiaire,'')+';'+
				ISNULL(CAST(DateLimiteEnvoi AS VARCHAR),'')+';'+
				ISNULL(FRAInforme, '')+';'+
				ISNULL(UserName,'')+';'+
				ISNULL(CAST(SubscriberID AS VARCHAR),'')+';'
			FROM #Notice

		-- Fait un lient entre le document et la convention pour que retrouve le document 
		-- dans l'historique des documents de la convention
		INSERT INTO CRQ_DocLink 
			SELECT
				C.ConventionID,
				1,
				D.DocID
			FROM CRQ_Doc D 
			JOIN CRQ_DocTemplate T ON (T.DocTemplateID = D.DocTemplateID)
			JOIN dbo.Un_Convention C ON (C.ConventionNo = D.DocGroup1)
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
				JOIN CRQ_DocTemplate T ON (T.DocTemplateID = D.DocTemplateID)
				LEFT JOIN CRQ_DocPrinted P ON P.DocID = D.DocID AND P.DocPrintConnectID = @ConnectID AND P.DocPrintTime = @Today
				WHERE P.DocID IS NULL
				  AND T.DocTypeID = @DocTypeID
				  AND D.DocOrderTime = @Today
				  AND D.DocOrderConnectID = @ConnectID					
	END

	IF @DocAction <> 0
	BEGIN
		-- Produit un dataset pour la fusion
		SELECT 
			DocTemplateID,
			LangID,
			ConventionNo, 
			FirstName, 
			LastName,
			Address,
			City,
			StateName,
			ZipCode,
			LongSexName,
			ShortSexName,
			LetterMedDate,
	--		InForceDay,
	--		InForceMonth,
	--		InForceYear,
	--		LimiteDay,
	--		LimiteMonth,
	---		LimiteYear,
	--		LimiteUpperMonth,
	--		FRA_Determ,
			PrenomBeneficiaire,
			NomBeneficiaire,
			DateLimiteEnvoi,
			FRAInforme,
			UserName,
			SubscriberID
		FROM #Notice 
		WHERE @DocAction IN (1,2)
	END

	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM CRQ_DocTemplate
			WHERE (DocTypeID = @DocTypeID)
			  AND (DocTemplateTime < @Today))
		RETURN -1 -- Pas de template d'entré ou en vigueur pour ce type de document
	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM #Notice)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	-- RETURN VALUE
	---------------
	-- >0  : Tout ok
	-- <=0 : Erreurs
	-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
	-- 	-2 : Pas de document(s) de généré(s)

	DROP TABLE #Notice;
END;


