
/****************************************************************************************************
Code de service		:		SP_IU_UN_Breaking
Nom du service		:		SP_IU_UN_Breaking
But					:		Ajout/modification d'arrêt de paiement sur convention
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres										Description
		                ----------										----------------
						@ConnectID										-- ID Unique de connexion de l'usager
						@BreakingID										-- ID Unique de l'arrêt de paiement 0 = nouvelle
						@BreakingTypeID									-- Type d'arrêt de paiement 'STP' (arrêt) ou 'SUS' (suspension)
						@ConventionID									-- ID Unique de la convention
						@BreakingStartDate								-- Dans d'entré en vigueur
						@BreakingEndDate								-- Dans de fin 
						@BreakingReason									-- Raison de l'arrêt
						@iID_Utilisateur								-- Utilisateur à l'origine de la création
						@dtDate_Operation								-- Date d'enregistrement de l'opération, devrait être passée NULL

Exemple d'appel:
					
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													@BreakingID						

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2004-06-09					Bruno Lapointe							Migration
		2009-09-24					Jean-François Gauthier					Remplacement du @@Identity par Scope_Identity()
		2011-04-11					Corentin Menthonnex						Modification du fonctionnement pour garder l'historique
																			des arrêts de paiements
		2012-02-10					Eric Michaud							Modification pour suivie des modifications GLPI6983	
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[SP_IU_UN_Breaking] (
		@ConnectID						INTEGER,		-- ID Unique de connexion de l'usager
		@BreakingID						INTEGER,		-- ID Unique de l'arrêt de paiement 0 = nouvelle
		@BreakingTypeID					VARCHAR(3),		-- Type d'arrêt de paiement 'STP' (arrêt) ou 'SUS' (suspension)
		@ConventionID					INTEGER,		-- ID Unique de la convention
		@BreakingStartDate				DATETIME,		-- Date d'entré en vigueur
		@BreakingEndDate				DATETIME,		-- Date de fin 
		@BreakingReason					VARCHAR(75),	-- Raison de l'arrêt
		@iID_Utilisateur				INT,			-- Utilisateur à l'origine de 
		@dtDate_Operation				DATETIME		-- Date d'enregistrement de l'opération, devrait être passée NULL
	)
AS
BEGIN
	-- 0 = Pas sauvegarder (Erreur)

	-- 2011-12 : + CM
	-- Utiliser l'utilisateur du système s'il est absent en paramètre
    IF @iID_Utilisateur IS NULL
        OR @iID_Utilisateur = 0
        OR NOT EXISTS ( SELECT  *
                        FROM    Mo_User utilisateur
                        WHERE   utilisateur.UserID = @iID_Utilisateur ) 
        SELECT TOP 1 @iID_Utilisateur = USR.UserID
        FROM Mo_Connect CON 
			INNER JOIN Mo_User USR ON USR.UserID = CON.UserID
        WHERE CON.ConnectID = @ConnectID;
            
	-- 2011-12 : + CM
    -- initialisation des dates si non fournies
    SET @dtDate_Operation = ISNULL(@dtDate_Operation, GETDATE());
        
	IF ISNULL(@BreakingStartDate,0) <= 0
		SET @BreakingStartDate = GetDate()

	IF @BreakingEndDate <= 0
		SET @BreakingEndDate = NULL

	-- Si on créer un nouvel arrêt de paiement
	IF @BreakingID = 0
	BEGIN
		-- 2011-12 : + CM
		-- On révoque les anciens arrêts de paiement en mettant une date de fin
		UPDATE Un_Breaking		
			SET BreakingEndDate					= @BreakingStartDate,
				iID_Utilisateur_Modification	= @iID_Utilisateur,
				dtDate_Modification_Operation	= @dtDate_Operation
			WHERE	ConventionID = @ConventionID 
			AND		BreakingEndDate IS NULL;
	
		-- Ajout
		INSERT INTO Un_Breaking (
			BreakingTypeID,
			ConventionID,
			BreakingStartDate,
			BreakingEndDate,
			BreakingReason,
			iID_Utilisateur_Creation,			-- 2011-12 : + CM
			dtDate_Creation_Operation,			-- 2011-12 : + CM
			iID_Utilisateur_Modification,		-- 2011-12 : + CM
			dtDate_Modification_Operation)		-- 2011-12 : + CM
		VALUES (
			@BreakingTypeID,
			@ConventionID,
			@BreakingStartDate,
			@BreakingEndDate,
			@BreakingReason,
			@iID_Utilisateur,			-- 2011-12 : + CM
			@dtDate_Operation,			-- 2011-12 : + CM
			NULL,								-- 2011-12 : + CM
			NULL								-- 2011-12 : + CM
			)
			
		IF @@ERROR = 0
			SELECT @BreakingID = SCOPE_IDENTITY()
	END
	ELSE
	-- Si on modifie un arrêt existant
	BEGIN
		-- Modification
		/*UPDATE Un_Breaking 
		SET
			BreakingTypeID		= @BreakingTypeID,
			ConventionID		= @ConventionID,
			BreakingStartDate	= @BreakingStartDate,
			BreakingEndDate		= @BreakingEndDate,
			BreakingReason		= @BreakingReason,
		WHERE BreakingID = @BreakingID*/
		
		-- On révoque celui que l'on vient de modifier
		-- 2011-12 : + CM
		UPDATE Un_Breaking		
			SET BreakingEndDate					= @BreakingEndDate, 
				BreakingTypeID					= @BreakingTypeID,
				BreakingReason					= @BreakingReason,
				iID_Utilisateur_Modification	= @iID_Utilisateur,	
				dtDate_Modification_Operation	= @dtDate_Operation	
			WHERE	ConventionID	= @ConventionID
			AND		BreakingID		= @BreakingID;
		
		-- On vérifie si on est pas en train d'ajouter une occurence alors que 
		-- la modification aurait été de mettre une date de fin ce qui aurait déjà
		-- été fait par l'update juste avant
		-- 2011-12 : + CM
/*		IF NOT EXISTS (	SELECT BreakingTypeID  
						FROM Un_Breaking
						WHERE	BreakingTypeID		= @BreakingTypeID
						AND		ConventionID		= @ConventionID
						AND		BreakingStartDate	= @BreakingStartDate
						AND		BreakingEndDate		IS NOT NULL
						AND		BreakingReason		= @BreakingReason)
		BEGIN
			INSERT INTO Un_Breaking (
				BreakingTypeID,
				ConventionID,
				BreakingStartDate,
				BreakingEndDate,
				BreakingReason,
				iID_Utilisateur_Creation,			-- 2011-12 : + CM
				dtDate_Creation_Operation,			-- 2011-12 : + CM
				iID_Utilisateur_Modification,		-- 2011-12 : + CM
				dtDate_Modification_Operation)		-- 2011-12 : + CM	
			VALUES (
				@BreakingTypeID,
				@ConventionID,
				@BreakingStartDate,
				@BreakingEndDate,
				@BreakingReason,
				@iID_Utilisateur,					-- 2011-12 : + CM
				@dtDate_Operation,					-- 2011-12 : + CM
				NULL,								-- 2011-12 : + CM
				NULL								-- 2011-12 : + CM	
				);
		END*/
			
		IF @@ERROR <> 0
			SET @BreakingID = 0
	END

	RETURN @BreakingID
END
