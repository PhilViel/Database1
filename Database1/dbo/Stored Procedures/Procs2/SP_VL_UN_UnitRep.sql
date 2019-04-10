/****************************************************************************************************
	Vérification de l'irrégularité de représantant pour un groupe d'unités.
 ******************************************************************************
	2004-05-27 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_UnitRep] (
	@SubscriberID INTEGER, -- ID unique d'un souscripteur
	@RepID        INTEGER, -- ID unique d'un représentant
	@UnitID       INTEGER) -- ID unique d'un groupe d'unités
AS
BEGIN
	DECLARE
		@SubscriberRepID MoID
	
	-- Valide que si c'était un groupe d'unité exitant, le rep est changé.
	IF NOT EXISTS(
		SELECT 
			UnitID
		FROM dbo.Un_Unit 
		WHERE (RepID=@RepID)
		  AND (UnitID=@UnitID))
	BEGIN
		SELECT 
			@SubscriberRepID = RepID
		FROM dbo.Un_Subscriber 
		WHERE (SubscriberID=@SubscriberID)
	
		-- Vérifie si le nom du reprérésentant est le même
		IF @SubscriberRepID = @RepID
			SET @SubscriberRepID = 0
	END
	ELSE 
		SET @SubscriberRepID = 0
	
	-- Retourne le nom du représentant du souscripteur s'il est différent
	SELECT 
		H.LastName, 
		H.FirstName
	FROM dbo.Mo_Human H
	WHERE H.HumanID = @SubscriberRepID
END;


