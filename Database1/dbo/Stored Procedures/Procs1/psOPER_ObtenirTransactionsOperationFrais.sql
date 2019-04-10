/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psOPER_ObtenirTransactionsOperationFrais
Nom du service		: Obtenir les transactions d'une opération de frais.
But 				: Obtenir les transactions d'une opération de frais ou d'annulation de frais.
Facette				: OPER

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Oper					Identifiant unique de l'opération dont on cherche à obtenir
													les transactions.

Exemple d’appel		:	EXECUTE [dbo].psOPER_ObtenirTransactionsOperationFrais 1111

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
													vcType_Transaction				Type de la transaction
																					si c’est une cotisation :
																						[Un_Convention.ConventionNo] + “ -> “ + [Un_Unit.InForceDate] + “ (“ + [Un_Unit.UnitQty] + “)“
																					si c’est une transaction sur la convention : 
																						[Un_Convention.ConventionNo]
						Un_Cotisation				mMontant_Epargne 				Montant d'épargne
						tblOPER_Frais				mMontant_Frais	 				Montant de frais (sans taxes)
						tblOPER_Frais				mMontant_TPS					Montant de la TPS appliquée sur le frais
						tblOPER_Frais				mMontant_TVQ					Montant de la TVQ appliquée sur le (Frais+tps)
						S/O							vcCode_Message					Message d'erreur lorsque le traitement
																					se fini à 0.
						S/O							iCode_Retour					 0 = Paramètres incomplets ou erronnés
																					-1 = Erreur non gérée

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-03-02		Corentin Menthonnex					Création du service							

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_ObtenirTransactionsOperationFrais]
    (
      @iID_Oper INT /*,
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
                                    AND oper.OperTypeID = [dbo].[fnOPER_ObtenirTypesOperationCategorie]('OPER_TYPE_FRS') ) 
            BEGIN
                SET @vcCode_Message = 'GENEE0008' ;
                RETURN 0 ;
            END*/
            
        BEGIN TRY
			-- Récupération des montants de taxes du frais affectant la convention
			DECLARE @mMontant_TPS MONEY;
			DECLARE @mMontant_TVQ MONEY;
			SELECT @mMontant_TPS = ft.mMontant_Taxe
			FROM dbo.tblOPER_Frais f
			JOIN dbo.tblOPER_FraisTaxes ft ON ft.iID_Frais = f.iID_Frais
			JOIN dbo.fntGENE_ObtenirTypeParametre(NULL, NULL) tp ON tp.iID_Type_Parametre = ft.iID_Type_Parametre
			WHERE f.iID_Oper = @iID_Oper 
			AND tp.vcCode_Type_Parametre = 'OPER_TAXE_TPS'

			SELECT @mMontant_TVQ = ft.mMontant_Taxe
			FROM dbo.tblOPER_Frais f
			JOIN dbo.tblOPER_FraisTaxes ft ON ft.iID_Frais = f.iID_Frais
			JOIN dbo.fntGENE_ObtenirTypeParametre(NULL, NULL) tp ON tp.iID_Type_Parametre = ft.iID_Type_Parametre
			WHERE f.iID_Oper = @iID_Oper 
			AND tp.vcCode_Type_Parametre = 'OPER_TAXE_TVQ'
            
			---------------------------------------------------------------------------------------------
			-- Remplissage des paramètres de sortie
			---------------------------------------------------------------------------------------------
            -- Transactions sur la convention
			SELECT TOP 1 cv.ConventionNo AS vcType_Transaction,
						 NULL AS mMontant_Epargne ,
						 f.mMontant_Frais AS mMontant_Frais , 
						 @mMontant_TPS AS mMontant_TPS ,
						 @mMontant_TVQ AS mMontant_TVQ
			FROM dbo.tblOPER_Frais f
			JOIN dbo.Un_Cotisation co ON co.OperID = f.iID_Oper
			JOIN dbo.Un_Unit u ON u.UnitID = co.UnitID
			JOIN dbo.Un_Convention cv ON cv.ConventionID = u.ConventionID
			WHERE f.iID_Oper = @iID_Oper
			
			UNION 
			
			-- Transactions sur les groupes d'unités
            SELECT  cv.ConventionNo  + ' -> ' + CONVERT(VARCHAR(10), u.InForceDate, 121) + ' (' + CAST(CAST(u.UnitQty AS DECIMAL(6,3)) AS VARCHAR) + ')' AS vcType_Transaction,
                    co.Cotisation AS mMontant_Epargne ,
                    NULL AS mMontant_Frais ,
                    NULL AS mMontant_TPS ,	
                    NULL AS mMontant_TVQ	
            FROM    dbo.Un_Cotisation co
                    INNER JOIN dbo.Un_Unit u ON u.UnitID = co.UnitID
                    INNER JOIN dbo.Un_Convention cv ON cv.ConventionID = u.ConventionID
            WHERE   co.OperID = @iID_Oper;
            

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

