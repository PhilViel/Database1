
/****************************************************************************************************
Code de service		:	psPCEE_RembourserBec
Nom du service		:	1.1.1 Rembourser le BEC au PCEE	
But					:	Créer les transactions de remboursement du BEC au PCEE	
Description			:	Ce service est utilisé afin de rembourser le BEC d'une convention d'un bénéficiaire
						au PCEE. Le service récupère en premier lieu l'opération BEC d'origine afin de lier
						la transaction de remboursement. Par la suite, il y a création de la transaction 400-21
						avec la raison du remboursement qui est précisée par l'utilisateur, c'est cette 
						transaction qui sera envoyée au PCEE.	

Facette				:		PCEE
Reférence			:		Document psPCEE_RembourserBEC.DOCX

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iID_Beneficiaire			Identifiant unique du bénéficiaire
						@iID_RaisonRemboursement	Identifiant de la raison du remboursement

Exemple d'appel:
				DECLARE @i INT
				EXECUTE @i = dbo.psPCEE_RembourserBec 436879, 11, 287654
				PRINT @i
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       S/O                          @iID_CodeErreur                             = 0		si traitement réussi
																								<> 0	si une erreur est survenue
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-10-29					Jean-François Gauthier					Création de la procédure
						2009-11-19					Jean-François Gauthier					Correction sur l'appel de fnCONV_ObtenirConventionBEC
						2009-11-23					Jean-François Gauthier					Élimination la validation de la raison du remboursement
						2010-01-05					Jean-François Gauthier					Modification pour ajouter le paramètre à l'appel de la fonction fnCONV_ObtenirConventionBEC
						2010-01-12					Jean-François Gauthier					Correction d'un bug
																												Ajout du update sur bCLBRequested
						2010-02-01					Jean-François Gauthier					Ajout d'une validation pour les montants BEC à zéro
						2010-02-02					Jean-François Gauthier					Ajout de la SUM pour la validation avec le montant fCLB
						2010-04-19					Jean-François Gauthier					Modification afin de gérer les cas particuliers de données
						2010-05-06					Pierre Paquet									Ajout: Désactiver le BEC si BEC coché et mCLB = 0.
						2010-10-14					Frederick Thibault							Ajout du champ fACESGPart pour régler le problème de remboursement SCEE+
						2015-01-08					Pierre-Luc Simard							Ne plus demander le BEC pour les convention ayant un remboursement
 ****************************************************************************************************/

CREATE PROCEDURE dbo.psPCEE_RembourserBec
								(
								@iID_Beneficiaire			INT
								,@iID_RaisonRemboursement	INT
								,@iID_Connect				INT
								)
AS
	BEGIN
		SET NOCOUNT ON
		SET XACT_ABORT ON		

		DECLARE		 @iErrno				INT
					,@iErrSeverity			INT
					,@iErrState				INT
					,@vErrmsg				NVARCHAR(1024)
					,@iID_CodeErreur		INT
					,@iRetour				INT
					,@iID_Convention		INT
					,@iID_Oper				INT
					,@iID_Cotisation		INT
					,@mCLB					MONEY		-- MONTANT BEC
					,@iID_ConventionDesactiver INT -- Convention avec BEC à zéro mais active.
					
		DECLARE @tConvention TABLE						-- 2010-04-19 : JFG : Ajout
										(
											ConventionID	INT PRIMARY KEY
											,mCLB			MONEY
											,bTraite		BIT
										)

		BEGIN TRY
			-----------------
			BEGIN TRANSACTION
			-----------------
				SET @iID_CodeErreur = NULL

				-- 2010-04-19 : JFG :	Modification, car on ne peut uniquement se baser sur le fait
				--						que le BEC est actif. Il faut plutôt traiter toutes les conventions
				--						dont le montant BEC est différent de zéro et retourner un message seulement
				--						si TOUTES les conventions ont un montant BEC à zéro.
				INSERT INTO @tConvention
				(
					ConventionID
					,mCLB
					,bTraite	
				)
				SELECT 
					c.ConventionID
					,SUM(fnt.fCLB)
					,0
				FROM
					dbo.Un_Convention c
					CROSS APPLY dbo.fntPCEE_ObtenirSubventionBons(c.ConventionID,NULL,NULL) fnt
				WHERE
					c.BeneficiaryID = @iID_Beneficiaire
				GROUP BY
					c.ConventionID
				ORDER BY
					c.ConventionID
					
				-- 2010-02-01 : JFG : Ajout d'un vérification pour voir si le montant BEC est à zéro
				-- 2010-04-19 : JFG : Modification afin de valider si TOUTES les conventions ont un BEC à zéro
				SELECT
					@mCLB = SUM(t.mCLB)
				FROM 
					@tConvention t
				
				IF ISNULL(@mCLB,0)= 0
					BEGIN
						SELECT					
									@vErrmsg		= 'PCEEE0008'
									,@iErrState		= 1
									,@iErrSeverity	= 11
									,@iID_CodeErreur		= -2

						RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
					END
				
				-- Ne plus demander le BEC pour les convention ayant eu un remboursement
				UPDATE C SET 
					SCEEFormulaire93BECRefuse = 1
				FROM dbo.Un_Convention C
				LEFT JOIN @tConvention t ON t.ConventionID = C.ConventionID
				WHERE ISNULL(t.mCLB, 0) <> 0
					AND ISNULL(C.SCEEFormulaire93BECRefuse, 0) = 0

				-- Récupérer s'il y a lieu la convention BEC coché avec un montant BEC à zéro.
				SET @iID_ConventionDesactiver = NULL
				SELECT @iID_ConventionDesactiver=t.ConventionID
				FROM @tConvention t
				LEFT JOIN dbo.Un_Convention C ON t.ConventionID = C.ConventionID
				WHERE C.bCLBRequested = 1
					AND t.mCLB = 0
				
				-- S'il y a une convention BEC coché avec un montant à zéro, alors on désactive.
				IF @iID_ConventionDesactiver IS NOT NULL
				BEGIN
					EXEC dbo.psPCEE_DesactiverBEC @iID_Beneficiaire, @iID_Connect
				END 
							
				-- 2010-04-19 : JFG : Pour chacune des conventions, on effecture le traitement
				DELETE FROM @tConvention WHERE mCLB = 0			-- suppression des conventions qui n'ont pas de montants BEC
				SET @iID_Convention = (SELECT TOP 1 ConventionID FROM @tConvention WHERE bTraite = 0)
				
				WHILE EXISTS(SELECT 1 FROM @tConvention WHERE bTraite = 0)
					BEGIN
						-- 2. Récupérer l'opération de la demande de BEC dans l'historique de la convention du bénérificiaire
						SET @iID_Oper = (	SELECT 
												TOP 1 ce.OperID
											FROM 
												dbo.Un_CESP400 ce
											WHERE
												ce.ConventionID			= @iID_Convention
												AND	
												ce.iCESPSendFileID		IS NOT NULL
												AND
												ce.tiCESP400TypeID		= 24
												AND
												ce.bCESPDemand			= 1
												AND
												ce.iCESP800ID			IS NULL
												AND
												ce.iReversedCESP400ID	IS NULL
											ORDER BY ce.iCESP400ID DESC	)

						SET @iID_Cotisation = (	SELECT	c.CotisationID
												FROM	dbo.Un_Cotisation c
												WHERE	c.OperID = @iID_Oper )

						-- 3. Traitement de la transaction 400-21
						IF	@iID_Cotisation IS NOT NULL		-- Si existe, on supprime la transaction de remboursement
							BEGIN
								DELETE FROM dbo.Un_CESP400
								WHERE 
									CotisationID				= @iID_Cotisation
									AND
									tiCEsP400WithdrawReasonID	IN (4,5,9,11)
									AND
									iCESPSendFileID				IS NULL
									AND
									tiCESP400TypeID = '21'  
									AND 
									fCLB <> 0		-- Montant BEC 
									AND 
									fCESG = 0		-- Montant SCEE 
									AND 
									fACESGPart = 0		-- Montant SCEE+ (Fred 2010-11-01)
									AND 
									fEAPCESG = 0	-- ??? (Fred 2010-11-01)

							END

						-- Création de la transaction 400-21 pour le remboursement du BEC
						EXECUTE @iRetour = dbo.IU_UN_CESP400ForOper 
															@ConnectID					= @iID_Connect				-- ID Unique de connexion de l'usager
															,@OperID					= @iID_Oper					-- ID de l'opération
															,@tiCESP400TypeID			= 21						-- Type d'enregistrement à créer
															,@tiCESP400WithdrawReasonID = @iID_RaisonRemboursement	-- Code de la raison du remboursement 
															,@iTypeRemboursement		= 2		

						IF @iRetour <= 0 -- UNE ERREUR S'EST PRODUITE LORS DE LA MISE À JOUR DES CHAMPS
							BEGIN
								SELECT					
									@vErrmsg		= CAST(@iRetour AS VARCHAR(5))
									,@iErrState		= 1
									,@iErrSeverity	= 11
									,@iID_CodeErreur		= -1
								RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
							END

						-- Mise à jour du champ bCLBRequested
						UPDATE	dbo.Un_Convention
						SET		bCLBRequested = 0
						WHERE
								ConventionID = @iID_Convention	
								
						UPDATE	@tConvention
						SET		bTraite = 1
						WHERE	ConventionID = @iID_Convention
						
						SET @iID_Convention = (SELECT TOP 1 ConventionID FROM @tConvention WHERE bTraite = 0)
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
						SET @iID_CodeErreur = -1
					END

--				SET @vErrmsg = CAST(@iErrno AS VARCHAR(6)) + ' : ' + @vErrmsg		-- CONCATÉNATION DU NUMÉRO D'ERREUR INTERNE À SQL SERVEUR
				SET @vErrmsg = @vErrmsg		-- 2010-02-02 : JFG : ÉLIMINATION DU NUMÉRO DE L'ERREUR CAR L'APPLICATION NE SERA PAS EN MESURE DE LA RÉCUPÉRER

				RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
		END CATCH
		
		RETURN @iID_CodeErreur					
	END


