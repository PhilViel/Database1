/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_ObtenirAdresseCourriel
Nom du service		: Obtenir adresse courriel humain
But 				: Retourner l'adresse courriel d'un humain
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@iUserId					Identifiant de l'usager pour lequel on modifie la securite
						@dtDateNaissance			Date de naissance qui doit corresponde pour retourner l'info
							
Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
													vcCourriel						Adresse courriel en cours
Exemple utilisation:																					
	- Obtenir le courriel d'un humain
		EXEC psGENE_ObtenirAdresseCourriel 2, '1 jan 1900'
	
TODO:
	
Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-08-10		Steve Gouin							Création du service							
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirAdresseCourriel]
	@iUserId INT,
	@dtDateNaissance datetime

AS
BEGIN
	SET NOCOUNT ON;

	--
	-- Validation
	--
	
	-- Verifier que le iUserId est un humain valide et que la date de naissance corresponde
	if not exists(select 1 FROM dbo.Mo_Human where Humanid = @iUserId and BirthDate = @dtDateNaissance)
	BEGIN
		RAISERROR('La date de naissance ne correspond pas à l''usager spécifié',15,1)
		RETURN 110
	END
			
	--
	-- Principal
	--

	select Email FROM dbo.Mo_Adr where adrid = (select adrid FROM dbo.Mo_Human where Humanid = @iUserId)

END


