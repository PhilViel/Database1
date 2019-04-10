/****************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc.

Code du service        : psCONV_ListeFermerAyantSoldeEpargnePositive
Nom du service        : Liste des Conventions avec épargne positive
But                   : Retourner la liste des conventions ayant un solde d'épargne positif
Facette                : OPER

Paramètres d’entrée    :    
    Paramètre                    Description
    --------------------    ------------------------------------------------------------------------------------------
	@StartDate               Plus petite date d'entrée en vigueur retournée. Si omis, la date du 1er jour du mois sera utilisé
    @EndDate                 Plus grande date d'entrée en vigueur retournée. Si omis, la date du jour sera utilisé

Exemple d’appel     :   EXEC dbo.psCONV_ListeFermerAyantSoldeEpargnePositive '2015-10-22', '2015-11-10'

Historique des modifications:
    Date            Programmeur                Description                                                    Référence
    ----------      --------------------    ---------------------------------------------------------   --------------
    2016-02-29      Dominique Pothier			Création
	2016-03-15		Dominique Pothier			Ajout de deux colonnes: etat premier groupe unité et raison fermeture
**********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ListeFermerAyantSoldeEpargnePositive] (
	@StartDate     DATE = NULL, 
    @EndDate       DATE = NULL
) AS
BEGIN
	IF @EndDate IS NULL
       SET @EndDate = GetDate()

    IF @StartDate IS NULL
        SET @StartDate =  '0001-01-01'

	Select Unit.ConventionId, Unit.UnitID, Unit.InForceDate, EtatCourant.UnitStateName, Unit.Row
	into #PremierGroupeUnite
	From ( Select ConventionID, UnitID, InForceDate,
			  Row = Row_Number() OVER(PARTITION BY conventionID ORDER BY InForceDate asc, unitID) 
			  From Un_unit Unit
			  ) Unit
		join (Select UnitState.UnitId, UnitState.UnitStateID, States.UnitStateName
			  From Un_UnitUnitState UnitState
				  join (Select UnitState.UnitID, Max(UnitState.StartDate) as StartDate
						From Un_UnitUnitState UnitState
						group by UnitState.UnitID) EtatCourant on EtatCourant.UnitID = UnitState.UnitID
				  join Un_UnitState States on UnitState.UnitStateID = States.UnitStateID
			 Where UnitState.StartDate = EtatCourant.StartDate
			 ) EtatCourant on EtatCourant.UnitID = Unit.UnitID
	Where Unit.Row = 1

	;With CTE_Conv as (
		SELECT Conv.ConventionID, Conv.ConventionNo, ConvState.ConventionStateID, SubscriberID, BeneficiaryID, RaisonsFermeture.vcRaison_Fermeture
		  FROM Un_Convention Conv
			   join dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(GETDATE(), null) ConvState on Conv.ConventionID = ConvState.ConventionID
			   left join tblCONV_RaisonFermeture RaisonsFermeture on RaisonsFermeture.iID_Raison_Fermeture = Conv.iID_Raison_Fermeture
		 where ConvState.ConventionStateID = 'FRM'
		   and Conv.dtEntreeEnVigueur Between @StartDate And @EndDate
	)
	,CTE_DateFRM as(
		SELECT Conv.ConventionID, Max(Oper.OperDate) as dateFermeture
		  FROM CTE_Conv Conv
		       join Un_Unit Unit on Unit.ConventionID = Conv.ConventionID
		       join Un_Cotisation Cotisation on Unit.UnitID = Cotisation.UnitID
		       join Un_Oper Oper on Cotisation.OperID = Oper.OperID
		       left join Un_OperCancelation OperAnnulee on OperAnnulee.OperSourceID = Oper.OperID
		       left join Un_OperCancelation OperAnnulation on OperAnnulation.OperID = Oper.OperID
		 where OperAnnulee.OperSourceID is null AND
			   OperAnnulee.OperID is null AND
			   Oper.OperTypeID = 'FRM'
		 group by Conv.ConventionID
	)
	,CTE_SoldeEpargne as(
		Select Conv.ConventionID,
			   SoldeEpargne =  Sum(Cotisation.Cotisation)
		  From CTE_Conv Conv
			   join Un_Unit Unit on Unit.ConventionID = Conv.ConventionID
			   join Un_Cotisation Cotisation on Cotisation.UnitID = Unit.UnitID
		 group by Conv.ConventionID
	)
	Select Conv.ConventionNo,
	       IdSouscripteur = Souscripteur.HumanID,
		   PrenomSouscripteur = Souscripteur.FirstName,
		   NomSouscripteur = Souscripteur.LastName,
		   IdBeneficiaire = Beneficiaire.HumanID,
		   PrenomBeneficiaire = Beneficiaire.FirstName,
		   NomBeneficiaire = Beneficiaire.LastName,
		   etat.ConventionStateName as EtatConvention,
		   PremierGU.UnitStateName as EtatPremierGU,
		   dateFRM = Fermeture.dateFermeture,
		   SoldeEpargne,
		   Conv.vcRaison_Fermeture
	  From CTE_SoldeEpargne soldes
		   join CTE_Conv Conv on soldes.ConventionID = Conv.ConventionID
		   join CTE_DateFRM Fermeture on Fermeture.ConventionID = Conv.ConventionID
		   join Mo_Human Souscripteur on Conv.SubscriberID = Souscripteur.HumanID
		   join Mo_Human Beneficiaire on Conv.BeneficiaryID = Beneficiaire.HumanID
		   join #PremierGroupeUnite PremierGU on PremierGU.ConventionID = Conv.ConventionID
		   join Un_ConventionState etat ON etat.ConventionStateID = Conv.ConventionStateID
	 WHERE SoldeEpargne > 0
	 ORDER BY Conv.ConventionNo

	 DROP Table #PremierGroupeUnite
END
