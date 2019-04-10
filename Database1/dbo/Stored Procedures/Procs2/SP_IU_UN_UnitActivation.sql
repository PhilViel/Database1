/****************************************************************************************************
	Active et désactive un groupe d'unités
 ******************************************************************************
	2004-05-28 Bruno Lapointe
		Création 
	2015-06-03	Pierre-Luc Simard		Appeler la procédure qui gère le PCEE
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_UN_UnitActivation] (
	@ConnectID INTEGER, -- ID Unique de connection,
	@ActivationConnectID INTEGER, -- ID Unique de connection, 0 si pas activé
	@UnitID INTEGER) -- ID Unique du groupe d'unité
AS
BEGIN
	DECLARE 
		@count integer	,
		@ConventionID INT

	IF @ConnectID <= 0 
		SET @ConnectID = NULL
	
	IF @ActivationConnectID <= 0 
		SET @ActivationConnectID = NULL

	-- Vérification si premier unité
	SELECT @count = count(UnitID) FROM dbo.Un_Unit 
	where ConventionID = (select ConventionID FROM dbo.Un_Unit where UnitID = @UnitID)

	IF @count > 1 
		-- Appelle la procédure pour lettre ajout d'unité
		EXECUTE SP_RP_UN_LettreAjoutUnit @ConnectID, @UnitID, 0

	UPDATE dbo.Un_Unit 
	SET ActivationConnectID = @ActivationConnectID
	WHERE UnitID = @UnitID
	
	SELECT @ConventionID = ConventionID 
	FROM dbo.Un_Unit 
	WHERE UnitID = @UnitID

	-- Gestion du PCEE
	EXEC TT_UN_CESPOfConventions @ConnectID, 0, 0, @ConventionID
	
	IF @@Error = 0
		RETURN @UnitID
	ELSE
		RETURN 0
END;


