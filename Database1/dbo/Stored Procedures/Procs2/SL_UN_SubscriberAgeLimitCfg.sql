
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SubscriberAgeLimitCfg
Description         :	Retourne la liste des configurations des limites d'âge (Minimum pour avoir une convention et
						Maximum pour avoir de l'assurance souscripteur)
Valeurs de retours  :	Dataset de données

Note                :	ADX0000472	IA	2005-02-04	Bruno Lapointe		Création
						ADX0001268	IA	2007-03-26	Alain Quirion		Modification. Changement du nom de la procédure et suppresion du paramètre d'entrée
*********************************************************************************************************************/
CREATE PROCEDURE dbo.SL_UN_SubscriberAgeLimitCfg
AS
BEGIN
	SELECT
		SubscriberAgeLimitCfgID,
		EffectDate,
		MaxAgeForSubscInsur,
		MinSubscriberAge
	FROM Un_SubscriberAgeLimitCfg
	ORDER BY EffectDate DESC
END

