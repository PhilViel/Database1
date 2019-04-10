/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psCONV_ObtenirListeIdentiteSouscripteur
Nom du service		:		Obtenir la liste de reference pour remplir le profil du souscripteur
But					:		
Facette				:		CONV
Reférence			:		

Parametres d'entrée :	Parametres							Description
						-----------------------------------------------------------------------------------------------------
						iIdentiteSouscripteurID				Identifiant unique 

Exemple d'appel:


Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													iID_Identite_Souscripteur				
													vcCode_Identite_Souscripteur
													vcDescription

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-09-15					Radu Trandafir							Création de procédure stockée

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirListeIdentiteSouscripteur] (
	@iIdentiteSouscripteurID INTEGER = 0 )
AS

BEGIN

	-- Retourne les dossiers de la table 
	SELECT
		iID_Identite_Souscripteur, 
		vcCode_Identite_Souscripteur, 
		vcDescription
	FROM tblCONV_IdentiteSouscripteur
	WHERE iID_Identite_Souscripteur = ISNULL(NULLIF(@iIdentiteSouscripteurID, 0), iID_Identite_Souscripteur) -- (0 pour tous)

END


 
