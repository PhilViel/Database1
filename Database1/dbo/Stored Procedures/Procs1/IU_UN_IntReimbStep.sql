/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_IntReimbStep
Description         :	Procédure d’insertion des étapes de RIN.
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL
Note                :	ADX0000694	IA	2005-06-08	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_IntReimbStep] (
	@ConnectID INTEGER, -- ID unique de l’usager qui a provoqué cette insertion.
	@UnitIDs INTEGER, -- ID du blob contenant les UnitID séparés par des , des groupe d’unités dont il faut inscrire un changement d’étape.
	@iIntReimbStep INTEGER ) -- Étape à laquelle doivent passer les groupes d’unités.
AS
BEGIN
	INSERT INTO Un_IntReimbStep (
			UnitID,
			iIntReimbStep,
			dtIntReimbStepTime,
			ConnectID )
		SELECT
			Val,
			@iIntReimbStep,
			GETDATE(),
			@ConnectID
		FROM dbo.FN_CRQ_BlobToIntegerTable(@UnitIDs)

	IF @@ERROR = 0
		RETURN 1
	ELSE
		RETURN -1
END

