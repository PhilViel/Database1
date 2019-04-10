/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service		: psCONV_RapportLettre_le_conf_max_t
Nom du service		: Générer la lettre de confirmation de dépot avec frais dans une convention T
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psCONV_RapportLettre_le_conf_max_t 'T-20181122001'


Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2018-11-26		Donald Huppé						Création du service							jira prod-12938

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettre_le_conf_max_t] 
(
	@cConventionno varchar(15) --Filtre sur un numéro de convention

)
AS
BEGIN
	DECLARE
		@today datetime
		
	set @today = GETDATE()

	SELECT top 1 -- Pour avoir la première cotisation positive dans la convention
		c.ConventionNo,
		Langue = hs.LangID,
		AppelLong = sex.LongSexName,
		AppelCourt = sex.ShortSexName,
		SouscPrenom = hs.FirstName,
		SouscNom = hs.LastName,
		SouscAdresse = a.Address,
		SouscVille = a.City,
		SouscCodePostal = dbo.fn_Mo_FormatZIP( a.ZipCode,a.countryID),
		SouscProvince = a.StateName,
		SouscPays = a.CountryID,
		BenefPrenom = hb.FirstName,
		c.SubscriberID,
		ct.Cotisation,
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.subscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','') + '_le_conf_MAX_T',
		nomRep = hr.FirstName + ' '+ hr.LastName,
		sexRep = hr.SexID,
		sexBenef = hb.SexID
	FROM 
		Un_Convention c
		JOIN dbo.Mo_Human hs ON c.SubscriberID = hs.HumanID
		JOIN Mo_Sex sex ON sex.SexID = hs.SexID AND sex.LangID = hs.LangID
		JOIN dbo.Mo_Human hb ON c.BeneficiaryID = hb.HumanID
		JOIN Un_Subscriber s on s.SubscriberID = c.SubscriberID
		JOIN Mo_Human hr on hr.HumanID = s.RepID
		JOIN dbo.Mo_Adr a ON hs.AdrID = a.AdrID
		JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
		JOIN Un_Cotisation ct on u.UnitID = ct.UnitID
		JOIN Un_Oper o ON ct.OperID = o.OperID
		JOIN (
			SELECT C1.ConventionID, MAX_OperID = MAX(O1.OperID)
			FROM Un_Convention c1
			JOIN dbo.Un_Unit u1 ON c1.ConventionID = u1.ConventionID
			JOIN Un_Cotisation ct1 on u1.UnitID = ct1.UnitID
			JOIN Un_Oper o1 ON ct1.OperID = o1.OperID						
			WHERE O1.OperTypeID IN ('PRD','CHQ','RDI','COU','CPA')
			AND c1.ConventionNo = @cConventionno
			GROUP BY C1.ConventionID
			)MO ON MO.MAX_OperID = O.OperID
	where 
		ct.Cotisation > 0
		and c.ConventionNo = @cConventionno
	ORDER BY ct.EffectDate ASC

END

/*
SELECT *
FROM dbo.Un_Convention c
JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
JOIN Un_Cotisation ct on u.UnitID = ct.UnitID
JOIN Un_Oper o ON ct.OperID = o.OperID
where c.ConventionNo LIKE 'U-20060523012'
AND o.OperTypeID = 'FRS'
order by c.ConventionNo desc

*/


