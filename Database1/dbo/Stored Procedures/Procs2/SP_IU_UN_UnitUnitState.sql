/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_IU_UN_UnitUnitState
Description         :	Procedure d'ajout et de modification d'historiques d'états de groupe d'unités.
Valeurs de retours  :	@ReturnValue :
									>0 :	La sauvegarde a réussie.  La valeur de retour correspond au UnitUnitStateID de
											l'historique d'état sauvegardé.
									<=0 :	La sauvegarde a échouée.
Note                :						2004-04-30	Dominic Létourneau	Création
													2004-07-12	Bruno Lapointe			Correction @UnitStateID est un VARCHAR(3) et
																								non un integer
								ADX0001602	BR	2005-10-11	Bruno Lapointe			SCOPE_IDENTITY au lieu de IDENT_CURRENT
														2015-10-09	Pierre-Luc Simard		Ne plus permettre l'appel via Delphi. Le retrait des accès ne fonctionne pas.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_UN_UnitUnitState] (
	@ConnectID INTEGER, -- Identifiant unique de la connection	
	@UnitUnitStateID INTEGER, -- Identifiant unique de l'historique d'états sur groupe d'unités
	@UnitID INTEGER, -- Identifiant unique de la Unit
	@UnitStateID VARCHAR(3), -- Identifiant unique de l'état de groupe d'unités
	@StartDate DATETIME) -- Date d'activation de l'état
AS
BEGIN
	DECLARE @ID MoID

	SET @ID = 1/0

	/*
	IF @UnitUnitStateID = 0
	-- Le dossier n'est pas existant; il sera donc créé
	BEGIN
		INSERT Un_UnitUnitState (
			UnitID,
			UnitStateID,
			StartDate)
		SELECT 
			@UnitID,
			@UnitStateID,
			ISNULL(@StartDate, GETDATE()) -- Prend la date actuelle du traitement si nulle

		-- Gestion d'erreur
		IF @@ERROR = 0
			SET @ID = SCOPE_IDENTITY()
		ELSE
			SET @ID = 0
	END
	ELSE -- Le dossier est existant et sera modifié
	BEGIN
		UPDATE Un_UnitUnitState
		SET 
			StartDate = @StartDate,
			UnitStateID = @UnitStateID
		WHERE UnitUnitStateID = @UnitUnitStateID 

		-- Gestion d'erreur
		IF @@ERROR = 0
			SET @ID = @UnitUnitStateID
		ELSE
			SET @ID = 0
	END

	*/

	RETURN @ID -- Retourne l'ID du dossier si tout a fonctionné, sinon 0
END


