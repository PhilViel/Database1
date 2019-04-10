/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psOPER_AnnulerOperationFrais
Nom du service		: Annuler une opération de frais.
But 				: Annuler une opération de frais et toutes ses composantes à partir de son identifiant.
Facette				: OPER

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Connexion				Identifiant unique de connexion de l'usager.
						iID_Oper_Origine			Identifiant unique de l'opération que l'on doit annuler.
						iID_Utilisateur				Identifiant unique de l'utilisateur qui engendré l'annulation du frais.   
								_Annulation			S’il n’est pas spécifié, le service considère l’utilisateur système.
											

Exemple d’appel		:	EXECUTE [dbo].[psOPER_AnnulerOperationFrais] 1

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							vcCode_Message					Message d'erreur lorsque le traitement 
																					se fini à 0.
						S/O							iCode_Retour					 1 = Traitement réussi
																					 0 = Paramètres incomplets ou erronnés
																					-1 = Erreur non gérée

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-02-28		Corentin Menthonnex					Création du service							

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_AnnulerOperationFrais]
    (
      @iID_Connexion INT ,
      @iID_Oper_Origine INT ,
      @iID_Utilisateur_Annulation INT ,
      @vcCode_Message VARCHAR(10) OUTPUT
    )
AS 
    BEGIN
    
        ---------------------------------------------------------------------------------------------
        -- Initialisation de la procédure
        ---------------------------------------------------------------------------------------------
		-- Retourner 0 s'il y a des paramètres manquants ou que l'opération n'existe pas
        IF @iID_Oper_Origine IS NULL
            OR NOT EXISTS ( SELECT  *
                            FROM    dbo.Un_Oper AS oper
                            WHERE   oper.OperID = @iID_Oper_Origine
                                    AND oper.OperTypeID = [dbo].[fnOPER_ObtenirTypesOperationCategorie]('OPER_TYPE_FRS') ) 
            BEGIN
                SET @vcCode_Message = 'GENEE0008'
                RETURN 0
            END
            
        -- Vérifier que l'opération que l'on veut annuler ne l'est pas déjà
        IF (SELECT f.dtDate_Annulation FROM dbo.tblOPER_Frais f WHERE f.iID_Oper = @iID_Oper_Origine) IS NOT NULL
            BEGIN
                SET @vcCode_Message = 'OPERE0022'
                RETURN 0
            END

		-- Utiliser l'utilisateur du système s'il est absent en paramètre
        IF @iID_Utilisateur_Annulation IS NULL
            OR @iID_Utilisateur_Annulation = 0
            OR NOT EXISTS ( SELECT  *
                            FROM    Mo_User utilisateur
                            WHERE   utilisateur.UserID = @iID_Utilisateur_Annulation ) 
            SELECT TOP 1
                    @iID_Utilisateur_Annulation = iID_Utilisateur_Systeme
            FROM    Un_Def


        SET XACT_ABORT ON 
        BEGIN TRANSACTION

        BEGIN TRY

            ---------------------------------------------------------------------------------------------
			-- Création de l'opération de type 'FRS' (Annulation)
            ---------------------------------------------------------------------------------------------
            DECLARE @iID_Oper_Annulation INT	-- Identifiant de l'opération d'annulation que l'on créer
            DECLARE @dtAnnulation DATETIME
            SET @dtAnnulation = GETDATE()  
            
            INSERT  INTO Un_Oper
                    ( OperTypeID ,
                      OperDate ,
                      ConnectID
                    )
            VALUES  ( [dbo].[fnOPER_ObtenirTypesOperationCategorie]('OPER_TYPE_FRS') , -- OperTypeID - MoOptionCode
                      @dtAnnulation , -- OperDate - MoGetDate
                      @iID_Connexion -- ConnectID - MoID
                    )
                    
            -- Récupération de l'identifiant unique de l'opération que l'on créer
            SET @iID_Oper_Annulation = SCOPE_IDENTITY()

			---------------------------------------------------------------------------------------------
			-- Création d'une occurence Un_OperCancelation
			---------------------------------------------------------------------------------------------
            INSERT  INTO dbo.Un_OperCancelation
                    ( OperSourceID ,
                      OperID 
                    )
            VALUES  ( @iID_Oper_Origine , -- OperSourceID - MoID
                      @iID_Oper_Annulation  -- OperID - MoID
                    ) ;			

			---------------------------------------------------------------------------------------------
			-- Annulation des frais et de leurs taxes
			---------------------------------------------------------------------------------------------
			-- Récupération des frais liés à l'opération
            DECLARE @iID_Frais_Annulation INT		-- Identifiant unique du frais d'annulation que l'on créer
            DECLARE @iID_Frais_Origine INT			-- Identifiant unique d'un frais appartenant à l'opération originale
            DECLARE @iID_Type_frais INT
            DECLARE @mMontant_Frais MONEY          
            
            DECLARE curFrais CURSOR LOCAL
            FOR
                SELECT  frais.iID_Frais ,
                        frais.iID_Type_Frais ,
                        frais.mMontant_Frais
                FROM    dbo.tblOPER_Frais frais
                WHERE   frais.iID_Oper = @iID_Oper_Origine ;

            OPEN curFrais ;

			--On parcours les frais de l'opération
            FETCH NEXT FROM curFrais
			INTO @iID_Frais_Origine, @iID_Type_frais, @mMontant_Frais ;

            WHILE @@FETCH_STATUS = 0 
                BEGIN
                
					---------------------------------------------------------------------------------------------
					-- Annulation des frais de l'opération
					---------------------------------------------------------------------------------------------
					-- Annulation du frais initial
                    UPDATE  dbo.tblOPER_Frais
                    SET     iID_Utilisateur_Annulation = @iID_Utilisateur_Annulation ,
                            dtDate_Annulation = @dtAnnulation
                    WHERE   dbo.tblOPER_Frais.iID_Frais = @iID_Frais_Origine ;
					
					-- Création du frais d'annulation en se basant sur le frais d'origine trouvé
                    INSERT  INTO dbo.tblOPER_Frais
                            ( iID_Oper ,
                              iID_Type_Frais ,
                              mMontant_Frais ,
                              iID_Utilisateur_Creation ,
                              dtDate_Creation ,
                              iID_Utilisateur_Annulation ,
                              dtDate_Annulation
					        
                            )
                    VALUES  ( @iID_Oper_Annulation , -- iID_Oper - int
                              @iID_Type_frais , -- iID_Type_Frais - int
                              ROUND(@mMontant_Frais * -1,2) , -- mMontant_Frais - money
                              @iID_Utilisateur_Annulation , -- iID_Utilisateur_Creation - int
                              @dtAnnulation , -- dtDate_Creation - datetime
                              NULL , -- iID_Utilisateur_Annulation - int
                              NULL  -- dtDate_Annulation - datetime
					        
                            ) ;
                    
					-- Récupération de l'identifiant unique du frais que l'on créer
                    SET @iID_Frais_Annulation = SCOPE_IDENTITY()
					
                
					---------------------------------------------------------------------------------------------
					-- Annulation des taxes appliquées sur le frais en se basant sur les taxes d'origine
					---------------------------------------------------------------------------------------------
					-- Récupération des taxes appliquées sur le frais courant
                    DECLARE @iID_Type_Parametre INT
                    DECLARE @mMontant_Taxe MONEY
                    DECLARE curTaxes CURSOR LOCAL
                    FOR
                        SELECT  fraisTaxes.iID_Type_Parametre ,
                                fraisTaxes.mMontant_Taxe
                        FROM    dbo.tblOPER_FraisTaxes fraisTaxes
                        WHERE   fraisTaxes.iID_Frais = @iID_Frais_Origine ;

                    OPEN curTaxes ;

					--On parcours les taxes du frais courant
                    FETCH NEXT FROM curTaxes
					INTO @iID_Type_Parametre, @mMontant_Taxe ;

                    WHILE @@FETCH_STATUS = 0 
                        BEGIN
						
							-- Annulation des taxes appliquées sur le frais courant
                            INSERT  INTO dbo.tblOPER_FraisTaxes
                                    ( iID_Frais ,
                                      iID_Type_Parametre ,
                                      mMontant_Taxe
									
                                    )
                            VALUES  ( @iID_Frais_Annulation , -- iID_Frais - int
                                      @iID_Type_Parametre , -- iID_Type_Parametre - int
                                      ROUND(@mMontant_Taxe * -1,2)  -- mMontant_Taxe - money
									
                                    ) ;
									
							-- On cherche la taxe suivante appliquée sur le frais
                            FETCH NEXT FROM curTaxes
							INTO @iID_Type_Parametre,
                                @mMontant_Taxe ;
							
                        END
                
					-- On cherche le frais suivant
                    FETCH NEXT FROM curFrais
					INTO @iID_Frais_Origine, @iID_Type_frais,
                        @mMontant_Frais ;
                END

            CLOSE curTaxes ;
            DEALLOCATE curTaxes ;
            
            CLOSE curFrais ;
            DEALLOCATE curFrais ;
			
			---------------------------------------------------------------------------------------------
			-- Annulation des transactions de l'opération
			---------------------------------------------------------------------------------------------				
			-- Création des transactions d'annulation en se basant sur les transactions originales
            INSERT  INTO dbo.Un_Cotisation
                    ( OperID ,
                      UnitID ,
                      EffectDate ,
                      Cotisation ,
                      Fee ,
                      BenefInsur ,
                      SubscInsur ,
                      TaxOnInsur
                    )
            SELECT  @iID_Oper_Annulation,
					cotisations.UnitID ,
					EffectDate,
					cotisations.Cotisation * -1 ,
					cotisations.Fee *-1 ,
					cotisations.BenefInsur *-1 ,
					cotisations.SubscInsur*-1 ,
					cotisations.TaxOnInsur*-1
			FROM    dbo.Un_Cotisation cotisations
			WHERE   cotisations.OperID = @iID_Oper_Origine ;

            COMMIT TRANSACTION
        END TRY
        
        BEGIN CATCH
			-- Lever l'erreur et faire le rollback
            DECLARE @ErrorMessage NVARCHAR(4000) ,
                @ErrorSeverity INT ,
                @ErrorState INT

            SET @ErrorMessage = ERROR_MESSAGE()
            SET @ErrorSeverity = ERROR_SEVERITY()
            SET @ErrorState = ERROR_STATE()

            IF ( XACT_STATE() ) = -1
                AND @@TRANCOUNT > 0 
                ROLLBACK TRANSACTION

            RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG ;

			-- Retourner -1 en cas d'erreur non gérée de traitement
            RETURN -1
        END CATCH

		-- Retourner 1 en cas de réussite du traitement
        RETURN 1
    END

