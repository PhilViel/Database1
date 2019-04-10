/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Nom du service		: psIQEE_CreerOperationFinanciereIQE_DeclarationImpotsSpeciaux

But 				: Créer l'opération IQE à afficher dans l'historique EAFB servant à décaisser ou encaisser 
					  les montants de crédit de base CBQ et de la majoration MMQ de l'IQEE dans la convention 
					  donnée et insérer les numéros d’opérations CBQ et MMQ dans la table tblIQEE_ImpotsSpeciaux 
					  qui sert à déclarer les impôts spéciaux.
					  
Facette				: IQEE
Référence			: IQEE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				
		  				
		  				

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Exemple utilisation:																					

		EXEC psIQEE_CreerOperationFinanciereIQE_DeclarationImpotsSpeciaux 175,602654
			


Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2012-12-07		Stéphane Barbeau						Création du service		
																		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_CreerOperationFinanciereIQE_DeclarationImpotsSpeciaux]
	@iID_Utilisateur_Creation INTEGER
	,@iID_Convention INTEGER
	,@iID_ImpotSpecial	INTEGER
	,@mSolde_IQEE_Base MONEY
	,@mSolde_IQEE_Majore MONEY
	
AS
BEGIN
	SET NOCOUNT ON;
		
	DECLARE	
		@iID_Connexion INT,
		@dtDate_Operation DATETIME,
		@cID_Type_Operation CHAR(3),
		@vcOPER_MONTANTS_CREDITBASE VARCHAR(100),
		@vcOPER_MONTANTS_MAJORATION VARCHAR(100),
		@iID_Operation INT,
		@iID_Transaction_Convention INT
			
	select @dtDate_Operation = getdate()
			
	-- Trouver la dernière connection de l'utilisateur
	SELECT @iID_Connexion = MAX(CO.ConnectID)
	FROM Mo_Connect CO
	WHERE CO.UserID = @iID_Utilisateur_Creation
  
	-- Déterminer le code d'opération
	SET @cID_Type_Operation = [dbo].[fnOPER_ObtenirTypesOperationCategorie]('IQEE_CODE_INJECTION_MONTANT_CONVENTION')
	SET @vcOPER_MONTANTS_CREDITBASE = [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('OPER_MONTANTS_CREDITBASE')
	SET @vcOPER_MONTANTS_MAJORATION = [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('OPER_MONTANTS_MAJORATION')

	
	
	-- Créer une nouvelle opération de subvention
	EXECUTE @iID_Operation = [dbo].[SP_IU_UN_Oper] @iID_Connexion, 0, @cID_Type_Operation, @dtDate_Operation

	IF @mSolde_IQEE_Base > 0
		BEGIN
			-- Injecter le montant dans la convention
			INSERT INTO [dbo].[Un_ConventionOper]
					   ([OperID]
					   ,[ConventionID]
					   ,[ConventionOperTypeID]
					   ,[ConventionOperAmount])
				 VALUES
					   (@iID_Operation
					   ,@iID_Convention
					   ,@vcOPER_MONTANTS_CREDITBASE
					   ,@mSolde_IQEE_Base * -1)
			SET @iID_Transaction_Convention = SCOPE_IDENTITY()

			-- Mettre à jour les identifiants de l'injection dans la réponse
			UPDATE [dbo].[tblIQEE_ImpotsSpeciaux]
				SET iID_Paiement_Impot_CBQ = @iID_Transaction_Convention
			WHERE iID_Impot_Special = @iID_ImpotSpecial
		END

	IF @mSolde_IQEE_Majore > 0
		BEGIN
			-- Injecter le montant dans la convention
			INSERT INTO [dbo].[Un_ConventionOper]
					   ([OperID]
					   ,[ConventionID]
					   ,[ConventionOperTypeID]
					   ,[ConventionOperAmount])
				 VALUES
					   (@iID_Operation
					   ,@iID_Convention
					   ,@vcOPER_MONTANTS_MAJORATION
					   ,@mSolde_IQEE_Majore * -1)
			SET @iID_Transaction_Convention = SCOPE_IDENTITY()

			-- Mettre à jour les identifiants de l'injection dans la réponse
			UPDATE [dbo].[tblIQEE_ImpotsSpeciaux]
				SET iID_Paiement_Impot_MMQ = @iID_Transaction_Convention
			WHERE iID_Impot_Special = @iID_ImpotSpecial
		END


	
END




