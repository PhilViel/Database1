/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Code de service		:		SP_IU_UN_IrregularityType
Nom du service		:		SP_IU_UN_IrregularityType
But					:		Création ou modification d'un type d'anomalies.
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@ConnectID					-- ID Unique de connexion de l'usager
						@IrregularityTypeID			-- Identificateur unique
						@IrregularityTypeName		-- Nom de l'anomalies
						@SearchStoredProcedure		-- Nom de la procédure servant à la recherche du type d'anomalies
						@CorrectingStoredProcedure	-- Nom de la procédure servant à corriger partiellement ou entièrement ce type d'anomalies
						@Active						-- Permet de rendre visible ou non le type d'anomalies dans les recherches

Exemple d'appel:
					
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													>0 : La sauvegarde à réussi.  
													Correspond au IrregularityTypeID de l'enregistrement sauvegardé
                    
Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2005-02-03					Bruno Lapointe							Création							ADX0000496	IA
		2009-09-24					Jean-François Gauthier					Remplacement du @@Identity par Scope_Identity()
        2018-01-19                  Pierre-Luc Simard                       N'est plus utilisé
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_UN_IrregularityType] (
	@ConnectID MoID, -- ID Unique de connexion de l'usager
	@IrregularityTypeID MoID, -- Identificateur unique
	@IrregularityTypeName MoDesc, -- Nom de l'anomalies
	@SearchStoredProcedure MoDesc, -- Nom de la procédure servant à la recherche du type d'anomalies
	@CorrectingStoredProcedure MoDescOption, -- Nom de la procédure servant à corriger partiellement ou entièrement ce type d'anomalies
	@Active MoBitTrue ) -- Permet de rendre visible ou non le type d'anomalies dans les recherches
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE
		@iResultID MoID

	IF @IrregularityTypeID = 0
	BEGIN
		INSERT INTO Un_IrregularityType (
			IrregularityTypeName,
			SearchStoredProcedure,
			CorrectingStoredProcedure,
			Active )
		VALUES (
			@IrregularityTypeName,
			@SearchStoredProcedure,
			@CorrectingStoredProcedure,
			@Active )

		IF @@ERROR = 0
			SELECT @iResultID = SCOPE_IDENTITY()
		ELSE
			SET @iResultID = 0
	END
	ELSE
	BEGIN
		UPDATE Un_IrregularityType
		SET
			IrregularityTypeName = @IrregularityTypeName,
			SearchStoredProcedure = @SearchStoredProcedure,
			CorrectingStoredProcedure = @CorrectingStoredProcedure,
			Active = @Active
		WHERE IrregularityTypeID = @IrregularityTypeID

		IF @@ERROR = 0
			SET @iResultID = @IrregularityTypeID
		ELSE
			SET @iResultID = 0
	END

	RETURN @iResultID
    */
END