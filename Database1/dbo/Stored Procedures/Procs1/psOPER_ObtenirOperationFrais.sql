/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psOPER_ObtenirOperationFrais
Nom du service		: Obtenir une opération de frais.
But 				: Obtenir une opération de frais ou d'annulation de frais.
Facette				: OPER

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Oper					Identifiant unique de l'opération que l'on chercher à obtenir
													l'opération doit être de type FRS.

Exemple d’appel		:	EXECUTE [dbo].psOPER_ObtenirOperationFrais 1111

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						tblOPER_Frais				vcID_Oper_Type					Type de l'opération (FRS).
    					tblOPER_Type_Frais			vcDescription_Type_Frais		Description du type du frais.
    					tblOPER_Frais				mMontant_Operation				Montant du frais (avec taxes).
    					Un_Human					vcUtilisateur_Creation			Prénom + Nom de l'utilisateur ayant
    																				créé le frais.
    					tblOPER_Frais				dtDate_Creation					Date de création du frais.
    					Un_Oper						dtDate_Operation				Date de l'opération
    					Un_Human					vcUtilisateur_Annulation		Prénom + Nom de l'utilisateur ayant
    																				annulé le frais.
    					tblOPER_Frais				dtDate_Annulation				Date d'annulation du frais.
    					Un_OperCancelation			iID_Oper_Annule					Identifiant de l'opération annulée
    																				par ce frais (si c'est une operétion 
    																				d'annulation)
						S/O							vcCode_Message					Message d'erreur lorsque le traitement
																					se fini à 0.
						S/O							iCode_Retour					 0 = Paramètres incomplets ou erronnés
																					-1 = Erreur non gérée

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-03-02		Corentin Menthonnex					Création du service							

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_ObtenirOperationFrais]
    (
      @iID_Oper INT /*,
      @vcID_Oper_Type CHAR(3) OUTPUT ,
      @vcDescription_Type_Frais VARCHAR(250) OUTPUT ,
      @mMontant_Operation MONEY OUTPUT ,
      @vcUtilisateur_Creation VARCHAR(250) OUTPUT ,
      @dtDate_Creation DATETIME OUTPUT ,
      @dtDate_Operation DATETIME OUTPUT ,
      @vcUtilisateur_Annulation VARCHAR(250) OUTPUT ,
      @dtDate_Annulation DATETIME OUTPUT ,
      @iID_Oper_Annule INT OUTPUT ,
      @vcCode_Message VARCHAR(10) OUTPUT*/
    )
AS 
    BEGIN

        ---------------------------------------------------------------------------------------------
        -- Initialisation de la procédure
        ---------------------------------------------------------------------------------------------
		-- Retourner 0 s'il y a des paramètres manquants ou que l'opération n'existe pas
        /*IF @iID_Oper IS NULL
            OR NOT EXISTS ( SELECT  *
                            FROM    dbo.Un_Oper AS oper
                            WHERE   oper.OperID = @iID_Oper
                                    AND oper.OperTypeID = 'FRS' ) 
            BEGIN
                SET @vcCode_Message = 'GENEE0008' ;
                RETURN 0 ;
            END*/
            
        BEGIN TRY
        
            DECLARE 
            @iID_Utilisateur_Creation	INT,
            @iID_Utilisateur_Annulation INT,
            @iID_Frais					INT,
            @vcID_Oper_Type				CHAR(3),
			@vcDescription_Type_Frais	VARCHAR(250),
			@mMontant_Operation			MONEY,
			@vcUtilisateur_Creation		VARCHAR(250),
			@dtDate_Creation			DATETIME,
			@dtDate_Operation			DATETIME,
			@vcUtilisateur_Annulation	VARCHAR(250),
			@dtDate_Annulation			DATETIME,
			@iID_Oper_Annule			INT,
			@vcCode_Message				VARCHAR(10);
        
			---------------------------------------------------------------------------------------------
			-- Remplissage des paramètres de sortie
			---------------------------------------------------------------------------------------------
			-- Récupération des données de l'opération
            SELECT  @vcID_Oper_Type = o.OperTypeID ,
                    @dtDate_Operation = o.OperDate
            FROM    dbo.Un_Oper o
            WHERE   o.OperID = @iID_Oper ;
			
            SELECT  @vcDescription_Type_Frais = tf.vcDescription_Type_Frais ,
                    @mMontant_Operation = f.mMontant_Frais , -- Montant du frais sans les taxes
                    @iID_Utilisateur_Creation = f.iID_Utilisateur_Creation ,
                    @dtDate_Creation = f.dtDate_Creation ,
                    @iID_Utilisateur_Annulation = f.iID_Utilisateur_Annulation ,
                    @dtDate_Annulation = f.dtDate_Annulation ,
                    @iID_Frais = f.iID_Frais
            FROM    dbo.tblOPER_Frais f
                    INNER JOIN dbo.tblOPER_TypesFrais tf ON tf.iID_Type_Frais = f.iID_Type_Frais
            WHERE   f.iID_Oper = @iID_Oper ;
            
            EXECUTE @vcUtilisateur_Creation = dbo.fn_Mo_HumanName @iID_Utilisateur_Creation ;
            EXECUTE @vcUtilisateur_Annulation = dbo.fn_Mo_HumanName @iID_Utilisateur_Annulation ;

			-- Ajout des taxes au montant du frais
            SET @mMontant_Operation = @mMontant_Operation
                + ( SELECT  SUM(ft.mMontant_Taxe)
                    FROM    dbo.tblOPER_Frais f
                            INNER JOIN dbo.tblOPER_FraisTaxes ft ON ft.iID_Frais = f.iID_Frais
                    WHERE   f.iID_Frais = @iID_Frais
                  ) ;
			
			-- Récupération de l'identifiant de l'opération annulée par l'opération courante si on est dans le cas
			-- d'une opération d'annulation de frais
            SET @iID_Oper_Annule = NULL ;
            SET @iID_Oper_Annule = ( SELECT oc.OperSourceID
                                     FROM   dbo.Un_OperCancelation oc
                                     WHERE  oc.OperID = @iID_Oper
                                   )
                
            -- Retour des informations
            SELECT 
				@vcID_Oper_Type				as 'vcID_Oper_Type',
				@vcDescription_Type_Frais	as 'vcDescription_Type_Frais',
				@mMontant_Operation			as 'mMontant_Operation',
				@vcUtilisateur_Creation		as 'vcUtilisateur_Creation',
				@dtDate_Creation			as 'dtDate_Creation',
				@dtDate_Operation			as 'dtDate_Operation',
				@vcUtilisateur_Annulation	as 'vcUtilisateur_Annulation',
				@dtDate_Annulation			as 'dtDate_Annulation',
				@iID_Oper_Annule			as 'iID_Oper_Annule',
				@vcCode_Message				as 'vcCode_Message';
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
            --RETURN -1
        END CATCH

		-- Retourner 1 en cas de réussite du traitement
        --RETURN 1
    END

