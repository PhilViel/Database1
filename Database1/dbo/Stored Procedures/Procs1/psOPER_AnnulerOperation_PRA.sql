/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psOPER_AnnulerOperation_PRA
Nom du service		:		Annuler une opération PRA.
But					:		Annuler une opération PRA dans les tables d'uniAccés.
Facette				:		OPER
Reférence			:		UniAccés-Noyau-OPER

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						@iID_Connexion			Identifiant de la connexion
						@iID_Oper_PRA			Identifiant de l'opération PRA à annuler
Exemple d'appel:
						@iID_Connexion = 1, --ID de connection de l'usager
						@iID_Oper_PRA = 17184475, --ID de l'opération PRA

Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													@CodeRetour						C'est un code de retour qui indique si le traitement :
																						 s'est terminée avec succès et si les frais sont couverts
																						@CodeRetour < 0  : Echec
																						@CodeRetour = 0  : traitement s'est bien deroulé
			
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2015-10-29					Steve Picard							Création de procédure stockée		[psOPER_AnnulerOperationRIO]
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_AnnulerOperation_PRA]
( 
	@iID_Oper_PRA INTEGER
) 
AS
BEGIN

	DECLARE	@dtToday DATE = GETDATE()
		,	@dtNow DATETIME = GETDATE()
		,	@CodeRetour INTEGER = 0
		,	@OperID INTEGER
		,	@OperChildID INTEGER
		,	@ConventionID INTEGER
		,	@iID_Connexion INTEGER = 2

	--	Vérifier que c'est bien une opération de type « PRA »
	IF NOT EXISTS(SELECT TOP 1 * FROM dbo.Un_Oper WHERE OperID = @iID_Oper_PRA and OperTypeID = 'PRA')
	BEGIN
		SET @CodeRetour = -2
		GOTO END_TRANSACTION
	END

	--	Vérifier si l'opération n'est pas déjà annulé ou que c'est une annulation d'une autre opération
	IF EXISTS(SELECT TOP 1 * FROM dbo.Un_OperCancelation WHERE OperSourceID = @iID_Oper_PRA OR OperID = @iID_Oper_PRA)
	BEGIN
		SET @CodeRetour = -3
		GOTO END_TRANSACTION
	END

	--Desactiver le service (Trigger)TUn_Cotisation_State
	IF object_id('tempdb..#DisableTrigger') is null
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))

	DECLARE @TB_ChildOper TABLE (
		ID_Oper		INT NOT NULL,
		ID_Type		VARCHAR(5) NOT NULL,
		ID_Raison	INT NULL,
		ID_Cancel	INT NULL
	)

	-----------------
	BEGIN TRANSACTION
	-----------------

	---------------------------------------------------
	-- Annulation des opérations enfants (si présentes)
	---------------------------------------------------
	INSERT INTO @TB_ChildOper (ID_Oper, ID_Type, ID_Raison)
		SELECT	A.iID_Operation_Enfant, O.OperTypeID, A.iID_Raison_Association
		FROM	dbo.tblOPER_AssociationOperations A
				JOIN dbo.tblOPER_RaisonsAssociation R ON R.iID_Raison_Association = A.iID_Raison_Association
				JOIN dbo.Un_Oper O ON O.OperID = A.iID_Operation_Enfant
		WHERE	A.iID_Operation_Parent = @iID_Oper_PRA
			AND	R.bCascader_Annulation_Enfants <> 0

     IF @@Error <> 0
     BEGIN
         SET @CodeRetour = -4
	    GOTO ROLLBACK_SECTION
     END
	
	--------------------------------------------
	-- Créer les opérations d’annulation « PRA »
	--------------------------------------------
	INSERT INTO dbo.Un_Oper (OperTypeID, OperDate, ConnectID, dtSequence_Operation)
		VALUES ('PRA', @dtToday, 2, @dtNow)

     IF @@Error <> 0
     BEGIN
         SET @CodeRetour = -5
	    GOTO ROLLBACK_SECTION
     END
	ELSE
		SET @OperID = SCOPE_IDENTITY()

	WHILE EXISTS(Select Top 1 * From @TB_ChildOper Where ID_Cancel Is Null)
	BEGIN
		SELECT	@OperChildID = Min(ID_Oper)
		FROM	@TB_ChildOper
		WHERE	ID_Cancel IS NULL

		INSERT INTO dbo.Un_Oper (OperTypeID, OperDate, ConnectID, dtSequence_Operation)
			SELECT	ID_Type, @dtToday, 2, @dtNow
			FROM	@TB_ChildOper
			WHERE	ID_Oper = @OperChildID

		IF @@Error <> 0
          BEGIN
               SET @CodeRetour = -6
			GOTO ROLLBACK_SECTION
          END
		ELSE
			UPDATE	@TB_ChildOper
			SET		ID_Cancel = SCOPE_IDENTITY()
			WHERE	ID_Oper = @OperChildID
	END

	--------------------------------------------
	-- Associer les nouvelles opérations enfants
	--------------------------------------------
	INSERT INTO	tblOPER_AssociationOperations (iID_Operation_Parent, iID_Operation_Enfant, iID_Raison_Association)
		SELECT	@OperID, ID_Cancel, ID_Raison
		FROM	@TB_ChildOper

	----------------------------------------------------------------------
	-- Créer le lien entre l’opération d’annulation et l’opération annulée
	----------------------------------------------------------------------
	INSERT INTO dbo.Un_OperCancelation (OperSourceID, OperID)
		VALUES (@iID_Oper_PRA, @OperID)

     IF @@Error <> 0
     BEGIN
         SET @CodeRetour = -7
	    GOTO ROLLBACK_SECTION
     END

	INSERT INTO dbo.Un_OperCancelation (OperSourceID, OperID)
		SELECT	ID_Oper, ID_Cancel
		FROM	@TB_ChildOper

     IF @@Error <> 0
     BEGIN
         SET @CodeRetour = -8
	    GOTO ROLLBACK_SECTION
     END

	----------------------------------------------------------------------------------------------
	-- Renverser chaque transaction sur la convention (Un_ConventionOper) de l’opération à annuler
	----------------------------------------------------------------------------------------------
	;WITH CTE_ConventionOper as (
		SELECT	ConventionOperID, @OperID as OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount
		FROM	dbo.Un_ConventionOper
		WHERE	OperID = @iID_Oper_PRA
		UNION
		SELECT	ConventionOperID, O.ID_Cancel, ConventionID, ConventionOperTypeID, ConventionOperAmount
		FROM	dbo.Un_ConventionOper C
				JOIN @TB_ChildOper O ON O.ID_Oper = C.OperID
	)
	INSERT INTO dbo.Un_ConventionOper (OperID, ConventionID, ConventionOperTypeID, ConventionOperAmount)
		SELECT	OperID, ConventionID, ConventionOperTypeID, -1 * ConventionOperAmount
		FROM	CTE_ConventionOper
		ORDER BY ConventionOperID

     IF @@Error <> 0
     BEGIN
         SET @CodeRetour = -9
	    GOTO ROLLBACK_SECTION
     END

	-----------------------------------------------------------------------------------------------
	-- Renverser chaque transaction sur les subventions fédérale (Un_CESP) de l’opération à annuler
	-----------------------------------------------------------------------------------------------
	INSERT INTO Un_CESP	(ConventionID, OperID, CotisationID, OperSourceID, fCESG, fACESG, fCLB, fCLBFee, fPG, vcPGProv, fCotisationGranted)
		SELECT	ConventionID, @OperID, CotisationID, @iID_Oper_PRA, -fCESG, -fACESG, -fCLB, -fCLBFee, -fPG, vcPGProv, fCotisationGranted
		FROM	dbo.Un_CESP
		WHERE	OperID = @iID_Oper_PRA

     IF @@Error <> 0
     BEGIN
         SET @CodeRetour = -10
	    GOTO ROLLBACK_SECTION
     END

	-------------------------------------------------------------------------
	-- Supprimer les transactions 400 à la subvention canadienne (Un_CESP400)
	-------------------------------------------------------------------------
	DELETE FROM	dbo.Un_CESP400	
	WHERE	iCESPSendFileID IS NULL
		AND OperID = @iID_Oper_PRA

     IF @@Error <> 0
     BEGIN
         SET @CodeRetour = -11
	    GOTO ROLLBACK_SECTION
     END

	-----------------------------------------------------------------------------------------------
	-- Créer de nouvelles transactions 400 de transfert pour chaque transfert associé à l’opération
	-----------------------------------------------------------------------------------------------

	-- Test s'il existent des transactions 400 a la subvention canadienne (Un_CESP400)
	IF EXISTS(SELECT TOP 1 * FROM Un_CESP400 WHERE iCESPSendFileID IS NOT NULL AND OperID = @iID_Oper_PRA)
	BEGIN			
		-- Renverse les enregistrements 400 déjà expédiés 
		EXECUTE @CodeRetour = IU_UN_ReverseCESP400 @iID_Connexion, 0, @iID_Oper_PRA

		IF @@Error <> 0 OR @CodeRetour = 0
         BEGIN
             PRINT '@CodeRetour :' + Str(@CodeRetour)
             SET @CodeRetour = -12
	        GOTO ROLLBACK_SECTION
         END
	END
		
	--------------------------------------
	-- Réviser le statut de la connvention
	--------------------------------------

	--Utiliser le service TT_UN_ConventionAndUnitStateForUnit
	EXEC  dbo.TT_UN_ConventionStateForConvention @ConventionID

	IF @@Error <> 0
		GOTO ROLLBACK_SECTION

	COMMIT TRANSACTION

	SET @CodeRetour = @OperID

-- Libellé de fin de procédure.
END_TRANSACTION:	

	RETURN @CodeRetour 

-- Libellé d'erreur
ROLLBACK_SECTION:

	IF @CodeRetour = 0
		SET @CodeRetour = -1
	
	-- On effectue un ROLLBACK et on quitte la procédure.
	ROLLBACK TRANSACTION
	GOTO END_TRANSACTION	
END
