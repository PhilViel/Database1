/****************************************************************************************************
  Description : Rapport de fusion word des certificats d'assurances
 ******************************************************************************
  2004-05-25 Bruno Lapointe		Création 
  2008-07-17 Pierre-Luc Simard	Modification pour ne plus retourner de dataset inutilement si le document n'est pas généré immédiatement
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_RP_UN_CertificatAssuranceVie] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@ConventionID INTEGER, -- ID de la convention  
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN

	DECLARE 
		@Today DATETIME,
		@DocTypeID INTEGER

	SET @Today = GetDate()	

	-- Table temporaire qui contient le certificat
	CREATE TABLE #Certificat(
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		SubscriberFirstName VARCHAR(35),
		SubscriberLastName VARCHAR(50),
		ConventionNo VARCHAR(75),
		InForceDate VARCHAR(75)
	)

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'CertificatSubInsur'

	-- Remplis la table temporaire
	INSERT INTO #Certificat
		SELECT
			T.DocTemplateID,
			HS.LangID,
			SubscriberFirstName = HS.FirstName,
			SubscriberLastName = HS.LastName,
			C.ConventionNo,
			InForceDate = dbo.fn_Mo_DateToLongDateStr (MIN(U.InForceDate), HS.LangID)
		FROM dbo.Un_Convention C
		JOIN dbo.Mo_Human HS ON (HS.HumanID = C.SubscriberID)
		JOIN dbo.Un_Unit U ON (U.ConventionID = C.ConventionID)
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
		GROUP BY 
			T.DocTemplateID,
			HS.LangID, 
			HS.FirstName, 
			HS.LastName, 
			C.ConventionNo

	-- Gestion des documents
	IF @DocAction IN (0,2)
	BEGIN

		-- Crée le document dans la gestion des documents
		INSERT INTO CRQ_Doc (DocTemplateID, DocOrderConnectID, DocOrderTime, DocGroup1, DocGroup2, DocGroup3, Doc)
			SELECT 
				DocTemplateID,
				@ConnectID,
				@Today,
				ISNULL(ConventionNO,''),
				ISNULL(SubscriberLastName,'')+', '+ISNULL(SubscriberFirstName,''),
				ISNULL(InForceDate,''),
				ISNULL(LangID,'')+';'+
				ISNULL(SubscriberFirstName,'')+';'+
				ISNULL(SubscriberLastName,'')+';'+
				ISNULL(InForceDate,'')+';'+
				ISNULL(ConventionNO,'')+';'
			FROM #Certificat C

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
	
	-- Produit un dataset pour la fusion
	IF @DocAction <> 0
		SELECT 
			DocTemplateID,
			LangID,
			SubscriberFirstName,
			SubscriberLastName,
			ConventionNo,
			InForceDate
		FROM #Certificat 
		WHERE @DocAction IN (1,2)

	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM CRQ_DocTemplate
			WHERE (DocTypeID = @DocTypeID)
			  AND (DocTemplateTime < @Today))
		RETURN -1 -- Pas de template d'entré ou en vigueur pour ce type de document
	IF NOT EXISTS (
			SELECT 
				ConventionNO
			FROM #Certificat)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	-- RETURN VALUE
	---------------
	-- >0  : Tout ok
	-- <=0 : Erreurs
	-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
	-- 	-2 : Pas de document(s) de généré(s)

	DROP TABLE #Certificat;
END


