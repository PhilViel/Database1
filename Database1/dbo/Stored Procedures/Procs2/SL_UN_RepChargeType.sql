/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_RepChargeType
Description         :	Procédure de sélection de la liste des types d’ajustements ou de retenus.
			'' = Tous 
Valeurs de retours  :	Dataset :
					RepChargeTypeID		CHAR(3)		Identifiant unique de l’ajustement ou retenu
					RepChargeTypeDesc	VARCHAR(75)	Nom du type d’ajustement ou retenu
					RepChargeTypeComm	BIT		Champ boolean qui détermine s’il s’agit d’un ajustement ou une retenu (0=retenu, <>0 = ajustement)
					RepChargeTypeVisible	BIT 	Champs boolean qui détermine si l'usager peut voir ce type dans la fenêtre d'édition et 
										visualisation (0 : Non, <> 0 : Oui). On a créer ce champs pour empêcher les usagers d'avoir 
										accèes à modifier des types d'ajustements ou retenus gérer automatique par l'application
			@ReturnValue :
					> 0 : [Réussite]
					<= 0 : [Échec].

Note                :	ADX0000991	IA	2006-05-19	Alain Quirion		Création	
			ADX0002023	ST	2006-06-12	Mireya Gonthier		Modification 					
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepChargeType] (
@RepChargeTypeID VARCHAR(3))
AS
BEGIN
	DECLARE @iReturn INTEGER
	SET @iReturn = 1

	(SELECT DISTINCT
	RepChargeTypeID,
	RepChargeTypeDesc, 
	RepChargeTypeComm,
	RepChargeTypeVisible,
	bUsed = CAST(1 AS BIT)
	FROM Un_RepChargeType
	WHERE (@RepChargeTypeID = '' -- Retourne tous les types
		OR @RepChargeTypeID = RepChargeTypeID)
		AND RepChargeTypeID IN (SELECT DISTINCT RepChargeTypeID
					FROM Un_RepCharge)
	UNION
	SELECT DISTINCT
		RepChargeTypeID,
		RepChargeTypeDesc, 
		RepChargeTypeComm,
		RepChargeTypeVisible,
		bUsed = CAST(0 AS BIT)
	FROM Un_RepChargeType
	WHERE (@RepChargeTypeID = ''  -- Retourne tous les types
		OR @RepChargeTypeID = RepChargeTypeID)
		AND RepChargeTypeID NOT IN (SELECT DISTINCT RepChargeTypeID
					FROM Un_RepCharge))
	ORDER BY RepChargeTypeDesc
	
	IF @@ERROR<>0
		SET @iReturn = -1

	RETURN @iReturn
END

