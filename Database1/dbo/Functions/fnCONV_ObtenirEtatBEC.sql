/****************************************************************************************************
Code de service		:		fnCONV_ObtenirEtatBEC
Nom du service		:		1.1.1 Obtenir l'état du BEC 
But					:		Afficher l'état du BEC pour un bénéficiaire
Facette				:		CONV
Reférence			:		Document fnCONV_ObtenirEtatBEC.DOCX

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
						iID_Beneficiare				Identifiant du bénéficiaire					Oui

Exemples d'appel:
				SELECT [dbo].[fnCONV_ObtenirEtatBEC](NULL)
				SELECT [dbo].[fnCONV_ObtenirEtatBEC](414793)
				SELECT [dbo].[fnCONV_ObtenirEtatBEC](441074)
				SELECT [dbo].[fnCONV_ObtenirEtatBEC](477675)
				SELECT [dbo].[fnCONV_ObtenirEtatBEC](415138)


Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
						N/A							iEtatBEC									Code de l'état du BEC
														CONVM001 = 'Inactive - Aucune demande en cours' 
														CONVM002 = 'Inactive - Remboursé au PCEE'
														CONVM003 = 'Active - En attente de l'envoi au PCEE'
														CONVM004 = 'BEC inactif : Refus pour erreur technique à corriger'
														CONVM005 = 'Demande active : avec réponse reçue'
														CONVM006 = 'BEC inactif : réponse de non-paiement'
														CONVM007 = 'Aucune information disponible'
														CONVM008 = 'Active - Envoyée en attente de réponse'

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-10-22					Jean-François Gauthier					Création de la fonction
						2009-11-03					Jean-François Gauthier					Modification pour retourner un code de retour
																							plutôt qu'un message
						2009-11-04					Jean-François Gauthier					Modification des codes d'erreur retourné
						2009-12-15					Jean-François Gauthier					Ajout de la validation pour l'enregistrement 400
																							ne soit pas renversé et est sans erreur
						2010-01-12					Jean-François Gauthier					Modification afin de rajouter l'état CONVM008
						2010-01-14					Jean-François Gauthier					Correction d'un bug lors de la sélection de l'enregisterment 400-24
																							le plus récent.	
						2010-01-15					Jean-François Gauthier					Modification pour détermination des cas CONVM003 et CONVM008																
						2010-01-20					Jean-François Gauthier					Modification de la façon de vérifier le "non renversé" à la validation 5.
						2010-02-02					Pierre Paquet							Ajout de la vérification de bCLBRequested pour la recherche du bon iCESP400ID.
						2010-04-15					Pierre Paquet							Correction: Ajustement sur l'état 'Refus pour erreur technique'.
						2010-04-19					Jean-François Gauthier					Modification afin de chercher uniquement dans le dernier fichier reçu 
																							des 900
						2010-04-19					Pierre Paquet							Vérification d'un remboursement même si la case est cochée.
						2010-04-20					Pierre Paquet							Ajustement pour l'état 'Remboursé' afin de gérer les cas multi-BEC...
						2010-04-26					Pierre Paquet							Ajout de la vérification des 400-23 le statut OUT.
						2010-05-03					Pierre Paquet							Ajout de la gestion des réponses 'C' seule. (convm002).
						2010-05-11					Pierre Paquet							Ajout de la gestion d'une demande 'renversée'. convm002.
																							
/*	OPTIMISATION (ATTENTION, IL VA SANS DOUTE FALLOIR CHANGER LES NOMS
	
	CREATE NONCLUSTERED INDEX [_dta_index_Un_CESP900_5_1912550047__K2_K1_K4] ON [dbo].[Un_CESP900] 
	(
		[iCESP400ID] ASC,
		[iCESP900ID] ASC,
		[iCESPReceiveFileID] ASC
	)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF)
	go

	CREATE STATISTICS [_dta_stat_1912550047_4_2] ON [dbo].[Un_CESP900]([iCESPReceiveFileID], [iCESP400ID])
	go

	CREATE STATISTICS [_dta_stat_1912550047_4_1] ON [dbo].[Un_CESP900]([iCESPReceiveFileID], [iCESP900ID])
	go
*/

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_ObtenirEtatBEC]
	(
		@iID_Beneficiaire INT
	)
RETURNS CHAR(8)
AS
	BEGIN
		DECLARE 
			@vcNAS					VARCHAR(75)
			,@iCESP400ID			INT
			,@cEtatBEC				CHAR(8)
			,@dtTransaction40024	DATETIME
			,@iCESPSendFileID		INT
			,@iCESP800ID			INT
			,@ConventionID          INT
			,@bCESPDemand			INT
			,@iNbrReponse			INT
			,@iReversedCESP400ID	INT

		-- 1. Récupérer le NAS du bénéficiaire
		SELECT
			@vcNAS	= h.SocialNumber		
		FROM
			dbo.Mo_Human h
		WHERE
			h.HumanID = @iID_Beneficiaire

		-- AUCUNE case 'BEC' de cochée -----------------------------------------------------------------------------------
		-- 2 choix possibles: Aucune demande ou remboursement.
		IF NOT EXISTS (SELECT 1 FROM dbo.UN_Convention C WHERE C.BeneficiaryID = @iID_Beneficiaire AND C.bCLBRequested = 1)
		BEGIN
			-- Récupérer l'enregistrement 400-24 le plus récent
			SELECT 
				TOP 1
				@iCESP400ID				= ce4.iCESP400ID
				,@dtTransaction40024	= ce4.dtTransaction
				,@iCESPSendFileID		= ce4.iCESPSendFileID
				,@iCESP800ID			= ce4.iCESP800ID
				,@ConventionID          = ce4.ConventionID
				,@bCESPDemand			= ce4.bCESPDemand
				,@iReversedCESP400ID    = ce4.iReversedCESP400ID
			FROM
				dbo.Un_CESP400 ce4
			LEFT JOIN dbo.UN_Convention C ON C.ConventionID = CE4.ConventionID
			WHERE
				ce4.tiCESP400TypeID		 = 24
				AND
				ce4.vcBeneficiarySIN	= @vcNAS
			ORDER BY
				ce4.iCESP400ID DESC					


			-- Soit aucune demande
			--IF NOT EXISTS (SELECT 1 FROM dbo.UN_CESP400 ce4 WHERE ce4.tiCESP400TypeID = 24 and ce4.bCESPDemand = 1 and ce4.vcBeneficiarySIN = @vcNAS)
			IF @iCESP400ID IS NULL
			BEGIN
				SET @cEtatBEC = 'CONVM001'  -- 'Inactive - Aucune demande en cours'
				RETURN 	@cEtatBEC			
			END

			-- Soit demande de désactivation
			--IF EXISTS (SELECT 1 FROM dbo.UN_CESP400 ce4 WHERE ce4.tiCESP400TypeID = 24 and ce4.bCESPDemand = 0 and ce4.vcBeneficiarySIN = @vcNAS)
			IF @bCESPDemand = 0  OR @iReversedCESP400ID IS NOT NULL
			BEGIN
				SET @cEtatBEC = 'CONVM002' -- 'Inactive - Remboursé,transféré, désactivé au PCEE'
				RETURN 	@cEtatBEC			
			END


			-- Soit remboursé.
			IF EXISTS(
						SELECT	
								1
							FROM	
								dbo.Un_CESP400 ce4
							WHERE 
									ce4.tiCESP400TypeID		IN (21, 23)
									AND
									ce4.dtTransaction		> @dtTransaction40024
									AND
									ce4.iCESP800ID			IS NULL
									AND 
								--	ce4.ConventionID		= @ConventionID -- PPaquet 2010-04-20
									ce4.vcBeneficiarySIN	= @vcNAS
									AND
									ce4.fCLB <> 0
									AND 
									NOT EXISTS (SELECT 1 FROM dbo.Un_CESP400 u2 WHERE ce4.iCESP400ID = u2.iReversedCESP400ID AND u2.iCESP800ID IS NULL)	-- NON RENVERSÉ
					  )
				BEGIN
					SET @cEtatBEC = 'CONVM002'		-- 'Inactive - Remboursé,transféré, désactivé au PCEE'
					RETURN 	@cEtatBEC			
				END

		END

		-- Case 'BEC' de cochée -----------------------------------------------------------------------------------
		-- 2. Récupérer l'enregistrement 400-24 le plus récent
		SELECT 
			TOP 1
			@iCESP400ID				= ce4.iCESP400ID
			,@dtTransaction40024	= ce4.dtTransaction
			,@iCESPSendFileID		= ce4.iCESPSendFileID
			,@iCESP800ID			= ce4.iCESP800ID
			,@ConventionID          = ce4.ConventionID
		FROM
			dbo.Un_CESP400 ce4
		LEFT JOIN dbo.UN_Convention C ON C.ConventionID = CE4.ConventionID
		WHERE
			ce4.tiCESP400TypeID		= 24
			AND
			ce4.vcBeneficiarySIN	= @vcNAS
			AND
			C.bCLBRequested = 1
		ORDER BY
			ce4.iCESP400ID DESC

	-- 2010-04-19 : JFG :	Récupération du ID du fichier reçu le plus récent
		--						en fonction du iCESP400ID traité
		
		IF (@iCESPSendFileID IS NULL)
			BEGIN
				SET @cEtatBEC = 'CONVM003'		-- 'Active - En attente de l'envoi au PCEE'
				RETURN 	@cEtatBEC			
			END
		

		DECLARE 
			@iCESPReceiveFileID INT
		
		SET @iCESPReceiveFileID =  (	
									SELECT
										TOP 1 rf.iCESPReceiveFileID 
									FROM
										dbo.Un_CESP900 ce9
										INNER JOIN dbo.Un_CESPReceiveFile rf
											ON CE9.iCESPReceiveFileID = rf.iCESPReceiveFileID
									WHERE
										ce9.iCESP400ID = @iCESP400ID
									ORDER BY
										rf.dtRead DESC,
										rf.iCESPReceiveFileID DESC)


		-- Récupérer le nombre de réponse reçu dans le dernier fichier.
		SET @iNbrReponse = (SELECT COUNT(*) FROM dbo.UN_CESP900 ce9
						   WHERE ce9.iCESP400ID = @iCESP400ID 
						   AND ce9.iCESPReceiveFileID = @iCESPReceiveFileID)
	
		-- avec une seule réponse 'C'.
		IF EXISTS(
					SELECT 1 
					FROM dbo.Un_CESP900 ce9 
					WHERE 
						ce9.iCESP400ID = @iCESP400ID 
						AND 
						ce9.cCESP900CESGReasonID = 'C'
						AND
						ce9.iCESPReceiveFileID = @iCESPReceiveFileID
				  ) AND @iNbrReponse = 1
			BEGIN
				SET @cEtatBEC = 'CONVM002' -- 'Remboursé / Transféré / Désactivé'
				RETURN 	@cEtatBEC			
			END


	
		-- Vérifier s'il y a eu un remboursement.
		IF EXISTS(
						SELECT	
								1
							FROM	
								dbo.Un_CESP400 ce4
							WHERE 
									ce4.tiCESP400TypeID		IN (21, 23)  --Remboursement ou OUT
									AND
									ce4.dtTransaction		> @dtTransaction40024
									AND
									ce4.iCESP800ID			IS NULL
									AND 
									ce4.ConventionID		= @ConventionID
									AND 
									ce4.fCLB <> 0
									AND
									NOT EXISTS (SELECT 1 FROM dbo.Un_CESP400 u2 WHERE ce4.iCESP400ID = u2.iReversedCESP400ID AND u2.iCESP800ID IS NULL)	-- NON RENVERSÉ
					  )
				BEGIN
					SET @cEtatBEC = 'CONVM002'		-- 'Inactive - Remboursé au PCEE'
					RETURN 	@cEtatBEC			
				END



		-- 5. Vérification de l'attente réponse
		IF (@iCESPSendFileID IS NULL)
			--	OR
			--	NOT EXISTS(SELECT 1 FROM dbo.Un_CESP900 ce9 WHERE ce9.iCESP400ID = @iCESP400ID)
			BEGIN
				SET @cEtatBEC = 'CONVM003'		-- 'Active - En attente de l'envoi au PCEE'
				RETURN 	@cEtatBEC			
			END

		-- 5.1 Verification de l'attente reponse	-- 2010-01-12 : JFG Ajout de cet état
		--IF NOT EXISTS(SELECT 1 FROM dbo.Un_CESP900 ce9 WHERE ce9.iCESP400ID = @iCESP400ID) PPAQUET 2010-04-15
		IF NOT EXISTS(SELECT 1 FROM dbo.Un_CESP900 ce9 WHERE ce9.iCESP400ID = @iCESP400ID) AND @iCESP800ID IS NULL
			BEGIN
				SET @cEtatBEC = 'CONVM008'  -- 'Active - Envoyée en attente de réponse'
				RETURN @cEtatBEC 
			END

		-- 6. Vérification de l'erreur technique
		IF @iCESP800ID IS NOT NULL
			BEGIN
				SET @cEtatBEC = 'CONVM004'  -- 'BEC inactif : Refus pour erreur technique à corriger'
				RETURN 	@cEtatBEC			
			END

	
									

		-- 7. Vérification des réponses
		-- pas de réponse
		IF NOT EXISTS(	
						SELECT 1 
						FROM dbo.Un_CESP900 ce9 
						WHERE 
							ce9.iCESP400ID = @iCESP400ID AND ce9.cCESP900CESGReasonID = 'C'
							AND
							ce9.iCESPReceiveFileID = @iCESPReceiveFileID
						)
			BEGIN
				SET @cEtatBEC = 'CONVM005' -- 'Demande active : avec réponse reçue'
				RETURN 	@cEtatBEC			
			END

		-- avec réponse
		IF EXISTS(
					SELECT 1 
					FROM dbo.Un_CESP900 ce9 
					WHERE 
						ce9.iCESP400ID = @iCESP400ID 
						AND 
						ce9.cCESP900CESGReasonID = 'C'
						AND
						ce9.iCESPReceiveFileID = @iCESPReceiveFileID
				  )
			BEGIN
				SET @cEtatBEC = 'CONVM006' -- 'BEC inactif : réponse de non-paiement'
				RETURN 	@cEtatBEC			
			END


		
		-- Aucun état trouvé
		SET @cEtatBEC = 'CONVM007'
		RETURN 	@cEtatBEC			
	END
