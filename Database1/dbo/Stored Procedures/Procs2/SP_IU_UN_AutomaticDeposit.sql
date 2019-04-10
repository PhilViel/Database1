
/****************************************************************************************************
Code de service		:		SP_IU_UN_AutomaticDeposit
Nom du service		:		SP_IU_UN_AutomaticDeposit
But					:		Ajout/modification d'horaires de prélèvement
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@ConnectID					-- ID Unique de connexion de l'usager
						@AutomaticDepositID			-- ID Unique de l'horaire de prélèvement 0 = nouvelle 
						@UnitID						-- ID unique du groupe d'unités
						@StartDate					-- Date d'entrée en vigueur de l'horaire
						@EndDate					-- Date de fin de l'horaire
						@FirstAutomaticDepositDate	-- Date du premier dépôt 
						@TimeUnit					-- Unité temporelle
						@TimeUnitLap				-- Nombre d'unité temporelle
						@CotisationFee				-- Montant de cotisation et frais par prélèvement
						@SubscInsur					-- Montant d'assurance souscripteur par prélèvement
						@BenefInsur					-- Montant d'assurance bénéficiaire par prélèvement
						

Exemple d'appel:
					
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													@AutomaticDepositID

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2004-06-09					Bruno Lapointe							Migration
		2009-09-24					Jean-François Gauthier					Remplacement du @@Identity par Scope_Identity()
 ****************************************************************************************************/

CREATE PROC [dbo].[SP_IU_UN_AutomaticDeposit] (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@AutomaticDepositID INTEGER, -- ID Unique de l'horaire de prélèvement 0 = nouvelle 
	@UnitID INTEGER, -- ID unique du groupe d'unités
	@StartDate DATETIME, -- Date d'entrée en vigueur de l'horaire
	@EndDate DATETIME, -- Date de fin de l'horaire
	@FirstAutomaticDepositDate DATETIME, -- Date du premier dépôt 
	@TimeUnit SMALLINT, -- Unité temporelle
	@TimeUnitLap INTEGER, -- Nombre d'unité temporelle
	@CotisationFee MONEY, -- Montant de cotisation et frais par prélèvement
	@SubscInsur MONEY, -- Montant d'assurance souscripteur par prélèvement
	@BenefInsur MONEY) -- Montant d'assurance bénéficiaire par prélèvement
AS
BEGIN
	-- 0 = Pas sauvegardé (Erreur)

	IF ISNULL(@FirstAutomaticDepositDate,0) <= 0
		SET @FirstAutomaticDepositDate = GetDate()

	IF ISNULL(@StartDate,0) <= 0 
		SET @StartDate = GetDate()

	IF @EndDate <= 0
		SET @EndDate = NULL

	IF @AutomaticDepositID = 0
	BEGIN
		-- Ajout
		INSERT INTO Un_AutomaticDeposit (
			UnitID,
			StartDate,
			EndDate,
			FirstAutomaticDepositDate,
			TimeUnit,
			TimeUnitLap,
			CotisationFee,
			SubscInsur,
			BenefInsur)
		VALUES (
			@UnitID,
			@StartDate,
			@EndDate,
			@FirstAutomaticDepositDate,
			@TimeUnit,
			@TimeUnitLap,
			@CotisationFee,
			@SubscInsur,
			@BenefInsur)

		IF (@@ERROR = 0)
		BEGIN
			SELECT @AutomaticDepositID = SCOPE_IDENTITY()
			EXEC IMo_Log @ConnectID, 'Un_AutomaticDeposit', @AutomaticDepositID, 'I', ''
		END
	END
	ELSE
	BEGIN
		-- Modification
		UPDATE Un_AutomaticDeposit 
		SET
			UnitID = @UnitID,
			StartDate = @StartDate,
			EndDate = @EndDate,
			FirstAutomaticDepositDate = @FirstAutomaticDepositDate,
			TimeUnit = @TimeUnit,
			TimeUnitLap = @TimeUnitLap,
			CotisationFee = @CotisationFee,
			SubscInsur = @SubscInsur,
			BenefInsur = @BenefInsur
		WHERE AutomaticDepositID = @AutomaticDepositID

		IF (@@ERROR <> 0)
			SET @AutomaticDepositID = 0
		ELSE
			EXEC IMo_Log @ConnectID, 'Un_AutomaticDeposit', @AutomaticDepositID, 'U', ''
	END

	RETURN @AutomaticDepositID
END
