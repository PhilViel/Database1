/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnCONV_ObtenirValeurUnitaireCohorte
Nom du service		: Obtenir la valeur unitaire pour une cohorte
But						: Trouver la valeur unitaire pour le numéro du PAE demandé. 
							  (S'il aucune valeur n'est trouvée, on prend la dernière saisie.)		
Facette					: CONV

Paramètres d’entrée	:	Paramètre				Description
						--------------------------		-----------------------------------------------------------------
						@iID_Plan						Identifiant du régime
						@iAnnee							Année de qualification : càd l'année du 1er PAE, si avant 1er juillet
						@iNumero_PAE					Numéro du PAE (Bourse 1, 2 ou 3)
																
Exemple d’appel		:	SELECT [dbo].[fnCONV_ObtenirValeurUnitaireCohorte] (8, 2013, 2)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							@mValeur_Unitaire			Montant de la valeur unitaire trouvée 
																											
Historique des modifications:
		Date				Programmeur				Description								 
		------------		---------------------	-----------------------------------------
		2015-10-06			Pierre-Luc Simard		Création du service pour le relevé

*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_ObtenirValeurUnitaireCohorteExiste]
(
	@iID_Plan INT,
	@iAnnee INT = NULL,
	@iNumero_PAE INT
)
RETURNS BIT
AS
BEGIN

	DECLARE	
		@bExiste BIT,
		@iAnneeMax INT

	SET @bExiste = 0
	
	SELECT @iAnneeMax = MAX(ScholarshipYear) FROM Un_PlanValues WHERE PlanID = @iID_Plan
	
	-- Si aucune année n'est demandée, on prend la dernière pour laquelle il existe une valeur
	IF ISNULL(@iAnnee,0) = 0 
		SET @iAnnee = @iAnneeMax
	
	-- Vérifie si une valeur existe pour cette cohorte
	SELECT 
		@bExiste = 1
	FROM Un_PlanValues PV 
	WHERE PV.PlanID = @iID_Plan
		AND PV.ScholarshipYear = @iAnnee
		AND PV.ScholarshipNo = @iNumero_PAE
	
	RETURN @bExiste

END
