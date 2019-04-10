
/****************************************************************************************************
Code de service		:		fnCONV_ObtenirMaxAnneeScolaire
Nom du service		:		Obtenir l'année la plus élevée pour laquelle des valeurs unitaires ont été saisies
But					:		Récupérer l'année la plus élevée pour laquelle des valeurs unitaires ont été saisies
Facette				:		P171U
Reférence			:		Relevé de dépôt

Parametres d'entrée :	Parametres					Description                              Obligatoir
                        ----------                  ----------------                         --------------                       

Exemple d'appel:

                SELECT dbo.fnCONV_ObtenirBourse (12345,5)

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
                        S/O                         @iMaxScholarshipYear                        L'année la plus élevée pour laquelle des valeurs unitaires ont été saisies

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-02-05					Fatiha Araar							Création de la fonction           
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_ObtenirMaxAnneeScolaire] ()

RETURNS INT
AS
BEGIN

    DECLARE @iMaxScholarshipYear INT

	SELECT @iMaxScholarshipYear = MIN(V.ScholarshipYear)-1
	  FROM Un_PlanValues V 
      JOIN Un_Plan P ON P.PlanID = V.PlanID
	 WHERE UnitValue = 0
	   AND P.PlanTypeID = 'COL'

	IF @iMaxScholarshipYear IS NULL
		SELECT @iMaxScholarshipYear = MAX(V.ScholarshipYear)
		  FROM Un_PlanValues V 
		  JOIN Un_Plan P ON P.PlanID = V.PlanID
		 WHERE P.PlanTypeID = 'COL'

	RETURN @iMaxScholarshipYear
END
