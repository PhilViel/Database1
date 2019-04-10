/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnGENE_DateDeFinAvecHeure
Nom du service		: Obtenir la date et l’heure d’une date de fin  
But 				: Obtenir une date avec l’heure 23:59:59 pour une date de fin de quelque chose.
Facette				: GENE
Référence			: UniAccès-Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				dtDate						Date à traiter.

Exemple d’appel		:	exec [dbo].[fnGENE_DateDeFinAvecHeure] '2008-05-27'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							dtDate_Fin						Date de fin avec l’heure 23:59:59.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-05-27		Éric Deshaies						Création du service							

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_DateDeFinAvecHeure]
(
	@dtDate DateTime
)
RETURNS DateTime
AS
BEGIN
	-- Retourner NULL
	IF @dtDate IS NULL
		RETURN NULL
	
	-- Retourner la date avec l'heure
	RETURN DATEADD(millisecond,-2,CAST(FLOOR(CAST(@dtDate AS FLOAT))+1 AS DATETIME))
END

