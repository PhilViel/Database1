/****************************************************************************************************
Code de service		:		IU_UN_MergeSubscriber
Nom du service		:		IU_UN_MergeSubscriber
But					:		Fusion des souscripteurs.
Facette				:		CONV

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						ConnectID					Identifiant unique de la connexion utilisateur en cours.
						iNewSubscriberID			Identifiant unique du souscripteur remplaçant.
						iOldSubscriberID			Identifiant unique du souscripteur remplacé

Exemple d'appel:
				exec IU_UN_MergeSubscriber 232612,550917,183335					
				exec IU_UN_MergeSubscriber 2,149969,149970	
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													iResult

Historique des modifications :
			
		Date		Programmeur							Description							Référence
		----------	--------------------------		----------------------------		---------------
		2007-02-13	Alain Quirion					Création							ADX0001235	IA
		2007-06-06	Alain Quirion					Mise à jour de dtRegEndDateAdjust en remplacement de RegEndDateAddyear ADX0001355	IA
		2008-01-31	Bruno Lapointe				Correction de bogues : Cas d'avant le 1 janvier 2003 mal géré. ADX0003131	UP
		2008-11-03	Josée Parent					Ajout d'un log lors de la mise à jour de l'ID du souscripteur
		2008-11-24	Josée Parent					Modification pour utiliser la fonction "fnCONV_ObtenirDateFinRegime" dans la table Un_Convention
		2009-03-24	Donald Huppé					Modification pour transférer le profil (d'investisseur) du souscripteur à supprimer vers le profil du souscripteur à conserver si ce dernier n'en a pas.
		2009-09-24	Jean-François Gauthier	Remplacement de @@Identity par Scope_Identity()
		2010-03-23	Éric Deshaies					Commander le traitement de la fusion des souscripteurs 
																pour le module de l'IQÉÉ
		2010-06-01	Jean-François Gauthier	Modification afin que lors de la fusion, les notes HTML supprimées
																soient automatiquement transférées au nouveau souscripteur
																Élimination du traitement sur l'ancienne table Mo_Note
		2010-11-18	Jean-Francois Arial			Commander le traitement de la fusion des souscripteurs 
																pour le module de SGRC
		2011-01-24	Jean-François Gauthier		Retirer la création des FCB-RCB, car les transactions sont maintenant effectuées dans IU_UN_Convention
		2010-10-14	Frederick Thibault			Ajout du champ fACESGPart pour régler le problème de remboursement SCEE+
		2011-10-24	Christian Chénard			Suppression des champs iID_Identite_Souscripteur et vcIdentiteVerifieeDescription du transfert de profil
		2012-09-14	Donald Huppé					Ajout de iID_Tolerance_Risque
		2014-04-01	Donald Huppé					Suppression dans Mo_HumanAdr
		2014-04-02	Pierre-Luc Simard			Retirer la suppression des tables Mo_Adr et Mo_HumanAdr qui n'existent plus et supprimer les données
																dans les tables tblGENE_Adresses, tblGENE_Telephone et tblGENE_Courriel.
		2014-06-03	Maxime Martel				Suppression dans tblconv_historiquePublipostage		
		2014-09-17	Pierre-Luc Simard			Fusionner le profil souscripteur			
		2014-11-07	Pierre-Luc Simard			Ne plus enregistrer la valeur des champs tiCESPState et CESGRequest qui sont maintenant gérés par la procédure psCONV_EnregistrerPrevalidationPCEE									
		2015-06-30	Steve Picard					Désactivation des triggers TRG_CONV_ProfilSouscripteur
		2015-07-23	Pierre-Luc Simard			Fusionner les documents génériques
		2015-10-30	Pierre-Luc Simard			Appeler le changement d'état des conventions et des groupes d'unités
		2017-04-30  Philippe Dubé-Tremblay		Ajout d'un message d'erreur dans le cas d'une convention immobilisé.
		2017-09-27	Donald Huppé				Gestion de la table tblCONV_ChangementsRepresentantsCiblesSouscripteurs : faire un update du souscripteur
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_MergeSubscriber] (
	@ConnectID INT,
	@iNewSubscriberID INT,			--Identifiant unique du souscripteur remplaçant.
	@iOldSubscriberID INT)			--Identifiant unique du souscripteur remplacé
AS
BEGIN	
	DECLARE @iResult INTEGER,
			@iSPResult INTEGER,
			@bFCBRCB BIT,
			@OldSocialNumber VARCHAR(10),
			@Today DATETIME,
			@tiCESPState INT,
			@cSep CHAR(1),
			@LogAction INT,
			@NewLastName VARCHAR(50),
			@NewFirstName VARCHAR(35),
			@OldLastName VARCHAR(50),
			@OldFirstName VARCHAR(35),
			@LogDesc VARCHAR(100)

	SET @cSep = CHAR(30)
	
	SET @Today = GETDATE()

	SET @iResult = 1
	SET @iSPResult = 1
	SET @bFCBRCB = 0
	SET @OldSocialNumber = ''

	BEGIN TRANSACTION

	IF object_id('tempdb..#DisableTrigger') is null
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

	--Va chercher les état de prévaliadtion du PCEE du nouveau souscripteur
	SELECT @tiCESPState = tiCESPState
	FROM dbo.Un_Subscriber 
	WHERE SubscriberID = @iNewSubscriberID

	--Si le souscripteur à conserver possède un NAS et que le souscripteur
	--remplacé n'en possèdait pas, les conventions doivent fixer leur date de début de régime
	--au jour de la fusion et on doit créer les fcb et rcb en conséquence le jour de la fusion
	-- 2011-01-24 : JFG : Mis en commentaire, car la création des FCB et RCB s'effectue maintenant via IU_UN_Convention
--	IF EXISTS (	SELECT S.SubscriberID
--				FROM dbo.Un_Subscriber S
--				JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
--				WHERE SubscriberID = @iOldSubscriberID
--						AND ISNULL(H.SocialNumber,'') = '')
--		AND EXISTS (	SELECT S.SubscriberID
--						FROM dbo.Un_Subscriber S
--						JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
--						WHERE SubscriberID = @iNewSubscriberID
--								AND ISNULL(H.SocialNumber,'') <> '')		
--	BEGIN
--		SET @bFCBRCB = 1
--
--		--Va cherccher les convention qui passent réellement en REEE
--		SELECT DISTINCT C.ConventionID
--		INTO #PropBefore 
--		FROM dbo.Un_Convention C
--		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID --Doit avoir un groupe d'unités
--		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
--		JOIN dbo.Mo_Human H ON H.HumanID = B.BeneficiaryID
--		WHERE C.SubscriberID = @iOldSubscriberID	
--				AND ISNULL(H.SocialNumber,'') <> ''	--Le bénéficiare doit avoir un NAS 		
--				AND C.dtRegStartDate IS NULL -- Proposition seulement
--
--		--Update la date de début de régime
--		UPDATE dbo.Un_Convention 
--		SET dtRegStartDate = GETDATE()	
--		FROM dbo.Un_Convention C
--		JOIN #PropBefore P ON P.ConventionID = C.ConventionID	
--	
--		IF @@ERROR <> 0
--			SET @iResult = -1
--		
--		IF @iResult > 0
--		BEGIN
--			UPDATE dbo.Un_Convention 
--			SET dtRegEndDateAdjust = (SELECT [dbo].[fnCONV_ObtenirDateFinRegime](C.ConventionID,'T',@Today))
--			FROM dbo.Un_Convention C
--			JOIN #PropBefore P ON P.ConventionID = C.ConventionID
--			JOIN (	SELECT  C.ConventionID,
--							InforceDate = MIN(U.InforceDate)
--					FROM dbo.Un_Unit U
--					JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
--					WHERE C.SubscriberID = @iOldSubscriberID
--					GROUP BY C.ConventionID) V ON V.ConventionID = C.ConventionID	
--			WHERE C.SubscriberID = @iOldSubscriberID
--					AND YEAR(@Today) - YEAR(V.InForceDate) > 0	
--					AND C.dtRegEndDateAdjust IS NULL --Si un ajustement existe déjà, on ne le modifie pas
--
--			IF @@ERROR <> 0
--				SET @iResult = -2
--		END
--	END
/*
	IF @iResult > 0
	BEGIN
		-- Met à jour l'état de pré-validations des conventions du souscripteur
		UPDATE dbo.Un_Convention 
		SET tiCESPState = 
				CASE 
					WHEN ISNULL(CS.tiCESPState,1) = 0 
						OR @tiCESPState = 0 
						OR B.tiCESPState = 0 THEN 0
				ELSE B.tiCESPState
				END
		FROM dbo.Un_Convention 
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = Un_Convention.BeneficiaryID
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = Un_Convention.SubscriberID
		LEFT JOIN dbo.Un_Subscriber CS ON CS.SubscriberID = Un_Convention.CoSubscriberID
		WHERE S.SubscriberID = @iOldSubscriberID
			AND Un_Convention.tiCESPState <> 
						CASE 
							WHEN ISNULL(CS.tiCESPState,1) = 0 
								OR @tiCESPState = 0 
								OR B.tiCESPState = 0 THEN 0
						ELSE B.tiCESPState
						END	

		IF @@ERROR <> 0
			SET @iResult = -3
	END
*/

	IF @iResult > 0
	AND	EXISTS (
        SELECT CV.tiMaximisationREEE
		FROM dbo.Un_Convention CV
		WHERE (CV.SubscriberID = @iOldSubscriberID OR CV.SubscriberID = @iNewSubscriberID) AND CV.tiMaximisationREEE = 2
		)
		SET @iResult = -37


	IF @iResult > 0
	BEGIN		
		SELECT @LogAction = LA.LogActionID FROM CRQ_LogAction LA WHERE LA.LogActionShortName = 'F'
		SELECT @NewLastName = H.LastName, @NewFirstName = H.FirstName FROM dbo.Un_Subscriber S
			JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
		WHERE S.SubscriberID = @iNewSubscriberID

		SELECT @OldLastName = H.LastName, @OldFirstName = H.FirstName FROM dbo.Un_Subscriber S
			JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
		WHERE S.SubscriberID = @iOldSubscriberID
		--SET @LogDesc = 'Souscripteur:' + @LastName + ', ' + @FirstName

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
				LogText = 'SubscriberID' + @cSep + CAST(@iOldSubscriberID AS VARCHAR(20)) + @cSep + CAST(@iNewSubscriberID AS VARCHAR(20)) + @cSep + @OldLastName + ', ' + @OldFirstName + @cSep + @NewLastName + ', ' + @NewFirstName + @cSep + CHAR(13) + CHAR(10)
			FROM dbo.Un_Convention C
			WHERE C.SubscriberID = @iOldSubscriberID
		
		-- Transfert des conventions du souscripteur « À supprimer » vers le souscripteur « À conserver » en modifiant l’identificateur unique du souscripteur dans la table des conventions.
		-- Doit être fait avant la création des enregistrement 400 car ceux ci doivent pointer sur le nouveau souscripteur
		UPDATE dbo.Un_Convention 
		SET SubscriberID = @iNewSubscriberID
		WHERE SubscriberID = @iOldSubscriberID

		IF @@ERROR <> 0
			SET @iResult = -4

		IF @iResult > 0
		BEGIN
		-- Mettre à jour l'état des prévalidations et les CESRequest de la convention
			EXEC @iSPResult = psCONV_EnregistrerPrevalidationPCEE @ConnectID, NULL, NULL, @iNewSubscriberID, NULL

			IF @iSPResult <= 0 
				SET @iResult = -4

			SELECT 
				@tiCESPState = tiCESPState
			FROM dbo.Un_Subscriber 
			WHERE SubscriberID = @iNewSubscriberID
		END
        
	END

	--	Commander le traitement de la fusion des souscripteurs pour le module de l'IQÉÉ
	IF @iResult > 0
		BEGIN
			DECLARE @iID_Utilisateur_Fusion INT

			SELECT @iID_Utilisateur_Fusion=C.UserID
			FROM Mo_Connect C
			WHERE C.ConnectID = @ConnectID

			EXECUTE @iSPResult = [dbo].[psIQEE_FusionnerSouscripteurs] @iOldSubscriberID, @iNewSubscriberID, @iID_Utilisateur_Fusion

			IF @@ERROR <> 0 OR @iSPResult <> 0
				SET @iResult = -29
		END

	--	Commander le traitement de la fusion des souscripteurs pour le module de SGRC
	IF @iResult > 0
		BEGIN
			-- Retourner -1 s'il y a des paramètres manquants ou invalides
			IF @iOldSubscriberID IS NULL OR @iOldSubscriberID = 0 OR
				NOT EXISTS(SELECT * 
							FROM dbo.Mo_Human H
							WHERE H.HumanID = @iOldSubscriberID) OR
				@iNewSubscriberID IS NULL OR @iNewSubscriberID = 0 OR
				NOT EXISTS(SELECT * 
							FROM dbo.Mo_Human H
							WHERE H.HumanID = @iNewSubscriberID)
				SET @iSPResult = -1
			ELSE
				EXECUTE @iSPResult = [dbo].[synUnivBase_psSGRC_FusionnerSouscripteurs] @iOldSubscriberID, @iNewSubscriberID

			IF @@ERROR <> 0 OR @iSPResult <> 0
				SET @iResult = -30
		END

	--2011-01-24 : JFG : Mise en commentaire, car la création des FCB et RCB s'effectue maintenant via IU_UN_Convention
	--	Création des opérations FCB et RCB au besoin
/*	IF @iResult > 0 AND @bFCBRCB = 1
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
				SET @iResult = -5

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
					SET @iResult = -6
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
					SET @iResult = -7
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
					SET @iResult = -8
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
					SET @iResult = -9
			END
	
			IF @iResult > 0
			BEGIN
				-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
				UPDATE Un_CESP400
				SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
				WHERE vcTransID = 'FIN' 
	
				IF @@ERROR <> 0
					SET @iResult = -10
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
*/

	--	L’historique des NAS/NE du souscripteur « À supprimer » sera supprimé.
	IF @iResult > 0
	BEGIN
		DELETE Un_HumanSocialNumber
		FROM Un_HumanSocialNumber
		WHERE HumanID = @iOldSubscriberID

		IF @@ERROR <> 0
			SET @iResult = -12
	END

	--	La liste des notes du souscripteur « À supprimer » sera supprimée.
	IF @iResult > 0
	BEGIN
		-- 2010-06-01 : JFG : Mise en commentaire de l'ancien traitement, car la table Mo_Note n'est plus utilisé
		--					  car remplacée par dbo.tblGENE_Note
		--DELETE Mo_Note
		--FROM 
		--	Mo_Note
		--	JOIN Mo_NoteType NT 
		--		ON Mo_Note.NoteTypeID = NT.NoteTypeID
		--WHERE 
		--	Mo_Note.NoteCodeID = @iOldSubscriberID
		--	AND 
		--	NT.NoteTypeClassName = 'TUNSUBSCRIBER'
		
		-- 2010-06-01 : JFG : Transfert des notes vers le nouveau souscripteur
		UPDATE	dbo.tblGENE_Note
		SET		iID_HumainClient = @iNewSubscriberID
		WHERE	iID_HumainClient = @iOldSubscriberID
		
		IF @@ERROR <> 0
			SET @iResult = -13
	END

	--	Le journal des modifications du souscripteur « À supprimer » sera supprimé.
	IF @iResult > 0
	BEGIN
		DELETE CRQ_Log
		FROM CRQ_Log
		WHERE LogTableName = 'Un_Subscriber'
			AND LogCodeID = @iOldSubscriberID

		IF @@ERROR <> 0
			SET @iResult = -14
	END

	--	Si le souscripteur « À supprimer » est dans la table des destinataires de chèque, son identificateur unique sera remplacé par celui du souscripteur « À conserver »
	--	Les propositions de chèque dont le destinataire est le souscripteur « À supprimer » seront modifiées afin que le nouveau destinataire soit le souscripteur « À conserver »
	--	Les chèques dont le destinataire est le souscripteur « À supprimer » seront transférés vers le souscripteur « À conserver »	
	IF @iResult > 0
	BEGIN
		IF EXISTS(	SELECT * 
					FROM CHQ_Payee
					WHERE iPayeeID = @iOldSubscriberID)
		BEGIN
			IF NOT EXISTS (	SELECT * 
							FROM CHQ_Payee
							WHERE iPayeeID = @iNewSubscriberID)
			BEGIN
				--Insertion du nouveau souscripteur dans la table
				INSERT INTO CHQ_Payee(iPayeeID)
				VALUES(@iNewSubscriberID)

				IF @@ERROR <> 0
					SET @iResult = -15
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
				WHERE H.HumanID = @iNewSubscriberID

				--Mise à jour des chèques
				UPDATE CHQ_Check
				SET iPayeeID = @iNewSubscriberID,
					vcFirstName = @vcFirstName, 
					vcLastName = @vcLastName,
					vcAddress = @vcAddress,
					vcCity = @vcCity,
					vcStateName = @vcStateName,
					vcCountry = @vcCountry,
					vcZipCode = @vcZipCode
				FROM CHQ_Check
				WHERE iPayeeID = @iOldSubscriberID

				IF @@ERROR <> 0
					SET @iResult = -16
			END

			IF @iResult > 0
			BEGIN
				UPDATE CHQ_OperationPayee
				SET iPayeeID = @iNewSubscriberID
				WHERE iPayeeID = @iOldSubscriberID

				IF @@ERROR <> 0
					SET @iResult = -17
			END

			IF @iResult > 0
			BEGIN
				DELETE 
				FROM CHQ_Payee
				WHERE iPayeeID = @iOldSubscriberID

				IF @@ERROR <> 0
						SET @iResult = -18
			END
		END
	END

	--	Le souscripteur « À supprimer » sera supprimé de la table des détails de familles (table qui n’est plus utilisée).
	IF @iResult > 0
	BEGIN
		DELETE Mo_FamilyDtl
		FROM Mo_FamilyDtl
		WHERE HumanID = @iOldSubscriberID

		IF @@ERROR <> 0
			SET @iResult = -19
	END

	--	Les enregistrements 200 pointant sur le souscripteur « À supprimer » seront transférés vers le souscripteur « À conserver » sauf les enregistrements 200 non envoyés au PCEE qui seront quant-à-eux supprimés.  Un nouvel enregistrement 200 sera créé si nécessaire pour la/les conventions(s) liée(s) au souscripteur « À supprimer » qui ont été transférées.
	IF @iResult > 0
	BEGIN
		UPDATE Un_CESP200
		SET HumanID = @iNewSubscriberID
		WHERE  HumanID = @iOldSubscriberID
				AND iCESPSendFileID IS NOT NULL

		IF @@ERROR <> 0
			SET @iResult = -20
	
		IF @iResult > 0
		BEGIN
			DELETE Un_CESP200
			FROM Un_CESP200
			WHERE iCESPSendFileID IS NULL
				AND HumanID = @iOldSubscriberID

			IF @@ERROR <> 0
				SET @iResult = -21
		END

		IF @iResult > 0
		BEGIN
			EXEC @iSPResult = TT_Un_CespOfConventions @ConnectID, 0, @iNewSubscriberID, 0

			IF @iSPResult <= 0
				SET @iResult = -22
		END
	END

	--	Transférer l'historique des profils du souscripteur « À supprimer » dans celui du souscripteur « À conserver » si ce dernier n'en a pas déjà un à cette date
	IF @iResult > 0
	BEGIN
		INSERT INTO #DisableTrigger VALUES('TRG_CONV_ProfilSouscripteur_U')

		UPDATE PSO
		SET iID_Souscripteur = @iNewSubscriberID
		FROM tblCONV_ProfilSouscripteur PSO
		WHERE PSO.iID_Souscripteur = @iOldSubscriberID
			-- Le nouveau souscripteur n'a pas de profil
			AND NOT EXISTS (
					SELECT PSN.iID_Profil_Souscripteur 
					FROM tblCONV_ProfilSouscripteur PSN
					WHERE PSN.iID_Souscripteur = @iNewSubscriberID
						AND PSN.DateProfilInvestisseur = PSO.DateProfilInvestisseur)
		
		IF @@ERROR <> 0
			SET @iResult = -27
	END	

	--	Les profils restant du souscripteur « À supprimer » seront supprimés.
	IF @iResult > 0
	BEGIN
		DELETE tblCONV_ProfilSouscripteur
		FROM tblCONV_ProfilSouscripteur
		WHERE iID_Souscripteur = @iOldSubscriberID
				
		IF @@ERROR <> 0
			SET @iResult = -28
	END	

	--	Le souscripteur « À supprimer » sera supprimé de la table des souscripteurs
	IF @iResult > 0
	BEGIN
		DELETE dbo.Un_Subscriber 
		FROM dbo.Un_Subscriber 
		WHERE SubscriberID = @iOldSubscriberID

		IF @@ERROR <> 0
			SET @iResult = -23
	END

	--	Le souscripteur « À supprimer » qui est aussi le tuteur d'un bénéficiaire sera remplacé par le souscripteur « À conserver »
	IF @iResult > 0
	BEGIN
		UPDATE dbo.Un_Beneficiary 
		SET iTutorID = @iNewSubscriberID
		WHERE iTutorID = @iOldSubscriberID

		IF @@ERROR <> 0
			SET @iResult = -24
	END

	--	Le souscripteur « À supprimer » qui a eu un changement de représentant sera remplacé par le souscripteur « À conserver »
	IF @iResult > 0
	BEGIN
		UPDATE dbo.tblCONV_ChangementsRepresentantsCiblesSouscripteurs 
		SET iID_Souscripteur = @iNewSubscriberID
		WHERE iID_Souscripteur = @iOldSubscriberID

		IF @@ERROR <> 0
			SET @iResult = -36
	END
	

/*
	IF @iResult > 0
	BEGIN
		DELETE dbo.Mo_HumanAdr
		FROM dbo.Mo_HumanAdr
		WHERE HumanID = @iOldSubscriberID

		IF @@ERROR <> 0
			SET @iResult = -25
	END
*/
	-- historique publipostage à supprimer
	IF @iResult > 0
	BEGIN
		delete tblconv_historiquePublipostage
		from tblconv_historiquePublipostage
		WHERE HumanID = @iOldSubscriberID
		
		IF @@ERROR <> 0
			SET @iResult = -27
	END
	
	--	Les adresses courantes et postdatées du souscripteur « À supprimer » seront supprimées
	IF @iResult > 0
	BEGIN
		INSERT INTO #DisableTrigger VALUES('TRG_GENE_Adresse_Historisation_D')	

		DELETE tblGENE_Adresse
		FROM tblGENE_Adresse
		WHERE iID_Source = @iOldSubscriberID
			AND cType_Source = 'H'

		IF @@ERROR <> 0
			SET @iResult = -31
	END
	
		--	Les adresses historiques du souscripteur « À supprimer » seront supprimées
	IF @iResult > 0
	BEGIN
		DELETE tblGENE_AdresseHistorique
		FROM tblGENE_AdresseHistorique
		WHERE iID_Source = @iOldSubscriberID
			AND cType_Source = 'H'

		IF @@ERROR <> 0
			SET @iResult = -32
	END
	
		--	Les adresses courriel du souscripteur « À supprimer » seront supprimées
	IF @iResult > 0
	BEGIN
		INSERT INTO #DisableTrigger VALUES('TRG_GENE_Courriel_Historisation_D')	

		DELETE tblGENE_Courriel
		FROM tblGENE_Courriel
		WHERE iID_Source = @iOldSubscriberID
			AND cType_Source = 'H'

		IF @@ERROR <> 0
			SET @iResult = -33
	END

	--	Les téléphones du souscripteur « À supprimer » seront supprimées
	IF @iResult > 0
	BEGIN
		INSERT INTO #DisableTrigger VALUES('TRG_GENE_Telephone_Historisation_D')	

		DELETE tblGENE_Telephone
		FROM tblGENE_Telephone
		WHERE iID_Source = @iOldSubscriberID
			AND cType_Source = 'H'

		IF @@ERROR <> 0
			SET @iResult = -34
	END

	--	Associer les doucments génériques au nouveau souscripteur
	IF @iResult > 0
	BEGIN
		UPDATE	dbo.DocumentGeneriqueHumain
		SET		IdHumain = @iNewSubscriberID
		WHERE	IdHumain = @iOldSubscriberID
		
		IF @@ERROR <> 0
			SET @iResult = -35
	END

	--	Le souscripteur « À supprimer » sera supprimé de la table des humains
	IF @iResult > 0
	BEGIN
		DELETE dbo.Mo_Human
		FROM dbo.Mo_Human
		WHERE HumanID = @iOldSubscriberID

		IF @@ERROR <> 0
			SET @iResult = -25
	END

	/*
	--	L’historique des adresses du souscripteur « À supprimer » sera supprimé.
	IF @iResult > 0
	BEGIN
		DELETE dbo.Mo_Adr 
		FROM dbo.Mo_Adr 
		WHERE SourceID = @iOldSubscriberID
				AND AdrTypeID = 'H' --Même les souscripteurs entreprise sont de type humain dans les adresses
				
		IF @@ERROR <> 0
			SET @iResult = -26
	END	
	*/

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
			WHERE C.SubscriberID = @iNewSubscriberID
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
		SET @iResult = -36

	IF @iResult > 0
		COMMIT TRANSACTION
	ELSE
		ROLLBACK TRANSACTION

	RETURN @iResult
END