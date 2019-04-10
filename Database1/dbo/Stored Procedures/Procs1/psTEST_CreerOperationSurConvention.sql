/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psTEST_CreerOperationSurConvention
Nom du service		: CreerOperationSurConvention
But 				: Créer une nouvelle opération sur une convention à partir d'une opération financière existante
Facette				: TEST

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Convention				Identifiant unique de la convention pour laquelle le calcul est
													demandé.
						iID_OperationID


Exemple d’appel		:	EXECUTE [dbo].[psTEST_CreerOperationSurConvention] 2008, 546658

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
CREATE PROCEDURE [dbo].[psTEST_CreerOperationSurConvention] 
(
	@iID_Convention INT,
	@iID_Operation INT,
	@cID_Type_Operation char(5),
	@iID_Cotisation int,
	@iID_OperSourceID int,
	@mMontant MONEY
)

AS
BEGIN
	Declare @iID_Transaction_Convention int
	
	
	If @cID_Type_Operation = 'BEC'
	BEGIN
				INSERT INTO [dbo].[Un_CESP]
					   ([ConventionID]
					   ,[OperID]
					   ,[CotisationID]
					   ,[OperSourceID]
					   ,[fCESG]
					   ,[fACESG]
					   ,[fCLB]
					   ,[fCLBFee]
					   ,[fPG]
					   ,[vcPGProv]
					   ,[fCotisationGranted])
				 VALUES
					   (@iID_Convention 
					   ,@iID_Operation
					   ,@iID_Cotisation 
					   ,@iID_OperSourceID  -- ID unique de l'opération qui a fait le mouvement de cotisation qui a provoqué des entrées ou sorties d'argent du PCEE
					   ,0
					   ,0
					   ,@mMontant
					   ,0  -- à clarifier Frais reçu pour la gestion du BEC
					   ,0
					   ,NULL
					   ,0)
					   
				SET @iID_Transaction_Convention = SCOPE_IDENTITY()
				
										  
	END
	ELSE IF  @cID_Type_Operation = 'SCEE'
		BEGIN
				INSERT INTO [dbo].[Un_CESP]
					   ([ConventionID]
					   ,[OperID]
					   ,[CotisationID]
					   ,[OperSourceID]
					   ,[fCESG]
					   ,[fACESG]
					   ,[fCLB]
					   ,[fCLBFee]
					   ,[fPG]
					   ,[vcPGProv]
					   ,[fCotisationGranted])
				 VALUES
					 (@iID_Convention 
					   ,@iID_Operation
					   ,@iID_Cotisation 
					   ,@iID_OperSourceID  -- ID unique de l'opération qui a fait le mouvement de cotisation qui a provoqué des entrées ou sorties d'argent du PCEE
					   ,@mMontant
					   ,0
					   ,0
					   ,0  -- à clarifier Frais reçu pour la gestion du BEC
					   ,0
					   ,NULL
					   ,0)
					 
					 
				SET @iID_Transaction_Convention = SCOPE_IDENTITY()
				
				SELECT * FROM Un_CESP where iCESPID = @iID_Transaction_Convention
				
		
		END

	ELSE IF  @cID_Type_Operation = 'SCEE+'
		BEGIN
			
				INSERT INTO [dbo].[Un_CESP]
					   ([ConventionID]
					   ,[OperID]
					   ,[CotisationID]
					   ,[OperSourceID]
					   ,[fCESG]
					   ,[fACESG]
					   ,[fCLB]
					   ,[fCLBFee]
					   ,[fPG]
					   ,[vcPGProv]
					   ,[fCotisationGranted])
				 VALUES
					 (@iID_Convention 
					   ,@iID_Operation
					   ,@iID_Cotisation 
					   ,@iID_OperSourceID  -- ID unique de l'opération qui a fait le mouvement de cotisation qui a provoqué des entrées ou sorties d'argent du PCEE
					   ,0
					   ,@mMontant
					   ,0
					   ,0  -- à clarifier Frais reçu pour la gestion du BEC
					   ,0
					   ,NULL
					   ,0)
					 
					   
					   SET @iID_Transaction_Convention = SCOPE_IDENTITY()
					   
					   SELECT * FROM Un_CESP where iCESPID = @iID_Transaction_Convention
		END

	ELSE
		BEGIN
				INSERT INTO [dbo].[Un_ConventionOper]
								   ([OperID]
								   ,[ConventionID]
								   ,[ConventionOperTypeID]
								   ,[ConventionOperAmount])
						 VALUES
								   (@iID_Operation
								   ,@iID_Convention
								   ,@cID_Type_Operation
								   ,@mMontant)
						SET @iID_Transaction_Convention = SCOPE_IDENTITY()
						
						SELECT * from Un_ConventionOper where ConventionOperID = @iID_Transaction_Convention
		END

	
END

