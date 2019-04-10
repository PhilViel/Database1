/****************************************************************************************************
  Retourne la liste de date de projection   

  2003-06-09   marcw   Création
  2003-08-12   Bruno   Modification (Mis sur la table Un_RepProjectionSumary plutôt que
                                     Un_RepProjection pour plus de rapidité)
*******************************************************************************************/
CREATE PROCEDURE [dbo].[SUn_RepProjectionList]
 (@ConnectID            MoID) --ID de connection de l'usager
AS
BEGIN

  SELECT DISTINCT 
    RepProjectionDate
  FROM Un_RepProjectionSumary
  ORDER BY RepProjectionDate

END

