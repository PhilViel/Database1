
/****************************************************************************************************
Code de service		:		fnGENE_ObtenirCoutEtude
Nom du service		:		Obtenir le coût des études   
But					:		Récupérer le coût des études pour une province pour une année
Facette				:		P171U
Reférence			:		Relevé de dépôt
Parametres d'entrée :	Parametres					Description                              Obligatoir
                        ----------                  ----------------                         --------------                       
                        vcCodeProvince	            Code de la province                      Oui
                        iAnnee                      Année du coût des études                 Oui

						                                        


Exemple d'appel:
                
              SELECT dbo.fnGENE_ObtenirCoutEtude ('QC',2020)

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
                        S/O                         mCoût	                                    Coût des études

                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-12-04					Fatiha Araar							Création de la fonction           
						2010-08-17					Jean-François Gauthier					Modification car le champ StudyCostNB a été renommé StudyCostCA
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fnGENE_ObtenirCoutEtude] 
(
	@vcCodeProvince VARCHAR(10),
    @iAnnee INT
)
RETURNS MONEY
AS
BEGIN
	DECLARE @mCout MONEY
    
    SELECT @mCout = CASE 
                        WHEN not (@vcCodeProvince = 'QC' OR @vcCodeProvince = 'Quebec'  OR @vcCodeProvince = 'Québec') THEN 
                          ISNULL(SC.StudyCostCA,0)
                        ELSE
                          ISNULL(SC.StudyCost,0)
                        END
      FROM Un_StudyCost SC
     WHERE SC.YearQualif = @iAnnee
 
RETURN @mCout
END
