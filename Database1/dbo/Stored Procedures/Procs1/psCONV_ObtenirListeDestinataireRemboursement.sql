/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psCONV_ObtenirListeDestinataireRamboursement
Nom du service		:		Obtenir la liste de reference pour remplir le profil du souscripteur
But					:		
Facette				:		CONV
Reférence			:		

Parametres d'entrée :	Parametres							Description
						-----------------------------------------------------------------------------------------------------
						iDestinataireRemboursementID		Identifiant unique 

Exemple d'appel:


Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													iID_Destinataire_Remboursement				
													vcCode_Destinataire_Remboursement
													vcDescription

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-09-15					Radu Trandafir							Création de procédure stockée

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirListeDestinataireRemboursement] (
	@iDestinataireRemboursementID INTEGER = 0 )
AS

BEGIN

	-- Retourne les dossiers de la table 
	SELECT
		iID_Destinataire_Remboursement, 
		vcCode_Destinataire_Remboursement, 
		vcDescription
	FROM tblCONV_DestinataireRemboursement
	WHERE iID_Destinataire_Remboursement = ISNULL(NULLIF(@iDestinataireRemboursementID, 0), iID_Destinataire_Remboursement) -- (0 pour tous)

END


 
