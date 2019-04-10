
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_BeneficiaryCeilingCfg
Description         :	Supprime un enregistrement de configuration des plafonds des bénéficiaires
Valeurs de retours  :		>0 : Suppression réussie								
							<=0 : Erreur SQL

Note                :	ADX0000472	IA	2005-02-04	Bruno Lapointe		Création
						ADX0001265	IA	2007-03-26	Alain Quirion		Modification. Suppresion du ConnectID
*********************************************************************************************************************/
CREATE PROCEDURE dbo.DL_UN_BeneficiaryCeilingCfg (
	@BeneficiaryCeilingCfgID INTEGER)
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = 0

	DELETE
	FROM Un_BeneficiaryCeilingCfg
	WHERE BeneficiaryCeilingCfgID = @BeneficiaryCeilingCfgID

	IF @@ERROR <> 0
		SET @iResult = -1
	ELSE
		SET @iResult = 1

	RETURN @iResult
END

