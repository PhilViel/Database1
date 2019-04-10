/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Code de service		:		dbo.psCONV_MiseAJourRelDepDateDispo
Nom du service		:		psCONV_MiseAJourRelDepDateDispo
But					:		Active les dates de disponibilité des relevés de dépôt en fonction du calcul des intérêts
Facette				:		
Reférence			:		Relevé de dépôt

Parametres d'entrée :	Parametres					Description                              Obligatoire
                        ----------                  ----------------                         --------------                       
 
Exemple d'appel:
			EXEC [dbo].[psCONV_MiseAJourRelDepDateDispo] 			


Parametres de sortie :  Table											Champs							Description
					    -----------------								---------------------------		--------------------------

Historique des modifications :
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2010-09-21					Jean-François Arial						Création de la procédure						
                        2017-09-27                  Pierre-Luc Simard                       Deprecated - Cette procédure n'est plus utilisée

  ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_MiseAJourRelDepDateDispo]
							
AS
BEGIN
    SELECT 1/0
    /*
	BEGIN TRY
		DECLARE @LastDate DATETIME

		--Va chercher la dernière date où a eu lieu le calcul d'intérêt
		SELECT TOP 1 @LastDate = OperDate
		FROM un_oper 
		WHERE opertypeid = 'in+' OR opertypeid = 'in-'
		ORDER BY OperDate DESC

		--Mets disponible pour les relevés cette même date
		UPDATE tblCONV_ReleveDepotDateSemestrielleDisponible
		SET bDateDisponible = 1
		WHERE dtDateReleveSemestriel = @LastDate
		AND bDateDisponible = 0
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

		IF (XACT_STATE()) = -1 					-- LA TRANSACTION EST TOUJOURS ACTIVE, ON PEUT FAIRE UN ROLLBACK
			AND @@TRANCOUNT > 0
			BEGIN
				--------------------
				ROLLBACK TRANSACTION
				--------------------
			END
			
		RAISERROR	(@vcErrMsg, @iErrSeverite, @iErrStatut) WITH LOG
	END CATCH
    */
END