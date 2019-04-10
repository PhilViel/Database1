/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		: psCONV_RapportPourLettreDuProgrammeGrandParent
Nom du service		: jira prod-3491 : Rapport sur la liste des conventions avec lien de parenté au grand-parent 
					  et qui permet d'imprimer la lettre du programme grand-parent (le_ems_gp) et le diplôme
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXEC psCONV_RapportPourLettreDuProgrammeGrandParent @dtDateFrom = '2017-01-01',  @dtDateTo = '2017-01-17',  @ConventionNo = NULL
						EXEC psCONV_RapportPourLettreDuProgrammeGrandParent @dtDateFrom = '2016-01-01',  @dtDateTo = '2016-01-17',  @ConventionNo = NULL
						EXEC psCONV_RapportPourLettreDuProgrammeGrandParent @dtDateFrom = '2016-01-01',  @dtDateTo = '2016-01-17',  @ConventionNo = 'X-20170104001'

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2017-01-18		Donald Huppé						Création du service	

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportPourLettreDuProgrammeGrandParent] 
	@dtDateFrom DATETIME
	,@dtDateTo DATETIME
	,@ConventionNo VARCHAR(30) = null
AS
BEGIN


	IF @ConventionNo IS NOT NULL
		BEGIN
		SET @dtDateFrom = '9999-12-31'
		SET @dtDateTo = '9999-12-31'
		END

	SELECT 
		NomSousc = hs.FirstName + ' ' + hs.LastName
		,c.SubscriberID
		,LienParenté = rt.vcRelationshipType
		,c.ConventionNo
		,NomBenef = hb.FirstName + ' ' + hb.LastName
		,NAS = case when hb.SocialNumber is NOT null then 'Oui' ELSE 'Non' end
		,Datesignature = cast(min(u.SignatureDate) as date)
		,PlanClassification = [dbo].[fnCONV_ObtenirDossierClient](c.subscriberID,1) + '\'
		,hs.LangID
		,Langue = l.LangName
	from Un_Convention c
	join Un_RelationshipType rt on rt.tiRelationshipTypeID = c.tiRelationshipTypeID
	join Un_Unit u on c.ConventionID = u.ConventionID
	join Mo_Human hs on c.SubscriberID = hs.HumanID
	JOIN Mo_Lang l on hs.LangID = l.LangID
	join Mo_Human hb on c.BeneficiaryID = hb.HumanID
	where c.tiRelationshipTypeID = 2
	GROUP by 
		hs.FirstName + ' ' + hs.LastName
		,c.SubscriberID
		,rt.vcRelationshipType
		,c.ConventionNo
		,hb.FirstName + ' ' + hb.LastName
		,hb.SocialNumber
		,hs.LangID
		,l.LangName
	HAVING 
		MIN(u.SignatureDate) BETWEEN @dtDateFrom AND @dtDateTo
		OR (@ConventionNo IS NOT NULL AND c.ConventionNo = @ConventionNo)

end	


