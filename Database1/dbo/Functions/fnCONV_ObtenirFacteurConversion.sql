/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnCONV_ObtenirFacteurConversion
Nom du service		: Obtenir le facteur de conversion des unités pour les PAE
But 						: Obtenir le facteur de conversion des unités pour les PAE.
Facette					: CONV

Paramètres d’entrée	:	Paramètre				Description
						--------------------------		-----------------------------------------------------------------
						iID_Plan								Identifiant du régime
						dtModalite							Date de la modalité des groupes d'unités
						iAnnee_QualifPremierPAE	Année de qualification au premier PAE 
																(Un_Convention.iAnnee_DebutQualifPremierPAE, sinon Un_Beneficiray.iAnnee_AdmissiblePAE)

Exemple d’appel		:	SELECT [dbo].[fnCONV_ObtenirFacteurConversion] (10, '2009-12-07', 2020)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							dFacteurConv				Facteur de conversion 
																											
Historique des modifications:
		Date		    Programmeur			    Description								 
		------------	---------------------	-----------------------------------------
		2013-12-19	    Pierre-Luc Simard	    Création du service
        2017-12-05      Pierre-Luc Simard       Ajout des validation sur les dates de signature et de début des opérations
                                                Retrait de la validation sur l'année du premier PAE

*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_ObtenirFacteurConversion]
(
	@iID_Plan INT,
	@dtModalite DATE,
	--@iAnnee_QualifPremierPAE INT,
    @dtSignature DATE,
    @dtDebutOperation DATE
)
RETURNS DECIMAL (5,2)
AS
BEGIN

	DECLARE	
		@dFacteurConv DECIMAL (5,2)

	SELECT 
		@dFacteurConv = FC.dFacteurConv
	FROM tblCONV_FacteurConversion FC
	WHERE FC.iID_Plan = @iID_Plan
		AND FC.dtDate_DebutModalite <= @dtModalite
		AND ISNULL(FC.dtDate_FinModalite, @dtModalite) >= @dtModalite
		--AND FC.iAnnee_DebutQualif <= @iAnnee_QualifPremierPAE
		--AND ISNULL(FC.iAnnee_FinQualif, @iAnnee_QualifPremierPAE) >= @iAnnee_QualifPremierPAE
        -- La date de signature ou la date de début d'opération doit être inférieur à la date de fin de modalité plus le nombre 
        -- de jour alloué pour la période de grâce
        AND (DATEADD(DAY, ISNULL(FC.iNb_JourSupplementaire, 0), ISNULL(FC.dtDate_FinModalite, @dtSignature)) >= @dtSignature
            OR DATEADD(DAY, ISNULL(FC.iNb_JourSupplementaire, 0), ISNULL(FC.dtDate_FinModalite, @dtDebutOperation)) >= @dtDebutOperation)
        	
	IF ISNULL(@dFacteurConv,0) = 0 
		SET @dFacteurConv = 1

	RETURN @dFacteurConv

END