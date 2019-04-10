/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psCONV_ObtenirListeConnaissancesPlacements
Nom du service		:		Obtenir la liste de reference pour remplir le profil du souscripteur
But					:		
Facette				:		CONV
Reférence			:		

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						iConnaissancePlacementsID	Identifiant unique 

Exemple d'appel:


Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													iID_Connaissance_Placements				
													vcCode_Connaissance_Placements
													vcDescription

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-09-15					Radu Trandafir							Création de procédure stockée

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirListeConnaissancesPlacements] (
	@iConnaissancePlacementsID INTEGER = 0 )
AS

BEGIN

	-- Retourne les dossiers de la table de SEXE
	SELECT
		iID_Connaissance_Placements, 
		vcCode_Connaissance_Placements, 
		vcDescription
	FROM tblCONV_ConnaissancesPlacements
	WHERE iID_Connaissance_Placements = ISNULL(NULLIF(@iConnaissancePlacementsID, 0), iID_Connaissance_Placements) -- (0 pour tous)

END

 
