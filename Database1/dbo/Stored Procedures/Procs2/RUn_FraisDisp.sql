
/****************************************************************************************************
Code de service		:		RUn_FraisDisp
Nom du service		:		RUn_FraisDisp
But					:		PROCEDURE D'AJOUT ET DE MODIFICATION DE DOCUMENTS.
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@ConnectID
						@OperDate 
						@Fee MoMoney
						@ConventionID
						@UnitID
						

Exemple d'appel:
					
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													RETURN(1)	-- pas d'errer				
													RETURN(0)	-- erreur

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2009-09-24					Jean-François Gauthier					Remplacement du @@Identity par Scope_Identity()
 ****************************************************************************************************/

-- Optimisé version 26 
CREATE PROC [dbo].[RUn_FraisDisp] (
@ConnectID MoID,
@OperDate MoGetDate,
@Fee MoMoney,
@ConventionID MoID,
@UnitID MoID)
AS
BEGIN

  DECLARE 
  @IOperID MoID;

  BEGIN TRANSACTION;

  INSERT INTO Un_Oper
    (ConnectID,
     OperTypeID,
     OperDate)
  VALUES
    (@ConnectID,
     'TFR',
     @OperDate);

  IF @@ERROR = 0
  BEGIN
    SELECT @IOperID = SCOPE_IDENTITY();

    INSERT INTO Un_Cotisation
      (UnitID,
       OperID,
       EffectDate,
       Cotisation,
       Fee,
       BenefInsur,
       SubscInsur,
       TaxOnInsur)
    VALUES
      (@UnitID,
       @IOperID,
       @OperDate,
       0,
       (@Fee * -1),
       0,
       0,
       0);

    IF @@ERROR = 0
    BEGIN
      INSERT INTO Un_ConventionOper
        (OperID,
         ConventionID,
         ConventionOperTypeID,
         ConventionOperAmount)
      VALUES
        (@IOperID,
         @ConventionID,
         'FDI',
         @Fee);
    END;
  END;

  IF @@ERROR = 0
  BEGIN
    COMMIT TRANSACTION;
    RETURN(1);
  END
  ELSE
  BEGIN
    ROLLBACK TRANSACTION;
    RETURN(0);
  END
END;
