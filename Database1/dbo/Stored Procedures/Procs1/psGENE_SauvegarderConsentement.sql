/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_SauvegarderConsentement
Nom du service		: Sauvegarder Consentement
But 				: Permet de sauvegarder le consentement des utilisateurs
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@iUserId					Identifiant de l'usager pour lequel on modifie la securite
						@ConsentementSouscripteur	Consentement du souscripteur
						@ConsentementBeneficiaire	Consentement du beneficiaire
							
Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Exemple utilisation:																					
	- Ajoute le consentement du souscripteur sans toucher a celui du benificiaire
		EXEC psGENE_SauvegarderConsentement 2, 1, null

	- Ajoute le consentement du benificiaire sans toucher a celui du souscripteur
		EXEC psGENE_SauvegarderConsentement 2, null,1
			
TO DO:
	
Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-18-10		Steve Gouin					Création du service		
		2014-02-20		Pierre-Luc Simard			Utilisation du champ bReleve_Papier au lieu de bConsentement		
****************************************************************************************************/
CREATE PROCEDURE dbo.psGENE_SauvegarderConsentement
	@iUserId INT,
	@bConsentementSouscripteur bit = null,
	@bConsentementBeneficiaire bit = null
	
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
	
	-- Verifie que l'usager est un souscripteur
	if @bConsentementSouscripteur is not null and not exists (select 1 FROM dbo.Un_Subscriber where subscriberid =@iUserId)
	BEGIN
		RAISERROR('L''usager spécifier n''est pas un souscripteur défini dans le système',15,1)
		RETURN 121
	END	

	-- Verifie que l'usager est un souscripteur
	if @bConsentementBeneficiaire is not null and not exists (select 1 FROM dbo.Un_Beneficiary where beneficiaryid =@iUserId)
	BEGIN
		RAISERROR('L''usager spécifier n''est pas un beneficiaire défini dans le système',15,1)
		RETURN 122
	END	

	--
	-- Principal
	--

	if 	@bConsentementSouscripteur is not null
		UPDATE dbo.Un_Subscriber set bReleve_Papier = @bConsentementSouscripteur where subscriberid = @iUserId		

	if 	@bConsentementBeneficiaire is not null
		UPDATE dbo.Un_Beneficiary set bReleve_Papier = @bConsentementBeneficiaire where beneficiaryid = @iUserId

END


