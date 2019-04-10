
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_MinIndAutDepositCfg
Description         :	Supprime un enregistrement de configuration du minimum par prélèvement pour les prélèvements
						automatiques des conventions individuelles.
Valeurs de retours  :		>0 : Suppression réussie
							<=0 : Erreur SQL

Note                :	ADX0000472	IA	2005-02-07	Bruno Lapointe		Création
						ADX0001275	IA	2007-03-27	Alain Quirion		Modification.  Changement de nom et suppresion du paramètre d'Entrée @ConnectID
*********************************************************************************************************************/
CREATE PROCEDURE dbo.DL_UN_MinIndAutDepositCfg (
	@MinIndAutDepositCfgID INTEGER ) -- ID unique de l'enregistrement à supprimer
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = 0

	DELETE
	FROM Un_MinIndAutDepositCfg
	WHERE MinIndAutDepositCfgID = @MinIndAutDepositCfgID

	IF @@ERROR <> 0
		SET @iResult = -1
	ELSE
		SET @iResult = 1

	RETURN @iResult
END

