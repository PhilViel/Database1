
/****************************************************************************************************
Code de service		:		psPCEE_ObtenirHistoriqueBEC
Nom du service		:		1.1.1 Obtenir l'historique du BEC 
But					:		Obtenir l'historique complet du BEC
Description			:		Ce service reçoit en paramètre l'identifiant unique d'un bénéficiaire
							Toutes les transactions reliées au BEC y sont affichées : les demandes,
							les remboursements, les versements annuels, les transferts entre convention
							ainsi que les désactivations
Facette				:		PCEE
Reférence			:		Document psPCEE_ObtenirHistoriqueBEC.DOCX

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
						iID_Beneficiare				Identifiant unique du bénéficiaire

Exemples d'appel:
			EXEC dbo.psPCEE_ObtenirHistoriqueBEC 418719
			EXEC dbo.psPCEE_ObtenirHistoriqueBEC 479667, 'ENU'


Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
						@tHistoriqueBEC				dtOperDate									Date de l'opération
													vcAction									Action de la transaction
													ConventionNo								Numéro de la convention							
													vcTransID									Identifiant de la transaction PCEE
													dtCESPSendFile								Date d'envoi du fichier
													dtRead										Date de réception du fichier
													mMontant									Montant BEC
													vcCESP9000CESGReason						Raison du PCEE
													siCESP800ErrorID							Code d'erreur s'il y a lieu			

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-10-15					Jean-François Gauthier					Création du service
						2009-12-11					Jean-François Gauthier					Ajout du champ vcCESP9000ACESGReason
						2010-01-06					Jean-François Gauthier					Ajout du champ bRenverse 
																							Élimination du champ vcCESP9000ACESGReason
																							Ajout du champ vcCESP800Error contenant la description de l'erreur
						2010-01-07					Jean-François Gauthier					Ajout du paramètre de langue
						2010-05-11					Jean-François Gauthier					Ajout de la gestion des erreurs
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psPCEE_ObtenirHistoriqueBEC]
	(
		@iIDBeneficiaire	INT
		,@cLangue			CHAR(3)	= NULL
	)
AS
	BEGIN
		SET NOCOUNT ON
		BEGIN TRY
			SELECT 
				iCESP400ID				
				,dtOperDate				
				,vcAction				
				,ConventionNo			
				,vcTransID				
				,mMontant				
				,vcCESP9000CESGReason	
				,siCESP800ErrorID		
				,dtEnvoi				
				,dtReception
				--,vcCESP9000ACESGReason			
				,vcCESP800Error
				,bRenverse
			FROM 
				dbo.fntPCEE_ObtenirHistoriqueBEC(@iIDBeneficiaire, @cLangue)
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
