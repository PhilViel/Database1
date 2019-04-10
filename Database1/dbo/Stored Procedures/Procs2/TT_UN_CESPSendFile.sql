/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_CESPSendFile
Description         :	Génération des lots de transactions (100, 200 et 400) pour un fichier de production du PCEE.
Valeurs de retours  :	@Return_Value :
						>0  :	Tout à fonctionné
		                <=0 :	Erreur SQL

Exemple d'appel		:	

						DECLARE @i INT
						EXECUTE @i = dbo.TT_UN_CESPSendFile 1
						SELECT @i

Note                :	ADX0000811	IA	2006-04-12	Bruno Lapointe	Création
								ADX0001153	IA	2006-11-10	Alain Quirion			Empêcher l’envoi des enregistrements 400 tant qu’il y aura des erreurs non corrigées sur un enregistrement 100 ou un enregistrement 200 de la convention
								ADX0001235	IA	2007-02-14	Alain Quirion			Utilisation de dtRegStartDate pour la date de début de régime
								ADX0002426	BR	2007-05-23	Bruno Lapointe			Gestion de la table Un_CESP.
								ADX0002465	BR	2007-05-31	Bruno Lapointe			Correction du problème des annualtions de 400 qui
																					se doublait quand il avait plus d'une 900 sur la 400 annulée.
                                                2008-10-17  Faiha Araar				Correcion pour ajouter les enregistrements 511
												2009-02-04	Pierre-Luc Simard		Correction pour envoyer les transactions de la dernière journée du mois, même s'il y a l'heure dans la date
												2009-11-19	Jean-François Gauthier	Ajout de la validation du changement de bénéficiaire 
																					et appel de la procédure psPCEE_CreerEnregistrement					
												2010-01-07	Jean-François Gauthier	Modification pour utiliser un CROSS APPLY  sur l'appel de la fonction de recherche des bénéficiaires
																					Élimination du paramètre d'appel de la procédure psPCEE_CreerEnregistrement511
												2010-03-03	Jean-François Gauthier	(point #1 - phase 2) Modification afin de recalculer les transaction 400-21-5 (Remplacement d'un bénéficiaire non-admissible)
												2010-03-16	Jean-François Gauthier	Modification de la méthode de calcul des 400-21-5 afin de les traiter à part des autres transactions
												2010-03-25	Jean-François Gauthier	(point #4) Modification afin d'éviter le retour des 400-11 en erreur 3006
												2010-03-29	Pierre Paquet			Utilisation de tiCESP400WithdrawReasonID pour les calculs.
												2010-03-29  Pierre Paquet			Remplacer le OperID par le OperSourceID pour les liens avec CESP.
												2010-04-14	Jean-François Gauthier	(point #9) Exclusion des transactions 400 dont le 200 est en erreur	
												2010-04-26	Pierre Paquet			(point #4) Il faut supprimer les transferts à zéro car ils ne sont pas envoyés au PCEE.
												2010-04-30  Jean-François Gauthier	(point #9) Ajout de la vérification sur iCESP800ID pour valider que les 200 sont en erreur
												2010-10-19	Pierre Paquet			(point #9) Correction sur les suppressions, ca ne marchait pas.
												2010-10-20	Pierre Paquet			Ajustement à la mise à jour de ConventionRES pour le type 3.
												2011-01-05	Jean-François Gauthier	Ajout de la gestion d'erreur Begin Try au niveau des requêtes en problème
																					Modification afin de corriger certains bugs
																					Optimisation
												2011-01-21	Jean-François Gauthier	Ajout des Begin / End à tous les IF		
												2011-03-01	DHuppé					Retrait des annulation et reprises des remboursements et ajout des 511							
												2010-10-14	Frederick Thibault		Ajout du champ fACESGPart pour régler le problème SCEE+
												2015-02-04	Donald Huppé			glpi 13342 (G Komenda): On ne devrait pas retenir les 400 quand ce n'est que le 200 du souscripteur qui est en erreur
												2015-03-03	Donald Huppé			Enlever AND C.tiCESPState > 0
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_CESPSendFile] (
	@bForceSendFile BIT) -- Indique si le traitement doit s'effectuer mème s'il y a une réponse en attente du PCEE.
AS
BEGIN
	DECLARE
		@iCESPSendFileID	INT, -- ID du fichier de production
		@dtToday			DATETIME,
		@vcTodayDate		VARCHAR(75),
		@dtLimit			DATETIME,
		@iCntCESPSendFile	INT,
		@iCESGWaitingDays	INT,
		@iResult			INT,
		@vcCESPSendFile		VARCHAR(75),
		@iRetour			INT
	
	SET @iResult = 1

	-- Si on ne force pas l'envoi, on retourne une erreur si 
	IF @bForceSendFile = 0
		BEGIN
			IF EXISTS (
					SELECT * 
					FROM Un_CESPSendFile
					WHERE vcCESPSendFile LIKE 'P%'
						AND iCESPReceiveFileID IS NULL
					)
				BEGIN
					SET @iResult = -1 -- Erreur on a un fichier de production pour lequel on a pas eu de fichier de retour et l'option forcer est à non.
				END
		END

	-----------------
	BEGIN TRANSACTION
	-----------------

	IF @iResult > 0
		BEGIN
			SET @dtToday = GETDATE()
			SET @dtLimit = CAST(CAST(DATEPART(MONTH,@dtToday) AS VARCHAR)+'-01-'+CAST(DATEPART(YEAR,@dtToday) AS VARCHAR) AS DATETIME)
			--SET @dtLimit = DATEADD(DAY,-1,@dtLimit)

			SET @vcTodayDate = CAST(DATEPART(YEAR,@dtToday) AS VARCHAR)
			IF DATEPART(MONTH,@dtToday) > 9
				BEGIN
					SET @vcTodayDate = @vcTodayDate + CAST(DATEPART(MONTH,@dtToday) AS VARCHAR)
				END
			ELSE
				BEGIN
					SET @vcTodayDate = @vcTodayDate + '0' + CAST(DATEPART(MONTH,@dtToday) AS VARCHAR)
				END

			IF DATEPART(DAY,@dtToday) > 9	
				BEGIN
					SET @vcTodayDate = @vcTodayDate + CAST(DATEPART(DAY,@dtToday) AS VARCHAR)
				END
			ELSE
				BEGIN
					SET @vcTodayDate = @vcTodayDate + '0' + CAST(DATEPART(DAY,@dtToday) AS VARCHAR)
				END
		
			SET @vcCESPSendFile = 'P0000105444723RC' + @vcTodayDate + '01'
		
			SELECT 
				@iCESGWaitingDays = MAX(CESGWaitingDays)
			FROM Un_Def
		
			SELECT 
				@iCntCESPSendFile = COUNT(iCESPSendFileID)
			FROM Un_CESPSendFile
			WHERE vcCESPSendFile LIKE 'P0000105444723RC' + @vcTodayDate + '%'
		
			IF @iCntCESPSendFile > 1
				BEGIN
					SET @vcCESPSendFile = 
						'P0000105444723RC'+@vcTodayDate+
						CASE 
							WHEN @iCntCESPSendFile < 10 THEN '0' + CAST(@iCntCESPSendFile AS VARCHAR)
						ELSE CAST(@iCntCESPSendFile AS VARCHAR) 
						END
				END
		END

	IF @iResult > 0
		BEGIN

			-- Création d'une table temporaire qui contiendra les id des conventions qui remplissent les critères nécessessaires à leurs 
			-- envois au PCEE
			CREATE TABLE #tConventionToSend (
				ConventionID INTEGER PRIMARY KEY )

			-- On ajoute TOUTES les conventions dont le minimum est requis.
			INSERT INTO #tConventionToSend
				SELECT DISTINCT
					C.ConventionID
				FROM dbo.Un_Convention C
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				JOIN Mo_Connect Cn ON Cn.ConnectID = U.ActivationConnectID -- S'assure qu'au moins un groupe d'unités est activé
                JOIN ( -- On s'assure que la convention a déjà été à l'état REEE
                            SELECT DISTINCT
                                        CS.ConventionID
                            FROM Un_ConventionConventionState CS
                            WHERE CS.ConventionStateID = 'REE'
                            ) CSS ON CSS.ConventionID = C.ConventionID
                JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
                JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
                WHERE C.bSendToCESP <> 0 -- À envoyer au PCEE                               
                            AND C.dtRegStartDate IS NOT NULL      
                            AND ISNULL(S.SocialNumber,'') <> ''
                            AND ISNULL(B.SocialNumber,'') <> ''

				--WHERE C.bSendToCESP <> 0 -- À envoyer au PCEE
					--AND C.tiCESPState > 0 -- Passe le minimum des pré-validations PCEE

			IF @@ERROR = 0	
				BEGIN
					-- Ne traite pas les conventions qui ont un enregistrement 100 en erreur qui n'est pas traité.
					DELETE #tConventionToSend
					FROM #tConventionToSend
					JOIN Un_CESP100 C1 ON C1.ConventionID = #tConventionToSend.ConventionID
					JOIN Un_CESP800ToTreat C8T ON C8T.iCESP800ID = C1.iCESP800ID
				END
			
			-- 2010-04-14 : JFG :	Élimination des conventions avec TOUS les enregistrements 200 de type bénéficiaire 
			--						ou de type souscripteur sont en erreur
			IF 	@@ERROR = 0
				BEGIN
					DELETE	t				-- suppression des conventions qui ont des types BÉNÉFICIAIRES ou SOUSCRIPTEUR en erreur
					FROM 	
						#tConventionToSend t	
						INNER JOIN dbo.Un_CESP200 ce ON t.ConventionID = ce.ConventionID
						INNER JOIN dbo.Un_CESP800ToTreat C8T ON C8T.iCESP800ID = ce.iCESP800ID -- Table contenant les erreurs non-traitées.
					WHERE 
						ce.tiType = 3 -- Bénéficiaire
						--OR ce.tiType = 4 -- Souscripteur glpi 13342
				END

			IF @@ERROR = 0
				BEGIN
					DELETE	t				-- suppression des conventions qui n'ont AUCUN enregistrement de type BÉNÉFICIAIRE 
							FROM 	
								#tConventionToSend t	
								INNER JOIN dbo.Un_CESP200 ce
									ON t.ConventionID = ce.ConventionID
							WHERE 
								NOT EXISTS ( SELECT 1 
											 FROM 
												dbo.Un_CESP200 ce2
											 WHERE	
												ce2.tiType = 3
												AND 
												ce.ConventionID= ce2.ConventionID )	
								AND
								ce.iCESP800ID IS NOT NULL						
				END

				IF @@ERROR = 0
					BEGIN
						DELETE	t				-- suppression des conventions qui n'ont AUCUN enregistrement de type SOUSCRIPTEUR 
								FROM 	
									#tConventionToSend t	
									INNER JOIN dbo.Un_CESP200 ce
										ON t.ConventionID = ce.ConventionID
								WHERE 
									NOT EXISTS ( SELECT 1 
												 FROM 
													dbo.Un_CESP200 ce2
												 WHERE	
													ce2.tiType = 4
													AND 
													ce.ConventionID= ce2.ConventionID )	
									AND
									ce.iCESP800ID IS NOT NULL												
					END

			-- ********************* Fin de la suppression des 200 en erreur
			IF @@ERROR <> 0
				BEGIN
					SET @iResult = -3 
				END
		END

	IF @iResult > 0
		BEGIN
			-- Table contenant les conventions ayant une résiliation complète.
			CREATE TABLE #tConventionRES (
											ConventionID		INT PRIMARY KEY
											,CotisationID		INT			NOT NULL
											,fCESG				MONEY		NOT NULL
											,fACESGPart			MONEY		NOT NULL
											,fCLB				MONEY		NOT NULL
											,tiCESP400WithdrawReasonID INT
										 )

			-- On sélectionne les conventions ayant un résiliation complète seulement.
			/*INSERT INTO #tConventionRES 
			(
				ConventionID
				,CotisationID
				,fCESG
				,fACESGPart
				,fCLB
				,tiCESP400WithdrawReasonID
			)
				SELECT 
					U.ConventionID
					,MAX(Ct.CotisationID)
					,0
					,0
					,0
					,G4.tiCESP400WithdrawReasonID
				FROM	
						dbo.Un_Unit U
						INNER JOIN dbo.Un_Cotisation Ct 
							ON U.UnitID = Ct.UnitID
						INNER JOIN dbo.Un_Oper O 
							ON O.OperID = Ct.OperID
						INNER JOIN dbo.Un_CESP400 G4 
							ON G4.CotisationID = Ct.CotisationID
				WHERE 
					NOT EXISTS 	(
									-- Retourne les convnetions qui ne sont pas totalement résiliée
									SELECT 
										1
									FROM 
										dbo.Un_Unit ut
									WHERE 
										ut.TerminatedDate IS NULL
										AND
										ut.ConventionID = U.ConventionID
									)
					AND 
						G4.tiCESP400TypeID			 = 21				-- Remboursement
					AND 
						G4.tiCESP400WithdrawReasonID IN (3,5)			-- Raison du remboursement est la résiliation totale -- 2010-03-03 : JFG : Ajout du type 5
					AND 
						O.OperTypeID				 IN ('RES','BNA')	-- Type d'opération -- 2010-03-03 : JFG : Ajout du BNA
				GROUP BY 
					U.ConventionID, G4.tiCESP400WithdrawReasonID
*/

			-- Ne traite pas les conventions qui ont un enregistrement 100 en erreur
			IF @@ERROR = 0	
				BEGIN
					DELETE #tConventionRES
					FROM #tConventionRES
					JOIN Un_CESP100 C1 ON C1.ConventionID = #tConventionRES.ConventionID
					JOIN Un_CESP800ToTreat C8T ON C8T.iCESP800ID = C1.iCESP800ID
				END

			-- Ne traite pas les conventions dont le bénéficiaire/souscripteur a un enregistrement 200 en erreur
			IF @@ERROR = 0	
				BEGIN
					DELETE #tConventionRES
					FROM #tConventionRES
					JOIN Un_CESP200 C2 ON C2.ConventionID = #tConventionRES.ConventionID
					JOIN Un_CESP200 C2B ON C2.HumanID = C2B.HumanID
					JOIN Un_CESP800ToTreat C8T ON C8T.iCESP800ID = C2B.iCESP800ID		
				END

			-- Ne traite pas les conventions qui ont un enregistrement 400 de non expédié
			IF @@ERROR = 0
				BEGIN
					DELETE 
					FROM #tConventionRES
					WHERE ConventionID IN (
						SELECT ConventionID
						FROM Un_CESP400
						WHERE iCESPSendFileID IS NULL )
				END

			IF @@ERROR = 0	
				BEGIN
					-- Ne traite pas les conventions qui ont un enregistrement 400 en erreur
					DELETE #tConventionRES
					FROM #tConventionRES
					JOIN Un_CESP400 C4 ON C4.ConventionID = #tConventionRES.ConventionID
					JOIN Un_CESP800ToTreat C8T ON C8T.iCESP800ID = C4.iCESP800ID
				END
			
			IF @@ERROR = 0
				BEGIN
					-- On calcul les montants de subventions pour toute la convention.
					UPDATE #tConventionRES
					SET 
						fCESG = V.fCESG,
						fACESGPart = V.fACESGPart,
						fCLB = V.fCLB
					FROM #tConventionRES
					JOIN (
							SELECT
								CE.ConventionID,
								CR.tiCESP400WithdrawReasonID,
								
								--fCESG = SUM(CE.fCESG+CE.fACESG), -- Solde de la SCEE et SCEE+
								-- Solde de la SCEE et SCEE+
								fCESG = SUM(CE.fCESG + CE.fACESG), 
								-- Partie bonifiée uniquement
								fACESGPart = SUM(CE.fACESG), 
								
								fCLB = SUM(CE.fCLB) -- Solde du BEC
							FROM 
								Un_CESP CE
								JOIN #tConventionRES CR 
									ON CR.ConventionID = CE.ConventionID
							GROUP BY 
								CE.ConventionID
								,CR.tiCESP400WithdrawReasonID
							) V ON V.ConventionID = #tConventionRES.ConventionID
					WHERE V.tiCESP400WithdrawReasonID  = 3		-- Résiliation complète. 2010-10-20

					-- 2010-03-03 : JFG :	-- Ajout du lien sur Un_CESP
											-- Ajout de la validation des transactions 21-5	
											-- Ajout de la condition spécifiant qu'il ne faut rembourser que les subventions
											-- qui ne sont pas rattachées au bénéficiaire actuel de la convetion
					UPDATE #tConventionRES
					SET 
						fCESG = V.fCESG,
						fACESGPart = V.fACESGPart,
						fCLB = V.fCLB
					FROM 
						#tConventionRES
						INNER JOIN 
						(
						SELECT
							CE.ConventionID,

							--fCESG = SUM(CE.fCESG+CE.fACESG),	-- Solde de la SCEE et SCEE+
							-- Solde de la SCEE et SCEE+
							fCESG = SUM(CE.fCESG + CE.fACESG), 
							-- Partie bonifiée uniquement
							fACESGPart = SUM(CE.fACESG), 
							
							fCLB = SUM(CE.fCLB)					-- Solde du BEC
						FROM
							dbo.Un_CESP CE
							INNER JOIN dbo.Un_CESP400 G4
								ON G4.OperID = CE.OperID
							INNER JOIN #tConventionRES CR 
								ON CR.ConventionID = CE.ConventionID
							INNER JOIN dbo.Un_Convention c
								ON c.ConventionID = CE.ConventionID
							INNER JOIN dbo.Un_Beneficiary b
								ON c.BeneficiaryID = b.BeneficiaryID
							INNER JOIN dbo.Mo_Human h 
								ON h.HumanID = b.BeneficiaryID
						WHERE
							CR.tiCESP400WithdrawReasonID  = 5		-- BNA (table temporaire)
							AND
							G4.vcBeneficiarySIN	<> h.SocialNumber	-- Subventions non rattachés au bénéficiaire actuel
						GROUP BY 
							CE.ConventionID
						) V ON V.ConventionID = #tConventionRES.ConventionID
				END

			-- Ajout au solde actuel le montant des remboursements qui seront annulés pour connaître le montant du nouveau remboursement.
			
			-- 2010-03-03 : JFG :	-- Ajout du lien sur Un_CESP400
									-- Ajout de la validation des transactions 21-5	
									-- Ajout de la condition spécifiant qu'il ne faut rembourser que les subventions
									-- qui ne sont pas rattachées au bénéficiaire actuel de la convetion	
			IF @@ERROR = 0
				BEGIN
					UPDATE #tConventionRES
					SET 
						fCESG = #tConventionRES.fCESG + V.fCESG,
						fACESGPart = #tConventionRES.fACESGPart + V.fACESGPart,
						fCLB = #tConventionRES.fCLB + V.fCLB
					FROM #tConventionRES
					JOIN (
							SELECT
								G4.ConventionID,
								
								fCESG = SUM(G4.fCESG),
								fACESGPart = SUM(G4.fACESGPart),
								
								fCLB = SUM(G4.fCLB)
							FROM Un_CESP400 G4
							JOIN #tConventionRES CR ON G4.CotisationID = CR.CotisationID
							LEFT JOIN Un_CESP400 R4 ON R4.iReversedCESP400ID = G4.iCESP400ID
							WHERE	G4.iCESP800ID IS NULL -- Pas revenu en erreur
								AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
								AND R4.iCESP400ID IS NULL -- Pas annulé
								AND CR.tiCESP400WithdrawReasonID <> 5 -- Différent de BNA
							GROUP BY G4.ConventionID
						) V ON V.ConventionID = #tConventionRES.ConventionID

					-- Pour le calcul du 5 (en excluant le bénéficaire actuel)
					UPDATE #tConventionRES
					SET 
						fCESG = #tConventionRES.fCESG + V.fCESG,
						fACESGPart = #tConventionRES.fACESGPart + V.fACESGPart,
						fCLB = #tConventionRES.fCLB + V.fCLB
					FROM #tConventionRES
						INNER JOIN 
						(
						SELECT
							G4.ConventionID,
							
							fCESG = SUM(G4.fCESG),
							fACESGPart = SUM(G4.fACESGPart),
							
							fCLB = SUM(G4.fCLB)
						FROM 
						 dbo.Un_CESP400 G4
							INNER JOIN #tConventionRES CR 
								ON G4.CotisationID = CR.CotisationID
							LEFT OUTER JOIN dbo.Un_CESP400 R4 
								ON R4.iReversedCESP400ID = G4.iCESP400ID
							INNER JOIN dbo.Un_Convention c
								ON c.ConventionID = G4.ConventionID
							INNER JOIN dbo.Un_Beneficiary b
								ON c.BeneficiaryID = b.BeneficiaryID
							INNER JOIN dbo.Mo_Human h 
								ON h.HumanID = b.BeneficiaryID
						WHERE	
							G4.iCESP800ID IS NULL			-- Pas revenu en erreur
							AND 
							G4.iReversedCESP400ID IS NULL	-- Pas une annulation
							AND 
							R4.iCESP400ID IS NULL			-- Pas annulé
							AND
							CR.tiCESP400WithdrawReasonID  = 5	-- BNA
							AND
							G4.vcBeneficiarySIN			  <> h.SocialNumber	-- Subventions non rattachés au bénéficiaire actuel
						GROUP BY 
							G4.ConventionID
						) V ON V.ConventionID = #tConventionRES.ConventionID		
				END

			IF @@ERROR <> 0
				BEGIN
					SET @iResult = -4
				END

			-- 
			IF @@ERROR = 0
				BEGIN
					DELETE
					FROM #tConventionRES
					WHERE	fCESG = 0 -- Solde de SCEE et SCEE+ différent de 0.00$
						AND fCLB = 0 -- Solde de BEC différent de 0.00$
				END
		END

	IF @iResult > 0
		BEGIN
			INSERT INTO Un_CESPSendFile (
				vcCESPSendFile,
				dtCESPSendFile)
			VALUES (
				@vcCESPSendFile,
				@dtToday)
		
			IF @@ERROR <> 0
				BEGIN
					SET @iResult = -2 -- Erreur à la sauvegarde du fichier d'envoi
				END
			ELSE
				BEGIN
					SET @iCESPSendFileID = IDENT_CURRENT('Un_CESPSendFile')
					SET @iResult = @iCESPSendFileID
				END
		END

	IF @iResult > 0
		BEGIN
			-- Mets dans le fichier les enregistrements 100 des conventions concernés qui n'ont pas encore été expédiés
			UPDATE Un_CESP100
			SET iCESPSendFileID = @iCESPSendFileID
			FROM Un_CESP100
			JOIN #tConventionToSend CTS ON CTS.ConventionID = Un_CESP100.ConventionID
			WHERE Un_CESP100.iCESPSendFileID IS NULL -- Pas déjà expédié
				AND Un_CESP100.dtTransaction < @dtLimit -- = @dtLimit -- Exclus les transactions ultérieure à la date limite.
				
			IF @@ERROR <> 0
				BEGIN
					SET @iResult = -5 
				END
		END

	IF @iResult > 0
		BEGIN
			-- Mets dans le fichier les enregistrements 200 des conventions concernés qui n'ont pas encore été expédiés
			UPDATE Un_CESP200
			SET iCESPSendFileID = @iCESPSendFileID
			FROM Un_CESP200
			JOIN #tConventionToSend CTS ON CTS.ConventionID = Un_CESP200.ConventionID			
			LEFT JOIN Un_CESP800ToTreat C8T ON C8T.iCESP800ID = Un_CESP200.iCESP800ID	
			WHERE Un_CESP200.iCESPSendFileID IS NULL -- Pas déjà expédié
				AND Un_CESP200.dtTransaction < @dtLimit -- = @dtLimit -- Exclus les transactions ultérieure à la date limite.
				AND C8T.iCESP800ID IS NULL	--Exclus ceux qui ont un enregistrment 200 lié toujours en traitement

			IF @@ERROR <> 0
				BEGIN
					SET @iResult = -6 
				END
		END

	IF @iResult > 0
		BEGIN
			-- Point #4.
			-- On supprimer les transferts à zéro (19 et 23) car ils ne doivent pas être envoyés au PCEE.
			-- Si les transactions ne sont pas supprimées, alors il est possible de faire des 'rollback' de transfert BEC
			DELETE FROM Un_CESP400
			WHERE Un_CESP400.iCESPSendFileID IS NULL -- Pas déjà expédié
				AND Un_CESP400.fCLB = 0 -- Montant BEC zéro.
				AND Un_CESP400.fCESG = 0 -- Montant CESP et CESP+ à zéro.
				AND Un_CESP400.fCotisation = 0 -- Cotisation à zéro.
				AND Un_CESP400.tiCESP400TypeID IN (19, 23) -- Type IN et OUT.
				AND EXISTS (SELECT 1 ConventionID FROM #tConventionToSend t WHERE t.ConventionID = Un_CESP400.ConventionID) 

			IF @@ERROR <> 0
				BEGIN
					SET @iResult = -6 
				END
		END

	IF @iResult > 0
		BEGIN
			IF @@ERROR = 0
				BEGIN
					-- Il faut renverser les transactions de cotisation 400-21.  Peu importe la raison de la résiliation.
					INSERT INTO Un_CESP400 
					(
						OperID,
						CotisationID,
						ConventionID,
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
						vcPGProv,
						fCotisationGranted 
					)
					SELECT
						G4.OperID,
						G4.CotisationID,
						G4.ConventionID,
						G4.iCESP400ID,
						G4.tiCESP400TypeID,
						G4.tiCESP400WithdrawReasonID,
						'FIN',
						G4.dtTransaction,
						G4.iPlanGovRegNumber,
						G4.ConventionNo,
						G4.vcSubscriberSINorEN,
						G4.vcBeneficiarySIN,
						-G4.fCotisation,
						G4.bCESPDemand,
						G4.dtStudyStart,
						G4.tiStudyYearWeek,
						-G4.fCESG,
						-G4.fACESGPart,
						-G4.fEAPCESG,
						-G4.fEAP,
						-G4.fPSECotisation,
						G4.iOtherPlanGovRegNumber,
						G4.vcOtherConventionNo,
						G4.tiProgramLength,
						G4.cCollegeTypeID,
						G4.vcCollegeCode,
						G4.siProgramYear,
						G4.vcPCGSINorEN,
						G4.vcPCGFirstName,
						G4.vcPCGLastName,
						G4.tiPCGType,
						-G4.fCLB,
						-G4.fEAPCLB,
						-G4.fPG,
						-G4.fEAPPG,
						G4.vcPGProv,
						-G4.fCotisationGranted
					FROM 
						dbo.Un_Cotisation Ct
						INNER JOIN dbo.Un_CESP400 G4 
							ON G4.CotisationID = Ct.CotisationID
						INNER JOIN #tConventionRES CR 
							ON Ct.CotisationID = CR.CotisationID
						LEFT OUTER JOIN dbo.Un_CESP400 R4 
							ON R4.iReversedCESP400ID = G4.iCESP400ID
					WHERE	
						G4.iCESP800ID IS NULL -- Pas revenu en erreur
						AND G4.iReversedCESP400ID IS NULL -- Pas une annulation
						AND R4.iCESP400ID IS NULL -- Pas annulé
						--AND	G4.tiCESP400WithdrawReasonID  <> 5 -- N'est pas un BNA.  On l'exclus car le calcul est différent.			
				END

			IF @@ERROR = 0
				BEGIN
						-- Recrée les enregistrements 400 des résiliations dont le montant de remboursement de SCEE, SCEE+ et BEC est a ajuster 
						-- avec les bons montants.

						-- 2009-11-19 : Validation du bénéficiaire de la transaction de remboursement 400-21
						--				afin qu'il soit  le même que celui de la  transaction d'origine
						--				et non celui du bénéficiaire actuel de la convention (en raison d'un
						--				changement possible de bénéficiaire)
						-- Récupérer le OperDate de la transaction initiale

						-- Récupération le bénéficiaire sur la convention lors de la création de la transaction initiale
					
						-- Insertion des information
						-- 2010-03-03 : JFG : Ajout du lien avec Un_CESP
					BEGIN TRY
						INSERT INTO dbo.Un_CESP400 
							(OperID,CotisationID,ConventionID,tiCESP400TypeID,
							 tiCESP400WithdrawReasonID,vcTransID,dtTransaction,
							 iPlanGovRegNumber,ConventionNo,vcSubscriberSINorEN,
							 vcBeneficiarySIN,fCotisation,bCESPDemand,fCESG,fACESGPart,
							 fEAPCESG,fEAP,fPSECotisation,fCLB,fEAPCLB,fPG,fEAPPG )
							SELECT
								Ct.OperID,Ct.CotisationID,C.ConventionID,
								21,--3, --En commentaire étant donné que l'on gère aussi les 5.
								CR.tiCESP400WithdrawReasonID,'FIN',Ct.EffectDate,P.PlanGovernmentRegNo,
								C.ConventionNo,HS.SocialNumber,HB.SocialNumber,0,
								C.bCESGRequested,
								-- Rembourse la totalité de la subvention
								CR.fCESG,CR.fACESGPart,0,0,0,
								-- Rembourse la totalité du BEC
								CR.fCLB,0,0,0
							FROM 
								dbo.Un_Cotisation Ct
								INNER JOIN #tConventionRES CR 
									ON Ct.CotisationID = CR.CotisationID
								INNER JOIN dbo.Un_Unit U 
									ON U.UnitID = Ct.UnitID
								INNER JOIN dbo.Un_Convention C 
									ON C.ConventionID = U.ConventionID
								INNER JOIN dbo.Un_Plan P 
									ON P.PlanID = C.PlanID
								INNER JOIN dbo.Mo_Human HS 
									ON HS.HumanID = C.SubscriberID
								INNER JOIN
									(
										SELECT
											c.ConventionID, 
											MinOperDate = (SELECT o.OperDate FROM dbo.Un_Oper o WHERE o.OperID = CASE 
																					WHEN MIN(ct.OperID) < MIN(co.OperID) THEN MIN(ct.OperID)
																					ELSE MIN(co.OperID)
																				END)
										FROM
											dbo.Un_Convention c
											INNER JOIN	dbo.Un_Unit u
												ON c.ConventionID = u.ConventionID
											LEFT OUTER JOIN dbo.Un_Cotisation ct
												ON u.UnitId = ct.UnitID
											LEFT OUTER JOIN dbo.Un_ConventionOper co
												ON c.ConventionID = co.ConventionID
										GROUP BY
											c.ConventionID
									)	AS MinOper
									ON	CR.ConventionID = MinOper.ConventionID
								CROSS APPLY
								(
								SELECT
									fnt.iID_Convention,
									fnt.iID_Nouveau_Beneficiaire
								FROM
									dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, NULL, CR.ConventionID, NULL, MinOper.MinOperDate, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL) fnt
								) f
									--ON f.iID_Convention  = c.ConventionID
								INNER JOIN dbo.Mo_Human HB
									ON HB.HumanID = f.iID_Nouveau_Beneficiaire
							WHERE 
								CR.fCESG >= 0
								AND 
								CR.fCLB >= 0
								AND 
								dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate
								-- 2011-01-05 : JFG : A noter, cette requête peut engendrer une erreur si un bénéficiare n'a pas de NAS
								AND
								HB.SocialNumber is not null
					END TRY
					BEGIN CATCH
						SET @iResult = -6 
					END CATCH
				END
		END

	IF @iResult > 0
		BEGIN
			BEGIN TRY
				-- Mets dans le fichier les enregistrements 400 des conventions concernés qui n'ont pas encore été expédiés
				UPDATE Un_CESP400
				SET iCESPSendFileID = @iCESPSendFileID
				FROM Un_CESP400
				JOIN #tConventionToSend CTS ON CTS.ConventionID = Un_CESP400.ConventionID
				LEFT JOIN Un_Cotisation Ct ON Ct.CotisationID = Un_CESP400.CotisationID
				LEFT JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID		
				LEFT JOIN Un_CESP200 C2 ON C2.ConventionID = CTS.ConventionID
				LEFT JOIN Un_CESP800ToTreat C8T ON C8T.iCESP800ID = C2.iCESP800ID
				WHERE 
					Un_CESP400.iCESPSendFileID IS NULL -- Pas déjà expédié
					AND(	( Un_CESP400.dtTransaction < @dtLimit -- = @dtLimit -- Exclus les transactions ultérieure à la date limite.
							AND( Un_CESP400.tiCESP400TypeID NOT IN (21) -- Le délai administratif s'applique uniquement au remboursement
								OR ISNULL(U.IntReimbDate,@dtLimit+1) < @dtLimit -- = @dtLimit -- Pas de délai si le remboursement intégral a eu lieu
								)
							)
						-- Délai administratif sur les remboursements.
						OR	Un_CESP400.dtTransaction < DATEADD(DAY,-@iCESGWaitingDays,@dtLimit) -- = DATEADD(DAY,-@iCESGWaitingDays,@dtLimit)
						)
					AND C8T.iCESP800ID IS NULL 	-- Exclus ceux qui ont un enregistrement 200 lié toujours en traîtement
					AND		-- 2010-03-25 : JFG : Ajout de la condition permettant d'éviter le retour des 400-11 en erreur 3006
						NOT (	Un_CESP400.fCotisation = 0 
								AND
								Un_CESP400.tiCESP400TypeID = 11 )
			END TRY
			BEGIN CATCH
				SET @iResult = -7 
			END CATCH
		END

	IF @iResult>0
		BEGIN
			BEGIN TRY
				-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
				UPDATE Un_CESP400
				SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
				WHERE vcTransID = 'FIN' 
			END TRY
			BEGIN CATCH
				SET @iResult = -8
			END CATCH
		END
    
    --Ajouter les enregistrements 511
	IF @iResult > 0
		
	BEGIN
		UPDATE UN_CESP511
		SET iCESPSendFileID = @iCESPSendFileID
		WHERE iCESPSendFileID IS NULL -- Pas déjà expédié
		AND dtTransaction < @dtLimit -- = @dtLimit -- Exclus les transactions ultérieure à la date limite.
		
		IF @@ERROR<>0
		   SET @iResult = -9 --Une erreur s'est produite lors de la mise èa jour des enregistremsnts 511
	END

   IF @iResult>0
		BEGIN
			------------------
			COMMIT TRANSACTION
			------------------
		END
	ELSE
		BEGIN
			--------------------
			ROLLBACK TRANSACTION
			--------------------
		END
	
	RETURN @iResult
END


