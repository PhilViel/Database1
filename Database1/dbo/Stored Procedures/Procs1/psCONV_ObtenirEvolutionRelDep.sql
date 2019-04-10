
/****************************************************************************************************
Code de service		:		psCONV_ObtenirEvolutionRelDep
Nom du service		:		psCONV_ObtenirEvolutionRelDep
But					:		Permet de voir l'évolution du traitement des données de relevé de dépôt
Facette				:		CONV 
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        N/A
						

Exemple d'appel:
				DECLARE @i INT
                EXECUTE @i = dbo.psCONV_ObtenirEvolutionRelDep 
				SELECT @i

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       N/A							iNbTotalSouscripteur						Nombre total de souscripteurs distincts à traiter
													iNbSouscripteurTraite						Nombre de souscripteurs distints traités
													@iStatut									= 1 si procédure exécutée avec succès
																								= -1 si erreur technique lors de l'exécution de la procédure						

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2010-04-26					Jean-Francois Gauthier					Création du service
						2010-05-10					Jean-François Gauthier					Modification, car le champ "processed" peut prendre
																							plusieurs valeurs
 ****************************************************************************************************/
CREATE PROCEDURE dbo.psCONV_ObtenirEvolutionRelDep
AS
	BEGIN
		BEGIN TRY
			DECLARE 
				@iStatut					INT
				,@iNbTotalSouscripteur		INT

			SELECT
				@iNbTotalSouscripteur = COUNT(DISTINCT rd.SubscriberID)
			FROM
				dbo.tblCONV_TMPRelDep rd

			SELECT
				iNbTotalSouscripteur	= @iNbTotalSouscripteur
				,iNbSouscripteurTraite	= COUNT(DISTINCT rd.SubscriberID)
			FROM
				dbo.tblCONV_TMPRelDep rd
			WHERE
				rd.processed <> 0	

			SET @iStatut = 1
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
				,@iStatut		= -1
				
			RAISERROR	(@vcErrMsg, @iErrSeverite, @iErrStatut) WITH LOG
		END CATCH
		
		RETURN @iStatut
	END
