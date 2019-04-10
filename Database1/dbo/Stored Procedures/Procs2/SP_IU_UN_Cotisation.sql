
/****************************************************************************************************
Code de service		:		SP_IU_UN_Cotisation
Nom du service		:		SP_IU_UN_Cotisation
But					:		Création ou modification d'une transaction de cotisation
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@ConnectID
						@CotisationID
						@OperID
						@UnitID
						@EffectDate
						@Cotisation
						@Fee
						@BenefInsur
						@SubscInsur
						@TaxOnInsur

Exemple d'appel:
					
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                    
Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2004-07-02					Bruno Lapointe							Migration
		2009-09-24					Jean-François Gauthier					Remplacement du @@Identity par Scope_Identity()
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[SP_IU_UN_Cotisation] (
	@ConnectID INTEGER,
	@CotisationID INTEGER,
	@OperID INTEGER,
	@UnitID INTEGER,
	@EffectDate DATETIME,
	@Cotisation MONEY,
	@Fee MONEY,
	@BenefInsur MONEY,
	@SubscInsur MONEY,
	@TaxOnInsur MONEY)
AS
BEGIN
	IF @CotisationID = 0
	BEGIN
		INSERT INTO Un_Cotisation (
			OperID,
			UnitID,
			EffectDate,
			Cotisation,
			Fee,
			BenefInsur,
			SubscInsur,
			TaxOnInsur)
		VALUES (
			@OperID,
			@UnitID,
			@EffectDate,
			@Cotisation,
			@Fee,
			@BenefInsur,
			@SubscInsur,
			@TaxOnInsur)

		IF @@ERROR = 0
			SELECT @CotisationID = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		UPDATE Un_Cotisation SET
			OperID = @OperID,
			UnitID = @UnitID,
			EffectDate = @EffectDate,
			Cotisation = @Cotisation,
			Fee = @Fee,
			BenefInsur = @BenefInsur,
			SubscInsur = @SubscInsur,
			TaxOnInsur = @TaxOnInsur
		WHERE CotisationID = @CotisationID

		IF @@ERROR <> 0
			SET @CotisationID = 0
	END

	RETURN @CotisationID
END
