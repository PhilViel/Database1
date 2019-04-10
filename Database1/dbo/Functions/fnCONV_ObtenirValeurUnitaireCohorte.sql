/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnCONV_ObtenirValeurUnitaireCohorte
Nom du service		: Obtenir la valeur unitaire pour une cohorte
But						: Trouver la valeur unitaire pour le numéro du PAE demandé. 
							  (S'il aucune valeur n'est trouvée, on prend la dernière saisie.)		
Facette					: CONV

Paramètres d’entrée	:	Paramètre				Description
						--------------------------		-----------------------------------------------------------------
						iID_Plan								Identifiant du régime
						iAnnee_PAE						Année de la cohorte
						iNumero_PAE						Numéro du PAE (Bourse 1, 2 ou 3)
																
Exemple d’appel		:	SELECT [dbo].[fnCONV_ObtenirValeurUnitaireCohorte] (8, 2013, 2)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							@mValeur_Unitaire			Montant de la valeur unitaire trouvée 
																											
Historique des modifications:
		Date				Programmeur			Description								 
		------------		---------------------	-----------------------------------------
		2014-04-03	Pierre-Luc Simard	Création du service

*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_ObtenirValeurUnitaireCohorte]
(
	@iID_Plan INT,
	@iAnnee INT = NULL,
	@iNumero_PAE INT
)
RETURNS MONEY
AS
BEGIN

	DECLARE	
		@mValeur_Unitaire MONEY,
		@iAnneeMax INT
		
	SET @mValeur_Unitaire = 0
	
	SELECT @iAnneeMax = MAX(ScholarshipYear) FROM Un_PlanValues WHERE PlanID = @iID_Plan
	
	-- Si aucune année n'est demandée, on prend la dernière pour laquelle il existe une valeur
	IF ISNULL(@iAnnee,0) = 0 
		SET @iAnnee = @iAnneeMax
	
	-- Va chercher la valeur unitaire selon les critères, si celle-ci existe
	SELECT 
		@mValeur_Unitaire = PV.UnitValue
	FROM Un_PlanValues PV 
	WHERE PV.PlanID = @iID_Plan
		AND PV.ScholarshipYear = @iAnnee
		AND PV.ScholarshipNo = @iNumero_PAE
	
	-- Si une valeur n'est pas trouvée, on prend la dernière valeur saisie pour la même année
	IF @mValeur_Unitaire = 0
		SELECT TOP 1
			@mValeur_Unitaire = PV.UnitValue
		FROM Un_PlanValues PV
		WHERE PV.PlanID = @iID_Plan
			AND PV.ScholarshipYear = @iAnnee
			AND PV.ScholarshipNo <= @iNumero_PAE
		ORDER BY PV.ScholarshipNo DESC

	-- Si une valeur n'est pas trouvée, on prend la dernière valeur saisie
	IF @mValeur_Unitaire = 0
		SELECT TOP 1
			@mValeur_Unitaire = PV.UnitValue
		FROM Un_PlanValues PV
		WHERE PV.PlanID = @iID_Plan
			AND PV.ScholarshipYear = @iAnneeMax 
			AND PV.ScholarshipNo <= @iNumero_PAE
		ORDER BY PV.ScholarshipNo DESC
			
	RETURN @mValeur_Unitaire

END
