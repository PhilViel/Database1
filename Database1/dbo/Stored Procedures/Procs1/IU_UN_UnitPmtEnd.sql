/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_UnitPmtEnd
Description         :	Activation/Désactivation de la fin de paiement forcé sur un groupe d’unités.
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL
Note                :	ADX0000722	IA	2005-07-06	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_UnitPmtEnd] (
	@ConnectID INTEGER, -- ID Unique de connexion de l’usager qui active la fin de paiement forcé (0=Désactiver).
	@UnitID INTEGER ) -- ID unique du groupe d’unités sur lequel il faut effectuer l’arrêt de paiement forcé.
AS
BEGIN
	IF ISNULL(@ConnectID,0) <= 0
		SET @ConnectID = NULL

	UPDATE dbo.Un_Unit 
	SET PmtEndConnectID = @ConnectID
	WHERE UnitID = @UnitID

	IF @@ERROR = 0
		RETURN 1
	ELSE
		RETURN -1
END


