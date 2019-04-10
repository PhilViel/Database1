/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */
/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettreDepotConventionTFrais
Nom du service		: Générer la lettre de confirmation de dépot avec frais dans une convention T
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psCONV_RapportLettreDepotConventionTFrais 'T-20121210003'
						EXECUTE psCONV_RapportLettreDepotConventionTFrais 'T-20080501028'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-06-27		Donald Huppé						Création du service	
		2013-09-25		Maxime Martel						Ajout du plan de classification		
		2017-09-27      Donald Huppé                        Deprecated - Cette procédure n'est plus utilisée (remplacée par psCONV_RapportLettre_le_conf_max_t)	
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettreDepotConventionTFrais] 
(
	@cConventionno varchar(15) --Filtre sur un numéro de convention

)
AS
BEGIN

	RETURN --Deprecated

	DECLARE
		@today datetime
		
	set @today = GETDATE()

	SELECT top 1 -- Pour avoir la première cotisation positive dans la convention
		c.ConventionNo,
		hs.LangID,
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
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.subscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','') + '_le_reg_T'
	FROM 
		Un_Convention c
		JOIN dbo.Mo_Human hs ON c.SubscriberID = hs.HumanID
		join Mo_Sex sex ON sex.SexID = hs.SexID AND sex.LangID = hs.LangID
		JOIN dbo.Mo_Human hb ON c.BeneficiaryID = hb.HumanID
		JOIN dbo.Mo_Adr a ON hs.AdrID = a.AdrID
		JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
		JOIN Un_Cotisation ct on u.UnitID = ct.UnitID
		JOIN Un_Oper o ON ct.OperID = o.OperID
	where 
		--o.OperTypeID IN ('RDI','CHQ')
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


