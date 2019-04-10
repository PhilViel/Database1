/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_PayerIQEE_ImpotsSpeciaux
Nom du service		: Enregistrer la securite
But 				: Injecter les montants dans les conventions et 
					  Insérer les numéros d’opérations dans la table tblIQEE_ImpotsSpeciaux
Facette				: IQEE
Référence			: IQEE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@iID_Fichier_IQEE			ID du fichier a traiter

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Exemple utilisation:																					
	- modification courriel
		EXEC psIQEE_PayerIQEE_ImpotsSpeciaux 175,602654
			
TODO:

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2012-08-08		Eric Michaud						Création du service		
		2012-08-24		Stéphane Barbeau					Ajustement du select du curseur CurseurAnnee pour ne pas tenir compte des impôts spéciaux à 0$.
		2012-08-24		Stéphane Barbeau					Ajout de conditions pour empêcher l'insertion d'opérations à 0$ dans Un_ConventionOper.																		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_PayerIQEE_ImpotsSpeciaux]
	@iID_Fichier_IQEE INT,
	@iID_Utilisateur_Creation INT
AS
BEGIN
	SET NOCOUNT ON;
		
	DECLARE	@iID_Sous_Type_01 INT,
		@iID_Connexion INT,
		@dtDate_Operation DATETIME,
		@iID_Sous_Type_22 INT,
		@iID_Sous_Type_91 INT,
		@cID_Type_Operation CHAR(3),
		@iID_ImpotSpecial INT, 
		@iID_Convention INT, 
		@mSolde_IQEE_Base MONEY,
		@msolde_IQEE_Majore MONEY,
		@vcOPER_MONTANTS_CREDITBASE VARCHAR(100),
		@vcOPER_MONTANTS_MAJORATION VARCHAR(100),
		@iID_Operation INT,
		@iID_Transaction_Convention INT
			
	select @dtDate_Operation = getdate()
			
	-- Initialiser le sous type de transaction
	SELECT @iID_Sous_Type_01 = iID_Sous_Type
	FROM tblIQEE_SousTypeEnregistrement ST
		 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = ST.tiID_Type_Enregistrement
	WHERE TE.cCode_Type_Enregistrement = '06'
	  AND ST.cCode_Sous_Type = '01'

	SELECT @iID_Sous_Type_22 = iID_Sous_Type
	FROM tblIQEE_SousTypeEnregistrement ST
		 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = ST.tiID_Type_Enregistrement
	WHERE TE.cCode_Type_Enregistrement = '06'
	  AND ST.cCode_Sous_Type = '22'

	SELECT @iID_Sous_Type_91 = iID_Sous_Type
	FROM tblIQEE_SousTypeEnregistrement ST
		 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = ST.tiID_Type_Enregistrement
	WHERE TE.cCode_Type_Enregistrement = '06'
	  AND ST.cCode_Sous_Type = '91'
	 
	-- Trouver la dernière connection de l'utilisateur
	SELECT @iID_Connexion = MAX(CO.ConnectID)
	FROM Mo_Connect CO
	WHERE CO.UserID = @iID_Utilisateur_Creation
  
	-- Déterminer le code d'opération
	SET @cID_Type_Operation = [dbo].[fnOPER_ObtenirTypesOperationCategorie]('IQEE_CODE_INJECTION_MONTANT_CONVENTION')
	SET @vcOPER_MONTANTS_CREDITBASE = [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('OPER_MONTANTS_CREDITBASE')
	SET @vcOPER_MONTANTS_MAJORATION = [dbo].[fnOPER_ObtenirTypesOperationConvCategorie]('OPER_MONTANTS_MAJORATION')

	
	DECLARE CurseurAnnee CURSOR FOR
		SELECT IPS.iID_Impot_Special,IPS.iID_Convention,IPS.mSolde_IQEE_Base,IPS.mSolde_IQEE_Majore FROM tblIQEE_ImpotsSpeciaux IPS
		WHERE  IPS.iID_Sous_Type IN (@iID_Sous_Type_01,@iID_Sous_Type_22,@iID_Sous_Type_91)
			   AND IPS.iID_Fichier_IQEE = @iID_Fichier_IQEE
			   AND IPS.mIQEE_ImpotSpecial > 0
			   AND IPS.tiCode_Version = 0
			   AND IPS.cStatut_Reponse = 'A'

	OPEN CurseurAnnee
	FETCH NEXT FROM CurseurAnnee INTO @iID_ImpotSpecial,@iID_Convention,@mSolde_IQEE_Base,@msolde_IQEE_Majore


	WHILE @@FETCH_STATUS = 0
	BEGIN
	
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


		FETCH NEXT FROM CurseurAnnee INTO @iID_ImpotSpecial,@iID_Convention,@mSolde_IQEE_Base,@msolde_IQEE_Majore
	END
	CLOSE CurseurAnnee
	DEALLOCATE CurseurAnnee
	
END



