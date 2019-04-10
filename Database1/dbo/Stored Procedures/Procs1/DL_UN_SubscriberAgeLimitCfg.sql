
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	DL_UN_SubscriberAgeLimitCfg
Description         :	Supprime un enregistrement de configuration des limites d'âge du souscripteur
Valeurs de retours  :		>0 : Suppression réussie
							<=0 : Erreur SQL

Note                :	ADX0000472	IA	2005-02-04	Bruno Lapointe		Création
						ADX0001268	IA	2007-03-26	Alain Quirion		Modification. CHangement de nom de la procédure et suppresion du COnnectID
*********************************************************************************************************************/
CREATE PROCEDURE dbo.DL_UN_SubscriberAgeLimitCfg (
	@SubscriberAgeLimitCfgID INTEGER ) -- ID Unique de l'enregistrement à supprimer
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = 0

	DELETE
	FROM Un_SubscriberAgeLimitCfg
	WHERE SubscriberAgeLimitCfgID = @SubscriberAgeLimitCfgID

	IF @@ERROR <> 0
		SET @iResult = -1
	ELSE
		SET @iResult = 1

	RETURN @iResult
END

