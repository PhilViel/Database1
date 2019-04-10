/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_ObtenirConventionAdmissiblePaeParSouscripteur
Nom du service		: Obtenir la listes des conventions d'un souscripteur admissible à un PAE
But 				: Obtenir la listes des conventions d'un souscripteur admissible à un PAE
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
	
		EXEC psGENE_ObtenirConventionAdmissiblePaeParSouscripteur 150035
	
TODO:
	
Historique des modifications:
		Date			Programmeur			Description									Référence
		------------	------------------  -----------------------------------------	------------
		2016-08-05		Maxime Martel		Création du service		
        2016-09-19      Pierre-Luc Simard   Retrait des Scholarship puisque non utilisé pour les Individuel
		2016-10-11		Maxime Martel		Ajout du courriel bénéficiaire personnel
		2017-10-16		Guehel Bouanga		Renvoie toutes les conventions
        2017-10-18      Pierre-Luc Simard   Ajout de la fonction fntCONV_ObtenirConventionAdmissiblePAE      
        2017-10-30      Pierre-Luc Simard   Ajout du paramètres @bValider_StatutConvention à NULL à la fonction fntCONV_ObtenirConventionAdmissiblePAE 
        2017-12-08      Pierre-Luc Simard   La fonction fntCONV_ObtenirConventionAdmissiblePAE gère maintenant les Individuel et les autres critères donc ils ont été retirés
*******************************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirConventionAdmissiblePaeParSouscripteur]
	@iIdSouscripteur INT
AS
BEGIN
	SET NOCOUNT ON;

    SELECT
		iIDConvention = C.ConventionID,
		vcNoConvention = C.ConventionNo,
		fQteUnites = U.UnitQty,
		vcRegime = P.PlanDesc,
		vcRegimeEn = P.PlanDesc_ENU,
		PlanId = P.PlanId,
		BeneficiaireId = C.BeneficiaryID,
		vcBeneficiaire = HB.FirstName + ' ' + HB.LastName,
		vcSouscripteur = HS.FirstName + ' ' + HS.LastName,
		vcCourrielBeneficiaire = dbo.fnGENE_CourrielEnDate(HB.HumanID, 1, NULL, 0)
	FROM dbo.Un_Convention C
    JOIN dbo.fntCONV_ObtenirConventionAdmissiblePAE(NULL) CA ON CA.ConventionID = C.ConventionID 
	JOIN Un_Plan P ON C.PlanID = P.PlanID
	JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
	JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
	JOIN (
		SELECT 
            U.ConventionID,
            UnitQty = SUM(U.UnitQty)
		FROM dbo.Un_Unit U 
		GROUP BY U.ConventionID
		) U ON C.ConventionID = U.ConventionID
    WHERE C.SubscriberID = @iIdSouscripteur
        
END