/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psCONV_ObtenirRaisonsChangementBeneficiaire
Nom du service		: Obtenir les raisons des changements de bénéficiaire 
But 				: Obtenir la liste des raisons des changements de bénéficiaire des conventions selon la langue de
					  l’utilisateur.
Facette				: CONV
Référence			: Noyau-CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.

Exemple d’appel		:	exec [dbo].[psCONV_ObtenirRaisonsChangementBeneficiaire] 'FRA'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Tous les champs de la table « tblCONV_RaisonsChangementBeneficiaire ».  Les raisons sont triées
						en ordre de présentation.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-12-18		Éric Deshaies						Création du service							
		2010-04-29		Jean-François Gauthier				Ajout du champ tiOrdre_Presentation en retour
		2010-05-05		Jean-François Gauthier				Ajout de la gestion des erreurs
		2010-08-03		Éric Deshaies						Mise à niveau sur la traduction des champs
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirRaisonsChangementBeneficiaire] 
(
	@cID_Langue CHAR(3)
)
AS
	BEGIN
		BEGIN TRY		
			-- Considérer le français comme la langue par défaut
			IF @cID_Langue IS NULL
				SET @cID_Langue = 'FRA'

			SET NOCOUNT ON;

			-- Retourner les statuts des erreurs
			SELECT R.tiID_Raison_Changement_Beneficiaire,
				   R.vcCode_Raison,
				   ISNULL(T1.vcTraduction,R.vcDescription) AS vcDescription,
				   R.bSelectionnable_Utilisateur,
				   R.bRequiere_Complement_Information,
				   R.tiOrdre_Presentation
			FROM 
				dbo.tblCONV_RaisonsChangementBeneficiaire R
				LEFT JOIN tblGENE_Traductions T1 ON T1.vcNom_Table = 'tblCONV_RaisonsChangementBeneficiaire'
												AND T1.vcNom_Champ = 'vcDescription'
												AND T1.iID_Enregistrement = R.tiID_Raison_Changement_Beneficiaire
												AND T1.vcID_Langue = @cID_Langue
			ORDER BY 
				R.tiOrdre_Presentation
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
