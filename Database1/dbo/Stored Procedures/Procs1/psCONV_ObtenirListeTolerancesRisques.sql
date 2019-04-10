/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psCONV_ObtenirListeTolerancesRisques
Nom du service		:		Obtenir la liste de reference pour remplir le profil du souscripteur
But					:		
Facette				:		CONV
Reférence			:		

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						iToleranceRisqueID	Identifiant unique 

Exemple d'appel:


Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													iID_Tolerance_Risque			
													vcCode_Tolerance_Risque
													vcDescription

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2012-09-14					Donald Huppé							Création de procédure stockée

exec psCONV_ObtenirListeTolerancesRisques 0
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirListeTolerancesRisques] (
	@iToleranceRisqueID INTEGER = 0 )
AS

BEGIN

	-- Retourne les dossiers de la table de ToleranceRisque
	SELECT
		iID_Tolerance_Risque, 
		vcCode_Tolerance_Risque, 
		vcDescription
	FROM tblCONV_ToleranceRisque
	WHERE iID_Tolerance_Risque = ISNULL(NULLIF(@iToleranceRisqueID, 0), iID_Tolerance_Risque) -- (0 pour tous)

END

 
