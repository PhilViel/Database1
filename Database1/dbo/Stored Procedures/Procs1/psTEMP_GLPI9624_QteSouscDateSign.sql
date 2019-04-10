/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEMP_GLPI9624_QteSouscYearQualif
Nom du service		: 
But 				: pour le rapport RapStatistiquesMensuellesGLPI utilisé par S Dupèré 
Facette				: 

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
	
		2014-02-06		Donald Huppé						

	exec psTEMP_GLPI9624_QteSouscYearQualif '2012-12-31'

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_GLPI9624_QteSouscDateSign]
(
	@dtDateFin datetime
)
AS
BEGIN

	select
		EnDateDu = LEFT(CONVERT(VARCHAR, @dtDateFin, 120), 10), 
		DateSignature,
		QtéBenef = count(*)
	from
	 (
		select 
			c.beneficiaryid,
			yearqualif = max(c.yearqualif),
			DateSignature = min(year(u.signaturedate))
		FROM dbo.Un_Convention c
		JOIN dbo.mo_human hb on c.beneficiaryID = hb.humanid
		JOIN dbo.Un_Unit u on c.conventionid = u.conventionid
		group by
			c.beneficiaryid
		HAVING min(u.signaturedate) <= @dtDateFin
		) V 
	group by DateSignature
	order by DateSignature

end	


