
/****************************************************************************************************
Code de service		:		psPCEE_ObtenirListeRaisonRemboursementBEC
Nom du service		:		1.1.1 Obtenir la liste des raisons de remboursement BEC
But					:		Afficher les raisons de remboursement du BEC
Description			:		Ce service affiche les raisons valables pour un remboursement du BEC au PCEE par
							l'outil de gestion du BEC
Facette				:		PCEE
Reférence			:		Document psPCEE_ObtenirListeRaisonRemboursementBEC.DOCX

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
						Aucun

Exemples d'appel:
					EXEC dbo.psPCEE_ObtenirListeRaisonRemboursementBEC

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
						Un_CESP400WithdrawReason	tiCESP400WithdrawReasonID					Code la raison du remboursement

													vcCESP400WithdrawReason						Description de la raison
Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-11-27					Jean-François Gauthier					Création du service
						2010-05-11					Jean-François Gauthier					Ajout de la gestion des erreurs
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psPCEE_ObtenirListeRaisonRemboursementBEC] 
AS
	BEGIN
		SET NOCOUNT ON
		BEGIN TRY
			SELECT 
				tiIDCESP400RaisonRemboursement		
				,vcCESP400DescriptionRemboursement	
			FROM 
				dbo.fntPCEE_ObtenirListeRaisonRemboursementBEC()
		END TRY
		BEGIN CATCH
			DECLARE		 
				@iErrSeverite	INT
				,@iErrStatut	INT
				,@vcErrMsg		NVARCHAR(1024)
				
			SELECT
				@vcErrMsg		= REPLACE(ERROR_MESSAGE(),'%',' ')
				,@iErrStatut	= ERROR_STATE()
				,@iErrSeverite	= ERROR_SEVERITY()
				
			RAISERROR	(@vcErrMsg, @iErrSeverite, @iErrStatut) WITH LOG
		END CATCH
	END
