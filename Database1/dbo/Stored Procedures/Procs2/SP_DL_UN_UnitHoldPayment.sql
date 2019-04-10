/****************************************************************************************************
	Permet de détruire un enregistrement d'arrêt de paiement sur un groupe d'unités.
 ******************************************************************************
	2003-06-12 André Sanscartier
		Création
	2004-06-09 Bruno Lapointe
		Migration
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_DL_UN_UnitHoldPayment] (
	@ConnectID INTEGER, -- ID unique de connexion de l'usager
	@UnitHoldPaymentID INTEGER) -- ID unique de l'arrêt de paiement
AS
BEGIN
	-- 0 = Erreur à la suppression.

	DELETE FROM Un_UnitHoldPayment
	WHERE UnitHoldPaymentID = @UnitHoldPaymentID

	IF @@ERROR = 0
		RETURN 1
	ELSE
		RETURN -1
END

