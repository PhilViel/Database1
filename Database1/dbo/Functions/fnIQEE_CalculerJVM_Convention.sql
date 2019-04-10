

/****************************************************************************************************
Code de service		:		fnIQEE_CalculerJVM_Convention
Nom du service		:		CalculerJVM_Convention
But					:		Calculer la juste valeur marchande (JVM) de l'IQEE
Facette				:		GENE
Reférence			:		Système de gestion de la relation client

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        iID_Convention              ID de la convention concernée par l'appel
                        dtDate_Fin                  Date de fin de la période considérée par l'appel


Exemple d'appel:
                SELECT * FROM DBO.[fnIQEE_CalculerJVM] (1234, 2011-12-19 07:52:45.930)

Parametres de sortie : La JVM de l'IQEE

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2012-07-24                  Dominique Pothier                       Création de la fonction
 ****************************************************************************************************/
 
CREATE FUNCTION [dbo].[fnIQEE_CalculerJVM_Convention]
					(	
	                        @iID_Convention 				INT,
							@dtDate_Fin  				DATETIME
					)
RETURNS  MONEY
AS
BEGIN
	DECLARE 
			@mJVM_Comptable money,
			@mSolde_SCEE money ,
			@mSolde_BEC money,
			@mJVM_IQEE money


			set @mJVM_Comptable  = 0
			set @mSolde_SCEE  = 0
			set @mSolde_BEC  = 0
			set @mJVM_IQEE  = 0

	SET @mJVM_Comptable = [dbo].[fnGENE_CalculerJVMComptable_Convention](@iID_Convention,@dtDate_Fin)
	SET @mSolde_SCEE = [dbo].[fnPCEE_CalculerSoldeSCEE_Convention](@iID_Convention,@dtDate_Fin)
	SET @mSolde_BEC = [dbo].[fnPCEE_CalculerSoldeBEC_Convention](@iID_Convention,@dtDate_Fin)

	SET @mJVM_IQEE = @mJVM_Comptable - @mSolde_BEC - @mSolde_SCEE

	RETURN isNull(@mJVM_IQEE,0)
END



