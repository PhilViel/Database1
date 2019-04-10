/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	SL_UN_RepExceptionType
Description         :	Procédure retournant la liste des types d’exceptions sur commissions et/ou bonis d’affaires.
			('' = Tous)
Valeurs de retours  :	Dataset :
					RepExceptionTypeID	CHAR(3)		Chaîne unique de 3 caractères donnant le type de
										l'exception.  Permet aussi de connaître si l'exception
										affecte les avances ou les avances couvertes ou les
										commissions de service.
					RepExceptionTypeDesc	VARCHAR(75)	Description du type d'exception.
					RepExceptionTypeTypeID	CHAR(3)		Indique ce qui est affecté par ce type d’exception.
					RepExceptionTypeVisible BIT		Champs boolean indiquant si le type d'exception est 
										visible pour l'usager (=0:Pas visible, <>0:Visible).  
										C'est une protection pour que les types gérés automatiquement 
										ne soient pas modifiés.		
					bUsed			BIT		Champs boolean indiquant si le type d'exception est
										utilisé dans les exceptions des représentants (0 = utilisé, <>0 = non utilisé). 										(Avances, avances couvertes, commissions de services,
																					
Note			: ADX0001003	IA	2006-07-13	Mireya Gonthier
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepExceptionType](
	@RepExceptionTypeID VARCHAR(3) ) -- ID du type d’exception de commissions, '' = Tous.
AS
BEGIN
	DECLARE @iReturn INTEGER
	SET @iReturn = 1

	(SELECT DISTINCT
		RepExceptionTypeID, 	-- Chaîne unique de 3 caractères donnant le type de l'exception.  Permet aussi de connaître si l'exception affecte les avances ou les avances couvertes ou les commissions de service.
		RepExceptionTypeDesc, 	-- Description du type d'exception.
		RepExceptionTypeTypeID, -- Indique ce qui est affecté par ce type d’exception. (Avances, avances couvertes, commissions de services, etc.)
		RepExceptionTypeVisible,--Champs boolean indiquant si le type d'exception est visible pour l'usager (=0:Pas visible, <>0:Visible).  
		bUsed = CAST(1 AS BIT)	--RepExceptionTypeID n'est pas utilisé dans la table Un_RepException
	FROM Un_RepExceptionType
	WHERE ( @RepExceptionTypeID = '' -- Retourne tous les types
		OR @RepExceptionTypeID = RepExceptionTypeID)
		AND RepExceptionTypeID IN (SELECT DISTINCT RepExceptionTypeID
					FROM UN_RepException)
	-----
	UNION
	-----
	SELECT DISTINCT
		RepExceptionTypeID, 	
		RepExceptionTypeDesc, 	
		RepExceptionTypeTypeID, 
		RepExceptionTypeVisible,
		bUsed = CAST(0 AS BIT)	--RepExceptionTypeID est utilisé dans la table Un_RepException
	FROM Un_RepExceptionType
	WHERE (@RepExceptionTypeID = '' -- Retourne tous les types
		OR @repExceptionTypeID = RepExceptionTypeID)
		AND RepExceptionTypeID NOT IN	(SELECT DISTINCT RepExceptionTypeID
						FROM UN_RepException))
	ORDER BY RepExceptionTypeDesc

	IF @@ERROR<>0
		SET @iReturn = -1

	RETURN @iReturn
END


