/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 : IU_UN_UnitReimbDateAdjust
Description         : Procédure de modification de la date de remboursement intégral (date ajustée)
Valeurs de retours  : 	@iResult 			
			 -1  : Le groupe d'unités n'existe pas
			 0   : Erreur à la mise à jour
			 > 0 : Pas d'erreur, la valeur correspond au UnitID
Note                :					2004-08-19 	Bruno Lapointe		Migration
				ADX0001114	IA	2006-11-17	Alain Quirion			Utilisation du paramètre @IntReimbDateAdjust
										2014-12-05	Pierre-Luc Simard	Utiliser UniID au lieu de UnitNo
 ***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_UnitReimbDateAdjust] (
	@ConnectID INTEGER, 			-- ID unique de connexion de l'usager
	@UnitID INTEGER, 			-- ID unique du groupe d'unités
	@IntReimbDateAdjust DATETIME) 		-- Date ajustée de RI 
AS
BEGIN
	DECLARE @iResult INTEGER

	SET @iResult = @UnitID

	IF NOT EXISTS (SELECT UnitID FROM dbo.Un_Unit WHERE UnitID = @UnitID)
		SET @iResult = -1
	
	IF @iResult > 0
		UPDATE dbo.Un_Unit 
		SET IntReimbDateAdjust = @IntReimbDateAdjust
		WHERE UnitID = @UnitID

	IF @@ERROR <> 0
		SET @iResult = 0

	RETURN @iResult
END


