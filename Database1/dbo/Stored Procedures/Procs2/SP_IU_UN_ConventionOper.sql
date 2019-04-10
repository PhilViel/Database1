
/****************************************************************************************************
Code de service		:		SP_IU_UN_ConventionOper
Nom du service		:		SP_IU_UN_ConventionOper
But					:		Création ou modification d'une transaction de cotisation.
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@ConnectID
						@ConventionOperID
						@ConventionID
						@OperID
						@ConventionOperTypeID
						@ConventionOperAmount

Exemple d'appel:
					
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													@ConventionOperID

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2004-07-02					Bruno Lapointe							Migration
		2009-09-24					Jean-François Gauthier					Remplacement du @@Identity par Scope_Identity()
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[SP_IU_UN_ConventionOper] (
	@ConnectID INTEGER,
	@ConventionOperID INTEGER,
	@ConventionID INTEGER,
	@OperID INTEGER,
	@ConventionOperTypeID VARCHAR(3),
	@ConventionOperAmount MONEY)
AS 
BEGIN
	IF @ConventionOperID = 0
	BEGIN
		INSERT INTO Un_ConventionOper (
			OperID,
			ConventionID,
			ConventionOperTypeID,
			ConventionOperAmount)
		VALUES (
			@OperID,
			@ConventionID,
			@ConventionOperTypeID,
			@ConventionOperAmount)

		IF @@ERROR = 0
			SELECT @ConventionOperID = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		UPDATE Un_ConventionOper SET
			OperID = @OperID,
			ConventionID = @ConventionID,
			ConventionOperTypeID = @ConventionOperTypeID,
			ConventionOperAmount = @ConventionOperAmount
		WHERE ConventionOperID = @ConventionOperID

		IF @@ERROR <> 0
			SET @ConventionOperID = 0
	END
END
