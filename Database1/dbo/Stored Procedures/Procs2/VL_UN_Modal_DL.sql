
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_Modal_DL
Description         :	Validation avant supprsion d'une modalité de dépôt
Valeurs de retours  :	Dataset :
							Code	CHAR(5)	Code d’erreur
							
						Validation :
							Code	Description
							MOD01	La modalité de dépôts est utilisée par des groupes d’unités.
							MOD02	La modalité de dépôts est utilisée dans un historique des modalités de dépôts d’un groupe d’unités.

Note                :			ADX0001317	IA	2007-05-01	Alain Quirion	Création
										ADX0002529	BR	2007-08-14	Bruno Lapointe Affichage d'un message à la fois.
*********************************************************************************************************************/
CREATE PROCEDURE dbo.VL_UN_Modal_DL (	
	@ModalID INTEGER) -- ID de la modalité de dépôt
AS
BEGIN
	DECLARE @tError TABLE(
		Code CHAR(5))

	IF EXISTS (
				SELECT *
				FROM Un_Unit
				WHERE ModalID = @ModalID)
		INSERT INTO @tError
		VALUES('MOD01')
	ELSE IF EXISTS (
				SELECT *
				FROM Un_UnitModalhistory
				WHERE ModalID = @ModalID)
		INSERT INTO @tError
		VALUES('MOD02')

	SELECT Code
	FROM @tError
END

