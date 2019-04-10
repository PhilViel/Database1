/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: fnGENE_ObtenirDerniereDateOuvrableDuMois
Nom du service		: Obtenir la dernière date ouvrable du mois
But 				: Obtenir la dernière date entre lundi et vendredi du mois associé à une date passée en paramètre
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						@dtDate						date contenant le mois pour lequel on veut la dernieère date ouvrable entre lundi et vendredi.

Exemple d’appel		:	select [dbo].[fnGENE_ObtenirDerniereDateOuvrableDuMois]('2013-07-28')

Paramètres de sortie:	une date

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-03-25		Donald Huppé						Création du service							

****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ObtenirDerniereDateOuvrableDuMois] 
(
	@dtDate DATETIME
)
RETURNS DATETIME
AS
BEGIN

DECLARE     
	@dateM DATETIME,
	@intDW INT

	-- Le dernier jour du mois   
	SET @dateM = DATEADD(month, DATEDIFF(month, 0, @dtDate) + 1, 0) - 1
	-- Le jour associé à cette date
	SET @intDW = datepart(dw, @dateM)
	-- Tant que c'est dimanche ou samedi, on recule d'un jour à la fois
	WHILE @intDW = 1 OR @intDW = 7     
	BEGIN
			 SET @dateM = DATEADD(d, -1, @dateM)
			 SET @intDW = DATEPART(dw, @dateM)    
	END 
	
	-- Retourner la date
	RETURN LEFT(CONVERT(VARCHAR, @dateM, 120), 10)

END

