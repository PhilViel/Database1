/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service	: fntCONV_ObtenirDateFinRegime_PourTous
Nom du service		: Obtenir la date de fin de régime de toutes les convnetions
But 				: Obtenir la date de fin de régime des conventions ou calculer une date de fin de régime théorique.
Facette			: CONV

Paramètres d’entrée	:	
    Paramètre					Description
    --------------------------	-----------------------------------------------------------------
    iID_Convention				Identifiant unique de la convention pour laquelle le calcul de la date de fin de régime est requis.
    cType_Calcul				Le type de calcul correspond à l’un des choix suivants :
							    « R » - Date réel de fin de régime de la convention qui tient compte de la date d’ajustement de fin de régime
							    « T » - Date de fin de régime théorique qui ne tient pas compte de la date d’ajustement de fin de régime de la convention.
									  Avec cette option de calcul, la fin de régime selon la date servant de base au calcul théorique si elle est
									  présente, sinon le calcul théorique se fait à partir de la date de base du calcul réelle de la convention.

Exemple d’appel     :
    Avec calcul théorique   Select * From dbo.fntCONV_ObtenirDateFinRegime_PourTous (NULL, 'T', '1978-05-12')
    Avec date dans la BD    Select * From dbo.fntCONV_ObtenirDateFinRegime_PourTous (NULL, 'R', NULL)

Paramètres de sortie:	
    Table					  Champ				 Description
    ------------------------    --------------------    ---------------------------------------
    S/O			        	  ConventionID            Id de la convention
    S/O					  Date_Fin_Regime		 Si le service se réalise avec succès, c’est la date de fin de régime réelle ou calculée.

Historique des modifications:
    Date			Programmeur					 Description
    ----------      --------------------------------    -------------------------------------------------------
    2016-05-31		Steeve Picard					 Création du service, basé sur la function «dbo.fnCONV_ObtenirDateFinRegime»
***********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirDateFinRegime_PourTous]
(
	@iID_Convention	INT,
	@cType_Calcul CHAR
)
RETURNS @TB_Result TABLE (
	ConventionID int NOT NULL,
	Date_Fin_Regime DATETIME
) AS
BEGIN
	DECLARE @TB_Conv TABLE (
		ConventionID int NOT NULL,
		PlanID int NULL,
		dtDate_Fin_Regime DATETIME,
		dtDate_Debut_Regime DATETIME
	)

	-- Retourner la date d'ajustement de fin de régime s'il y en a une et que le type de calcul est réel
	INSERT INTO @TB_Conv (ConventionID, PlanID, dtDate_Fin_Regime)
	SELECT ConventionID, PlanID, 
			CASE @cType_Calcul WHEN 'R' THEN dtRegEndDateAdjust ELSE NULL END
  	  FROM dbo.Un_Convention 
	 WHERE ConventionID = @iID_Convention OR @iID_Convention IS NULL

	IF EXISTS( Select Top 1 * From @TB_Conv Where dtDate_Fin_Regime Is Null)
	BEGIN
		---- Trouver la date de base de calcul
		UPDATE TB
		   SET dtDate_Debut_Regime = dtFirst
		  FROM @TB_Conv TB
		       JOIN (
					SELECT U.ConventionID, dtFirst = MIN(CASE WHEN O.OperDate <= CO.EffectDate THEN O.OperDate ELSE CO.EffectDate END)
					  FROM dbo.Un_Unit U
						   JOIN @TB_Conv TB ON TB.ConventionID = U.ConventionID
						   JOIN Un_Cotisation CO ON CO.UnitID = U.UnitID
						   JOIN Un_Oper O ON O.OperID = CO.OperID AND O.OperTypeID = 'RCB'
						   LEFT JOIN Un_OperCancelation OC1 ON OC1.OperID = O.OperID
						   LEFT JOIN Un_OperCancelation OC2 ON OC2.OperSourceID = O.OperID
					 WHERE U.ConventionID = @iID_Convention
					   AND OC1.OperID IS NULL
					   AND OC2.OperID IS NULL
					 GROUP BY U.ConventionID
			   ) X ON X.ConventionID = TB.ConventionID
		 WHERE TB.dtDate_Fin_Regime IS NULL
		
		UPDATE TB
		   SET dtDate_Fin_Regime = Str(Year(dtDate_Debut_Regime) + P.PlanLifeTimeInYear, 4, 0) + '-12-31'
		  FROM @TB_Conv TB JOIN Un_Plan P ON P.PlanID = TB.PlanID
		 WHERE dtDate_Debut_Regime IS NOT NULL
	END

	INSERT INTO @TB_Result (ConventionID, Date_Fin_Regime)
	SELECT ConventionID, dtDate_Fin_Regime
	  FROM @TB_Conv
	 WHERE dtDate_Fin_Regime IS NOT NULL

	RETURN
END


