/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psCONV_ObtenirListeObjectifsInvestissement
Nom du service		:		Obtenir la liste de reference pour remplir le profil du souscripteur
But					:		
Facette				:		CONV
Reférence			:		

Parametres d'entrée :	Parametres							Description
						-----------------------------------------------------------------------------------------------------
						iObjectifInvestissementID			Identifiant unique 
						siLigneCritereID

Exemple d'appel:


Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													iID_Objectif_Investissement				
													vcCode_Objectif_Investissement
													siID_LigneCritere
													vcDescription

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-09-15					Radu Trandafir							Création de procédure stockée

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirListeObjectifsInvestissement] (
	@iObjectifInvestissementID INTEGER = 0,
	@siLigneCritereID SMALLINT=0 )
AS

BEGIN

	-- Retourne les dossiers de la table 
	SELECT
		iID_Objectif_Investissement, 
		vcCode_Objectif_Investissement, 
		siID_LigneCritere,
		vcDescription
	FROM tblCONV_ObjectifsInvestissement
	WHERE iID_Objectif_Investissement = ISNULL(NULLIF(@iObjectifInvestissementID, 0), iID_Objectif_Investissement) -- (0 pour tous)
		   AND siID_LigneCritere = ISNULL(NULLIF(@siLigneCritereID, 0), siID_LigneCritere) -- (0 pour tous)				
END


