/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************    */

/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_ObtenirConventionPaeIndividuelParSouscripteur
Nom du service		: Obtenir la listes des conventions individuel d'un souscripteur admissible à un PAE
But 				: Obtenir la listes des conventions individuel d'un souscripteur admissible à un PAE
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@iIdSouscripteur			Identifiant du souscripteur
							
Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
													iIDConvention
													vcNoConvention
													fQteUnites
													vcRegime
													planId
													beneficiaireId
													vcBeneficiaire
		
Exemple utilisation:																					
	
		EXEC psGENE_ObtenirConventionPaeIndividuelParSouscripteur 150035
	
TODO:
	
Historique des modifications:
		Date			Programmeur			Description									Référence
		------------	------------------  -----------------------------------------	------------
		2016-08-05		Maxime Martel		Création du service		
        2016-09-19      Pierre-Luc Simard   Retrait des Scholarship puisque non utilisé pour les Individuel
		2016-10-11		Maxime Martel		Ajout du courriel bénéficiaire personnel
        2017-09-27      Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée
                                            Remplacée par la psGENE_ObtenirConventionPaeParSouscripteur

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirConventionPaeIndividuelParSouscripteur]
	@iIdSouscripteur INT
AS
BEGIN
    SELECT 1/0
    /*
	SET NOCOUNT ON;

    SELECT
		iIDConvention = C.ConventionID,
		vcNoConvention = C.ConventionNo,
		fQteUnites = U.UnitQty,
		vcRegime = P.PlanDesc,
		PlanId = P.PlanId,
		BeneficiaireId = C.BeneficiaryID,
		vcBeneficiaire = HB.FirstName + ' ' + HB.LastName,
		vcSouscripteur = HS.FirstName + ' ' + HS.LastName,
		vcCourrielBeneficiaire = dbo.fnGENE_CourrielEnDate (HB.HumanID, 1, NULL, 0)
	FROM dbo.Un_Convention C
	JOIN Un_Plan P ON C.PlanID = P.PlanID
	JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
	JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
    JOIN fntCONV_ObtenirStatutConventionEnDate_PourTous(NULL, NULL) CS ON CS.ConventionID = C.ConventionID
	JOIN (
		SELECT 
            U.ConventionID,
            UnitQty = SUM(U.UnitQty)
		FROM dbo.Un_Unit U 
		GROUP BY U.ConventionID
		) U ON C.ConventionID = U.ConventionID
	WHERE C.SubscriberID = @iIdSouscripteur
		AND P.PlanTypeID = 'IND'
		AND CS.ConventionStateID = 'REE'
    */		 		
END