/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntGENE_ObtenirTypeParametre
Nom du service		: Obtenir un type de paramètre  
But 				: Obtenir un type de paramètre via son id ou son code
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Type_Parametre			Identifiant unique du paramètre que l'on cherche.
						vcCode_Type_Parametre		Code du type de paramètre que l'on cherche.

Exemple d’appel		:	SELECT * FROM [dbo].[fntGENE_ObtenirTypeParametre](1)

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
		  				tblGENE_TypesParametre		iID_Type_Parametre				Identifiant unique.
						tblGENE_TypesParametre		vcCode_Type_Parametre			Code du type de paramètre.
						tblGENE_TypesParametre		vcDescription					Description du type de paramètre.
						tblGENE_TypesParametre		tiNB_Dimensions					Nombre de dimensions du type de paramètre.
						tblGENE_TypesParametre		bConserver_Historique			Bit de conservation d'historique
						tblGENE_TypesParametre		bPermettre_MAJ_Via_Interface	Bit pour la mise à jour via interface.
						tblGENE_TypesParametre		vcTypeDonneParametre			Type de données.
						tblGENE_TypesParametre		iLongueurParametre				Longueur du paramètre.
						tblGENE_TypesParametre		iNbreDecimale					Nombre de décimales.
						tblGENE_TypesParametre		vcNomDimension1					Dimension 1.
						tblGENE_TypesParametre		vcNomDimension2					Dimension 2.
						tblGENE_TypesParametre		vcNomDimension3					Dimension 3.
						tblGENE_TypesParametre		vcNomDimension4					Dimension 4.
						tblGENE_TypesParametre		vcNomDimension5					Dimension 5.
						tblGENE_TypesParametre		bObligatoire					Bit pour définir son caractère obligatoire.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-03-02		Corentin Menthonnex					Création du service							
        
****************************************************************************************************/
CREATE FUNCTION [dbo].[fntGENE_ObtenirTypeParametre]
    (
      @iID_Type_Parametre INT ,
      @vcCode_Type_Parametre VARCHAR(100)
    )
RETURNS @tblGENE_TypesParametre TABLE
    (
      iID_Type_Parametre INT NOT NULL ,
      vcCode_Type_Parametre VARCHAR(100) NOT NULL ,
      vcDescription VARCHAR(500) NOT NULL ,
      tiNB_Dimensions TINYINT NOT NULL ,
      bConserver_Historique BIT NOT NULL ,
      bPermettre_MAJ_Via_Interface BIT NOT NULL ,
      vcTypeDonneParametre VARCHAR(20) ,
      iLongueurParametre INT ,
      iNbreDecimale INT ,
      vcNomDimension1 VARCHAR(30) ,
      vcNomDimension2 VARCHAR(30) ,
      vcNomDimension3 VARCHAR(30) ,
      vcNomDimension4 VARCHAR(30) ,
      vcNomDimension5 VARCHAR(30) ,
      bObligatoire BIT
    )
AS 
    BEGIN

		-- Récupération du type
        INSERT  INTO @tblGENE_TypesParametre
                SELECT  tp.iID_Type_Parametre ,
                        tp.vcCode_Type_Parametre ,
                        tp.vcDescription ,
                        tp.tiNB_Dimensions ,
                        tp.bConserver_Historique ,
                        tp.bPermettre_MAJ_Via_Interface ,
                        tp.vcTypeDonneParametre ,
                        tp.iLongueurParametre ,
                        tp.iNbreDecimale ,
                        tp.vcNomDimension1 ,
                        tp.vcNomDimension2 ,
                        tp.vcNomDimension3 ,
                        tp.vcNomDimension4 ,
                        tp.vcNomDimension5 ,
                        tp.bObligatoire
                FROM    dbo.tblGENE_TypesParametre tp
                WHERE   tp.vcCode_Type_Parametre = ISNULL(@vcCode_Type_Parametre, tp.vcCode_Type_Parametre)
                        AND tp.iID_Type_Parametre = ISNULL(@iID_Type_Parametre, tp.iID_Type_Parametre)
			
		        
		-- Retourner les informations
        RETURN 
		
    END

