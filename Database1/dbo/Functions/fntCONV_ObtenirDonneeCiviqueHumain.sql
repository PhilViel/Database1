
/****************************************************************************************************
Code de service		:		fcCONV_DonneeCiviqueHumain
Nom du service		:		Obtenir les données civiques du souscripteur / Bénificiaire 
But					:		Récupérer les données à imprimer du souscripteur / Bénificiaire
Facette				:		P171U
Reférence			:		Relevé de dépôt
Parametres d'entrée :	Parametres					Description                                                     Obligatoir
                        ----------                  ----------------                                                --------------                       
                        iIDhumain	                Identifiant unique de l'humain


Exemple d'appel:
                 SELECT * FROM fnCONV_DonneeCiviqueHumain(425000)

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       Mo_Human	                    FirstName	                                Prénom du souscripteur
                       Mo_Human	                    LastName	                                Nom du souscripteur
                       Mo_Adr	                    Adresse	                                    Adresse du souscripteur
                       Mo_Adr	                    City	                                    Ville du souscripteur
                       Mo_Adr	                    ZipCode	                                    Code Postal du souscripteur
                       Mo_Adr	                    StateName	                                Province du souscripteur
                       Mo_Adr                       EMail                                       Email du souscripteur

                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-01-09					Fatiha Araar							Création de la fonction
                        2009-02-06                  Fatiha Araar                            Ajouter l'eMail du souscripteur
****************************************************************************************************/

CREATE FUNCTION [dbo].[fntCONV_ObtenirDonneeCiviqueHumain]
(	
	@iIDHumain INT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT 
		vcPrenom		= HS.FirstName,
		vcNom			= HS.LastName,
		vcAdresse		= A.Address,
		vcVille			= A.City,
		vcCodePostal	= A.ZipCode,
		vcProvince		= (SELECT TOP 1 vcCode_Province from dbo.fntGENE_ObtenirProvincePays(A.StateName, A.City, A.CountryId, A.ZipCode) ),
		vcLangue		= HS.LangID,
		vcPays			= C.CountryName,
		vcCourriel		= A.EMail,
		cSexe			= HS.SexID,
		vcNAS			= HS.SocialNumber
	  FROM 
		dbo.Mo_Human HS 
		LEFT JOIN 
		dbo.Mo_Adr A 
		ON A.AdrID = HS.AdrID
		LEFT JOIN
		dbo.Mo_Country C 
		ON C.CountryID = A.CountryID
     WHERE 
		HS.HumanID  = @iIDHumain
)
