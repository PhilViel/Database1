/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_SupprimerNote
Nom du service		: Supprimer une note
But 				: Effacer une note dans la tables des notes
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Note					Identifiant de la note

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						N/A

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-03-12		Jean-Francois Arial					Création du service							

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_SupprimerNote]
	@iID_Note					INT	
	
	
AS
BEGIN
	DELETE dbo.tblGENE_Note
	WHERE @iID_Note = iID_Note
END
