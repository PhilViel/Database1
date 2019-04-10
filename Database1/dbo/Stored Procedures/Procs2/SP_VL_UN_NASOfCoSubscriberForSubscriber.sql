/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_VL_UN_NASOfCoSubscriberForSubscriber
Description         :	Renvoi les conventions dans lesquelles un souscripteur est inscrit comme co-souscripteur si
								le souscripteur n'a pas de NAS.
Valeurs de retours  :	Dataset :
									ConventionNo	Numéro de convention
Note                :						2004-05-26	Bruno Lapointe		Création
								ADX0001812	BR	2006-02-28	Bruno Lapointe		Retourne les numéros de conventions que si le 
																							NAS est manquant.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_NASOfCoSubscriberForSubscriber](
	@SubscriberID MoID) -- Id unique du souscripteur
AS
BEGIN
	-- Renvoi la liste des conventions dans lesquelles le souscripteur est co-souscripteur
	SELECT DISTINCT
		ConventionNo
	FROM dbo.Un_Convention C
	JOIN dbo.Mo_Human H ON H.HumanID = C.CoSubscriberID
	WHERE H.HumanID = @SubscriberID 
		  AND ISNULL(H.SocialNumber,'') = ''
END


