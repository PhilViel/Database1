/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc

Code de service		:		IU_UN_OperBNA
Nom du service		:		Créer une operation RIO
But					:		Insertion d'une opération de type BNA et des cotisations liées
Facette				:		OPER
Reférence			:		UniAccés-Noyau-OPER

Parametres d'entrée :	Parametres					Description
						-----------------------------------------------------------------------------------------------------
						iID_Connect				Identifiant de la connexion à la procédure
						iID_Convention			ID qui correspond au numéro de la convention collective
						dtDateTransaction		Date de la transaction à effectuer

Exemple d'appel:
			DECLARE @i INT	
			EXEC @i = [dbo].[IU_UN_OperBNA] 2, 240633, '2010-02-19'
			print @i
	
Parametres de sortie : Table						Champs								Description
					   -----------------			---------------------------			--------------------------
													@iStatut							Statut d'exécution de la procédure 
																						(<0 : Traitement en erreur, >0 : Traitement réussie 
																						(identifiant de l'enregistrement 400))

Historique des modifications :
			
						Date		Programmeur								Description							Référence
						----------	-------------------------------------	----------------------------		---------------
						2010-01-28	Pierre Paquet							Création de la procédure			
						2010-02-01	Jean-François Gauthier					Formatage et ajout d'une gestion d'erreur de base
						2010-02-22	Pierre Paquet							Bogue sur un iConnectID
****************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_OperBNA] 
	(
		@iID_Connect		INT,		-- ID Unique de connexion de l'usager
		@iID_Convention		INT,		-- ID Unique de la convention dont SCEE et SCEE+ sont à rembourser
		@dtDateTransaction	DATETIME	-- Date de la transaction
	)
AS
	BEGIN
		DECLARE 
				@iID_OperID		INT
				,@mSCEE			MONEY
				,@mSCEESup		MONEY
				,@iID_Unit		INT
				,@iStatut		INT
				,@iErrno		INT
				,@iErrSeverite	INT
				,@iErrStatut	INT
				,@vcErrmsg		VARCHAR(1024)
				,@iRetour		INT

		-----------------
		BEGIN TRANSACTION
		-----------------

			BEGIN TRY
				------------------------------------------------------------------------------
				-- Validations
				-- Vérifier s'il y a des montants de SCEE/SCEE+, sinon on ne fait rien, pas d'erreur.

					-- Recherche des montants SCEE et SCEE+
					SELECT 
						@mSCEE		= SUM(fCESG + fCESGINT),
						@mSCEESup	= SUM(fACESG + fACESGINT)
					FROM 
						dbo.fntPCEE_ObtenirSubventionBons (@iID_Convention,NULL,GETDATE())

				------------------------------------------------------------------------------
				IF (@mSCEE+@mSCEESup) > 0 
				BEGIN
					-- Insertion d'une nouvelle opération de type 'BNA'
					INSERT INTO dbo.Un_Oper 
					(
						ConnectID,
						OperTypeID,
						OperDate
					)
					VALUES 
					( 
						@iID_Connect,
						'BNA',
						@dtDateTransaction
					)

					SET @iID_OperID = SCOPE_IDENTITY()
				------------------------------------------------------------------------------
					-- Récupérer le MIN(UnitID) - 
					SELECT 
						@iID_Unit = MIN(U.UnitID)
					FROM 
						dbo.Un_Convention C 
						INNER JOIN dbo.Un_Unit U 
							ON U.ConventionID = C.ConventionID	
					WHERE 
						C.ConventionID = @iID_Convention

				------------------------------------------------------------------------------
					-- Insertion d'une nouvelle cotisation
					INSERT INTO dbo.Un_Cotisation 
					(
						UnitID,
						OperID,
						EffectDate,
						Cotisation,
						Fee,
						BenefInsur,
						SubscInsur,
						TaxOnInsur 
					)
					VALUES 
					( 
						@iID_Unit,
						@iID_OperID,
						@dtDateTransaction,
						0,
						0,
						0,
						0,
						0
					)
				------------------------------------------------------------------------------
					-- Insère les enregistrements 400 de type 21-5 sur l'opération.
					EXECUTE @iRetour = dbo.IU_UN_CESP400ForOper @iID_Connect, @iID_OperID, 21, 5, 3
				END -- Fin du IF (@mSCEE+@mSCEESup) > 0 

				IF @iRetour <= 0 -- UNE ERREUR S'EST PRODUITE LORS DE L'APPEL DE IU_UN_CESP400ForOper
					BEGIN
						SET @iStatut = -1
						--------------------
						ROLLBACK TRANSACTION
						--------------------
					END

				-----------------
				COMMIT TRANSACTION
				-----------------
				SET @iStatut = 1
			END TRY
			BEGIN CATCH
				SELECT										-- RÉCUPÉRATION DES INFORMATIONS CONCERNANT L'ERREUR
					@vcErrmsg		= REPLACE(ERROR_MESSAGE(),'%',' '),
					@iErrStatut		= ERROR_STATE(),
					@iErrSeverite	= ERROR_SEVERITY(),
					@iErrno			= ERROR_NUMBER()

				IF (XACT_STATE()) = -1						-- LA TRANSACTION EST TOUJOURS ACTIVE, ON PEUT FAIRE UN ROLLBACK
					BEGIN
						--------------------
						ROLLBACK TRANSACTION
						--------------------
--						IF @iErrno >= 50000					-- RETOURNE L'ERREUR UTILISATEUR SELON P171 (TOUT CE QUI EST SUPÉRIEUR À 50000 CONSTITUE UN MESSAGE PERSONNALISÉ)
--							BEGIN
--								RAISERROR 50001 'MESSAGE PERSONNALISÉ D''ERREUR !' WITH LOG
--							END
--						ELSE								-- RETOURNE L'ERREUR SYSTÈME
--							BEGIN
--								SET @vErrmsg = CAST(@iErrno AS VARCHAR(6)) + ' : ' + @vErrmsg		-- CONCATÉNATION DU NUMÉRO D'ERREUR INTERNE À SQL SERVEUR
--
--								-- si procédure
--								SET @vErrmsg = @vErrmsg + ', '+ERROR_PROCEDURE()+' line ' + cast(ERROR_LINE() as varchar(10))
--
--								RAISERROR	(@vErrmsg, @iErrSeverity, @iErrState) WITH LOG
--							END
					END
--				ELSE
--					BEGIN
--						SET @vErrmsg = 'AUCUNE TRANSACTION ACTIVE POUR LA SESSION : ' + CAST(@iErrno AS VARCHAR(6)) + @vErrmsg
--						RAISERROR 50001 @vErrmsg
--					END
				RAISERROR	(@vcErrmsg, @iErrSeverite, @iErrStatut) WITH LOG
				SET @iStatut = -1
			END CATCH
	
		RETURN @iStatut
	END


