/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom			: IU_UN_RepLevelBracket
Description		: Procédure d’insertion ou de mise à jour d’une configuration de tombée.
Valeurs de retours	: 
			@ReturnValue :
					> 0 : [Réussite], ID de la configuration de tombée
					<= 0 : [Échec].

Note			: ADX0000994	IA	2006-05-25	Alain Quirion			Création
                                    2018-06-07  Pierre-Luc Simard       Ne peux plus être utilisé suite à l'ajout du champ PlanID
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_RepLevelBracket] (
@RepLevelBracketID INTEGER,		--Identifiant unique de la configuration
@RepLevelID INTEGER,			--Identifiant unique du niveau de représentant auquel s’applique la configuration
@EffectDate DATETIME,			--Date d’entrée en vigueur de la configuration
@TerminationDate DATETIME,		--Date de fin de vigueur de la configuration
@TargetFeeByUnit MONEY,			--Nombre de frais par unité à atteindre pour être éligible à cette tombée
@AdvanceByUnit MONEY,			--Valeur par unité de la tombée
@RepLevelBracketTypeID CHAR(3)) 	--Chaîne de 3 caractères identifiant de quel type de tombée il s’agit ('COM'=Commission de service, 'ADV'=Avances, 'CAD'=Avances couvertes).
AS
BEGIN

    SELECT 1/0
    /*
	IF @RepLevelBracketID = 0
	BEGIN
		INSERT INTO Un_RepLevelBracket (
			RepLevelID,
			TargetFeeByUnit,
			AdvanceByUnit,
			EffectDate,
			TerminationDate,
			RepLevelBracketTypeID)
		VALUES (
			@RepLevelID,
			@TargetFeeByUnit,
			@AdvanceByUnit,
			@EffectDate,
			@TerminationDate,
			@RepLevelBracketTypeID)
	
		IF @@ERROR = 0
			SET @RepLevelBracketID = SCOPE_IDENTITY()      
		ELSE
			SET @RepLevelBracketID = -1
	END
	ELSE
	BEGIN
		UPDATE Un_RepLevelBracket 
		SET
			RepLevelID = @RepLevelID,
			TargetFeeByUnit = @TargetFeeByUnit,
			AdvanceByUnit = @AdvanceByUnit,
			EffectDate = @EffectDate,
			TerminationDate = @TerminationDate,
			RepLevelBracketTypeID = @RepLevelBracketTypeID
		WHERE RepLevelBracketID = @RepLevelBracketID

		IF @@ERROR <> 0
			SET @RepLevelBracketID = -1
	END		

	RETURN @RepLevelBracketID
    */
END



