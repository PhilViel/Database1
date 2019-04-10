/****************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc.

Code du service		: psREPR_RapportStatistiqueArriveeEtDepartRepresentant
Nom du service		: Procedure pour le RapportStatistiqueArriveeEtDepartRepresentant
But 				: 
Facette				: REPR

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

		exec psREPR_RapportStatistiqueArriveeEtDepartRepresentant 
			@dtDateFrom = '2016-01-01',
			@dtDateTo = '2017-10-30'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2016-05-10		Donald Huppé						Création du service		
		2017-10-31		Donald Huppé						Exclure rep corpo et siège social 
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_RapportStatistiqueArriveeEtDepartRepresentant] 
(
	@dtDateFrom DATETIME,
	@dtDateTo DATETIME
)
AS
BEGIN
	--DECLARE @dtDateFrom datetime = '2016-01-01'
	--DECLARE @dtDateTo datetime = '2016-04-30'


	SELECT *
	FROM (
		SELECT
			ActifAuDebut =	CASE WHEN ISNULL(r.BusinessStart,'9999-12-31') <= @dtDateFrom and isnull(R.BusinessEnd,'9999-12-31') > @dtDateFrom THEN 1 ELSE 0 END ,
			DevenuActif =	CASE WHEN ISNULL(r.BusinessStart,'9999-12-31') BETWEEN @dtDateFrom and @dtDateTo THEN 1 ELSE 0 END ,
			DevenuInactif = CASE WHEN ISNULL(r.BusinessEnd,'9999-12-31') BETWEEN @dtDateFrom AND @dtDateTo THEN 1 ELSE 0 END,
			ActifAlaFin =	CASE WHEN ISNULL(r.BusinessStart,'9999-12-31') <= @dtDateTo and isnull(R.BusinessEnd,'9999-12-31') > @dtDateTo THEN 1 ELSE 0 END,
			NomRepresentant = HR.LastName,
			PrenomRepresentant = HR.FirstName,
			Directeur = hb.FirstName + ' ' + hb.LastName,
			R.RepCode,
			r.BusinessStart,
			r.BusinessEnd

		FROM Un_Rep R
		join (
			SELECT
				RB.RepID,
				BossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
			FROM 
				Un_RepBossHist RB
				JOIN (
					SELECT
						RepID,
						RepBossPct = MAX(RepBossPct)
					FROM 
						Un_RepBossHist RB
					WHERE 
						RepRoleID = 'DIR'
						AND StartDate IS NOT NULL
						AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, @dtDateTo, 120), 10)
						AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, @dtDateTo, 120), 10)) 
					GROUP BY
							RepID
					) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
				WHERE RB.RepRoleID = 'DIR'
					AND RB.StartDate IS NOT NULL
					AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, @dtDateTo, 120), 10)
					AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, @dtDateTo, 120), 10))
				GROUP BY
					RB.RepID
			)br on r.RepID = br.RepID
		JOIN Mo_Human hb on br.BossID = hb.HumanID
		JOIN Mo_Human HR ON R.RepID = HR.HumanID
		LEFT JOIN tblGENE_Telephone tt on HR.HumanID = tt.iID_Source and getdate() BETWEEN tt.dtDate_Debut and isnull(tt.dtDate_Fin,'9999-12-31') and tt.iID_Type = 4
		LEFT JOIN tblGENE_Courriel c on c.iID_Source = hr.HumanID and GETDATE() BETWEEN c.dtDate_Debut and ISNULL(c.dtDate_Fin,'9999-12-31') and c.iID_Type = 2
		LEFT JOIN tblREPR_Lien_Rep_RepCorpo RC ON RC.RepID_Corpo = R.RepID
		WHERE 
			RC.RepID_Corpo IS NULL -- EXCLURE REP CORPO
			AND R.RepID <> 149876 -- EXCLURE SIEGE SOCIAL
		) V

	WHERE V.ActifAuDebut <> 0 OR V.DevenuActif <> 0 OR V.DevenuInactif <> 0 OR V.ActifAlaFin <> 0

END
