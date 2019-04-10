
/****************************************************************************************************
Code de service		:		psGENE_ObtenirListeDateProspectus
Nom du service		:		psGENE_ObtenirListeDateProspectus
But					:		Retourne la liste des valeurs possibles des dates de prospectus
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
                EXEC dbo.psGENE_ObtenirListeDateProspectus 
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------
                       tblGene_DateProspectus		iIDDateProspectus							Identifiant de la date de prospectus
													dtDateProspectus							Valeur de la date de prospectus

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2010-02-19					Jean-Francois Gauthier					Création de la procédure       
						2011-10-24					Donald Huppé							ajout d'un tri sur dtDateProspectus 
						
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirListeDateProspectus]
AS
	BEGIN
		SET NOCOUNT ON
		
		SELECT
			t.iIDDateProspectus,
			dtDateProspectus = ISNULL(CONVERT(VARCHAR(25),t.dtDateProspectus,121), 'Inconnu')
		FROM
			dbo.tblGene_DateProspectus t
		ORDER BY 
			t.dtDateProspectus desc
				
	END
