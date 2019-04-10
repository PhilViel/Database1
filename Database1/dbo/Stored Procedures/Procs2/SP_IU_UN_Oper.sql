
/****************************************************************************************************
Code de service		:		SP_IU_UN_Oper
Nom du service		:		SP_IU_UN_Oper
But					:		Création ou modification d'un opération.
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@ConnectID
						@OperID
						@OperTypeID
						@OperDate

Exemple d'appel:
					
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													@OperID
                    
Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2004-07-02					Bruno Lapointe							Migration
		2009-09-24					Jean-François Gauthier					Remplacement du @@Identity par Scope_Identity()
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[SP_IU_UN_Oper] (
	@ConnectID INTEGER,
	@OperID INTEGER,
	@OperTypeID VARCHAR(3),
	@OperDate DATETIME)
AS
BEGIN
	IF @OperID = 0
	BEGIN
		INSERT INTO Un_Oper (
			ConnectID,
			OperTypeID,
			OperDate)
		VALUES (
			@ConnectID,
			@OperTypeID,
			@OperDate)

		IF @@ERROR = 0
			SELECT @OperID = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		UPDATE Un_Oper SET
			OperTypeID = @OperTypeID,
			OperDate = @OperDate
		WHERE OperID = @OperID

		IF @@ERROR <> 0
			SET @OperID = 0
	END

	RETURN @OperID 
END
