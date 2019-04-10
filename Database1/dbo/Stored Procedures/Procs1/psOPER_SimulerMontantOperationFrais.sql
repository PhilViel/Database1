/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psOPER_SimulerMontantOperationFrais
Nom du service		: Simuler le montant total (avec taxes) d'une opération de frais.
But 				: Simuler le montant total (avec taxes) d'une opération de frais.
Facette				: OPER

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						vcCode_Type_Frais			Code du type de frais à créer.
						mMontant_Frais				Montant hors taxes du frais. Si non spécifié, le montant par défaut du
													type de frais sera utilisé.
											

Exemple d’appel		:	DECLARE	@return_value int,
								@mMontant_Frais_TTC money,
								@vcCode_Message varchar(10)
						EXEC	@return_value = [dbo].[psOPER_SimulerMontantOperationFrais]
								@vcCode_Type_Frais = N'CUI',
								@mMontant_Frais = null,
								@mMontant_Frais_TTC = @mMontant_Frais_TTC OUTPUT,
								@vcCode_Message = @vcCode_Message OUTPUT
						SELECT	@mMontant_Frais_TTC as N'@mMontant_Frais_TTC',
								@vcCode_Message as N'@vcCode_Message'
						SELECT	'Return Value' = @return_value

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							mMontant_Frais_TTC				Montant total de l'opération de frais.
						S/O							vcCode_Message					Message d'erreur lorsque le traitement
																					se fini à 0.
						S/O							iCode_Retour					 1 = Traitement réussi
																					 0 = Paramètres incomplets ou erronnés
																					-1 = Erreur non gérée

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-03-10		Corentin Menthonnex					Création du service							

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_SimulerMontantOperationFrais]
    (
      @vcCode_Type_Frais VARCHAR(10) ,
      @mMontant_Frais MONEY ,
      @mMontant_Frais_TTC MONEY OUTPUT ,
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
            
		-- Utiliser le montant du type de frais si le montant n'est pas fourni
        IF @mMontant_Frais IS NULL 
            SELECT TOP 1
                    @mMontant_Frais = tf.mMontant_Defaut
            FROM    tblOPER_TypesFrais tf

        BEGIN TRY
			-- Déclaration des variables
            DECLARE @iID_Type_Frais INT				-- Identifiant unique du type de frais utilisé pour simuler le frais.
            DECLARE @dDate_Simulation DATETIME		-- Date de simulation de l'opération.
            
            -- Initialisation des variables
            SET @dDate_Simulation = GETDATE()
            SET @mMontant_Frais_TTC = @mMontant_Frais
            SELECT TOP 1
                    @iID_Type_Frais = tf.iID_Type_Frais
            FROM    dbo.tblOPER_TypesFrais tf
            WHERE   tf.vcCode_Type_Frais = @vcCode_Type_Frais
                    
            -- Récupération des taxes applicables sur le frais que l'on veut simuler
            DECLARE @iID_Type_Parametre INT				-- Identifiant unique (ici des taxes) des paramètres associés au type de frais
            DECLARE @vcCode_Taxe VARCHAR(100)			-- Code de taxe applicable sur le type de frais
            DECLARE @vcTaux_Taxe VARCHAR(MAX)			-- Taux de la taxe applicable sur le type de frais
            DECLARE @mMontant_Taxe MONEY				-- Montant de la taxe
            DECLARE curTaxes_Applicables CURSOR LOCAL	-- Curseur pour trouver les taxes applicables au type de frais
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
                    FROM    dbo.fntGENE_ObtenirTypeParametre(@iID_Type_Parametre,
                                                             NULL) tp ;

					-- Récupération du taux de la taxe applicable
                    SET @vcTaux_Taxe = dbo.fnGENE_ObtenirParametre(@vcCode_Taxe,
                                                              @dDate_Simulation,
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
                                @dtDate_Application = @dDate_Simulation, -- datetime
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
                    SET @mMontant_Frais_TTC = ROUND(@mMontant_Frais_TTC, 2)
                        + ROUND(@mMontant_Taxe, 2)

					-- On cherche la taxe applicable suivante
                    FETCH NEXT FROM curTaxes_Applicables
					INTO @iID_Type_Parametre ;
                END

            CLOSE curTaxes_Applicables ;
            DEALLOCATE curTaxes_Applicables ;
                        
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

