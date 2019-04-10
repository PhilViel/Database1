/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service		: JIRA TI-1939
Nom du service		: 
But 				: 
Facette				: 

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2017-02-03		Donald Huppé						Création du service
		2018-09-07		Maxime Martel						JIRA MP-699 Ajout de OpertypeID COU

exec psTEMP_JIRA_TI_1939_EpargneEtFrais_Enfant6AnsEtPlus '2017-01-31'
drop proc psTEMP_JIRA_TI_1939_EpargneEtFrais_Enfant6AnsEtPlus

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_JIRA_TI_1939_EpargneEtFrais_Enfant6AnsEtPlus]
(
	@dtDateFin datetime
)
AS
BEGIN


/*

1. Nous aimerions avoir le montant d'épargne (net de frais) total déposé à chaque mois, en terme de nouvelles ventes, pour les bénéficiaires qui ont commencé à cotiser à l'âge de 6 ans et plus, 
depuis les 120 derniers mois. Sur le même format que le GLPI 15395

2. Nous aimerions avoir le montant d'épargne                      déposé à chaque mois, en terme de nouvelles ventes, pour les bénéficiaires qui ont commencé à cotiser à l'âge de 6 ans et plus, 
depuis les 120 derniers mois. Sur le même format que le GLPI 15395

*/
	declare	 @Year int, @month int

	set @Year = year(@dtDateFin)
	set @month = month(@dtDateFin)

	select 
		Recensement = 'JIRA_TI_1939',
		EnDatedu = LEFT(CONVERT(VARCHAR, @dtDateFin, 120), 10),
		Annee = year(@dtDateFin),
		Mois = MONTH(@dtDateFin),
		Epargne = sum(ct.Cotisation),
		EpargneEtFrais = sum(ct.Cotisation + ct.Fee)
		--,c.ConventionNo

	from 
		Un_Convention c
		join Un_Unit u on c.ConventionID = u.ConventionID
		join Un_Modal m on u.ModalID = m.ModalID
		join Un_Cotisation ct on ct.UnitID = u.UnitID
		join Un_Oper o on ct.OperID = o.OperID
		left join Un_TIO tio on o.OperID = tio.iTINOperID
		left JOIN Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
		left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
	where 1=1
		and YEAR(o.OperDate) = @Year
		AND MONTH(o.OperDate) = @month
		and year(u.dtFirstDeposit) = year(o.OperDate) and month(u.dtFirstDeposit) = month(o.OperDate)		
		and m.BenefAgeOnBegining >= 6
		and oc1.OperSourceID is NULL
		and oc2.OperID is NULL
		and c.PlanID <> 4
		and o.OperTypeID in ('PRD','CHQ','CPA','NSF','RDI','TIN','COU')
		and tio.iTINOperID is null


END