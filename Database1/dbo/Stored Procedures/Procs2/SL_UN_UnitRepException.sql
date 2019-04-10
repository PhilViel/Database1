/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_UnitRepException
Description         :	Procédure retournant les exceptions sur commissions et/ou bonis d’affaires pour un groupe
								d’unités.
Valeurs de retours  :	Dataset :
									RepExceptionID				INTEGER			ID unique de l’exception.
									RepID							INTEGER			ID du représentant affecté par l’exception.
									UnitID						INTEGER			ID du groupe d’unités.
									RepCode						VARCHAR(75)		Code du représentant.
									RepName						VARCHAR(87)		Nom, prénom du représentant.
									RepLevelID					INTEGER			ID du niveau du représentant.
									RepLevelDesc				VARCHAR(150)	Description du niveau (incluant le rôle).
									RepExceptionTypeID		CHAR(3)			Chaîne unique de 3 caractères donnant le type de
																						l'exception.  Permet aussi de connaître si
																						l'exception affecte les avances ou les avances
																						couvertes ou les commissions de service.
									RepExceptionTypeDesc		VARCHAR(75)		Description du type d'exception.
									RepExceptionTypeTypeID	CHAR(3)			Type de commission affectée (Avance, Avance couverte
																						commissions de service, etc.)
									RepExceptionTypeVisible	BIT				Indique s’il s’agit d’une exception système (0) ou
																						non (1).
									RepExceptionAmount		MONEY				Montant de l’exception
									RepExceptionDate			DATETIME			Date d'entrée en vigueur de l'exception.
Note                :	ADX0000723	IA	2005-07-13	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_UnitRepException] (
	@RepExceptionID INTEGER, -- ID unique de l’exception. (0 si prend @UnitID)
	@UnitID INTEGER ) -- ID du groupe d’unités dont on veut la liste des exceptions (0 si prend @RepExceptionID)
AS
BEGIN
	SELECT 
		RE.RepExceptionID, -- ID unique de l’exception.
		RE.RepID, -- ID du représentant affecté par l’exception.
		RE.UnitID, -- ID du groupe d’unités.
		R.RepCode, -- Code du représentant.
		RepName = H.LastName+', '+H.FirstName, -- Nom, prénom du représentant.
		RE.RepLevelID, -- ID du niveau du représentant.
		RepLevelDesc = RR.RepRoleDesc+' '+RL.LevelDesc, -- Description du niveau (incluant le rôle).
		RE.RepExceptionTypeID, -- Chaîne unique de 3 caractères donnant le type de l''exception.  Permet aussi de connaître si l''exception affecte les avances ou les avances couvertes ou les commissions de service.
		RET.RepExceptionTypeDesc, -- Description du type d''exception.
		RET.RepExceptionTypeTypeID, -- Type de commission affectée (Avance, Avance couverte commissions de service, etc.)
		RET.RepExceptionTypeVisible, -- Indique s’il s’agit d’une exception système (0) ou non (1).
		RE.RepExceptionAmount, -- Montant de l’exception
		RE.RepExceptionDate -- Date d''entrée en vigueur de l''exception.
	FROM Un_RepException RE
	JOIN Un_RepExceptionType RET ON RET.RepExceptionTypeID = RE.RepExceptionTypeID
	JOIN Un_Rep R ON R.RepID = RE.RepID
	JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
	JOIN Un_RepLevel RL ON RL.RepLevelID = RE.RepLevelID
	JOIN Un_RepRole RR ON RR.RepRoleID = RL.RepRoleID
	WHERE @UnitID = RE.UnitID
		OR @RepExceptionID = RE.RepExceptionID
	ORDER BY 
		RE.RepExceptionDate DESC,
		RET.RepExceptionTypeTypeID,
		RE.RepExceptionTypeID,
		RE.RepExceptionID DESC
END


