
/****************************************************************************************************
Code de service		:		psGENE_ObtenirTypeTelephone
Nom du service		:		Obtenir les types de téléphones
But					:		Obtenir tous les types du téléphone.
Facette				:		OPPO
Reférence			:		Gestion des opportunités
Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        cID_Langue	                Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».  Le français est la langue par défaut si elle n’est pas spécifiée.

Exemple d'appel:
                EXEC dbo.psGENE_ObtenirTypeTelephone

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       tblGENE_TypeTelephone        iID_TypeTelephone                           ID unique de type téléphone
                       tblGENE_TypeTelephone        vcCode                                      code du type téléphone
                       tblGENE_TypeTelephone        vcDescription                               description du type téléphone

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-10-24					Fatiha Araar							Création de procédure stockée 
                        2008-11-26                  Fatiha Araar                            Ajouter la traduction          
						2009-12-09					Jean-François Gauthier					Ajout des synonymes
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirTypeTelephone](
													@cID_Langue VARCHAR(3)= 'FRA'
													)
AS
	BEGIN
		SELECT 
			iID_TypeTelephone,vcCode,vcDescription =CASE @cID_Langue
                                                    WHEN  'ENU' THEN
                                                           CASE  
                                                           dbo.fnGENE_ObtenirParametre(
																						    'TRADUCTION',
																						    NULL,
																						    'tblGENE_TypeTelephone',
																						    'vcDescription',
																						    iID_TypeTelephone,
																						    @cID_Langue,
																						    NULL)
                                                           WHEN '-1' THEN vcDescription
                                                           WHEN '-2' THEN vcDescription
                                                          
                                                           ELSE
                                                           dbo.fnGENE_ObtenirParametre(
																						    'TRADUCTION',
																						    NULL,
																						    'tblGENE_TypeTelephone',
																						    'vcDescription',
																						    iID_TypeTelephone,
																						    @cID_Langue,
																						    NULL)
                                                           END
                                                                                                                 
                                                   ELSE
                                                   vcDescription
                                                   END
        FROM 
			dbo.tblGENE_TypeTelephone
        ORDER BY 
			vcDescription
	END
