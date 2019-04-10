
/****************************************************************************************************
Code de service		:		psPCEE_ObtenirTransactionBECEnAttente
Nom du service		:		1.1.1 Obtenir la liste des transactions BEC en attente
But					:		Obtenir la liste complète des transactions BEC n'ayant pas été envoyéees au PCEE
Description			:		Ce service est utilisé afin d'obtenir la liste complète des transactions qui sont pas
							encore envoyées au PCEE et qui ont été effectuées via l'outil de gestion du BEC. Les
							différents types de transactions sont 'Demande de BEC', 'Remboursement du BEC',
							'Transfert de solde entre convention' et 'Désactivation du BEC'
							
Facette				:		PCEE
Reférence			:		Document psPCEE_ObtenirTransactionBECEnAttente.DOCX

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
						iID_Beneficiaire			Identifiant unique du bénéficiaire			Oui

Exemples d'appel:
				EXEC [dbo].[psPCEE_ObtenirTransactionBECEnAttente] 446695
				EXEC [dbo].[psPCEE_ObtenirTransactionBECEnAttente] 547697
				

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
						@tConvEnAttenteBEC			dtTransaction (Un_CESP400)					Date de l'opération
													vcAction									Description de l'action de la transaction en attente
													ConventionNO (Un_CESP400)					Numéro de la convention
													fCLB		 (Un_CESP400)					Montant du remboursement ou montant du transfert de solde
													iCESP400ID									Identifiant unique de la transaction

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-11-27					Jean-François Gauthier					Création du service

 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psPCEE_ObtenirTransactionBECEnAttente]
		(
		@iID_Beneficiaire	INT
		)
AS
	BEGIN
		SET NOCOUNT ON
		BEGIN TRY
			SELECT 
				dtTransaction
				,vcAction	
				,ConventionNO
				,fCLB		
				,iCESP400ID	
			FROM 
				dbo.fntPCEE_ObtenirTransactionBECEnAttente(@iID_Beneficiaire)
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
