-- Alter Function fntCONV_ObtenirStatutUnitEnDate_PourTous
/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnCONV_ObtenirStatutUnitEnDatePourTous
Nom du service		: 
But 				: Permet d'obtenir le statut de toutes les groupes d'unités en fonction d'une date
Description			: Cette fonction est appelée à chaque fois qu'il est nécesaire d'obtenir les statuts
					  des groupes d'unités
Facette				: CONV
Référence			: 

Paramètres d’entrée	:	Paramètre					Obligatoire	Description
						--------------------------	-----------	-----------------------------------------------------------------
						@dtDateStatut				Non			Date à laquelle on veut récupérer les statuts, par défaut, ce sont les actuels
						@idConvention				Non			ID de la convention pour laquelle on veut le statut, par défaut, pour tous
		  			

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Un_UnitState    			UnitID			        		ID du groupe d'unité
						Un_UnitState	    		UnitStateID     				Code du statut de la convention
						Un_UnitState		    	StartDate						Date d'entrée en vigueur du statut

Exemple d'appel : 
				SELECT * FROM dbo.fnCONV_ObtenirStatutUnitEnDatePourTous(NULL, NULL)
	
Historique des modifications:
		Date		Programmeur					Description						
		----------	-------------------------	---------------------------  	
		2015-11-27	Steeve Picard				Création de la fonction		
		2016-05-19	Pierre-Luc Simard		    Appel selon le groupe d'unités et non la convention
		2017-08-21	Steeve Picard				Optimisation
*********************************************************************************************************************/
CREATE FUNCTION dbo.fntCONV_ObtenirStatutUnitEnDate_PourTous
(
	@dtDateStatut	DATETIME = NULL,
	@idUnit	INT = NULL
)
RETURNS TABLE AS
RETURN (
	WITH CTE_Unit AS (
	    SELECT UnitID, UnitStateID, StartDate, UnitUnitStateID,
               Row_Num = ROW_NUMBER() OVER(PARTITION BY UnitID ORDER BY StartDate DESC)
	      FROM dbo.Un_UnitUnitState
		 WHERE UnitID = IsNull(@idUnit, UnitID)
		   AND StartDate <= IsNull(@dtDateStatut, GetDate())
    )
    SELECT UnitID, UnitStateID, StartDate, UnitUnitStateID
	  FROM CTE_Unit
     WHERE Row_Num = 1
    /*
	SELECT C.UnitID, C.UnitStateID, C.StartDate, C.UnitUnitStateID
	FROM dbo.Un_UnitUnitState C
	JOIN (
				SELECT UnitID, Max(StartDate) as LastStartDate
				FROM dbo.Un_UnitUnitState
				 WHERE StartDate <= IsNull(@dtDateStatut, GetDate())
				   AND UnitID = IsNull(@idUnit, UnitID)
				 GROUP BY UnitID
		   ) S On S.UnitID = C.UnitID And S.LastStartDate = C.StartDate
    */
)

