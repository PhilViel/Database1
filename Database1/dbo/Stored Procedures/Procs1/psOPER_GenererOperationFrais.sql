/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psOPER_GenererOperationFrais
Nom du service		: Ajouter une opération de frais.
But 				: Ajouter une opération de frais.
Facette				: OPER

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Connexion				Identifiant unique de connexion de l'usager.
						iID_Convention				Identifiant unique de la convention
						vcCode_Type_Frais			Code du type de frais à créer.
						mMontant_Frais				Montant hors taxes du frais. Si non spécifié, le montant par défaut du
													type de frais sera utilisé.
						iID_Utilisateur_			Identifiant unique de l'utilisateur qui engendré la création du frais.   
								Creation			S’il n’est pas spécifié, le service considère l’utilisateur système.
						dtDate_Operation				Date de l'opération (Date comptable)
						dtDate_Effective				Date effective (pour les conventions)
											

Exemple d’appel		:	DECLARE	@return_value int,
								@iID_Oper int,
								@vcCode_Message varchar(10)
						EXEC	@return_value = [dbo].[psOPER_GenererOperationFrais]
								@iID_Connexion = -666,
								@iID_Convention = 373347,
								@vcCode_Type_Frais = 'CUI',
								@mMontant_Frais = NULL,
								@iID_Utilisateur_Creation = 606354,
								@iID_Oper = @iID_Oper OUTPUT,
								@vcCode_Message = @vcCode_Message OUTPUT
						SELECT	@iID_Oper as '@iID_Oper',
								@vcCode_Message as N'@vcCode_Message'
						SELECT	'Return Value' = @return_value

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iID_Oper						Identifiant unique de l'opération générée
																					se fini à 0.
						S/O							vcCode_Message					Message d'erreur lorsque le traitement
																					se fini à 0.
						S/O							iCode_Retour					 1 = Traitement réussi
																					 0 = Paramètres incomplets ou erronnés
																					-1 = Erreur non gérée

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-02-24		Corentin Menthonnex					Création du service							

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_GenererOperationFrais]
    (
      @iID_Connexion INT ,
      @iID_Convention INT ,
      @vcCode_Type_Frais VARCHAR(10) ,
      @mMontant_Frais MONEY ,
      @iID_Utilisateur_Creation INT ,
      @dtDate_Operation	DATETIME ,
      @dtDate_Effective DATETIME ,
      @iID_Oper INT OUTPUT ,
      @vcCode_Message VARCHAR(10) OUTPUT
    )
AS 
    BEGIN
    
        ---------------------------------------------------------------------------------------------
        -- Initialisation de la procédure
        ---------------------------------------------------------------------------------------------
		-- Retourner 0 s'il y a des paramètres manquants ou que le type de frais n'existe pas
        IF @vcCode_Type_Frais IS NULL
            OR NOT EXISTS ( SELECT  *
                            FROM    tblOPER_TypesFrais AS tf
                            WHERE   tf.vcCode_Type_Frais = @vcCode_Type_Frais ) 
            BEGIN
                SET @vcCode_Message = 'OPERE0020'
                RETURN 0
            END

		-- Utiliser l'utilisateur du système s'il est absent en paramètre
        IF @iID_Utilisateur_Creation IS NULL
            OR @iID_Utilisateur_Creation = 0
            OR NOT EXISTS ( SELECT  *
                            FROM    Mo_User utilisateur
                            WHERE   utilisateur.UserID = @iID_Utilisateur_Creation ) 
            SELECT TOP 1
                    @iID_Utilisateur_Creation = iID_Utilisateur_Systeme
            FROM    Un_Def
            
		-- Utiliser le montant du type de frais si le montant n'est pas fourni
        IF @mMontant_Frais IS NULL 
            SELECT TOP 1
                    @mMontant_Frais = tf.mMontant_Defaut
            FROM    tblOPER_TypesFrais tf
            
		-- Utiliser la dernière connexion du user si n'est pas fourni
        IF @iID_Connexion IS NULL 
            SELECT TOP 1
                    @iID_Connexion = c.ConnectID
            FROM    dbo.Mo_Connect c
            WHERE c.UserID = @iID_Utilisateur_Creation
            
        -- initialisation des dates si non fournies
        SET @dtDate_Operation = ISNULL(@dtDate_Operation, GETDATE());
        SET @dtDate_Effective = ISNULL(@dtDate_Effective, GETDATE());

        SET XACT_ABORT ON 
        BEGIN TRANSACTION

        BEGIN TRY
			-- Déclaration des variables
            DECLARE @vcType_Oper CHAR(3)			-- Type de l'opération que nous allons créer.
            DECLARE @iID_Frais INT					-- Identifiant unique du frais que nous allons créer.
            DECLARE @iID_Type_Frais INT				-- Identifiant unique du type de frais utilisé pour créer le frais.
            DECLARE @mMontant_Frais_TTC MONEY		-- Montant total du frais, inclus les taxes applicables.
            DECLARE @dtDate_Creation DATETIME		-- Date de création de l'opération.
            
            -- Initialisation des variables
            SET @vcType_Oper = [dbo].[fnOPER_ObtenirTypesOperationCategorie]('OPER_TYPE_FRS');
            SET @dtDate_Creation = GETDATE()
            SET @mMontant_Frais_TTC = @mMontant_Frais
            SELECT TOP 1
                    @iID_Type_Frais = tf.iID_Type_Frais
            FROM    dbo.tblOPER_TypesFrais tf
            WHERE   tf.vcCode_Type_Frais = @vcCode_Type_Frais
                   
            ---------------------------------------------------------------------------------------------
			-- Création de l'opération de type 'FRS' (Frais)
            ---------------------------------------------------------------------------------------------
            INSERT  INTO Un_Oper
                    ( OperTypeID ,
                      OperDate ,
                      ConnectID
                    )
            VALUES  ( @vcType_Oper , -- OperTypeID - MoOptionCode
                      @dtDate_Operation , -- OperDate - MoGetDate
                      @iID_Connexion -- ConnectID - MoID
                    )
                    
            -- Récupération de l'identifiant unique de l'opération que l'on créer
            SET @iID_Oper = SCOPE_IDENTITY()
        
            ---------------------------------------------------------------------------------------------
			-- Création du frais et de ses taxes
            ---------------------------------------------------------------------------------------------
            INSERT  INTO tblOPER_Frais
                    ( iID_Oper ,
                      iID_Type_Frais ,
                      mMontant_Frais ,
                      iID_Utilisateur_Creation ,
                      dtDate_Creation ,
                      iID_Utilisateur_Annulation ,
                      dtDate_Annulation
			        
                    )
            VALUES  ( @iID_Oper , -- iID_Oper - int
                      @iID_Type_Frais , -- iID_Type_Frais - int
                      ROUND(@mMontant_Frais,2) , -- mMontant_Frais - money
                      @iID_Utilisateur_Creation , -- iID_Utilisateur_Creation - int
                      @dtDate_Creation , -- dtDate_Creation - datetime
                      NULL , -- iID_Utilisateur_Annulation - int
                      NULL  -- dtDate_Annulation - datetime
                    )
            
            -- Récupération de l'identifiant unique du frais que l'on créer
            SET @iID_Frais = SCOPE_IDENTITY()
                    
            -- Récupération des taxes applicables sur le frais que l'on veut créer
            DECLARE @iID_Type_Parametre INT				-- Identifiant unique (ici des taxes) des paramètres associés au type de frais
            DECLARE @vcCode_Taxe VARCHAR(100)			-- Code de taxe applicable sur le type de frais
            DECLARE @vcTaux_Taxe VARCHAR(MAX)			-- Taux de la taxe applicable sur le type de frais
            DECLARE @mMontant_Taxe MONEY				-- Montant de la taxe
            DECLARE curTaxes_Applicables CURSOR	LOCAL	-- Curseur pour trouver les taxes applicables au type de frais
            FOR
                SELECT  ta.iID_Type_Parametre
                FROM    tblOPER_TypesFraisTaxesApplicables ta
                WHERE   ta.iID_Type_Frais = @iID_Type_Frais ;

            OPEN curTaxes_Applicables ;

			--On parcours les taxes applicables au type de frais
            FETCH NEXT FROM curTaxes_Applicables
			INTO @iID_Type_Parametre

            WHILE @@FETCH_STATUS = 0 
                BEGIN
					
					-- Récupération du code du type de paramètre courant (taxe)
                    SELECT  @vcCode_Taxe = tp.vcCode_Type_Parametre
                    FROM    dbo.fntGENE_ObtenirTypeParametre(@iID_Type_Parametre, NULL) tp ;

					-- Récupération du taux de la taxe applicable
                    SET @vcTaux_Taxe = dbo.fnGENE_ObtenirParametre(@vcCode_Taxe,
                                                              @dtDate_Operation,
                                                              NULL, NULL, NULL,
                                                              NULL, NULL) ;
                        
                    -- Calcul du montant de la taxe et mise à jour du montant du frais
                    IF @vcCode_Taxe = 'OPER_TAXE_TVQ' 
						-- Si la taxe que l'on veut calculer est la TVQ, il faut la calculer sur le montant du frais + le montant de la TPS
                        BEGIN
                            DECLARE @vcTauxTPS VARCHAR(MAX)
                            DECLARE @mMontantAvecTps MONEY
							-- Récupération du taux courant de la TPS
                            EXECUTE @vcTauxTPS = dbo.fnGENE_ObtenirParametre @vcCode_Type_Parametre = 'OPER_TAXE_TPS', -- varchar(100)
                                @dtDate_Application = @dtDate_Operation, -- datetime
                                @vcDimension1 = NULL, -- varchar(100)
                                @vcDimension2 = NULL, -- varchar(100)
                                @vcDimension3 = NULL, -- varchar(100)
                                @vcDimension4 = NULL, -- varchar(100)
                                @vcDimension5 = NULL -- varchar(100)
                            SET @mMontantAvecTps = @mMontant_Frais
                                + CONVERT(MONEY, @mMontant_Frais
                                * CONVERT(FLOAT, @vcTauxTPS) / 100)
                            SET @mMontant_Taxe = CONVERT(MONEY, @mMontantAvecTps
                                * CONVERT(FLOAT, @vcTaux_Taxe) / 100)
                        END
                    ELSE 
						-- Si la taxe que l'on veut calculer n'est pas la TVQ, le calcul se fait normalement
                        SET @mMontant_Taxe = CONVERT(MONEY, @mMontant_Frais
                            * CONVERT(FLOAT, @vcTaux_Taxe) / 100)
						
					-- Mise à jour du montant total du frais
                    SET @mMontant_Frais_TTC = @mMontant_Frais_TTC
                        + @mMontant_Taxe
					
					-- On créer la taxe applicable sur le frais
                    INSERT  INTO tblOPER_FraisTaxes
                            ( iID_Frais ,
                              iID_Type_Parametre ,
                              mMontant_Taxe
                            )
                    VALUES  ( @iID_Frais , -- iID_Frais - int
                              @iID_Type_Parametre , -- iID_Type_Parametre - int
                              ROUND(@mMontant_Taxe,2)  -- mMontant_Taxe - money
                            )

					-- On cherche la taxe applicable suivante
                    FETCH NEXT FROM curTaxes_Applicables
					INTO @iID_Type_Parametre ;
                END

            CLOSE curTaxes_Applicables ;
            DEALLOCATE curTaxes_Applicables ;
            
            ---------------------------------------------------------------------------------------------
            -- Création de la (ou des) transaction(s)
            ---------------------------------------------------------------------------------------------
            DECLARE @iID_Groupe_Unite INT
            DECLARE @dtDate_Debut_Operation DATETIME
            DECLARE @mMontant_Cotisations_Unite MONEY
            
			-- Récupération des groupes d'unités rattachés à la convention, du plus ancien au plus récent
            DECLARE curGroupes_Unites_Convention CURSOR LOCAL
            FOR
                SELECT  u.UnitID ,
                        u.InForceDate
                FROM    dbo.Un_Unit u
                WHERE   u.ConventionID = @iID_Convention
                ORDER BY u.InForceDate ASC
                    
            OPEN curGroupes_Unites_Convention ;

			--On parcours les groupes d'unités
            FETCH NEXT FROM curGroupes_Unites_Convention
			INTO @iID_Groupe_Unite, @dtDate_Debut_Operation
			
            WHILE @mMontant_Frais_TTC > 0
                AND @@FETCH_STATUS = 0 
                BEGIN
                	-- Calcul du montant total des cotisations restant dans l'unité
                    SELECT TOP 1
                            @mMontant_Cotisations_Unite = SUM(c.Cotisation)
                    FROM    Un_Cotisation AS c
                    WHERE   c.UnitID = @iID_Groupe_Unite
                	
      --          	-- Création de la transaction négative dans le groupe d'unité
      --              IF @mMontant_Frais_TTC > @mMontant_Cotisations_Unite 
						---- S'il n'y a pas assez d'argent dans l'unité courante
      --                  BEGIN
      --                      INSERT  INTO Un_Cotisation
      --                              ( OperID ,
      --                                UnitID ,
      --                                EffectDate ,
      --                                Cotisation ,
      --                                Fee ,
      --                                BenefInsur ,
      --                                SubscInsur ,
      --                                TaxOnInsur
                					
      --                              )
      --                      VALUES  ( @iID_Oper , -- OperID - MoID
      --                                @iID_Groupe_Unite , -- UnitID - MoID
      --                                @dtDate_Effective , -- EffectDate - MoGetDate
      --                                ROUND(@mMontant_Cotisations_Unite * -1,2) , -- Cotisation - MoMoney
      --                                0 , -- Fee - MoMoney
      --                                0 , -- BenefInsur - MoMoney
      --                                0 , -- SubscInsur - MoMoney
      --                                0  -- TaxOnInsur - MoMoney
      --                              )
      --                      SET @mMontant_Frais_TTC = @mMontant_Frais_TTC
      --                          - @mMontant_Cotisations_Unite
      --                  END
      --              ELSE
      --          		-- S'il y a assez d'argent dans l'unité courante
      --                  BEGIN
                            INSERT  INTO Un_Cotisation
                                    ( OperID ,
                                      UnitID ,
                                      EffectDate ,
                                      Cotisation ,
                                      Fee ,
                                      BenefInsur ,
                                      SubscInsur ,
                                      TaxOnInsur
                                    )
                            VALUES  ( @iID_Oper , -- OperID - MoID
                                      @iID_Groupe_Unite , -- UnitID - MoID
                                      @dtDate_Effective , -- EffectDate - MoGetDate
                                      ROUND(@mMontant_Frais_TTC * -1,2) , -- Cotisation - MoMoney
                                      0 , -- Fee - MoMoney
                                      0 , -- BenefInsur - MoMoney
                                      0 , -- SubscInsur - MoMoney
                                      0  -- TaxOnInsur - MoMoney
                                    )
                            SET @mMontant_Frais_TTC = 0
                        --END
                        
                    FETCH NEXT FROM curGroupes_Unites_Convention
					INTO @iID_Groupe_Unite, @dtDate_Debut_Operation
                END
                
            CLOSE curGroupes_Unites_Convention ;
            DEALLOCATE curGroupes_Unites_Convention ;
            
            -- Si on a retiré tout l'argent des cotisations et qu'il reste de l'argent dans les frais
            -- déclencher une erreur gérée et rollbacker la transaction
            IF @@FETCH_STATUS != 0
                AND @mMontant_Frais_TTC > 0 
                BEGIN
                    SET @vcCode_Message = 'OPERE0021'
                    ROLLBACK TRANSACTION
                    RETURN 0
                END

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

