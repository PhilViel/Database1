

/****************************************************************************************************
Code de service		:		psGENE_ModifierPortailEtats
Nom du service		:		Ce service permet de modifier l'enregistrement de la table tblGENE_PortailAuthentification
But					:		Récupérer le type 
Facette				:		GENE
Reférence			:		SGRC

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@@iUserId					Identifiant de l’humain
						@@NouvelEtat				Nouvel état
Exemple d'appel:
                
                EXEC dbo.psGENE_ModifierPortailEtats 176465,7

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
                    
Historique des modifications :
			
	Date						Programmeur								Description							Référence
	----------					-------------------------------------	----------------------------		---------------
	2011-09-06					Eric Michaud							Création du service

 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ModifierPortailEtats]
				(					
					@iUserId INT,
					@NouvelEtat	int
				)
AS
	BEGIN

	SET NOCOUNT ON
	
		-- Mettre l'état 
		UPDATE tblGENE_PortailAuthentification
		SET iEtat = @NouvelEtat 
		WHERE iUserId = @iUserId

	END
