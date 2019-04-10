/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_AutomaticDeposit_IU
Description         :	Valide si la cotisation de l’horaire de prélèvement respecte la cotisation minimale permise.
Valeurs de retours  :	
	DateSet :
		vcErrorCode	VARCHAR(3)		Code de l’erreur
		vcErrorText	VARCHAR(200)	Texte de l’erreur	

						Code d’erreur	Texte de l’erreur
						AD1				La cotisation est inférieure à la cotisation minimale permise 

Note                :	
	ADX0001275	IA	2006-03-27	Alain Quirion		Création
	ADX0001254	UP	2007-10-03	Bruno Lapointe		Faire la validation seulement pour les conventions individuelles
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_AutomaticDeposit_IU] (
	@UnitID INTEGER,
	@CotisationFee MONEY)
AS
BEGIN
	DECLARE @tError TABLE (
		vcErrorCode VARCHAR(3),
		vcErrorText VARCHAR(200))

	IF EXISTS ( -- Fait la validation seulement s'il s'agit d'un groupe d'unités d'un plan individuel.
		SELECT *
		FROM dbo.Un_Unit U
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID
		WHERE U.UnitID = @UnitID
			AND P.PlanTypeID = 'IND'
		)
	BEGIN
		DECLARE 
			@InforceDate DATETIME,
			@MinIndAutDepositCfgID INTEGER

		-- Va chercher la date d'entrée en vigueur de la convention
		SELECT @InforceDate = MIN(U2.InforceDate)
		FROM dbo.Un_Unit U1
		JOIN dbo.Un_Unit U2 ON U1.ConventionID = U2.ConventionID
		WHERE U1.UnitID = @UnitID

		-- Va chercher la configuration "Cotisation minimale pour les prélèvements 
		-- automatiques des individuelles" qui s'applique à cette convention.
		SELECT TOP 1 @MinIndAutDepositCfgID = MinIndAutDepositCfgID
		FROM Un_MinIndAutDepositCfg
		WHERE EffectDate <= @InforceDate
		ORDER BY EffectDate DESC

		 IF EXISTS ( -- Valide que le minimum est respecté.	
				SELECT *
				FROM Un_MinIndAutDepositCfg
				WHERE MinAmount > @CotisationFee
					AND EffectDate <= @InforceDate
					AND MinIndAutDepositCfgID = @MinIndAutDepositCfgID
				)
			-- Message d'erreur ou d'attention si le minimum n'est pas respecté.
			INSERT INTO @tError(vcErrorCode, vcErrorText)
			VALUES('AD1', 'La cotisation est inférieure à la cotisation minimale permise')
	END

	-- Retourne l'erreur.
	SELECT *
	FROM @tError				
END


