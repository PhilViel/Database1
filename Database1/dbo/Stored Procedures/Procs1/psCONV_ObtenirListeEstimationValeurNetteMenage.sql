/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psCONV_ObtenirListeEstimationValeurNetteMenage
Nom du service		:		Obtenir la liste de reference pour remplir le profil du souscripteur
But					:		
Facette				:		CONV
Reférence			:		

Parametres d'entrée :	Parametres							Description
						-----------------------------------------------------------------------------------------------------
						@iEstimationValeurNetteMenageID		Identifiant unique 

Exemple d'appel:


Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													iID_Estimation_Valeur_Nette_Menage
													vcCode_Estimation_Valeur_Nette_Menage
													vcDescription

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2011-10-31					Christian Chénard						Création de la procédure stockée

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirListeEstimationValeurNetteMenage] (
	@iEstimationValeurNetteMenageID INTEGER = 0 )
AS

BEGIN

	-- Retourne les dossiers de la table 
	SELECT
		iID_Estimation_Valeur_Nette_Menage,
		vcCode_Estimation_Valeur_Nette_Menage,	 
		vcDescription
	FROM dbo.tblCONV_EstimationValeurNetteMenage
	WHERE iID_Estimation_Valeur_Nette_Menage = ISNULL(NULLIF(@iEstimationValeurNetteMenageID, 0), iID_Estimation_Valeur_Nette_Menage) -- (0 pour tous)

END

 
