/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_BatchRES
Description         :	Fait la résiliation en lot de groupes d'unités.
Valeurs de retours  :	@ReturnValue :
									> 0 : Les résiliations ont réussies.
									<= 0 : Les résiliations ont échoués.

Note                :	ADX0000693	IA	2005-05-17	Bruno Lapointe	Création
						ADX0000753	IA	2005-10-04	Bruno Lapointe	Il faut expédier les opérations au module des
																							chèques.  Il faut aussi expédier les destinataires
																							originaux et les changements de destinataire.
						ADX0001602	BR	2005-10-11	Bruno Lapointe	SCOPE_IDENTITY au lieu de IDENT_CURRENT
						ADX0001749	BR	2005-11-14	Bruno Lapointe	Suppression des CPA anticipé avant résiliation.
						ADX0001760	BR	2005-11-17	Bruno Lapointe	Frais disponibles
						ADX0000865	IA	2006-04-10	Bruno Lapointe	Génération des 400
						ADX0001235	IA	2007-02-14	Alain Quirion		Utilisation de dtRegStartDate pour la date de début de régime
						ADX0001351	IA	2007-04-11	Alain Quirion		Commande des lettre de résiliation sans NAS sans Cotisation automatique
						ADX0002438	BR	2007-05-16	Bruno Lapointe	Gérer correctement la SCEE quand on résilie dans un même lot
																							deux groupes d'unités de la même convention.
						ADX0002426	BR	2007-05-24	Bruno Lapointe	Gestion de la table Un_CESP.
						ADX0002502	BR	2007-06-27	Bruno Lapointe	NAS absent mal géré pour les conventions entrées en vigueur avant le 1 janvier 2003
						ADX0001357	IA	2007-06-04	Alain Quirion		Création automatique de la proposition de chèque au nom de 
																							Gestion Universitas Inc. si l’unité du remboursement intégral 
																							a une source de vente de type « Gagnant de concours ».
										2010-05-07  Pierre Paquet			Gestion du BEC lors de la résiliation d'une convention.
										2010-05-11	Pierre Paquet			Correction d'un BeneficiaryID.
										2010-05-12	Pierre Paquet			Correction: Soustraire les montants remboursés.
										2010-05-13	Pierre Paquet			Correction: Gérer le NULL de fnCONV_ObtenirConventionBECSuggeree.
																						Déplacement de la section du BEC pour avoir le bon état du groupe d'unité.
										2010-05-17	Pierre Paquet			Correction: gérer multiconventions BEC.
										2010-05-18	Pierre Paquet			Correction: Nettoyage de @tConventions.
										2010-10-04	Steve Gouin			Gestion des disable trigger par #DisableTrigger
										2010-10-14	Frederick Thibault	Ajout du champ fACESGPart pour régler le problème SCEE+
										2014-11-21	Pierre-Luc Simard	Filtrer sur le champ SCEEFormulaire93BECRefuse
										2015-02-26	Donald Huppé			GLPI 13541 : Enlever la gestion du BEC
										2015-03-24	Donald Huppé			changer URR.UnitReductionReason = 'sans NAS après un (1) an' par urr.UnitReductionReasonID = 7
										2015-12-11	Pierre-Luc Simard	Gestion des états des groupes d'unités et des conventions à la fin
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_BatchRES] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@BlobID INTEGER,	-- ID du blob qui contient les objets nécessaires à la résiliation des groupes d'unités.
	@OperDate DATETIME ) -- Date des opérations
AS
BEGIN
	DECLARE
		@iResult INTEGER,
		@iProcResult INTEGER,
		@iStartOperIDRES INTEGER,
		@iStartOperIDTFR INTEGER,
		@iStartCotisationID INTEGER,
		@iStartUnitReductionID INTEGER,
		@LastBankFile DATETIME,
		@RESType CHAR(3), -- EPG = Épg. (Seulement les épargnes seront remboursées au souscripteur.  Les frais seront transférés (TFR) dans les frais disponibles de la convention pour les conventions collectives et dans les frais éliminés pour les conventions individuelles.) FEE = Épg., frais et ass. (Les épargnes, les frais, les primes d’assurance souscripteur et d’assurance bénéficiaire ainsi que les taxes seront remboursés au souscripteur.)
		@UnitReductionReasonID INTEGER, -- Raison de la résiliation, par défaut vide. 
		@IntINC MONEY -- Intérêt client

	SET @iResult = 1

	SELECT 
		@LastBankFile = ISNULL(MAX(BankFileEndDate),GETDATE()) 
	FROM Un_BankFile

	IF object_id('tempdb..#DisableTrigger') is null
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

	-----------------
	BEGIN TRANSACTION
	-----------------

	DECLARE @tChequeSuggestion TABLE (
			ChequeSuggestionID INTEGER, -- ID unique de la suggestion
			OperID INTEGER, -- Devrait contenir l'id de l'opération, mais dans ce cas contient le ID du groupe d'unités (UnitID).
			iHumanID INTEGER -- Destinataire du chèque
			)

	DECLARE @tBatchRESUnit TABLE (
		UnitID INTEGER PRIMARY KEY, -- ID unique du groupe d'unités
		iAddToOperID INTEGER IDENTITY(1,1),
		RESType CHAR(3), -- EPG = Épg. (Seulement les épargnes seront remboursées au souscripteur.  Les frais seront transférés (TFR) dans les frais disponibles de la convention pour les conventions collectives et dans les frais éliminés pour les conventions individuelles.) FEE = Épg., frais et ass. (Les épargnes, les frais, les primes d’assurance souscripteur et d’assurance bénéficiaire ainsi que les taxes seront remboursés au souscripteur.)
		UnitReductionReasonID INTEGER, -- Raison de la résiliation, par défaut vide. 
		IntINC MONEY -- Intérêt client
		)

	INSERT INTO @tChequeSuggestion
		SELECT 
			ChequeSuggestionID,
			OperID,
			iHumanID
		FROM dbo.FN_UN_ChequeSuggestion(@BlobID)

	INSERT INTO @tBatchRESUnit (
			UnitID,
			RESType,
			UnitReductionReasonID,
			IntINC )
		SELECT 
			UnitID, -- ID unique du groupe d'unités
			RESType, -- EPG = Épg. (Seulement les épargnes seront remboursées au souscripteur.  Les frais seront transférés (TFR) dans les frais disponibles de la convention pour les conventions collectives et dans les frais éliminés pour les conventions individuelles.) FEE = Épg., frais et ass. (Les épargnes, les frais, les primes d’assurance souscripteur et d’assurance bénéficiaire ainsi que les taxes seront remboursés au souscripteur.)
			UnitReductionReasonID, -- Raison de la résiliation, par défaut vide. 
			IntINC -- Intérêt client
		FROM dbo.FN_UN_BatchRESUnit(@BlobID)
		ORDER BY RESType

/*
		-- AUTOMATISMES SUR LE BEC 2010-05-07 Pierre Paquet ------------------------------
		DECLARE @iNbrConvention INT
		DECLARE @BeneficiaireATraiter INT
		DECLARE @mBEC MONEY
		DECLARE @ConventionAvecBEC INT
		DECLARE @ConventionBECSuggeree INT
		DECLARE @dtDateJour DATETIME

		SET @dtDateJour = GETDATE()

		CREATE TABLE #ConventionBEC (ConventionID INT, BeneficiaryID INT, bCLBRequested INT, mBEC MONEY, iNbrConventionLOT int, iNbrConventionTOTAL int)
		INSERT INTO #ConventionBEC SELECT DISTINCT ConventionID,0,0,0,0,0 FROM @tBatchRESUnit B JOIN dbo.Un_Unit U ON U.UnitID = B.UnitID

		-- Récupère les valeurs des cases BEC.
		UPDATE CB SET CB.bCLBRequested = C.bCLBRequested, CB.BeneficiaryID=C.BeneficiaryID 
		FROM #ConventionBEC CB 
			INNER JOIN dbo.UN_Convention C ON CB.ConventionID = C.ConventionID

		-- Si toutes les conventions du bénéficiaire sont résiliées, alors il ne faut pas gérer le transfert.
		-- Combien de convention dans le lot.
		UPDATE CB SET CB.iNbrConventionLOT = tmp.NbrConvention 
		FROM 
			(SELECT distinct NbrConvention = COUNT(*)
					, ct.BeneficiaryID
			FROM
				#ConventionBEC ct
			GROUP BY
				ct.BeneficiaryID
			) tmp
				INNER JOIN #ConventionBEC CB 
				ON tmp.BeneficiaryID = CB.BeneficiaryID

		-- Combien de convention valide pour le bénéficiaire.
		UPDATE CB SET CB.iNbrConventionTOTAL = tmp.NbrConvention
		FROM 
			(SELECT distinct NbrConvention = COUNT(DISTINCT C.ConventionID)
					, c.BeneficiaryID
			FROM
				#ConventionBEC ct
				LEFT JOIN dbo.UN_Convention C ON C.BeneficiaryID = ct.BeneficiaryID
			WHERE (dbo.fnCONV_ObtenirStatutConventionEnDate(C.ConventionID, @dtDateJour) <> 'FRM')

			GROUP BY
				c.BeneficiaryID
			) tmp
				INNER JOIN #ConventionBEC CB 
				ON tmp.BeneficiaryID = CB.BeneficiaryID

		-- Récupérer le montant BEC s'il y a lieu
		UPDATE	CB
		SET		CB.mBEC = tmp.mMontantBEC
		FROM
			(
			SELECT
				mMontantBEC = SUM(c.fCLB)
				,c.ConventionID
			FROM
				#ConventionBEC  ct
				INNER JOIN dbo.UN_CESP C 
					ON C.ConventionID = ct.ConventionID
			GROUP BY
				c.ConventionID
			) tmp
			INNER JOIN #ConventionBEC CB 
				ON tmp.ConventionID = CB.ConventionID

		-- Soustraire les montants remboursés.
		UPDATE CB
		SET CB.mBEC = CB.mBEC + tmp.mMontantBEC
		FROM
			(
			SELECT
				mMontantBEC = SUM(c.fCLB) -- Solde de BEC à rembourser
				,c.ConventionID
			FROM
				#ConventionBEC ct
				INNER JOIN dbo.UN_CESP400 C
					ON C.ConventionID = ct.ConventionID
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C.OperID
			WHERE C9.iCESP900ID IS NULL
				AND C.iCESP800ID IS NULL
				AND CE.iCESPID IS NULL					
			GROUP BY
				c.ConventionID
			) tmp
			INNER JOIN #ConventionBEC CB
				ON tmp.ConventionID = CB.ConventionID

		-- On conserve uniquement celle du BEC.
		DELETE FROM #ConventionBEC WHERE bCLBRequested = 0 AND mBEC = 0

		-- Les cas de BEC à une convention dont le montant = zéro alors psPCEE_DesactiverBEC (désactivation)
		-- Les cas de plusieurs conventions, alors on transfert.
		DECLARE CurseurConventionBEC CURSOR FOR SELECT BeneficiaryID, mBEC, ConventionID, iNbrConventionTOTAL, iNbrConventionLOT, bCLBRequested FROM #ConventionBEC
		DECLARE @iNbrUniteConvention INT
		DECLARE @iNbrUniteConventionRES INT
		DECLARE @iNbrConventionTOTAL INT
		DECLARE @iNbrConventionLOT INT
		DECLARE @bCLBRequested INT

		-- Récupérer la convention BEC suggérée.
		DECLARE @tConvention	TABLE
					(			
					iID_Convention			INT
					,iID_Souscripteur		INT
					,iID_Beneficiaire		INT
					,vcConventionNO			VARCHAR(75)
					,cID_PlanType			CHAR(3)
					,vcPlanDesc				VARCHAR(75)
					,dtDateEntreeVigueur	DATETIME
					,bCLBRequested			INT
					)

		OPEN CurseurConventionBEC 
		FETCH NEXT FROM CurseurConventionBEC INTO @BeneficiaireATraiter, @mBEC, @ConventionAvecBEC, @iNbrConventionTOTAL, @iNbrConventionLOT, @bCLBRequested
		WHILE @@FETCH_STATUS = 0
		BEGIN

			-- Obtenir le nombre d'unité de la convention
			SELECT @iNbrUniteConvention = SUM(UnitQty) 
			FROM dbo.UN_UNIT U
			WHERE U.ConventionID = @ConventionAvecBEC

			-- Récupérer le nombre d'unité à résilier dans le lot pour le bénéficiaire.
			SELECT @iNbrUniteConventionRES = SUM(U.UnitQty) 
			FROM dbo.Un_Unit U
			INNER JOIN @tBatchRESUnit BRU ON BRU.UnitID = U.UnitID
			WHERE U.ConventionID = @ConventionAvecBEC

			IF (@iNbrConventionTOTAL <> @iNbrConventionLOT)
			BEGIN
				-- 1.	FAIRE LA LISTE DE TOUTES LES CONVENTIONS ACTIVES DU BÉNÉFICIARE QUI ONT ENVOYÉ LE FORMULAIRE RHDSC
				-- On supprime les données de la table temporaire pour le traitement.
				DELETE FROM @tConvention	

				INSERT INTO @tConvention
					(
					iID_Convention		
					,iID_Souscripteur	
					,iID_Beneficiaire	
					,vcConventionNO		
					,cID_PlanType		
					,vcPlanDesc			
					,dtDateEntreeVigueur
					,bCLBRequested		
					)
					SELECT
						fnt.iConventionID
						,fnt.iSubscriberID
						,fnt.iBeneficiaryID
						,fnt.vcConventionNO
						,fnt.cPlanTypeID
						,fnt.vcPlanDesc
						,u.InForceDate
						,c.bCLBRequested
					FROM
						dbo.fntCONV_ObtenirListeConventionsParBeneficiaire(GETDATE(), @BeneficiaireATraiter) fnt	-- LISTE DES CONVENTION REE ACTIVES
						INNER JOIN dbo.Un_Beneficiary b
							ON fnt.iBeneficiaryID = b.BeneficiaryID
						INNER JOIN dbo.Un_Unit u
							ON u.ConventionID = fnt.iConventionID
						INNER JOIN dbo.Un_Convention c
							ON c.ConventionID = fnt.iConventionID
					WHERE	c.bFormulaireRecu	= 1-- FORMULAIRE RHDSC REÇU
						AND dbo.fnCONV_ObtenirStatutConventionEnDate(fnt.iConventionID,GETDATE()-1) <> 'FRM' -- 2010-04-16 : JFG : SUPPRESSION DES CONVENTIONS FERMÉES
						AND c.ConventionID NOT IN (SELECT ConventionID FROM @tBatchRESUnit B JOIN dbo.Un_Unit U ON U.UnitID = B.UnitID)
						AND ISNULL(C.SCEEFormulaire93BECRefuse, 0) = 0 -- BEC non refusé

					-- 4.	RÉCUPÉRER LA CONVENTION SUGGÉRÉE POUR LE BEC SELON L'ORDRE SUIVANT :
					--			- PLUS VIEILLE CONVENTION INDIVIDUELLE
					--			- SINON PLUS VIEILLE CONVENTION COLLECTIVE REEFLEX
					--			- SINON PLUS VIEILLE CONVENTION COLLECTIVE UNIVERSITAS
					SET @ConventionBECSuggeree = NULL

					SET @ConventionBECSuggeree = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.bCLBRequested = 1 ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)

					IF @ConventionBECSuggeree IS NULL
						BEGIN
							SET @ConventionBECSuggeree = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.cID_PlanType = 'IND' ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)
						END

					IF @ConventionBECSuggeree IS NULL
						BEGIN
							SET @ConventionBECSuggeree = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.vcPlanDesc = 'Reeeflex' ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)
						END

					IF @ConventionBECSuggeree IS NULL
						BEGIN
							SET @ConventionBECSuggeree = (SELECT TOP 1 t.iID_Convention FROM @tConvention t WHERE t.vcPlanDesc = 'Universitas' ORDER BY t.dtDateEntreeVigueur ASC, t.iID_Convention)				
						END

					-- Cas #1 S'il y a une convention suggérée.
					IF (@ConventionBECSuggeree IS NOT NULL AND (@mBEC > 0  OR @bCLBRequested = 1) AND (@iNbrConventionTOTAL > @iNbrConventionLOT) AND (@iNbrUniteConvention = @iNbrUniteConventionRES))
						BEGIN
							EXEC dbo.psPCEE_CreerTransfertBEC @ConventionAvecBEC, @ConventionBECSuggeree, @dtDateJour, @ConnectID
						END

					END -- 2010-05-17

				-- CAS #2
				-- Si le montant BEC = 0 ET fCLBRequested = 1 ET toutes les conventions sont résiliés en même temps, alors on désactive.

				IF (@iNbrConventionTOTAL = @iNbrConventionLOT) AND @mBEC = 0 AND @bCLBRequested = 1 AND (@iNbrUniteConvention = @iNbrUniteConventionRES) 
				BEGIN
					EXEC dbo.psPCEE_DesactiverBEC @BeneficiaireATraiter, @ConnectID, NULL, 0
				END

				FETCH NEXT FROM CurseurConventionBEC INTO @BeneficiaireATraiter, @mBEC, @ConventionAvecBEC, @iNbrConventionTOTAL, @iNbrConventionLOT, @bCLBRequested

			END

		CLOSE CurseurConventionBEC
		DEALLOCATE CurseurConventionBEC
*/

	-- Supprime les CPA anticipé du groupe d'unités s'il y en a
	DELETE Un_Cotisation
	FROM Un_Cotisation
	JOIN @tBatchRESUnit B ON B.UnitID = Un_Cotisation.UnitID
	JOIN Un_Oper O ON O.OperID = Un_Cotisation.OperID
	LEFT JOIN Un_OperBankFile OB ON OB.OperID = O.OperID
	WHERE O.OperTypeID = 'CPA'
		AND OB.OperID IS NULL
		AND O.OperDate > @LastBankFile

	IF @@ERROR <> 0
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		-- Va chercher le dernier OperID avant l'insertion des nouvelles opérations
		SET @iStartOperIDRES = IDENT_CURRENT('Un_Oper')

		-- Insère l'opération RES
		INSERT INTO Un_Oper (
				OperTypeID,
				OperDate,
				ConnectID )
			SELECT
				'RES',
				@OperDate,
				@ConnectID
			FROM @tBatchRESUnit

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	IF @iResult > 0
	BEGIN
		-- Va chercher le dernier UnitReductionID avant l'insertion des nouvelles réductions d'unités
		SET @iStartUnitReductionID = IDENT_CURRENT('Un_UnitReduction')

		-- Insère l'historique de réduction d'unités
		INSERT INTO Un_UnitReduction (
				UnitID,
				ReductionConnectID,
				ReductionDate,
				UnitQty,
				FeeSumByUnit,
				SubscInsurSumByUnit,
				UnitReductionReasonID,
				NoChequeReasonID )
			SELECT
				B.UnitID,
				@ConnectID,
				@OperDate,
				U.UnitQty,
				CASE -- Regarde le type de résiliation, inscrit seulement les frais non-remboursés
					WHEN B.RESType = 'EPG' AND U.UnitQty > 0 THEN ROUND(SUM(Ct.Fee)/U.UnitQty,2) --2010-05-17 division par zéro.
				ELSE 0
				END,
				CASE -- Regarde le type de résiliation, inscrit seulement les assurances bénéficiaires non-remboursés
					WHEN B.RESType = 'EPG' AND U.UnitQty > 0 THEN ROUND(SUM(Ct.SubscInsur)/U.UnitQty,2) --2010-05-17 division par zéro.
				ELSE 0
				END,
				CASE 
					WHEN ISNULL(B.UnitReductionReasonID,0) <= 0 THEN NULL
				ELSE B.UnitReductionReasonID
				END,
				NULL
			FROM @tBatchRESUnit B
			JOIN dbo.Un_Unit U ON B.UnitID = U.UnitID
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			GROUP BY 
				B.UnitID,
				B.RESType,
				B.UnitReductionReasonID,
				U.UnitQty

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	IF @iResult > 0
	BEGIN
		-- Désactive le trigger de mise à jour des états pour optimisation. Les cotisations étant manquante pour faire le calcul de l'état correctement
		--ALTER TABLE Un_Unit 
		--	DISABLE TRIGGER TUn_Unit_State
		INSERT INTO #DisableTrigger VALUES('TUn_Unit_State')

		-- Met à jour la date de résiliation
		IF @@ERROR = 0
			UPDATE dbo.Un_Unit 
			SET 
				TerminatedDate = @OperDate,
				UnitQty = 0
			FROM dbo.Un_Unit 
			JOIN @tBatchRESUnit B ON B.UnitID = Un_Unit.UnitID

		-- Active le trigger de mise à jour des états 
		--ALTER TABLE Un_Unit 
		--	ENABLE TRIGGER TUn_Unit_State
		Delete #DisableTrigger where vcTriggerName = 'TUn_Unit_State'

		IF @@ERROR <> 0
			SET @iResult = -4
	END

	IF @iResult > 0
	BEGIN
		-- Va chercher le dernier CotisationID avant l'insertion des nouvelles cotisations
		SET @iStartCotisationID = IDENT_CURRENT('Un_Cotisation')

		-- Insère la cotisation sur l'opération RES
		INSERT INTO Un_Cotisation (
				OperID,
				UnitID,
				EffectDate,
				Cotisation,
				Fee,
				BenefInsur,
				SubscInsur,
				TaxOnInsur )
			SELECT
				B.iAddToOperID + @iStartOperIDRES,
				B.UnitID,
				@OperDate,
				-SUM(Cotisation),
				CASE -- Regarde le type de résiliation, rembourse les frais uniquement si de type : Epg, Frais et Ass. (FEE)
					WHEN B.RESType = 'FEE' THEN -SUM(Fee)
				ELSE 0
				END,
				CASE -- Regarde le type de résiliation, rembourse les assurances souscripteurs uniquement si de type : Epg, Frais et Ass. (FEE)
					WHEN B.RESType = 'FEE' THEN -SUM(BenefInsur)
				ELSE 0
				END,
				CASE -- Regarde le type de résiliation, rembourse les assurances bénéficiaires uniquement si de type : Epg, Frais et Ass. (FEE)
					WHEN B.RESType = 'FEE' THEN -SUM(SubscInsur)
				ELSE 0
				END,
				CASE -- Regarde le type de résiliation, rembourse les taxes sur l'assurances uniquement si de type : Epg, Frais et Ass. (FEE)
					WHEN B.RESType = 'FEE' THEN -SUM(TaxOnInsur)
				ELSE 0
				END
			FROM @tBatchRESUnit B
			JOIN Un_Cotisation Ct ON Ct.UnitID = B.UnitID
			GROUP BY B.UnitID, B.iAddToOperID, B.RESType

		IF @@ERROR <> 0
			SET @iResult = -5
	END

	IF @iResult > 0
	BEGIN
		-- Inscrit un les intétêts chargés au client (INC)
		INSERT INTO Un_ConventionOper (
				OperID,
				ConventionID,
				ConventionOperTypeID,
				ConventionOperAmount )
			SELECT
				B.iAddToOperID + @iStartOperIDRES,
				U.ConventionID,
				'INC',
				B.IntINC 
			FROM @tBatchRESUnit B
			JOIN dbo.Un_Unit U ON U.UnitID = B.UnitID

		IF @@ERROR <> 0
			SET @iResult = -6
	END

	IF @iResult > 0
	BEGIN
		-- Inscrit les propositions de modifications de chèque.
		INSERT INTO Un_ChequeSuggestion (
				OperID, -- ID de l'opération
				iHumanID ) -- ID de l'humain qui est le destinataire du chèque
			SELECT
				B.iAddToOperID + @iStartOperIDRES, -- ID de l'opération
				C.iHumanID -- ID de l'humain qui est le destinataire du chèque
			FROM @tBatchRESUnit B
			JOIN @tChequeSuggestion C ON C.OperID = B.UnitID -- Le C.OperID contient le UnitID dans cette table temporaire voir plus haut

		IF @@ERROR <> 0
			SET @iResult = -7
	END

	--Création de la proposition de chèque au nom de Gestion Universitas Inc. si la source de vente
	--du groupe d'unités est de type "gagnant de concours"
	IF @iResult > 0
		AND EXISTS (	SELECT U.UnitID
						FROM @tBatchRESUnit R
						JOIN dbo.Un_Unit U ON U.UnitID = R.UnitID
						JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
						WHERE SS.bIsContestWinner = 1
					)
	BEGIN
		DECLARE @HumanID INTEGER

		SELECT TOP 1 @HumanID = HumanID
		FROM dbo.Mo_Human H		
		WHERE H.LastName + ' ' + H.Firstname = 'Gestion Universitas Inc.'
		ORDER BY H.HumanID			

		INSERT INTO Un_ChequeSuggestion (
			OperID,
			iHumanID )
		SELECT 
			O.OperID,
			@HumanID
		FROM @tBatchRESUnit BR
		JOIN Un_Cotisation Ct ON Ct.UnitID = BR.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		JOIN dbo.Un_Unit U ON U.UnitID = BR.UnitID
		JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		WHERE Ct.OperID = @iStartOperIDRES + BR.iAddToOperID		
			AND O.OperTypeID = 'RES'
			AND O.ConnectID = @ConnectID
			AND SS.bIsContestWinner = 1
			AND C.SubscriberID <> @HumanID --Le souscripteur n'est pas déjà Gestion Universitas Inc.

		IF @@ERROR <> 0 
			SET @iResult = -8
	END

	-- Exportes les opérations dans le module des chèques
	IF @iResult > 0
	BEGIN
		DECLARE
			@iSPID INTEGER,
			@iCheckResultID INTEGER

		SET @iSPID = @@SPID

		INSERT INTO Un_OperToExportInCHQ (
				OperID,
				iSPID )
			SELECT
				iAddToOperID + @iStartOperIDRES,
				@iSPID
			FROM @tBatchRESUnit

		EXECUTE @iCheckResultID = IU_UN_OperCheckBatch 1, @iSPID

		IF @iCheckResultID <> @iSPID
			SET @iResult = -9
	END

	IF @iResult > 0
	BEGIN
		-- Va chercher le dernier OperID avant l'insertion des nouvelles opérations
		SET @iStartOperIDTFR = IDENT_CURRENT('Un_Oper')

		-- Insère l'opération TFR
		INSERT INTO Un_Oper (
				OperTypeID,
				OperDate,
				ConnectID )
			SELECT
				'TFR',
				@OperDate,
				@ConnectID
			FROM @tBatchRESUnit
			WHERE RESType = 'EPG'

		IF @@ERROR <> 0
			SET @iResult = -10
	END

	IF @iResult > 0
	BEGIN
		-- Insère la cotisation sur l'opération TFR
		INSERT INTO Un_Cotisation (
				OperID,
				UnitID,
				EffectDate,
				Cotisation,
				Fee,
				BenefInsur,
				SubscInsur,
				TaxOnInsur )
			SELECT
				B.iAddToOperID + @iStartOperIDTFR,
				B.UnitID,
				@OperDate,
				0,
				-SUM(Fee),
				0,
				0,
				0
			FROM @tBatchRESUnit B
			JOIN Un_Cotisation Ct ON Ct.UnitID = B.UnitID
			WHERE B.RESType = 'EPG'
			GROUP BY B.UnitID, B.iAddToOperID

		IF @@ERROR <> 0
			SET @iResult = -11
	END

	IF @iResult > 0
	BEGIN
		-- Inscrit une opération de convention de frais disponible (FDI)
		INSERT INTO Un_ConventionOper (
				OperID,
				ConventionID,
				ConventionOperTypeID,
				ConventionOperAmount )
			SELECT
				Ct.OperID,
				U.ConventionID,
				'FDI',
				-SUM(Fee)
			FROM @tBatchRESUnit B
			JOIN dbo.Un_Unit U ON U.UnitID = B.UnitID
			JOIN Un_Cotisation Ct ON Ct.OperID = B.iAddToOperID + @iStartOperIDTFR
			GROUP BY U.ConventionID, Ct.OperID

		IF @@ERROR <> 0
			SET @iResult = -12
	END

	IF @iResult > 0
	BEGIN
		-- Inscrit un lien entre la dernier cotisation et la réduction d'unités
		INSERT INTO Un_UnitReductionCotisation (
				CotisationID,
				UnitReductionID )
			SELECT
				Ct.CotisationID,
				UR.UnitReductionID
			FROM @tBatchRESUnit B
			JOIN Un_Cotisation Ct ON Ct.UnitID = B.UnitID
			JOIN Un_UnitReduction UR ON UR.UnitID = B.UnitID
			LEFT JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID AND URC.UnitReductionID = UR.UnitReductionID
			WHERE	( Ct.OperID = @iStartOperIDRES + B.iAddToOperID
					OR	( Ct.OperID = @iStartOperIDTFR + B.iAddToOperID
						AND B.RESType = 'EPG'
						)
					)
				AND UR.UnitReductionID > @iStartUnitReductionID
				AND URC.CotisationID IS NULL

		IF @@ERROR <> 0
			SET @iResult = -13
	END

	IF @iResult > 0
	BEGIN
		-- Génération des 400 de retrait 21-1 sur les TFR
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
				21,
				1,
				'FIN',
				Ct.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				0,
				C.bCESGRequested,
				NULL,
				NULL,

				-- SCEE
				CASE
					-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
					WHEN ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) <= 0 
						THEN 0
					-- Rembourse tout s'il n'y a pas de cotisations subventionnées
					WHEN ISNULL(G.fCotisationGranted, 0) = 0 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse tout si on retire toutes les cotisations subventionnées
					WHEN Ct.Cotisation + Ct.Fee > ISNULL(G.fCotisationGranted, 0) 
						THEN -(ISNULL(G.fCESG + G.fACESG,0) + ISNULL(C4.fCESG, 0))
					-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
					WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / ISNULL(G.fCotisationGranted, 0) * ((Ct.Cotisation + Ct.Fee)*-1), 2) > ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
					ELSE 
						-(ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / ISNULL(G.fCotisationGranted, 0) * ((Ct.Cotisation + Ct.Fee)*-1), 2))
				END,

				-- SCEE+
				CASE
					-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
					WHEN ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0) <= 0 
						THEN 0
					-- Rembourse tout s'il n'y a pas de cotisations subventionnées
					WHEN ISNULL(G.fCotisationGranted, 0) = 0 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse tout si on retire toutes les cotisations subventionnées
					WHEN Ct.Cotisation + Ct.Fee > ISNULL(G.fCotisationGranted, 0) 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
					WHEN ROUND((ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)) / ISNULL(G.fCotisationGranted, 0) * ((Ct.Cotisation + Ct.Fee)*-1), 2) > ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0) 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
					ELSE 
						-(ROUND((ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)) / ISNULL(G.fCotisationGranted, 0) * ((Ct.Cotisation + Ct.Fee)*-1), 2))
				END,

				0,
				0,
				0,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				0,
				0,
				0,
				0,
				NULL
			FROM @tBatchRESUnit BR
			JOIN Un_Cotisation Ct ON Ct.UnitID = BR.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			LEFT JOIN ( -- Solde SCEE et SCEE+ et solde de cotisations subventionnées
				SELECT
					V.ConventionID,

					-- Solde de la SCEE et SCEE+
					fCESG = SUM(fCESG), 
					fACESG = SUM(fACESG), 

					fCotisationGranted = SUM(fCotisationGranted) -- Solde des cotisations subventionnées
				FROM (
					SELECT DISTINCT 
						ConventionID
					FROM @tBatchRESUnit B
					JOIN dbo.Un_Unit U ON B.UnitID = U.UnitID
					WHERE B.RESType = 'EPG'
					) V
				JOIN Un_CESP G ON G.ConventionID = V.ConventionID
				GROUP BY V.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					V.ConventionID,

					-- Solde de la SCEE et SCEE+
					fCESG = SUM(C4.fCESG),
					fACESGPart = SUM(C4.fACESGPart) 
				FROM (
					SELECT DISTINCT 
						ConventionID
					FROM @tBatchRESUnit B
					JOIN dbo.Un_Unit U ON B.UnitID = U.UnitID
				WHERE B.RESType = 'EPG'
					) V
				JOIN Un_CESP400 C4 ON C4.ConventionID = V.ConventionID
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
				GROUP BY V.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.OperID = @iStartOperIDTFR + BR.iAddToOperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND BR.RESType = 'EPG'
				AND O.OperTypeID = 'TFR'		

		IF @@ERROR <> 0
			SET @iResult = -14
	END

	IF @iResult > 0
	BEGIN
		-- Génération des 400 de retrait pour les RES qui ne sont pas les derniers. (Cas ou 
		-- la convention à plus d'une groupe d'unités à résilier.
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
				21,
				1,
				'FIN',
				Ct.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				0,
				C.bCESGRequested,
				NULL,
				NULL,

				-- SCEE
				CASE
					-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
					WHEN ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) <= 0 
						THEN 0
					-- Rembourse tout s'il n'y a pas de cotisations subventionnées
					WHEN ISNULL(G.fCotisationGranted, 0) = 0 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse tout si on retire toutes les cotisations subventionnées
					WHEN Ct.Cotisation + Ct.Fee > ISNULL(G.fCotisationGranted, 0) 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
					WHEN ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / ISNULL(G.fCotisationGranted, 0) * ((Ct.Cotisation + Ct.Fee)*-1), 2) > ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0) 
						THEN -(ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0))
					-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
					ELSE 
						-(ROUND((ISNULL(G.fCESG + G.fACESG, 0) + ISNULL(C4.fCESG, 0)) / ISNULL(G.fCotisationGranted, 0) * ((Ct.Cotisation + Ct.Fee)*-1), 2))
				END,

				-- SCEE+
				CASE
					-- Rembourse rien 0.00 si le solde de subvention et négatif ou à 0.00
					WHEN ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0) <= 0 
						THEN 0
					-- Rembourse tout s'il n'y a pas de cotisations subventionnées
					WHEN ISNULL(G.fCotisationGranted, 0) = 0 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse tout si on retire toutes les cotisations subventionnées
					WHEN Ct.Cotisation + Ct.Fee > ISNULL(G.fCotisationGranted, 0) 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse tout si le proprata selon la formule A/B*C du règlement sur l’épargne-études est plus élevé que le total de la SCEE
					WHEN ROUND((ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)) / ISNULL(G.fCotisationGranted, 0) * ((Ct.Cotisation + Ct.Fee)*-1), 2) > ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0) 
						THEN -(ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0))
					-- Rembourse au proprata selon la formule A/B*C du règlement sur l’épargne-études si on retire seulement une partie des cotisations subventionnées
					ELSE 
						-(ROUND((ISNULL(G.fACESG, 0) + ISNULL(C4.fACESGPart, 0)) / ISNULL(G.fCotisationGranted, 0) * ((Ct.Cotisation + Ct.Fee)*-1), 2))
				END,

				0,
				0,
				0,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				0,
				0,
				0,
				0,
				NULL
			FROM @tBatchRESUnit BR
			JOIN Un_Cotisation Ct ON Ct.UnitID = BR.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			LEFT JOIN ( -- Solde SCEE et SCEE+ et solde de cotisations subventionnées
				SELECT
					V.ConventionID,

					-- Solde de la SCEE et SCEE+
					fCESG = SUM(fCESG), 
					fACESG = SUM(fACESG), 

					fCotisationGranted = SUM(fCotisationGranted) -- Solde des cotisations subventionnées
				FROM (
					SELECT DISTINCT 
						ConventionID
					FROM @tBatchRESUnit B
					JOIN dbo.Un_Unit U ON B.UnitID = U.UnitID
					) V
				JOIN Un_CESP G ON G.ConventionID = V.ConventionID
				GROUP BY V.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					V.ConventionID,

					-- Solde de la SCEE et SCEE+
					fCESG = SUM(C4.fCESG),
					fACESGPart = SUM(C4.fACESGPart) 
				FROM (
					SELECT DISTINCT 
						ConventionID
					FROM @tBatchRESUnit B
					JOIN dbo.Un_Unit U ON B.UnitID = U.UnitID
					) V
				JOIN Un_CESP400 C4 ON C4.ConventionID = V.ConventionID
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
				GROUP BY V.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.OperID = @iStartOperIDRES + BR.iAddToOperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND O.OperTypeID = 'RES'
				AND O.OperID NOT IN ( -- Va chercher le dernier RES de la convention
						SELECT 
							OperID = MAX(O.OperID)
						FROM @tBatchRESUnit BR
						JOIN dbo.Un_Unit U ON U.UnitID = BR.UnitID
						JOIN Un_Cotisation Ct ON Ct.UnitID = BR.UnitID
						JOIN Un_Oper O ON O.OperID = Ct.OperID
						WHERE Ct.OperID = @iStartOperIDRES + BR.iAddToOperID
							AND O.OperTypeID = 'RES'
						GROUP BY U.ConventionID 
						)

		IF @@ERROR <> 0
			SET @iResult = -15
	END

	IF @iResult > 0
	BEGIN
		-- Génération des 400 de résiliation 21-3 sur les RES
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
				21,
				3,
				'FIN',
				Ct.EffectDate,
				P.PlanGovernmentRegNo,
				C.ConventionNo,
				ISNULL(HS.SocialNumber,''),
				HB.SocialNumber,
				0,
				C.bCESGRequested,
				NULL,
				NULL,

				-- Rembourse la totalité de la subvention
				-(ISNULL(G.fCESG + G.fACESG,0) + ISNULL(C4.fCESG,0)),
				-(ISNULL(G.fACESG,0) + ISNULL(C4.fACESGPart,0)),

				0,
				0,
				0,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				NULL,
				-- Rembourse la totalité du BEC
				-(ISNULL(G.fCLB,0)+ISNULL(C4.fCLB,0)),
				0,
				0,
				0,
				NULL
			FROM @tBatchRESUnit BR
			JOIN Un_Cotisation Ct ON Ct.UnitID = BR.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
			JOIN dbo.Mo_Human HB ON HB.HumanID = B.BeneficiaryID
			JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
			LEFT JOIN ( -- Solde SCEE et SCEE+ et solde de BEC
				SELECT
					V.ConventionID,

					-- Solde de la SCEE et SCEE+
					fCESG = SUM(fCESG), 
					fACESG = SUM(fACESG), 

					fCLB = SUM(fCLB) -- Solde de BEC
				FROM (
					SELECT DISTINCT 
						ConventionID
					FROM @tBatchRESUnit B
					JOIN dbo.Un_Unit U ON B.UnitID = U.UnitID
					) V
				JOIN Un_CESP G ON G.ConventionID = V.ConventionID
				GROUP BY V.ConventionID
				) G ON G.ConventionID = C.ConventionID
			LEFT JOIN ( -- Solde SCEE et SCEE+ à rembourser
				SELECT
					V.ConventionID,

					-- Solde de la SCEE et SCEE+ à rembourser
					fCESG = SUM(C4.fCESG), 
					fACESGPart = SUM(C4.fACESGPart), 

					fCLB = SUM(C4.fCLB) -- Solde de BEC à rembourser
				FROM (
					SELECT DISTINCT 
						ConventionID
					FROM @tBatchRESUnit B
					JOIN dbo.Un_Unit U ON B.UnitID = U.UnitID
					) V
				JOIN Un_CESP400 C4 ON C4.ConventionID = V.ConventionID
				LEFT JOIN Un_CESP900 C9 ON C9.iCESP400ID = C4.iCESP400ID
				LEFT JOIN Un_CESP CE ON CE.OperID = C4.OperID
				WHERE C9.iCESP900ID IS NULL
					AND C4.iCESP800ID IS NULL
					AND CE.iCESPID IS NULL
				GROUP BY V.ConventionID
				) C4 ON C4.ConventionID = C.ConventionID
			WHERE Ct.OperID = @iStartOperIDRES + BR.iAddToOperID
				AND dbo.FN_CRQ_DateNoTime(ISNULL(C.dtRegStartDate,Ct.EffectDate+1)) <= Ct.EffectDate
				AND ISNULL(HB.SocialNumber,'') <> ''
				AND O.OperTypeID = 'RES'
				AND O.OperID IN ( -- Va chercher le dernier RES de la convention
						SELECT 
							OperID = MAX(O.OperID)
						FROM @tBatchRESUnit BR
						JOIN dbo.Un_Unit U ON U.UnitID = BR.UnitID
						JOIN Un_Cotisation Ct ON Ct.UnitID = BR.UnitID
						JOIN Un_Oper O ON O.OperID = Ct.OperID
						WHERE Ct.OperID = @iStartOperIDRES + BR.iAddToOperID
							AND O.OperTypeID = 'RES'
						GROUP BY U.ConventionID 
						)

		IF @@ERROR <> 0
			SET @iResult = -16
	END

	IF @iResult > 0
	BEGIN
		-- Inscrit le vcTransID avec le ID FIN + <iCESP400ID>.
		UPDATE Un_CESP400
		SET vcTransID = 'FIN'+CAST(iCESP400ID AS VARCHAR(12))
		WHERE vcTransID = 'FIN' 

		IF @@ERROR <> 0
			SET @iResult = -17
	END

	IF @iResult > 0
	BEGIN
		--Commande des lettres de résiliation "sans NAS - aucune épargne"
		DECLARE @ConventionID INTEGER

		DECLARE CUR_ConventionNoNASNoCotisation	CURSOR FOR
			SELECT DISTINCT C.ConventionID
			FROM @tBatchRESUnit BRU			
			JOIN dbo.Un_Unit U ON BRU.UnitID = U.UnitID
			JOIN Un_UnitReduction UR ON UR.UnitID = U.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
			JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = BRU.UnitReductionReasonID		
			JOIN (	SELECT 
						CCS.ConventionID,
						MaxDate = MAX(CCS.StartDate)
					FROM Un_Cotisation Ct
					JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
					JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = U.ConventionID
					JOIN @tBatchRESUnit BRU ON BRU.UnitID = U.UnitID
					GROUP BY CCS.ConventionID
					) CS ON U.ConventionID = CS.ConventionID
			JOIN Un_ConventionConventionState CCS ON CCS.ConventionID = CS.ConventionID AND CCS.StartDate = CS.MaxDate
			WHERE urr.UnitReductionReasonID = 7 --URR.UnitReductionReason = 'sans NAS après un (1) an'	
					AND UR.ReductionDate = ISNULL(U.TerminatedDate,0)
					AND CCS.ConventionStateID = 'FRM'
					AND Ct.Cotisation = 0.00
					AND ( Ct.OperID = @iStartOperIDRES + BRU.iAddToOperID
							OR	( Ct.OperID = @iStartOperIDTFR + BRU.iAddToOperID
									AND BRU.RESType = 'EPG'))					
					AND UR.UnitReductionID > @iStartUnitReductionID

		OPEN CUR_ConventionNoNASNoCotisation

		FETCH NEXT FROM CUR_ConventionNoNASNoCotisation
		INTO
			@ConventionID

		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC RP_UN_RESCheckWithoutNASAndCotisation @ConnectID, 	@ConventionID, 0

			FETCH NEXT FROM CUR_ConventionNoNASNoCotisation
			INTO
				@ConventionID
		END

		CLOSE CUR_ConventionNoNASNoCotisation
		DEALLOCATE CUR_ConventionNoNASNoCotisation	
	END
	
	-- Appelle la procédure qui met à jour les états des groupes d'units et des conventions
	IF @iResult > 0
	BEGIN
		DECLARE @UnitIDs VARCHAR(8000)
		SET @UnitIDs = ''
	
		SELECT
			@UnitIDs = @UnitIDs + CAST(U.UnitID AS VARCHAR(30)) + ', '
		FROM @tBatchRESUnit U

		IF @UnitIDs <> '' 
		BEGIN 
			SET @UnitIDs = LEFT(@UnitIDs, LEN(@UnitIDs) - 1)

			EXECUTE TT_UN_ConventionAndUnitStateForUnit @UnitIDs 
		END 

		IF @@ERROR <> 0
			SET @iResult = -18
	END 
	
	--DROP TABLE #ConventionBEC

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


