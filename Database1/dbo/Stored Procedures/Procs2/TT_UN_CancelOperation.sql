/********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : 	TT_UN_CancelOperation
Description         : 	Créé une opération annulant l'opération passé en paramètre
Valeurs de retours  : 	>0 	: Pas d'erreur, corresponds au dernier OperID de l'opération d'annulation
								<=0	: Erreurs
									-1 	On ne peut pas annuler un NSF provenant d'un fichier bancaire.
									-2	On ne peut pas annuler ce type d'opération.
									-3	On ne peut pas annuler une avance de bourse (AVC) si le versement de la bourse (PAE) a déjà été fait.  Annulez le versement d'abord.
									-4 	Message d’erreur : On a émis un chèque pour cette opération qui n'a pas été refusé ou annulé.
									-5 	Message d’erreur : L'opération est barrée par la fenêtre de validation des changements de destinataire.
									-6 	Message d’erreur : Une opération de résiliation ne peut être annulée lorsque qu’un transfert de frais utilise les frais associés aux unités résiliées.
									-7 	Message d’erreur : Une opération de transfert OUT ne peut être annulée lorsque qu’un transfert de frais utilise les frais associés aux unités résiliées.	
									-8	Message d’erreur : Une opération de transfert TIO ne peut être annulée lorsque une convention est immobilisée.							
									-101	Erreur à l'insertion d'une opération d'annulation.
									-102	Erreur lors de la mise à jour de la table temporaire.
									-103	Erreur lors de l'insertion du lien entre l'opération annulér et l'opération qui l'annule.
									-104	Erreur lors de l'insertion de cotisation.
									-105	Erreur lors de l'insertion d'un transfert externe.
									-106	Erreur lors de l'insertion d'opération sur convention.
									-107	Erreur lors de l'insertion d'opération sur plan.
									-108	Erreur lors de l'insertion d'opération dans les autres comptes.
									-109	Erreur lors de l'insertion de lien entre une bourse et l'opération d'annulation.
									-110	Erreur lors de mise à jour du statut de la bourse.
									-111	Erreur lors de l'annulation de la SCÉÉ de l'opération.
									-112	Erreur lors de l'annulation de la SCÉÉ de l'opération.
									-120	Erreur lors de la mise à jour de groupe d'unités.
									-121	Erreur lors de la recherche du ID de remboursement intégral.
									-122	Erreur lors d'insertion de lien entre l'historique du remboursement intégral et les opérations d'annulation.
									-123	Erreur lors de la redirection du lien NSF.
									-124	Erreur lors de la redirection du lien NSF.
									-125	Erreur lors de la recherche d'une historique de réduction d'unités.
									-126	Erreur l'insertion d'un historique de réduction d'unités.
									-127	Erreur l'insertion de lien entre historique de réduction d'unités et les cotisations.
									-128	Erreur lors de la mise à jour de groupe d'unités.
									-129	Erreur lors de la création d'exceptions de commissions.
									-130	Erreur lors de la création de lien entre des exceptions de commissions et une historique de reduction d'unités.
									-131	Erreur lorsque le système marque l'opération annul dans le module des chèques.
									-132	Erreur lors de l'insertion d'une étape de PAE.
									-133	Erreur lors de l'insertion d'une étape de RIN.
									-300 à -349 Erreurs lors de l'annulation de la SCÉÉ d'une opération annulée.
									-350 à -399 Erreurs lors de la génération d'une nouvelle demande de subvention pour l'opération qui n'est plus NSF.

Note                :			ADX0000635	IA	2005-01-11	Bruno Lapointe		Création
								ADX0001505	BR	2005-07-11	Bruno Lapointe		Correction du problème de subvention des annulations de TIN  
																							et de OUT qui n'ont pas été expédié à la SCEE.
								ADX0000720	IA	2005-07-19	Bruno Lapointe		Permettre l’annulation d’opération de type CPA. 
								ADX0000753	IA	2005-10-05	Bruno Lapointe		Empêcher l’annulation financière de toutes opérations qui aura
																				un chèque lié qui n’est  pas annulé ou refusé. Quand on annulera
																				une opération de type RES, OUT, RET, RIN, PAE ou AVC, on
																				enlèvera la disponibilité de l’opération dans le module des
																				chèques. Ainsi, on ne pourra plus proposer de chèque pour cette
																				opération.
																				Nouveaux codes d’erreurs : 
																				-4 Message d’erreur : On a émis un chèque pour cette
																				opération qui n'a pas été refusé ou annulé.
																				-5 Message d’erreur : L'opération est barrée par la fenêtre de
																				validation des changements de destinataire.
								ADX0001602	BR	2005-10-11	Bruno Lapointe		SCOPE_IDENTITY au lieu de IDENT_CURRENT
								ADX0001614	BR	2005-10-17	Bruno Lapointe		Ramener à l'étape #4 les PAE suite à une annulation.
								ADX0001627	BR	2005-10-19	Bruno Lapointe		Ramener à l'étape #3 les RIN suite à une annulation.
								ADX0000833	IA	2006-04-10	Bruno Lapointe		Gestion des 400
								ADX0000992	IA	2006-05-23	Alain Quirion		Gestion de l'objet Un_OUT
								ADX0000925	IA	2006-06-05	Bruno Lapointe		Gestion de l'objet Un_TIN
								ADX0001064 	IA	2006-08-03	Mireya Gonthier		Opération financière : Ajustement comptable(AJU)
								ADX0001109	IA	2006-09-07	Bruno Lapointe		Annulation de CPA en date du CPA annulé.
								ADX0002093	BR	2006-09-22	Bruno Lapointe		La date effective des annulations doit être la même que celle de l'opération annulé et non en date de l'opération d'annulation.
								ADX0001100	IA	2006-10-24	Alain Quirion		Gestion de l'objet Un_TIO
								ADX0001119	IA	2006-11-01	Alain Quirion		Gestion des erreurs pour les frais disponibles utilisés
								ADX0002428	BR	2007-05-10	Alain Quirion		Annulation de l'opération TFR liée èa une résiliation
								ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
								ADX0002474	BR	2005-06-04	Alain Quirion		Modification : POur les TIO, OUT, TIN, les 400 ne sont jamais supprimés même s'ils ne sont pas envoyés.
								ADX0001355	IA	2007-06-06	Alain Quirion		Modification de la date d’entrée en vigueur TIN (dtInforceDateTIN) 
																                de la convention et du groupe d’unités s’il y a lieu.
                                       2010-01-19	Jean-F. Gauthier		Ajout du champ EligibilityConditionID
                                       2010-03-03	Danielle Côté			Ajout du traitement du type d'opération RDI
                                       2014-04-24	Pierre-Luc Simard	    Ajout de la gestion des statuts des conventions et des groupes d'unités pour les PAE et les RIN (Refonte)
									   2014-10-06	Pierre-Luc Simard	    Ne pas permettre l'annulation si une demande de décaissement a été faite pour cette opération, sans demande de non-décaissement
									   2016-03-09	Pierre-Luc Simard	    Ne plus bloquer l'annulation des RGC (Validation -2)
									   2016-04-27   Steeve Picard		    Forcer le «OtherConventionNo» en majuscule dans les tables «Un_TIN & Un_OUT»
									   2016-09-23	Donald Huppé		    Permettre de renverser une opération même s'il y a un CHQ ou DDD associé, pour certain usager : JTessier
									   2016-09-28	Donald Huppé		    Permettre de renverser une opération même s'il y a un CHQ ou DDD associé, pour certain usager : mcbreton
									   2017-04-20	Philippe Dubé-Tremblay  Interdire l'annulation d'une opération TIO si une convention est immobilisée
                                       2017-10-20   Pierre-Luc Simard       Mettre la bourse au statut Annulé (ANL) au lieu des Admissible (ADM)
									   2018-02-07	Donald Huppé			Retirer les validations -6 et -7 concernant la présence de TFR.  Depuis plusieures années, on les ignore quand on reçoit une demande 
																			JIRA pour renverser une RES ou un OUT. 
									   2018-09-07	Maxime Martel			JIRA MP-699 Ajout de OpertypeID COU
									   2018-11-21	Donald Huppé		    Permettre de renverser une opération même s'il y a un CHQ ou DDD associé, pour certain usager : chuppe
									   2019-01-04	Donald Huppé			à la demande de MC Breton, ne plus permettre de renverser une opération s'il y a un CHQ ou DDD valide
									   2019-01-18	Donald Huppé			à lad emande de MC Breton, permettre de renverser une opération s'il y a un DDD valide
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_CancelOperation]
(
	@ConnectID INTEGER,
	@OperID INTEGER     -- ID unique de l'opération à annuler
)
AS
BEGIN
	DECLARE
		@iResult INTEGER,
		@iSourceOperID INTEGER,
		@iOldCotisationID INTEGER,
		@iCotisationID INTEGER,
		@iOperID INTEGER,
		@iOperOfCancelID INTEGER,
		@iIntReimbID INTEGER,
		@iOldUnitReductionID INTEGER,
		@iUnitReductionID INTEGER,
		@iRepExceptionID INTEGER,
		@iRepExceptionIDBef INTEGER,
		@UnitID INTEGER,
		@dtOtherConvention DATETIME,
		@dtMinUnitInforceDateTIN DATETIME,
		@ConventionID INTEGER,
		@iID_RDI_Depot INT,
		@iID_RDI_Paiement INT,
		@iUnitID INTEGER,
		@vcUnitIDs VARCHAR(8000),
		@LoginNameID VARCHAR(24)


	SELECT @LoginNameID = u.LoginNameID 
	FROM Mo_Connect cn
	JOIN Mo_User u ON cn.UserID = u.UserID
	WHERE cn.ConnectID = @ConnectID
		AND ( 
				u.LoginNameID like '%jtessier%'
			OR	u.LoginNameID like '%mcbreton%'
			OR	u.LoginNameID like '%dhuppe%'
			--OR	u.LoginNameID like '%chuppe%'
			)


	-- Création d'une table temporaire qui contiendra les OperIDs
	DECLARE @OperTable TABLE (
		OperID INTEGER,
		OperOfCancelID INTEGER)

	-- Insertion des OperIDs dans la table temporaire
	INSERT INTO @OperTable
		SELECT 
			@OperID,
			0

	-- Insère les opérations reliés des remboursements intégraux
	INSERT INTO @OperTable
		SELECT
			IRO2.OperID,
			0
		FROM @OperTable OT
		JOIN Un_IntReimbOper IRO ON IRO.OperID = OT.OperID
		JOIN Un_IntReimbOper IRO2 ON IRO2.IntReimbID = IRO.IntReimbID AND IRO2.OperID <> IRO.OperID
		LEFT JOIN @OperTable OT2 ON OT2.OperID = IRO2.OperID
		WHERE OT2.OperID IS NULL

	IF EXISTS (	SELECT * 
			FROM @OperTable OD
			JOIN Un_Oper O ON O.OperID = OD.OperID
			WHERE O.OperTypeID = 'TIN')
	BEGIN	
		-- Insère les opérations liées du transfert interne (OUT)
		INSERT INTO @OperTable
			SELECT
				T.iOUTOperID,
				0
			FROM @OperTable OT
			JOIN Un_TIO T ON T.iTINOperID = OT.OperID		
			LEFT JOIN @OperTable OT2 ON OT2.OperID = T.iOUTOperID
			WHERE OT2.OperID IS NULL

		-- Insère les opérations liées du transfert interne (TFR)
		INSERT INTO @OperTable
			SELECT
				T.iTFROperID,
				0
			FROM @OperTable OT
			JOIN Un_TIO T ON T.iTINOperID = OT.OperID		
			LEFT JOIN @OperTable OT2 ON OT2.OperID = T.iTFROperID
			WHERE OT2.OperID IS NULL	
				AND iTFROperID IS NOT NULL		
	END
	ELSE IF EXISTS(	SELECT * 
			FROM @OperTable OD
			JOIN Un_Oper O ON O.OperID = OD.OperID
			WHERE O.OperTypeID = 'OUT')
		OR EXISTS(	SELECT * 
				FROM @OperTable OD
				JOIN Un_Oper O ON O.OperID = OD.OperID
				WHERE O.OperTypeID = 'TFR')
	BEGIN
		-- Insère les opérations reliés des transferts OUT
		INSERT INTO @OperTable
			SELECT
				Ct2.OperID,
				0
			FROM @OperTable OT
			JOIN Un_Cotisation Ct ON Ct.OperID = OT.OperID
			JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
			JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID  AND URC2.CotisationID <> URC.CotisationID
			JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
			LEFT JOIN @OperTable OT2 ON OT2.OperID = Ct2.OperID
			WHERE OT2.OperID IS NULL

		-- Insère les opérations liées du transfert interne (TIN)
		INSERT INTO @OperTable
			SELECT
				T.iTINOperID,
				0
			FROM @OperTable OT
			JOIN Un_TIO T ON T.iOUTOperID = OT.OperID		
			LEFT JOIN @OperTable OT2 ON OT2.OperID = T.iTINOperID
			WHERE OT2.OperID IS NULL		
	END
	ELSE IF EXISTS(	SELECT * 
			FROM @OperTable OD
			JOIN Un_Oper O ON O.OperID = OD.OperID
			WHERE O.OperTypeID = 'RES')
	BEGIN
		-- Insère les opérations reliés des résiliations
		INSERT INTO @OperTable
			SELECT
				Ct2.OperID,
				0
			FROM @OperTable OT
			JOIN Un_Cotisation Ct ON Ct.OperID = OT.OperID
			JOIN Un_UnitReductionCotisation URC ON URC.CotisationID = Ct.CotisationID
			JOIN Un_UnitReductionCotisation URC2 ON URC2.UnitReductionID = URC.UnitReductionID  AND URC2.CotisationID <> URC.CotisationID
			JOIN Un_Cotisation Ct2 ON Ct2.CotisationID = URC2.CotisationID
			LEFT JOIN @OperTable OT2 ON OT2.OperID = Ct2.OperID	
			WHERE OT2.OperID IS NULL
	END

	-- Insère les opérations reliés des paiements de bourses
	
	IF EXISTS (
			SELECT OT.OperID
			FROM @OperTable OT 
			JOIN Un_Oper O ON O.OperID = OT.OperID
			JOIN Un_ScholarshipPmt SP ON SP.OperID = O.OperID
			WHERE O.OperTypeID IN ('PAE','RGC'))
		INSERT INTO @OperTable
			SELECT
				O.OperID,
				0
			FROM @OperTable OT
			JOIN Un_ScholarshipPmt SP ON SP.OperID = OT.OperID
			JOIN Un_ScholarshipPmt SP2 ON SP2.ScholarshipID = SP.ScholarshipID AND SP2.OperID <> SP.OperID
			JOIN Un_Oper O ON O.OperID = SP2.OperID AND O.OperTypeID IN ('PAE','RGC')
			LEFT JOIN @OperTable OT2 ON OT2.OperID = O.OperID
			WHERE OT2.OperID IS NULL
			--AND O.OperID <> 20286516 -- GLPI 4871
			--and O.OperID NOT IN (21469476,21534180)--glpi 6607
			--and O.OperID NOT IN (21758120,22031088) -- glpi 7536
			--AND O.OperID <> 23266495 -- glpi 9328 : operid de l'autre opération qu'il ne faut pas annuler
			--AND O.OperID <> 23285782 -- glpi 9398 : operid de l'autre opération qu'il ne faut pas annuler
			--AND O.OperID NOT IN (23331291,23285336,23266495) -- glpi 9430
			--AND O.OperID NOT IN (23352089,23328329) -- glpi 9512
			--AND O.OperID NOT IN (23380130,23333424,23331291,23285336,23266495) -- glpi 9512
			--AND O.OperID NOT IN (23376501,23289066,23285782) -- glpi 9512
			--AND O.OperID NOT IN (23432079,23378213,23461330,23390319,21051154) -- glpi 9599
			--AND O.OperID NOT IN (23939565) -- glpi 10105
			--AND O.OperID NOT IN (23832690) --
			--AND O.OperID NOT IN (23771214,23929113) -- glpi 10125
			--AND O.OperID NOT IN (24181461) -- glpi 10713
			--AND o.OperID NOT IN (25191813)

   -- Annulation d'une Opérations RDI - récupérer le numéro du dépôt
   SET @iID_RDI_Depot = 0
   SET @iID_RDI_Paiement = 0 
   IF EXISTS (SELECT * 
                FROM @OperTable OD
                JOIN Un_Oper O ON O.OperID = OD.OperID
               WHERE O.OperTypeID = 'RDI')
   BEGIN
      SELECT @iID_RDI_Depot = P.iID_RDI_Depot
		      ,@iID_RDI_Paiement = P.iID_RDI_Paiement
        FROM tblOPER_RDI_Liens L
            ,tblOPER_RDI_Paiements P
       WHERE P.iID_RDI_Paiement = L.iID_RDI_Paiement
         AND L.OperID = @OperID
   END			

	-- Crée une chaîne de caractère avec tout les groupes d'unités affectés par la suppression d'un PAE ou d'un RIN
	-- Procédure TT_UN_ConventionAndUnitStateForUnit appelée à la fin du traitement
    DECLARE UnitIDs CURSOR
    FOR
        SELECT DISTINCT 
            U.UnitID
        FROM @OperTable OD
        JOIN Un_Oper O ON O.OperID = OD.OperID
        JOIN Un_ScholarshipPmt SP ON SP.OperID = O.OperID
        JOIN Un_Scholarship S ON S.ScholarshipID = SP.ScholarshipID
        JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
        JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
        WHERE O.OperTypeID = 'PAE'
        UNION 				
        SELECT DISTINCT
			CT.UnitID
		FROM @OperTable OD 
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

	-----------------
	BEGIN TRANSACTION
	-----------------

	SET @iResult = 1

	IF 	@iResult > 0
	AND	EXISTS	(
						SELECT 
							O.OperID
						FROM @OperTable O 
						JOIN Mo_BankReturnLink L ON O.OperID = L.BankReturnCodeID
						JOIN Mo_BankReturnFile F ON F.BankReturnFileID = L.BankReturnFileID
						)
		-- On ne peut pas annuler un NSF provenant d'un fichier bancaire
		SET @iResult = -1

	IF 	@iResult > 0
	AND	EXISTS	(
						SELECT 
							O.OperID
						FROM @OperTable OT
						JOIN Un_Oper O ON OT.OperID = O.OperID
						WHERE O.OperTypeID NOT IN ('AVC','CHQ','CPA','NSF','OUT','PAE','PEE','PRD','RES','RET','RIN','TFR','TIN','TRA','AJU','RDI','RGC','COU') -- 2016-03-09
						)
		-- On ne peut pas annuler ce type d'opération
		SET @iResult = -2

	IF 	@iResult > 0
	AND	EXISTS	(
						SELECT 
							O.OperID
						FROM @OperTable OT
						JOIN Un_Oper O ON OT.OperID = O.OperID
						JOIN Un_ScholarshipPmt SP ON SP.OperID = OT.OperID
						JOIN Un_ScholarshipPmt SP2 ON SP2.ScholarshipID = SP.ScholarshipID AND SP2.OperID <> SP.OperID
						JOIN Un_Oper O2 ON O2.OperID = SP2.OperID
						LEFT JOIN Un_OperCancelation OC ON OC.OperSourceID = SP2.OperID OR OC.OperID = SP2.OperID
						WHERE		O.OperTypeID = 'AVC'
							AND	O2.OperTypeID = 'PAE'
							AND	OC.OperSourceID IS NULL
						)
		-- On ne peut pas annuler une avance de bourse (AVC) si le versement de la bourse (PAE) a déjà été fait.  Annulez le versement d'abord.
		SET @iResult = -3

	-- Une demande de décaissement de dépôt direct a été faite
    -- PLS: Faudrait permettre d'annuler si la DDD a été annulé auparavant
	IF EXISTS (
		SELECT OT.OperID
		FROM @OperTable OT
		JOIN DecaissementDepotDirect DDD ON DDD.IdOperationFinanciere = OT.OperID
		WHERE OT.OperID NOT IN ( -- On permet l'annulation sur une demande de non décaissement a été faite
			SELECT OT.OperID
			FROM @OperTable OT
			JOIN DecaissementDepotDirect DDD ON DDD.IdOperationFinanciere = OT.OperID
			JOIN Demande DD ON DD.Id = DDD.IdDemande
			JOIN Demande DN ON DN.IdPreDemande = DD.IdPreDemande 
			JOIN DemandeDND DND ON DND.ID = DN.Id
			WHERE DND.TraitementDnd = 2
			)
		) 
		AND ISNULL(@LoginNameID,'') = '' -- RETIRÉ LE 2019-01-04 remis le 18 janv 2019
		SET @iResult = -4
		
	-- Un chèque a été émis
	IF EXISTS (
		SELECT OT.OperID
		FROM @OperTable OT
		JOIN Un_OperLinkToCHQOperation CO ON CO.OperID = OT.OperID
		JOIN CHQ_OperationDetail OD ON OD.iOperationID = CO.iOperationID
		JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID
		JOIN CHQ_Check C ON C.iCheckID = COD.iCheckID
		WHERE C.iCheckStatusID NOT IN (3,5) -- Pas refusé ou annulé
		) 
		--AND ISNULL(@LoginNameID,'') = '' -- RETIRÉ LE 2019-01-04
		SET @iResult = -4

	-- Opération barrée par le module des chèques
	IF EXISTS (
		SELECT OT.OperID
		FROM @OperTable OT
		JOIN Un_OperLinkToCHQOperation CO ON CO.OperID = OT.OperID
		JOIN CHQ_OperationLocked OL ON OL.iOperationID = CO.iOperationID
		)
		SET @iResult = -5

	-- -6 Erreur : Une opération de résiliation ne peut être supprimée lorsque qu’un transfert de frais utilise les frais associés aux unités résiliées. 

/* --Retiré le 2018-02-07
	IF EXISTS(
			SELECT
				A.OperID
			FROM Un_AvailableFeeUse A
			JOIN Un_UnitReduction UR ON UR.UnitReductionID = A.UnitReductionID
			JOIN Un_UnitReductionCotisation URC ON URC.UnitReductionID = UR.UnitReductionID
			JOIN Un_Cotisation CT ON CT.CotisationID = URC.CotisationID
			JOIN Un_Oper OP ON OP.OperID = CT.OperID
			JOIN @OperTable OD ON OD.OperID = OP.OperID
			WHERE OP.OperTypeID = 'RES'
				AND A.OperID NOT IN (SELECT @OperID FROM @OperTable) -- Le TFR n'est pas dans les opérations a supprimé
			)
			SET @iResult = -6
	*/

	-- -7 Erreur : Une opération de transfert OUT ne peut être supprimée lorsque qu’un transfert de frais utilise les frais associés aux unités résiliées.

/* --Retiré le 2018-02-07
	IF EXISTS(
			SELECT
				A.OperID
			FROM Un_AvailableFeeUse A
			JOIN Un_UnitReduction UR ON UR.UnitReductionID = A.UnitReductionID
			JOIN Un_UnitReductionCotisation URC ON URC.UnitReductionID = UR.UnitReductionID
			JOIN Un_Cotisation CT ON CT.CotisationID = URC.CotisationID
			JOIN Un_Oper OP ON OP.OperID = CT.OperID
			JOIN @OperTable OD ON OD.OperID = OP.OperID
			WHERE OP.OperTypeID = 'OUT'
				AND A.OperID NOT IN (SELECT @OperID FROM @OperTable) -- Le TFR n'est pas dans les opérations a annulée
			)
			SET @iResult = -7
*/

	IF 	@iResult > 0
	AND	EXISTS (
		SELECT CV.ConventionID
		FROM Un_Convention CV 
			JOIN Un_Unit UT ON UT.ConventionID = CV.ConventionID
			JOIN Un_Cotisation CT ON CT.UnitID = UT.UnitID
			JOIN Un_TIO TI ON TI.iTINOperID = CT.OperID	
			JOIN @OperTable OT2 ON OT2.OperID = TI.iTINOperID
		WHERE CV.tiMaximisationREEE = 2
		)
		SET @iResult = -8

			IF 	@iResult > 0
	AND	EXISTS (
		SELECT CV.ConventionID
		FROM Un_Convention CV 
			JOIN Un_Unit UT ON UT.ConventionID = CV.ConventionID
			JOIN Un_Cotisation CT ON CT.UnitID = UT.UnitID
			JOIN Un_TIO TI ON TI.iOUTOperID = CT.OperID	
			JOIN @OperTable OT2 ON OT2.OperID = TI.iOUTOperID
		WHERE CV.tiMaximisationREEE = 2
		)
		SET @iResult = -8

	-- Curseur annulant une opération à la fois.
	DECLARE crOper CURSOR 
	FOR
		SELECT OperID
		FROM @OperTable

	OPEN crOper

	FETCH NEXT FROM crOper
	INTO 
		@iOperID

	WHILE 	@@FETCH_STATUS = 0 
		AND 	@iResult > 0
	BEGIN

      INSERT INTO Un_Oper (
				OperTypeID, 
				OperDate, 
				ConnectID)
			SELECT
				OperTypeID, 
				CASE 
					WHEN OperTypeID = 'CPA' THEN OperDate
				ELSE dbo.FN_CRQ_DateNoTime(GETDATE())
				END, 
				@ConnectID
			FROM Un_Oper
			WHERE OperID = @iOperID

		-- Erreur à l'insertion d'une opération d'annulation
		IF @@ERROR <> 0
			SET @iResult = -101
		ELSE
		BEGIN
			SET @iOperOfCancelID = SCOPE_IDENTITY()
			-- Prend le premier OperID de l'opération d'annulation comme valeur de retour s'il n'y a pas d'erreurs
			IF @iResult = 1
				SET @iResult = @iOperOfCancelID
		END

		IF @iResult > 0
		BEGIN
			UPDATE @OperTable
			SET OperOfCancelID = @iOperOfCancelID
			WHERE OperID = @iOperID

         -- RDI
         IF EXISTS (SELECT * 
                      FROM @OperTable OD
                      JOIN Un_Oper O ON O.OperID = OD.OperID
                     WHERE O.OperTypeID = 'RDI')
         BEGIN                     
            INSERT INTO tblOPER_RDI_Liens
                  (iID_RDI_Paiement
                  ,OperID)
            VALUES (@iID_RDI_Paiement, @iOperOfCancelID)	
         END            

			-- Erreur lors de la mise à jour de la table temporaire
			IF @@ERROR <> 0
				SET @iResult = -102
		END

		IF @iResult > 0
		BEGIN

			INSERT INTO Un_OperCancelation (
					OperSourceID,
					OperID)
				SELECT
					@iOperID,
					@iOperOfCancelID

			-- Erreur lors de l'insertion du lien entre l'opération annulér et l'opération qui l'annule
			IF @@ERROR <> 0
				SET @iResult = -103
		END

		IF @iResult > 0
		BEGIN
			DECLARE crCotisation CURSOR
			FOR
				SELECT
					CotisationID
				FROM Un_Cotisation
				WHERE OperID = @iOperID

			OPEN crCotisation

			FETCH NEXT FROM crCotisation
			INTO
				@iOldCotisationID

			WHILE	@@FETCH_STATUS = 0
			AND	 @iResult > 0
			BEGIN
				SET @iCotisationID = 0

				INSERT INTO Un_Cotisation (
						OperID,
						UnitID,
						EffectDate,
						Cotisation,
						Fee,
						BenefInsur,
						SubscInsur,
						TaxOnInsur)
					SELECT
						@iOperOfCancelID,
						Ct.UnitID,
						Ct.EffectDate,
						Ct.Cotisation *-1,
						Ct.Fee *-1,
						Ct.BenefInsur *-1,
						Ct.SubscInsur *-1,
						Ct.TaxOnInsur *-1
					FROM Un_Cotisation Ct
					JOIN Un_Oper O ON O.OperID = @iOperOfCancelID
					WHERE Ct.CotisationID = @iOldCotisationID

				SET @iCotisationID = SCOPE_IDENTITY()
				
				-- Erreur lors de l'insertion de cotisation
				IF @@ERROR <> 0
					SET @iResult = -104
				
				FETCH NEXT FROM crCotisation
				INTO
					@iOldCotisationID
			END

			CLOSE crCotisation
			DEALLOCATE crCotisation
		END

		IF		@iResult > 0
		BEGIN
			INSERT INTO Un_OUT (
					OperID,
					ExternalPlanID,
					tiBnfRelationWithOtherConvBnf,
					vcOtherConventionNo,
					tiREEEType,
					bEligibleForCESG,
					bEligibleForCLB,
					bOtherContratBnfAreBrothers,
					fYearBnfCot,
					fBnfCot,
					fNoCESGCotBefore98,
					fNoCESGCot98AndAfter,
					fCESGCot,
					fCESG,
					fCLB,
					fAIP,
					fMarketValue)
				SELECT 
					@iOperOfCancelID,
					ExternalPlanID,
					tiBnfRelationWithOtherConvBnf,
					Upper(vcOtherConventionNo),
					tiREEEType,
					bEligibleForCESG,
					bEligibleForCLB,
					bOtherContratBnfAreBrothers,
					-fYearBnfCot,
					-fBnfCot,
					-fNoCESGCotBefore98,
					-fNoCESGCot98AndAfter,
					-fCESGCot,
					-fCESG,
					-fCLB,
					-fAIP,
					-fMarketValue 
				FROM Un_OUT
				WHERE OperID = @iOperID		

			IF @@ERROR <> 0
				SET @iResult = -105
		END

		IF		@iResult > 0
		BEGIN
			INSERT INTO Un_TIN (
					OperID,
					ExternalPlanID,
					tiBnfRelationWithOtherConvBnf,
					vcOtherConventionNo,
					dtOtherConvention,
					tiOtherConvBnfRelation,
					bAIP,
					bACESGPaid,
					bBECInclud,
					bPGInclud,
					fYearBnfCot,
					fBnfCot,
					fNoCESGCotBefore98,
					fNoCESGCot98AndAfter,
					fCESGCot,
					fCESG,
					fCLB,
					fAIP,
					fMarketValue,
					bPendingApplication)
				SELECT 
					@iOperOfCancelID,
					ExternalPlanID,
					tiBnfRelationWithOtherConvBnf,
					Upper(vcOtherConventionNo),
					dtOtherConvention,
					tiOtherConvBnfRelation,
					bAIP,
					bACESGPaid,
					bBECInclud,
					bPGInclud,
					-fYearBnfCot,
					-fBnfCot,
					-fNoCESGCotBefore98,
					-fNoCESGCot98AndAfter,
					-fCESGCot,
					-fCESG,
					-fCLB,
					-fAIP,
					-fMarketValue,
					bPendingApplication
				FROM Un_TIN
				WHERE OperID = @iOperID			

			IF @@ERROR <> 0
				SET @iResult = -106
		END

		IF @iResult > 0
		BEGIN
			INSERT INTO Un_ConventionOper (
					OperID,
					ConventionID,
					ConventionOperTypeID,
					ConventionOperAmount)
				SELECT
					@iOperOfCancelID,
					ConventionID,
					ConventionOperTypeID,
					ConventionOperAmount *-1
				FROM Un_ConventionOper
				WHERE OperID = @iOperID

			-- Erreur lors de l'insertion d'opération sur convention
			IF @@ERROR <> 0
				SET @iResult = -106
		END

		IF @iResult > 0
		BEGIN
			INSERT INTO Un_PlanOper (
					OperID,
					PlanID,
					PlanOperTypeID,
					PlanOperAmount)
				SELECT
					@iOperOfCancelID,
					PlanID,
					PlanOperTypeID,
					PlanOperAmount *-1
				FROM Un_PlanOper
				WHERE OperID = @iOperID

			-- Erreur lors de l'insertion d'opération sur plan
			IF @@ERROR <> 0
				SET @iResult = -107
		END

		IF @iResult > 0
		BEGIN
			INSERT INTO Un_OtherAccountOper (
					OperID,
					OtherAccountOperAmount)
				SELECT
					@iOperOfCancelID,
					OtherAccountOperAmount *-1
				FROM Un_OtherAccountOper
				WHERE OperID = @iOperID

			-- Erreur lors de l'insertion d'opération dans les autres comptes
			IF @@ERROR <> 0
				SET @iResult = -108
		END

		IF @iResult > 0
		BEGIN
			INSERT INTO Un_ScholarshipPmt (
					OperID,
					ScholarshipID,
					CollegeID,
					ProgramID,
					StudyStart,
					ProgramLength,
					ProgramYear,
					RegistrationProof,
					SchoolReport,
					EligibilityQty,
					CaseOfJanuary,
					EligibilityConditionID)
				SELECT
					@iOperOfCancelID,
					ScholarshipID,
					CollegeID,
					ProgramID,
					StudyStart,
					ProgramLength,
					ProgramYear,
					RegistrationProof,
					SchoolReport,
					EligibilityQty,
					CaseOfJanuary,
               EligibilityConditionID
				FROM Un_ScholarshipPmt
				WHERE OperID = @iOperID

			-- Erreur lors de l'insertion de lien entre une bourse et l'opération d'annulation
			IF @@ERROR <> 0
				SET @iResult = -109
		END

		IF @iResult > 0
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
				JOIN Un_ScholarshipStep SS ON SS.ScholarshipID = S.ScholarshipID AND SS.iScholarshipStep = 5 AND SS.bOldPAE = 0
				JOIN Un_Oper O ON O.OperID = SP.OperID
				WHERE SP.OperID = @iOperID
					AND O.OperTypeID = 'PAE'

			-- Erreur lors de l'insertion d'une étape de PAE.
			IF @@ERROR <> 0
				SET @iResult = -110
		END

		IF @iResult > 0
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
				WHERE O.OperID = @iOperID
					AND O.OperTypeID = 'RIN'

			-- Erreur lors de l'insertion d'une étape de RIN.
			IF @@ERROR <> 0
				SET @iResult = -111
		END

		IF @iResult > 0
		BEGIN
			-- Enregistrement pour inverser l'historique des frais disponibles utilisés 
			INSERT INTO Un_AvailableFeeUse (
					UnitReductionID,
					OperID,
					fUnitQtyUse)
				SELECT DISTINCT
					A.UnitReductionID,
					@iOperOfCancelID,
					A.fUnitQtyUse * -1
				FROM Un_AvailableFeeUse A
				JOIN Un_Oper O ON O.OperID = A.OperID
				WHERE O.OperID = @iOperID
					AND O.OperTypeID = 'TFR'

			IF @@ERROR <> 0
				SET @iResult = -112
		END

		IF @iResult > 0
		BEGIN
			UPDATE Un_Scholarship
			SET ScholarshipStatusID = 'ANL' --'ADM'
			FROM Un_Scholarship
			JOIN Un_ScholarshipPmt SP ON SP.ScholarshipID = Un_Scholarship.ScholarshipID
			JOIN Un_Oper O ON O.OperID = SP.OperID
			WHERE 	SP.OperID = @iOperID
				AND	O.OperTypeID = 'PAE'

			-- Erreur lors de mise à jour du statut de la bourse
			IF @@ERROR <> 0
				SET @iResult = -113
		END

		-- Supprime les enregistrements 400 non-expédiés de l'opération annulée
		IF @iResult > 0
		BEGIN
			DELETE Un_CESP400
			FROM Un_CESP400
			JOIN Un_Cotisation Ct ON Un_CESP400.CotisationID = Ct.CotisationID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			WHERE Ct.OperID = @iOperID
				AND Un_CESP400.iCESPSendFileID IS NULL
				-- Il n'y aura pas de 900 lié car la 400 n'a pas été expédié

			-- Erreur lors de la suppression des 400 non expédié.
			IF @@ERROR <> 0
				SET @iResult = -114
		END

		-- Supprime les enregistrements 400 de PAE non-expédiés de l'opération annulée
		IF @iResult > 0
		BEGIN
			DELETE Un_CESP400
			FROM Un_CESP400			
			JOIN Un_Oper O ON O.OperID = Un_CESP400.OperID
			WHERE O.OperID = @iOperID
				AND Un_CESP400.iCESPSendFileID IS NULL
				AND O.OperTypeID = 'PAE'
				-- Il n'y aura pas de 900 lié car la 400 n'a pas été expédié

			-- Erreur lors de la suppression des 400 non expédié.
			IF @@ERROR <> 0
				SET @iResult = -115
		END

		-- Renverse les enregistrements 400 déjà expédiés 
		IF @iResult > 0
			EXECUTE @iResult = IU_UN_ReverseCESP400 @ConnectID, 0, @iOperID

		-- Redemande la SCEE pour le CPA, PRD ou CHQ qui était l'objet du NSF annulé	
		IF	@iResult > 0
		AND EXISTS (
				SELECT O.OperID
				FROM Un_Oper O
				JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
				WHERE	O.OperID = @iOperID
					AND OT.OperTypeID = 'NSF'
				)
		BEGIN
			SET @iSourceOperID = 0
			SELECT
				@iSourceOperID = BRL.BankReturnSourceCodeID
			FROM Mo_BankReturnLink BRL
			WHERE BRL.BankReturnCodeID = @iOperID

			-- Insère les enregistrements 400 de type 11 sur l'opération
			IF @iSourceOperID > 0
				EXECUTE @iResult = IU_UN_CESP400ForOper @ConnectID, @iSourceOperID, 11, 0
		END

		IF	@iResult > 0
		AND EXISTS (
			SELECT *
			FROM Un_Oper
			WHERE OperID = @iOperID
				AND OperTypeID IN ('PAE', 'TIN', 'OUT')
			)
		BEGIN			
			--Création du CESP d'annulation
			INSERT INTO Un_CESP (
					ConventionID,
					OperID,
					CotisationID,					
					fCESG,
					fACESG,
					fCLB,
					fCLBFee,
					fPG,
					vcPGProv,
					fCotisationGranted,
					OperSourceID)
				SELECT
					CE.ConventionID,				
					@iOperOfCancelID,
					@iCotisationID,
					-CE.fCESG,
					-CE.fACESG,
					-CE.fCLB,
					-CE.fCLBFee,
					-CE.fPG,
					CE.vcPGProv,
					-CE.fCotisationGranted,
					@iOperOfCancelID
				FROM Un_CESP CE				
				WHERE CE.OperID = @iOperID					

			-- Erreurs lors de l'annulation de la SCÉÉ de l'opération
			IF @@ERROR <> 0
				SET @iResult = -116
		END

		FETCH NEXT FROM crOper
		INTO 
			@iOperID
	END

	CLOSE crOper
	DEALLOCATE crOper

	IF @iResult > 0
	BEGIN
		INSERT INTO Un_TIO(iOUTOperID, iTINOperID, iTFROperID)
		SELECT 
			OTO.OperOfCancelID,
			OTI.OperOfCancelID,
			OTF.OperOfCancelID
		FROM Un_TIO O
		JOIN @OperTable OTO ON OTO.OperID = O.iOUTOperID
		JOIN @OperTable OTI ON OTI.OperID = O.iTINOperID
		LEFT JOIN @OperTable OTF ON OTF.OperID = O.iTFROperID		

		-- Erreur lors de la mise à jour de groupe d'unités
		IF @@ERROR <> 0
			SET @iResult = -117
	END

	IF @iResult > 0
	BEGIN
		UPDATE dbo.Un_Unit 
		SET IntReimbDate = NULL
		FROM dbo.Un_Unit 
		JOIN Un_IntReimb IR ON IR.UnitID = Un_Unit.UnitID
		JOIN Un_IntReimbOper IRO ON IRO.IntReimbID = IR.IntReimbID
		JOIN @OperTable O ON O.OperID = IRO.OperID

		-- Erreur lors de la mise à jour de groupe d'unités
		IF @@ERROR <> 0
			SET @iResult = -118
	END

	SET @iIntReimbID = 0

	IF @iResult > 0
	BEGIN
		SELECT
			@iIntReimbID = IRO.IntReimbID
		FROM Un_IntReimbOper IRO
		JOIN @OperTable O ON O.OperID = IRO.OperID

		-- Erreur lors de la recherche du ID de remboursement intégral
		IF @@ERROR <> 0
			SET @iResult = -119
	END

	IF 	@iResult > 0
	AND	@iIntReimbID > 0
	BEGIN
		INSERT INTO Un_IntReimbOper (
				IntReimbID,
				OperID)
			SELECT
				@iIntReimbID,
				OperOfCancelID
			FROM @OperTable

		-- Erreur lors d'insertion de lien entre l'historique du remboursement intégral et les opérations d'annulation
		IF @@ERROR <> 0
			SET @iResult = -120
	END

	IF @iResult > 0
	BEGIN
		UPDATE Mo_BankReturnLink
		SET BankReturnSourceCodeID = O.OperOfCancelID
		FROM Mo_BankReturnLink
		JOIN @OperTable O ON O.OperID = Mo_BankReturnLink.BankReturnCodeID

		-- Erreur lors de la redirection du lien NSF
		IF @@ERROR <> 0
			SET @iResult = -121
	END

	IF		@iResult > 0
	BEGIN
		INSERT INTO Mo_BankReturnLink (
				BankReturnCodeID,
				BankReturnFileID,
				BankReturnSourceCodeID,
				BankReturnTypeID)
			SELECT 
				BRL.BankReturnSourceCodeID,
				BRL.BankReturnFileID,
				BRL.BankReturnCodeID,
				BRL.BankReturnTypeID
			FROM Mo_BankReturnLink BRL
			JOIN @OperTable O ON O.OperID = BRL.BankReturnCodeID

		-- Erreur lors de la redirection du lien NSF
		IF @@ERROR <> 0
			SET @iResult = -122
	END

	SET @iOldUnitReductionID = 0

	IF @iResult > 0
	BEGIN
		SELECT 
			@iOldUnitReductionID = UR.UnitReductionID
		FROM @OperTable O
		JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
		JOIN Un_UnitReductionCotisation UR ON UR.CotisationID = Ct.CotisationID
		UPDATE Mo_BankReturnLink
		SET BankReturnSourceCodeID = O.OperOfCancelID
		FROM Mo_BankReturnLink
		JOIN @OperTable O ON O.OperID = Mo_BankReturnLink.BankReturnCodeID

		-- Erreur lors de la recherche d'une historique de réduction d'unités
		IF @@ERROR <> 0
			SET @iResult = -123
	END

	SET @iUnitReductionID = 0

	IF 	@iResult > 0
	AND	@iOldUnitReductionID > 0
	BEGIN
		INSERT INTO Un_UnitReduction (
				UnitID,
				ReductionConnectID,
				ReductionDate,
				UnitQty,
				FeeSumByUnit,
				SubscInsurSumByUnit,
				UnitReductionReasonID,
				NoChequeReasonID)
			SELECT
				UnitID,
				@ConnectID,
				dbo.FN_CRQ_DateNoTime(GETDATE()),
				UnitQty*-1,
				FeeSumByUnit,
				SubscInsurSumByUnit,
				UnitReductionReasonID,
				NoChequeReasonID
			FROM Un_UnitReduction
			WHERE UnitReductionID = @iOldUnitReductionID

		-- Erreur l'insertion d'un historique de réduction d'unités
		IF @@ERROR <> 0
			SET @iResult = -124
		ELSE
			SET @iUnitReductionID = SCOPE_IDENTITY()
	END

	IF 	@iResult > 0
	AND	@iUnitReductionID > 0
	BEGIN
		INSERT INTO Un_UnitReductionCotisation (
				UnitReductionID,
				CotisationID)
			SELECT
				@iUnitReductionID,
				Ct.CotisationID
			FROM Un_Cotisation Ct
			JOIN @OperTable O ON Ct.OperID = O.OperOfCancelID

		-- Erreur l'insertion de lien entre historique de réduction d'unités et les cotisations
		IF @@ERROR <> 0
			SET @iResult = -125
	END

	IF		@iResult > 0
	AND	@iOldUnitReductionID > 0
	BEGIN
		UPDATE dbo.Un_Unit 
		SET 
			TerminatedDate = NULL,
			UnitQty = Un_Unit.UnitQty + UR.UnitQty
		FROM dbo.Un_Unit 
		JOIN Un_UnitReduction UR ON UR.UnitID = Un_Unit.UnitID
		WHERE UR.UnitReductionID = @iOldUnitReductionID

		-- Erreur lors de la mise à jour de groupe d'unités
		IF @@ERROR <> 0
			SET @iResult = -126
	END

	IF 	@iResult > 0
	AND	@iOldUnitReductionID > 0
	BEGIN
		SET @iRepExceptionIDBef = IDENT_CURRENT('Un_RepException')+1

		INSERT INTO Un_RepException (
				RepID,
				UnitID,
				RepLevelID,
				RepExceptionTypeID,
				RepExceptionDate,
				RepExceptionAmount)
			SELECT
				RE.RepID,
				RE.UnitID,
				RE.RepLevelID,
				RE.RepExceptionTypeID,
				dbo.FN_CRQ_DateNoTime(GETDATE()),
				RepExceptionAmount = SUM(RE.RepExceptionAmount)*-1
			FROM Un_RepException RE
			JOIN Un_UnitReductionRepException URRE ON URRE.RepExceptionID = RE.RepExceptionID
			WHERE URRE.UnitReductionID = @iOldUnitReductionID
			GROUP BY
				RE.RepID,
				RE.UnitID,
				RE.RepLevelID,
				RE.RepExceptionTypeID
			HAVING SUM(RE.RepExceptionAmount) <> 0

		-- Erreur lors de la création d'exceptions de commissions
		IF @@ERROR <> 0
			SET @iResult = -127
		ELSE
			SET @iRepExceptionID = SCOPE_IDENTITY()

		IF 	@iResult > 0
		BEGIN
			INSERT INTO Un_UnitReductionRepException (
					UnitReductionID,
					RepExceptionID)
				SELECT
					@iUnitReductionID,
					RepExceptionID
				FROM Un_RepException
				WHERE RepExceptionID BETWEEN @iRepExceptionIDBef AND @iRepExceptionID

			-- Erreur lors de la création de lien entre des exceptions de commissions et une historique de reduction d'unités
			IF @@ERROR <> 0
				SET @iResult = -128
		END 
	END

	-- Marque supprimé les opérations du modules des chèques attachés aux opérations supprimées
	IF @iResult > 0
	AND EXISTS (
		SELECT
			L.iOperationID
		FROM @OperTable OD 
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

		DECLARE crCHQ_OperationCancel CURSOR
		FOR
			SELECT
				O.iOperationID,
				O.iConnectID,
				O.dtOperation,
				O.vcDescription,
				O.vcRefType,
				O.vcAccount
			FROM @OperTable OD 
			JOIN Un_OperLinkToCHQOperation L ON OD.OperID = L.OperID
			JOIN CHQ_Operation O ON O.iOperationID = L.iOperationID

		OPEN crCHQ_OperationCancel

		FETCH NEXT FROM crCHQ_OperationCancel
		INTO
			@iOperationID,
			@iConnectID,
			@dtOperation,
			@vcDescription,
			@vcRefType,
			@vcAccount

		WHILE @@FETCH_STATUS = 0 AND @iResult > 0
		BEGIN
			-- Modifie (marque supprimé) les opérations dans la gestion des chèques (CHQ_Operation)
			EXECUTE @iOperationID = IU_CHQ_Operation 0, @iOperationID, 1, @iConnectID, @dtOperation, @vcDescription, @vcRefType, @vcAccount

			IF @iOperationID <= 0
				SET @iResult = -129

			FETCH NEXT FROM crCHQ_OperationCancel
			INTO
				@iOperationID,
				@iConnectID,
				@dtOperation,
				@vcDescription,
				@vcRefType,
				@vcAccount
		END

		CLOSE crCHQ_OperationCancel
		DEALLOCATE crCHQ_OperationCancel
	END

	--Mise à jour de la date TIN du groupe d'unités et de la convention
	IF @iResult > 0 	
	BEGIN
		--Va chercher la date minimale des TIN restants après l'annulation
		SELECT  
				@UnitID = U.UnitID,
				@ConventionID = U.ConventionID,
				@dtOtherConvention = MIN(T.dtOtherConvention)
		FROM @OperTable OD
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
			SET @iResult = -130

		SELECT @dtMinUnitInforceDateTIN = MIN(U.dtInforceDateTIN)					
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		WHERE C.ConventionID = @ConventionID
				AND U.dtInforceDateTIN IS NOT NULL
		GROUP BY C.ConventionID
			
		UPDATE dbo.Un_Convention 
		SET dtInforceDateTIN = @dtMinUnitInforceDateTIN
		WHERE ConventionID = @ConventionID

		SELECT @UnitID, @dtOtherConvention, @dtMinUnitInforceDateTIN, @ConventionID

		IF @@ERROR <> 0
			SET @iResult = -131
			
	END
	
	-- Mise à jour des états de conventions et unités
	IF @iResult > 0 AND ISNULL(@vcUnitIDs, '') <> '' 
			EXECUTE TT_UN_ConventionAndUnitStateForUnit @vcUnitIDs 	
			
	IF @iResult > 0
	BEGIN
		------------------
		COMMIT TRANSACTION
		------------------
		-- S'il s'agit d'une opération RDI - Mettre à jour le statut du dépôt
		IF @iID_RDI_Depot > 0
         EXECUTE [dbo].[psOPER_RDI_ModifierStatutDepot] @iID_RDI_Depot
   END
	ELSE
	BEGIN
		--------------------
		ROLLBACK TRANSACTION
		--------------------
   END

	RETURN @iResult
END