/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_CLB
Description         :	Crée les opérations BEC
Valeurs de retours  :	>0  :	Tout à fonctionné
                     	<=0 :	Erreur SQL
Note                :	
	ADX0002077	BR	2006-09-05	Bruno Lapointe		BEC génère des commissions.
	ADX0002152	BR	2007-02-02	Alain Quirion		Annuler le BEC si nécessaire
	ADX0001235	IA	2007-02-14	Alain Quirion		Utilisation de dtRegStartDate pour la date de début de régime
	ADX0002465	BR	2007-05-31	Bruno Lapointe		Correction du problème des annualtions de 400 qui
																se doublait quand il avait plus d'une 900 sur la 400 annulée.
	ADX0001277	UP	2008-02-04	Bruno Lapointe		Amélioration : Elle recréé les 400 de BEC si supprimé dans un autre 
																traitement (ex : TT_UN_CESPOfConvention). Redemande le BEC (400) quand
																on recoche la case à cocher BEC voulu.
	ADX0003172	UR	2008-06-23	Bruno Lapointe		Ne pas créer de BEC avant la date d'entrée en REEE (dtRegStartDate)
					2010-01-12	Jean-F.	Gauthier	Modification afin pouvoir traiter unitairement une convention (ajout d'un paramètre)
					2010-02-03	Pierre Paquet		Ajustement à la partie unitaire afin d'avoir un seul UnitID (Retirer le ActivationConnectID du group by).
					2010-03-03	Pierre Paquet		Dans la partie unitaire, réutiliser les OperId et CotisationID du BEC s'il existe.
					2010-04-16	Pierre Paquet		Récupérer les OperID et CotisationID BEC dès qu'ils existent.
					2010-04-21	Pierre Paquet		Ajustement à la partie unitaire pour la création du 400-24
					2010-05-04	Pierre Paquet		Correction: Utilisation de la date du jour plutôt que opération sur nouvelle 400-24.
					2010-05-10	Pierre Paquet		Ajout de la validation avec le NAS.
					2010-05-26	Pierre Paquet		Ajout de dbo.FN_CRQ_DateNoTime pour la dtRegStartDate.
					2010-05-27	Pierre Paquet		Correction: Ajout d'un ISNULL pour éviter un champ null dans UN_Oper.
					2010-06-01	Pierre Paquet		Retrait de la section sur les 'Renversements'.
					2010-07-05	Pierre Paquet		Ne pas recréer une nouvelle 400-24 si elle est en attente d'envoi.
					2010-08-12	Pierre Paquet		Correction sur le C4.ConventionID
					2010-08-12	Pierre Paquet		Correction: Ajout de la vérification complète des NAS.
					2010-11-25	Pierre Paquet		Correction: S'assurer qu'il n'y a pas de 400-24 en attente d'envoi SANS PR.
					2010-10-14	Frederick Thibault	Ajout du champ fACESGPart pour régler le problème SCEE+
					2014-08-11	Donald Huppé		La convention doit être REE (demande de G Komenda)
                    2017-04-27  Pierre-Luc Simard   Validation de l'état REE ajoutée à la création des 400 pour les opérations existantes
                    2018-04-04  Steeve Picard       Remplacement de la fonction «fnCONV_ObtenirStatutConventionEnDatePourTous» par «fntCONV_ObtenirStatutConventionEnDate_PourTous»
			exec TT_UN_CLB	
****************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_CLB]
	(
		@ConventionID	INT = NULL		-- ID de la convention (Traite la convention si présent)
	)
AS
BEGIN
	DECLARE
			@iOperID					INT
			,@dtToday					DATETIME
			,@iResult					INT
			,@iOperIDToReverse			INT
			,@iCotisationIDToReverse	INT
			,@ConnectID					INT

	DECLARE @tCLB TABLE 
					(
					ConventionID	INT PRIMARY KEY
					,iAddToOperID	INT IDENTITY
					,UnitID			INT NOT NULL
					,EffectDate		DATETIME NOT NULL
					,ConnectID		INT NOT NULL 
					)

	CREATE TABLE #tNoCLB 
					(
					ConventionID			INT PRIMARY KEY
					,iOperIDToReverse		INT
					,iCotisationIDToReverse INT
					,UnitID					INT NOT NULL
					,EffectDate				DATETIME NOT NULL
					,ConnectID				INT NOT NULL 
					)

	IF @ConventionID IS NULL
		BEGIN
			-- Initialise à a le résultat
			SET @iResult = 1
			-- Date du jour
			SET @dtToday = dbo.FN_CRQ_DateNoTime(GETDATE())

--			SET @iOperIDToReverse = 0
--			SET @iCotisationIDToReverse = 0

			INSERT INTO @tCLB (
					ConventionID,
					UnitID,
					EffectDate,
					ConnectID )
				SELECT DISTINCT
					V.ConventionID,
					V.UnitID,
					V.EffectDate,
					U.ActivationConnectID
				FROM (
					SELECT 
						C.ConventionID,
						UnitID = MIN(U.UnitID),
						EffectDate = -- Date d'entrée en vigueur de la convention pour le PCEE
							CASE 
							-- Avant le 1 janvier 2003 on envoi toujours la date d'entrée en vigueur de la convention
							WHEN C.dtRegStartDate < '2003-01-01' THEN C.dtRegStartDate
							-- La date d'entrée en vigueur de la convention est la récente c'est donc elle qu'on envoit
							WHEN C.dtRegStartDate > B.BirthDate THEN C.dtRegStartDate
							-- La date de naissance du bénéficiaire est la plus récente c'est donc elle qu'on envoit
							ELSE B.BirthDate		
						END
					FROM dbo.Un_Convention C 
					JOIN fntCONV_ObtenirStatutConventionEnDate_PourTous(NULL, NULL) CS ON CS.ConventionID = C.ConventionID
					JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID	
					JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
					WHERE C.bCLBRequested <> 0 -- BEC demandé
						AND C.tiCESPState IN (2,4) -- Pré-validation du BEC passe
                        AND CS.ConventionStateID = 'REE'
						AND (C.ConventionID NOT IN ( -- Convnetion ou le BEC est déjà traité.
								SELECT U.ConventionID
								FROM dbo.Un_Unit U
								JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
								JOIN Un_Oper O ON O.OperID = Ct.OperID
								WHERE O.OperTypeID = 'BEC'
								)
							OR C.ConventionID IN ( -- Convention ou le BEC a été annulé.
								SELECT C.ConventionID
								FROM dbo.Un_Convention C
								JOIN (	SELECT  C4.ConventionID,
												iCESP400ID = MAX(C4.iCESP400ID)
										FROM Un_CESP400 C4
										LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = C4.iCESP400ID
										WHERE C4.tiCESP400TypeID = 24
											AND C4.iCESP800ID IS NULL -- Pas revenu en erreur
											--AND C4.iReversedCESP400ID IS NULL -- Pas une annulation
											AND R4.iCESP400ID IS NULL -- Pas annulé																
										GROUP BY C4.ConventionID) V ON V.ConventionID = C.ConventionID
								JOIN Un_CESP400 C4 ON C4.iCESP400ID = V.iCESP400ID
								WHERE C4.bCESPDemand = 0	
										AND C4.iCESPSendFileID IS NOT NULL
								))

							 AND C.ConventionID NOT IN ( -- Convention avec demande en attente d'envoi
									SELECT C4.ConventionID -- CORRECTION 12-août-2010
									FROM UN_CESP400 C4
									WHERE C4.tiCESP400TypeID = 24
									AND C4.iCESPSendFileID IS NULL
									AND C4.bCESPDemand = 1)

						AND C.bSendToCESP <> 0 -- À envoyer au PCEE
						AND C.dtRegStartDate IS NOT NULL
						AND dbo.FN_CRQ_DateNoTime(C.dtRegStartDate) <= @dtToday -- Ne pas créer de BEC avant la date d'entrée en REEE
					GROUP BY 
						C.ConventionID,
						C.dtRegStartDate,
						B.BirthDate
					) V
				JOIN dbo.Un_Unit U ON U.UnitID = V.UnitID
				WHERE U.ActivationConnectID IS NOT NULL -- La loupe est enlevé.
				ORDER BY V.ConventionID

			-- Va chercher le dernier OperID avant l'insertion
			SET @iOperID = IDENT_CURRENT('Un_Oper')

			INSERT INTO Un_Oper (
					OperTypeID,
					OperDate,
					ConnectID )
				SELECT
					'BEC',
					@dtToday,
					ConnectID
				FROM @tCLB
				ORDER BY ConventionID

			IF @@ERROR <> 0
				SET @iResult = -1

			IF @iResult = 1
			BEGIN
				-- Insertion d'une nouvelle cotisation
				INSERT INTO Un_Cotisation (
						UnitID,
						OperID,
						EffectDate,
						Cotisation,
						Fee,
						BenefInsur,
						SubscInsur,
						TaxOnInsur )
					SELECT 
						UnitID,
						@iOperID+iAddToOperID,
						@dtToday,
						0,
						0,
						0,
						0,
						0
					FROM @tCLB

				IF @@ERROR <> 0
					SET @iResult = -2
			END

			IF @iResult = 1
			BEGIN
				INSERT INTO Un_CESP400 (
						OperID,
						CotisationID,
						ConventionID,
						tiCESP400TypeID,
						vcTransID,
						dtTransaction,
						iPlanGovRegNumber,
						ConventionNo,
						vcSubscriberSINorEN,
						vcBeneficiarySIN,
						fCotisation,
						bCESPDemand,
						fCESG,
						fACESGPart,
						fEAPCESG,
						fEAP,
						fPSECotisation,
						vcPCGSINorEN,
						vcPCGFirstName,
						vcPCGLastName,
						tiPCGType,
						fCLB,
						fEAPCLB,
						fPG,
						fEAPPG )
					SELECT
						Ct.OperID,
						Ct.CotisationID,
						C.ConventionID,
						24,
						'FIN',
						CASE
							WHEN DATEDIFF(YEAR, Ct.EffectDate, GETDATE()) >= 2 THEN dbo.FN_CRQ_DateNoTime(GETDATE())
						ELSE Ct.EffectDate
						END,
						P.PlanGovernmentRegNo,
						C.ConventionNo,
						HS.SocialNumber,
						HB.SocialNumber,
						0,
						C.bCLBRequested,
						0,
						0,
						0,
						0,
						0,
						B.vcPCGSINOrEN,
						B.vcPCGFirstName,
						B.vcPCGLastName,
						B.tiPCGType,
						0,
						0,
						0,
						0
					FROM Un_Cotisation Ct
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
					JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                    JOIN fntCONV_ObtenirStatutConventionEnDate_PourTous(NULL, NULL) CS ON CS.ConventionID = C.ConventionID
					JOIN Un_Plan P ON P.PlanID = C.PlanID
					JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
					JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
					JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
					-- S'assure que les informations ne sont pas les mêmes que les dernières expédiées
					WHERE O.OperTypeID = 'BEC'
                        AND CS.ConventionStateID = 'REE'
						AND C.bCLBRequested <> 0 -- BEC demandé
						AND C.tiCESPState IN (2,4) -- Pré-validation du BEC passe
						AND Ct.CotisationID NOT IN (
								-- Cotisation qui ont un enregistrement 400 expédié qui est valide.
								SELECT Ct.CotisationID
								FROM Un_Cotisation Ct
								JOIN Un_CESP400 G4 ON G4.CotisationID = Ct.CotisationID
								LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID AND R4.iCESP800ID IS NULL
								WHERE G4.tiCESP400TypeID = 24
									AND( G4.iCESP800ID IS NULL -- Pas revenu en erreur
										OR G4.iCESP800ID IN (SELECT iCESP800ID FROM Un_CESP800ToTreat) -- ou erreur pas traité
										)
									AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
									AND R4.iCESP400ID IS NULL -- Pas annulé
					)

				IF @@ERROR <> 0
					SET @iResult = -3
			END

			DROP TABLE #tNoCLB
			
			IF @iResult = 1
			BEGIN
				-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
				UPDATE Un_CESP400
				SET vcTransID = vcTransID+CAST(iCESP400ID AS VARCHAR(12))
				WHERE vcTransID = 'FIN' 

				IF @@ERROR <> 0
					SET @iResult = -4
			END

			----------------------------------------------------------------------
			-- Inscrire les infos du principal responsable s'il y en a à NULL   --
			----------------------------------------------------------------------
			IF @iResult = 1
			BEGIN
				UPDATE Un_CESP400
				SET 
					vcPCGSINorEN = B.vcPCGSINOrEN,
					vcPCGFirstName = B.vcPCGFirstName,	
					vcPCGLastName = B.vcPCGLastName,				
					tiPCGType = B.tiPCGType					
				FROM Un_CESP400
				JOIN dbo.Un_Convention C ON C.ConventionID = Un_CESP400.ConventionID
				JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
				WHERE 
					Un_CESP400.iCESPSendFileID IS NULL -- Transaction non-envoyée.
					AND
					Un_CESP400.tiCESP400TypeID = 24 -- Types 24 (BEC)
					AND (UN_CESP400.vcPCGSINorEN IS NULL OR UN_CESP400.vcPCGFirstName IS NULL OR UN_CESP400.vcPCGLastName IS NULL)

					IF @@ERROR <> 0
						SET @iResult = -5
			END
	END
	ELSE  -------------------------- 2010-01-12 : JFG : AJOUT DU TRAITEMENT UNITAIRE DE LA CONVENTION
		BEGIN
			-- Initialise à a le résultat
			SET @iResult = 1
			-- Date du jour
			SET @dtToday = dbo.FN_CRQ_DateNoTime(GETDATE())
			
			SET @iOperIDToReverse = 0
			SET @iCotisationIDToReverse = 0

			-- Récupérer le NAS du bénéficiaire de la convention
/*			DECLARE @vcNAS VARCHAR(30)
			SET @vcNAS =   (SELECT H.SocialNumber 
							FROM dbo.Mo_Human H 
							LEFT JOIN dbo.UN_Convention C 
								ON C.BeneficiaryID = H.HumanID 
							WHERE C.ConventionID = @ConventionID)
*/
			CREATE TABLE #NAS (vcNAS VARCHAR(30))
			INSERT INTO #NAS 
			SELECT SocialNumber 
			FROM dbo.UN_HumanSocialNumber 
			WHERE HumanID = (	SELECT BeneficiaryID 
								FROM dbo.UN_Convention 
								WHERE ConventionID = @ConventionID
							)
						
				-- Vérifier s'il y a un 400-24-1 dans UN_CESP400
				-- Si oui, alors il faut supprimer l'enregistrement 400-24 et en créer un nouveau 400-24 avec le OperID et CotisationID
				-- de la transaction que l'on supprime.
	
			IF EXISTS (	SELECT 1
						FROM dbo.UN_CESP400 C4 
						WHERE C4.ConventionID = @ConventionID
						AND C4.tiCESP400TypeID = 24
						--AND C4.vcBeneficiarySIN = @vcNAS)
						AND C4.vcBeneficiarySIN IN (SELECT vcNAS FROM #NAS))
				
				BEGIN --Existe déjà une 400-24.
					DECLARE @iID_OperIDBEC INT
					DECLARE @iID_CotisationIDBEC INT					
					
					-- Récupérer les valeurs de la transaction existante.
					SELECT TOP 1 @iID_OperIDBEC = C4.OperID, @iID_CotisationIDBEC = C4.CotisationID
					FROM dbo.UN_CESP400 C4
					--WHERE C4.iCESPSendFileID IS NULL  -- 2010-04-16 Pierre Paquet
						WHERE C4.ConventionID = @ConventionID
						AND C4.tiCESP400TypeID = 24
						AND C4.bCESPDemand = 1
						--AND C4.vcBeneficiarySIN = @vcNAS
						AND C4.vcBeneficiarySIN IN (SELECT vcNAS FROM #NAS)
					ORDER BY 1 DESC
					
					-- Suppression de la transaction en attente d'envoi si elle existe.
					DELETE FROM dbo.UN_CESP400 
					WHERE iCESPSendFileID IS NULL 
						AND ConventionID = @ConventionID
						AND tiCESP400TypeID = 24
						AND bCESPDemand = 1
						--AND vcBeneficiarySIN = @vcNAS
						AND vcBeneficiarySIN IN (SELECT vcNAS FROM #NAS)
			
					-- Création de la demande de BEC avec les anciennes valeurs de OperId et CotisationID
					INSERT INTO Un_CESP400 (
						OperID,
						CotisationID,
						ConventionID,
						tiCESP400TypeID,
						vcTransID,
						dtTransaction,
						iPlanGovRegNumber,
						ConventionNo,
						vcSubscriberSINorEN,
						vcBeneficiarySIN,
						fCotisation,
						bCESPDemand,
						fCESG,
						fACESGPart,
						fEAPCESG,
						fEAP,
						fPSECotisation,
						vcPCGSINorEN,
						vcPCGFirstName,
						vcPCGLastName,
						tiPCGType,
						fCLB,
						fEAPCLB,
						fPG,
						fEAPPG )
					SELECT
						@iID_OperIDBEC,
						@iID_CotisationIDBEC,
						C.ConventionID,
						24,
						'FIN',
					--	CASE
					--		WHEN DATEDIFF(YEAR, Ct.EffectDate, GETDATE()) >= 2 THEN dbo.FN_CRQ_DateNoTime(GETDATE())
					--	ELSE Ct.EffectDate
					--	END,
						@dtToday, -- 2010-05-04 Pierre Paquet
						P.PlanGovernmentRegNo,
						C.ConventionNo,
						HS.SocialNumber,
						HB.SocialNumber,
						0,
						C.bCLBRequested,
						0,
						0,
						0,
						0,
						0,
						B.vcPCGSINOrEN,
						B.vcPCGFirstName,
						B.vcPCGLastName,
						B.tiPCGType,
						0,
						0,
						0,
						0
					FROM Un_Cotisation Ct
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
					JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
                    JOIN fntCONV_ObtenirStatutConventionEnDate_PourTous(NULL, NULL) CS ON CS.ConventionID = C.ConventionID
					JOIN Un_Plan P ON P.PlanID = C.PlanID
					JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
					JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
					JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
					-- S'assure que les informations ne sont pas les mêmes que les dernières expédiées
					WHERE O.OperTypeID = 'BEC'
						AND C.bCLBRequested <> 0 -- BEC demandé
						AND C.tiCESPState IN (2,4) -- Pré-validation du BEC passe
						AND C.ConventionId = @ConventionID
						AND O.OperID = @iID_OperIDBEC
                        AND CS.ConventionStateID = 'REE'

			END	
			ELSE -- On doit recréer un nouvel OperID et une nouvelle Cotisation car il n'y a aucune 400-24.
			BEGIN --1

				INSERT INTO @tCLB (
					ConventionID,
					UnitID,
					EffectDate,
					ConnectID )
					SELECT 
						C.ConventionID,
						UnitID = MIN(U.UnitID),
						@dtToday, -- 2010-05-04 Pierre Paquet
						1
					FROM dbo.Un_Convention C 
                    JOIN fntCONV_ObtenirStatutConventionEnDate_PourTous(NULL, NULL) CS ON CS.ConventionID = C.ConventionID
					JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID	
					JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
				WHERE C.ConventionID = @ConventionID
                        AND CS.ConventionStateID = 'REE'
						AND	C.bCLBRequested <> 0 -- BEC demandé
						AND C.tiCESPState IN (2,4) -- Pré-validation du BEC passe
						AND C.bSendToCESP <> 0 -- À envoyer au PCEE
						AND C.dtRegStartDate IS NOT NULL
						AND dbo.FN_CRQ_DateNoTime(C.dtRegStartDate) <= @dtToday -- Ne pas créer de BEC avant la date d'entrée en REEE			
				GROUP BY 
						C.ConventionID,
						C.dtRegStartDate,
						B.BirthDate
						--U.ActivationConnectID	
		
			-- Va chercher le dernier OperID avant l'insertion
			SET @iOperID = IDENT_CURRENT('Un_Oper')

			INSERT INTO Un_Oper (
					OperTypeID,
					OperDate,
					ConnectID )
				SELECT
					'BEC',
					@dtToday,
					ISNULL(U.ActivationConnectID, 1)
				FROM @tCLB C
				LEFT JOIN dbo.Un_Unit U ON C.UnitID=U.UnitID
				ORDER BY C.ConventionID

			SET @iID_OperIDBEC = SCOPE_IDENTITY()

			IF @@ERROR <> 0
				SET @iResult = -1

			IF @iResult = 1
			BEGIN --2
				-- Insertion d'une nouvelle cotisation
				INSERT INTO Un_Cotisation (
						UnitID,
						OperID,
						EffectDate,
						Cotisation,
						Fee,
						BenefInsur,
						SubscInsur,
						TaxOnInsur )
					SELECT 
						UnitID,
						@iOperID+iAddToOperID,
						@dtToday,
						0,
						0,
						0,
						0,
						0
					FROM @tCLB

				IF @@ERROR <> 0
					SET @iResult = -2
			END --2

			IF @iResult = 1
			BEGIN --3
				INSERT INTO Un_CESP400 (
						OperID,
						CotisationID,
						ConventionID,
						tiCESP400TypeID,
						vcTransID,
						dtTransaction,
						iPlanGovRegNumber,
						ConventionNo,
						vcSubscriberSINorEN,
						vcBeneficiarySIN,
						fCotisation,
						bCESPDemand,
						fCESG,
						fACESGPart,
						fEAPCESG,
						fEAP,
						fPSECotisation,
						vcPCGSINorEN,
						vcPCGFirstName,
						vcPCGLastName,
						tiPCGType,
						fCLB,
						fEAPCLB,
						fPG,
						fEAPPG )
					SELECT
						Ct.OperID,
						Ct.CotisationID,
						C.ConventionID,
						24,
						'FIN',
						@dtToday, -- 2010-05-04 Pierre Paquet
						P.PlanGovernmentRegNo,
						C.ConventionNo,
						HS.SocialNumber,
						HB.SocialNumber,
						0,
						C.bCLBRequested,
						0,
						0,
						0,
						0,
						0,
						B.vcPCGSINOrEN,
						B.vcPCGFirstName,
						B.vcPCGLastName,
						B.tiPCGType,
						0,
						0,
						0,
						0
					FROM Un_Cotisation Ct
					JOIN Un_Oper O ON O.OperID = Ct.OperID
					JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
					JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
					JOIN Un_Plan P ON P.PlanID = C.PlanID
					JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
					JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
					JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
					-- S'assure que les informations ne sont pas les mêmes que les dernières expédiées
					WHERE O.OperTypeID = 'BEC'
						AND C.bCLBRequested <> 0 -- BEC demandé
						AND C.tiCESPState IN (2,4) -- Pré-validation du BEC passe
						AND O.OperID = @iID_OperIDBEC
					END -- 3
			
				IF @@ERROR <> 0
					SET @iResult = -3
				
		END 
		
		IF @iResult = 1
		BEGIN
			-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
			UPDATE Un_CESP400
			SET vcTransID = vcTransID+CAST(iCESP400ID AS VARCHAR(12))
			WHERE vcTransID = 'FIN' 
		END
			IF @@ERROR <> 0
				SET @iResult = -4
	
	END 

	RETURN @iResult
END