
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas
Nom                 :	DL_UN_RepRecruitMonthCfg
Description         :	Suppression d’une configuration de durée en mois des recrues
Valeurs de retours  :	@ReturnValue :
							> 0 : [Réussite]
							<= 0 : [Échec].

Note                :	ADX0001254	IA	2007-03-23	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE dbo.DL_UN_RepRecruitMonthCfg(
	@RepRecruitMonthCfgID INTEGER)		
AS
BEGIN
	DECLARE @iResult INTEGER

	SET @iResult = 1

	DELETE 
	FROM Un_RepRecruitMonthCfg
	WHERE RepRecruitMonthCfgID = @RepRecruitMonthCfgID
	
	IF @@ERROR <> 0
		SET @iResult = -1

	RETURN @iResult
END

