/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnCONV_ObtenirRistourneAssurance
Nom du service		: Obtenir la ristourne pour les PAE
But 						: Obtenir la ristourne pour les PAE.
Facette					: CONV

Paramètres d’entrée	:	Paramètre				Description
						--------------------------		-----------------------------------------------------------------
						iID_Plan								Identifiant du régime
						dtModalite							Date de la modalité des groupes d'unités
						iAnnee_QualifPremierPAE	Année de qualification au premier PAE 

Exemple d’appel		:	SELECT [dbo].[fnCONV_ObtenirRistourneAssurance] (79028, 2013, 0)
								SELECT [dbo].[fnCONV_ObtenirRistourneAssurance] (79028, 2014, 1)
								SELECT [dbo].[fnCONV_ObtenirRistourneAssurance] (71723, 2014, 0)
								SELECT [dbo].[fnCONV_ObtenirRistourneAssurance] (71723, 2014, 1)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							dFacteurConv				Facteur de conversion 
																											
Historique des modifications:
		Date				Programmeur			Description								 
		------------		---------------------	-----------------------------------------
		2013-12-19	Pierre-Luc Simard	Création du service
		2014-07-23	Pierre-Luc Simard	Ajout des paramètres @bWantSubscriberInsurance et @iID_Modal
        2017-12-05  Pierre-Luc Simard   Ajout des validation sur les dates de signature et de début des opérations
                                        Retrait de la validation sur l'année du premier PAE

*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_ObtenirRistourneAssurance]
(
	@iID_Modal INT,
	--@iAnnee_QualifPremierPAE INT,
	@bWantSubscriberInsurance BIT,	-- Le souscripteur voulait l'assurance pour cet unité
    @dtSignature DATE,
    @dtDebutOperation DATE
)
RETURNS MONEY
AS
BEGIN

	DECLARE	
		@mRistourneAss MONEY,
		@iID_Plan INT,
		@dtModalite DATE,
		@SubscriberInsuranceRate MONEY		
	
	SELECT 
		@iID_Plan = M.PlanID,
		@dtModalite = M.ModalDate,
		@SubscriberInsuranceRate = M.SubscriberInsuranceRate -- Montant d'assurance à payer selon la modalité, si le souscripteur en voulait
	FROM Un_Modal M
	WHERE M.ModalID = @iID_Modal	

	/*	bValiderAssSousc = 1: On doit vérifier si le souscripteur désirait l'assurance pour cet unité et si sa modalité contenait un montant, sinon il n'aura pas la ristourne
		bValiderAssSousc = 0: On doit payer la ristourne s'il y en a une sans valider si le souscripteur désirait l'assurance et si sa modalité en contenait */
	SELECT 
		@mRistourneAss = CASE WHEN ISNULL(RA.bValiderAssSousc,0) = 0 
										THEN RA.mRistourneAss
										ELSE 
											CASE WHEN (ISNULL(@bWantSubscriberInsurance,0) <> 0 AND ISNULL(@SubscriberInsuranceRate,0) <> 0) 
												THEN RA.mRistourneAss
												ELSE 0
											END
									END
	FROM tblCONV_RistournesAssurance RA
	WHERE RA.iID_Plan = @iID_Plan
		AND RA.dtDate_DebutModalite <= @dtModalite
		AND ISNULL(RA.dtDate_FinModalite, @dtModalite) >= @dtModalite
		--AND RA.iAnnee_DebutQualif <= @iAnnee_QualifPremierPAE
		--AND ISNULL(RA.iAnnee_FinQualif, @iAnnee_QualifPremierPAE) >= @iAnnee_QualifPremierPAE
        AND (DATEADD(DAY, ISNULL(RA.iNb_JourSupplementaire, 0), ISNULL(RA.dtDate_FinModalite, @dtSignature)) >= @dtSignature
            OR DATEADD(DAY, ISNULL(RA.iNb_JourSupplementaire, 0), ISNULL(RA.dtDate_FinModalite, @dtDebutOperation)) >= @dtDebutOperation)
	
	IF @mRistourneAss IS NULL
		SET @mRistourneAss = 0

	RETURN @mRistourneAss

END