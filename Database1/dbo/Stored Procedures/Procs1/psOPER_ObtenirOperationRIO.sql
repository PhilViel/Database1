/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		psOPER_ObtenirOperationRIO
Nom du service		:		Obtenir une opération RIO 
But					:		Obtenir toutes les informations relatives à une opération RIO.
Facette				:		OPER
Reférence			:		UniAccés-Noyau-Oper

Parametres d'entrée :	Parametres					Description
						-----------------			-------------------------------------------
						@iID_Oper_RIO				Identifiant de l'operation RIO à consulter

Exemple d'appel:
				EXECUTE dbo.psOPER_ObtenirOperationRIO 17349210

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
						tblOper_OperationsRIO		iID_Operation_RIO						Identifiant du détail d’une opération RIO.
						tblOper_OperationsRIO		dtDate_Enregistrement					Date d’enregistrement d’une opération RIO.
						Un_Oper						@iID_Oper_RIO							Identifiant de l’opération RIO.
						tblOper_OperationsRIO		iID_Convention_Source					Identifiant de la convention source de l’opération RIO.
						tblOper_OperationsRIO		iID_Unite_Source						Identifiant du groupe d’unité de la convention source de l’opération RIO.
						tblOper_OperationsRIO		iID_Convention_Destination				Identifiant de la convention de destination de l’opération RIO.
						tblOper_OperationsRIO		iID_Unite_Destination					Identifiant du groupe d’unité de la convention de destination de l’opération RIO.
						tblOper_OperationsRIO		bRIO_Annulee							Indicateur si l’opération a été annulée.
						tblOper_OperationsRIO		bRIO_QuiAnnule							Indicateur si l’opération annule une opération RIO originale.
						Un_Oper						@dtOperDateQuiAnnule					Date de l’opération RIO d’annulation.
						Mo_User						@vcUtilisateurQuiAnnule					Nom d’utilisateur de l’opération RIO.
						Un_OperCancelation			@iOperIDQuiAnnule						Identifiant de l’opération RIO annulée.
						Un_Oper						@dtOperDateCas2							Date de l’opération RIO.
						Un_Convention				@vcConventionNoSource					Numéro de la convention collective source 
						Un_Convention				@vcConventionNoDest						Numéro de la convention collective de destination 
						Mo_User						@vcUtilisateurCas2						Nom d’utilisateur de l’opération RIO.
						tblOPER_OperationsRIO		@dtEnregistrementCas2					Date de la réalisation de l’opération 				
						Un_Oper						@dtOperDateCas3							Date de l’opération RIO.				
						Mo_User						@vcUtilisateurCas3						Nom d’utilisateur de l’opération RIO 

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2008-06-19					Nassim Rekkab							Création de procédure stockée
						2010-05-07					Jean-François Gauthier					Ajout de la gestion des erreurs
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_ObtenirOperationRIO](

	@iID_Oper_RIO INTEGER
)
AS
	BEGIN
		BEGIN TRY
			DECLARE @bQuiAnnule BIT,
				@dtOperDate DATETIME,
				@dtOperDateQuiAnnule DATETIME,
				@dtOperDateQuiAnnule2 DATETIME,
				@vcloginUtil VARCHAR(30),
				@dtOperDateQuiAnnuleCas2 DATETIME,
				@dtOperDateCas2 DATETIME,
				@vcConventionNoSource VARCHAR(15),
				@vcConventionNoDest VARCHAR(15),
				@vcloginUtilCas2 VARCHAR(30),
				@dtEnregistrement DATETIME,
				@vcloginUtilCas3 VARCHAR(30),
				@iCancelOper INTEGER,
				@mtEpargnes MONEY
				
			--Va chercher le bit pour l'annulation dans l'opération RIO
			SELECT @bQuiAnnule = OpRIO.bRIO_QuiAnnule
			FROM  tblOPER_OperationsRIO OpRIO
			WHERE OpRIO.iID_Oper_RIO = @iID_Oper_RIO

			IF @bQuiAnnule = 1
			BEGIN

				--Champ 10.--Date opération d'annulation
				SELECT  @dtOperDateQuiAnnule = Oper.OperDate 									 
				FROM Un_Oper Oper 
				WHERE Oper.OperID= @iID_Oper_RIO

				--Champ 11.--Login de l'utilisateur (1er Cas) d'annulation
				SELECT @vcloginUtil = MoUs.LoginNameID
				FROM Mo_User MoUs 
						JOIN Mo_Connect Con ON MoUs.UserID = Con.UserID
						JOIN Un_Oper Op ON  Con.ConnectID = Op.ConnectID
				WHERE Op.OperID= @iID_Oper_RIO

				--Champ 12. Operation de cancelation 
				SELECT @iCancelOper = OpCan.OperSourceID
				FROM Un_OperCancelation OpCan 										
				WHERE OpCan.OperID = @iID_Oper_RIO

				--Champ 13. Date de l'opération RIO Annulé
				SELECT  @dtOperDateCas2 = Oper.OperDate 									 
				FROM Un_Oper Oper 
				WHERE Oper.OperID= @iCancelOper

				--Champ 14.Numero de Convention (Convention Source)
				SELECT @vcConventionNoSource = C.ConventionNo
				FROM  tblOPER_OperationsRIO OperRIO 
				JOIN dbo.Un_Convention C ON (OperRIO.iID_Convention_Destination = C.ConventionID)
				WHERE OperRIO.iID_Oper_RIO = @iID_Oper_RIO

				--Champ 15.Numero de Convention (Convention Destination)
				SELECT @vcConventionNoDest = C.ConventionNo
				FROM  tblOPER_OperationsRIO OperRIO
				JOIN dbo.Un_Convention C ON (OperRIO.iID_Convention_Source = C.ConventionID)
				WHERE OperRIO.iID_Oper_RIO = @iID_Oper_RIO

				--Champ 16--Login de l'utilisateur (2eme Cas) 
				SELECT @vcloginUtilCas2 = MoUs.LoginNameID
				FROM Mo_User MoUs 
					JOIN Mo_Connect Con ON MoUs.UserID = Con.UserID
					JOIN Un_Oper Op ON  Con.ConnectID = Op.ConnectID				
				WHERE Op.OperID = @iCancelOper

				--Champ 17 Date enregistrement
				SELECT  @dtEnregistrement = OperRio.dtDate_Enregistrement									 
				FROM tblOPER_OperationsRIO OperRIO 
				WHERE  OperRIO.iID_Oper_RIO = @iCancelOper

				--Champ 18.Date de l'operation RIO qui annule
				SET @dtOperDateQuiAnnule2 = NULL

				--Champ 19.--Login de l'utilisateur (3eme Cas)
				SET @vcloginUtilCas3 = NULL

			END
			ELSE
			BEGIN
				--Champ 10.--Date opération d'annulation
				SET @dtOperDateQuiAnnule = NULL

				--Champ 11.--Login de l'utilisateur (1er Cas) d'annulation
				SET @vcloginUtil = NULL

				--Champ 12. Operation de cancelation
				SET @iCancelOper = NULL

				--Champ 13. Date de l'opération RIO Annulé
				SELECT  @dtOperDateCas2 = Oper.OperDate 									 
				FROM Un_Oper Oper
				WHERE Oper.OperID= @iID_Oper_RIO

				--Champ 14.Numero de Convention (Convention Source)
				SELECT @vcConventionNoSource = C.ConventionNo
				FROM  tblOPER_OperationsRIO OperRIO 
				JOIN dbo.Un_Convention C ON (OperRIO.iID_Convention_Source = C.ConventionID)
				WHERE OperRIO.iID_Oper_RIO = @iID_Oper_RIO

				--Champ 15.Numero de Convention (Convention Destination)
				SELECT @vcConventionNoDest = C.ConventionNo
				FROM  tblOPER_OperationsRIO OperRIO
				JOIN dbo.Un_Convention C ON (OperRIO.iID_Convention_Destination = C.ConventionID)
				WHERE OperRIO.iID_Oper_RIO = @iID_Oper_RIO

				--Champ 16--Login de l'utilisateur (2eme Cas) 
				SELECT @vcloginUtilCas2 = MoUs.LoginNameID
				FROM Mo_User MoUs 
						JOIN Mo_Connect Con ON MoUs.UserID = Con.UserID
						JOIN Un_Oper Op ON  Con.ConnectID = Op.ConnectID
				WHERE Op.OperID = @iID_Oper_RIO

				--Champ 17 Date enregistrement
				SELECT  @dtEnregistrement = OperRIO.dtDate_Enregistrement
				FROM tblOPER_OperationsRIO OperRIO 
				WHERE OperRIO.iID_Oper_RIO= @iID_Oper_RIO

				--Champ 18.Date de l'operation RIO qui annule
				SELECT  @dtOperDateQuiAnnule2 = OperRIO2.dtDate_Enregistrement
				FROM tblOPER_OperationsRIO OperRIO   
				JOIN un_OperCancelation OpCan ON OperRIO.iID_Oper_RIO = OpCan.OperSourceID     
				JOIN Un_Oper Op ON (OpCan.OperID = Op.OperID)
				JOIN tblOPER_OperationsRIO OperRIO2 ON (OperRIO2.iID_OPER_RIO = Op.OperID)
				WHERE OperRIO.iID_Oper_RIO = @iID_Oper_RIO and OperRIO.bRIO_Annulee = 1
						
				--Champ 19.--Login de l'utilisateur (3eme Cas)
				SELECT @vcloginUtilCas3 = MoUs.LoginNameID									
				FROM tblOPER_OperationsRIO OperRIO 
				JOIN un_OperCancelation OpCan ON OperRIO.iID_Oper_RIO = OpCan.OperSourceID     
				JOIN Un_Oper Op ON (OpCan.OperID = Op.OperID)
				JOIN Mo_Connect Con ON Con.ConnectID = Op.ConnectID
				JOIN Mo_User MoUs ON MoUs.UserID = Con.UserID
				WHERE OperRIO.iID_Oper_RIO = @iID_Oper_RIO and bRIO_Annulee = 1

			END	

			--Affichage des champs (selection de tous les champs)
			SELECT 
					OperRIO.iID_Operation_RIO,
					OperRIO.dtDate_Enregistrement,
					@iID_Oper_RIO AS 'iID_Oper_RIO',
					OperRIO.iID_Convention_Source,
					OperRIO.iID_Unite_Source,
					OperRIO.iID_Convention_Destination,
					OperRIO.iID_Unite_Destination,
					OperRIO.bRIO_Annulee,
					OperRIO.bRIO_QuiAnnule,
					@dtOperDateQuiAnnule AS 'dtOperDateQuiAnnule',
					@vcloginUtil AS 'vcUtilisateurQuiAnnule',
					@iCancelOper AS 'iOperIdQuiAnnule',
					@dtOperDateCas2 AS 'dtOperDateCas2',
					@vcConventionNoSource AS 'vcConventionNoSource',
					@vcConventionNoDest AS 'vcConventionNoDest',
					@vcloginUtilCas2 AS 'vcUtilisateurCas2',
					@dtEnregistrement AS 'dtDateEnregistrementCas2',
					@dtOperDateQuiAnnule2 AS 'dtOperDateCas3',
					@vcloginUtilCas3  AS 'vcUtilisateurCas3'
			FROM 	tblOper_OperationsRIO OperRIO
			WHERE OperRIO.iID_Oper_RIO = @iID_Oper_RIO
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


