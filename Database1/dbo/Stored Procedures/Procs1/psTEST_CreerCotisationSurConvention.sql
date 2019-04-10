/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEST_CreerCotisationSurConvention
Nom du service		: CreerOperationSurConvention
But 				: Créer une nouvelle opération sur une convention à partir d'une opération financière existante
Facette				: TEST

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Convention				Identifiant unique de la convention pour laquelle le calcul est
													demandé.
						iID_OperationID


Exemple d’appel		:	EXECUTE [dbo].[psTEST_CreerCotisationSurConvention] 2008, 546658

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					> 0 = Identifiant de la nouvelle
																						  série de paramètres
																					-1 = Absence du paramètre
																						 « siAnnee_Fiscale »
																					-2 = Erreur de traitement

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-03-12		Stéphane Barbeau					Création du service							

		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEST_CreerCotisationSurConvention] 
(
	@iID_Operation INT,
	@iID_UnitID INT,
	@dtEffectDate datetime,
	@mCotisation MONEY,
	@mFee MONEY,
	@mBenefInsur Money,
	@SubscInsur Money,
	@TaxOnInsur Money
)

AS
BEGIN
	Declare @iID_Transaction_Convention int

INSERT INTO [UnivBase_1_FONC].[dbo].[Un_Cotisation]
           ([OperID]
           ,[UnitID]
           ,[EffectDate]
           ,[Cotisation]
           ,[Fee]
           ,[BenefInsur]
           ,[SubscInsur]
           ,[TaxOnInsur])
     VALUES
           (@iID_Operation
           ,@iID_UnitID
           ,@dtEffectDate
           ,@mCotisation
           ,@mFee
           ,@mBenefInsur 
           ,@SubscInsur 
           ,@TaxOnInsur)
	
	
			SET @iID_Transaction_Convention = SCOPE_IDENTITY()
						
			SELECT * from Un_Cotisation where CotisationID = @iID_Transaction_Convention
		END

	RETURN @iID_Transaction_Convention 


