/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psCONV_ObtenirListeEstimationCoutEtudes
Nom du service		:		Obtenir la liste de reference pour remplir le profil du souscripteur
But					:		
Facette				:		CONV
Reférence			:		

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						@iEstimationCoutEtudesID			Identifiant unique 

Exemple d'appel:


Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													iID_Estimation_Cout_Etudes
													vcCode_Estimation_Cout_Etudes
													vcDescription

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-10-24					Christian Chénard						Création de la procédure stockée

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirListeEstimationCoutEtudes] (
	@iEstimationCoutEtudesID INTEGER = 0 )
AS

BEGIN

	-- Retourne les dossiers de la table 
	SELECT
		iID_Estimation_Cout_Etudes,
		vcCode_Estimation_Cout_Etudes,		 
		vcDescription
	FROM dbo.tblCONV_EstimationCoutEtudes
	WHERE iID_Estimation_Cout_Etudes = ISNULL(NULLIF(@iEstimationCoutEtudesID, 0), iID_Estimation_Cout_Etudes) -- (0 pour tous)

END

 
