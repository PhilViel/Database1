/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service		: psREPR_ObtenirRepTreatment
Nom du service		: Obtenir les info de Un_RepTreatment pour les listes déroulantes des paramètres des rapports SSRS
But 				: 
Facette				: REPR

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psREPR_ObtenirRepTreatment

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-12-17		Donald Huppé						Création du service	

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_ObtenirRepTreatment] 

AS

BEGIN

	SELECT 
		RepTreatmentID, 
		Descr = cast(RepTreatmentID as varchar(4)) + ' (' + convert(char(10),RepTreatmentDate,121) + ')',
		TreatmentDate = convert(char(10),RepTreatmentDate,121)
	FROM 
		Un_RepTreatment 
	ORDER BY 
		RepTreatmentID DESC

End
