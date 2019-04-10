/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psCONV_ObtenirSouscripteurInitialConvention
Nom du service		: Obtenir les informations du souscripteur initial d’une convention 
But 				: Obtenir les informations du souscripteur initial d’une convention.
Facette				: CONV
Référence			: Noyau-CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.
						iID_Convention				Identifiant unique de la convention pour laquelle les informations
													sont demandées.

Exemple d’appel		:	EXEC [dbo].[psCONV_ObtenirSouscripteurInitialConvention] NULL, 300000

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
													iID_Souscripteur_Initial		Identifiant du souscripteur initial
						Mo_Human					Lastname, FirstName,			Nom du souscripteur initial.
													CompanyName					
						Mo_Human					SocialNumber					NAS du bénéficiaire initial.


Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-11-27		Jean-François Gauthier				Création de la procédure
		2010-01-27		Jean-François Gauthier				Ajout des champs vcPrenom et vcNomFamille
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirSouscripteurInitialConvention]
	(
		@cID_Langue CHAR(3),
		@iID_Convention INT
	)
AS
BEGIN
	SET NOCOUNT ON

	SELECT 
		iID_Souscripteur_Initial
		,vcNom
		,vcNAS
		,vcPrenom					
		,vcNomFamille				
	FROM 
		dbo.fntCONV_ObtenirSouscripteurInitialConvention(@cID_Langue, @iID_Convention)
END
