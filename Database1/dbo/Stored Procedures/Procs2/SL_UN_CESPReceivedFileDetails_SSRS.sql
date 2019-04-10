
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CESPReceivedFileDetails
Description         :	Retourne le détail d’un fichier reçu du PCEE.
Valeurs de retours  :	Dataset :
								siDetailType	SMALLINT		Type de détail : 1 = Origine, 2 = Fichiers reçus, 3 = Raison de non paiement SCEE et 4 = Raison de non paiement SCEE+, 5=Détails sur .lse enregistrements et sur les monatnts BEC
								vcDetailID		VARCHAR(10)		ID du détail (Unique par pour chaque type).  Si siDetailType = 5, alors cas possibe : CLBFee : Frais de bec, NewBECConv : Conventions admissible au BEC, REC100 : enregistrement sur le contrat, REC200B : enregistrement sur le bénéficiaire, RECS : enregistrement sur le souscripteur, REC400 : enregistement sur les transactions financières.
								vcDescription	VARCHAR(75)		Description, si type = 1 alors c’Est le type d’origine, si type = 2 alors c’est le nom du fichier, si type = 3 ou 4 alors c’est le type de raison.  Si 5, alors c’est la description du vcDetailID.
								fCount			INTEGER			Nombre de cas. Inutilisé pour type 2.
								dtReceived		DATETIME		Date de réception du fichier. Inutilisé pour type 1, 3 et 4, 5. 

Note                :	ADX0000811	IA	2006-04-17	Bruno Lapointe	Création
						ADx0001295	IA	2007-04-24	Alain Quirion	Modification : Ajout des détails de transactions et de BEC
										2010-09-30	Donald Huppé	Création de la SP pour les besoin du rapport SSRS - ajout du param @siDetailType et concaténer le count à la description
exec SL_UN_CESPReceivedFileDetails_SSRS 201, 4
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESPReceivedFileDetails_SSRS] (
	@iCESPReceiveFileID INTEGER, -- ID du fichier reçu du PCEE
	@siDetailType int ) 
AS
BEGIN
	SELECT *
	FROM(
	-- Origine
	SELECT
		siDetailType = 1,
		vcDetailID = CAST(O.tiCESP900OriginID AS VARCHAR),
		vcDescription = O.vcCESP900Origin + ' (' + CAST(ISNULL(COUNT(C9.iCESP900ID),0)AS VARCHAR) + ')',
		fCount = ISNULL(COUNT(C9.iCESP900ID),0),
		dtReceived = NULL
	FROM Un_CESP900Origin O
	LEFT JOIN Un_CESP900 C9 ON O.tiCESP900OriginID = C9.tiCESP900OriginID AND C9.iCESPReceiveFileID = @iCESPReceiveFileID
	GROUP BY
		O.tiCESP900OriginID,
		O.vcCESP900Origin
	---------
	UNION ALL
	---------
	-- Fichiers reçus
	SELECT
		siDetailType = 2,
		vcDetailID = CAST(iCESPReceiveFileDtlID AS VARCHAR),
		vcDescription = vcCESPReceiveFileName,
		fCount = 0,
		dtReceived = CAST(SUBSTRING(vcCESPReceiveFileName, 17, 4)+'-'+SUBSTRING(vcCESPReceiveFileName, 21, 2)+'-'+SUBSTRING(vcCESPReceiveFileName, 23, 2) AS DATETIME)
	FROM Un_CESPReceiveFileDtl
	WHERE iCESPReceiveFileID = @iCESPReceiveFileID
	---------
	UNION ALL
	---------
	-- Raison de non paiement SCEE
	SELECT
		siDetailType = 3,
		vcDetailID = CAST(R.cCESP900CESGReasonID AS VARCHAR),
		vcDescription = R.vcCESP900CESGReason + ' (' + CAST(ISNULL(COUNT(C9.iCESP900ID),0)AS VARCHAR) + ')',
		fCount = ISNULL(COUNT(C9.iCESP900ID),0),
		dtReceived = NULL
	FROM Un_CESP900CESGReason R
	LEFT JOIN Un_CESP900 C9 ON R.cCESP900CESGReasonID = C9.cCESP900CESGReasonID AND C9.iCESPReceiveFileID = @iCESPReceiveFileID
	GROUP BY
		R.cCESP900CESGReasonID,
		R.vcCESP900CESGReason
	---------
	UNION ALL
	---------
	-- Raison de non paiement SCEE+
	SELECT
		siDetailType = 4,
		vcDetailID = CAST(R.cCESP900ACESGReasonID AS VARCHAR),
		vcDescription = R.vcCESP900ACESGReason  + ' (' + CAST(ISNULL(COUNT(C9.iCESP900ID),0)AS VARCHAR) + ')',
		fCount = ISNULL(COUNT(C9.iCESP900ID),0),
		dtReceived = NULL
	FROM Un_CESP900ACESGReason R
	LEFT JOIN Un_CESP900 C9 ON R.cCESP900ACESGReasonID = C9.cCESP900ACESGReasonID AND C9.iCESPReceiveFileID = @iCESPReceiveFileID
	GROUP BY
		R.cCESP900ACESGReasonID,
		R.vcCESP900ACESGReason
	---------
	UNION ALL
	---------
	-- Détails des enregistrements 100
	SELECT 
		siDetailType = 5,
		vcDetailID = 'REC100',
		vcDescription = 'Enregistrement sur le contrat',
		fCount = COUNT(*),
		dtReceived = NULL
	FROM Un_CESP100 C1
	JOIN Un_CESPSendFile CS ON CS.iCESPSendFileID = C1.iCESPSendFileID AND CS.iCESPReceiveFileID = @iCESPReceiveFileID
	WHERE C1.iCESP800ID IS NULL	
	---------
	UNION ALL
	---------
	-- Détails des enregistrements 200 benef	
	SELECT
		siDetailType = 5,
		vcDetailID = 'REC200B',
		vcDescription = 'Enregistrement sur le bénéficiaire',
		fCount = COUNT(*) - MAX(ISNULL(V.iCriticalErrors,0)),
		dtReceived = NULL
	FROM Un_CESP200 C2
	JOIN Un_CESPSendFile CS ON CS.iCESPSendFileID = C2.iCESPSendFileID AND CS.iCESPReceiveFileID = @iCESPReceiveFileID
	LEFT JOIN (
				SELECT  iCESPReceiveFileID,
						iCriticalErrors = COUNT(*)
				FROM Un_CESP850
				WHERE iCESPReceiveFileID = @iCESPReceiveFileID
				GROUP BY iCESPReceiveFileID) V ON V.iCESPReceiveFileID = CS.iCESPReceiveFileID
	WHERE C2.iCESP800ID IS NULL
			AND C2.tiType = 3
	---------
	UNION ALL
	---------
	-- Détails des enregistrements 200 souscripteur	
	SELECT
		siDetailType = 5,
		vcDetailID = 'REC200S',
		vcDescription = 'Enregistrement sur le souscripteur',
		fCount = COUNT(*),
		dtReceived = NULL
	FROM Un_CESP200 C2
	JOIN Un_CESPSendFile CS ON CS.iCESPSendFileID = C2.iCESPSendFileID AND CS.iCESPReceiveFileID = @iCESPReceiveFileID
	WHERE C2.iCESP800ID IS NULL		
			AND C2.tiType = 4
	---------
	UNION ALL
	---------
	-- Détails des enregistrements 400
	SELECT
		siDetailType = 5,
		vcDetailID = 'REC400',
		vcDescription = 'Enregistrement sur les transactions financières',
		fCount = COUNT(*),
		dtReceived = NULL
	FROM Un_CESP900 C9
	WHERE C9.iCESPReceiveFileID = @iCESPReceiveFileID
	) V
	where siDetailType = @siDetailType
	ORDER BY
		1,
		2
END
