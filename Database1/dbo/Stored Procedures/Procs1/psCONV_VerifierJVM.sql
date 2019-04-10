/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psCONV_VerifierJVM
Nom du service		: Vérifie la Juste Valeur Marchande de la convention avant une opération
But 				: Vérifie la Juste Valeur Marchande de la convention avant une opération, la JVM ne doit pas 
					  être inférieure au montant minimum.
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Utilisateur				Identifiant unique de l'utilisateur.
						iID_Convention				Obligatoire - Identifiant unique de la convention concernée.
						cCode_Type_Retrait			Code unique du type de retrait à effectuer, NON UTILISÉ pour l'instant.
						mMontant_Operation			Obligatoire - Montant de l'opération prévue (à passer en négatif si 
													c'est un retrait et en positif si c'est un dépôt).

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						N/A							iCode_Retour					= 1 si JVM respecte le montant 
																					minimum
																					= 0 erreur gérée
																					= - 1 si erreur de traitement
						N/A							vcCode_Message					Message de retour lorsque le traitement
																					se termine à 0.
	
Exemple d'appel : EXECUTE [dbo].[psCONV_VerifierJVM] 1, 'PAE', -40.55

Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2011-03-08		Corentin Menthonnex			Création du service
		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_VerifierJVM]
    (
      @iID_Utilisateur INT ,
      @iID_Convention INT ,
      @cCode_Type_Retrait CHAR(3) ,
      @mMontant_Operation MONEY ,
      @vcCode_Message VARCHAR(10) OUTPUT	
    )
AS 
    BEGIN
    
        ---------------------------------------------------------------------------------------------
        -- Initialisation de la procédure
        ---------------------------------------------------------------------------------------------  
        -- Si le montant passé est null, déclencher une erreur
        IF @mMontant_Operation IS NULL
			OR @iID_Convention IS NULL
			BEGIN
				SET @vcCode_Message = 'GENEE0020'
				RETURN 0;
			END
                  
		-- Utiliser l'utilisateur du système s'il est absent en paramètre
        IF @iID_Utilisateur IS NULL
            OR @iID_Utilisateur = 0
            OR NOT EXISTS ( SELECT  *
                            FROM    Mo_User utilisateur
                            WHERE   utilisateur.UserID = @iID_Utilisateur ) 
            SELECT TOP 1
                    @iID_Utilisateur = iID_Utilisateur_Systeme
            FROM    Un_Def
    
        BEGIN TRY
			-- Récupération du montant minimum
            DECLARE @mMontant_Minimum MONEY ;
            SET @mMontant_Minimum = dbo.fnGENE_ObtenirParametre('CONV_MONTANT_MINIMUM',
                                                              NULL, NULL, NULL,
                                                              NULL, NULL, NULL)

			-- Si le montant de la JVM est correcte
            IF ( ( dbo.fnCONV_CalculerJVM(@iID_Convention)
                   + @mMontant_Operation ) >= @mMontant_Minimum ) 
                RETURN 1 ;
            
            -- Si le montant de la JVM est incorrecte    
            ELSE 
                BEGIN
					-- Si l'utilisateur peut bypasser la vérification
                    IF ( dbo.fnSECU_ObtenirAccessibiliteDroitUtilisateur(@iID_Utilisateur,
                                                              'CONV_SURPASSER_VERIFICATION_JVM') = 1 ) 
                        SET @vcCode_Message = 'CONVQ0011';
                    -- Si l'utilisateur n'as pas les accès de bypass
                    ELSE 
                        SET @vcCode_Message = 'CONVE0026';
                END
                
            -- Si on arrive ici c'est que la JVM est incorrecte.
            RETURN 0 ;
	        
        END TRY
        
        BEGIN CATCH
			-- Lever l'erreur et faire le rollback
            DECLARE @ErrorMessage NVARCHAR(4000) ,
                @ErrorSeverity INT ,
                @ErrorState INT

            SET @ErrorMessage = ERROR_MESSAGE()
            SET @ErrorSeverity = ERROR_SEVERITY()
            SET @ErrorState = ERROR_STATE()

            RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG ;

			-- Retourner -1 en cas d'erreur non gérée de traitement
            RETURN -1
        END CATCH
    END

