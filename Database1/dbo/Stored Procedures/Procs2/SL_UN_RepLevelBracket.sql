/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_RepLevelBracket
Description         :	Procédure de sélection des configurations de tombées de commissions par niveau
Valeurs de retours  :	Dataset :
					RepLevelBracketID	INTEGER		Identifiant unique de la configuration
					RepLevelID		INTEGER		Identifiant unique du niveau de représentant auquel s’applique la configuration
					EffectDate		DATETIME	Date d’entrée en vigueur de la configuration
					TerminationDate		DATETIME	Date de fin de vigueur de la configuration
					TargetFeeByUnit		Monétaire	Nombre de frais par unité à atteindre pour être éligible à cette tombée
					AdvanceByUnit		Monétaire	Valeur par unité de la tombée
					RepLevelBracketTypeID   CHAR(3)		Chaîne de 3 caractères identifiant de quel type de tombée il s’agit ('COM'=Commission de service, 'ADV'=Avances, 'CAD'=Avances couvertes).

			@ReturnValue :
					> 0 : [Réussite]
					<= 0 : [Échec].

Note                :	ADX0000994	IA	2006-05-25	Alain Quirion		Création								
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepLevelBracket] (
@RepLevelBracketID INTEGER,		--Identifiant unique de la configuration ( 0 = TOUS )
@RepLevelID INTEGER)			--Identifiant unique du niveau de représentant auquel s’applique la configuration ( 0 = TOUS sauf si @RepLevelBracket != 0 )
AS
BEGIN
	DECLARE 
		@iReturn INTEGER,
		@dtMaxDate DATETIME	--Date maximale nécessaire pour le tri déseendant avec les NULL au début

	SET @iRETURN = 1		--Aucune erreur par défaut

	-- Recherche la date maximale de fin de configuration de tombée
	SELECT @dtMaxDate = MAX(TerminationDate)
	FROM Un_RepLevelBracket
	WHERE (@RepLevelBracketID = 0
		OR @RepLevelBracketID = RepLevelBracketID)
		AND (@RepLevelID = 0
		OR @RepLevelID = RepLevelID)

	SELECT 
		RepLevelBracketID,
		RepLevelID,		
		EffectDate,		
		TerminationDate,
		TargetFeeByUnit,
		AdvanceByUnit,
		RepLevelBracketTypeID
	FROM Un_RepLevelBracket 
	WHERE (@RepLevelBracketID = 0
		OR @RepLevelBracketID = RepLevelBracketID)
		AND (@RepLevelID = 0
		OR @RepLevelID = RepLevelID)
	ORDER BY ISNULL(TerminationDate, @dtMaxDate+1) DESC, TargetFeeByUnit

	IF @@ERROR<>0
		SET @iReturn = -1

	RETURN @iReturn
END


