/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psCONV_ObtenirListeRevenuFamilial
Nom du service		:		Obtenir la liste de reference pour remplir le profil du souscripteur
But					:		
Facette				:		CONV
Reférence			:		

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						iRevenuFamilialID			Identifiant unique 

Exemple d'appel:


Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													iID_Revenu_Familial
													vcCode_Revenu_Familial
													vcDescription

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------				-------------------------------------	----------------------------		---------------
						2008-09-15			Radu Trandafir							Création de procédure stockée
						2015-03-24			Pierre-Luc Simard						Ajout du filtre sur les dates
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirListeRevenuFamilial] (
	@iRevenuFamilialID INTEGER = 0 )
AS

BEGIN

	-- Retourne les dossiers de la table 
	SELECT
		iID_Revenu_Familial, 
		vcCode_Revenu_Familial, 
		vcDescription
	FROM tblCONV_RevenuFamilial
	WHERE iID_Revenu_Familial = ISNULL(NULLIF(@iRevenuFamilialID, 0), iID_Revenu_Familial) -- (0 pour tous)
		AND DateDebut <= GETDATE()
		AND ISNULL(DateFin, GETDATE()) >= CONVERT(Date, GETDATE())  

END

	
