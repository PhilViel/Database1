/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 				:	IU_UN_ConvRegEndDateAdjust
Description 		:	Édite l’ajustement de la date de fin de régime du groupe d’unités
Valeurs de retour	:	@ReturnValue :
								>0 : [Réussite]
								<= 0			: [Échec].

Note			:		ADX0001355	IA	2007-06-05	Alain Quirion		Création
										2008-11-24	Josée Parent		Modification pour utiliser la
																		fonction "fnCONV_ObtenirDateFinRegime"
*************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_ConvRegEndDateAdjust] (	
	@ConventionID INTEGER, -- ID Unique de la convention
	@dtRegEndDateAdjust DATETIME) -- Ajustement en mois à la date de vigueur
AS
BEGIN
	DECLARE @iResult INTEGER,
			@dtRegEndDateOrig DATETIME	

	SET @iResult = 1

	SET @dtRegEndDateOrig = (SELECT [dbo].[fnCONV_ObtenirDateFinRegime](@ConventionID,'T',NULL))

	IF @dtRegEndDateAdjust = @dtRegEndDateOrig
		SET @dtRegEndDateAdjust = NULL
	
	UPDATE dbo.Un_Convention 
	SET dtRegEndDateAdjust = @dtRegEndDateAdjust
	WHERE ConventionID = @ConventionID

	IF @@ERROR <> 0
		SET @iResult = -1

	RETURN @iResult
END


