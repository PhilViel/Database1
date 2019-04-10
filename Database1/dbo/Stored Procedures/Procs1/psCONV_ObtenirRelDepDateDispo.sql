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
Code de service		:		dbo.psCONV_ObtenirRelDepDateDispo
Nom du service		:		psCONV_ObtenirRelDepDateDispo
But					:		Récupérer les dates de disponibilité des relevés de dépôt semestriels
Facette				:		
Reférence			:		Relevé de dépôt

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
                        @bDisponible				Indique si on recherche les dates			OUI
													disponibles ou non
													1 = Oui, 0 = Non, NULL = 0                     
                        @bDateDebut					Indique si on recherche les dates			OUI
													de début ou non
													1 = Oui, 0 = Non, NULL = 0	

Exemple d'appel:
			EXEC [dbo].[psCONV_ObtenirRelDepDateDispo] 0, 1
			EXEC [dbo].[psCONV_ObtenirRelDepDateDispo] 1, 1


Parametres de sortie :  Table											Champs							Description
					    -----------------								---------------------------		--------------------------
					    tblCONV_ReleveDepotDateSemestrielleDisponible   iDateID							Identifiant unique de la date		            
																		dtDateReleveSemestriel			Date du relevé semestriel
																		bDateDisponible					Indique si la date est disponible pour consultation ou non
																		bDateDebut						Indique si la date est une date de début ou une date de fin
																										1 si c'est une date de début, 0 sinon

Historique des modifications :
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-11-27					Jean-François Gauthier					Création de la fonction           
						2010-05-10					Jean-François Gauthier					Ajout de la gestion des erreurs
						2011-06-28					Corentin Menthonnex						Ajout de la gestion des dates de
																							début
                        2017-09-27                  Pierre-Luc Simard                       Deprecated - Cette procédure n'est plus utilisée

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirRelDepDateDispo]
( 
	@bDisponible	BIT,
	@bDateDebut		BIT
)
AS
	BEGIN
    SELECT 1/0
    /*
        SET NOCOUNT ON
		BEGIN TRY
			SELECT 
				iDateID					
				,dtDateReleveSemestriel	
				,bDateDisponible	
				,bDateDebut			
			FROM 
				dbo.fntCONV_ObtenirRelDepDateDispo(@bDisponible, @bDateDebut)		
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
        */
	END