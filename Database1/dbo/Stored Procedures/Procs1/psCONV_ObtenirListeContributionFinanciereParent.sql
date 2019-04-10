/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psCONV_ObtenirListeContributionFinanciereParent
Nom du service		:		Obtenir la liste des pourcentages de contribution financière des parents
But					:		
Facette				:		CONV
Reférence			:		

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						N/A

Exemple d'appel:
			EXECUTE dbo.psCONV_ObtenirListeContributionFinanciereParent 

Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
					   tblCONV_NiveauEtudeParent	iIDNiveauEtudeParent
													vcDescNiveauEtudeParent	

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-12-18					Jean-François Gauthier					Création du service

****************************************************************************************************/
CREATE PROCEDURE dbo.psCONV_ObtenirListeContributionFinanciereParent
AS
	BEGIN		
		SELECT
			cfp.iIDContributionFinanciereParent, 
			cfp.vcContributionFinanciereParent
		FROM 
			dbo.tblCONV_ContributionFinanciereParent cfp
	END
