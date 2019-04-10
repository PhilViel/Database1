/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnGENE_TelephoneEnDate
Nom du service		: Déterminer le téléphone à une date
But 				: Retourner le téléphone d’une personne ou d’une entreprise à une date donnée.
Facette				: GENE
Référence			: UniAccès-Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Source						Identifiant de l’humain ou de l'entreprise
		  				iID_Type						Type de téléphone désiré
						dtDate_Debut					Date pour laquelle l’adresse doit être déterminée. Si la date n’est pas 
															fournie, on considère que c’est pour obtenir le téléphone le plus récent.

Exemple d’appel		:	SELECT dbo.fnGENE_TelephoneEnDate (601617, 2, NULL)
								SELECT dbo.fnGENE_TelephoneEnDate (297799, 1, '2013-01-22')

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						tblGENE_Telephone		vcTelephone					Téléphone avec extension à la date demandée et pour le type demandé.  

Historique des modifications:
		Date				Programmeur							Description									Référence
		------------		----------------------------------	-----------------------------------------	------------
		2014-02-11	Pierre-Luc Simard			Création du service							
		2014-05-01	Pierre-Luc Simard			Retrancher une journée à la date de fin pour ne pas l'utiliser à cette date
		2014-05-07  	Maxime Martel				Ajout de l'option afficher invalide lorsque le telephone est invalide
		2014-09-30	Pierre-Luc Simard			Ajout du tri sur iID_Telephone lorsque même date pour obtenir le dernier
		2015-12-15	Pierre-Luc Simard			Ajout de la possibilité d'ajouter un espace entre le téléphone et l'extension
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_TelephoneEnDate]
(
	@iID_Source INT,
	@iID_Type INT,
	@dtDate_Debut DATETIME = NULL,
	@afficherInvalide bit = NULL,
	@AjouterEspaceExtension bit = NULL
)
RETURNS VARCHAR(37)
AS
BEGIN
	DECLARE 
		@vcTelephone VARCHAR(37),
		@bInvalide bit
	
	--SET @vcTelephone = ''
	IF @dtDate_Debut IS NULL 
		SET @dtDate_Debut = dbo.FN_CRQ_DateNoTime(GETDATE())
	
	SELECT -- Valider que ce dernier téléphone saisie n'a pas de date de fin avant la date
		@vcTelephone = T.vcTelephone, @bInvalide  = T.bInvalide 
	FROM (	
		SELECT TOP 1 -- Va chercher le dernier téléphone saisie selon la date
			T.dtDate_Debut,
			dtDate_Fin = DATEADD(d,-1,T.dtDate_Fin), 
			vcTelephone = isnull(vcTelephone, '') + CASE WHEN ISNULL(@AjouterEspaceExtension, 0) = 1 THEN CASE WHEN ISNULL(T.vcExtension,'') <> '' THEN ' ' + T.vcExtension ELSE '' END ELSE ISNULL(vcExtension, '') END,
			T.bInvalide
		FROM tblGENE_Telephone T
		WHERE T.iID_Source = @iID_Source
			AND T.iID_Type = @iID_Type
			AND T.dtDate_Debut <= @dtDate_Debut 
		ORDER BY 
			T.dtDate_Debut DESC,
			T.iID_Telephone DESC
		) T
		WHERE ISNULL(T.dtDate_Fin, @dtDate_Debut) >= @dtDate_Debut

	IF isnull(@afficherInvalide,0) = 1
		SET @vcTelephone = CASE WHEN @bInvalide = 1 then '*** Invalide *** ' else @vcTelephone end

	RETURN @vcTelephone
	
END
