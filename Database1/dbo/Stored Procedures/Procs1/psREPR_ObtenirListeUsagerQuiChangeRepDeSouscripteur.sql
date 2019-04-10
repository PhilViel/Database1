/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service		: psREPR_ObtenirListeUsagerQuiChangeRepDeSouscripteur
Nom du service		: Obtenir la Liste des Usager Qui ont déjà fait un changement de représentant associé à un Souscripteur
But 				: Pour populer une liste déroulante de paramètre d'un rapport SSRS concernant l'historique des changements de représentant associé à un Souscripteur
Facette				: REPR

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psREPR_ObtenirListeUsagerQuiChangeRepDeSouscripteur

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-05-09		Donald Huppé						Création du service	

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_ObtenirListeUsagerQuiChangeRepDeSouscripteur] 

AS
BEGIN

/* -- ce sql est trop long (retiré le 2012-05-23 pour faire fonctionner pour Sandra Dufour)
	SELECT DISTINCT
		groupe = 1,
		h.HumanID,
		Usager = h.LastName + ' ' + h.FirstName + CASE WHEN R.RepID IS NOT NULL THEN ' (Rep ' + R.RepCode + ')' ELSE ' (Employé)' end,
		h.LastName,
		h.FirstName
	FROM 
		crq_log l
		join mo_connect cn on l.ConnectID = cn.ConnectID 
		JOIN dbo.Mo_Human h	ON cn.UserID = h.HumanID
		LEFT JOIN Un_Rep R ON h.HumanID = R.RepID
	WHERE 
		logtablename = 'Un_Subscriber'
		and logtext like '%RepID%'
		and logactionid = 2

	UNION ALL
*/	
	SELECT 
		groupe = 0,
		HumanID = 0,
		Usager = 'Tous les usagers',
		LastName = 'Tous',
		FirstName = 'Tous'
/*
	ORDER BY
		groupe,
		h.LastName,
		h.FirstName,
		h.HumanID
*/
end

