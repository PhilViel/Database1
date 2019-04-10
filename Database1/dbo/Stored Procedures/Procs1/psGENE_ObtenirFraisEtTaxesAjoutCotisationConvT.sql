/****************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc.

Code du service            : psGENE_ObtenirFraisEtTaxesAjoutCotisationConvT
Nom du service             : Procedure pour obtenir le montant de base et les 2 taxes nécessaire pour calculer les frais dans une convention T
But                        : 
Facette                           : GENE

Paramètres d’entrée :      Paramètre                               Description
                                        -------------------------- -----------------------------------------------------------------

Exemple d’appel            :      

             exec psGENE_ObtenirFraisEtTaxesAjoutCotisationConvT

Paramètres de sortie:      

Historique des modifications:
             Date           Programmeur             Description                                   
             ------------   ----------------------  -----------------------------------------     
             2016-11-14     Patrice Côté            Création du service        
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirFraisEtTaxesAjoutCotisationConvT]
AS
BEGIN
    DECLARE 
        @EnDateDu DATE = GETDATE(),
        @MontantBase MONEY,
	    @MontantTaxes MONEY = 0,
	    @return_value int,
		@mMontant_Frais_TTC money = 0,
		@vcCode_Message varchar(10)

    EXECUTE @MontantBase = dbo.fnGENE_ObtenirParametre @vcCode_Type_Parametre = 'CONV_MNT_FRAIS_R17',
                                                                @dtDate_Application = @EnDateDu
                                                                ,@vcDimension1 = NULL
                                                                ,@vcDimension2 = NULL
                                                                ,@vcDimension3 = NULL
                                                                ,@vcDimension4 = NULL
                                                                ,@vcDimension5 = NULL

	IF(@MontantBase > 0)
		BEGIN
			EXEC @return_value = [dbo].[psOPER_SimulerMontantOperationFrais]
			@vcCode_Type_Frais = N'CUI',
			@mMontant_Frais = @MontantBase,
			@mMontant_Frais_TTC = @mMontant_Frais_TTC OUTPUT,
			@vcCode_Message = @vcCode_Message OUTPUT

			IF(@return_value = 1)
				BEGIN
					SELECT @MontantTaxes = @mMontant_Frais_TTC - @MontantBase
				END
		END
    ELSE 
        BEGIN 
           SET @MontantBase = 0
        END 

	SELECT 
        MontantBase = @MontantBase, 
	    MontantTaxes = @MontantTaxes    

END
