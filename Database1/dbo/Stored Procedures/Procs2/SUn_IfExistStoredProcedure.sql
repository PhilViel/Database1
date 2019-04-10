/****************************************************************************************************
  Description : dit si une procédure existe ou non dans la base de données.

  Variables :
   @ConnectID            : Id unique de la connection de l'usager
   @ProcedureName        : Nom de la procédure recherché 

 ******************************************************************************
  02-12-2003 Bruno      Création #0779
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SUn_IfExistStoredProcedure] (
@ConnectID MoID,
@ProcedureName MoDesc)
AS
BEGIN

  IF EXISTS (SELECT * FROM sysobjects WHERE Name = @ProcedureName)
    RETURN(1)
  ELSE
    RETURN(0);

END;

