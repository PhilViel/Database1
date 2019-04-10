
/****************************************************************************************************
Code de service		:		SP_IU_UN_UnitHoldPayment
Nom du service		:		SP_IU_UN_UnitHoldPayment
But					:		Permet de crèer ou mêttre à jour un enregistrement d'arrêt de paiement sur un groupe d'unités.
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@ConnectID					-- ID unique de connexion de l'usager
						@UnitHoldPaymentID			-- ID unique de l'arrêt de paiement
						@UnitID						-- ID unique de l'unité
						@StartDate					-- Date de début de l'arrêt de paiement
						@EndDate					-- Date de fin (optionnelle) de l'arrêt de paiement
						@Reason						-- Description de la raison de l'arrêt de paiement

Exemple d'appel:
					
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													@UnitHoldPaymentID
                    
Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2003-06-12					André Sanscartier						Création
		2004-06-09					Bruno Lapointe							Migration
		2009-09-24					Jean-François Gauthier					Remplacement du @@Identity par Scope_Identity()
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[SP_IU_UN_UnitHoldPayment] (
	@ConnectID INTEGER, -- ID unique de connexion de l'usager
	@UnitHoldPaymentID INTEGER, -- ID unique de l'arrêt de paiement
	@UnitID INTEGER, -- ID unique de l'unité
	@StartDate DATETIME, -- Date de début de l'arrêt de paiement
	@EndDate DATETIME, -- Date de fin (optionnelle) de l'arrêt de paiement
	@Reason VARCHAR(75)) -- Description de la raison de l'arrêt de paiement
AS
BEGIN
	-- 0 = Pas sauvegarder (Erreur)

	IF ISNULL(@StartDate,0) <= 0
		SET @StartDate = GetDate()

	IF @EndDate <= 0
		SET @EndDate = NULL

	IF @UnitHoldPaymentID = 0
	BEGIN
		-- Ajout
		INSERT INTO Un_UnitHoldPayment (
			UnitID,
			StartDate,
			EndDate,
			Reason)
		VALUES (
			@UnitID,
			@StartDate,
			@EndDate,
			@Reason)

		IF @@ERROR = 0
			SELECT @UnitHoldPaymentID = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		-- Modification
		UPDATE Un_UnitHoldPayment SET
			UnitID = @UnitID,
			StartDate = @StartDate,
			EndDate = @EndDate,
			Reason = @Reason
		WHERE UnitHoldPaymentID = @UnitHoldPaymentID

		IF @@ERROR <> 0
			SET @UnitHoldPaymentID = 0
	END

	RETURN @UnitHoldPaymentID
END
