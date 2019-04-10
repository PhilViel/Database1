/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                :	VL_UN_Subscriber_DL
Description        :	Fait les validations BD d'un souscripteur avant sa suppression.
Valeurs de retours :	>0  : Tout à fonctionné
                      <=0 : Erreur SQL
								-1 : 	Erreur à la création du log
								-2 : 	Erreur à la suppression du souscripteur
Note               :						2004-05-28	Bruno Lapointe	Création
							ADX0000826	IA	2006-03-14	Bruno Lapointe			Adaptation des souscripteurs pour PCEE 4.3
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_Subscriber_DL] (
	@SubscriberID INTEGER)
AS
BEGIN
	-- DS01 = Il est souscripteur d'une ou plusieurs conventions
	-- DS02 = Il est co-souscripteur d'une ou plusieurs conventions
	-- DS03 = Le souscripteur a été expédié au PCEE

	CREATE TABLE #WngAndErr(
		Code VARCHAR(4),
		NbRecord INTEGER
	)

	-- DS01 = Il est souscripteur d'une ou plusieurs conventions
	INSERT INTO #WngAndErr
		SELECT 
			'DS01',
			COUNT(ConventionID)
		FROM dbo.Un_Convention 
		WHERE SubscriberID = @SubscriberID
		HAVING COUNT(ConventionID) > 0

	-- DS02 = Il est co-souscripteur d'une ou plusieurs conventions
	INSERT INTO #WngAndErr
		SELECT 
			'DS02',
			COUNT(ConventionID)
		FROM dbo.Un_Convention 
		WHERE CoSubscriberID = @SubscriberID
		HAVING COUNT(ConventionID) > 0

	-- DS03 = Le souscripteur a été expédié au PCEE
	INSERT INTO #WngAndErr
		SELECT 
			'DS03',
			COUNT(ConventionID)
		FROM Un_CESP200
		WHERE HumanID = @SubscriberID
			AND tiType = 4
			AND iCESPSendFileID IS NOT NULL
		HAVING COUNT(ConventionID) > 0

	SELECT *
	FROM #WngAndErr

	DROP TABLE #WngAndErr
END


