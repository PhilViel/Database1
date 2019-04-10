/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psCONV_ObtenirListePreferenceSuivi
Nom du service		:		Obtenir la liste de reference pour remplir le profil du souscripteur
But					:		
Facette				:		CONV
Reférence			:		

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						iPreferenceSuiviID	Identifiant unique du suivi

Exemple d'appel:


Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													iID_Preference_Suivi				
													vcCode_Preference_Suivi
													vcDescription

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-09-15					Radu Trandafir							Création de procédure stockée

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirListePreferenceSuivi] (
	@iPreferenceSuiviID INTEGER = 0 )
AS

BEGIN

	-- Retourne les dossiers de la table tblCONV_PreferenceSuivi
	SELECT
		iID_Preference_Suivi, 
		vcCode_Preference_Suivi, 
		vcDescription
	FROM tblCONV_PreferenceSuivi
	WHERE iID_Preference_Suivi = ISNULL(NULLIF(@iPreferenceSuiviID, 0), iID_Preference_Suivi) -- (0 pour tous)

END

 
