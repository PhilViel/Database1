/****************************************************************************************************
Code de service	:	IU_UN_MergeBeneficiary
Nom du service		:	IU_UN_MergeBeneficiary
But				:	Fusion des bénéficiaires.
Facette			:	CONV

Parametres d'entrée :	Parametres					Description
		               ----------                  ----------------
					ConnectID					Identifiant unique de la connexion utilisateur en cours.
					iNewBeneficiaryID			Identifiant unique du bénéficiaire remplaçant.
					iOldBeneficiaryID			Identifiant unique du bénéficiaire remplacé

Exemple d'appel:
							
Parametres de sortie : Table						Champs										Description
				   -----------------			---------------------------					--------------------------
											@ReturnValue :
												> 0 : [Réussite]
												<= 0 : [Échec]

Historique des modifications :
			
        Date		Programmeur			Description									    Référence
        ----------	----------------------	----------------------------------------------------------	---------------
        2007-02-15  Alain Quirion			Création													ADX0001234	IA	
        2007-06-06  Alain Quirion			Mise à jour de dtRegEndDateAdjust en remplacement de RegEndDateAddyear ADX0001355	IA	
        2008-01-31  Bruno Lapointe			Correction de bogues : Cas d'avant le 1 janvier 2003 mal géré. Mauvais paramètre à la SP TT_UN_CESPOfConventions ADX0003131	UP	
        2008-11-04  Josée Parent			Ajout d'un log lors de la mise à jour de l'ID du bénéficiaire
        2008-11-24  Josée Parent			Modification pour utiliser la fonction "fnCONV_ObtenirDateFinRegime" dans la table Un_Convention
        2008-12-17  Éric Deshaies			Ajout d'un historique des changements de bénéficiaire: Modifier l'identifiant du bénéficiaire remplacé par le nouveau bénéficaire dans l'historique des changements des bénéficiaires pour maintenir l'intégrité de la base de données.
        2009-01-26  Donald Huppé			Ne pas supprimer une adresse si elle est utilisé par un autre humain par erreur
        2009-09-24  Jean-François Gauthier  Remplacement de @@Identity par Scope_Identity()
        2010-03-22  Éric Deshaies			Commander le traitement de la fusion des bénéficiaires pour
								            le module de l'IQÉÉ
        2011-01-31  Frederick Thibault		Ajout du champ fACESGPart pour régler le problème SCEE+
        2013-11-26  Donald Huppé			Ajout de : Delete from Mo_HumanAdr where HumanID = @iOldBeneficiaryID
        2014-04-02  Pierre-Luc Simard		Retirer la suppression des tables Mo_Adr et Mo_HumanAdr qui n'existent plus et supprimer les données
								            dans les tables tblGENE_Adresses, tblGENE_Telephone et tblGENE_Courriel.
        2014-06-03  Maxime Martel			Suppression dans tblconv_historiquePublipostage
        2014-09-26  Pierre-Luc Simard		Modification du champ iIDBeneficiaire dans Un_Scholarship
        2014-11-07  Pierre-Luc Simard		Ne plus enregistrer la valeur du champ tiCESPState qui sera maintenant géré par la procédure psCONV_EnregistrerPrevalidationPCEE
        2015-04-01  Donald Huppé			Supprimer tblGENE_PortailAuthentification
        2015-06-30  Steve Picard			Désactivation des triggers TRG_GENE_Adresse_Historisation
        2015-07-23  Pierre-Luc Simard		Fusionner les documents génériques
        2015-10-30  Pierre-Luc Simard		Appeler le changement d'état des conventions et des groupes d'unités
        2016-05-26  Pierre-Luc Simard       Fusion du bénéficiaire original sur le groupe d'unités
        2016-08-04  Steeve Picard           Ajout d'un séparateur «@cSep» manquant lors de la journalisation
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_MergeBeneficiary] (
	@ConnectID INTEGER,
	@iNewBeneficiaryID INTEGER,			--Identifiant unique du bénéficiaire remplaçant.
	@iOldBeneficiaryID INTEGER)			--Identifiant unique du bénéficiaire remplacé
AS
BEGIN	
	DECLARE @iResult INTEGER,
			@iSPResult INTEGER,
			@bFCBRCB BIT,
			@OldSocialNumber VARCHAR(10),
			@Today DATETIME,
			@tiCESPState TINYINT,
			@tiOldCESPState TINYINT,
			@cSep CHAR(1),
			@LogAction INT,
			@NewLastName VARCHAR(50),
			@NewFirstName VARCHAR(35),
			@OldLastName VARCHAR(50),
			@OldFirstName VARCHAR(35),
			@LogDesc VARCHAR(100),
			@NoConvention VARCHAR(15)

	SET @cSep = CHAR(30)

	SET @Today = GETDATE()

	SET @iResult = 1
	SET @iSPResult = 1
	SET @bFCBRCB = 0
	SET @OldSocialNumber = ''

	-----------------
	BEGIN TRANSACTION
	-----------------

	IF object_id('tempdb..#DisableTrigger') is null
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

	--Va chercher les état de prévaliadtion du PCEE des deux bénéficiaires
	SELECT @tiCESPState = tiCESPState
	FROM dbo.Un_Beneficiary 
	WHERE BeneficiaryID = @iNewBeneficiaryID

	SELECT @tiOldCESPState = tiCESPState
	FROM dbo.Un_Beneficiary 
	WHERE BeneficiaryID = @iOldBeneficiaryID

	--Si le bénéficiaire à conserver possède un NAS et que le bénéficiaire
	--remplacé n'en possèdait pas, les conventions doivent fixer leur date de début de régime
	--au jour de la fusion et on doit créer les fcb et rcb en conséquence le jour de la fusion
	IF EXISTS (	SELECT B.BeneficiaryID
				FROM dbo.Un_Beneficiary B
				JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
				WHERE B.BeneficiaryID = @iOldBeneficiaryID
						AND ISNULL(H.SocialNumber,'') = '')
		AND EXISTS (	SELECT B.BeneficiaryID
						FROM dbo.Un_Beneficiary B
						JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
						WHERE B.BeneficiaryID = @iNewBeneficiaryID
								AND ISNULL(H.SocialNumber,'') <> '')
	BEGIN
		SET @bFCBRCB = 1

		--Va cherccher les convention qui passent réellement en REEE
		SELECT DISTINCT C.ConventionID
		INTO #PropBefore 
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID --Doit avoir un groupe d'unités
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
		WHERE C.BeneficiaryID = @iOldBeneficiaryID	
				AND ISNULL(H.SocialNumber,'') <> ''	--Le souscripteur doit avoir un NAS 		
				AND C.dtRegStartDate IS NULL -- Proposition seulement

		--Update la date de début de régime
		UPDATE dbo.Un_Convention 
		SET dtRegStartDate = GETDATE()
		FROM dbo.Un_Convention C
		JOIN #PropBefore P ON P.ConventionID = C.ConventionID	
	
		IF @@ERROR <> 0
			SET @iResult = -1

		IF @iResult > 0
		BEGIN
			UPDATE dbo.Un_Convention 
			SET dtRegEndDateAdjust = (SELECT [dbo].[fnCONV_ObtenirDateFinRegime](C.ConventionID,'T',@Today))
			FROM dbo.Un_Convention C
			JOIN #PropBefore P ON P.ConventionID = C.ConventionID
			JOIN (	SELECT  C.ConventionID,
							InforceDate = MIN(U.InforceDate)
					FROM dbo.Un_Unit U
					JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
					WHERE C.BeneficiaryID = @iOldBeneficiaryID
					GROUP BY C.ConventionID) V ON V.ConventionID = C.ConventionID	
			WHERE C.BeneficiaryID = @iOldBeneficiaryID
					AND YEAR(@Today) - YEAR(V.InForceDate) > 0	
					AND C.dtRegEndDateAdjust IS NULL --Si un ajustement existe déjà, on ne le modifie pas

			IF @@ERROR <> 0
				SET @iResult = -2
		END
	END
	/*
	IF @iResult > 0
	BEGIN
		-- Met à jour l'état de pré-validations des conventions du bénéficiaire supprimé
		UPDATE dbo.Un_Convention 
		SET tiCESPState = 
				CASE 
					WHEN ISNULL(CS.tiCESPState,1) = 0 
						OR S.tiCESPState = 0 
						OR @tiCESPState = 0 THEN 0 --tiCESPState du nouveau Bénéficiaire
				ELSE @tiCESPState
				END
		FROM dbo.Un_Convention 
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = Un_Convention.BeneficiaryID
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = Un_Convention.SubscriberID
		LEFT JOIN dbo.Un_Subscriber CS ON CS.SubscriberID = Un_Convention.CoSubscriberID
		WHERE B.BeneficiaryID = @iOldBeneficiaryID
			AND Un_Convention.tiCESPState <> 
						CASE 
							WHEN ISNULL(CS.tiCESPState,1) = 0 
								OR S.tiCESPState = 0 
								OR @tiCESPState = 0 THEN 0 --tiCESPState du nouveau Bénéficiaire
						ELSE @tiCESPState
						END		

		IF @@ERROR <> 0
			SET @iResult = -3
	END
	*/
	   
	IF @iResult > 0
	BEGIN
		SELECT @LogAction = LA.LogActionID FROM CRQ_LogAction LA WHERE LA.LogActionShortName = 'F'
		SELECT @NewLastName = H.LastName, @NewFirstName = H.FirstName FROM dbo.Un_Beneficiary B
			JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
		WHERE B.BeneficiaryID = @iNewBeneficiaryID

		SELECT @OldLastName = H.LastName, @OldFirstName = H.FirstName FROM dbo.Un_Beneficiary B
			JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
		WHERE B.BeneficiaryID = @iOldBeneficiaryID
		--SET @LogDesc = 'Convention:' +  + 'Beneficiaire:' + @LastName + ', ' + @FirstName

		-- Créer un log pour la mise à jour du Souscripteur.
		INSERT INTO CRQ_Log (
			ConnectID,
			LogTableName,
			LogCodeID,
			LogTime,
			LogActionID,
			LogDesc,
			LogText)
			SELECT
				@ConnectID,
				'Un_Convention',
				C.ConventionID,
				GETDATE(),
				@LogAction,
				LogDesc = 'Convention : ' + C.ConventionNo,
				LogText = 'BeneficiaryID' + @cSep + CAST(@iOldBeneficiaryID AS VARCHAR(20)) + @cSep + CAST(@iNewBeneficiaryID AS VARCHAR(20)) + @cSep + @OldLastName + ', ' + @OldFirstName + @cSep + @NewLastName + ', ' + @NewFirstName + @cSep + CHAR(13) + CHAR(10)
			FROM dbo.Un_Convention C
			WHERE C.BeneficiaryID = @iOldBeneficiaryID

		--	Transfert des conventions du bénéficiaire « À supprimer » vers le bénéficiaire « À conserver » en modifiant l’identificateur unique du bénéficiaire dans la table des conventions.
		-- Doit être fait avant la création des enregistrement 400 car ceux ci doivent pointer sur le nouveau bénéficiarie
		UPDATE dbo.Un_Convention 
		SET BeneficiaryID = @iNewBeneficiaryID
		WHERE BeneficiaryID = @iOldBeneficiaryID

		IF @@ERROR <> 0
			SET @iResult = -4

		IF @iResult > 0
		BEGIN
		-- Mettre à jour l'état des prévalidations et les CESRequest de la convention
			EXEC @iSPResult = psCONV_EnregistrerPrevalidationPCEE @ConnectID, NULL, @iNewBeneficiaryID, NULL, NULL

			IF @iSPResult <= 0 
				SET @iResult = -4

			SELECT 
				@tiCESPState = tiCESPState
			FROM dbo.Un_Beneficiary 
			WHERE BeneficiaryID = @iNewBeneficiaryID
		END
	END

	-- Modifier l'identifiant du bénéficiaire remplacé par le nouveau bénéficaire
	--	dans la table Un_Scholarship pour maintenir l'intégrité de la base de données 
	-- et respecter les limites pour les PAE.
	IF @iResult > 0
		BEGIN
			UPDATE Un_Scholarship
			SET iIDBeneficiaire = @iNewBeneficiaryID
			WHERE iIDBeneficiaire = @iOldBeneficiaryID

			IF @@ERROR <> 0
				SET @iResult = -35
		END

	--	Ajout d'un historique des changements de bénéficiaire: Modifier
	--	l'identifiant du bénéficiaire remplacé par le nouveau bénéficaire
	--	dans l'historique des changements des bénéficiaires pour maintenir
	--	l'intégrité de la base de données.
	IF @iResult > 0
		BEGIN
			UPDATE tblCONV_ChangementsBeneficiaire
			SET iID_Nouveau_Beneficiaire = @iNewBeneficiaryID
			WHERE iID_Nouveau_Beneficiaire = @iOldBeneficiaryID

			IF @@ERROR <> 0
				SET @iResult = -28
		END

	--	Commander le traitement de la fusion des bénéficiaires pour le module de l'IQÉÉ
	IF @iResult > 0
		BEGIN
			DECLARE @iID_Utilisateur_Fusion INT

			SELECT @iID_Utilisateur_Fusion=C.UserID
			FROM Mo_Connect C
			WHERE C.ConnectID = @ConnectID

			EXECUTE @iSPResult = [dbo].[psIQEE_FusionnerBeneficiaires] @iOldBeneficiaryID, @iNewBeneficiaryID, @iID_Utilisateur_Fusion

			IF @@ERROR <> 0 OR @iSPResult <> 0
				SET @iResult = -29
		END
/*
	IF @tiCESPState IN (2,4) -- Éligible au BEC
	AND @tiOldCESPState NOT IN (2,4) -- N'était pas éligible avant
	AND @iResult > 0
	BEGIN
		-- Si le bénéficiaire est éligible au BEC (Date de naissance après le 31 décembre 2003 et information du principale responsable 
		-- remplis), on demande le BEC automatiquement pour la plus vieille convention de ce dernier dont la case à cocher « SCEE » est
		-- cochée
		UPDATE dbo.Un_Convention 
		SET bCLBRequested = 1
		WHERE bCLBRequested = 0
			AND tiCESPState IN (2,4) -- État de la convention permet la demande du BEC 
			AND ConventionID IN ( -- Recherche la plus convention du bénéficiaire dont la case à cocher « SCEE » est cochée 
				SELECT MIN(ConventionID)
				FROM ( -- Va chercher les conventions du bénéficiaire avec leurs date d'entrée en vigueur
					SELECT 
						C.ConventionID,
						InForceDate = MIN(U.InForceDate)
					FROM dbo.Un_Convention C
					JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
					WHERE C.BeneficiaryID = @iNewBeneficiaryID
						AND C.bCESGRequested = 1 -- Seulement les conventions dont la SCEE est cochée
						AND C.ConventionID IN ( -- Convention dont l'état n'est pas fermé
								SELECT 
									T.ConventionID
								FROM (-- Retourne la plus grande date de début d'un état par convention
									SELECT 
										S.ConventionID,
										MaxDate = MAX(S.StartDate)
									FROM Un_ConventionConventionState S
									JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
									WHERE C.BeneficiaryID = @iNewBeneficiaryID
									  AND S.StartDate <= GETDATE()
									GROUP BY S.ConventionID
									) T
								JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
								WHERE CCS.ConventionStateID <> 'FRM' -- La convention n'est pas fermée
								)
					GROUP BY C.ConventionID
					HAVING MIN(U.InForceDate) IN (
						-- Va chercher a plus petite date d'entré en vigueur des conventions du bénéficiaire
						SELECT 
							InForceDate = MIN(U.InForceDate)
						FROM dbo.Un_Convention C
						JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
						WHERE C.BeneficiaryID = @iNewBeneficiaryID
							AND C.bCESGRequested = 1 -- Seulement les conventions dont la SCEE est cochée
							AND C.ConventionID IN ( -- Convention dont l'état n'est pas fermé
									SELECT 
										T.ConventionID
									FROM (-- Retourne la plus grande date de début d'un état par convention
										SELECT 
											S.ConventionID,
											MaxDate = MAX(S.StartDate)
										FROM Un_ConventionConventionState S
										JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
										WHERE C.BeneficiaryID = @iNewBeneficiaryID
										  AND S.StartDate <= GETDATE()
										GROUP BY S.ConventionID
										) T
									JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
									WHERE CCS.ConventionStateID <> 'FRM' -- La convention n'est pas fermée
									)
						)
					) V
				)

		IF @@ERROR <> 0
			SET @iResult = -5
	END
	
	IF @tiCESPState IN (3,4) -- Éligible à la SCEE+
	AND @tiOldCESPState NOT IN (3,4) -- N'était pas éligible avant
	AND @iResult > 0
	BEGIN
		-- Si le bénéficiaire est éligible à la SCEE+ (Les informationa du principale responsable sont remplis), on demande la SCEE+
		-- automatiquement pour toutes les conventions de ce dernier dont la case à cocher « SCEE » est cochée et qui ne sont pas fermées
		UPDATE dbo.Un_Convention 
		SET bACESGRequested = 1
		WHERE bACESGRequested = 0
			AND bCESGRequested = 1 -- Seulement les conventions dont la SCEE est cochée
			AND tiCESPState IN (3,4) -- État de la convention permet la demande de la SCEE+ 
			AND ConventionID IN ( -- Convention dont l'état n'est pas fermé
					SELECT 
						T.ConventionID
					FROM (-- Retourne la plus grande date de début d'un état par convention
						SELECT 
							S.ConventionID,
							MaxDate = MAX(S.StartDate)
						FROM Un_ConventionConventionState S
						JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
						WHERE C.BeneficiaryID = @iNewBeneficiaryID
						  AND S.StartDate <= GETDATE()
						GROUP BY S.ConventionID
						) T
					JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
					WHERE CCS.ConventionStateID <> 'FRM' -- La convention n'est pas fermée
					)

		IF @@ERROR <> 0
			SET @iResult = -6
	END
	*/
	--	Création des opérations FCB et RCB au besoin
	IF @iResult > 0 AND @bFCBRCB = 1
	BEGIN
		DECLARE 
			@OperID INTEGER,
			@UnitID INTEGER,
			@Cotisation MONEY,
			@Fee MONEY				

		DECLARE ToDo CURSOR FOR
			SELECT 
				U.UnitID,
				Cotisation = SUM(Ct.Cotisation),
				Fee = SUM(Ct.Fee)
			FROM #PropBefore P
			JOIN dbo.Un_Unit U ON U.ConventionID = P.ConventionID
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			WHERE O.OperDate < @Today
			GROUP BY U.UnitID
			HAVING (SUM(Ct.Cotisation) <> 0)
				OR (SUM(Ct.Fee) <> 0)

		OPEN ToDo

		FETCH NEXT FROM ToDo
		INTO 	@UnitID,
				@Cotisation,
				@Fee

		WHILE @@FETCH_STATUS = 0 AND @iResult > 0
		BEGIN
			INSERT INTO Un_Oper (
				ConnectID,
				OperTypeID,
				OperDate)
			VALUES (
				@ConnectID,
				'RCB',
				@Today)

			IF @@ERROR = 0
				SELECT @OperID = SCOPE_IDENTITY()
			ELSE
				SET @iResult = -7

			IF @iResult > 0
			BEGIN
				INSERT INTO Un_Cotisation (
					OperID,
					UnitID,
					EffectDate,
					Cotisation,
					Fee,
					BenefInsur,
					SubscInsur,
					TaxOnInsur)
				VALUES (
					@OperID,
					@UnitID,
					@Today,
					-@Cotisation,
					-@Fee,
					0,
					0,
					0)

				IF @@ERROR <> 0
					SET @iResult = -8
			END

			IF @iResult > 0
			BEGIN
				INSERT INTO Un_Oper (
					ConnectID,
					OperTypeID,
					OperDate)
				VALUES (
					@ConnectID,
					'FCB',
					@Today)

				IF @@ERROR = 0
					SELECT @OperID = SCOPE_IDENTITY()
				ELSE
					SET @iResult = -9
			END

			IF @iResult > 0
			BEGIN
				INSERT INTO Un_Cotisation (
					OperID,
					UnitID,
					EffectDate,
					Cotisation,
					Fee,
					BenefInsur,
					SubscInsur,
					TaxOnInsur)
				VALUES (
					@OperID,
					@UnitID,
					@Today,
					@Cotisation,
					@Fee,
					0,
					0,
					0)

				IF @@ERROR <> 0
					SET @iResult = -10
			END

			-- Crée l'enregistrement 400 de demande de subvention au PCEE.
			IF @iResult > 0
			BEGIN
				INSERT INTO Un_CESP400 (
						iCESPSendFileID,
						OperID,
						CotisationID,
						ConventionID,
						iCESP800ID,
						iReversedCESP400ID,
						tiCESP400TypeID,
						tiCESP400WithdrawReasonID,
						vcTransID,
						dtTransaction,
						iPlanGovRegNumber,
						ConventionNo,
						vcSubscriberSINorEN,
						vcBeneficiarySIN,
						fCotisation,
						bCESPDemand,
						dtStudyStart,
						tiStudyYearWeek,
						fCESG,
						fACESGPart,
						fEAPCESG,
						fEAP,
						fPSECotisation,
						iOtherPlanGovRegNumber,
						vcOtherConventionNo,
						tiProgramLength,
						cCollegeTypeID,
						vcCollegeCode,
						siProgramYear,
						vcPCGSINorEN,
						vcPCGFirstName,
						vcPCGLastName,
						tiPCGType,
						fCLB,
						fEAPCLB,
						fPG,
						fEAPPG,
						vcPGProv )
					SELECT
						NULL,
						Ct.OperID,
						Ct.CotisationID,
						C.ConventionID,
						NULL,
						NULL,
						11,
						NULL,
						'FIN',
						Ct.EffectDate,
						P.PlanGovernmentRegNo,
						C.ConventionNo,
						HS.SocialNumber,
						HB.SocialNumber,
						Ct.Cotisation+Ct.Fee,
						C.bCESGRequested,
						NULL,
						NULL,
						0,
						0,
						0,
						0,
						0,
						NULL,
						NULL,
						NULL,
						NULL,
						NULL,
						NULL,
						CASE 
							WHEN C.bACESGRequested = 0 THEN NULL
						ELSE B.vcPCGSINOrEN
						END,
						CASE 
							WHEN C.bACESGRequested = 0 THEN NULL
						ELSE B.vcPCGFirstName
						END,
						CASE 
							WHEN C.bACESGRequested = 0 THEN NULL
						ELSE B.vcPCGLastName
						END,
						CASE 
							WHEN C.bACESGRequested = 0 THEN NULL
						ELSE B.tiPCGType
						END,
						0,
						0,
						0,
						0,
						NULL
					FROM Un_Cotisation Ct
					JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
					JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
					JOIN Un_Plan P ON P.PlanID = C.PlanID
					JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
					JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
					JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
					WHERE Ct.OperID = @OperID
	
				IF @@ERROR <> 0 
					SET @iResult = -11
			END
	
			IF @iResult > 0
			BEGIN
				-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
				UPDATE Un_CESP400
				SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
				WHERE vcTransID = 'FIN' 
	
				IF @@ERROR <> 0
					SET @iResult = -12
			END	

			FETCH NEXT FROM ToDo
			INTO 	@UnitID,
					@Cotisation,
					@Fee
		END

		CLOSE ToDo
		DEALLOCATE ToDo		

		DROP TABLE #PropBefore
	END		

	--	L’historique des NAS du bénéficiaire « À supprimer » sera supprimé.
	IF @iResult > 0
	BEGIN
		DELETE Un_HumanSocialNumber
		FROM Un_HumanSocialNumber
		WHERE HumanID = @iOldBeneficiaryID

		IF @@ERROR <> 0
			SET @iResult = -14
	END

	--	La liste des notes du bénéficiaire « À supprimer » sera supprimée.
	IF @iResult > 0
	BEGIN
		DELETE Mo_Note
		FROM Mo_Note
		JOIN Mo_NoteType NT ON Mo_Note.NoteTypeID = NT.NoteTypeID
		WHERE Mo_Note.NoteCodeID = @iOldBeneficiaryID
				AND NT.NoteTypeClassName = 'TUNBENEFICIARY'
		
		IF @@ERROR <> 0
			SET @iResult = -15
	END

	--	Le journal des modifications du bénéficiaire « À supprimer » sera supprimé.
	IF @iResult > 0
	BEGIN
		DELETE CRQ_Log
		FROM CRQ_Log
		WHERE LogTableName = 'Un_Beneficiary'
			AND LogCodeID = @iOldBeneficiaryID

		IF @@ERROR <> 0
			SET @iResult = -16
	END

	--	Si le bénéficiaire « À supprimer » est dans la table des destinataires de chèque, son identificateur unique sera remplacé par celui du bénéficiaire « À conserver »
	--	Les propositions de chèque dont le destinataire est le bénéficiaire « À supprimer » seront modifiées afin que le nouveau destinataire soit le bénéficiaire « À conserver »
	--	Les chèques dont le destinataire est le bénéficiaire « À supprimer » seront transférés vers le bénéficiaire « À conserver »	
	IF @iResult > 0
	BEGIN
		IF EXISTS(	SELECT * 
					FROM CHQ_Payee
					WHERE iPayeeID = @iOldBeneficiaryID)
		BEGIN
			IF NOT EXISTS (	SELECT * 
							FROM CHQ_Payee
							WHERE iPayeeID = @iNewBeneficiaryID)
			BEGIN
				--Insertion du nouveau souscripteur dans la table
				INSERT INTO CHQ_Payee(iPayeeID)
				VALUES(@iNewBeneficiaryID)

				IF @@ERROR <> 0
					SET @iResult = -17
			END

			IF @iResult > 0
			BEGIN
				DECLARE @vcFirstName VARCHAR(35), 
						@vcLastName VARCHAR(50),
						@vcAddress VARCHAR(75),
						@vcCity VARCHAR(100),
						@vcStateName VARCHAR(75),
						@vcCountry CHAR(4),
						@vcZipCode VARCHAR(10)

				--Va chercher les information dui souscripteur actuel
				SELECT TOP 1
						@vcFirstName = H.FirstName, 
						@vcLastName = H.LastName,
						@vcAddress = A.Address,
						@vcCity = A.City,
						@vcStateName = A.StateName,
						@vcCountry = C.CountryName,
						@vcZipCode = A.ZipCode
				FROM dbo.Mo_Human H
				JOIN dbo.Mo_Adr A ON H.AdrID = A.AdrID
				JOIN Mo_Country C ON C.CountryID = A.CountryID
				WHERE H.HumanID = @iNewBeneficiaryID

				--Mise à jour des chèques
				UPDATE CHQ_Check
				SET iPayeeID = @iNewBeneficiaryID
				FROM CHQ_Check
				WHERE iPayeeID = @iOldBeneficiaryID

				IF @@ERROR <> 0
					SET @iResult = -18
			END

			IF @iResult > 0
			BEGIN
				UPDATE CHQ_OperationPayee
				SET iPayeeID = @iNewBeneficiaryID
				WHERE iPayeeID = @iOldBeneficiaryID

				IF @@ERROR <> 0
					SET @iResult = -19
			END

			IF @iResult > 0
			BEGIN
				DELETE 
				FROM CHQ_Payee
				WHERE iPayeeID = @iOldBeneficiaryID

				IF @@ERROR <> 0
						SET @iResult = -20
			END
		END
	END

	--	Le bénéficiaire « À supprimer » sera supprimé de la table des détails de familles (table qui n’est plus utilisée).
	IF @iResult > 0
	BEGIN
		DELETE Mo_FamilyDtl
		FROM Mo_FamilyDtl
		WHERE HumanID = @iOldBeneficiaryID

		IF @@ERROR <> 0
			SET @iResult = -21
	END

	--	Les enregistrements 200 pointant sur le bénéficiaire « À supprimer » seront transférés vers le bénéficiaire « À conserver » sauf les enregistrements 200 non envoyés au PCEE qui seront quant-à-eux supprimés.  Un nouvel enregistrement 200 sera créé si nécessaire pour la/les conventions(s) liée(s) au bénéficiaire « À supprimer » qui ont été transférées.
	IF @iResult > 0
	BEGIN
		UPDATE Un_CESP200
		SET HumanID = @iNewBeneficiaryID
		WHERE  HumanID = @iOldBeneficiaryID
				AND iCESPSendFileID IS NOT NULL

		IF @@ERROR <> 0
			SET @iResult = -22
	
		IF @iResult > 0
		BEGIN
			DELETE Un_CESP200
			FROM Un_CESP200
			WHERE iCESPSendFileID IS NULL
				AND HumanID = @iOldBeneficiaryID

			IF @@ERROR <> 0
				SET @iResult = -23
		END

		IF @iResult > 0
		BEGIN
			EXEC @iSPResult = TT_Un_CESPOfConventions @ConnectID, @iNewBeneficiaryID, 0, 0

			IF @iSPResult <= 0
				SET @iResult = -24
		END
	END

	--	Le bénéficiaire « À supprimer » sera supprimé de la table des bénéficiaires
	IF @iResult > 0
	BEGIN
		DELETE dbo.Un_Beneficiary 
		FROM dbo.Un_Beneficiary 
		WHERE BeneficiaryID = @iOldBeneficiaryID

		IF @@ERROR <> 0
			SET @iResult = -25
	END
	
	-- historique publipostage à supprimer
	IF @iResult > 0
	BEGIN
		DELETE tblconv_historiquePublipostage
		FROM tblconv_historiquePublipostage
		WHERE humanID = @iOldBeneficiaryID

		IF @@ERROR <> 0
			SET @iResult = -27
	END

	--	Les adresses courantes et postdatées du bénéficiaires « À supprimer » seront supprimées
	IF @iResult > 0
	BEGIN
		INSERT INTO #DisableTrigger VALUES('TRG_GENE_Adresse_Historisation_D')	

		DELETE tblGENE_Adresse
		FROM tblGENE_Adresse
		WHERE iID_Source = @iOldBeneficiaryID
			AND cType_Source = 'H'

		IF @@ERROR <> 0
			SET @iResult = -31
	END
	
		--	Les adresses historiques du bénéficiaires « À supprimer » seront supprimées
	IF @iResult > 0
	BEGIN
		DELETE tblGENE_AdresseHistorique
		FROM tblGENE_AdresseHistorique
		WHERE iID_Source = @iOldBeneficiaryID
			AND cType_Source = 'H'

		IF @@ERROR <> 0
			SET @iResult = -32
	END
	
		--	Les adresses courriel du bénéficiaires « À supprimer » seront supprimées
	IF @iResult > 0
	BEGIN
		INSERT INTO #DisableTrigger VALUES('TRG_GENE_Courriel_Historisation_D')	

		DELETE tblGENE_Courriel
		FROM tblGENE_Courriel
		WHERE iID_Source = @iOldBeneficiaryID
			AND cType_Source = 'H'

		IF @@ERROR <> 0
			SET @iResult = -33
	END

	--	Les téléphones du bénéficiaires « À supprimer » seront supprimées
	IF @iResult > 0
	BEGIN
		DELETE tblGENE_PortailAuthentification
		FROM tblGENE_PortailAuthentification
		WHERE iUserId = @iOldBeneficiaryID

		IF @@ERROR <> 0
			SET @iResult = -36
	END

	--	Les téléphones du bénéficiaires « À supprimer » seront supprimées
	IF @iResult > 0
	BEGIN
		INSERT INTO #DisableTrigger VALUES('TRG_GENE_Telephone_Historisation_D')	

		DELETE tblGENE_Telephone
		FROM tblGENE_Telephone
		WHERE iID_Source = @iOldBeneficiaryID
			AND cType_Source = 'H'

		IF @@ERROR <> 0
			SET @iResult = -34
	END
	
	--	Associer les doucments génériques au nouveau bénéficiaire
	IF @iResult > 0
	BEGIN
		UPDATE	dbo.DocumentGeneriqueHumain
		SET		IdHumain = @iNewBeneficiaryID
		WHERE	IdHumain = @iOldBeneficiaryID
		
		IF @@ERROR <> 0
			SET @iResult = -37
	END

    --	Mettre à jour le bénéficiaire original sur les groupes d'unités
	IF @iResult > 0
	BEGIN
		UPDATE	dbo.Un_Unit
		SET		iID_BeneficiaireOriginal = @iNewBeneficiaryID
		WHERE	iID_BeneficiaireOriginal = @iOldBeneficiaryID
		
		IF @@ERROR <> 0
			SET @iResult = -39
	END

		--	Le bénéficiaire « À supprimer » sera supprimé de la table des humains
	IF @iResult > 0
	BEGIN
		DELETE dbo.Mo_Human 
		FROM dbo.Mo_Human
		WHERE HumanID = @iOldBeneficiaryID

		IF @@ERROR <> 0
			SET @iResult = -26
	END

	-- Mise à jour de l'état des conventions et des groupes d'unités.
	IF @iResult > 0
	BEGIN
		DECLARE 
			@vcUnitIDs VARCHAR(MAX),
			@iUnitID INT

		-- Crée une chaîne de caractère avec tout les groupes d'unités affectés
		DECLARE crUnitIDs CURSOR FOR
			SELECT
				U.UnitID
			FROM dbo.Un_Unit U
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			WHERE C.BeneficiaryID = @iNewBeneficiaryID
			ORDER BY 
				C.ConventionID, 
				U.UnitID

		OPEN crUnitIDs

		FETCH NEXT FROM crUnitIDs
		INTO
			@iUnitID

		SET @vcUnitIDs = ''

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			SET @vcUnitIDs = @vcUnitIDs + CAST(@iUnitID AS VARCHAR(30)) + ','
				
			FETCH NEXT FROM crUnitIDs
			INTO
				@iUnitID
		END

		CLOSE crUnitIDs
		DEALLOCATE crUnitIDs

		-- Appelle la procédure qui met à jour les états des groupes d'unités et des conventions
		IF @vcUnitIDs <> ''
			EXECUTE TT_UN_ConventionAndUnitStateForUnit @vcUnitIDs 
		
	END 

		IF @@ERROR <> 0
			SET @iResult = -38

	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @iResult
END
