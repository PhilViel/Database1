/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_ObtenirListeQuestionSecrete
Nom du service		: Obtenir liste QS
But 				: Retourner la liste de questions secrètes pour un usager
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@iUserId					Identifiant de l'usager pour lequel on modifie la securite
						@dtDateNaissance			Date de naissance qui doit corresponde pour retourner l'info
							
Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
													IQS1Id							Id de la question secrète 1
													IQS2Id							Id de la question secrète 2
													IQS3Id							Id de la question secrète 3
Exemple utilisation:																					
	- Obtenir la liste pour 1 usager
		EXEC psGENE_ObtenirListeQuestionSecrete 2, '1 jan 1900'

TODO:
	- Phase 2 : Ne plus retourner la liste des reponses secretes, la validation devrait se faire dans la bd
	
Erreur:
		110		La date de naissance ne correspond pas à l'usager spécifié
		120		L''usager spécifier n'a pas d''accès défini dans le système
			
Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-08-10		Steve Gouin							Création du service							
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirListeQuestionSecrete]
	@iUserId INT,
	@dtDateNaissance datetime

AS
BEGIN
	SET NOCOUNT ON;

	--
	-- Validation
	--
	
	-- Verifie que l'uager est defini dans la BD
	if not exists (select 1 from tblGENE_PortailAuthentification where iUserId =@iUserId)
	BEGIN
		RAISERROR('L''usager spécifier n''a pas d''accès défini dans le système',15,1)
		RETURN 120
	END	

	-- Verifier que le iUserId est un humain valide et que la date de naissance corresponde
	if not exists(select 1 FROM dbo.MO_Human where Humanid = @iUserId and BirthDate = @dtDateNaissance)
	BEGIN
		RAISERROR('La date de naissance ne correspond pas à l''usager spécifié',15,1)
		RETURN 110
	END
			
	--
	-- Principal
	--
	
	SELECT [iQS1id],[iQS2id],[iQS3id], vbRQ1, vbRQ2, vbRQ3
	from tblGENE_PortailAuthentification
	WHERE iUserId = @iUserId
	
END


