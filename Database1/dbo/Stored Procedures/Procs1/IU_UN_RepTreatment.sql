/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_RepTreatment 
Description         :	Insère un traitement dans la table des traitements de commissions.
Valeurs de retours  :	@ReturnValue :
									>0 :	L’insertion a réussi. La valeur correspond au RepTreatmentID du traitement
											sauvegardé.
									<=0 :	L’insertion a échoué.
Note                :	ADX0000696	IA	2005-08-16	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_RepTreatment] (
	@ConnectID INTEGER, -- ID de connexion de l’usager.
	@RepTreatmentDate DATETIME, -- Dernier jour inclusivement à traiter.
	@MaxRepRisk MONEY ) -- Maximum de pourcentage de risque utilisé pour ce traitement.
AS
BEGIN
	-- Variable qui contiendra le ID du traitement crée.
	DECLARE
		@iRepTreatmentID INTEGER
	
	-- Insère le traitement de commission
	INSERT INTO Un_RepTreatment (
		RepTreatmentDate,
		MaxRepRisk )
	VALUES (
		@RepTreatmentDate,
		@MaxRepRisk )
	
	IF @@ERROR = 0
	BEGIN
		-- Va chercher le ID du traitement
		SET @iRepTreatmentID = SCOPE_IDENTITY()
		-- Insère une trace de par qui, quand et où le traitement a été crée 
		EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_RepTreatment', @iRepTreatmentID, 'I', ''
	END
	ELSE
		-- Erreur à la création du traitement.
		SET @iRepTreatmentID = -1
	
	RETURN @iRepTreatmentID
END

