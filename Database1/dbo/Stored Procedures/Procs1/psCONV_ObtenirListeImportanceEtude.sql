/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psCONV_ObtenirListeImportanceEtude
Nom du service		:		Obtenir la liste des niveaux d'importance des études de métier, collégiales ou universitaires
But					:		
Facette				:		CONV
Reférence			:		

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						@iIDImportanceEtude			Identifiant unique 

Exemple d'appel:
			EXECUTE dbo.psCONV_ObtenirListeImportanceEtude NULL

Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
					   tblCONV_ImportanceEtudeMetier iIDImportanceEtude, 
													 iCodeImportanceEtude, 
													 vcDescImportanceEtude

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-12-18					Jean-François Gauthier					Création du service
						2010-01-05					Jean-François Gauthier					Modification, car le paramètre @iIDTypeEtude
																							n'est plus nécessaire 
****************************************************************************************************/
CREATE PROCEDURE dbo.psCONV_ObtenirListeImportanceEtude 
											(
												@iIDImportanceEtude INT
											)
AS
	BEGIN		
		SELECT
			ie.iIDImportanceEtude, 
			ie.iCodeImportanceEtude, 
			ie.vcDescImportanceEtude
		FROM 
			dbo.tblCONV_ImportanceEtudePostSecondaire ie
		WHERE 
			ie.iIDImportanceEtude = ISNULL(@iIDImportanceEtude, ie.iIDImportanceEtude)
		ORDER BY
			ie.iCodeImportanceEtude
	END
