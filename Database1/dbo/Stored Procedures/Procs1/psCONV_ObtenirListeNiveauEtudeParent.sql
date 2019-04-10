/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psCONV_ObtenirListeNiveauEtudeParent
Nom du service		:		Obtenir la liste des niveaux d'études des parents
But					:		
Facette				:		CONV
Reférence			:		

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						iIDNiveauEtudeParent		Identifiant unique 

Exemple d'appel:
			EXECUTE dbo.psCONV_ObtenirListeNiveauEtudeParent NULL

Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
					   tblCONV_NiveauEtudeParent	iIDNiveauEtudeParent
													vcDescNiveauEtudeParent	

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-12-18					Jean-François Gauthier					Création du service

****************************************************************************************************/
CREATE PROCEDURE dbo.psCONV_ObtenirListeNiveauEtudeParent 
											(
												@iIDNiveauEtudeParent INT
											)
AS
	BEGIN		
		SELECT
			nep.iIDNiveauEtudeParent, 
			nep.vcDescNiveauEtudeParent	
		FROM 
			dbo.tblCONV_NiveauEtudeParent nep
		WHERE 
			nep.iIDNiveauEtudeParent = ISNULL(@iIDNiveauEtudeParent, nep.iIDNiveauEtudeParent)
	END
