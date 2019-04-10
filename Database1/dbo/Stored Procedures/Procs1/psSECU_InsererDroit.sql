
/****************************************************************************************************
Code de service		:		psSECU_InsererDroit
Nom du service		:		Insérer un droit   
But					:		Ajouter un droit dans le système.
                            
Facette				:		SECU 
Reférence			:		Services du noyau de la facette

Parametres d'entrée :	Parametres					              Description
                        ----------                                ----------------
                       lRightTypeID	                              Identifiant du type de droit
                       tRightCode	                              Code unique du droit.
                       tRightDesc	                              Nom du droit.
                       bRightVisible	                          Champs booléen indiquant si le droit est visible dans l'application (=0:Non, <>0:Oui).






Exemple d'appel: 
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       Mo_Right	                    RightID	                                    ID unique du droit créé
                                                                                                : > 0 l'ID du droit
                                                                                                : -1 Paramétres invalide
                                                                                                : -2 Code déja inséré 
																								: -3 Une erreur sql s'est produite                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-01-05					Fatiha Araar							Création de procédure stockée 
						2009-06-19					Jean-François Gauthier					Formatage de la requête                        
						2009-09-24					Jean-François Gauthier					Remplacement de @@Identity par Scope_Identity()
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psSECU_InsererDroit]
					@iRightTypeID	INT,
				    @tRightCode		VARCHAR(75),
				    @tRightDesc		VARCHAR(255),
				    @bRightVisible	BIT

AS
	BEGIN

		DECLARE @iResult	INT,
				@iCount		INT

		SET @iResult = 0 --Initialisation
		SET @iCount = 0

		--Validation des paramétres
		IF @iRightTypeID IS NOT NULL AND
		   @tRightCode IS NOT NULL AND
		   @tRightDesc IS NOT NULL AND
		   @bRightVisible IS NOT NULL

			BEGIN
				--Valider si RightCode Existe déja
				SELECT 
					@iCount = COUNT(*)
				FROM 
					dbo.Mo_Right 
				WHERE 
					RightCode = @tRightCode

				IF @iCount = 0 
					BEGIN
						 --Insérer le droit
						 INSERT INTO dbo.Mo_Right
								   (
									RightTypeID,
									RightCode,
									RightDesc,
									RightVisible
								   )
							  VALUES
								   (
									@iRightTypeID,
									@tRightCode,
									@tRightDesc,
									@bRightVisible
								   );
				         
							--Gestion des erreurs sql
							IF @@ERROR <> 0
							   SET @iResult = -3 --Une erreurs sql s'est produite lors de l'insersion 
							ELSE
							   SELECT @iResult = SCOPE_IDENTITY()
					END
				ELSE
					SET @iResult = -2 --Code déja existant
			END
		ELSE
			SET @iResult = -1 --Paramétres invalide

		RETURN @iResult
	END
