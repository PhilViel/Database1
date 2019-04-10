/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc
Nom                 :	SP_RP_UN_Certificat
Description         :	Document : Certificats bénéficiaire.
Valeurs de retours  :	
Note                :	
					2004-05-21	Bruno Lapointe	Création 
ADX0000915	BR	2004-08-19	Bruno Lapointe	Ajout d'un champ TextDiplome pour contourner le fait que le développement
														des blobs dans les blobs de document ne sont pas encore géré par le 
														module.
ADX00001315	IA	2007-03-13	Bruno Lapointe		Création
				2008-07-17	Pierre-Luc Simard	Modification pour ne plus retourner de dataset inutilement 
												si le document n'est pas généré immédiatement
				2015-07-29	Steve Picard		Utilisation du "Un_Convention.TexteDiplome" au lieu de la table UN_DiplomaText
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_RP_UN_Certificat] (
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
		BenefFirstName VARCHAR(35),
		BenefLastName VARCHAR(50),
		SubsFirstName VARCHAR(35),
		SubsLastName VARCHAR(50),
		DateDay VARCHAR(25),
		DateLongMonth VARCHAR(25),
		DateYear INTEGER,
		DiplomaTableName VARCHAR(7),
		DiplomaFieldName VARCHAR(8),
		DiplomaWhereClose VARCHAR(100),
		DiplomaMEMO VARCHAR(11),
		DiplomaText VARCHAR(150),
		ConventionNO VARCHAR(75)
	)

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'CertificatBnf'

	-- Remplis la table temporaire
	INSERT INTO #Certificat
		SELECT 
			T.DocTemplateID,
			HB.LangID,
			BenefFirstName = HB.FirstName,
			BenefLastName = HB.LastName,
			SubsFirstName = HS.FirstName,
			SubsLastName = HS.LastName,
			DateDay = dbo.fn_Mo_DateToCompleteDayStr(MIN(U.InForceDate), HB.LangID),
			DateLongMonth = dbo.fn_Mo_TranslateMonthToStr(MIN(U.InForceDate), HB.LangID),
			DateYear = YEAR(MIN(U.InForceDate)),
			DiplomaTableName = 'Mo_Note',
			DiplomaFieldName = 'NoteText', 
			DiplomaWhereClose = 'WHERE (Mo_Note.NoteTypeID = ' + CAST(IsNULL(N.NoteTypeID,0) AS VARCHAR(20)) + ') AND (Mo_Note.NoteCodeID = ' + CAST(C.ConventionID AS VARCHAR(20))+ ')', 
			DiplomaMEMO = 'DiplomaMEMO',
			DiplomaText = ISNULL(C.TexteDiplome,''),   -- 2015-07-29
			C.ConventionNO
		FROM dbo.Un_Convention C
		JOIN dbo.mo_Human HB ON HB.HumanID = C.BeneficiaryID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
		--LEFT JOIN Un_DiplomaText DT ON DT.DiplomaTextID = C.DiplomaTextID  -- 2015-07-29
		LEFT JOIN Mo_Note N ON N.NoteCodeID = C.ConventionID AND N.NoteTypeID = 1
		JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
			SELECT 
				LangID,
				DocTypeID,
				DocTemplateTime = MAX(DocTemplateTime)
			FROM CRQ_DocTemplate
			WHERE (DocTypeID = @DocTypeID)
			  AND (DocTemplateTime < @Today)
			GROUP BY LangID, DocTypeID
			) V ON (V.LangID = HB.LangID)
		JOIN CRQ_DocTemplate T ON (V.DocTypeID = T.DocTypeID) AND (V.DocTemplateTime = T.DocTemplateTime) AND (T.LangID = HB.LangID)
		WHERE (C.ConventionID = @ConventionID)
		GROUP BY 
			T.DocTemplateID,
			HB.FirstName, 
			HB.LastName, 
			HS.FirstName, 
			HS.LastName, 
			HB.LangID, 
			CAST(N.NoteText AS VARCHAR(5000)),
			C.TexteDiplome,
			N.NoteTypeID, 
			C.ConventionID, 
			C.ConventionNO

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
				ISNULL(BenefLastName,'')+', '+ISNULL(BenefFirstName,''),
				ISNULL(SubsLastName,'')+', '+ISNULL(SubsFirstName,''),
				ISNULL(LangID,'')+';'+
				ISNULL(BenefFirstName,'')+';'+
				ISNULL(BenefLastName,'')+';'+
				ISNULL(DateDay,'')+';'+
				ISNULL(DateLongMonth,'')+';'+
				ISNULL(CAST(DateYear AS VARCHAR),'')+';'+
				ISNULL(DiplomaTableName,'')+';'+
				ISNULL(DiplomaFieldName,'')+';'+
				ISNULL(DiplomaWhereClose,'')+';'+
				ISNULL(DiplomaMEMO,'')+';'+
				ISNULL(DiplomaText,'')+';'+
				ISNULL(ConventionNO,'')+';'
			FROM #Certificat

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
			BenefFirstName,
			BenefLastName,
			DateDay,
			DateLongMonth,
			DateYear,
			DiplomaTableName,
			DiplomaFieldName,
			DiplomaWhereClose,
			DiplomaMEMO,
			DiplomaText,
			ConventionNO
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
		RETURN -2 -- Pas de document de généré
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	-- RETURN VALUE
	---------------
	-- >0  : Tout ok
	-- <=0 : Erreurs
	-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
	-- 	-2 : Pas de document de généré

	DROP TABLE #Certificat;
END


