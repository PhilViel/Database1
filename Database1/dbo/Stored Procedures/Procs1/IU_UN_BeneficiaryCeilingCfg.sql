
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_BeneficiaryCeilingCfg
Description         :	Supprime un enregistrement de configuration des plafonds des bénéficiaires
Valeurs de retours  :		>0 : Sauvegarde réussie (BeneficiaryCeilingCfgID de l'enregistrement sauvegardé)
							<=0 : Erreur SQL

Note                :	ADX0000472	IA	2005-02-04	Bruno Lapointe		Création
						ADX0001265	IA	2007-03-26	Alain Quirion		Modification. Changement du nom de la procédure
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_BeneficiaryCeilingCfg (
	@ConnectID INTEGER,					-- ID Unique de connexion de l'usager
	@BeneficiaryCeilingCfgID INTEGER,	-- ID unique de l'enregistrement de configuration à sauvegarder
	@EffectDate DATETIME,				-- Date d'Effectivité des plafonds
	@AnnualCeiling MONEY,				-- Planfond annuel
	@LifeCeiling MONEY )				-- Plafond à vie
AS
BEGIN
	DECLARE @iResult INTEGER
		
	SET @iResult = 1

	IF @BeneficiaryCeilingCfgID <= 0 -- Nouvel enregistrement
	BEGIN
		INSERT INTO Un_BeneficiaryCeilingCfg (
			EffectDate,
			AnnualCeiling,
			LifeCeiling )
		VALUES (
			@EffectDate,
			@AnnualCeiling,
			@LifeCeiling )

		IF @@ERROR <> 0
			SET @iResult = -1
		ELSE
		BEGIN
			SET @iResult = SCOPE_IDENTITY()
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_BeneficiaryCeilingCfg', @iResult, 'I', ''
		END			
	END
	ELSE
	BEGIN
		UPDATE Un_BeneficiaryCeilingCfg
		SET
			EffectDate     = @EffectDate,
			AnnualCeiling  = @AnnualCeiling,
			LifeCeiling    = @LifeCeiling
		WHERE BeneficiaryCeilingCfgID = @BeneficiaryCeilingCfgID

		IF @@ERROR <> 0
			SET @iResult = -2
		ELSE
		BEGIN
			SET @iResult = @BeneficiaryCeilingCfgID
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_BeneficiaryCeilingCfg', @BeneficiaryCeilingCfgID, 'U', ''
		END		
	END

	RETURN @iResult
END

