/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_Operation
Description         :	Suppression d'une opération
Valeurs de retours  :	1 Suppression réussie
								------------------------
								-1 Erreur la date de l'opération n'est pas plus grande que la date de blocage 
								-2 Erreur l'opération fait partie d'un fichier bancaire
								-3 Erreur l'opération fait partie d'un calcul d'intérêt
								-6 Erreur l'opération fait partie d'un fichier de retour de la banque
								-7 Erreur l'opération est un NSF fesant partie d'un fichier de retour de la banque
								-8 Erreur l'opération a fait l'objet d'une annulation financière
								-9 Erreur l'opération a été expédié à la PCEE
								-10 Message d’erreur : Une opération de résiliation ne peut être annulée lorsque qu’un transfert de frais utilise les frais associés aux unités résiliées.
								-11 Message d’erreur : Une opération de transfert OUT ne peut être annulée lorsque qu’un transfert de frais utilise les frais associés aux unités résiliées.	
								-29 Erreur : On a émis un chèque pour cette opération qui n'a pas été refusé ou annulé.
								-30 Erreur : L'opération est barrée par la fenêtre de validation des changements de destinataire.
Note                :							
									2004-07-12	Bruno Lapointe			Création
					ADX0000509	IA	2004-10-04	Bruno Lapointe			Suppression des raisons de retrait
					ADX0001120	BR	2004-10-21	Bruno Lapointe			Supprimer la subvention qui n'a pas été envoyé 
																		des transferts IN
					ADX0001151	BR	2004-11-11	Bruno Lapointe			Correction de la suppression des réductions d'unités
					ADX0000510	IA	2004-11-15	Bruno Lapointe			Renommé et adapté pour les opérations multiples.
					ADX0000588	IA	2004-11-18	Bruno Lapointe			Gestion des AVC, suppression de paiement et 
																		d'avance de bourse.
					ADX0000625	IA	2004-01-05	Bruno Lapointe			Gestion des RIN
					ADX0000753	IA	2005-10-05	Bruno Lapointe			1. Pour les opérations RES, TFR, OUT, RIN, RET, PAE,
																		RGC, AVC on validera qu’il n’y pas de chèque d’émis
																		dans le module des chèques plutôt que dans les table
																		d’UniSQL.
																		2. Pour les mêmes opérations il faut informer le
																		module des chèques de la suppression de l’opération
																		pour qu’elle ne soit plus disponible pour une
																		proposition de chèque.
					ADX0000984	IA	2006-05-12	Alain Quirion			Supprimer les enregistrements liés à l’opération de la nouvelle table Un_TFR.
					ADX0000992	IA	2006-05-23	Alain Quirion			Supprimer les enregistrements liés à l’opération de la nouvelle table Un_OUT.
					ADX0001100	IA	2006-10-24	Alain Quirion			Supprimer les enregistrements liés à l’opération de la nouvelle table Un_TIO.
					ADX0001119	IA	2006-10-31	Alain Quirion			Ajout des messages d'erreur concernant les frais disponibles utilisés (-10 et -11)
					ADX0001235	IA	2007-02-14	Alain Quirion			Utilisation de dtRegStartDate pour la date de début de régime
					ADX0002404	BR	2007-04-27	Alain Quirion			On supprimera désormais les enregistrements 400 des PAE directement enpassant par l'OperID sans apsser par la CotiastionID
					ADX0002426	BR	2007-05-23	Bruno Lapointe			Gestion de la table Un_CESP.
					ADX0001355	IA	2007-06-06	Alain Quirion			Modification de la date d’entrée en vigueur TIN (dtInforceDateTIN) 
																		de la convention et du groupe d’unités s’il y a lieu.
									2010-03-29	Jean-François Gauthier	Utilisation de FN_CRQ_DateNoTime afin d'enlever les heures/min/sec sur dtRegStartDate
									2010-09-01  Danielle Côté			Ajout du traitement pour les types d'opérations RDI                           
									2011-01-31	Frederick Thibault	    Ajout du champ fACESGPart pour régler le problème SCEE+
									2014-04-24	Pierre-Luc Simard	    Ajout de la gestion des statuts des conventions et des groupes d'unités pour les PAE et les RIN (Refonte)
									2014-10-08	Pierre-Luc Simard	    Ne pas permettre la suppression si une demande de dépôt direct a été faite, peu importe son statut
                                    2017-10-20  Pierre-Luc Simard       Mettre la bourse au statut Annulé (ANL) au lieu des Admissible (ADM)
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_Operation] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@OperIDs VARCHAR(8000)) -- Liste des IDs des opérations séparés par des virgules
AS
BEGIN
	DECLARE
		@iResult INTEGER,
		@dtOtherConvention DATETIME,
		@UnitID INTEGER,
		@ConventionID INTEGER,
		@dtMinUnitInforceDateTIN DATETIME,
		@iUnitID INTEGER,
		@vcUnitIDs VARCHAR(8000)
	
	SET @iResult = 1

	CREATE TABLE #OperToDel (
		OperID INTEGER PRIMARY KEY)

	INSERT INTO #OperToDel (OperID)
		SELECT 
			Val
		FROM dbo.FN_CRQ_IntegerTable(@OperIDs)
		WHERE Val NOT IN (-- Ne pas permettre la suppression lors qu'une DDD a déjà été faite
			SELECT DISTINCT
				IdOperationFinanciere
			FROM DecaissementDepotDirect DDD 
			WHERE DDD.IdOperationFinanciere = Val
			)
        	
	-- Insère les opérations reliés des remboursements intégraux qui ne sont pas dans la liste(@OperIDs)
	INSERT INTO #OperToDel
		SELECT
			IRO2.OperID
		FROM #OperToDel OT
		JOIN Un_IntReimbOper IRO ON IRO.OperID = OT.OperID
		JOIN Un_IntReimbOper IRO2 ON IRO2.IntReimbID = IRO.IntReimbID AND IRO2.OperID <> IRO.OperID
		LEFT JOIN #OperToDel OT2 ON OT2.OperID = IRO2.OperID
		WHERE OT2.OperID IS NULL
			AND IRO2.OperID NOT IN (-- Ne pas permettre la suppression lors qu'une DDD a déjà été faite
				SELECT DISTINCT
					IdOperationFinanciere
				FROM DecaissementDepotDirect DDD 
				WHERE DDD.IdOperationFinanciere = IRO2.OperID
				)

	IF EXISTS (	SELECT * 
			FROM #OperToDel OD
			JOIN Un_Oper O ON O.OperID = OD.OperID
			WHERE O.OperTypeID = 'TIN')
	BEGIN	
		-- Insère les opérations liées du transfert interne (OUT)
		INSERT INTO #OperToDel
			SELECT
				T.iOUTOperID
			FROM #OperToDel OT
			JOIN Un_TIO T ON T.iTINOperID = OT.OperID		
			LEFT JOIN #OperToDel OT2 ON OT2.OperID = T.iOUTOperID
			WHERE OT2.OperID IS NULL
				AND T.iOUTOperID NOT IN (-- Ne pas permettre la suppression lors qu'une DDD a déjà été faite
					SELECT DISTINCT
						IdOperationFinanciere
					FROM DecaissementDepotDirect DDD 
					WHERE DDD.IdOperationFinanciere = T.iOUTOperID
					)
	
		-- Insère les opérations liées du transfert interne (TFR)
		INSERT INTO #OperToDel
			SELECT
				T.iTFROperID
			FROM #OperToDel OT
			JOIN Un_TIO T ON T.iTINOperID = OT.OperID		
			LEFT JOIN #OperToDel OT2 ON OT2.OperID = T.iTFROperID
			WHERE OT2.OperID IS NULL
				AND T.iTFROperID NOT IN (-- Ne pas permettre la suppression lors qu'une DDD a déjà été faite
					SELECT DISTINCT
						IdOperationFinanciere
					FROM DecaissementDepotDirect DDD 
					WHERE DDD.IdOperationFinanciere = T.iTFROperID
					)
	END
	ELSE IF EXISTS(	SELECT * 
			FROM #OperToDel OD
			JOIN Un_Oper O ON O.OperID = OD.OperID
			WHERE O.OperTypeID = 'OUT')
		OR EXISTS(	SELECT * 
				FROM #OperToDel OD
				JOIN Un_Oper O ON O.OperID = OD.OperID
				WHERE O.OperTypeID = 'TFR')
	BEGIN
		-- Insère les opérations reliés des transferts OUT qui ne sont pas dans la liste(@OperIDs)
		INSERT INTO #OperToDel
			SELECT
				DISTINCT Ct2.OperID
			FROM 
				#OperToDel OT
				JOIN Un_Cotisation Ct ON Ct.OperID = OT.OperID
				JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
				JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID  AND URC2.CotisationID <> URC.CotisationID
				JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
				LEFT JOIN #OperToDel OT2 ON OT2.OperID = Ct2.OperID
			WHERE OT2.OperID IS NULL
				AND Ct2.OperID NOT IN (-- Ne pas permettre la suppression lors qu'une DDD a déjà été faite
					SELECT DISTINCT
						IdOperationFinanciere
					FROM DecaissementDepotDirect DDD 
					WHERE DDD.IdOperationFinanciere = Ct2.OperID
					)

		-- Insère les opérations liées du transfert interne (TIN)
		INSERT INTO #OperToDel
			SELECT
				T.iTINOperID
			FROM #OperToDel OT
			JOIN Un_TIO T ON T.iOUTOperID = OT.OperID		
			LEFT JOIN #OperToDel OT2 ON OT2.OperID = T.iTINOperID
			WHERE OT2.OperID IS NULL		
				AND T.iTINOperID NOT IN (-- Ne pas permettre la suppression lors qu'une DDD a déjà été faite
					SELECT DISTINCT
						IdOperationFinanciere
					FROM DecaissementDepotDirect DDD 
					WHERE DDD.IdOperationFinanciere = T.iTINOperID
					)	
	END	
	ELSE IF EXISTS(	SELECT * 
			FROM #OperToDel OD
			JOIN Un_Oper O ON O.OperID = OD.OperID
			WHERE O.OperTypeID = 'RES')
	BEGIN
		-- Insère les opérations reliés des résiliations qui ne sont pas dans la liste(@OperIDs)
		INSERT INTO #OperToDel
			SELECT
				Ct2.OperID
			FROM #OperToDel OT
			JOIN Un_Cotisation Ct ON Ct.OperID = OT.OperID
			JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
			JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID  AND URC2.CotisationID <> URC.CotisationID
			JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
			LEFT JOIN #OperToDel OT2 ON OT2.OperID = Ct2.OperID	
			WHERE Ct2.OperID NOT IN (-- Ne pas permettre la suppression lors qu'une DDD a déjà été faite
				SELECT DISTINCT
					IdOperationFinanciere
				FROM DecaissementDepotDirect DDD 
				WHERE DDD.IdOperationFinanciere = Ct2.OperID
				)
	END

	-- Insère les opérations reliés des paiements de bourses qui ne sont pas dans la liste(@OperIDs)
	
	IF EXISTS (
			SELECT OT.OperID
			FROM #OperToDel OT 
			JOIN Un_Oper O ON O.OperID = OT.OperID
			JOIN Un_ScholarshipPmt SP ON SP.OperID = O.OperID
			WHERE O.OperTypeID IN ('PAE','RGC'))
		INSERT INTO #OperToDel
			SELECT
				O.OperID
			FROM #OperToDel OT
			JOIN Un_ScholarshipPmt SP ON SP.OperID = OT.OperID
			JOIN Un_ScholarshipPmt SP2 ON SP2.ScholarshipID = SP.ScholarshipID AND SP2.OperID <> SP.OperID
			JOIN Un_Oper O ON O.OperID = SP2.OperID AND O.OperTypeID IN ('PAE','RGC')
			LEFT JOIN #OperToDel OT2 ON OT2.OperID = O.OperID
			WHERE OT2.OperID IS NULL
				AND O.OperID NOT IN (-- Ne pas permettre la suppression lors qu'une DDD a déjà été faite
					SELECT DISTINCT
						IdOperationFinanciere
					FROM DecaissementDepotDirect DDD 
					WHERE DDD.IdOperationFinanciere = O.OperID
					)	

	-- -1 Erreur la date de l'opération n'est pas plus grande que la date de blocage 
	IF EXISTS (
			SELECT 
				O.OperID
			FROM Un_Oper O
			JOIN #OperToDel OD ON OD.OperID = O.OperID
			JOIN Un_Def D ON O.OperDate <= D.LastVerifDate) AND
			(@iResult = 1)
		SET @iResult = -1

	-- -2 Erreur l'opération fait partie d'un fichier bancaire
	IF EXISTS (
			SELECT 
				OB.OperID
			FROM Un_OperBankFile OB
			JOIN #OperToDel OD ON OD.OperID = OB.OperID) AND
			(@iResult = 1)
		SET @iResult = -2

	-- -3 Erreur l'opération fait partie d'un calcul d'intérêt
	IF EXISTS (
			SELECT 
				IR.OperID
			FROM Un_InterestRate IR
			JOIN #OperToDel OD ON OD.OperID = IR.OperID) AND
			(@iResult = 1)
		SET @iResult = -3
	
	-- -6 Erreur l'opération fait partie d'un fichier de retour de la banque
	IF EXISTS (
			SELECT 
				BRL.BankReturnSourceCodeID
			FROM Mo_BankReturnLink BRL
			JOIN #OperToDel OD ON OD.OperID = BRL.BankReturnSourceCodeID
			WHERE BRL.BankReturnFileID IS NOT NULL) AND
			(@iResult = 1)
		SET @iResult = -6

	-- -7 Erreur l'opération est un NSF fesant partie d'un fichier de retour de la banque
	IF EXISTS (
			SELECT 
				BRL.BankReturnCodeID
			FROM Mo_BankReturnLink BRL
			JOIN #OperToDel OD ON OD.OperID = BRL.BankReturnCodeID
			WHERE BRL.BankReturnFileID IS NOT NULL) AND
			(@iResult = 1)
		SET @iResult = -7

	-- -8 Erreur l'opération a fait l'objet d'une annulation financière
	IF EXISTS (
			SELECT 
				OC.OperID
			FROM Un_OperCancelation OC
			JOIN #OperToDel OD ON OD.OperID = OC.OperSourceID) AND
			(@iResult = 1)
		SET @iResult = -8

	-- -9 Erreur l'opération a été expédié à la PCEE
	IF EXISTS (
			SELECT 
				G4.OperID
			FROM Un_CESP400 G4
			JOIN #OperToDel OD ON OD.OperID = G4.OperID
			WHERE G4.iCESPSendFileID IS NOT NULL) AND
			(@iResult = 1)
		SET @iResult = -9

	-- -10 Erreur : Une opération de résiliation ne peut être supprimée lorsque qu’un transfert de frais utilise les frais associés aux unités résiliées. 
	IF EXISTS(
			SELECT
				A.OperID
			FROM Un_AvailableFeeUse A
			JOIN Un_UnitReduction UR ON UR.UnitReductionID = A.UnitReductionID
			JOIN Un_UnitReductionCotisation URC ON URC.UnitReductionID = UR.UnitReductionID
			JOIN Un_Cotisation CT ON CT.CotisationID = URC.CotisationID
			JOIN Un_Oper OP ON OP.OperID = CT.OperID
			JOIN #OperToDel OD ON OD.OperID = OP.OperID
			LEFT JOIN #OperToDel OD2 ON OD.OperID = A.OperID
			WHERE OP.OperTypeID = 'RES'
				AND A.OperID NOT IN (SELECT * FROM #OperToDel) -- Le TFR n'est pas dans les opérations a supprimé
			)
			SET @iResult = -10

	-- -11 Erreur : Une opération de transfert OUT ne peut être supprimée lorsque qu’un transfert de frais utilise les frais associés aux unités résiliées.
	IF EXISTS(
			SELECT
				A.OperID
			FROM Un_AvailableFeeUse A
			JOIN Un_UnitReduction UR ON UR.UnitReductionID = A.UnitReductionID
			JOIN Un_UnitReductionCotisation URC ON URC.UnitReductionID = UR.UnitReductionID
			JOIN Un_Cotisation CT ON CT.CotisationID = URC.CotisationID
			JOIN Un_Oper OP ON OP.OperID = CT.OperID
			JOIN #OperToDel OD ON OD.OperID = OP.OperID
			LEFT JOIN #OperToDel OD2 ON OD.OperID = A.OperID
			WHERE OP.OperTypeID = 'OUT'
				AND A.OperID NOT IN (SELECT * FROM #OperToDel)	-- Le TFR n'est pas dans les opérations a supprimé
			)
			SET @iResult = -11

	-- -29 Un chèque a été émis
	IF EXISTS (
		SELECT OT.OperID
		FROM #OperToDel OT
		JOIN Un_OperLinkToCHQOperation CO ON CO.OperID = OT.OperID
		JOIN CHQ_OperationDetail OD ON OD.iOperationID = CO.iOperationID
		JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
		JOIN CHQ_Check C ON C.iCheckID = COD.iCheckID
		WHERE C.iCheckStatusID NOT IN (3,5) -- Pas refusé ou annulé
		)
		SET @iResult = -29

	-- -30 Opération barrée par le module des chèques
	IF EXISTS (
		SELECT OT.OperID
		FROM #OperToDel OT
		JOIN Un_OperLinkToCHQOperation CO ON CO.OperID = OT.OperID
		JOIN CHQ_OperationLocked OL ON OL.iOperationID = CO.iOperationID
		)
		SET @iResult = -30

	IF @iResult = 1
	BEGIN
		-----------------
		BEGIN TRANSACTION
		-----------------

		-- Crée une chaîne de caractère avec tout les groupes d'unités affectés par la suppression d'un PAE ou d'un RIN
		-- Procédure TT_UN_ConventionAndUnitStateForUnit appelée à la fin du traitement
        DECLARE UnitIDs CURSOR
        FOR
            SELECT DISTINCT 
                U.UnitID
            FROM #OperToDel OD
            JOIN Un_Oper O ON O.OperID = OD.OperID
            JOIN Un_ScholarshipPmt SP ON SP.OperID = O.OperID
            JOIN Un_Scholarship S ON S.ScholarshipID = SP.ScholarshipID
            JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
            JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
            WHERE O.OperTypeID = 'PAE'
            UNION 				
            SELECT DISTINCT
				CT.UnitID
			FROM #OperToDel OD 
			JOIN Un_Oper O ON O.OperID = OD.OperID
			JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
			WHERE O.OperTypeID = 'RIN'
        OPEN UnitIDs
        FETCH NEXT FROM UnitIDs
		INTO @iUnitID
        SET @vcUnitIDs = ''
        WHILE (@@FETCH_STATUS = 0) 
            BEGIN
                SET @vcUnitIDs = @vcUnitIDs + CAST(@iUnitID AS VARCHAR(30)) + ','
                FETCH NEXT FROM UnitIDs
			INTO @iUnitID
            END
        CLOSE UnitIDs
        DEALLOCATE UnitIDs

		-- Mise à jour du groupe d'unités dans le cas d'opération de type RIN
		UPDATE dbo.Un_Unit 
		SET IntReimbDate = NULL
		FROM dbo.Un_Unit 
		JOIN Un_IntReimb I ON I.UnitID = Un_Unit.UnitID
		JOIN Un_IntReimbOper IRO ON IRO.IntReimbID = I.IntReimbID
		JOIN #OperToDel OD ON OD.OperID = IRO.OperID

		IF @@ERROR <> 0
			SET @iResult = -12

		-- Retourne à l'étape #5
		IF @iResult = 1
		BEGIN
			INSERT INTO Un_ScholarshipStep (
					ScholarshipID,
					iScholarshipStep,
					dtScholarshipStepTime,
					ConnectID )
				SELECT DISTINCT
					S.ScholarshipID,
					4,
					GETDATE(),
					@ConnectID
				FROM Un_Scholarship S
				JOIN Un_ScholarshipPmt SP ON SP.ScholarshipID = S.ScholarshipID
				JOIN Un_ScholarshipStep SS ON SS.ScholarshipID = S.ScholarshipID AND SS.iScholarshipStep = 5
				JOIN Un_Oper O ON O.OperID = SP.OperID
				JOIN #OperToDel OD ON OD.OperID = O.OperID
				WHERE O.OperTypeID = 'PAE'

			-- Erreur lors de l'insertion d'une étape de PAE.
			IF @@ERROR <> 0
				SET @iResult = -29
		END

		-- Retourne à l'étape #4
		IF @iResult = 1
		BEGIN
			INSERT INTO Un_IntReimbStep (
					UnitID,
					iIntReimbStep,
					dtIntReimbStepTime,
					ConnectID )
				SELECT DISTINCT
					Ct.UnitID,
					3,
					GETDATE(),
					@ConnectID
				FROM Un_Cotisation Ct
				JOIN Un_IntReimbStep IRS ON IRS.UnitID = Ct.UnitID AND IRS.iIntReimbStep = 4
				JOIN Un_Oper O ON O.OperID = Ct.OperID
				JOIN #OperToDel OD ON OD.OperID = O.OperID
				WHERE O.OperTypeID = 'RIN'

			-- Erreur lors de l'insertion d'une étape de RIN.
			IF @@ERROR <> 0
				SET @iResult = -30
		END

		-- Suppression des historiques de remboursement intégral
		IF @iResult = 1
		BEGIN
			SELECT DISTINCT
				IRO.IntReimbID
			INTO #IntReimbToDel
			FROM Un_IntReimbOper IRO
			JOIN #OperToDel OD ON OD.OperID = IRO.OperID
			
			DELETE Un_IntReimbOper
			FROM Un_IntReimbOper
			JOIN #IntReimbToDel IRD ON IRD.IntReimbID = Un_IntReimbOper.IntReimbID

			DELETE Un_IntReimb
			FROM Un_IntReimb
			JOIN #IntReimbToDel IRD ON IRD.IntReimbID = Un_IntReimb.IntReimbID

			IF @@ERROR <> 0
				SET @iResult = -13
		END

		-- Mise à jour des groupes d'unités dans le cas de résiliation ou transfert OUT
		IF @iResult = 1
		BEGIN
			UPDATE dbo.Un_Unit 
			SET 
				TerminatedDate = NULL,
				UnitQty = Un_Unit.UnitQty + UR.UnitQty
			FROM dbo.Un_Unit 
			JOIN Un_UnitReduction UR ON UR.UnitID = Un_Unit.UnitID
			JOIN Un_UnitReductionCotisation URC ON URC.UnitReductionID = UR.UnitReductionID
			JOIN Un_Cotisation Ct ON Ct.CotisationID = URC.CotisationID
			JOIN #OperToDel OD ON OD.OperID = Ct.OperID

			IF @@ERROR <> 0
				SET @iResult = -14
		END

		-- Supprime les enregistrements 400 d'annulation non-expédiés du PRD ou du CHQ revenu NSF, AJU
		IF @iResult = 1
		BEGIN
			DELETE Un_CESP400
			FROM Un_CESP400
			JOIN Un_Cotisation Ct ON Un_CESP400.CotisationID = Ct.CotisationID
			JOIN Mo_BankReturnLink BL ON BL.BankReturnSourceCodeID = Ct.OperID
			JOIN #OperToDel OD ON BL.BankReturnCodeID = OD.OperID
			WHERE Un_CESP400.iCESPSendFileID IS NULL -- Pas expédié
				AND Un_CESP400.iReversedCESP400ID IS NULL -- Est une annulation

			IF @@ERROR <> 0
				SET @iResult = 15
		END

		-- Supprime les frais disponibles utilisés lié au TFR supprimé
		IF @iResult = 1
		BEGIN
			DELETE Un_AvailableFeeUse
			FROM Un_AvailableFeeUse
			JOIN #OperToDel OD ON OD.OperID = Un_AvailableFeeUse.OperID
			JOIN Un_Oper O ON O.OperID = Un_AvailableFeeUse.OperID
			WHERE O.OperTypeID = 'TFR'

			IF @@ERROR <> 0
				SET @iResult = -16
		END

		-- Insère les enregistrements 400 de demande sur le PRD ou le CHQ qui était revenu NSF
		IF @iResult = 1
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
				FROM #OperToDel OD
				JOIN Mo_BankReturnLink BL ON BL.BankReturnCodeID = OD.OperID
				JOIN Un_Cotisation Ct ON BL.BankReturnSourceCodeID = Ct.OperID
				JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
				JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
				LEFT JOIN (
					SELECT 
						C.ConventionID,
						EffectDate = dbo.FN_CRQ_DateNoTime(C.dtRegStartDate)
					FROM (
						SELECT DISTINCT
							U.ConventionID
						FROM #OperToDel OD
						JOIN Mo_BankReturnLink BL ON BL.BankReturnCodeID = OD.OperID
						JOIN Un_Cotisation Ct ON BL.BankReturnSourceCodeID = Ct.OperID
						JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
						) V
					JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
					WHERE C.dtRegStartDate IS NOT NULL					
					GROUP BY 
						C.ConventionID,
						C.dtRegStartDate
					) FCB ON FCB.ConventionID = C.ConventionID AND FCB.EffectDate > Ct.EffectDate
				WHERE ISNULL(HB.SocialNumber,'') <> '' -- Pas dans un compte bloqué
					AND ISNULL(HS.SocialNumber,'') <> '' -- Pas dans un compte bloqué
					AND FCB.ConventionID IS NULL -- Pas dans un compte bloqué
					AND Ct.CotisationID NOT IN (
							-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
							SELECT Ct.CotisationID
							FROM #OperToDel OD
							JOIN Mo_BankReturnLink BL ON BL.BankReturnCodeID = OD.OperID
							JOIN Un_Cotisation Ct ON BL.BankReturnSourceCodeID = Ct.OperID
							JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
							LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
							WHERE G4.iCESP800ID IS NULL -- Pas revenu en erreur
								AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
								AND R4.iCESP400ID IS NULL -- Pas annulé
							)

			IF @@ERROR <> 0 
				SET @iResult = -17
		END

		IF @iResult = 1
		BEGIN
			-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
			UPDATE Un_CESP400
			SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
			WHERE vcTransID = 'FIN' 

			IF @@ERROR <> 0
				SET @iResult = -18
		END
		
		-- Suppression des subventions
		IF @iResult = 1
		BEGIN
			DELETE Un_CESP
			FROM Un_CESP
			JOIN #OperToDel OD ON OD.OperID = Un_CESP.OperID

			IF @@ERROR <> 0
				SET @iResult = -19
		END

		-- Supprime les enregistrements 400 non-expédiés (d'autres seront insérés pour les remplacer)
		IF @iResult > 0
		BEGIN
			DELETE Un_CESP400
			FROM Un_CESP400
			JOIN Un_Cotisation Ct ON Un_CESP400.CotisationID = Ct.CotisationID
			JOIN #OperToDel OD ON OD.OperID = Ct.OperID
			WHERE Un_CESP400.iCESPSendFileID IS NULL

			IF @@ERROR <> 0
				SET @iResult = -20
		END

		-- Supprime les enregistrements 400 des PAE
		IF @iResult > 0
		BEGIN
			DELETE Un_CESP400
			FROM Un_CESP400
			JOIN Un_Oper O ON Un_CESP400.OperID = O.OperID
			JOIN #OperToDel OD ON OD.OperID = O.OperID
			WHERE Un_CESP400.iCESPSendFileID IS NULL
					AND O.OperTypeID = 'PAE'

			IF @@ERROR <> 0
				SET @iResult = -20
		END

		-- Suppression d'exceptions de commissions générées lors de résiliation ou transfert OUT
		IF @iResult = 1
		BEGIN
			DELETE Un_UnitReductionRepException
			FROM Un_UnitReductionRepException
			JOIN Un_UnitReductionCotisation URC ON URC.UnitReductionID = Un_UnitReductionRepException.UnitReductionID
			JOIN Un_Cotisation Ct ON Ct.CotisationID = URC.CotisationID
			JOIN #OperToDel OD ON OD.OperID = Ct.OperID

			IF @@ERROR <> 0
				SET @iResult = -21
		END

		IF EXISTS (
				SELECT DISTINCT
					URC.UnitReductionID
				FROM Un_UnitReductionCotisation URC 
				JOIN Un_Cotisation Ct ON Ct.CotisationID = URC.CotisationID
				JOIN #OperToDel OD ON OD.OperID = Ct.OperID) AND
			(@iResult = 1)
		BEGIN
			SELECT DISTINCT
				URC.UnitReductionID
			INTO #UnitReductionToDel
			FROM Un_UnitReductionCotisation URC 
			JOIN Un_Cotisation Ct ON Ct.CotisationID = URC.CotisationID
			JOIN #OperToDel OD ON OD.OperID = Ct.OperID

			-- Suppression des liens entres les historiques de résiliations et les opérations
			DELETE Un_UnitReductionCotisation
			FROM Un_UnitReductionCotisation
			JOIN Un_Cotisation Ct ON Ct.CotisationID = Un_UnitReductionCotisation.CotisationID
			JOIN #OperToDel OD ON OD.OperID = Ct.OperID

			IF @@ERROR <> 0
				SET @iResult = -22
	
			-- Suppression des historiques de résiliations
			IF @iResult = 1
			BEGIN
				DELETE Un_UnitReduction
				FROM Un_UnitReduction
				JOIN #UnitReductionToDel UR ON UR.UnitReductionID = Un_UnitReduction.UnitReductionID
				LEFT JOIN Un_UnitReductionCotisation URC ON URC.UnitReductionID = Un_UnitReduction.UnitReductionID
				WHERE URC.UnitReductionID IS NULL

				IF @@ERROR <> 0
					SET @iResult = -23
			END
	
			DROP TABLE #UnitReductionToDel
		END

		-- Suppression des informations sur les transferts externes
		IF @iResult = 1
		BEGIN
			DELETE Un_ExternalTransfert
			FROM Un_ExternalTransfert
			JOIN Un_Cotisation Ct ON Ct.CotisationID = Un_ExternalTransfert.CotisationID
			JOIN #OperToDel OD ON OD.OperID = Ct.OperID

			IF @@ERROR <> 0
				SET @iResult = -24
		END

		-- Suppression des informations sur les transferts IN
		IF @iResult = 1
		BEGIN
			DELETE Un_TIN
			FROM Un_TIN
			JOIN #OperToDel OD ON OD.OperID = Un_TIN.OperID

			IF @@ERROR <> 0
				SET @iResult = -25
		END

		-- Suppression des informations sur les transferts de frais TFR
		IF @iResult = 1
		BEGIN
			DELETE Un_TFR
			FROM Un_TFR
			JOIN #OperToDel OD ON OD.OperID = Un_TFR.OperID

			IF @@ERROR <> 0
				SET @iResult = -26
		END
		-- Suppression des informations sur les transferts OUT
		IF @iResult = 1
		BEGIN
			DELETE Un_OUT
			FROM Un_OUT
			JOIN #OperToDel OD ON OD.OperID = Un_OUT.OperID

			IF @@ERROR <> 0
				SET @iResult = -27
		END
		-- Suppression des informations sur les transferts TIO
		IF @iResult = 1
		BEGIN
			DELETE Un_TIO
			FROM Un_TIO
			JOIN #OperToDel OD1 ON OD1.OperID = Un_TIO.iOUTOperID
			JOIN #OperToDel OD2 ON OD2.OperID = Un_TIO.iTINOperID

			IF @@ERROR <> 0
				SET @iResult = -28
		END

		--Mise à jour de la date TIN du groupe d'unités et de la convention
		IF @iResult = 1	
		BEGIN
			--Va chercher la date minimale des TIN restants après la suppresion
			SELECT  
					@UnitID = U.UnitID,
					@ConventionID = U.ConventionID,
					@dtOtherConvention = MIN(T.dtOtherConvention)
			FROM #OperToDel OD
			JOIN Un_Oper O1 ON O1.OperID = OD.OperID
			JOIN Un_Cotisation Ct1 ON Ct1.OperID = O1.OperID
			JOIN dbo.Un_Unit U ON U.UnitID = Ct1.UnitID
			JOIN Un_Cotisation Ct2 ON Ct2.UnitID = U.UnitID
			JOIN Un_Oper O2 ON O2.OperID = Ct2.OperID
			LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O2.OperID
			LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O2.OperID
			LEFT JOIN Un_TIN T ON T.OperID = O2.OperID -- Vérifie s'il reste des opération TIN autre que celle supprimée
			WHERE O1.OperTypeID = 'TIN'
				AND OC1.OperID IS NULL --N'est pas une annulation
				AND OC2.OperID IS NULL --N'a pas été annulé
			GROUP BY U.UnitID, U.ConventionID

			UPDATE dbo.Un_Unit 
			SET dtInforceDateTIN = @dtOtherConvention
			WHERE UnitID = @UnitID

			IF @@ERROR <> 0
				SET @iResult = -44

			SELECT @dtMinUnitInforceDateTIN = MIN(U.dtInforceDateTIN)					
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			WHERE C.ConventionID = @ConventionID
					AND U.dtInforceDateTIN IS NOT NULL
			GROUP BY C.ConventionID
				
			UPDATE dbo.Un_Convention 
			SET dtInforceDateTIN = @dtMinUnitInforceDateTIN
			WHERE ConventionID = @ConventionID

			IF @@ERROR <> 0
				SET @iResult = -45
		END
		
		-- Suppression des cotisations
		IF @iResult = 1
		BEGIN
			DELETE Un_Cotisation
			FROM Un_Cotisation 
			JOIN #OperToDel OD ON OD.OperID = Un_Cotisation.OperID

			IF @@ERROR <> 0
				SET @iResult = -31
		END

		-- Suppression des opérations dans le compte GUI pour l'opération
		IF @iResult = 1
		BEGIN
			DELETE Un_OtherAccountOper
			FROM Un_OtherAccountOper
			JOIN #OperToDel OD ON OD.OperID = Un_OtherAccountOper.OperID

			IF @@ERROR <> 0
				SET @iResult = -32
		END

		-- Suppression des opérations sur convention pour l'opération
		IF @iResult = 1
		BEGIN
			DELETE Un_ConventionOper
			FROM Un_ConventionOper
			JOIN #OperToDel OD ON OD.OperID = Un_ConventionOper.OperID

			IF @@ERROR <> 0
				SET @iResult = -33
		END

		-- Suppression des opérations sur plan pour l'opération
		IF @iResult = 1
		BEGIN
			DELETE Un_PlanOper
			FROM Un_PlanOper
			JOIN #OperToDel OD ON OD.OperID = Un_PlanOper.OperID

			IF @@ERROR <> 0
				SET @iResult = -34
		END

		-- Suppression des liens d'annulations financières
		IF @iResult = 1
		BEGIN
			DELETE Un_OperCancelation
			FROM Un_OperCancelation
			JOIN #OperToDel OD ON OD.OperID = Un_OperCancelation.OperID

			IF @@ERROR <> 0
				SET @iResult = -35
		END

		-- Suppression des suggestions de chèques
		IF @iResult = 1
		BEGIN
			DELETE Un_ChequeSuggestion
			FROM Un_ChequeSuggestion
			JOIN #OperToDel OD ON OD.OperID = Un_ChequeSuggestion.OperID

			IF @@ERROR <> 0
				SET @iResult = -36
		END
	
		-- Suppression des liens d'effets retournées
		IF @iResult = 1
		BEGIN
			DELETE Mo_BankReturnLink
			FROM Mo_BankReturnLink
			JOIN #OperToDel OD ON Mo_BankReturnLink.BankReturnCodeID = OD.OperID
			WHERE Mo_BankReturnLink.BankReturnFileID IS NULL

			IF @@ERROR <> 0
				SET @iResult = -37
		END

		-- Suppression des raisons de retrait
		IF @iResult = 1
		BEGIN
			DELETE Un_WithdrawalReason
			FROM Un_WithdrawalReason
			JOIN #OperToDel OD ON OD.OperID = Un_WithdrawalReason.OperID

			IF @@ERROR <> 0
				SET @iResult = -38
		END

		-- Remet le status à jour de la bourse lors de la suppression du PAE.
		IF @iResult = 1
		BEGIN
			UPDATE Un_Scholarship
			SET
				ScholarshipStatusID = 'ANL'--'ADM'
			FROM Un_Scholarship
			JOIN Un_ScholarshipPmt P ON P.ScholarshipID = Un_Scholarship.ScholarshipID
			JOIN #OperToDel OD ON OD.OperID = P.OperID
			JOIN Un_Oper O ON O.OperID = OD.OperID
			WHERE O.OperTypeID = 'PAE'

			IF @@ERROR <> 0
				SET @iResult = -39
		END

		-- Conserve les ScholarshipID à supprimer
		IF @iResult = 1
		BEGIN
			CREATE TABLE #ScholarshipToDel (
				ScholarshipID INTEGER PRIMARY KEY)
		
			INSERT INTO #ScholarshipToDel (ScholarshipID)
				SELECT DISTINCT
					S.ScholarshipID
				FROM #OperToDel OD
				JOIN Un_ScholarshipPmt SP ON OD.OperID = SP.OperID
				JOIN Un_Scholarship S ON S.ScholarshipID = SP.ScholarshipID
				JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
				JOIN Un_Plan P ON P.PlanID = C.PlanID
				WHERE P.PlanTypeID = 'IND'
		END

		-- Suppression des paiements de bourses
		IF @iResult = 1
		BEGIN
			DELETE Un_ScholarshipPmt
			FROM Un_ScholarshipPmt
			JOIN #OperToDel OD ON OD.OperID = Un_ScholarshipPmt.OperID

			IF @@ERROR <> 0
				SET @iResult = -40
		END

		-- Suppression de bourses
		IF @iResult = 1
		BEGIN
			DELETE Un_Scholarship
			FROM Un_Scholarship
			JOIN #ScholarshipToDel SD ON SD.ScholarshipID = Un_Scholarship.ScholarshipID

			DROP TABLE #ScholarshipToDel

			IF @@ERROR <> 0
				SET @iResult = -41
		END

		-- Marque supprimé les opérations du modules des chèques attachés aux opérations supprimées
		IF @iResult = 1
		AND EXISTS (
			SELECT
				L.iOperationID
			FROM #OperToDel OD 
			JOIN Un_OperLinkToCHQOperation L ON OD.OperID = L.OperID
			)
		BEGIN	
			DECLARE
				@iOperationID INTEGER,
				@iConnectID INTEGER,
				@dtOperation DATETIME,
				@vcDescription VARCHAR(100),
				@vcRefType VARCHAR(10),
				@vcAccount VARCHAR(75)

			DECLARE crCHQ_OperationDel CURSOR
			FOR
				SELECT
					O.iOperationID,
					O.iConnectID,
					O.dtOperation,
					O.vcDescription,
					O.vcRefType,
					O.vcAccount
				FROM #OperToDel OD 
				JOIN Un_OperLinkToCHQOperation L ON OD.OperID = L.OperID
				JOIN CHQ_Operation O ON O.iOperationID = L.iOperationID

			OPEN crCHQ_OperationDel

			FETCH NEXT FROM crCHQ_OperationDel
			INTO
				@iOperationID,
				@iConnectID,
				@dtOperation,
				@vcDescription,
				@vcRefType,
				@vcAccount

			WHILE @@FETCH_STATUS = 0 AND @iResult = 1
			BEGIN
				-- Modifie (marque supprimé) les opérations dans la gestion des chèques (CHQ_Operation)
				EXECUTE @iOperationID = IU_CHQ_Operation 0, @iOperationID, 1, @iConnectID, @dtOperation, @vcDescription, @vcRefType, @vcAccount

				IF @iOperationID <= 0
					SET @iResult = -31

				FETCH NEXT FROM crCHQ_OperationDel
				INTO
					@iOperationID,
					@iConnectID,
					@dtOperation,
					@vcDescription,
					@vcRefType,
					@vcAccount
			END

			CLOSE crCHQ_OperationDel
			DEALLOCATE crCHQ_OperationDel
		END
      
     -- Dépots informatisés
      IF @iResult = 1
      BEGIN
         DECLARE
            @iID_RDI_Paiement INT
           ,@iID_RDI_Depot    INT
 
         -- Ajustement des statuts des dépôts
         DECLARE curRDI_Liens CURSOR FOR
         SELECT iID_RDI_Paiement
           FROM tblOPER_RDI_Liens L
           JOIN #OperToDel OD ON OD.OperID = L.OperID

         OPEN curRDI_Liens
         FETCH NEXT FROM curRDI_Liens INTO @iID_RDI_Paiement
         WHILE @@FETCH_STATUS = 0
         BEGIN

            IF @iID_RDI_Paiement > 0
            BEGIN
               SELECT @iID_RDI_Depot = iID_RDI_Depot
                 FROM tblOPER_RDI_Paiements 
                WHERE iID_RDI_Paiement = @iID_RDI_Paiement

               IF @iID_RDI_Depot > 0
                  EXECUTE [dbo].[psOPER_RDI_ModifierStatutDepot] @iID_RDI_Depot
               
            END
            FETCH NEXT FROM curRDI_Liens INTO @iID_RDI_Paiement

         END
         CLOSE curRDI_Liens
         DEALLOCATE curRDI_Liens

         -- Suppression du lien entre l'opération et le paiement
         DELETE tblOPER_RDI_Liens
           FROM tblOPER_RDI_Liens L
           JOIN #OperToDel OD ON OD.OperID = L.OperID

         IF @@ERROR <> 0
            SET @iResult = -46

      END      

		-- Suppression du lien entre l'opération du système de convention et l'opération du module des chèques
		IF @iResult = 1
		BEGIN
			DELETE Un_OperLinkToCHQOperation
			FROM Un_OperLinkToCHQOperation
			JOIN #OperToDel OD ON OD.OperID = Un_OperLinkToCHQOperation.OperID

			IF @@ERROR <> 0
				SET @iResult = -42
		END		

		-- Suppression de l'opération
		IF @iResult = 1
		BEGIN
			DELETE Un_Oper
			FROM Un_Oper
			JOIN #OperToDel OD ON OD.OperID = Un_Oper.OperID

			IF @@ERROR <> 0
				SET @iResult = -43
		END

		-- Mise à jour des états de conventions et unités
		IF @iResult = 1 AND ISNULL(@vcUnitIDs, '') <> '' 
			EXECUTE TT_UN_ConventionAndUnitStateForUnit @vcUnitIDs 
		
		IF @iResult = 1
			------------------
			COMMIT TRANSACTION
			------------------
		ELSE
			--------------------
			ROLLBACK TRANSACTION
			--------------------
	END
	
	RETURN @iResult
END