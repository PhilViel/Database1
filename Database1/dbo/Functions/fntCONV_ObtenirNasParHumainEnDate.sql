CREATE FUNCTION [dbo].[fntCONV_ObtenirNasParHumainEnDate] (
	@dtDateFin date = NULL
)
RETURNS TABLE
AS RETURN
(
	SELECT CB.HumanID, CB.SocialNumber, CB.EffectDate as dtDateDebut
	  FROM (	SELECT HumanID, SocialNumber, EffectDate,
					   Row_Num = Row_Number() OVER (PARTITION BY HumanID ORDER BY EffectDate DESC, HumanSocialNumberID DESC)
				  FROM dbo.UN_HumanSocialNumber
				 WHERE EffectDate <= IsNull(@dtDateFin, GetDate())
			) CB
	 WHERE CB.Row_Num = 1
)