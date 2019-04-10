
/****************************************************************************************************
Code de service		:		psGENE_SupprimerTitreNote
Nom du service		:		1.7.4	Supprimer un titre de note (psGENE_SupprimerTitreNote)
But					:		Supprimer un titre de note
Facette				:		SGRC 
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@iID_TitreNote				Identifiant du titre de note à modifier

Exemple d'appel:
                
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------

Historique des modifications :			
						Date						Programmeur								Description							Référence
						2009-04-23					D.T.									Création
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_SupprimerTitreNote]
                                  (	
									@iID_TitreNote	INT
                                  )
AS
BEGIN
	DELETE 
	FROM dbo.tblGENE_TitreNote
	WHERE iID_TitreNote = @iID_TitreNote
END
