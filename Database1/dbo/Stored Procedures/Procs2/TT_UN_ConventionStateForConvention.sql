/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_ConventionStateForConvention
Description         :	Calcul l'état de la convention et le met à jour pour les conventions passés en paramètre.
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL
Exemple d'appel		: EXECUTE dbo.TT_UN_ConventionStateForConvention 240633

Note                :						    2004-06-11	Bruno Lapointe		Création Point 10.23.02
								ADX0000694	IA	2005-06-17	Bruno Lapointe		Ajout du paramètre @BlobID pour offrir une 
																							option qui permet de passer plus de ID
								ADX0001216	UR	2005-10-12	Bruno Lapointe		Changer les blobs pour une table temporaire pour
																							optimiser les performances.
								ADX0001095	BR	2005-12-15	Bruno Lapointe		Retour en arrière avec le paramètre VARCHAR(8000)
																							à cause du bogue de Deadlock.
								ADX0000834	IA	2006-06-28	Bruno Lapointe		Optimisation
												2009-11-10	Jean-F. Gauthier		Ajout des validations concernant le BEC actif
												2009-12-14	Jean-F. Gauthier		Ajout d'instructions lors que le statut de la convention passe de TRA à REE (formulaire RHDSC)
												2010-01-06	Jean-F. Gauthier		Correction d'un bug avec l'appel à la fonction pour l'historique BEC
												2010-01-07	Jean-F. Gauthier		Modification pour la gestion du BEC lorsque la convention est fermée
												2010-01-18	Jean-F. Gauthier		Modification afin d'utiliser une variable de type table plutôt que dans la table temporaire
																								dans la déclaration du curseur en raison d'un bug étrange
												2010-02-18	Jean-F. Gauthier		Ajout des appels à TT_UN_CLB																					
												2010-02-19	Jean-F. Gauthier		Correction pour un alias manquant
												2010-02-19	Pierre Paquet			Correction d'un NULL - NOT NULL
												2010-05-02	Pierre Paquet			Correction: appel au transfert plutôt qu'à la demande.
												2010-05-17	Pierre Paquet			Correction: pour la résiliation en lot..vérifier s'il y a une désactivation.
												2010-05-26	Pierre Paquet			Correction: Ajout de la vérification de tiCESPState (2,4).
												2010-05-27	Pierre Paquet			Correction: Utilisation de bCLBRequested
												2010-09-14	Pierre Paquet			Correction: Ajout du PRP dans le traitement des cases à cocher.
												2014-11-07	Pierre-Luc Simard	Appeler la procédure psCONV_EnregistrerPrevalidationPCEE pour gérer les prévalidations du PCEE
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_ConventionStateForConvention] 
				(@ConventionIDs VARCHAR(8000)) 	-- String de IDs Unique de conventions séparé par des virgules
AS
BEGIN
	DECLARE 
			@iID_Convention		INT
			,@iID_Beneficiaire	INT
			,@iID_Connect		INT
			,@iRetour			INT
			,@iIDConventionREE  INT
			,@iID_ConventionOUT INT
			,@iID_ConventionIN	INT
			,@dDate_Transfert	DATETIME

	-- Crée un table temporaire dans laquel on insérera le contenu que retournera la fonction dbo.FN_CRQ_IntegerTable
	CREATE TABLE #ConventionIDs 
		(
			ConventionID				INT PRIMARY KEY
			,ConventionNo				VARCHAR(15)
			,cStatutInitialConvention	CHAR(3)
			,cNouveauStatutConvention	CHAR(3)	
			,bBECActif					BIT	
			,iIDBeneficiaire			INT	
			,iIDConventionBecSuggere	INT	
			,vcAction					VARCHAR(75)
			,vcNASBeneficiaire			VARCHAR(75)
		) 

	SET @dDate_Transfert = GETDATE()
	
	INSERT INTO #ConventionIDs		-- Insertion des informations sur la convention
	(
		ConventionID
		,ConventionNo
		,cStatutInitialConvention
		,bBECActif
		,iIDBeneficiaire
		,iIDConventionBecSuggere
		,vcAction
		,vcNASBeneficiaire
	)	
	SELECT 
		DISTINCT 
		f.Val
		,c.ConventionNo
		,dbo.fnCONV_ObtenirStatutConventionEnDate(f.Val, GETDATE())
		--,dbo.fnPCEE_ValiderPresenceBEC(f.Val)
		,c.bCLBRequested
		,c.BeneficiaryID
		,dbo.fnCONV_ObtenirConventionBEC(c.BeneficiaryID, 1, f.Val)
		,(SELECT TOP 1 f.vcAction FROM dbo.fntPCEE_ObtenirHistoriqueBEC(c.BeneficiaryID, 'FRA') f WHERE c.ConventionNo = f.ConventionNo ORDER BY f.dtOperDate DESC)	-- ON VEUT L'ACTION DE LA DERNIÈRE OPÉRATION SUR LA CONVENTION			
		,H.SocialNumber
	FROM 
		dbo.FN_CRQ_IntegerTable(@ConventionIDs) f
		INNER JOIN dbo.Un_Convention c
			ON c.ConventionID = f.Val
		INNER JOIN dbo.MO_Human H
			ON C.BeneficiaryID = H.HumanID

	-- Va chercher l'état de premier niveau du groupe d'unités
	SELECT 
		U.ConventionID,
		Unit1LevelStateID = 
			CASE 
				WHEN CS3.UnitStateID IS NOT NULL THEN CS3.UnitStateID -- Regarde si c'était un état de troisième niveau
				WHEN CS2.UnitStateID IS NOT NULL THEN CS2.UnitStateID -- Regarde si c'était un état de deuxième niveau
			ELSE CS.UnitStateID -- Regarde si c'était un état de premier niveau
			END
	INTO #Unit1LevelStateID
	FROM dbo.Un_Unit U
	JOIN #ConventionIDs C ON U.ConventionID = C.ConventionID
	JOIN Un_UnitUnitState UUS ON UUS.UnitID = U.UnitID
	JOIN (
		SELECT
			USS.UnitID,
			StartDate = MAX(USS.StartDate) 
		FROM #ConventionIDs C
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_UnitUnitState USS ON USS.UnitID = U.UnitID
		GROUP BY USS.UnitID
		) UMX ON UMX.UnitID = U.UnitID AND UMX.StartDate = UUS.StartDate
	LEFT JOIN Un_ConventionState CS ON UUS.UnitStateID = CS.UnitStateID
	LEFT JOIN Un_UnitState US ON UUS.UnitStateID = US.UnitStateID
	LEFT JOIN Un_ConventionState CS2 ON US.OwnerUnitStateID = CS2.UnitStateID
	LEFT JOIN Un_UnitState US2 ON US2.UnitStateID = US.OwnerUnitStateID
	LEFT JOIN Un_ConventionState CS3 ON US2.OwnerUnitStateID = CS3.UnitStateID

	-- Calcul et insère le nouvelle état s'il y a lieu
	INSERT INTO Un_ConventionConventionState
		SELECT DISTINCT
			U.ConventionID,
			CS.ConventionStateID,
			GETDATE()
		FROM #Unit1LevelStateID U
		JOIN Un_ConventionState CS ON (CS.UnitStateID = U.Unit1LevelStateID)
		JOIN (
			SELECT
				ConventionID,
				PriorityLevelID = MIN(CS.PriorityLevelID)
			FROM #Unit1LevelStateID U
			JOIN Un_ConventionState CS ON (CS.UnitStateID = U.Unit1LevelStateID)
			GROUP BY ConventionID
			) V ON (V.ConventionID = U.ConventionID) AND (CS.PriorityLevelID = V.PriorityLevelID)
		-- Va chercher l'état actuel de la convention
		LEFT JOIN (
			SELECT 
				CS.ConventionID,
				CS.ConventionStateID
			FROM Un_ConventionConventionState CS
			JOIN (
				SELECT 
					CSS.ConventionID,
					StartDate = MAX(CSS.StartDate) 
				FROM #ConventionIDs C
				JOIN Un_ConventionConventionState CSS ON CSS.ConventionID = C.ConventionID
				GROUP BY CSS.ConventionID
				) V ON V.ConventionID = CS.ConventionID AND CS.StartDate = V.StartDate
			) EA ON EA.ConventionID = U.ConventionID
		-- S'assure que l'état actuel de la convention est différent que celui calculé pour ne pas insérer d'historique inutilement
		WHERE EA.ConventionID IS NULL
			OR EA.ConventionStateID <> CS.ConventionStateID

	--2009-11-11 : JFG : Vérification si la convention est passé à l'état 'FRM' (fermé)	
	UPDATE 	#ConventionIDs			-- Insertion du nouveau statut de la convention
	SET		cNouveauStatutConvention = dbo.fnCONV_ObtenirStatutConventionEnDate(ConventionID, GETDATE())
	
	DECLARE @tConventionATraiter TABLE
									(
									ConventionID		INT
									,iIDBeneficiaire	INT		
									)	

	INSERT INTO	@tConventionATraiter		
	(
		ConventionID		
		,iIDBeneficiaire	
	)
	SELECT					-- RETOURNE LES CONVENTIONS PASSANT AU STATUT FERMÉ AYANT UN BEC ACTIF ET 
								-- DONT LE BEC N'A PAS ÉTÉ GÉRÉ
		t.ConventionID				
		,t.iIDBeneficiaire			
	FROM 
		#ConventionIDs t
	WHERE
		t.bBECActif = 1							-- BEC ÉTAIT ACTIF SUR LA CONVENTION 
		AND
		t.cNouveauStatutConvention = 'FRM'		-- CONVENTION QUI PASSE À FERMER
		AND
		t.vcAction NOT IN (	
							SELECT
								dbo.fnPCEE_ObtenirDescActionBEC('BEC003', 'FRA') -- BEC désactivé donc géré
							UNION ALL
							SELECT
								dbo.fnPCEE_ObtenirDescActionBEC('BEC005', 'FRA') -- TRANSFERT OUT donc géré
							UNION ALL
							SELECT
								dbo.fnPCEE_ObtenirDescActionBEC('BEC006', 'FRA') -- REMBOURSEMENT donc géré
							)

	DECLARE curConvention CURSOR LOCAL FAST_FORWARD
	FOR
		SELECT					-- RETOURNE LES CONVENTIONS PASSANT AU STATUT FERMÉ AYANT UN BEC ACTIF ET 
								-- DONT LE BEC N'A PAS ÉTÉ GÉRÉ
			t.ConventionID				
			,t.iIDBeneficiaire			
		FROM 
			@tConventionATraiter t

	-- Gestion du BEC pour toutes les conventions présentes dans le curseur
	SELECT
		@iID_Connect = d.iID_Utilisateur_Systeme
	FROM
		dbo.Un_Def d
/*
	OPEN curConvention
	FETCH NEXT FROM curConvention INTO @iID_Convention, @iID_Beneficiaire
	WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @iIDConventionREE = NULL

			-- Vérifier le bénéficiaire à une autre convention 'REE'
			SELECT @iIDConventionREE = c.ConventionID 
			FROM dbo.Un_Convention c 
			WHERE	c.BeneficiaryId = @iID_Beneficiaire
					AND
					dbo.fnCONV_ObtenirStatutConventionEnDate (c.ConventionID, GETDATE()) = 'REE' 

			IF @iIDConventionREE IS NULL -- Dans la négative, on désactive le BEC
				BEGIN
					
					EXECUTE  @iRetour = dbo.psPCEE_DesactiverBec @iID_Beneficiaire ,@iID_Connect
				END
			ELSE	-- On crée un transfert de BEC vers une autre convention. 2010-05-02 Pierre Paquet
				BEGIN
					
				-- Récupérer la convention ayant le BEC.
				SET @iID_ConventionOUT = (SELECT dbo.fnCONV_ObtenirConventionBEC (@iID_Beneficiaire, 0, NULL))

				-- Récupérer la convention du bénéficiaire suggéré pour le transfert
				SET @iID_ConventionIN = (SELECT dbo.fnCONV_ObtenirConventionBEC (@iID_Beneficiaire, 1, @iID_ConventionOUT))
				
				-- Créer le transfert entre les 2 conventions.
				EXECUTE @iRetour = dbo.psPCEE_CreerTransfertBEC @iID_ConventionOUT, @iID_ConventionIN, @dDate_Transfert, @iID_Connect
				END

			FETCH NEXT FROM curConvention INTO @iID_Convention, @iID_Beneficiaire
		END
	CLOSE curConvention
	DEALLOCATE curConvention
*/	
	DROP TABLE #Unit1LevelStateID

	-- Gère le cas ou l'on supprime tous les groupes d'unités, dans ce cas l'état de la convention doit être proposition.
	INSERT INTO Un_ConventionConventionState
		SELECT DISTINCT
			C.ConventionID,
			'PRP',
			GETDATE()
		FROM dbo.Un_Convention C
		JOIN #ConventionIDs CI ON CI.ConventionID = C.ConventionID
		LEFT JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		-- Va chercher l'état actuel de la convention
		LEFT JOIN (
			SELECT 
				CS.ConventionID,
				CS.ConventionStateID
			FROM Un_ConventionConventionState CS
			JOIN (
				SELECT 
					CSS.ConventionID,
					StartDate = MAX(CSS.StartDate) 
				FROM #ConventionIDs C
				JOIN Un_ConventionConventionState CSS ON CSS.ConventionID = C.ConventionID
				GROUP BY CSS.ConventionID
				) V ON V.ConventionID = CS.ConventionID AND CS.StartDate = V.StartDate
			) EA ON EA.ConventionID = U.ConventionID
		-- S'assure que l'état actuel de la convention est différent que celui calculé pour ne pas insérer d'historique inutilement
		WHERE U.UnitID IS NULL
			AND( EA.ConventionID IS NULL
				OR EA.ConventionStateID <> 'PRP'
				)

-- 2009-12-14 : Modification pour Formulaire RHDSC 

	-- Si le statut passe de 'TRA' à 'REE' alors il faut cocher la case SCEE
	-- pour toutes les conventions où le formulaire a été reçu  = 1
/*
	UPDATE c
	SET c.bCESGRequested = 1
	FROM
		dbo.Un_Convention c
		INNER JOIN #ConventionIDs t
			ON c.ConventionID = t.ConventionID
	WHERE
		c.bFormulaireRecu			= 1
		AND
		--t.cStatutInitialConvention	= 'TRA'
		t.cStatutInitialConvention	IN ('TRA', 'PRP')  -- 2010-09-14
		AND 
		t.cNouveauStatutConvention	= 'REE'

	-- Si le statut passe 'TRA' à  'REE' et que les informations du principal responsable
	-- sont présentes (NAS, Nom, Prenom) et que les cases Formulaire reçu (bFormulaireRecu = 1) et SCEE (bCESGRequested = 1) sont
	-- cochés, alors il faut cocher la case SCEE+ (bACESGRequested = 1)
	UPDATE c
	SET bACESGRequested = 1
	FROM
		dbo.Un_Beneficiary b
		INNER JOIN dbo.Un_Convention c
			ON b.BeneficiaryID = c.BeneficiaryID
		INNER JOIN #ConventionIDs t
			ON c.ConventionID = t.ConventionID
	WHERE
		(b.vcPCGSINorEN IS NOT NULL AND b.vcPCGSINorEN <>'')
		AND 
		(b.vcPCGFirstName IS NOT NULL AND b.vcPCGFirstName <>'')
		AND
		(b.vcPCGLastName IS NOT NULL AND b.vcPCGLastName <>'')
		AND
		c.bCESGRequested = 1
		AND
		c.bFormulaireRecu			= 1
		AND
		--t.cStatutInitialConvention	= 'TRA'
		t.cStatutInitialConvention	IN ('TRA', 'PRP')  -- 2010-09-14
		AND 
		t.cNouveauStatutConvention	= 'REE'

	-- Vérifier le bénéficiaire a une Convention dans laquelle le BEC serait actif
	-- Dans la négative, activer le BEC sur la convention suggérée
	DECLARE 
		@tConventionMaj	TABLE	
							(
								iConventionID	INT PRIMARY KEY
							)
							
	DECLARE @iMaxConventionID	INT
	
	-- S'il n'y a pas de transaction de demande de BEC 'En attente' alors on en créé une nouvelle sinon on skip.
	UPDATE c
	SET	bCLBRequested = 1
	OUTPUT INSERTED.ConventionID INTO @tConventionMaj
	FROM
		dbo.Un_Convention c
		INNER JOIN #ConventionIDs t
			ON c.BeneficiaryID = t.iIDBeneficiaire AND c.ConventionID = t.iIDConventionBecSuggere
		INNER JOIN dbo.Un_Beneficiary b
			ON c.BeneficiaryID = b.BeneficiaryID
	WHERE
		c.tiCESPState IN (2,4) -- 2010-05-26 PPA.
		AND
		b.tiCESPState IN (2,4) -- 2010-05-26 PPA.
		AND
		-- 2010-09-14 PPA
		(b.vcPCGSINorEN IS NOT NULL AND b.vcPCGSINorEN <>'')
		AND 
		(b.vcPCGFirstName IS NOT NULL AND b.vcPCGFirstName <>'')
		AND
		(b.vcPCGLastName IS NOT NULL AND b.vcPCGLastName <>'')
		AND
		t.iIDBeneficiaire NOT IN	
								(
								SELECT							-- Élimine les bénéficiaires qui ont déjà un BEC actif
									DISTINCT iIDBeneficiaire
								FROM 
									#ConventionIDs
								WHERE
									bBECActif = 1
								)
		AND
		t.iIDBeneficiaire NOT IN  -- On s'assure que le bénéficiare n'a pas déjà une convention avec un BEC dedans.
								(
								SELECT 
									DISTINCT BeneficiaryID
								FROM
									dbo.UN_Convention C
								WHERE t.iIDBeneficiaire = C.BeneficiaryID
									AND C.bCLBRequested = 1
								) 
		AND c.ConventionID NOT IN -- On s'assurer que le BEC n'a pas été désactivé ou remboursé.
								(
								SELECT
									Cs.ConventionID
								FROM
									#ConventionIDs Cs
									LEFT OUTER JOIN dbo.UN_CESP400 C4 
										ON C4.ConventionID = Cs.ConventionID
									LEFT OUTER JOIN Un_CESP400 R4 
										ON R4.iReversedCESP400ID = C4.iCESP400ID				
								WHERE
									((C4.tiCESP400TypeID = '24' AND C4.bCESPDemand = '0')
										OR (C4.tiCESP400TypeID = '21' AND C4.fCLB <> 0))
																						
									AND 
									C4.iCESP800ID IS NULL
									AND 
									C4.iReversedCESP400ID IS NULL -- Pas une annulation
									AND 
									R4.iCESP400ID IS NULL -- Pas annulé 
									AND C4.vcBeneficiarySIN = (SELECT H.SocialNumber 
																FROM dbo.Mo_Human H 
																LEFT JOIN dbo.UN_Convention C 
																	ON C.BeneficiaryID = H.HumanID 
																WHERE C.ConventionID = Cs.ConventionID)

								)
		AND t.vcNASBeneficiaire NOT IN (
										SELECT vcBeneficiarySIN
										FROM dbo.UN_CESP400 C400 
										WHERE C400.tiCESP400TypeId = 24
										--AND C400.bCESPDemand = 1
										AND C400.iCESPSendFileID IS NULL
										)
*/
	-- Boucler sur les changements de PRP ou TRA vers REE afin de mettre à jour les prévalidations et le BEC
	DECLARE @iMaxConventionID	INT

	SELECT 
		@iMaxConventionID = MAX(t.ConventionID) 
	FROM #ConventionIDs t
	WHERE t.cStatutInitialConvention	IN ('TRA', 'PRP') 
		AND t.cNouveauStatutConvention	= 'REE'

	WHILE @iMaxConventionID	IS NOT NULL
		BEGIN
			EXEC @iRetour = psCONV_EnregistrerPrevalidationPCEE @iID_Connect, @iMaxConventionID, NULL, NULL, NULL
			
			UPDATE dbo.Un_Convention
			   SET IdSouscripteurOriginal = SubscriberID
			 WHERE ConventionID = @iMaxConventionID And IdSouscripteurOriginal IS NULL

			SELECT 
				@iMaxConventionID = MAX(t.ConventionID) 
			FROM #ConventionIDs t
			WHERE t.cStatutInitialConvention	IN ('TRA', 'PRP') 
				AND t.cNouveauStatutConvention	= 'REE'
				AND t.ConventionID < @iMaxConventionID	
		END

/* -- Le BEC est maintenant géré dans la procédure psCONV_EnregistrerPrevalidationPCEE
	SELECT 
		@iMaxConventionID = MAX(t.ConventionID) 
	FROM #ConventionIDs t
	JOIN dbo.Un_Convention C ON C.ConventionID = t.ConventionID
	WHERE t.bBECActif <> C.bCLBRequested
	
	-- Boucler à travers les conventions qui ont changé d'état de BEC pour créer les demandes		
	DECLARE @dtToday DATETIME
	DECLARE @dDateEntreeREEE DATETIME
	SET @dtToday = (GETDATE())

	WHILE @iMaxConventionID	IS NOT NULL
		BEGIN
			SET @dDateEntreeREEE = (SELECT dtRegStartDate FROM dbo.UN_Convention WHERE ConventionID = @iMaxConventionID)
		
			-- S'il y a une convention BEC et une date dtRegStartDAte, alors on génère la transaction 400.
			IF (dbo.FN_CRQ_DateNoTime(@dDateEntreeREEE) <= @dtToday) -- Ne pas créer de BEC avant la date d'entrée en REEE
			BEGIN
				EXECUTE TT_UN_CLB @iMaxConventionID		-- pour les conventions mis à jour par le UPDATE précédent
			END
			
			SELECT 
				@iMaxConventionID = MAX(t.ConventionID) 
			FROM #ConventionIDs t
			JOIN dbo.Un_Convention C ON C.ConventionID = t.ConventionID
			WHERE t.bBECActif <> C.bCLBRequested
				AND t.ConventionID < @iMaxConventionID	
		END
*/		
	DROP TABLE #ConventionIDs
END
