/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnOPER_ObtenirMontantTaxeFrais
Nom du service		: Obtenir le montant d'une taxe d'un frais
But 				: Obtenir le montant d'une taxe d'un frais
Facette				: OPER

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Frais					Identifiant unique du frais pour lequel nous cherchons le montant de taxe.
						vcCode_Taxe					Code de la taxe que dont on cherche le montant (le code correspond au 
													vcCode_Type_Parametre de la table tblGENE_TypesParametre ou se trouve 
													le type de taxe).

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						N/A							mMontant_Taxe					Montant de la taxe
	
Exemple d'appel : SELECT dbo.fnOPER_ObtenirMontantTaxesOperationFrais(1)

Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2011-03-03		Corentin Menthonnex			Création du service
		
****************************************************************************************************/
CREATE FUNCTION [dbo].[fnOPER_ObtenirMontantTaxeFrais]
    (
      @iID_Frais INT ,
      @vcCode_Taxe VARCHAR(100)
    )
RETURNS MONEY
AS 
    BEGIN
        DECLARE @mMontant_Taxe MONEY ;
        DECLARE @iID_Type_Parametre INT ;
        
        SET @iID_Type_Parametre = ( SELECT  tp.iID_Type_Parametre
                                    FROM    dbo.fntGENE_ObtenirTypeParametre(NULL, @vcCode_Taxe) tp
                                  )
        
        SELECT  @mMontant_Taxe = ft.mMontant_Taxe
        FROM    dbo.tblOPER_FraisTaxes ft
        WHERE   ft.iID_Frais = @iID_Frais
                AND iID_Type_Parametre = @iID_Type_Parametre ;


        RETURN ROUND(@mMontant_Taxe,2) ;
    END

