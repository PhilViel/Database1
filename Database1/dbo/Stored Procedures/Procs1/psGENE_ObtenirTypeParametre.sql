/****************************************************************************************************
Code de service		:		psGENE_ObtenirTypeParametre
Nom du service		:		Obtenir les types d'un paramètre
But					:		Obtenir les données d'un types de paramètre.
Facette				:		GENE
Reférence			:		Générique
Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						vcCodeTypeParametre			Le code du type de paramètre
                        cID_Langue	                Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».  
													Le français est la langue par défaut si elle n’est pas spécifiée.

Exemple d'appel:
                EXECUTE dbo.psGENE_ObtenirTypeParametre 'TRADUCTION'

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       tblGENE_TypesParametre       iID_TypeTelephone                           ID unique de type téléphone
                       tblGENE_TypesParametre       vcCode                                      code du type téléphone
                       tblGENE_TypesParametre       vcDescription                               description du type téléphone

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-02-19					Thierry Sombreffe						Création de procédure stockée 
						2010-05-06					Jean-François Gauthier					Ajout de la gestion des erreurs
****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_ObtenirTypeParametre](
							   @vcCodeTypeParametre varchar(100),
                               @cID_Langue varchar(3)= 'FRA')
AS
	BEGIN
		BEGIN TRY
			SELECT iID_Type_Parametre,
				   vcCode_Type_Parametre,
				   vcDescription = CASE @cID_Langue
									   WHEN  'ENU' THEN CASE [dbo].[fnGENE_ObtenirParametre]('TRADUCTION',
																							 NULL,
																							 'tblGENE_TypesParametre',
																							 'vcDescription',
																							 iID_Type_Parametre,
																							 @cID_Langue  ,
																							 NULL)
															 WHEN '-1' THEN vcDescription
															 WHEN '-2' THEN vcDescription
															 ELSE [dbo].[fnGENE_ObtenirParametre] ('TRADUCTION',
																								   NULL,
																								   'tblGENE_TypesParametre',
																								   'vcDescription',
																								   iID_Type_Parametre,
																								   @cID_Langue,
																								   NULL)
														END
									   ELSE vcDescription
								   END,
				   tiNB_Dimensions,
				   bConserver_Historique,
				   bPermettre_MAJ_Via_Interface,
				   vcTypeDonneParametre,
				   iLongueurParametre,
				   iNbreDecimale,
				   vcNomDimension1 = CASE @cID_Langue
										 WHEN  'ENU' THEN CASE [dbo].[fnGENE_ObtenirParametre]('TRADUCTION',
																							   NULL,
																							   'tblGENE_TypesParametre',
																							   'vcNomDimension1',
																							   iID_Type_Parametre,
																							   @cID_Langue  ,
																							   NULL)
															   WHEN '-1' THEN vcNomDimension1
															   WHEN '-2' THEN vcNomDimension1
															   ELSE [dbo].[fnGENE_ObtenirParametre] ('TRADUCTION',
																									 NULL,
																									 'tblGENE_TypesParametre',
																									 'vcNomDimension1',
																									 iID_Type_Parametre,
																									 @cID_Langue,
																									 NULL)
														  END
										 ELSE vcNomDimension1
									 END,
				   vcNomDimension2 = CASE @cID_Langue
										 WHEN  'ENU' THEN CASE [dbo].[fnGENE_ObtenirParametre]('TRADUCTION',
																							   NULL,
																							   'tblGENE_TypesParametre',
																							   'vcNomDimension2',
																							   iID_Type_Parametre,
																							   @cID_Langue  ,
																							   NULL)
															   WHEN '-1' THEN vcNomDimension2
															   WHEN '-2' THEN vcNomDimension2
															   ELSE [dbo].[fnGENE_ObtenirParametre] ('TRADUCTION',
																									 NULL,
																									 'tblGENE_TypesParametre',
																									 'vcNomDimension2',
																									 iID_Type_Parametre,
																									 @cID_Langue,
																									 NULL)
														  END
										 ELSE vcNomDimension2
									 END,
				   vcNomDimension3 = CASE @cID_Langue
										 WHEN  'ENU' THEN CASE [dbo].[fnGENE_ObtenirParametre]('TRADUCTION',
																							   NULL,
																							   'tblGENE_TypesParametre',
																							   'vcNomDimension3',
																							   iID_Type_Parametre,
																							   @cID_Langue  ,
																							   NULL)
															   WHEN '-1' THEN vcNomDimension3
															   WHEN '-2' THEN vcNomDimension3
															   ELSE [dbo].[fnGENE_ObtenirParametre] ('TRADUCTION',
																									 NULL,
																									 'tblGENE_TypesParametre',
																									 'vcNomDimension3',
																									 iID_Type_Parametre,
																									 @cID_Langue,
																									 NULL)
														  END
										 ELSE vcNomDimension3
									 END,
				   vcNomDimension4 = CASE @cID_Langue
										 WHEN  'ENU' THEN CASE [dbo].[fnGENE_ObtenirParametre]('TRADUCTION',
																							   NULL,
																							   'tblGENE_TypesParametre',
																							   'vcNomDimension4',
																							   iID_Type_Parametre,
																							   @cID_Langue  ,
																							   NULL)
															   WHEN '-1' THEN vcNomDimension4
															   WHEN '-2' THEN vcNomDimension4
															   ELSE [dbo].[fnGENE_ObtenirParametre] ('TRADUCTION',
																									 NULL,
																									 'tblGENE_TypesParametre',
																									 'vcNomDimension4',
																									 iID_Type_Parametre,
																									 @cID_Langue,
																									 NULL)
														  END
										 ELSE vcNomDimension4
									 END,
				   vcNomDimension5 = CASE @cID_Langue
										 WHEN  'ENU' THEN CASE [dbo].[fnGENE_ObtenirParametre]('TRADUCTION',
																							   NULL,
																							   'tblGENE_TypesParametre',
																							   'vcNomDimension5',
																							   iID_Type_Parametre,
																							   @cID_Langue  ,
																							   NULL)
															   WHEN '-1' THEN vcNomDimension5
															   WHEN '-2' THEN vcNomDimension5
															   ELSE [dbo].[fnGENE_ObtenirParametre] ('TRADUCTION',
																									 NULL,
																									 'tblGENE_TypesParametre',
																									 'vcNomDimension5',
																									 iID_Type_Parametre,
																									 @cID_Langue,
																									 NULL)
														  END
										 ELSE vcNomDimension5
									 END,
				   bObligatoire
			  FROM tblGENE_TypesParametre
			 WHERE vcCode_Type_Parametre = @vcCodeTypeParametre
		END TRY
		BEGIN CATCH
			DECLARE		 
				@iErrSeverite	INT
				,@iErrStatut	INT
				,@vcErrMsg		NVARCHAR(1024)
			
			SELECT
				@vcErrMsg			= REPLACE(ERROR_MESSAGE(),'%',' ')
				,@iErrStatut		= ERROR_STATE()
				,@iErrSeverite		= ERROR_SEVERITY()
	
			RAISERROR	(@vcErrMsg, @iErrSeverite, @iErrStatut) WITH LOG
		END CATCH
	END
