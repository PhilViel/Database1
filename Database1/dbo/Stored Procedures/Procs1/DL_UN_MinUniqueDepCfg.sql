
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_MinUniqueDepCfg
Description         :	Supprime un enregistrement de configuration du minimum du dépôt pour un ajout d'unité avec
								modalité de paiement unique.
Valeurs de retours  :	>0 : Suppression réussie
								<=0 : Erreur SQL
Note                :	ADX0000472	IA	2005-02-07	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE dbo.DL_UN_MinUniqueDepCfg(
	@MinUniqueDepCfgID INTEGER ) -- ID unique de l'enregistrement à supprimer
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = 0

	DELETE
	FROM Un_MinUniqueDepCfg
	WHERE MinUniqueDepCfgID = @MinUniqueDepCfgID

	IF @@ERROR <> 0
		SET @iResult = -1
	ELSE
		SET @iResult = 1

	RETURN @iResult
END

