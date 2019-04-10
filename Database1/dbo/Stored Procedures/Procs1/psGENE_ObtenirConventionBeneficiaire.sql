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

Code du service		: psGENE_ObtenirConventionBeneficiaire
Nom du service		: Obtenir la listes des conventions d'un bénéficiaire
But 				: Obtenir la listes des conventions d'un bénéficiaire
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@iBeneficiaryId				Identifiant du bénéficiaire
							
Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
													iIDConvention
													vcNoConvention
													vcSouscripteur
													fQteUnite
		
Exemple utilisation:																					
	- Obtenir la liste des convention d'un bénéficiaire
		EXEC psGENE_ObtenirConventionBeneficiaire 225901
	
TODO:
	
Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-04-21		Donald Huppé						Création du service		
		2011-09-13		Donald Huppé						Calculer la date de fin de régime avec la fonction fnCONV_ObtenirDateFinRegime		
		2012-04-16		Donald Huppé						Ajout de 'WAI'		
		2014-04-23		Donald Huppé						Au lieu de chercher ceci : ScholarshipStatusID IN ('RES','ADM','WAI')
															On cherche les convention REEE dont la 3ième bourse n'est pas encore payé et dont l'année de qualif est en cours ou passée.
		2016-01-20		Pierre-Luc Simard				    On remet la liste à partir des scholarship (JIRA PROD-362) mais on valide également l'année de qualification.
		2016-08-09		Maxime Martel						Ajout du nom du beneficiaire
        2017-09-27      Pierre-Luc Simard                   Deprecated - Cette procédure n'est plus utilisée
                                                            Remplacé par la psGENE_ObtenirConventionPaeParSouscripteur

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirConventionBeneficiaire]
	@iIDBeneficiaire INT
AS
BEGIN
    SELECT 1/0
/*
	SET NOCOUNT ON;

	SELECT DISTINCT
		iIDConvention = c.ConventionID,
		vcNoConvention = c.ConventionNo,
		vcSouscripteur = HS.FirstName + ' ' + HS.LastName,
		vcBeneficiaire = HB.FirstName + ' ' + HB.LastName,
		fQteUnites = UnitQty,
		vcRegime = p.PlanDesc,
		dtFinRegime = LEFT(CONVERT(VARCHAR, [dbo].[fnCONV_ObtenirDateFinRegime] (c.ConventionID, 'R', NULL), 120), 10)
	FROM Un_convention c
	JOIN Un_Scholarship ss ON c.ConventionID = ss.ConventionID
	JOIN Un_Plan p ON c.PlanID = p.PlanID
	JOIN dbo.Mo_Human HS ON c.SubscriberID = HS.HumanID
	JOIN dbo.Mo_Human HB ON c.BeneficiaryID = HB.HumanID
	JOIN (
		SELECT ConventionID,UnitQty =sum(unitqty) , maxSignatureDate = LEFT(CONVERT(VARCHAR, max(SignatureDate), 120), 10)
		FROM dbo.Un_Unit 
		GROUP BY ConventionID
		) U ON c.ConventionID = U.ConventionID
	join (
		select 
			Cs.conventionid ,
			ccs.startdate,
			cs.ConventionStateID
		from 	un_conventionconventionstate cs
		join (
			select 
			conventionid,
			startdate = max(startDate)
			from un_conventionconventionstate
			--where startDate < DATEADD(d,1 ,'2013-12-31')
			group by conventionid
			) ccs on ccs.conventionid = cs.conventionid AND ccs.startdate = cs.startdate 
		) css on C.conventionid = css.conventionid	
	JOIN ( -- pour avoir maxSignatureDate
		SELECT 
			c.BeneficiaryID,
			maxSignatureDate = max(maxSignatureDate)
		FROM 
			Un_convention c
			JOIN Un_Scholarship ss ON c.ConventionID = ss.ConventionID
			JOIN Un_Plan p ON c.PlanID = p.PlanID
			JOIN (
				SELECT ConventionID,UnitQty =sum(unitqty) , maxSignatureDate = LEFT(CONVERT(VARCHAR, max(SignatureDate), 120), 10)
				FROM dbo.Un_Unit 
				GROUP BY ConventionID
				) U ON c.ConventionID = U.ConventionID
		WHERE C.BeneficiaryID = @iIDBeneficiaire
			AND ss.ScholarshipStatusID IN ('RES','ADM','WAI')
			AND p.PlanTypeID = 'COL'
		GROUP BY 
			c.BeneficiaryID
		) S ON c.BeneficiaryID = S.BeneficiaryID
	WHERE c.BeneficiaryID = @iIDBeneficiaire
		AND ss.ScholarshipStatusID IN ('RES','ADM','WAI')
		AND p.PlanTypeID = 'COL'
		AND css.ConventionStateID = 'REE' -- je veux les convention qui ont cet état
		AND C.YearQualif <= YEAR(GETDATE()) 
*/
END