/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntCONV_ObtenirSouscripteurInitialConvention
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

Exemple d’appel		:	
						SELECT * FROM [dbo].[fntCONV_ObtenirSouscripteurInitialConvention](NULL, 300000)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
													iID_Souscripteur_Initial		Identifiant du souscripteur initial
						Mo_Human					Lastname, FirstName,			Nom du souscripteur initial.
													CompanyName					
						Mo_Human					SocialNumber					NAS du bénéficiaire initial.


Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-12-18		Éric Deshaies						Création du service							
		2010-01-27		Jean-François Gauthier				Ajout des champs FirstName et LastName séparés
****************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirSouscripteurInitialConvention]
(
	@cID_Langue CHAR(3),
	@iID_Convention INT
)
RETURNS @tblCONV_SouscripteurInitial TABLE
(
	iID_Souscripteur_Initial	INT				NOT NULL
	,vcNom						VARCHAR(100)	NULL
	,vcNAS						VARCHAR(75)		NULL
	,vcPrenom					VARCHAR(100)	NULL
	,vcNomFamille				VARCHAR(100)	NULL
)
AS
BEGIN
	-- Considérer le français comme la langue par défaut
	IF @cID_Langue IS NULL
		SET @cID_Langue = 'FRA'

	-- Déterminer le souscripteur initial
	DECLARE @iID_Souscripteur_Initial INT
	SET @iID_Souscripteur_Initial = [dbo].[fnCONV_SouscripteurEnDate](@iID_Convention, 0)

	IF @iID_Souscripteur_Initial IS NOT NULL AND @iID_Souscripteur_Initial <> 0
		BEGIN
			-- Rechercher les séries de paramètres selon les critères de recherche
			INSERT INTO @tblCONV_SouscripteurInitial
			(
				iID_Souscripteur_Initial	
				,vcNom						
				,vcNAS						
				,vcPrenom					
				,vcNomFamille				
			)
			SELECT	
					@iID_Souscripteur_Initial
					,CASE WHEN IsCompany = 0
							THEN FirstName + ' ' + LastName
							ELSE CompanyName
					 END
					,[dbo].[fn_Mo_FormatSIN](SocialNumber,'CAN')
					,FirstName
					,LastName
			FROM 
				dbo.Mo_Human
			WHERE 
				HumanID = @iID_Souscripteur_Initial
		END	
	-- Retourner les informations
	RETURN 
END
