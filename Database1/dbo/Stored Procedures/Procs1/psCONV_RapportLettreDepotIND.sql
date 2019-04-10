/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportLettreDepotIND
Nom du service		: Générer la lettre de confirmation de dépot dans une convention individuelle
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psCONV_RapportLettreDepotIND 'I-20131211002', '2014-04-01'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-07-02		Donald Huppé						Création du service	
		2013-09-25		Maxime Martel						Ajout du plan de classification		
		2014-04-02		Donald Huppé						Ajout de OpertypeID PRD à la demande de Guylaine Berthiaume
		2018-09-07		Maxime Martel						JIRA MP-699 Ajout de OpertypeID COU 
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportLettreDepotIND] 
(
	@cConventionno varchar(15), --Filtre sur un numéro de convention
	@DateEffective datetime

)
AS
BEGIN
	declare 
		@today datetime
	
	set @today = GETDATE()

	SELECT top 1 -- Pour avoir la première cotisation positive à cette date effective
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
		PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.subscriberID,1) + '\' + replace(LEFT(CONVERT(VARCHAR, @today, 120), 10),'-','') + '_le_ind'
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
		o.OperTypeID IN ('RDI','CHQ','PRD','COU')
		and ct.Cotisation > 0
		and c.ConventionNo = @cConventionno
		and ct.EffectDate = @DateEffective
	ORDER BY o.OperID ASC

END