/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnCONV_ObtenirDateFinRegime
Nom du service		: Obtenir la date de fin de régime 
But 				: Obtenir la date de fin de régime d’une convention ou calculer une date de fin de régime théorique.
Facette				: CONV
Référence			: Noyau-CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Convention				Identifiant unique de la convention pour laquelle le calcul de la
													date de fin de régime est requis.
						cType_Calcul				Le type de calcul correspond à l’un des choix suivants :
														« R » - Date réel de fin de régime de la convention qui tient
																compte de la date d’ajustement de fin de régime
														« T » - Date de fin de régime théorique qui ne tient pas compte
																de la date d’ajustement de fin de régime de la convention.
																Avec cette option de calcul, la fin de régime selon la
																date servant de base au calcul théorique si elle est
																présente, sinon le calcul théorique se fait à partir de
																la date de base du calcul réelle de la convention.

						dtDate_Base_Calcul			Date servant de base au calcul théorique d’une date de fin de régime.

Exemple d’appel		:	Avec calcul théorique
						exec [dbo].[fnCONV_ObtenirDateFinRegime] 300000, 'T', '1978-05-12'
						Avec date dans la BD
						exec [dbo].[fnCONV_ObtenirDateFinRegime] 300000, 'R', NULL

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							dtDate_Fin_Regime				Si le service se réalise avec succès,
																					c’est la date de fin de régime réelle
																					ou calculée.
						S/O							iCode_Retour					Code de retour en cas d’erreur.
																						-1 – Un paramètre est absent ou
																							 n’existe pas.
																						-2 – Toute autre erreur.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-11-21		Josée Parent						Création du service
		2012-01-27		Éric Deshaies						Utiliser la nouvelle date de début de régime
															pour déterminer la date de fin de régime.

*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_ObtenirDateFinRegime]
(
	@iID_Convention	INT,
	@cType_Calcul CHAR,
	@dtDate_Base_Calcul DATETIME
)
RETURNS DATETIME
AS
BEGIN
	-- Valider les paramètres
	IF @iID_Convention IS NULL OR
	   NOT EXISTS(SELECT *
				  FROM dbo.Un_Convention 
				  WHERE ConventionID = @iID_Convention) OR
	   @cType_Calcul IS NULL OR
	  (@cType_Calcul <> 'R' AND @cType_Calcul <> 'T')
		RETURN -1
	
	DECLARE @dtDate_Fin_Regime DATETIME

	-- Retourner la date d'ajustement de fin de régime s'il y en a une et que le type de calcul est réel
	IF @cType_Calcul = 'R'
		BEGIN
			SELECT @dtDate_Fin_Regime = dtRegEndDateAdjust
			FROM dbo.Un_Convention 
			WHERE ConventionID = @iID_Convention

			IF @dtDate_Fin_Regime IS NOT NULL
				RETURN @dtDate_Fin_Regime
		END

	-- Trouver la date de base de calcul
	IF @cType_Calcul = 'R' OR
	  (@cType_Calcul = 'T' AND @dtDate_Base_Calcul IS NULL)
		SET @dtDate_Base_Calcul = [dbo].[fnCONV_ObtenirDateDebutRegime](@iID_Convention, NULL)

	DECLARE @iDuree_Regime INT,
			@iAnnee_Fin_Regime INT

	-- Déterminer la durée de la convention selon le régime
	SELECT @iDuree_Regime = PlanLifeTimeInYear
	FROM Un_Plan P
		 JOIN dbo.Un_Convention C ON C.PlanID = P.PlanID
	WHERE C.ConventionID = @iID_Convention

	-- Calculer la date de fin de régime selon la date de base de calcul
	SET @iAnnee_Fin_Regime = DATEPART(yyyy,@dtDate_Base_Calcul) + @iDuree_Regime
	SET @dtDate_Fin_Regime = CAST(@iAnnee_Fin_Regime AS VARCHAR(4)) + '-12-31'

	-- Retourner la date de fin de régime
	RETURN @dtDate_Fin_Regime
END


