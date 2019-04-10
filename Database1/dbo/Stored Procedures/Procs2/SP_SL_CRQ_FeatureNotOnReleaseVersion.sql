/*****************************************************************************
	Cette requête retournera la liste de tous les Features donc le 
	ReleaseVersionID est plus grand que le plus grand VersionID de la table 
	Un_Version.
******************************************************************************
	2004-04-23 Bruno
		Point CRQ-BAS-00002
*****************************************************************************/
CREATE PROCEDURE SP_SL_CRQ_FeatureNotOnReleaseVersion
AS
BEGIN
	SELECT DISTINCT
		FRV.Feature
	FROM CRQ_FeatureReleaseVersion FRV
	JOIN (
		SELECT VersionID = MAX(VersionID) 
		FROM CRQ_Version
		) V ON (V.VersionID >= FRV.ReleaseVersionID)
	ORDER BY FRV.Feature
END
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'SP_SL_CRQ_Lang' AND type = 'P')
	DROP PROCEDURE SP_SL_CRQ_Lang 
