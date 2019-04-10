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
Code de service		:		dbo.psCONV_EnregistrerRelDepDateDispo
Nom du service		:		psCONV_EnregistrerRelDepDateDispo
But					:		Récupérer les dates de disponibilité des relevés de dépôt semestriels
Facette				:		
Reférence			:		Relevé de dépôt

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
                        @iDateID					Identitifiant unique de la date à modifier	Oui
						@bDateDisponible			Indicateur si disponible ou non				Oui

Exemple d'appel:
			select * from dbo.tblCONV_ReleveDepotDateSemestrielleDisponible
			DECLARE @i INT
			EXECUTE @i = [dbo].[psCONV_EnregistrerRelDepDateDispo] 1, 1
			PRINT @i


Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
						n/a							@iExecStatus								= 1 si traitement réussi et -1 sinon						                       

Historique des modifications :
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-10-02					Jean-François Gauthier					Création de la procédure           
						2016-05-25                  Steeve Picard                           Standardisation des vieux RaisError
						2017-09-27                  Pierre-Luc Simard                       Deprecated - Cette procédure n'est plus utilisée

  ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_EnregistrerRelDepDateDispo]
	( 
		@iDateID				INT, 
		@bDateDisponible		BIT
	)
AS
	BEGIN
		SELECT 1/0
        /*
		DECLARE		@iErrno			INT,
					@iErrSeverity	INT,
					@iErrState		INT,
					@vErrmsg		NVARCHAR(1024),
					@iExecStatus	INT		

		BEGIN TRY
			IF (@iDateID IS NOT NULL) AND (@bDateDisponible IS NOT NULL)
				BEGIN
					UPDATE	dbo.tblCONV_ReleveDepotDateSemestrielleDisponible
					SET		bDateDisponible = @bDateDisponible
					WHERE	iDateID			= @iDateID

					SET @iExecStatus = 1
				END
			ELSE
				BEGIN
					SELECT 
							@iErrno			= 50002,
							@vErrmsg 		= 'Paramètres invalides',
							@iExecStatus	= -1

					RAISERROR (@vErrmsg, 10, 1)	
				END
		END TRY
		BEGIN CATCH
			SELECT	@vErrmsg		= REPLACE(ERROR_MESSAGE(),'%',' '),
					@iErrState		= ERROR_STATE(),
					@iErrSeverity	= ERROR_SEVERITY(),
					@iErrno			= ERROR_NUMBER(),
					@iExecStatus	= -1

			SET @vErrmsg = CAST(@iErrno AS VARCHAR(6)) + ' : ' + @vErrmsg 	-- CONCATÉNATION DU NUMÉRO D'ERREUR INTERNE À SQL SERVEUR
			RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState)
		END CATCH

		RETURN @iExecStatus
        */
	END