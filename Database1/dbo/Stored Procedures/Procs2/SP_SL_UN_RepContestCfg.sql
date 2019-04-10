/****************************************************************************************************
	Renvoi la liste des concours inscrits au système.
 ******************************************************************************
	2004-09-07 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROC [dbo].[SP_SL_UN_RepContestCfg] (
	@RepContestCfgID INTEGER, -- ID unique du concours (0 = tous).  Sert de filtre à la liste.
	@RepContestType CHAR(3)) -- Type de concours ('ALL' = tous).  Sert de filtre à la liste.
AS
BEGIN
	SELECT
		RepContestCfgID,
		StartDate,
		EndDate,
		ContestName,
		RepContestType,
		RepContestTypeDesc =
			CASE 
				WHEN RepContestType = 'REC' THEN 'Recrues'
				WHEN RepContestType = 'DIR' THEN 'Directeurs'
				WHEN RepContestType = 'CBP' THEN 'Club du président'
				WHEN RepContestType = 'OTH' THEN 'Autres concours'
			END
	FROM Un_RepContestCfg
	WHERE (@RepContestCfgID = 0 -- Filtre du concours
		 OR @RepContestCfgID = RepContestCfgID)
	  AND (@RepContestType = 'ALL' -- Filtre du type de concours
		 OR @RepContestType = RepContestType)
END

