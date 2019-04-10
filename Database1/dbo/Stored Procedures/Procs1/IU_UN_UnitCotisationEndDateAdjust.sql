/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 				:	IU_UN_UnitCotisationEndDateAdjust
Description 		:	Édite l’ajustement de la date de fin de cotisation du groupe d’unités
Valeurs de retour	:	@ReturnValue :
								>0 : [Réussite]
								<= 0			: [Échec].

Note			:		ADX0001355	IA	2007-06-06	Alain Quirion		Création
*************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_UnitCotisationEndDateAdjust] (	
	@UnitID INTEGER, -- ID Unique du groupe d'unités
	@dtCotisationEndDateAdjust DATETIME) -- Ajustement en mois à la date de vigueur
AS
BEGIN
	DECLARE @iResult INTEGER,
			@dtCotisationEndDateOrig DATETIME,
			@MaxConvDepositDateCfg INT,
			@InforceDate DATETIME

	SET @iResult = 1

	SELECT @InforceDate = InforceDate
	FROM dbo.Un_Unit 
	WHERE UnitID = @UnitID

	SELECT TOP 1 @MaxConvDepositDateCfg = YearQty
	FROM Un_MaxConvDepositDateCfg
	WHERE EffectDate <= @InforceDate
	ORDER BY EffectDate DESC

	SELECT @dtCotisationEndDateOrig = DATEADD(YEAR, @MaxConvDepositDateCfg, 
										CASE
											WHEN MIN(U.InforceDate) < ISNULL(U.dtInforceDateTIN,MIN(U.InforceDate)+1) THEN MIN(U.InforceDate)
											ELSE U.dtInforceDateTIN
										END)
	FROM dbo.Un_Unit U
	WHERE U.UnitID = @UnitID
	GROUP BY U.dtInforceDateTIN

	IF @dtCotisationEndDateAdjust = @dtCotisationEndDateOrig
		SET @dtCotisationEndDateAdjust = NULL
	
	UPDATE dbo.Un_Unit 
	SET dtCotisationEndDateAdjust = @dtCotisationEndDateAdjust
	WHERE UnitID = @UnitID

	IF @@ERROR <> 0
		SET @iResult = -1

	RETURN @iResult
END


