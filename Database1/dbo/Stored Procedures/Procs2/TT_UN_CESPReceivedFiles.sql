/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_CESPReceivedFiles
Description         :	Fait la lecture, le traitement et la sauvegarde des données des fichiers de retour du PCEE.
Valeurs de retours  :	@Return_Value :
				> 0 :	Tout s’est bien passé.  La valeur correspond au iCESPReceiveFileID qui a été créé.
				<= 0:	Erreur :
					-1 :	Erreur au traitement des enregistrements 900
					-2 :	Erreur au traitement des enregistrements 800
					-3 :	Erreur au traitement des enregistrements 950
					-4 :	Erreur au traitement des enregistrements 850
			Dataset :
				Code	:	Code d'erreur
				Info1	:	Information sur l'erreur
			Erreurs possibles :
				800-1 : Erreur à la sauvegarde d'un enregistrement 800.  Le vcTransID est @Info1@.
					Code  : '800-1'
					Info1 : vcTransID de l'enregistrement en erreur
				900-1 : Erreur à la sauvegarde d'un enregistrement 900.  Le vcTransID est @Info1@.
					Code  : '900-1'
					Info1 : vcTransID de l'enregistrement en erreur
				950-1 : Erreur à la sauvegarde d'un enregistrement 950.  Le numéro de convention est @Info1@.
					Code  : '950-1'
					Info1 : ConventionNo de l'enregistrement en erreur
Note                :	ADX0000811	IA	2006-04-17	Bruno Lapointe			Création
						ADX0002065	BR	2006-08-18	Bruno Lapointe			Gestion du champ Un_CESP400.fCotisationGranted. On transfère sa valeur au champ Un_CESP900.fCotisationGranted des enregistrements 900 créés par le traitement pour des transactions de type 11 ou les annulations.
						ADX0002092	BR	2006-10-04	Bruno Lapointe			Utilisation du champ Un_CESP400Type.bNegOnReceive au lieu de Un_OperType.GovernmentNegOnReceive			
						ADX0001153	IA	2006-11-10	Alain Quirion			Insérer dans la table des erreurs à corriger les nouvelles erreurs.
						ADX0002426	BR	2007-05-23	Bruno Lapointe			Gestion de la table Un_CESP.
						ADX0001178	UP	2007-06-13	Bruno Lapointe			Mise à jour des 400 d'annulation non envoyés.
										2008-06-12  Jean-Francois Arial		Traitement des transactions SUB ayant fait l'objet d'une opération RIO
										2008-08-21  Éric Deshaies			Modification de la date de l'opération RIO de retransfert de la subvention
										2009-02-26  Patrick Robitaille		Gestion des erreurs associées aux enregistrements 511
										2009-03-30  Patrick Robitaille		Ajout des enregistrements 511 à la table Un_CESP900
										2010-04-08	Jean-François Gauthier	Modification afin de gérer les réévaluation des transactions du PCEE
										2010-08-23	Jean-François Gauthier	Correction pour des commandes de désactivation / activation des triggers manquantes
										2010-08-23	Éric Deshaies			Ne pas faire de retransfert RIO s'il y a un compte en négatif.
																			Détacher le retransfert RIO du traitement principal
										2010-10-04	Steve Gouin				Gestion des disable trigger par #DisableTrigger
										2011-01-13	Jean-François Gauthier	Remise en place de la gestion des trigger manuelle, car la table #DisableTrigger
																			ne sert juste pas.
																			Modification du disable trigger
										2011-01-24  Jean-François Gauthier  Retour à la gestion des trigger avec #DisableTrigger 
										2011-01-28	Jean-François Gauthier	Modification de la réévaluation afin d'utiliser le champ ce4.vcBeneficiarySIN de UN_CESP400
																			au lieu de celui de la table temporaire.
										2011-02-03	Frederick Thibault		Ajout du champ fACESGPart pour régler le problème SCEE+
										2011-04-28	Frederick Thibault		Adaptation de l'appel à psOPER_CreerOperationRIO pour projet Prospectus 2010-2011 (FT1)
										2011-06-08	Frederick Thibault		Ajout d'une validation pour le retransfert (FT2)
										2011-08-09	Frederick Thibault		Mise en commentaire à l'appel à psPCEE_CreerDemandeBEC (ça fait planter la SP)
										2013-05-31	Pierre-Luc Simard		Utiliser la dernière journée ouvrable du mois du fichier au lieu de la date dans le nom du fichier
										2014-06-25	Donald Huppé			Enlever les retransfert RIO, depuis qu'on ne fait plus de RIO.
										2015-10-28	Pierre-Luc Simard	Désactiver les triggers de Un_Convention
        2016-11-25  Steeve Picard               Changement d'orientation de la valeur de retour de «fnIQEE_RemplacementBeneficiaireReconnu»
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_CESPReceivedFiles] (
	@ConnectID INTEGER,  -- ID Unique de connexion de l'usager
	@iPROBlobID INTEGER, -- ID unique du blob (CRI_Blob) contenant le texte de fichier de retour qui a l’extension .PRO
	@iERRBlobID INTEGER, -- ID unique du blob (CRI_Blob) contenant le texte de fichier de retour qui a l’extension .ERR (0 =  pas de fichier de ce type)
	@iREGBlobID INTEGER, -- ID unique du blob (CRI_Blob) contenant le texte de fichier de retour qui a l’extension .REG (0 =  pas de fichier de ce type)
	@iSERBlobID INTEGER, -- ID unique du blob (CRI_Blob) contenant le texte de fichier de retour qui a l’extension .SER (0 =  pas de fichier de ce type)
	@vcPROFilename VARCHAR(75), -- Nom du fichier .PRO excluant le path
	@vcERRFilename VARCHAR(75), -- Nom du fichier .ERR excluant le path ('' =  pas de fichier de ce type)
	@vcREGFilename VARCHAR(75), -- Nom du fichier .REG excluant le path ('' =  pas de fichier de ce type)
	@vcSERFilename VARCHAR(75)) -- Nom du fichier .SER excluant le path ('' =  pas de fichier de ce type)
AS
BEGIN
	-- EXECUTE('DISABLE TRIGGER dbo.TUn_CESP900 ON dbo.Un_CESP900')

	IF object_id('tempdb..#DisableTrigger') is null
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

	INSERT INTO #DisableTrigger VALUES('TUn_CESP900')	
	
	DECLARE
		@iResult INTEGER,
		@OperID INTEGER,
		@iCESPReceiveFileDtlID INTEGER,
		@iCESPReceiveFileID INTEGER,
		@dtCESPReceive DATETIME,
		@dtPeriodStart DATETIME,
		@dtPeriodEnd DATETIME,
		@dtLock DATETIME,
		@fSumary MONEY,
		@fPayment MONEY,
		@vcPaymentReqID VARCHAR(10),
		-- Fin des variables du curseur du traitement du fichier .ERR
		@vcTransID VARCHAR(15),
		@iCESPID INT	
		,@vcCode_Message VARCHAR(10) -- FT1
		
	-- Ajout : JFG : 2004-04-08	
	DECLARE	@tSCCEReval	TABLE
						(
						iCESP400ID				INT
						,mSumSCEE				MONEY
						,mSumSCEEPlus			MONEY
						,vcBeneficiarySIN		VARCHAR(75)
						,vcSubscriberSINorEn	VARCHAR(75)
						,iConventionID			INT
						)
		
	DECLARE 
		@vcLigneBlob			VARCHAR(MAX)
		,@vcLigneBlobCotisation	VARCHAR(MAX)
		,@iIDBlob				INT
		,@iIDCotisationBlob		INT
		,@iIDOperCur			INT
		,@iIDCotisationCur		INT
		,@dtDateOperCur			DATETIME
		,@iCompteLigne			INT	
		,@iConventionID			INT
		,@iCESP400IDRecent		INT
		,@iMaxReceiveFileId		INT
		,@dtTrsPlusVieille		DATETIME

	SET @iResult = 1

	SELECT @dtLock = LastVerifDate
	FROM Un_Def

	-- Table temporaire contenant la liste des erreurs, qui ne sont pas majeures, survenues durant le traitement s'il y a lieu
	CREATE TABLE #WngAndErr(
		Code VARCHAR(5),
		Info1 VARCHAR(100))

	-- Tables temporaires contenant les informations formatées des fichiers de la SCÉÉ
	DECLARE @tCESPReceiveFile TABLE (
		dtPeriodStart DATETIME,
		dtPeriodEnd DATETIME,
		fSumary MONEY,
		fPayment MONEY,
		vcPaymentReqID VARCHAR(10),
		vcCESPSendFile VARCHAR(26))

	CREATE TABLE #tCESP800 (
		vcTransID VARCHAR(15) PRIMARY KEY,
		vcErrFieldName VARCHAR(30),
		siCESP800ErrorID VARCHAR(4),
		tyCESP800SINID BIT,
		bFirstName BIT,
		bLastName BIT,
		bBirthDate BIT,
		bSex BIT,
		iCESP100ID INTEGER,
		iCESP200ID INTEGER,
		iCESP400ID INTEGER,
		iCESP800ID INTEGER,
		iCESP511ID INTEGER)

	DECLARE @tCESP850 TABLE (
		tiCESP850ErrorID TINYINT,
		vcTransaction VARCHAR(8000))

	CREATE TABLE #tCESP900 (
		iCESP900ID INT IDENTITY PRIMARY KEY,
		vcTransID VARCHAR(15) NOT NULL,
		fCESG MONEY,
		cCESP900CESGReasonID VARCHAR(1),
		tiCESP900OriginID INTEGER,
		ConventionNo VARCHAR(75),
		vcBeneficiarySIN VARCHAR(75),
		fCLB MONEY,
		fACESG MONEY,
		fCLBFee MONEY,
		fPG MONEY,
		vcPGProv VARCHAR(2),
		fCotisationGranted MONEY,
		cCESP900ACESGReasonID VARCHAR(1),
		ConventionID INT NULL,
		iCESP400ID INT NULL,
		iCESP511ID INT NULL,
		bNegOnReceive BIT DEFAULT(0),
		bUpdateOnReceive BIT DEFAULT(0),
		OperSourceID INT NULL,
		CotisationID INT NULL)

	CREATE INDEX #IX_tCESP900_vcTransID ON #tCESP900(vcTransID)

	CREATE TABLE #tCESP950 (
		dtCESPReg DATETIME,
		ConventionNo VARCHAR(15),
		iConventionState INTEGER,
		tiCESP950ReasonID VARCHAR(1),
		ConventionID INTEGER)

	CREATE TABLE #tCESP (
		iCESPID INT IDENTITY PRIMARY KEY,
		ConventionID INT NOT NULL,
		OperID INT NOT NULL,
		CotisationID INT NULL,
		OperSourceID INT NULL,
		fCESG MONEY NOT NULL,
		fACESG MONEY NOT NULL,
		fCLB MONEY NOT NULL,
		fCLBFee MONEY NOT NULL,
		fPG MONEY NOT NULL,
		vcPGProv VARCHAR(2) NULL,
		fCotisationGranted MONEY NOT NULL,
		iCESP900ID INT NOT NULL )
		
	CREATE INDEX #IX_tCESP_iCESP900ID ON #tCESP(iCESP900ID)

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- Extraction et formatage du contenu des fichiers de SCEE des blobs.
	INSERT INTO @tCESPReceiveFile
		SELECT *
		FROM dbo.FN_UN_CESPReceiveFileOfBlob(@iPROBlobID)

	-- Regarde s'il y a un fichier d'erreurs
	IF @iERRBlobID > 0
		INSERT INTO #tCESP800 (
				vcTransID,
				vcErrFieldName,
				siCESP800ErrorID,
				tyCESP800SINID,
				bFirstName,
				bLastName,
				bBirthDate,
				bSex)
			SELECT *
			FROM dbo.FN_UN_CESP800OfBlob(@iERRBlobID)
	
	-- Regarde s'il y a un fichier d'erreur graves
	IF @iSERBlobID > 0
		INSERT INTO @tCESP850
			SELECT *
			FROM dbo.FN_UN_CESP850OfBlob(@iSERBlobID)

	-- Le fichier .PRO est obligatoire
	INSERT INTO #tCESP900 (
			vcTransID,
			fCESG,
			cCESP900CESGReasonID,
			tiCESP900OriginID,
			ConventionNo,
			vcBeneficiarySIN,
			fCLB,
			fACESG,
			fCLBFee,
			fPG,
			vcPGProv,
			fCotisationGranted,
			cCESP900ACESGReasonID )
		SELECT *
		FROM dbo.FN_UN_CESP900OfBlob(@iPROBlobID)

	-- Regarde s'il y a un fichier d'enregistrement de convention
	IF @iREGBlobID > 0
		INSERT INTO #tCESP950 (
				dtCESPReg,
				ConventionNo,
				iConventionState,
				tiCESP950ReasonID)
			SELECT *
			FROM dbo.FN_UN_CESP950OfBlob(@iREGBlobID)

	-- Va chercher la date de l'opération dans le nom du fichier .pro
	SET @dtCESPReceive = CAST(SUBSTRING(@vcPROFilename, 17, 4)+'-'+SUBSTRING(@vcPROFilename, 21, 2)+'-'+SUBSTRING(@vcPROFilename, 23, 2) AS DATETIME)
	-- Va chercher la dernière journée ouvrable du mois à partir de la date du fichier
	SET @dtCESPReceive = [dbo].[fnGENE_ObtenirDerniereDateOuvrableDuMois](@dtCESPReceive)

	UPDATE Un_Def
	SET LastVerifDate = DATEADD(DAY, -1, @dtCESPReceive)

	-- Crée l'opération dont fera partie la subvention
	EXECUTE @OperID = SP_IU_UN_Oper @ConnectID, 0, 'SUB', @dtCESPReceive

	IF @OperID <= 0
		-- -1 : Erreur à la sauvegarde de l'opération
		SET @iResult = -1
	
	IF @iResult > 0
		IF (SELECT COUNT(*) FROM @tCESPReceiveFile) <> 1
			-- -2 : Il doit y avoir un et un seul enregistrement de type 002 dans le fichier .PRO
			SET @iResult = -2

	IF @iResult > 0
	BEGIN
		-- Va chercher l'information nécessaire à la création du fichier reçu
		SELECT
			@dtPeriodStart = dtPeriodStart,
			@dtPeriodEnd = dtPeriodEnd,
			@fSumary = fSumary,
			@fPayment = fPayment,
			@vcPaymentReqID = vcPaymentReqID
		FROM @tCESPReceiveFile

		-- Création du fichier reçu
		EXECUTE @iCESPReceiveFileID = 
			IU_UN_CESPReceivedFile 
				0, 
				@OperID, 
				@dtPeriodStart, 
				@dtPeriodEnd, 
				@fSumary, 
				@fPayment, 
				@vcPaymentReqID

		IF @iCESPReceiveFileID <= 0 
			-- -3 : Erreur à la sauvegarde
			SET @iResult = -3
		ELSE 
			SET @iResult = @iCESPReceiveFileID
	END

	-- Lie le fichier reçu au fichier envoyé.
	IF @iResult > 0
	BEGIN
		UPDATE Un_CESPSendFile 
		SET
			iCESPReceiveFileID = @iCESPReceiveFileID
		FROM Un_CESPSendFile 
		JOIN @tCESPReceiveFile C ON Un_CESPSendFile.vcCESPSendFile LIKE C.vcCESPSendFile

		IF @@ERROR <> 0
			SET @iResult = -4
	END

	-- Sauvegarde du fichier .PRO dans la liste des fichiers appartenant à ce retour
	IF @iResult > 0
	BEGIN
		-- Crée un enregistrement pour le fichier .PRO dans la liste des fichiers appartenant à ce retour
		EXECUTE @iCESPReceiveFileDtlID = IU_UN_CESPReceivedFileDtl 0, @iCESPReceiveFileID, @vcPROFilename

		IF @iCESPReceiveFileID <= 0 
			-- -5 : Erreur à la sauvegarde de fichier .PRO dans la liste des fichiers appartenant à ce retour
			SET @iResult = -5
	END

	-- Sauvegarde du fichier .ERR, s'il y en a un, dans la liste des fichiers appartenant à ce retour
	IF @iResult > 0 AND @iERRBlobID > 0
	BEGIN
		-- Crée un enregistrement pour le fichier .ERR dans la liste des fichiers appartenant à ce retour
		EXECUTE @iCESPReceiveFileDtlID = IU_UN_CESPReceivedFileDtl 0, @iCESPReceiveFileID, @vcERRFilename

		IF @iCESPReceiveFileID <= 0 
			-- -6 : Erreur à la sauvegarde de fichier .ERR dans la liste des fichiers appartenant à ce retour
			SET @iResult = -6
	END

	-- Sauvegarde du fichier .REG, s'il y en a un, dans la liste des fichiers appartenant à ce retour
	IF @iResult > 0 AND @iREGBlobID > 0
	BEGIN
		-- Crée un enregistrement pour le fichier .REG dans la liste des fichiers appartenant à ce retour
		EXECUTE @iCESPReceiveFileDtlID = IU_UN_CESPReceivedFileDtl 0, @iCESPReceiveFileID, @vcREGFilename

		IF @iCESPReceiveFileID <= 0 
			-- -7 : Erreur à la sauvegarde de fichier .REG dans la liste des fichiers appartenant à ce retour
			SET @iResult = -7
	END

	-- Sauvegarde du fichier .SER, s'il y en a un, dans la liste des fichiers appartenant à ce retour
	IF @iResult > 0 AND @iSERBlobID > 0
	BEGIN
		-- Crée un enregistrement pour le fichier .SER dans la liste des fichiers appartenant à ce retour
		EXECUTE @iCESPReceiveFileDtlID = IU_UN_CESPReceivedFileDtl 0, @iCESPReceiveFileID, @vcSERFilename

		IF @iCESPReceiveFileID <= 0 
			-- -8 : Erreur à la sauvegarde de fichier .SER dans la liste des fichiers appartenant à ce retour
			SET @iResult = -8
	END

	-- Insère les nouveaux codes d'erreurs 800 s'il y a lieu
	IF @iResult > 0
		INSERT INTO Un_CESP800Error (
				siCESP800ErrorID,
				vcCESP800Error )
			SELECT DISTINCT
				siCESP800ErrorID,
				'Ajout automatique'
			FROM #tCESP800
			WHERE siCESP800ErrorID NOT IN (SELECT siCESP800ErrorID FROM Un_CESP800Error)

	IF @@ERROR <> 0 AND @iResult > 0
		SET @iResult = -37

	-- Insère les nouvelles origines s'il y a lieu
	IF @iResult > 0
		INSERT INTO Un_CESP900Origin (
				tiCESP900OriginID,
				vcCESP900Origin )
			SELECT DISTINCT
				tiCESP900OriginID,
				'Ajout automatique'
			FROM #tCESP900
			WHERE tiCESP900OriginID NOT IN (SELECT tiCESP900OriginID FROM Un_CESP900Origin)

	IF @@ERROR <> 0 AND @iResult > 0
		SET @iResult = -38

	-- Insère les nouvelles raisons de non-paiement de SCEE s'il y a lieu
	IF @iResult > 0
		INSERT INTO Un_CESP900CESGReason (
				cCESP900CESGReasonID,
				vcCESP900CESGReason )
			SELECT DISTINCT
				cCESP900CESGReasonID,
				'Ajout automatique'
			FROM #tCESP900
			WHERE cCESP900CESGReasonID NOT IN (SELECT cCESP900CESGReasonID FROM Un_CESP900CESGReason)

	IF @@ERROR <> 0 AND @iResult > 0
		SET @iResult = -39

	-- Insère les nouvelles raisons de non-paiement de SCEE+ s'il y a lieu
	IF @iResult > 0
		INSERT INTO Un_CESP900ACESGReason (
				cCESP900ACESGReasonID,
				vcCESP900ACESGReason )
			SELECT DISTINCT
				cCESP900ACESGReasonID,
				'Ajout automatique'
			FROM #tCESP900
			WHERE cCESP900ACESGReasonID NOT IN (SELECT cCESP900ACESGReasonID FROM Un_CESP900ACESGReason)

	IF @@ERROR <> 0 AND @iResult > 0
		SET @iResult = -40

	-- Début du traitement des données du fichier .PRO
	IF @iResult > 0
	BEGIN
		-- Suppression des enregistrements 100 et 200 qui ne sont pas traités.
		DELETE 
		FROM #tCESP900
		WHERE SUBSTRING(vcTransID,1,3) IN ('CON', 'BEN', 'SUB')

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -9
	
		IF @iResult > 0
			-- Suppression des enregistrements de réponse aux enregistrements 100 (pas traités)
			DELETE #tCESP900
			FROM #tCESP900
			LEFT JOIN Un_CESP100 G1 ON G1.vcTransID = #tCESP900.vcTransID
			WHERE G1.vcTransID IS NOT NULL
		
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -10

		IF @iResult > 0
			-- Suppression des enregistrements de réponse aux enregistrements 200 (pas traités)
			DELETE #tCESP900
			FROM #tCESP900
			LEFT JOIN Un_CESP200 G2 ON G2.vcTransID = #tCESP900.vcTransID
			WHERE G2.vcTransID IS NOT NULL
		
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -11

		IF @iResult > 0
			-- Va chercher les informations nécessaires au traitement des transactions autres que financières et 511 (<> 'FIN' OU <> 'PCG').
			UPDATE #tCESP900
			SET 
				iCESP400ID = G4.iCESP400ID,
				ConventionID = G4.ConventionID,
				bNegOnReceive = C4T.bNegOnReceive,
				bUpdateOnReceive = C4T.bUpdateOnReceive,
				OperSourceID = G4.OperID,
				CotisationID = G4.CotisationID
			FROM #tCESP900
			JOIN Un_CESP400 G4 ON G4.vcTransID = #tCESP900.vcTransID
			JOIN Un_CESP400Type C4T ON C4T.tiCESP400TypeID = G4.tiCESP400TypeID
			WHERE (RTRIM(#tCESP900.vcTransID) <> '') 
			  AND ((SUBSTRING(#tCESP900.vcTransID,1,3) <> 'FIN')
					OR (SUBSTRING(#tCESP900.vcTransID,1,3) <> 'PCG'))
		
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -12

		IF @iResult > 0
			-- Va chercher le iCESP400ID dans le vcTransID si la transaction est de type financière ('FIN'), va aussi chercher le OperSourceID
			UPDATE #tCESP900
			SET 
				iCESP400ID = CAST(RTRIM(SUBSTRING(vcTransID,4,12)) AS INTEGER)
			WHERE (SUBSTRING(vcTransID,1,3) = 'FIN')
		
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -13

		IF @iResult > 0
			-- Va chercher les informations nécessaires au traitement des transactions financières ('FIN').
			UPDATE #tCESP900
			SET 
				ConventionID = G4.ConventionID,
				bNegOnReceive = C4T.bNegOnReceive,
				bUpdateOnReceive = C4T.bUpdateOnReceive,
				OperSourceID = G4.OperID,
				CotisationID = G4.CotisationID
			FROM #tCESP900
			JOIN Un_CESP400 G4 ON G4.iCESP400ID = #tCESP900.iCESP400ID
			JOIN Un_CESP400Type C4T ON C4T.tiCESP400TypeID = G4.tiCESP400TypeID
			WHERE (SUBSTRING(#tCESP900.vcTransID,1,3) = 'FIN')
		
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -14

		IF @iResult > 0
			-- Dans le cas où on n'a pas de government 400 on essaie de le remplir à l'aide du numéro de convention
			UPDATE #tCESP900
			SET 
				ConventionID = C.ConventionID
			FROM #tCESP900
			JOIN dbo.Un_Convention C ON C.ConventionNo LIKE RTRIM(#tCESP900.ConventionNo)
			WHERE (#tCESP900.iCESP400ID IS NULL) 
			  AND (RTRIM(#tCESP900.ConventionNo) <> '')
		
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -16

		IF @iResult > 0
			-- Va chercher le ConventionID avec le numéro de convention si pas réussi à le trouver précédemment
			UPDATE #tCESP900
			SET 
				ConventionID = C.ConventionID
			FROM #tCESP900
			JOIN dbo.Mo_Human H ON H.SocialNumber = #tCESP900.vcBeneficiarySIN
			JOIN dbo.Un_Convention C ON H.HumanID = C.BeneficiaryID
			WHERE (#tCESP900.iCESP400ID IS NULL) 
			  AND (RTRIM(#tCESP900.ConventionNo) <> '')
			  AND (#tCESP900.ConventionID IS NULL)
			
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -17

		IF @iResult > 0
			-- Met en négatif les montants des enregistrements dont le type d'opération indique qui doivent l'être.
			UPDATE #tCESP900
			SET 
				fCESG = -fCESG,
				fACESG = -fACESG,
				fCLB = -fCLB,
				fPG = -fPG
			WHERE bNegOnReceive = 1
			
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -18

		IF @iResult > 0
			-- Créé les enregistrements UN_CESP
			INSERT INTO #tCESP (
					ConventionID,
					OperID,
					CotisationID,
					OperSourceID,
					fCESG,
					fACESG,
					fCLB,
					fCLBFee,
					fPG,
					vcPGProv,
					fCotisationGranted,
					iCESP900ID )
				SELECT
					C9.ConventionID,
					@OperID,
					C9.CotisationID,
					C9.OperSourceID,
					
					-- FT :	Si origine d'un remboursement alors : fCESG - le montant SCEE+ de la table 400
					CASE 
						WHEN C4.tiCESP400TypeID = 21
							THEN C9.fCESG - C4.fACESGPart
						ELSE
							C9.fCESG
					END,
					--C9.fCESG,

					-- FT :	Si origine d'un remboursement alors : montant SCEE+ de la table 400
					CASE 
						WHEN C4.tiCESP400TypeID = 21
							THEN C4.fACESGPart
						ELSE
							C9.fACESG
					END,
					--C9.fACESG,
					
					C9.fCLB,
					C9.fCLBFee,
					C9.fPG,
					C9.vcPGProv,
					C9.fCotisationGranted,
					C9.iCESP900ID
				FROM #tCESP900 C9
				JOIN UN_CESP400 C4 ON C4.iCESP400ID = C9.iCESP400ID -- FT
				WHERE C9.bUpdateOnReceive = 0 -- Enregistrements de subventions qui doivent être créés lors de la réponse de la SCÉÉ
				  AND C9.ConventionID IS NOT NULL -- Le ID unique de la convention ne doit pas être inconnu

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -19

		IF @iResult > 0
			-- Insère les enregistrements dont le type d'opération indique qu'ils doivent être mis à jour mais dont on ne retrouve pas l'enregistrement 900.
			INSERT INTO #tCESP (
					ConventionID,
					OperID,
					CotisationID,
					OperSourceID,
					fCESG,
					fACESG,
					fCLB,
					fCLBFee,
					fPG,
					vcPGProv,
					fCotisationGranted,
					iCESP900ID )
				SELECT
					C9.ConventionID,
					C9.OperSourceID,
					C9.CotisationID,
					C9.OperSourceID,

					-- FT :	Si origine d'un remboursement alors : fCESG - le montant SCEE+ de la table 400
					CASE 
						WHEN C4.tiCESP400TypeID = 21
							THEN C9.fCESG - C4.fACESGPart
						ELSE
							C9.fCESG
					END,
					--C9.fCESG,

					-- FT :	Si origine d'un remboursement alors : montant SCEE+ de la table 400
					CASE 
						WHEN C4.tiCESP400TypeID = 21
							THEN C4.fACESGPart
						ELSE
							C9.fACESG
					END,
					--C9.fACESG,

					C9.fCLB,
					C9.fCLBFee,
					C9.fPG,
					C9.vcPGProv,
					C9.fCotisationGranted,
					C9.iCESP900ID
				FROM #tCESP900 C9
				LEFT JOIN UN_CESP CE ON CE.OperID = C9.OperSourceID
				JOIN UN_CESP400 C4 ON C4.iCESP400ID = C9.iCESP400ID
				WHERE bUpdateOnReceive <> 0 -- Enregistrements de subventions qui doivent être techniquement mis à jour lors de la réponse de la SCÉÉ met qui dans ce cas seront créé car ils n'existent pas
					AND CE.iCESPID IS NULL -- Existe par dans Un_CESP
					AND C9.ConventionID IS NOT NULL -- Le ID unique de la convention ne doit pas être inconnu
					AND C4.iReversedCESP400ID IS NULL -- Dans le cas d'une annulation on ne doit pas recréé la Un_CESP.

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -21

		SET @iCESPID = IDENT_CURRENT('Un_CESP')

		-- EXECUTE('DISABLE TRIGGER dbo.TUn_CESP ON dbo.Un_CESP')
		INSERT INTO #DisableTrigger VALUES('TUn_CESP')
			
		-- Insère dans a vrai table
		IF @iResult > 0
			INSERT INTO Un_CESP (
					ConventionID,
					OperID,
					CotisationID,
					OperSourceID,
					fCESG,
					fACESG,
					fCLB,
					fCLBFee,
					fPG,
					vcPGProv,
					fCotisationGranted )
				SELECT
					ConventionID,
					OperID,
					CotisationID,
					OperSourceID,
					fCESG,
					fACESG,
					fCLB,
					fCLBFee,
					fPG,
					vcPGProv,
					fCotisationGranted
				FROM #tCESP
				
		-- EXECUTE ('ENABLE TRIGGER dbo.TUn_CESP ON dbo.Un_CESP')
		Delete #DisableTrigger where vcTriggerName = 'TUn_CESP'
			
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -42

		IF @iResult > 0
			-- Insère les enregistrements dont le type d'opération indique qu'il doivent être insérés.
			INSERT INTO Un_CESP900 (
					iCESP400ID,
					iCESPReceiveFileID,
					ConventionID,
					iCESPID,
					tiCESP900OriginID,
					cCESP900CESGReasonID,
					cCESP900ACESGReasonID,
					vcTransID,
					vcBeneficiarySIN,
					fCESG,
					fACESG,
					fCLB,
					fCLBFee,
					fPG,
					vcPGProv,
					fCotisationGranted )
				SELECT
					C9.iCESP400ID,
					@iCESPReceiveFileID,
					C9.ConventionID,
					CE.iCESPID+@iCESPID,
					C9.tiCESP900OriginID,
					C9.cCESP900CESGReasonID,
					C9.cCESP900ACESGReasonID,
					C9.vcTransID,
					C9.vcBeneficiarySIN,
					C9.fCESG,
					C9.fACESG,
					C9.fCLB,
					C9.fCLBFee,
					C9.fPG,
					C9.vcPGProv,
					C9.fCotisationGranted
				FROM #tCESP900 C9
				JOIN #tCESP CE ON CE.iCESP900ID = C9.iCESP900ID
				WHERE C9.ConventionID IS NOT NULL -- Le ID unique de la convention ne doit pas être inconnu

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -20
		
		-- **************** 2010-04-08 : Réévaluation des transactions PCEE *******************
		-- Insertion des montants PCEE pour les transaction réévaluées						
		INSERT INTO @tSCCEReval
		(
			iCESP400ID		
			,mSumSCEE		
			,mSumSCEEPlus
			,vcBeneficiarySIN
			,vcSubscriberSINorEn
			,iConventionID
		)
		SELECT
			t.iCESP400ID
			,SUM(t.fCESG)
			,SUM(t.fACESG)
			,ce4.vcBeneficiarySIN			--t.vcBeneficiarySIN
			,ce4.vcSubscriberSINorEN
			,ce4.ConventionId
		FROM
			#tCESP900 t
			INNER JOIN dbo.Un_CESP400 ce4
				ON t.iCESP400ID = ce4.iCESP400ID
		WHERE
			t.tiCESP900OriginID IN (1,4,8)		-- Origine d'une réévaluation ( 1= Réexamen, 4 = Réexamen par suite d'une évaluation de l'ARC (BEC), 8 = Réexamen en raison de l'information sur le principal responsable)
		GROUP BY
			t.iCESP400ID						-- On somme les transactions reliées au même iCESP400ID
			,ce4.vcBeneficiarySIN				--t.vcBeneficiarySIN
			,ce4.vcSubscriberSINorEN
			,ce4.ConventionId
			,ce4.dtTransaction
		HAVING 
			COUNT(t.iCESP400ID) > 1				-- Lors d'un réévaluation, il a 2 transactions reliées au même iCESP400ID		

		-- Évaluation POSITIVE
		DECLARE curConvention CURSOR LOCAL FAST_FORWARD
		FOR
			SELECT
				DISTINCT iConventionID
			FROM
				@tSCCEReval
			
		OPEN curConvention
		FETCH NEXT FROM curConvention INTO @iConventionID
		
		WHILE @@FETCH_STATUS = 0
			BEGIN
				DECLARE curBlob	CURSOR LOCAL FAST_FORWARD	-- Curseur pour bâtir les blobs
				FOR
					SELECT
						ce4.OperID
						,ce4.CotisationID
						,o.OperDate
					FROM
						dbo.Un_Oper o
						INNER JOIN dbo.Un_CESP400 ce4			-- récupération des transactions 400				
							ON o.OperID = ce4.OperID 
						INNER JOIN @tSCCEReval rev
							ON	(	ce4.vcBeneficiarySIN	= rev.vcBeneficiarySIN		-- même bénéficiare et même souscripteur
									AND
									ce4.vcSubscriberSINorEn	= rev.vcSubscriberSINorEn	)
						INNER JOIN dbo.Un_CESP900 ce9
							ON ce9.iCESP400ID = ce4.iCESP400ID
					WHERE
						(rev.mSumSCEE > 0 OR rev.mSumSCEEPlus > 0)	-- réévaluation positive
						AND
						ce4.tiCESP400TypeID = 11					-- transaction de type 11
						AND
						DATEDIFF(mm, ce4.dtTransaction, DATEADD(mm,1,GETDATE())) <= 36	-- transaction pas plus vieille que 36 mois
						AND											-- raison de non-paiement
						(	ce9.cCESP900CESGReasonID IN ('1','2','4','7','L','M')
							OR
							ce9.cCESP900ACESGReasonID IN ('1','2','4','7','L','M')	)
						AND
							ce9.tiCESP900OriginID NOT IN (1,4,8)		-- Le 400 n'a jamais été réévalué (pas de transaction 900 de type 1,4,8 existante)
						AND
							ce4.CotisationID		IS NOT NULL	 
						AND
							ce4.ConventionID		= @iConventionID	-- On doit traiter convention par convention
						
				-- Initialisation des variables
				SELECT
					@vcLigneBlob			= ''
					,@vcLigneBlobCotisation	= ''
					,@iCompteLigne			= 0
					
				-- Construction des blobs
				OPEN curBlob
				FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur
				WHILE @@FETCH_STATUS = 0
					BEGIN
						SET @vcLigneBlob			= @vcLigneBlob + 'Un_Oper' + ';' + CAST(ISNULL(@iCompteLigne,'') AS VARCHAR(8)) + ';' + CAST(ISNULL(@iIDOperCur,'') AS VARCHAR(8)) + ';' + CAST(ISNULL(@ConnectID,'') AS VARCHAR(10)) + ';BNA;' + ';' + CONVERT(VARCHAR(25), ISNULL(@dtDateOperCur,''), 121) + CHAR(13) + CHAR(10)
						SET @vcLigneBlobCotisation	= @vcLigneBlobCotisation + CAST(ISNULL(@iIDCotisationCur,'') AS VARCHAR(10)) + ','
						FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur
					END
				CLOSE curBlob
				DEALLOCATE curBlob

				IF (RTRIM(LTRIM(@vcLigneBlobCotisation)) <> '' AND RTRIM(LTRIM(@vcLigneBlobCotisation)) <> ',')
					BEGIN
						-- Insertion des blobs
						EXECUTE @iIDBlob			= dbo.IU_CRI_BLOB 0, @vcLigneBlob
						EXECUTE @iIDCotisationBlob	= dbo.IU_CRI_BLOB 0, @vcLigneBlobCotisation
						
						-- Renvois des transactions
						EXEC @iResult = dbo.IU_UN_ReSendCotisationCESP400 @iConventionID, @iIDCotisationBlob, @iIDBlob
					END
		
				-- Vérification si la case BEC de la convention est cochée
				IF EXISTS (SELECT 1 FROM dbo.Un_Convention WHERE ConventionId = @iConventionID AND bCLBRequested = 1)
					BEGIN
						-- Récupérer la dernière transaction 400-24 et vérifier si le BEC en erreur
						SELECT
							TOP 1 @iCESP400IDRecent = ce4.iCESP400ID
						FROM
							dbo.Un_CESP400 ce4
						WHERE
							ConventionID	= @iConventionID
							AND
							tiCESP400TypeID	= 24
						ORDER BY
							ce4.dtTransaction DESC
						
						-- Récuper le fichier le plus récent des réponses 900 
						SELECT 
							@iMaxReceiveFileId = MAX(ce9.iCESPReceiveFileID)
						FROM
							dbo.Un_CESP900 ce9
						WHERE
							ce9.iCESP400ID = @iCESP400IDRecent
							
						-- Vérifier les réponses 900 dans le fichier PCEE le plus récent
						IF EXISTS (	SELECT
										1
									FROM 
										dbo.Un_CESP900 ce9
									WHERE
										ce9.iCESPReceiveFileID = @iMaxReceiveFileId
										AND
										ce9.cCESP900CESGReasonID IN ('4','L','M')
										AND
										ce9.iCESP400ID = @iCESP400IDRecent)
							BEGIN
								-- Le fichier est en erreur, il faut faire une nouvelle demande de BEC
								--EXECUTE @iResult = dbo.psPCEE_CreerDemandeBEC @iConventionID
								
								IF @@ERROR <> 0 AND @iResult > 0
									BEGIN
										SET @iResult = -20
									END
							END
					END
				
				-- Évaluation NÉGATIVE

				-- Recherche de la plus ancienne date de transaction parmi les transactions réévaluées
				SELECT
					@dtTrsPlusVieille = MIN(ce4.dtTransaction)
				FROM
					@tSCCEReval t
					INNER JOIN dbo.Un_CESP400 ce4
						ON t.iCESP400ID = ce4.iCESP400ID
				WHERE
					ce4.ConventionID = @iConventionID
					AND
					(t.mSumSCEE < 0 OR t.mSumSCEEPlus < 0)	-- réévaluation négative
					
				IF EXISTS (
							SELECT	
								1			
							FROM 
								@tSCCEReval t
								INNER JOIN dbo.Un_CESP400 ce4
									ON t.iConventionId = ce4.ConventionId	-- recherche basée sur la convention							
								INNER JOIN dbo.Un_CESP900 ce9
									ON ce4.iCESP400ID = ce9.iCESP400ID 
							WHERE
								ce4.tiCESP400TypeID = 21					-- transaction non annulée et non renversée
								AND
								(t.mSumSCEE < 0 OR t.mSumSCEEPlus < 0)	-- réévaluation négative
								AND
								ce4.dtTransaction >= @dtTrsPlusVieille		-- transaction avec une date supérieure ou égale à la transaction réévaluée
								AND
								ce4.fCESG < 0								-- transaction avec un montant de SCCE remboursé
								AND
								t.iConventionID = @iConventionID			-- pour la convention en cours de traitement
								AND
								ce9.cCESP900CESGReasonID IN ('1','3','4','5','7','8','9','11')
						  )
					BEGIN
						DECLARE curBlob	CURSOR LOCAL FAST_FORWARD	-- Curseur pour bâtir les blobs
						FOR
							SELECT
								ce4.OperID
								,ce4.CotisationID
								,o.OperDate
							FROM
								dbo.Un_Oper o
								INNER JOIN dbo.Un_CESP400 ce4				-- récupération des transactions 400				
									ON o.OperID = ce4.OperID 					
								INNER JOIN @tSCCEReval t
									ON t.iConventionId = ce4.ConventionId	-- recherche basée sur la convention		
								INNER JOIN dbo.Un_CESP900 ce9
									ON ce4.iCESP400ID = ce9.iCESP400ID 
							WHERE
								ce4.tiCESP400TypeID = 21					-- transaction non annulée et non renversée
								AND
								(t.mSumSCEE < 0 OR t.mSumSCEEPlus < 0)	-- réévaluation négative
								AND
								ce4.dtTransaction >= @dtTrsPlusVieille		-- transaction avec une date supérieure ou égale à la transaction réévaluée
								AND
								ce4.fCESG < 0								-- transaction avec un montant de SCCE remboursé
								AND
								t.iConventionID = @iConventionID			-- pour la convention en cours de traitement
								AND
								ce9.cCESP900CESGReasonID IN ('1','3','4','5','7','8','9','11')
						
						-- Initialisation des variables
						SELECT
							@vcLigneBlob			= ''
							,@vcLigneBlobCotisation	= ''
							,@iCompteLigne			= 0
							
						-- Construction des blobs
						OPEN curBlob
						FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur
						WHILE @@FETCH_STATUS = 0
							BEGIN
								SET @vcLigneBlob			= @vcLigneBlob + 'Un_Oper' + ';' + CAST(ISNULL(@iCompteLigne,'') AS VARCHAR(8)) + ';' + CAST(ISNULL(@iIDOperCur,'') AS VARCHAR(8)) + ';' + CAST(ISNULL(@ConnectID,'') AS VARCHAR(10)) + ';BNA;' + ';' + CONVERT(VARCHAR(25), ISNULL(@dtDateOperCur,''), 121) + CHAR(13) + CHAR(10)
								SET @vcLigneBlobCotisation	= @vcLigneBlobCotisation + CAST(ISNULL(@iIDCotisationCur,'') AS VARCHAR(10)) + ','
								FETCH NEXT FROM curBlob INTO @iIDOperCur, @iIDCotisationCur, @dtDateOperCur
							END
						CLOSE curBlob
						DEALLOCATE curBlob

						IF (RTRIM(LTRIM(@vcLigneBlobCotisation)) <> '' AND RTRIM(LTRIM(@vcLigneBlobCotisation)) <> ',')
							BEGIN
								-- Insertion des blobs
								EXECUTE @iIDBlob			= dbo.IU_CRI_BLOB 0, @vcLigneBlob
								EXECUTE @iIDCotisationBlob	= dbo.IU_CRI_BLOB 0, @vcLigneBlobCotisation
								
								-- Renvois des transactions
								EXEC @iResult = dbo.IU_UN_ReSendCotisationCESP400 @iConventionID, @iIDCotisationBlob, @iIDBlob
							END				
					END	
		
				FETCH NEXT FROM curConvention INTO @iConventionID
			END	-- Fin du While de curConvention
		CLOSE curConvention
		DEALLOCATE curConvention
		-- *********************** Fin réévalution	******************************

		-- Gestion des enregistrements 511 - On le fait ici car les 511 doivent être insérés dans Un_CESP900,
		-- mais pas dans Un_CESP car les 511 ne sont pas liés à un OperID.
		IF @iResult > 0
			UPDATE #tCESP900
			SET 
				ConventionID = C5.ConventionID,
				iCESP511ID = C5.iCESP511ID
			FROM #tCESP900 C9
			JOIN Un_CESP511 C5 ON C5.vcTransID = C9.vcTransID
			WHERE (C9.iCESP400ID IS NULL) 
			  AND (SUBSTRING(C9.vcTransID,1,3) = 'PCG')
			  AND (C9.ConventionID IS NULL)			
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -43

		IF @iResult > 0
			INSERT INTO Un_CESP900 (
					iCESP400ID,
					iCESPReceiveFileID,
					ConventionID,
					iCESPID,
					tiCESP900OriginID,
					cCESP900CESGReasonID,
					cCESP900ACESGReasonID,
					vcTransID,
					vcBeneficiarySIN,
					fCESG,
					fACESG,
					fCLB,
					fCLBFee,
					fPG,
					vcPGProv,
					fCotisationGranted,
					iCESP511ID )
				SELECT
					NULL,
					@iCESPReceiveFileID,
					C9.ConventionID,
					NULL,
					C9.tiCESP900OriginID,
					C9.cCESP900CESGReasonID,
					C9.cCESP900ACESGReasonID,
					C9.vcTransID,
					C9.vcBeneficiarySIN,
					C9.fCESG,
					C9.fACESG,
					C9.fCLB,
					C9.fCLBFee,
					C9.fPG,
					C9.vcPGProv,
					C9.fCotisationGranted,
					C9.iCESP511ID
				FROM #tCESP900 C9				
				WHERE C9.ConventionID IS NOT NULL -- Le ID unique de la convention ne doit pas être inconnu			
				  AND SUBSTRING(C9.vcTransID, 1, 3) = 'PCG'
				  AND C9.iCESP511ID IS NOT NULL

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -44

		-- Gestion des enregistrements 900 d'origine 2, c'est-à-dire, initié par le PCEE
		IF @iResult > 0
			INSERT INTO Un_CESP900 (
					iCESP400ID,
					iCESPID,
					iCESPReceiveFileID,
					ConventionID,
					tiCESP900OriginID,
					cCESP900CESGReasonID,
					cCESP900ACESGReasonID,
					vcTransID,
					vcBeneficiarySIN,
					fCESG,
					fACESG,
					fCLB,
					fCLBFee,
					fPG,
					vcPGProv,
					fCotisationGranted )
				SELECT
					C9.iCESP400ID,
					CE.iCESPID,
					@iCESPReceiveFileID,
					C9.ConventionID,
					C9.tiCESP900OriginID,
					C9.cCESP900CESGReasonID,
					C9.cCESP900ACESGReasonID,
					C9.vcTransID,
					C9.vcBeneficiarySIN,
					C9.fCESG,
					C9.fACESG,
					C9.fCLB,
					C9.fCLBFee,
					C9.fPG,
					C9.vcPGProv,
					C9.fCotisationGranted
				FROM #tCESP900 C9
				LEFT JOIN #tCESP tCE ON tCE.iCESP900ID = C9.iCESP900ID
				LEFT JOIN Un_CESP CE ON CE.OperSourceID = C9.OperSourceID
				WHERE C9.ConventionID IS NOT NULL -- Le ID unique de la convention ne doit pas être inconnu
					AND tCE.iCESPID IS NULL
	
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -41

		-- Gestion des cotisations subventionnées pour les remboursements
		IF @iResult > 0
			UPDATE Un_CESP900 
			SET fCotisationGranted = C4.fCotisationGranted
			FROM Un_CESP900 C9
			JOIN Un_CESP400 C4 ON C4.iCESP400ID = C9.iCESP400ID
			WHERE C9.iCESPReceiveFileID = @iCESPReceiveFileID
				AND( C4.iReversedCESP400ID IS NOT NULL
					OR tiCESP400TypeID = 21
					)
	
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -42

		-- EXECUTE('DISABLE TRIGGER dbo.TUn_CESP ON dbo.Un_CESP')
		INSERT INTO #DisableTrigger VALUES('TUn_CESP')
		
		-- Gestion des enregistrements 900 d'origine 2, c'est-à-dire, initié par le PCEE
		IF @iResult > 0
			UPDATE Un_CESP 
			SET fCotisationGranted = C4.fCotisationGranted
			FROM Un_CESP CE
			JOIN Un_CESP900 C9 ON C9.iCESPID = CE.iCESPID
			JOIN Un_CESP400 C4 ON C4.iCESP400ID = C9.iCESP400ID
			WHERE C9.iCESPReceiveFileID = @iCESPReceiveFileID
				AND( C4.iReversedCESP400ID IS NOT NULL
					OR tiCESP400TypeID = 21
					)
	
--		EXECUTE('ENABLE TRIGGER dbo.TUn_CESP ON dbo.Un_CESP')
		Delete #DisableTrigger where vcTriggerName = 'TUn_CESP'
		
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -43

		-- Met à jour le fCotisationGranted des 400 d'annulation qui annule une 400 dont la 
		-- 900 de réponse est dans ce fichier
		IF @iResult > 0
			UPDATE Un_CESP400
			SET 
				fCotisationGranted = -CE.fCotisationGranted,
				
				--fCESG = -CE.fCESG, -- FT
				-- SCEE
				fCESG =
					CASE 
						WHEN R4.tiCESP400TypeID = 21
							THEN -(CE.fCESG + CE.fACESG)
						ELSE
							-CE.fCESG
					END,

				-- SCEE+
				fACESGPart = -CE.fACESG,
				
				fCLB = -CE.fCLB
			FROM Un_CESP400 R4
			JOIN Un_CESP900 C9 ON R4.iReversedCESP400ID = C9.iCESP400ID
			JOIN Un_CESP CE ON C9.iCESPID = CE.iCESPID
			WHERE C9.iCESPReceiveFileID = @iCESPReceiveFileID -- 900 reçu dans ce fichier
				AND R4.iCESPSendFileID IS NULL -- Annulation non enovyé
				AND R4.fCotisationGranted = 0
				AND R4.fCESG = 0
				AND R4.fCLB = 0
	
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -44
			
		IF @iResult > 0
			-- Cas ou on ne retrouve pas de trace de ce qui a été expédié
			INSERT INTO #WngAndErr (
					Code,
					Info1)
				SELECT 
					'900-1',
					vcTransID
				FROM #tCESP900
				WHERE ConventionID IS NULL

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -22
	END
	-- Fin du traitement des données du fichier .PRO

	-- Début du traitement des données du fichier .ERR
	-- Vérifie qu'il n'y a pas eu d'erreur dans le traitement pour le moment et qu'il y a un fichier d'erreurs à traiter.
	IF (@iResult > 0) AND (@iERRBlobID > 0)
	BEGIN
		-- Va chercher l'information nécessaire pour les erreurs sur enregistrement 400
		UPDATE #tCESP800
		SET 
			iCESP400ID = G4.iCESP400ID,
			iCESP800ID = G4.iCESP800ID
		FROM #tCESP800
		JOIN Un_CESP400 G4 ON G4.vcTransID = #tCESP800.vcTransID

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -23

		IF @iResult > 0
			-- Va chercher l'information nécessaire pour les erreurs sur enregistrement 200
			UPDATE #tCESP800
			SET 
				iCESP200ID = G2.iCESP200ID,
				iCESP800ID = G2.iCESP800ID
			FROM #tCESP800
			JOIN Un_CESP200 G2 ON G2.vcTransID = #tCESP800.vcTransID
			WHERE #tCESP800.iCESP400ID IS NULL
	
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -24

		IF @iResult > 0
			-- Va chercher l'information nécessaire pour les erreurs sur enregistrement 100
			UPDATE #tCESP800
			SET 
				iCESP100ID = G1.iCESP100ID,
				iCESP800ID = G1.iCESP800ID
			FROM #tCESP800
			JOIN Un_CESP100 G1 ON G1.vcTransID = #tCESP800.vcTransID
			WHERE #tCESP800.iCESP400ID IS NULL
			  AND #tCESP800.iCESP200ID IS NULL
	
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -25

		IF @iResult > 0
			-- Va chercher l'information nécessaire pour les erreurs sur enregistrements 511
			UPDATE #tCESP800
			SET 
				iCESP511ID = G5.iCESP511ID,
				iCESP800ID = G5.iCESP800ID
			FROM #tCESP800
			JOIN Un_CESP511 G5 ON G5.vcTransID = #tCESP800.vcTransID
			WHERE #tCESP800.iCESP511ID IS NULL
	
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -26

		IF @iResult > 0
			INSERT INTO Un_CESP800 (
					iCESPReceiveFileID,
					vcTransID,
					vcErrFieldName,
					siCESP800ErrorID,
					tyCESP800SINID,
					bFirstName,
					bLastName,
					bBirthDate,
					bSex)
				SELECT 
					@iCESPReceiveFileID,
					vcTransID,
					vcErrFieldName,
					siCESP800ErrorID,
					tyCESP800SINID,
					bFirstName,
					bLastName,
					bBirthDate,
					bSex
				FROM #tCESP800
				WHERE (iCESP100ID IS NOT NULL -- Exclu les enregistrements dont on a pas pu retracer l'information
					 OR iCESP200ID IS NOT NULL
					 OR iCESP400ID IS NOT NULL
					 OR iCESP511ID IS NOT NULL)
				  AND (iCESP800ID IS NULL) -- Exclu les enregistrements qui sont déjà marqué en erreur.

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -27

		-- Inscrit le ID des enregistrements 800 sur les enregistrements 100
		IF @iResult > 0
			UPDATE #tCESP800
			SET iCESP800ID = C8.iCESP800ID
			FROM #tCESP800 T8
			JOIN Un_CESP800 C8 ON C8.vcTransID = T8.vcTransID

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -28

		-- Inscrit le ID des enregistrements 800 sur les enregistrements 100
		IF @iResult > 0
			UPDATE Un_CESP100
			SET iCESP800ID = C8.iCESP800ID
			FROM Un_CESP100
			JOIN #tCESP800 C8 ON C8.iCESP100ID = Un_CESP100.iCESP100ID

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -29

		-- Inscrit le ID des enregistrements 800 sur les enregistrements 200
		IF @iResult > 0
			UPDATE Un_CESP200
			SET iCESP800ID = C8.iCESP800ID
			FROM Un_CESP200
			JOIN #tCESP800 C8 ON C8.iCESP200ID = Un_CESP200.iCESP200ID

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -30

		-- Inscrit le ID des enregistrements 800 sur les enregistrements 400
		IF @iResult > 0
			UPDATE Un_CESP400
			SET iCESP800ID = C8.iCESP800ID
			FROM Un_CESP400
			JOIN #tCESP800 C8 ON C8.iCESP400ID = Un_CESP400.iCESP400ID

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -31

		-- Inscrit le ID des enregistrements 800 sur les enregistrements 511
		IF @iResult > 0
			UPDATE Un_CESP511
			SET iCESP800ID = C8.iCESP800ID
			FROM Un_CESP511
			JOIN #tCESP800 C8 ON C8.iCESP511ID = Un_CESP511.iCESP511ID

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -32

		IF @iResult > 0
			-- Insertion des erreurs à traiter
			INSERT INTO Un_CESP800ToTreat (iCESP800ID)
				SELECT DISTINCT
					C8.iCESP800ID
				FROM #tCESP800 C8
				LEFT JOIN Un_CESP800ToTreat C8T ON C8T.iCESP800ID = C8.iCESP800ID
				WHERE C8T.iCESP800ID IS NULL

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -33

		IF @iResult > 0
			-- Supprime les annulations (400) non envoyés qui pointait sur une 400 revenu en erreur
			DELETE
			FROM Un_CESP400
			WHERE iCESP400ID IN (
				SELECT R4.iCESP400ID
				FROM Un_CESP400 R4
				JOIN Un_CESP400 C4 ON C4.iCESP400ID = R4.iReversedCESP400ID
				JOIN #tCESP800 C8 ON C8.iCESP400ID = C4.iCESP400ID
				WHERE R4.iCESPSendFileID IS NULL
				)

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -34

		IF @iResult > 0
			-- Cas ou on ne retrouve pas de trace de ce qui a été expédié
			INSERT INTO #WngAndErr (
					Code,
					Info1)
				SELECT 
					'800-1',
					vcTransID
				FROM #tCESP800
				WHERE iCESP100ID IS NULL
				  AND iCESP200ID IS NULL
				  AND iCESP400ID IS NULL
				  AND iCESP511ID IS NULL

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -35
	END
	-- Fin du traitement des données du fichier .ERR

	-- Début du traitement des données du fichier .SER
	-- Regarde s'il y a un fichier d'erreur graves
	IF (@iSERBlobID > 0) AND (@iResult > 0)
	BEGIN
		INSERT INTO Un_CESP850 (
				iCESPReceiveFileID,
				tiCESP850ErrorID,
				vcTransaction)
			SELECT
				@iCESPReceiveFileID,
				tiCESP850ErrorID,
				vcTransaction
			FROM @tCESP850

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -36
	END
	-- Fin du traitement des données du fichier .SER

	-- Début du traitement des données du fichier .REG
	-- Regarde s'il y a un fichier d'enregistrement de convention
	IF (@iREGBlobID > 0) AND (@iResult > 0)
	BEGIN
		-- Va chercher le ID de la convention
		UPDATE #tCESP950
		SET 
			ConventionID = C.ConventionID
		FROM #tCESP950
		JOIN dbo.Un_Convention C ON C.ConventionNo = #tCESP950.ConventionNo

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -37

		IF @iResult > 0
			-- Met la raison de la 950 à NULL pour les conventions dont l'état est actif
			UPDATE #tCESP950
			SET 
				tiCESP950ReasonID = NULL
			FROM #tCESP950
			WHERE iConventionState = 1 
			  AND ConventionID IS NOT NULL
	
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -38

		IF @iResult > 0
		BEGIN 	
		
			INSERT INTO #DisableTrigger VALUES('TR_U_Un_Convention_F_dtRegStartDate')	
			INSERT INTO #DisableTrigger VALUES('TUn_Convention')	
			INSERT INTO #DisableTrigger VALUES('TUn_Convention_State')	
			INSERT INTO #DisableTrigger VALUES('TUn_Convention_YearQualif')	

			-- Met à jour la date d'enregistrement de la convention pour les conventions dont l'état est actif
			UPDATE dbo.Un_Convention SET 
	        GovernmentRegDate = T950.dtCESPReg
			FROM dbo.Un_Convention 
			JOIN #tCESP950 T950 ON T950.ConventionID = Un_Convention.ConventionID
			WHERE T950.iConventionState = 1 
			  AND T950.ConventionID IS NOT NULL

			Delete #DisableTrigger where vcTriggerName = 'TR_U_Un_Convention_F_dtRegStartDate'
			Delete #DisableTrigger where vcTriggerName = 'TUn_Convention'
			Delete #DisableTrigger where vcTriggerName = 'TUn_Convention_State'
			Delete #DisableTrigger where vcTriggerName = 'TUn_Convention_YearQualif'

		END 

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -39

		IF @iResult > 0
			-- Insère les enregistrements 950 dans leurs tables.
			INSERT INTO Un_CESP950 (
			      iCESPReceiveFileID,
			      ConventionID,
					dtCESPReg,
			      tiCESP950ReasonID)
				SELECT 
			      iCESPReceiveFileID = @iCESPReceiveFileID,
			      ConventionID,
					dtCESPReg,
			      tiCESP950ReasonID
				FROM #tCESP950
				WHERE ConventionID IS NOT NULL
	
		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -40

		IF @iResult > 0
			-- Cas ou on ne retrouve pas de trace de ce qui a été expédié
			INSERT INTO #WngAndErr (
					Code,
					Info1)
				SELECT 
					'950-1',
					ConventionNo
				FROM #tCESP950
				WHERE ConventionID IS NULL

		IF @@ERROR <> 0 AND @iResult > 0
			SET @iResult = -41
	END

	IF @iResult > 0
		UPDATE Un_Def
		SET LastVerifDate = @dtLock

	-- Fin du traitement des données du fichier .REG

	-------------------------------------------------------------------------------------
	-- Retransférer les nouvelles subventions vers la convention individuel après un RIO
	-------------------------------------------------------------------------------------

---- A remettre après les essais d'acceptation
--	BEGIN TRANSACTION
--	BEGIN TRY

	/*
		DECLARE @iID_Convention_Source INT,
				@iID_Unite_Source INT,
				@mfCESG MONEY,
				@mfACESG MONEY,
				@mfCLB MONEY,
				@mfPG MONEY,
				@iCode_Retour INT,
				@dtDateDuJour DATETIME,
				@dtDateOperationRIOOriginale DATETIME,
				@vcRIO_TRANSFERT_TRANSAC_CONVENTION VARCHAR(200)
				,@OperTypeID			VARCHAR(3) -- FT1
				,@ConventionDestination	INT -- FT2

		SET @vcRIO_TRANSFERT_TRANSAC_CONVENTION = [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('RIO-TRANSFERT-TRANSAC-CONVENTION')

		SET @dtDateDuJour = GETDATE()

		DECLARE curTransactionsSUB CURSOR FOR
			SELECT DISTINCT	 R1.iID_Convention_Source
							,R1.iID_Unite_Source
							,O.OperDate
							,R1.OperTypeID -- FT1
							,R1.iID_Convention_Destination -- FT2
									
			FROM Un_CESP C1 
			JOIN tblOPER_OperationsRIO R1 ON R1.iID_Convention_Source = C1.ConventionID AND
												  R1.bRIO_Annulee = 0 AND
												  R1.bRIO_QuiAnnule = 0
			JOIN Un_Oper O ON O.OperID = R1.iID_Oper_RIO
			
			-- FT2
			JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = R1.iID_Convention_Destination

			WHERE	C1.OperID = @OperID 
			AND		R1.dtDate_Enregistrement = (SELECT MIN(R2.dtDate_Enregistrement)
												FROM tblOPER_OperationsRIO R2
												WHERE	R2.iID_Convention_Source = R1.iID_Convention_Source AND
														R2.bRIO_Annulee = 0 AND
														R2.bRIO_QuiAnnule = 0)
			-- qui ont un solde transférable par le RIO...
			AND 0 < (	SELECT SUM(ISNULL(C2.fCESG,0))+SUM(ISNULL(C2.fACESG,0))+SUM(ISNULL(C2.fCLB,0))+SUM(ISNULL(C2.fPG,0))
						FROM Un_CESP C2
						WHERE C2.ConventionID = R1.iID_Convention_Source)
			-- qui n'ont pas de compte en perte
			AND NOT EXISTS (SELECT CO.ConventionOperTypeID,SUM(CO.ConventionOperAmount)
							FROM Un_ConventionOper CO
							WHERE CO.ConventionID = R1.iID_Convention_Source
							AND (CHARINDEX(CO.ConventionOperTypeID,@vcRIO_TRANSFERT_TRANSAC_CONVENTION) > 0)
							GROUP BY CO.ConventionOperTypeID
							HAVING SUM(CO.ConventionOperAmount) < 0)
			
			-- dont la convention cible n'est pas fermée -- FT2
			AND CCS.StartDate = (	SELECT MAX(StartDate)
									FROM Un_ConventionConventionState CCS2
									WHERE CCS2.ConventionID = CCS.ConventionID
									) 
			AND CCS.ConventionStateID <> 'FRM'
			
			-- dont le changement de bénéficiaire est élligible -- FT2
			AND NOT EXISTS(	SELECT 1
							FROM [dbo].[fntCONV_RechercherChangementsBeneficiaire]
												(
												 NULL
												,NULL
												,R1.iID_Convention_Destination
												,NULL
												,dbo.fnCONV_ObtenirDateDebutRegime(R1.iID_Convention_Destination)
												,GETDATE()
												,NULL
												,NULL
												,NULL
												,NULL
												,NULL
												,NULL
												,NULL
												) C
							JOIN dbo.Mo_Human HN ON HN.HumanID = C.iID_Nouveau_Beneficiaire
							JOIN dbo.Mo_Human HA ON HA.HumanID = C.iID_Ancien_Beneficiaire
								
							WHERE C.vcCode_Raison <> 'INI'
							AND dbo.fnIQEE_RemplacementBeneficiaireReconnu
												(
												 C.iID_Changement_Beneficiaire
												,R1.iID_Convention_Destination
												,C.iID_Ancien_Beneficiaire
												,C.iID_Nouveau_Beneficiaire
												,C.dtDate_Changement_Beneficiaire
												,C.bLien_Frere_Soeur_Avec_Ancien_Beneficiaire
												,C.bLien_Sang_Avec_Souscripteur_Initial
												) = 0
							)
					
		OPEN curTransactionsSUB

		FETCH NEXT FROM curTransactionsSUB INTO  @iID_Convention_Source
												,@iID_Unite_Source
												,@dtDateOperationRIOOriginale
												,@OperTypeID
												,@ConventionDestination

		WHILE @@FETCH_STATUS = 0
			BEGIN
				SELECT @mfCESG = SUM(ISNULL(fCESG,0)), @mfACESG = SUM(ISNULL(fACESG,0)), @mfCLB = SUM(ISNULL(fCLB,0)), @mfPG = SUM(ISNULL(fPG,0))
				FROM Un_CESP
				WHERE ConventionID = @iID_Convention_Source

				IF @mfCESG >= 0 AND @mfACESG >= 0 AND @mfCLB >= 0 AND @mfPG >= 0  
					BEGIN
						EXEC @iCode_Retour = [dbo].[psOPER_CreerOperationRIO] 
																 @ConnectID
																,@iID_Convention_Source
																,@iID_Unite_Source
																,@dtDateOperationRIOOriginale
																,@dtDateDuJour
																,@ConventionDestination
																,@OperTypeID
																,1
																
						IF @@Error <> 0 or @iCode_Retour < -2
							SET @iResult = -42
					END

				FETCH NEXT FROM curTransactionsSUB INTO	 @iID_Convention_Source
														,@iID_Unite_Source
														,@dtDateOperationRIOOriginale
														,@OperTypeID
														,@ConventionDestination
			END

		CLOSE curTransactionsSUB
		DEALLOCATE curTransactionsSUB

	*/
---- A remettre après les essais d'acceptation
--		IF @@TRANCOUNT > 0
--			COMMIT TRANSACTION
--	END TRY
--	BEGIN CATCH
--		IF @@TRANCOUNT > 0
--			ROLLBACK TRANSACTION
--	END CATCH

	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------
	
	-- Retourne la liste des erreurs mineures
	SELECT *
	FROM #WngAndErr

	-- Suppression des tables temporaires
	DROP TABLE #tCESP900
	DROP TABLE #tCESP800
	DROP TABLE #tCESP950
	DROP TABLE #WngAndErr
	DROP TABLE #tCESP

	Delete #DisableTrigger where vcTriggerName = 'TUn_CESP900'
	--EXECUTE('ENABLE TRIGGER dbo.TUn_CESP900 ON dbo.Un_CESP900')
	
	RETURN @iResult
END


