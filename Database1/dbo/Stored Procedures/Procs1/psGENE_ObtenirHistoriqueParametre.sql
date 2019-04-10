/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnGENE_ObtenirHistoriqueParametre
Nom du service		: Obtenir l'historique d'un paramètre
But 				: Obtenir l'historique des valeurs d’un paramètre selon les dimensions fournies.
Facette				: GENE
Référence			: Noyau-GENE

Exemple d'appel		:
					EXECUTE dbo.psGENE_ObtenirHistoriqueParametre 'CONV_RDEP_INFO_REE', NULL, NULL, NULL, NULL, NULL			
		
Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				vcCode_Type_Parametre		Identifiant unique du type de paramètre à mettre à jour.
						vcDimension1				Valeur de la dimension1 du paramètre.
						vcDimension2				Valeur de la dimension2 du paramètre.
						vcDimension3				Valeur de la dimension3 du paramètre.
						vcDimension4				Valeur de la dimension4 du paramètre.
						vcDimension5				Valeur de la dimension5 du paramètre.

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						tblGENE_Parametres			iID_Parametre_Applicatif		Identifiant unique du paramètre applicatif
						tblGENE_Parametres			iID_Type_Parametre				Identifiant du type de paramètre
						tblGENE_Parametres			vcDimension1					Dimension 1 du paramètre
						tblGENE_Parametres			vcDimension2					Dimension 2 du paramètre
						tblGENE_Parametres			vcDimension3					Dimension 3 du paramètre
						tblGENE_Parametres			vcDimension4					Dimension 4 du paramètre
						tblGENE_Parametres			vcDimension5					Dimension 5 du paramètre
						tblGENE_Parametres			dtDate_Debut_Application		Date de début d'application du paramètre
						tblGENE_Parametres			dtDate_Fin_Application			Date de fin d'application du paramètre
						tblGENE_Parametres			vcValeur_Parametre				Valeur du paramètre

Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2009-02-19		Thierry Sombreffe			Création du service							
		2010-05-06		Jean-François Gauthier		Ajout de la gestion des erreurs
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirHistoriqueParametre](
							@vcCode_Type_Parametre	VARCHAR(100),
							@vcDimension1			VARCHAR(100),
							@vcDimension2			VARCHAR(100),
							@vcDimension3			VARCHAR(100),
							@vcDimension4			VARCHAR(100),
							@vcDimension5			VARCHAR(100))
AS
	BEGIN
		BEGIN TRY
			SELECT P.iID_Parametre_Applicatif,
				   P.iID_Type_Parametre,
				   P.vcDimension1,
				   P.vcDimension2,
				   P.vcDimension3,
				   P.vcDimension4,
				   P.vcDimension5,
				   P.dtDate_Debut_Application,
				   P.dtDate_Fin_Application,
				   P.vcValeur_Parametre
			  FROM tblGENE_Parametres P
			  JOIN tblGENE_Typesparametre TP on TP.iID_Type_Parametre=P.iID_Type_Parametre
			 WHERE TP.vcCode_Type_Parametre = @vcCode_Type_Parametre
			   AND isnull(vcDimension1,'') = isnull(@vcDimension1,'')
			   AND isnull(vcDimension2,'') = isnull(@vcDimension2,'')
			   AND isnull(vcDimension3,'') = isnull(@vcDimension3,'')
			   AND isnull(vcDimension4,'') = isnull(@vcDimension4,'')
			   AND isnull(vcDimension5,'') = isnull(@vcDimension5,'')
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
