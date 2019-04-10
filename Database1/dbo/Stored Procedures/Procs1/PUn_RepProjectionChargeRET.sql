/****************************************************************************************************
  Retourne les retenus d'une projection par représentant     

  2003-07-04   marcw   Création
*******************************************************************************************/
CREATE PROC [dbo].[PUn_RepProjectionChargeRET] 
( @ConnectID MoID,            --ID unique de la connection
  @RepProjectionDate MoDate,  --Date de la projection
  @RepID MoID )               --ID unique du représentant ou si 0 de toutes les représentants 
AS
BEGIN

  SELECT 
    RepProjectionDate,
    RepID,
    'Avances sur résiliations' AS RepChargeDesc,
    AVRAmount AS RepChargeAmount
  FROM Un_RepProjectionSumary 
  WHERE ((@RepID = 0) OR (@RepID = RepID)) 
    AND (RepProjectionDate = @RepProjectionDate) 
    AND (AVRAmount <> 0)
  UNION ALL
  SELECT 
    RepProjectionDate,
    RepID,
    'Avances spéciales' AS RepChargeDesc,
    AVSAmount AS RepChargeAmount
  FROM Un_RepProjectionSumary 
  WHERE ((@RepID = 0) OR (@RepID = RepID)) 
    AND (RepProjectionDate = @RepProjectionDate) 
    AND (AVSAmount <> 0)
  
END;


