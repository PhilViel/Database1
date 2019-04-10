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
Code de service		:		psCONV_ObtenirDonneeReleveDepot
Nom du service		:		Obtenir toutes les données nécessaire pour l'impression du relevé de dépôt    
But					:		Récupérer toutes les données nécessaire pour l'impression du relevé de dépôt
Facette				:		P171U
Reférence			:		Relevé de dépôt

Parametres d'entrée :	Parametres					Description                                 Obligatoir
                        ----------                  ----------------                            --------------                       
                        dtDateDebut                 Date début du relevé de dépôt               Non
						dtDateFin                   Date fin du relevé de dépôt                 Oui
                        iSubscriberID               Identifiant unique du souscripteur          Non
                        @bIsSave                    Indique si on doit sauvegarder les données
                                                    dans une table physique


Exemple d'appel:
		
				EXECUTE dbo.[psCONV_ObtenirDonneeReleveDepot] NULL, NULL, NULL, NULL

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------

Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-12-05					Fatiha Araar							Création de la fonction 
                        2009-01-27                  Fatiha Araar                            Corrcection 
                        2009-02-03                  Fatiha Araar                            Ajouter les montants IQEE         
						2009-02-13					Dan Trifan								Implantation des traitements en parallèe. 
																							Les traitements sont deplacés dans 
																								dbo.psCONV_ObtenirDonneeReleveDepot_Prep
																								dbo.psCONV_ObtenirDonneeReleveDepot_EXEC
																							Cette sp n'utilise qu'un seul procès
																							Pour l'apèl en 'multiprocès' utiliser 
																								dbo.psCONV_ObtenirDonneeReleveDepot_StartSSIS
						2010-05-05					Jean-François Gauthier					Ajout de la gestion des erreurs																						
                        2017-09-27                  Pierre-Luc Simard                       Deprecated - Cette procédure n'est plus utilisée
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_ObtenirDonneeReleveDepot]
	                        @dtDateDebut DATETIME,-- Date début du relevé
						    @dtDateFin DATETIME,-- Date fin du relevé
                            @iSubscriberID INT, -- Identifiant unique du souscripteur
                            @bIsSave BIT -- Indique si on doit générer les données du rapport ou juste faire un select (1 = Oui)
AS
	BEGIN
        SELECT 1/0
        /*
		BEGIN TRY
			IF @iSubscriberID IS NOT NULL
				SET @bIsSave = 1

			IF @bIsSave = 1
				BEGIN
					EXEC psCONV_ObtenirDonneeReleveDepot_Prep @dtDateFin=@dtDateFin,@iSubscriberID=@iSubscriberID

					EXECUTE [dbo].[psCONV_ObtenirDonneeReleveDepot_EXEC] @dtDateDebut = @dtDateDebut,@dtDateFin = @dtDateFin,
								@iSubscriberID = @iSubscriberID,@bIsSave = @bIsSave,@inbProcesses = 10,@iNoprocess = -1
					SELECT * 
					FROM dbo.tblCONV_DonneeReleveDepot
					WHERE iIDSouscripteur = @iSubscriberID OR @iSubscriberID IS NULL 
					ORDER BY iIDSouscripteur,iIDBeneficiaire,iIDConvention,vcRegime,vcTypeDonnee DESC, dtDateOperation ASC
				END
			ELSE
					SELECT * 
					FROM dbo.tblCONV_DonneeReleveDepot
					WHERE iIDSouscripteur = @iSubscriberID OR @iSubscriberID IS NULL 
					ORDER BY iIDSouscripteur,iIDBeneficiaire,iIDConvention,vcRegime,vcTypeDonnee DESC, dtDateOperation ASC
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
		
		RETURN
        */
	END