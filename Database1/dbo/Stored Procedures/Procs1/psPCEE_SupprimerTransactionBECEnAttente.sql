
/****************************************************************************************************
Code de service		:	psPCEE_SupprimerTransactionBECEnAttente
Nom du service		:	1.1.1 Supprimer une transaction BEC en attente	
But					:	Supprimer une transaction BEC en attente	
Description			:	Ce service valide et supprime une transaction BEC en attente. S'il s'agit d'une
						transaction de 'Demande de BEC', alors la case BEC de la convention est décochée.
						Pour supprimer une transaction de remboursement, alors on supprime la transaction
						400-21 de CESP400. S'il s'agit de transactions de transfert entre convention, alors
						il faut supprimer les transaction 400-19 et 400-23 de la table CESP400 ainsi que
						les opérations rattachées.	

Facette				:		PCEE
Reférence			:		Document psPCEE_SupprimerTransactionBECEnAttente.DOCX

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iID_CESP400				Identifiant unique de la transaction 400 à supprimer
						
Exemple d'appel:
				DECLARE @i INT												
				EXECUTE @i = dbo.psPCEE_SupprimerTransactionBECEnAttente 71312265, 2
				PRINT @i
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       S/O                          @iID_CodeErreur                             = 0		si traitement réussi
																								<> 0	si une erreur est survenue
                    
Historique des modifications :
			
						Date						Programmeur								Description									Référence
						----------					-------------------------------------	----------------------------				---------------
						2009-10-29					Jean-François Gauthier	Création de la procédure
						2009-11-19					Jean-François Gauthier	Élimination de l'appel à VL_UN_CONVENTION_IU
						2010-01-12					Jean-François Gauthier	Ajout de la mise à jour du champ bCLBRequested
						2010-01-15					Jean-François Gauthier	Ajout de la suppression de l'opération et de la cotisation
																								si la demande de BEC est supprimé
						2010-02-02					Jean-François Gauthier	Ajout d'un CASE dans la validation 7 pour le type d'opération
						2010-02-03					Pierre Paquet				Utilisation du vcBeneficiarySIN dans la recherche des trx de transfert.
						2010-02-03					Jean-François Gauthier	Ajout des champs dtRegStartDate, bSouscripteur_Desire_IQEE, IQEE, IQEEMaj
																								dans la table temporaire qui reçoit des données de SL_UN_Convention
						2010-02-04					Pierre Paquet				Suppression automatique de la demande lors de la suppression d'un transfert.
						2010-02-10					Pierre Paquet				Ajustement des cases à cocher lors de la suppression du Transfert.
						2010-02-11					Pierre Paquet				Ajout de la validation: La trx doit appartenir au bénéficiaire actuel de la convention.
						2010-02-12					Pierre Paquet				Ajustement sur le retour du code d'erreur.
						2010-02-17					Pierre Paquet				Ajout d'une validation : supprimer un transfert, les 2 conventions doivent appartenir au même bénéficiaire.
						2010-04-16					Pierre Paquet				Gérer la suppression d'un transfert seul.
						2010-04-20					Pierre Paquet				Correction lors de la suppresion d'un transfert et d'une demande de BEC.
						2010-04-21					Pierre Paquet				Correction pour la suppression d'un transfert à zéro.
						2010-04-21					Jean-François Gauthier	Modification afin de plus appeler IU_UN_Convention qui interfére
																								avec le traitement subséquent
						2010-04-22					Pierre Paquet				Supprimer les trx de transfert si on supprime la demande.
						2010-04-23					Pierre Paquet				Correction: affiche un message d'erreur si l'utilisateur veut supprimer le transfert avant la demande.
						2010-05-05					Pierre Paquet				Ajout du rollback dans UN_CESP800ToTreat si iCESP800ID.
						2010-05-06					Pierre Paquet				Ajout d'une validation: Ne pas supprimer un remboursement s'il y a une désactivation.
																							Automatisme si on rollback des remboursements.
						2010-05-07					Pierre Paquet				Ajout de la validation PCEEE0014.
						2010-10-14					Frederick Thibault		Ajout du champ fACESGPart pour régler le problème de remboursement SCEE+
						2014-11-20					Pierre-Luc Simard		Mise à jour du champ SCEEFormulaire93BECRefuse et appel de la procédure psCONV_EnregistrerPrevalidationPCEE
						2015-02-24					Pierre-Luc Simard		Retrait de la table temporaire @tConvention
 ****************************************************************************************************/
CREATE PROCEDURE dbo.psPCEE_SupprimerTransactionBECEnAttente
								(
								@iID_CESP400	INT
								,@iID_Connect	INT
								)
AS
	BEGIN
		SET NOCOUNT ON
		SET XACT_ABORT ON		

		DECLARE		 @iErrno							INT
					,@iErrSeverity						INT
					,@iErrState							INT
					,@vErrmsg							NVARCHAR(1024)
					,@iID_CodeErreur					INT
					,@iRetour							INT
					,@iID_Convention					INT
					,@iID_CESPSendFile					INT
					,@tiID_CESP400Type					INT
					,@bCESPDemande						BIT
					,@mCLB								MONEY
					,@mCESG								MONEY
					,@mACESG							MONEY
					,@iID_Oper							INT
					,@iID_Cotisation					INT
					,@iID_Subscriber					INT
					,@iID_CoSubscriber					INT
					,@iID_Beneficiary					INT
					,@iID_Plan							INT
					,@vcConventionNo					VARCHAR(15)
					,@dtPmtDate							DATETIME
					,@cID_PmtType						CHAR(3)
					,@dtGovernmentRegDate				DATETIME
					,@iID_DiplomaText					INT	
					,@bSendToCESP						BIT 				
					,@bCESGRequested					BIT 			
					,@bACESGRequested					BIT 			
					,@bCLBRequested						BIT 			
					,@tiCESPState						TINYINT 			
					,@tiID_RelationshipType				TINYINT  
					,@vcDiplomaText						VARCHAR(150)		
					,@iID_DestinationRemboursement		INT
					,@vcDestinationRemboursementAutre	VARCHAR(50)
					,@dtDateduProspectus				DATETIME
					,@bSouscripteurDesireIQEE			BIT
					,@tiLienCoSouscripteur				TINYINT
					,@bTuteurDesireReleveElect			BIT
					,@iSous_Cat_ID_Resp_Prelevement		INT
					,@iID_Oper19						INT
					,@vcID_Oper40024					VARCHAR(12)
					,@vcID_Oper							VARCHAR(38)
					,@bFormulaireRecu					BIT
					,@vcNASBeneficiaireConvention		VARCHAR(12)
					,@vcNASBeneficiaireTransaction		VARCHAR(12)
					,@iCESP400ID_19						INT
					,@iID_ConventionBEC					INT
					,@dtDateJour						DATETIME

	BEGIN TRY
			-----------------
			BEGIN TRANSACTION
			-----------------
			SET @iID_CodeErreur = NULL
			
			-- 1. Récupérer les informations de la transaction 400 à supprimer
			SELECT
				@iID_Convention					=	ce.ConventionID
				,@iID_CESPSendFile				=	ce.iCESPSendFileID
				,@tiID_CESP400Type				=	ce.tiCESP400TypeID
				,@bCESPDemande					=	ce.bCESPDemand
				,@mCLB							=	ce.fCLB
				,@mCESG							=	ce.fCESG
				,@mACESG						=   ce.fACESGPart
				,@iID_Oper						=	ce.OperID
				,@vcNASBeneficiaireTransaction	=   ce.vcBeneficiarySIN
			FROM
				dbo.Un_CESP400 ce
			WHERE
				ce.iCESP400ID = @iID_CESP400

			-- 2. Trouver le type de transaction reçu en paramètre 
			--	  Section modifiée afin d'avoir plus de performance (voir les IF ci-bas)
		
			-- 3. Valide que la transaction n'a pas été envoyée au PCEE
			IF @iID_CESPSendFile IS NOT NULL
				BEGIN
					SELECT					
							@vErrmsg		 = 'PCEEE003'		-- La transaction a déjà été envoyée au PCEEE
							,@iErrState		 = 1
							,@iErrSeverity	 = 11
							,@iID_CodeErreur = -9

					RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
				END			
			
			-- Récupérer le NAS du bénéficiaire actuel de la convention
			SELECT 
					@vcNASBeneficiaireConvention=SocialNumber 
			FROM 
					dbo.UN_CESP400 C4
					INNER JOIN dbo.UN_CONVENTION C
						ON C4.conventionID=C.conventionID 
					INNER JOIN dbo.MO_HUMAN H
						ON C.BeneficiaryID=H.HumanID 
			WHERE 
				C4.iCESP400ID = @iID_CESP400

			IF (@vcNASBeneficiaireConvention <> @vcNASBeneficiaireTransaction)
				BEGIN
					SELECT					
							@vErrmsg		 = 'PCEEE0010'		-- La transaction appartient à l'ancien bénéficiaire.
							,@iErrState		 = 1
							,@iErrSeverity	 = 11
							,@iID_CodeErreur = -9

					RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
				END	

------------------------- 4. Type 'Demande du BEC' 
			IF	(@tiID_CESP400Type = 24 AND @bCESPDemande = 1) -- 'Demande du BEC' 
				BEGIN
					-- On vérifie si c'est un transfert, si oui alors on s'occupe toute suite des trx de transfert.

					-- Vérifier si cette demande provient d'un transfert, si oui alors supprimer le transfert aussi.
					IF EXISTS (SELECT 1 FROM dbo.UN_CESP400 WHERE ConventionID = @iID_Convention AND tiCESP400TypeID = '19' AND iCESPSendFileID IS NULL AND fCESG = 0 AND fACESGPart = 0)
					BEGIN
						-- Récupérer le iCESP400ID de la transaction 19.
						SELECT @iCESP400ID_19 = iCESP400ID FROM dbo.UN_CESP400 WHERE ConventionID = @iID_Convention AND tiCESP400TypeID = '19' AND iCESPSendFileID IS NULL AND fCESG = 0 AND fACESGPart = 0
						
						-- 1. Récupérer les informations de la transaction 400-19 (transfert)
						SELECT
							@iID_Convention					=	ce.ConventionID
							,@iID_CESPSendFile				=	ce.iCESPSendFileID
							,@tiID_CESP400Type				=	ce.tiCESP400TypeID
							,@bCESPDemande					=	ce.bCESPDemand
							,@mCLB							=	ce.fCLB
							,@mCESG							=	ce.fCESG
							,@mACESG						=	ce.fACESGPart
							,@iID_Oper						=	ce.OperID
							,@vcNASBeneficiaireTransaction	=   ce.vcBeneficiarySIN
						FROM
							dbo.Un_CESP400 ce
						WHERE
							ce.iCESP400ID = @iCESP400ID_19

						-- Récupérer l'autre OperID (transaction 19)
							SELECT 
								@iID_Oper19 = tio.iOUTOperID
							FROM
								UN_TIO tio
							WHERE iTINOperID = @iID_Oper

						-- Validation: L'état de la convention d'origine doit être différent de 'FRM'. Sinon erreur.
						DECLARE @iID_Convention_23 INT
						DECLARE @cEtatConvention_23 CHAR(3)

						-- Récupérer l'identifiant unique de la convention d'origine.
						SET @iID_Convention_23 = (SELECT C.ConventionID 
												   FROM dbo.Un_Convention C 
													LEFT JOIN UN_CESP400 C4 on C4.vcOtherConventionNo = C.ConventionNo
												   WHERE C4.iCESP400ID = @iCESP400ID_19)
							
						-- Récupérer l'état de la convention d'origine
						SET @dtDateJour = getdate() + 1 
						SET @cEtatConvention_23 = (SELECT dbo.fnCONV_ObtenirStatutConventionEnDate (@iID_Convention_23, @dtDateJour))
						
						-- Si l'état est 'FRM', erreur.
						IF @cEtatConvention_23 = 'FRM'
						BEGIN
									SELECT					
										@vErrmsg		 = 'PCEEE0014'		
										,@iErrState		 = 1
										,@iErrSeverity	 = 11
										,@iID_CodeErreur = -5
									RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
						END

						-- Valider que les 2 conventions appartiennent au même bénéficiaire.
						IF (SELECT C.BeneficiaryID FROM dbo.UN_Convention C LEFT OUTER JOIN dbo.UN_CESP400 C4 ON C.ConventionID=C4.ConventionID
							WHERE C4.OperID = @iID_Oper19) <> (SELECT C.BeneficiaryID FROM dbo.UN_Convention C LEFT OUTER JOIN dbo.UN_CESP400 C4 ON C.ConventionID=C4.ConventionID
							WHERE C4.OperID = @iID_Oper)
						BEGIN
							SELECT					
								@vErrmsg		 = 'PCEEE0010'		-- La transaction appartient à l'ancien bénéficiaire.
								,@iErrState		 = 1
								,@iErrSeverity	 = 11
								,@iID_CodeErreur = -9
							RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
						END
						
						-- 2010-01-12 : Mise à jour de la case BEC dans Un_Convention (Coche)
							UPDATE	dbo.UN_Convention SET		
								bCLBRequested = 1, -- On le met à 1 mais la procédure psCONV_EnregistrerPrevalidationPCEE le rechangera peut-être
								SCEEFormulaire93BECRefuse = 0,
								@iID_Convention = ConventionID
							WHERE	ConventionID = 	(SELECT ce.ConventionID FROM	dbo.Un_CESP400 ce
													WHERE ce.tiCESP400TypeID = 23 AND ce.iCESPSendFileID	IS NULL
													AND	ce.vcBeneficiarySIN = (SELECT vcBeneficiarySIN FROM dbo.UN_CESP400 C4 WHERE iCESP400ID = @iID_CESP400))
						
						-- Mettre à jour l'état des prévalidations et les CESRequest de la convention
							EXEC @iRetour = psCONV_EnregistrerPrevalidationPCEE @iID_Connect, @iID_Convention, NULL, NULL, NULL	
								
						--  Supprimer les transactions 'IN' et 'OUT'
							SET @vcID_Oper = CAST(@iID_Oper AS VARCHAR(12)) + ',' + CAST(@iID_Oper19 AS VARCHAR(12))	
							EXECUTE @iRetour = dbo.DL_UN_OPERATION @iID_Connect, @vcID_Oper
		
						IF @iRetour <= 0 -- UNE ERREUR S'EST PRODUITE LORS DE LA MISE À JOUR DES CHAMPS
							BEGIN
								SELECT					
									@vErrmsg			= CAST(@iRetour AS VARCHAR(5))
									,@iErrState			= 1
									,@iErrSeverity		= 11
									,@iID_CodeErreur	= -4

								RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
							END
					END

						-- 1. Récupérer les informations de la transaction 400-24
						SELECT
							@iID_Convention					=	ce.ConventionID
							,@iID_CESPSendFile				=	ce.iCESPSendFileID
							,@tiID_CESP400Type				=	ce.tiCESP400TypeID
							,@bCESPDemande					=	ce.bCESPDemand
							,@mCLB							=	ce.fCLB
							,@mCESG							=	ce.fCESG
							,@mACESG						=	ce.fACESGPart
							,@iID_Oper						=	ce.OperID
							,@vcNASBeneficiaireTransaction	=   ce.vcBeneficiarySIN
						FROM
							dbo.Un_CESP400 ce
						WHERE
							ce.iCESP400ID = @iID_CESP400

					-- Décoche la case 'BEC' rollback.
					UPDATE	dbo.Un_Convention
					SET		bCLBRequested		= 0
					WHERE	ConventionID		= @iID_Convention

					-- Mettre à jour l'état des prévalidations et les CESRequest de la convention
						EXEC @iRetour = psCONV_EnregistrerPrevalidationPCEE @iID_Connect, @iID_Convention, NULL, NULL, NULL	

					IF @iRetour <= 0 -- UNE ERREUR S'EST PRODUITE LORS DE LA MISE À JOUR DES CHAMPS
						BEGIN
							SELECT					
								@vErrmsg			= CAST(@iRetour AS VARCHAR(5))
								,@iErrState			= 1
								,@iErrSeverity		= 11
								,@iID_CodeErreur	= -2

							RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
						END

					-- Si on supprime une demande de 'BEC', alors il faut supprimer l'opération et la cotisation BEC
					-- Seulement si elle n'est pas déjà lié à une autre transaction 400.
					IF (SELECT COUNT(1) FROM dbo.UN_CESP400 WHERE OperID = @iID_Oper) = 1
					BEGIN
						EXECUTE @iRetour = dbo.DL_UN_Operation @iID_Connect, @iID_Oper
					END
					ELSE
					BEGIN
						-- On supprime la 400-24.
						DELETE FROM dbo.UN_CESP400 WHERE iCESP400id = @iID_CESP400
					END
								
					IF @iRetour <= 0 -- UNE ERREUR S'EST PRODUITE LORS DE LA SUPPRESSION
						BEGIN
							SELECT					
								@vErrmsg			= CAST(@iRetour AS VARCHAR(5))
								,@iErrState			= 1
								,@iErrSeverity		= 11
								,@iID_CodeErreur	= -3

							RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
						END
			
					-- Vérifier si suite à la suppresion de la CESP400 si l'état du BEC est 'Inactif - Erreur technique'. 
					-- Si oui, alors on génère les enregistrements dans UN_CESP800ToTreat et on retirer celle de UN_CESP800Corrected.
						DECLARE @iCESP400ID_ERR INT
						DECLARE @iCESP800IDErreur INT

						-- Récupérer l'enregistrement 400-24 en erreur
						SET @iCESP400ID_ERR = (SELECT MAX(C4.iCESP400ID)
											FROM dbo.UN_CESP400 C4
											LEFT JOIN dbo.UN_CESP400 R4 ON C4.iCESP400ID = R4.iReversedCESP400id
											LEFT JOIN dbo.UN_CESP900 C9 ON C4.iCESP400ID = C9.iCESP400ID
											WHERE C4.vcBeneficiarySIN = @vcNASBeneficiaireConvention
											AND C4.tiCESP400TypeID = 24
											AND C4.bCESPDemand = 1
											AND C4.iCESPSendFileID IS NOT NULL
											AND C4.iReversedCESP400ID IS NULL
											AND R4.iCESP400id IS NULL
											AND NOT EXISTS (SELECT 1 FROM dbo.UN_CESP900 C9 
															WHERE C4.iCESP400Id = C9.iCESP400Id 
															AND C9.cCESP900CESGReasonID = 'C')
											)

						-- Récupérer la valeur de l'erreur 800
						SET @iCESP800IDErreur = (SELECT iCESP800ID FROM dbo.UN_CESP400 C4 WHERE C4.iCESP400id = @iCESP400ID_ERR)
							
						IF @iCESP800IDErreur IS NOT NULL
						BEGIN
								-- Supprimer l'enregistrement de la table des UN_CESP800Corrected
								DELETE dbo.UN_CESP800Corrected 
								WHERE iCESP800ID = @iCESP800IDErreur
								
								-- Insérer un enregistrement afin d'afficher la convention dans l'outil des 400.
								INSERT INTO Un_CESP800ToTreat (iCESP800ID)
									VALUES (@iCESP800IDErreur)
						END
								
				END

-------------------- 4. Type 'Désactivation du BEC'
			IF	(@tiID_CESP400Type = 24 AND @bCESPDemande = 0) -- 'Désactivation du BEC'
				BEGIN
					-- On coche la case 'BEC' pour le rollback.
					UPDATE	dbo.Un_Convention SET		
						bCLBRequested		= 1,
						SCEEFormulaire93BECRefuse = 0
					WHERE	ConventionID		= @iID_Convention

					-- Mettre à jour l'état des prévalidations et les CESRequest de la convention
						EXEC @iRetour = psCONV_EnregistrerPrevalidationPCEE @iID_Connect, @iID_Convention, NULL, NULL, NULL	

					IF @iRetour <= 0 -- UNE ERREUR S'EST PRODUITE LORS DE LA MISE À JOUR DES CHAMPS
						BEGIN
							SELECT					
								@vErrmsg			= CAST(@iRetour AS VARCHAR(5))
								,@iErrState			= 1
								,@iErrSeverity		= 11
								,@iID_CodeErreur	= -2

							RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
						END

					-- On supprime la 400-24.  On ne doit pas supprimer de OperID car la demande reste active.
					DELETE FROM dbo.UN_CESP400 WHERE iCESP400id = @iID_CESP400
					
					IF @iRetour <= 0 -- UNE ERREUR S'EST PRODUITE LORS DE LA SUPPRESSION
						BEGIN
							SELECT					
								@vErrmsg			= CAST(@iRetour AS VARCHAR(5))
								,@iErrState			= 1
								,@iErrSeverity		= 11
								,@iID_CodeErreur	= -3

							RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
						END
					
				END

---------------------- 6. Type 'Remboursement de BEC'
			IF (@tiID_CESP400Type = 21 AND @mCLB <>0 AND @mCESG = 0 AND @mACESG = 0)
				BEGIN
					-- On vérifie s'il y a une 'désactivation' en attente, si oui on affiche un message à l'utilisateur.
					IF EXISTS (SELECT 1 FROM dbo.UN_CESP400 
							   WHERE vcBeneficiarySIN = @vcNASBeneficiaireConvention 
							   AND tiCESP400TypeID = '24' AND bCESPDemand = 0 AND iCESPSendFileID IS NULL)
					BEGIN
					-- On affiche une erreur à l'utilisateur en lui indiquant qu'il doit supprimer la transaction 'Désactivation' en premier
							SELECT					
									@vErrmsg		 = 'PCEEA0002'		
									,@iErrState		 = 1
									,@iErrSeverity	 = 11
									,@iID_CodeErreur = -5
								RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
					END

					-- Récupérer l'ensemble des transactions de remboursement à supprimer.
					CREATE TABLE #400ASupprimer (iCESP400ID INT)
					INSERT INTO #400ASupprimer  SELECT iCESP400ID 
												FROM dbo.UN_CESP400 C4 
												WHERE C4.tiCESP400TypeID = 21 AND C4.fCLB <> 0 AND C4.fCESG = 0 AND C4.fACESGPart = 0 AND C4.fCotisation = 0
												AND C4.iCESPSendFileID IS NULL
												AND C4.vcBeneficiarySIN = @vcNASBeneficiaireConvention

					-- Supprimer la transaction 400-21 non-envoyée
					DELETE FROM dbo.Un_CESP400 WHERE iCESP400ID IN (SELECT iCESP400ID FROM #400ASupprimer)

					-- Récupérer la dernière transaction 400-24-1 valide et cocher le BEC sur cette convention.
					DECLARE @iCESP400IDBEC INT
					SET @iCESP400IDBEC = (SELECT MAX(C4.iCESP400ID)
											FROM dbo.UN_CESP400 C4
											LEFT JOIN dbo.UN_CESP400 R4 ON C4.iCESP400ID = R4.iReversedCESP400id
											LEFT JOIN dbo.UN_CESP900 C9 ON C4.iCESP400ID = C9.iCESP400ID
											WHERE C4.vcBeneficiarySIN = @vcNASBeneficiaireConvention
											AND C4.tiCESP400TypeID = 24
											AND C4.bCESPDemand = 1
											AND C4.iCESP800ID IS NULL
											AND C4.iCESPSendFileID IS NOT NULL
											AND C4.iReversedCESP400ID IS NULL
											AND R4.iCESP400id IS NULL
											AND NOT EXISTS (SELECT 1 FROM dbo.UN_CESP900 C9 
															WHERE C4.iCESP400Id = C9.iCESP400Id 
															AND C9.cCESP900CESGReasonID = 'C')
											)
					-- Récupérer la convention ciblé.
					SET @iID_ConventionBEC = (SELECT ConventionID 
												FROM dbo.UN_CESP400 
												WHERE iCESP400ID = @iCESP400IDBEC
											  )

					-- Étant donné qu'il peut y avoir plus d'un remboursement en même temps. Cas rare. A
					-- Alors on met à jour uniquement 1 seule convention.
					--SELECT @iID_Beneficiary = BeneficiaryID FROM dbo.UN_Convention WHERE ConventionID = @iID_Convention

					--IF NOT EXISTS (SELECT 1 FROM dbo.UN_Convention WHERE BeneficiaryID = @iID_Beneficiary AND bCLBRequested = 1)
					--BEGIN
						UPDATE	dbo.UN_Convention SET		
							bCLBRequested = 1,
							SCEEFormulaire93BECRefuse = 0 
						WHERE	ConventionID = @iID_ConventionBEC

					-- Mettre à jour l'état des prévalidations et les CESRequest de la convention
						EXEC @iRetour = psCONV_EnregistrerPrevalidationPCEE @iID_Connect, @iID_ConventionBEC, NULL, NULL, NULL	
					--END
					
					DROP TABLE #400ASupprimer
				END

---------------------------------------- TRANSFERT -- ERREUR
-- Vérifier si cette demande provient d'un transfert, si oui alors supprimer le transfert aussi.
				IF (@tiID_CESP400Type = 19 AND @mCESG = 0 AND @mACESG = 0) 
				BEGIN
					IF EXISTS (SELECT 1 FROM dbo.UN_CESP400 WHERE ConventionID = @iID_Convention AND tiCESP400TypeID = '24' AND iCESPSendFileID IS NULL)
					BEGIN
					-- On affiche une erreur à l'utilisateur en lui indiquant qu'il doit supprimer la transaction 'Demande' en premier
							SELECT					
									@vErrmsg		 = 'PCEEA0001'		
									,@iErrState		 = 1
									,@iErrSeverity	 = 11
									,@iID_CodeErreur = -5
								RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
					END

					-- Récupérer l'autre OperID (transaction 19)
					SELECT 
						@iID_Oper19 = tio.iOUTOperID
					FROM
						UN_TIO tio
					WHERE iTINOperID = @iID_Oper

					-- Valider que les 2 conventions appartiennent au même bénéficiaire.
					IF (SELECT C.BeneficiaryID FROM dbo.UN_Convention C LEFT OUTER JOIN dbo.UN_CESP400 C4 ON C.ConventionID=C4.ConventionID
						WHERE C4.OperID = @iID_Oper19) <> (SELECT C.BeneficiaryID FROM dbo.UN_Convention C LEFT OUTER JOIN dbo.UN_CESP400 C4 ON C.ConventionID=C4.ConventionID
						WHERE C4.OperID = @iID_Oper)
					BEGIN
						SELECT					
							@vErrmsg		 = 'PCEEE0010'		-- La transaction appartient à l'ancien bénéficiaire.
							,@iErrState		 = 1
							,@iErrSeverity	 = 11
							,@iID_CodeErreur = -9
						RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
					END

					--  Supprimer les transactions 'IN' et 'OUT'
						SET @vcID_Oper = CAST(@iID_Oper AS VARCHAR(12)) + ',' + CAST(@iID_Oper19 AS VARCHAR(12))	
						EXECUTE @iRetour = dbo.DL_UN_OPERATION @iID_Connect, @vcID_Oper

						IF @iRetour <= 0 -- UNE ERREUR S'EST PRODUITE LORS DE LA MISE À JOUR DES CHAMPS
							BEGIN
								SELECT					
									@vErrmsg			= CAST(@iRetour AS VARCHAR(5))
									,@iErrState			= 1
									,@iErrSeverity		= 11
									,@iID_CodeErreur	= -4

								RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
							END

				END

			SET @iID_CodeErreur = 0
			------------------
			COMMIT TRANSACTION
			------------------
		END TRY
		BEGIN CATCH
				IF (XACT_STATE()) = -1												-- LA TRANSACTION EST TOUJOURS ACTIVE, ON PEUT FAIRE UN ROLLBACK
					BEGIN
						--------------------
						ROLLBACK TRANSACTION
						--------------------
					END
				
				SELECT																-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
					@vErrmsg		= REPLACE(ERROR_MESSAGE(),'%',' ')
					,@iErrState		= ERROR_STATE()
					,@iErrSeverity	= ERROR_SEVERITY()
					,@iErrno		= ERROR_NUMBER()

				IF @iID_CodeErreur IS NULL			-- IL S'AGIT D'UNE ERREUR TECHNIQUE, ON RETOURNE LE CODE -1
					BEGIN
						SET @iID_CodeErreur = -5
					END

			RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
		END CATCH	
		
		RETURN @iID_CodeErreur					
	END


