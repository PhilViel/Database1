/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CESP400And511Tool
Description         :	Renvoi les données pour l’outil de traitement des erreurs sur 400 et 511.
Valeurs de retours  :	Dataset :
				iCESP800ID		    INTEGER		    ID unique de l’erreur.
				iCESP400ID		    INTEGER		    ID de l’enregistrement 400 en erreur.
				bModified		    BIT		        Indique quand le bénéficiaire ou le souscripteur selon le cas aura été modifié sur une des données envoyées au PCEE depuis l’envoi de l’enregistrement 200 revenus en erreur.
				bError100Or200	    BIT		        Indique si l’erreur est causé par un erreur sur l’enregistrement 100 ou 200 (0= Non, 1= Oui)	
				dtRead			    DATETIME	    Date de réception du fichier d’erreur.
				vcTransID		    VARCHAR(15)	    ID PCEE
				ConventionID	    INTEGER		    ID de la convention
				ConventionNo	    VARCHAR(75)	    Numéro de convention.
				SubscriberID	    INTEGER		    ID du souscripteur
				BeneficiaryID	    INTEGER		    ID du bénéficiaire
				UnitID			    INTEGER		    ID du groupe d’unités
				InForceDate		    DATETIME	    Date d’entré en vigueur du groupe d’unités
				UnitQty			    MONEY		    Nombre d’unités
				EffectDate		    DATETIME	    Date envoyé au PCEE pour la transaction. Correspond à la date effective. Dans le cas d’une opération sur la convention qui n’affecte pas un groupe d’unités (ex : PAE) elle correspondra à la date d’opération.
				OperType		    CHAR(3)		    Type d’opération
				ConventionStateName	VARCHAR(75)	    État actuel de la convention
				vcErrFieldName		VARCHAR(30)	    Champ en erreur
				siCESP800ErrorID	INTEGER		    Code de l’erreur
				vcCESP800Error		VARCHAR(200)	Description de l’erreur

Note                :	ADX0001153	IA	2006-11-10	Alain Quirion			Création
                    :                   2008-10-20  Fatiha Araar			Ajouter les traitement des erreurs pour les 
																			enregistrements 511  
                                        2009-01-05  Fatiha Araar			Correction(Afficher les informations de UnitID ,InForceDate et UnitQty )          
										2009-02-06  Patrick Robitaille		Rendre fonctionnel le champ bModified du côté des 511
										2009-02-06  Patrick Robitaille		Ne pas retourner les infos des groupes d'unités dans les 511
																			Elles ne sont pas utiles et font en sorte d'afficher des doublons dans l'outil.
										2010-04-14	Jean-François Gauthier	Correction pour d'ajouter le lien sur le ConventionID 
																			dans le LEFT JOIN sur UN_CESP400															
										2010-08-26	Pierre Paquet			Correction pour afficher les conventions 'fermées' MAIS avec une trx de désactivation BEC en erreur.
										2012-04-17	Donald Huppé			Glpi 7389 : afficher les convention T en erreur mais fermée
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESP400And511Tool](
	@iCESP800ID INTEGER = 0)
AS
BEGIN
	CREATE TABLE #tConvention(
		ConventionID INTEGER,
		tiCESP400TypeID INTEGER,
		bCESPDemand INTEGER)

	INSERT INTO #tConvention
	SELECT DISTINCT
		C4.ConventionID,
		C4.tiCESP400TypeID,
		C4.bCESPDemand
	FROM Un_CESP800ToTreat C8T
	JOIN Un_CESP400 C4 ON C4.iCESP800ID = C8T.iCESP800ID
   --Ajouter les conventions de la 511
    UNION ALL
    SELECT DISTINCT
		C5.ConventionID,
		NULL,
		NULL
	FROM Un_CESP800ToTreat C8T
	JOIN Un_CESP511 C5 ON C5.iCESP800ID = C8T.iCESP800ID

	CREATE INDEX PK_tConvention
	ON #tConvention (ConventionID)

	-- Insère les états de convention
	CREATE TABLE #tConventionState(
		ConventionID INTEGER PRIMARY KEY,
		ConventionStateName VARCHAR(20))

	INSERT INTO #tConventionState
		SELECT 
				C.ConventionID,
				CSt.ConventionStateName
		FROM dbo.Un_Convention C
		JOIN (
				SELECT
						C.ConventionID,
						ConventionConventionStateID = MAX(ConventionConventionStateID)
				FROM #tConvention tC			
				JOIN dbo.Un_Convention C ON C.ConventionID = tC.ConventionID
				JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = C.ConventionID
				GROUP BY C.ConventionID) CCS1 ON CCS1.COnventionID = C.ConventionID
		JOIN Un_ConventionConventionState CCS2 ON CCS1.ConventionConventionStateID = CCS2.ConventionConventionStateID
		JOIN Un_ConventionState CSt ON CSt.ConventionStateID = CCS2.ConventionStateID	
		WHERE CCS2.ConventionStateID <> 'FRM'
				OR (CCS2.ConventionStateID = 'FRM' 
					AND (C.ConventionID IN ( SELECT ConventionID FROM #tConvention tCONV
											 WHERE tCONV.tiCESP400TypeID = 24 
											AND tCONV.bCESPDemand = 0
										   )
						-- glpi 7389			   
						or	C.ConventionID IN (SELECT ConventionID FROM dbo.Un_Convention where ConventionNo LIKE 'T%')
										   
						)
					)

	-- Table pour les erreurs sur les 100
	CREATE TABLE #tCESP100ReceiveFile(
		iCESP800ID INTEGER,
		iCESPReceiveFileID INTEGER,
		ConventionID INTEGER
	)

	-- Table pour les erreurs sur les 200
	CREATE TABLE #tCESP200ReceiveFile (
		iCESP800ID INTEGER,
		iCESPReceiveFileID INTEGER,
		ConventionID INTEGER,
		bModified BIT
	)

	-- Insertion des erreurs sur les 100
	INSERT INTO #tCESP100ReceiveFile
	SELECT 
		C8.iCESP800ID,
		C8.iCESPReceiveFileID,
		C1.ConventionID
	FROM Un_CESP800ToTreat C8T 
	JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8T.iCESP800ID
	JOIN Un_CESP100 C1 ON C1.iCESP800ID = C8.iCESP800ID
	WHERE C8.iCESP800ID = @iCESP800ID
			OR @iCESP800ID = 0

	-- Insertion des erreurs sur les 200
	INSERT INTO #tCESP200ReceiveFile
	SELECT 
		C8.iCESP800ID,
		C8.iCESPReceiveFileID,
		C2.ConventionID,
		bModified = CASE 
					WHEN ISNULL(C2B.iCESP200ID,-1) = -1 THEN 0
					ELSE 1
				END				
	FROM Un_CESP800ToTreat C8T 
	JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8T.iCESP800ID
	JOIN Un_CESP200 C2 ON C2.iCESP800ID = C8.iCESP800ID
	LEFT JOIN Un_CESP200 C2B ON C2B.ConventionID = C2.ConventionID AND C2B.HumanID = C2.HumanID AND C2B.iCESP200ID > C2.iCESP200ID
	WHERE C8.iCESP800ID = @iCESP800ID
			OR @iCESP800ID = 0

	CREATE INDEX IX_tCESP100ReceiveFile
	ON #tCESP100ReceiveFile (iCESPReceiveFileID, ConventionID, iCESP800ID)

	CREATE INDEX IX_tCESP200ReceiveFile
	ON #tCESP200ReceiveFile (iCESPReceiveFileID, ConventionID, iCESP800ID)

	/*DROP TABLE #tConvention
	DROP TABLE #tConventionState
	DROP TABLE #tCESP100ReceiveFile
	DROP TABLE #tCESP200ReceiveFile*/

	-- Sélection des 400 pour l'outil de retour
	SELECT DISTINCT 
		iCESP800ID = C8.iCESP800ID,		
		iCESP400ID = C4.iCESP400ID,		
		bModified = CAST((CASE 
					WHEN ISNULL(C4R.iCESP400ID,-1) = -1 THEN 0
					ELSE 1 
				END) AS BIT),	
		bError100Or200 = CAST((CASE 
					WHEN ISNULL(C1R.iCESP800ID,-1) = -1 
						AND ISNULL(C2R.iCESP800ID,-1) = -1 THEN 0
					ELSE 1
				END) AS BIT),
		dtRead = dbo.FN_CRQ_DateNoTime(CRF.dtRead),		
		vcTransID = C8.vcTransID,		
		ConventionID = C.ConventionID,		
		ConventionNo = C.ConventionNo,		
		SubscriberID = C.SubscriberID,		
		BeneficiaryID = C.BeneficiaryID,		
		UnitID = U.UnitID,			
		InForceDate = U.InForceDate,		
		UnitQty = U.UnitQty,			
		EffectDate = CT.EffectDate,		
		OperType = O.OperTypeID,		
		ConventionStateName = CCS.ConventionStateName,	
		vcErrFieldName = C8.vcErrFieldName,	
		siCESP800ErrorID = C8.siCESP800ErrorID,
		vcCESP800Error = C8E.vcCESP800Error,
        vcOriginalTransID = '',
        bIs511 = CAST(0 AS Bit)
	FROM 
		Un_CESP800ToTreat C8T
		JOIN Un_CESP800 C8 
			ON C8.iCESP800ID = C8T.iCESP800ID
		JOIN Un_CESP800Error C8E 
			ON C8E.siCESP800ErrorID = C8.siCESP800ErrorID
		JOIN Un_CESP400 C4 
			ON C4.iCESP800ID = C8.iCESP800ID
		JOIN dbo.Un_Convention C 
			ON C.ConventionID = C4.ConventionID
		JOIN #tConventionState CCS 
			ON C.ConventionID = CCS.ConventionID
		LEFT JOIN Un_Cotisation CT 
			ON CT.CotisationID = C4.CotisationID
		LEFT JOIN dbo.Un_Unit U 
			ON U.UnitID = CT.UnitID
		LEFT JOIN Un_Oper O 
			ON O.OperID = C4.OperID
		JOIN Un_CESPReceiveFile CRF 
			ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID
		LEFT JOIN #tCESP100ReceiveFile C1R 
			ON C1R.iCESPReceiveFileID = C8.iCESPReceiveFileID AND C1R.ConventionID = C4.ConventionID
		LEFT JOIN #tCESP200ReceiveFile C2R 
			ON C2R.iCESPReceiveFileID = C8.iCESPReceiveFileID AND C2R.ConventionID = C4.ConventionID
		LEFT JOIN Un_CESP400 C4R 
			ON C4R.OperID = C4.OperID AND C4R.ConventionID = C4.ConventionID AND C4R.iCESP400ID > C4.iCESP400ID	 -- 2010-04-14 : JFG : Ajout du lien sur ConventionID
	WHERE 
		C8.iCESP800ID = @iCESP800ID
		OR 
		@iCESP800ID = 0
		AND (CCS.ConventionStateName <> 'Fermé' OR (CCS.ConventionStateName = 'Fermé' AND O.OperTypeID = 'BEC') /* glpi 7389* -->*/ OR (CCS.ConventionStateName = 'Fermé' AND c.ConventionNo LIKE 'T-%') /*<--  glpi 7389*/ ) -- Ajouté par Pierre Paquet
--ORDER BY dbo.FN_CRQ_DateNoTime(CRF.dtRead), C.ConventionNo, U.UnitID, CT.EffectDate, O.OperTypeID
----------
UNION ALL
----------
--Sélection des 511 pour l'outil de retour
SELECT DISTINCT 
		iCESP800ID = C8.iCESP800ID,		
		iCESP400ID = C5.iCESP511ID,		
		bModified = CASE -- Si les infos du principal responsable dans le 511 diffèrent de celles dans le bénef, c'est qu'il y a eu modification
						WHEN (C5.tiPCGType <> B.tiPCGType) OR 
							  ISNULL(C5.vcPCGLastName, '') <> ISNULL(B.vcPCGLastName, '') OR
							  ISNULL(C5.vcPCGFirstName, '') <> ISNULL(B.vcPCGFirstName, '') OR 
							  ISNULL(C5.vcPCGSINorEN, '') <> ISNULL(B.vcPCGSINorEN, '') THEN					
							CAST (1 AS BIT)
					ELSE CAST(0 AS BIT)
					END,
		bError100Or200 = CAST(0 AS BIT),
		dtRead = dbo.FN_CRQ_DateNoTime(CRF.dtRead),		
		vcTransID = C8.vcTransID,		
		ConventionID = C.ConventionID,		
		ConventionNo = C.ConventionNo,		
		SubscriberID = C.SubscriberID,		
		BeneficiaryID = C.BeneficiaryID,		
		UnitID = 0,			
		InForceDate = 0,		
		UnitQty = 0,			
		EffectDate = 0,		
		OperType = '',		
		ConventionStateName = '',	
		vcErrFieldName = C8.vcErrFieldName,	
		siCESP800ErrorID = C8.siCESP800ErrorID,
		vcCESP800Error = C8E.vcCESP800Error,
        vcOriginalTransID = vcOriginalTransID,
        bIs511 = CAST (1 AS Bit)
	FROM Un_CESP800ToTreat C8T
	JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8T.iCESP800ID
	JOIN Un_CESP800Error C8E ON C8E.siCESP800ErrorID = C8.siCESP800ErrorID
	JOIN Un_CESP511 C5 ON C5.iCESP800ID = C8.iCESP800ID
	JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C5.iBeneficiaryID
    JOIN dbo.Un_Convention C ON C.ConventionID = C5.ConventionID
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID
	WHERE C8.iCESP800ID = @iCESP800ID
			OR @iCESP800ID = 0
	   
--On supprime les tables temporaire
    DROP TABLE #tConvention
	DROP TABLE #tConventionState
	DROP TABLE #tCESP100ReceiveFile
	DROP TABLE #tCESP200ReceiveFile
END


