/****************************************************************************************************
	Validation des paramètres de configuration
 ******************************************************************************
	2004-08-27 Bruno Lapointe
		Création		
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_Def_IU] (
	@BusinessBonusLimit INTEGER) -- Nombre d'années après la date de vigueur des groupes d'unités avant l'expiration des bonis d'affaires.
AS
BEGIN
	-- DEF01 : Le nombre d'année avant l'expiration des boni d'affaire doit être plus grand que les nombres d'années de la configuration des versements des bonis d'affaires.
	
	CREATE TABLE #WngAndErr(
		Code VARCHAR(5),
		Info1 VARCHAR(100),
		Info2 VARCHAR(100),
		Info3 VARCHAR(100)
	)

	-- DEF01 : Le nombre d'année avant l'expiration des boni d'affaire ne doit pas dépasser les nombres d'années de la configuration des versements des bonis d'affaires.
	IF EXISTS (
			SELECT 
				RepBusinessBonusCfgID
			FROM Un_RepBusinessBonusCfg
			WHERE BusinessBonusNbrOfYears >= @BusinessBonusLimit)
		INSERT INTO #WngAndErr
			SELECT 
				'DEF01',
				'',
				'',
				''

	SELECT *
	FROM #WngAndErr

	DROP TABLE #WngAndErr
END

