/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psCONV_ObtenirEpargneEtudeEnCours
Nom du service		:		Obtenir la liste oui/non concernant l'épargne étude en cours
But					:		
Facette				:		CONV
Reférence			:		

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						N/A

Exemple d'appel:
			EXECUTE dbo.psCONV_ObtenirEpargneEtudeEnCours 

Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
					   tblCONV_EpargneEtudeEnCours	iIDNiveauEtudeParent
													vcDescNiveauEtudeParent	

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-12-18					Jean-François Gauthier					Création du service

****************************************************************************************************/
CREATE PROCEDURE dbo.psCONV_ObtenirEpargneEtudeEnCours
AS
	BEGIN		
		SELECT
			ec.iIDEpargneEtudeEnCours,
			ec.vcDescEpargneEtudeEnCours
		FROM 
			dbo.tblCONV_EpargneEtudeEnCours ec
	END
