/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_ChangerMotDePassePortail
Nom du service		: Enregistrer la securite
But 				: Créer ou mettre à jour le mot de passe
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@iUserId					Identifiant de l'usager 
						@vbMotPasse					Mot de passe usager

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Exemple utilisation:																					
	- MAJ du mot de passe en connaissant ancien mot de passe
		EXEC psGENE_ChangerMotDePassePortail 1, <MotPasse_Nouveau>
	
TODO:

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-12-08		Eric Michaud						Création du service a partir de psGENE_EnregistrerSecurite							
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ChangerMotDePassePortail]
	@iUserId					INT,
	@vbMotPasse_Nouveau			varbinary(100) 
	
AS
BEGIN
	--SET NOCOUNT ON;

	-- MAJ de la securite actuelle
	Update tblGENE_PortailAuthentification
	SET vbMotPasse = @vbMotPasse_Nouveau
	WHERE iUserId = @iUserId
		
END


