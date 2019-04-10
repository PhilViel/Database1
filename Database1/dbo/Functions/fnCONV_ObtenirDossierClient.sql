/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnCONV_ObtenirDossierClient
Nom du service		: Obtenir le nom du répertoire du client 
But 				: Obtenir le nom du répertoire pour un client, qu'il soit souscripteur ou bénéficiaire.	
Facette			: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Humain					Identifiant unique de l'humain
						bCheminComplet			Indique si on souhaite obtenir le chemin au complet (Oui) ou uniquement le nom du dossier (Non) 
															
Exemple d’appel		:	SELECT [dbo].[fnCONV_ObtenirDossierClient](630593,1)  -- Dossier souscripteur avec chemin complet
								SELECT [dbo].[fnCONV_ObtenirDossierClient](601617,0)  -- Dossier souscripteur
								SELECT [dbo].[fnCONV_ObtenirDossierClient](601618,1)  -- Dossier bénéficiaire avec chemin complet
								SELECT [dbo].[fnCONV_ObtenirDossierClient](601618,0)  -- Dossier bénéficiaire

Paramètres de sortie:	Table						Champ							Description
		  						-------------------------	--------------------------- 	---------------------------------
																@vcRepertoire				Nom du dossier client
												
Historique des modifications:
		Date				Programmeur							Description								 
		------------		----------------------------------	-----------------------------------------
		2013-08-26	Pierre-Luc Simard					Création du service
\\filesprod\PlanDeClassification\8_SERVICES_A_LA_CLIENTELE\802_GESTION_DES_CONTRATS\802-100_SOUSCRIPTEUR\S\ST-GEORGES_Stephanie_630593\le_test
*********************************************************************************************************************/
CREATE FUNCTION dbo.fnCONV_ObtenirDossierClient
(
	@iID_Humain	INT,
	@bCheminComplet BIT
)
RETURNS VARCHAR(255)
AS
BEGIN
	DECLARE 
		@vcRepertoire VARCHAR(255)
	
	SELECT
		@vcRepertoire =	CASE 
										WHEN @bCheminComplet = 1 THEN 
											CASE 
												WHEN S.SubscriberID IS NOT NULL THEN  dbo.fnGENE_ObtenirParametre('REPERTOIRE_DOSSIER_CLIENT_SOUSCRIPTEUR', NULL, NULL, NULL, NULL, NULL, NULL) 
												WHEN B.BeneficiaryID IS NOT NULL THEN  dbo.fnGENE_ObtenirParametre('REPERTOIRE_DOSSIER_CLIENT_BENEFICIAIRE', NULL, NULL, NULL, NULL, NULL, NULL)  
												ELSE ''
											END + 
											'\'+ dbo.fn_Mo_FormatStringWithoutAccent(substring(LTRIM(RTRIM(H.LastName)),1,1)) + '\' 
										ELSE ''
									END + 
									replace(replace(replace(replace(replace(dbo.fn_Mo_FormatStringWithoutAccent(upper(replace(LTRIM(RTRIM(H.LastName)),' ','_')) + '_' + replace(LTRIM(RTRIM(H.FirstName)),' ','_') + '_' + cast(H.HumanID as varchar(20))),'.',''),',',''),'&','Et'),'/',''),'\','') 
	FROM dbo.Mo_Human H 
	LEFT JOIN dbo.Un_Subscriber S ON S.SubscriberID = H.HumanID
	LEFT JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = H.HumanID
	WHERE H.HumanID = @iID_Humain

	-- Retourner le chemin et le nom du dossier client
	RETURN @vcRepertoire
END


