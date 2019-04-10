/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnGENE_CourrielEnDate
Nom du service		: Déterminer le courriel à une date
But 				: Retourner le courriel d’une personne ou d’une entreprise à une date donnée.
Facette				: GENE
Référence			: UniAccès-Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Source						Identifiant de l’humain ou de l'entreprise
		  				iID_Type						Type de téléphone désiré
						dtDate_Debut					Date pour laquelle l’adresse doit être déterminée. Si la date n’est pas 
															fournie, on considère que c’est pour obtenir le courriel le plus récent.

Exemple d’appel		:	SELECT dbo.fnGENE_CourrielEnDate (149665, 3, NULL)
								SELECT dbo.fnGENE_CourrielEnDate (606191, 1, '2011-11-30')

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						tblGENE_Courriel		vcCourriel						Courriel à la date demandée et pour le type demandé.  

Historique des modifications:
		Date				Programmeur							Description									Référence
		------------		----------------------------------	-----------------------------------------	------------
		2014-02-11			Pierre-Luc Simard			Création du service			
		2014-05-01			Pierre-Luc Simard			Retrancher une journée à la date de fin pour ne pas l'utiliser à cette date				
		2014-05-07			Maxime Martel				Ajout de l'option afficher invalide lorsque le telephone est invalide
		2014-08-28			Pierre-Luc Simard			Correction du nombre de caractères de 37 à 80
		2014-09-30			Pierre-Luc Simard			Ajout du tri sur iID_Courriel lorsque même date pour obtenir le dernier
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_CourrielEnDate]
(
	@iID_Source INT,
	@iID_Type INT,
	@dtDate_Debut DATETIME = NULL,
	@afficherInvalide bit = NULL
)
RETURNS VARCHAR(80)
AS
BEGIN
	DECLARE 
		@vcCourriel VARCHAR(80),
		@bInvalide bit
	
	--SET @vcCourriel = ''
	IF @dtDate_Debut IS NULL 
		SET @dtDate_Debut = dbo.FN_CRQ_DateNoTime(GETDATE())
	
	-- Le courriel de type Professionnel est retourné s'il s'agit d'un représentant actif, peu importe le type demandé en paramètre.
	IF EXISTS (SELECT 1 FROM Un_Rep R WHERE R.RepID = @iID_Source AND R.BusinessEnd IS NULL AND R.BusinessStart IS NOT NULL)
		SET @iID_Type = 2
	
	SELECT -- Valider que ce dernier courriel saisi n'a pas de date de fin avant la date
		@vcCourriel = T.vcCourriel, @bInvalide  = T.bInvalide
	FROM (	
		SELECT TOP 1 -- Va chercher le dernier courriel saisi selon la date
			T.dtDate_Debut,
			dtDate_Fin = DATEADD(d,-1,T.dtDate_Fin), 
			vcCourriel = ISNULL(vcCourriel, ''),
			T.bInvalide
		FROM tblGENE_Courriel T
		WHERE T.iID_Source = @iID_Source
			AND T.iID_Type = @iID_Type
			AND T.dtDate_Debut <= @dtDate_Debut 
		ORDER BY 
			T.dtDate_Debut DESC,
			T.iID_Courriel DESC
		) T
		WHERE ISNULL(T.dtDate_Fin, @dtDate_Debut) >= @dtDate_Debut

	IF isnull(@afficherInvalide,0) = 1
		SET @vcCourriel = CASE WHEN @bInvalide = 1 then '*** Invalide *** ' else @vcCourriel end --+ @vcCourriel

	RETURN @vcCourriel
	
END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[fnGENE_CourrielEnDate] TO [svc-portailmigrationprod]
    AS [dbo];

