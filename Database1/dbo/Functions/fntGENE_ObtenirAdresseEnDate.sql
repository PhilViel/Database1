/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fntGENE_ObtenirAdresseEnDate
Nom du service		: Déterminer l’adresse à une date
But 					: Retourner l’adresse d’une personne ou d’une entreprise à une date donnée, dans le format abrégé ou non.
Facette				: GENE
Référence			: UniAccès-Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Humain					Identifiant de l’humain (personne ou entreprise).
		  				iID_Type						Type d'adresse demandé.
						dtDate							Date pour laquelle l’adresse doit être déterminée.   Si la date
															n’est pas fournie, on considère que c’est pour la date du jour.
						bFormatCourt					Format abrégé demandé

Exemple d’appel		:	select * from [dbo].[fntGENE_ObtenirAdresseEnDate](601617, 1, getdate(), 1)
								select * from [dbo].[fntGENE_ObtenirAdresseEnDate](601617, 1, getdate(), 0)

Historique des modifications:
		Date		Programmeur			    Description
		----------  --------------------    ------------------------------------------------------
		2014-05-14  Pierre-Luc Simard		Création du service							
		2015-10-05  Stéphane Barbeau		Ajustement déclaration vcLogin_Creation à VARCHAR(50) pour régler erreur String or binary data would be truncated.
		2016-08-16  Steeve Picard           Optimation en Inline Function
        2016-10-18  Steeve Picard           Ajout du nom de la province «vcNom_Province»
        2018-11-27  Pierre-Luc Simard       Date de début en DATE au lieu de DATETIME
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntGENE_ObtenirAdresseEnDate]
    (
     @iID_Source INT,
     @iID_Type INT,
     @dtDate_Debut DATE = NULL,
     @bFormatCourt BIT = 0
    )
RETURNS @Adresse TABLE
    (
		iID_Adresse MoID,
		iID_Type INT,  
		iID_Source MoID,
		cType_Source CHAR(1),
		dtDate_Debut DATE,
		dtDate_Fin DATE,
		bInvalide BIT,
		bNouveau_Format BIT,
		vcNumero_Civique VARCHAR(10),
        vcNom_Rue VARCHAR(75),
        vcUnite VARCHAR(10),
		iID_Ville INT,
		vcVille MoCity, 
		iID_Province INT,
		vcProvince VARCHAR(75) NULL,
		vcNom_Province VARCHAR(100) NULL,
		cId_Pays CHAR(4),
		vcPays VARCHAR(75),
		vcCodePostal MoZipCode,
		iID_TypeBoite INT,
		vcBoite VARCHAR(50),    
		vcInternationale1 VARCHAR(175),
		vcInternationale2 VARCHAR(175),
		vcInternationale3 VARCHAR(175),
		bResidenceFaitCanada BIT,
		bResidenceFaitQuebec BIT,
		dtDate_Creation DATETIME,
		vcLogin_Creation VARCHAR(50)
	)
AS 
    BEGIN 

		-- Date du jour si aucune date passée en paramètre
        IF @dtDate_Debut IS NULL 
            SET @dtDate_Debut = dbo.FN_CRQ_DateNoTime(GETDATE())
            
		-- Si aucune type d'adresse passé en paramètre, adresse d'affaire si c'est un représentant, sinon adresse résidentielle      
		IF ISNULL(@iID_Type, 0) = 0 
			IF EXISTS (SELECT 1 FROM un_Rep WHERE RepID = @iID_Source)
				SET @iID_Type = 4  
			ELSE
		 		SET @iID_Type = 1  
		 	
        INSERT INTO @Adresse
			 SELECT TOP 1
                    A.iID_Adresse,  
                    A.iID_Type,
                    A.iID_Source,
                    A.cType_Source, 
                    A.dtDate_Debut,  
                    A.dtDate_Fin,
                    A.bInvalide,
                    A.bNouveau_Format, 
                    A.vcNumero_Civique,
                    A.vcNom_Rue,
                    A.vcUnite, 
                    A.iID_Ville,  
                    A.vcVille,
                    A.iID_Province,
                    A.vcProvinceCode,
                    A.vcProvince,
                    A.cID_Pays,
                    A.vcPays,
                    A.vcCodePostal, 
                    A.iID_TypeBoite,
                    A.vcBoite, 
                    A.vcInternationale1,
                    A.vcInternationale2,
                    A.vcInternationale3,
                    A.bResidenceFaitCanada,
                    A.bResidenceFaitQuebec,
                    A.dtDate_Creation,
                    A.vcLogin_Creation
                FROM [dbo].[fntGENE_ObtenirAdresseEnDate_PourTous] (@iID_Source, @iID_Type, @dtDate_Debut, @bFormatCourt) A
                ORDER BY
                    A.dtDate_Debut DESC, 
                    A.dtDate_Creation DESC 

        RETURN
    END


