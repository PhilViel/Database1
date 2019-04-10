/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psOPER_SupprimerOperationFrais
Nom du service		: Supprimer une opération de frais.
But 				: Supprimer une opération de frais et toutes ses composantes à partir de son identifiant.
Facette				: OPER

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Oper					Identifiant unique de connexion de l'usager.
											

Exemple d’appel		:	EXECUTE [dbo].[psOPER_SupprimerOperationFrais] 1

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
CREATE PROCEDURE [dbo].[psOPER_SupprimerOperationFrais]
    (
      @iID_Oper INT ,
      @vcCode_Message VARCHAR(10) OUTPUT
    )
AS 
    BEGIN
    
        ---------------------------------------------------------------------------------------------
        -- Initialisation de la procédure
        ---------------------------------------------------------------------------------------------
		-- Retourner 0 s'il y a des paramètres manquants ou que l'opération n'existe pas
        IF @iID_Oper IS NULL
            OR NOT EXISTS ( SELECT  *
                            FROM    dbo.Un_Oper AS oper
                            WHERE   oper.OperID = @iID_Oper
                                    AND oper.OperTypeID = 'FRS' ) 
            BEGIN
                SET @vcCode_Message = 'GENEE0008'
                RETURN 0
            END
            
        -- Vérifier que l'opération que l'on veut annuler ne l'est pas déjà
        IF (SELECT f.dtDate_Annulation FROM dbo.tblOPER_Frais f WHERE f.iID_Oper = @iID_Oper) IS NOT NULL
            BEGIN
                SET @vcCode_Message = 'OPERE0022'
                RETURN 0
            END


        SET XACT_ABORT ON 
        BEGIN TRANSACTION

        BEGIN TRY

			---------------------------------------------------------------------------------------------
			-- Suppression des frais et de leurs taxes
			---------------------------------------------------------------------------------------------
			-- Récupération des identifiants de frais liés à l'opération
            DECLARE @iID_Frais INT			-- Identifiant unique d'un frais appartenant à l'opération
            DECLARE curFrais CURSOR LOCAL
            FOR
                SELECT  frais.iID_Frais
                FROM    dbo.tblOPER_Frais frais
                WHERE   frais.iID_Oper = @iID_Oper ;

            OPEN curFrais ;

			--On parcours les frais de l'opération
            FETCH NEXT FROM curFrais
			INTO @iID_Frais ;

            WHILE @@FETCH_STATUS = 0 
                BEGIN
                
					-- Suppression des taxes appliquées sur le frais courant
                    DELETE  FROM dbo.tblOPER_FraisTaxes
                    WHERE   dbo.tblOPER_FraisTaxes.iID_Frais = @iID_Frais ;
                        
                    -- Suppression du frais courant
                    DELETE  FROM dbo.tblOPER_Frais
                    WHERE   dbo.tblOPER_Frais.iID_Frais = @iID_Frais ;
                
					-- On cherche le frais suivant
                    FETCH NEXT FROM curFrais
					INTO @iID_Frais ;
                END

            CLOSE curFrais ;
            DEALLOCATE curFrais ;
			
			---------------------------------------------------------------------------------------------
			-- Suppression des transactions de l'opération
			---------------------------------------------------------------------------------------------
            DELETE  FROM dbo.Un_Cotisation
            WHERE   dbo.Un_Cotisation.OperID = @iID_Oper ;
			
			---------------------------------------------------------------------------------------------
			-- Suppression de l'opération
			---------------------------------------------------------------------------------------------
            DELETE  FROM dbo.Un_Oper
            WHERE   dbo.Un_Oper.OperID = @iID_Oper ;

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

