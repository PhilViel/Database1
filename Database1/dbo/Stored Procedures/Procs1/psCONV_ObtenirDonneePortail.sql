/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psCONV_ObtenirDonneePortail
Nom du service		: Obtenir les données Portail-Client
But 				: Obtenir les données du compte du Portai-Client pour un souscripteur ou un bénéficiaire
Facette				: CONV
Référence			: Noyau-CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@ID							Identifiant du souscripteur ou du bénéficiaire
						
Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Exemple utilisation:	
	-- Obtenir les données du compte du Portai-Client pour un souscripteur
		EXEC psCONV_ObtenirDonneePortail 601617
	-- Obtenir les données du compte du Portai-Client pour un bénéficiaire
		EXEC psCONV_ObtenirDonneePortail 601618

TODO:
	
Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-04-28		Pierre-Luc Simard			Création du service
		2012-01-05		Eric Michaud					Modification bConsentement et ajout dtInscription						
		2014-02-20		Pierre-luc Simard			Utilisation du champ bReleve_Papier au lieu de bConsenement
*********************************************************************************************************************/
CREATE PROCEDURE dbo.psCONV_ObtenirDonneePortail (
	@ID INTEGER) -- Identifiant unique du souscripteur ou du bénéficiaire
AS
BEGIN

	-- Retourne les données du souscripteur ou du bénéficiaire pour son compte sur le Portail-Client
	SELECT 
		HumanID,
		iEtat = ISNULL(P.iEtat,6),
		E.vcDescEtat,
		P.dtDernierAcces,
		bConsentement = COALESCE(S.bReleve_Papier, B.bReleve_Papier),		
		bActivation = ISNULL(E.bActivation, 0),
		bDesactivation = ISNULL(E.bDesactivation, 0),
		P.dtInscription
	FROM dbo.Mo_Human H
	LEFT JOIN tblGENE_PortailAuthentification P ON P.iUserId = H.HumanID
	LEFT JOIN tblGENE_PortailEtat E ON E.iIDEtat = ISNULL(P.iEtat,6)
	LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
	LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
	WHERE H.HumanID = @ID
		AND (S.SubscriberID IS NOT NULL
			OR B.BeneficiaryID IS NOT NULL)	

END


