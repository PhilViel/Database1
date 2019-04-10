
/****************************************************************************************************
Code de service		:		psGENE_EnvoyerCourriel
Nom du service		:		Envois de courriels
But					:		Envois de courriels
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@vcDestinataire				Courriel du destinataire								(obligatoire, si NULL, une erreur utilisateur sera retournée)
						@vcDestinataireCopie		Courriel du destinataire en copie						(optionel, défaut = NULL)
						@vcDestinataireCopieCache	Courriel du destinataire en copie cachée 				(optionel, défaut = NULL)
						@vcSujet					Sujet du courriel										(optionel, défaut = NULL)
						@vcContenuMessage			Contenu du courriel										(obligatoire, si NULL, une erreur utilisateur sera retournée)
						@bHTML						Format du contenu 0 = TEXT, 1 = HTML					(optionel, défaut = 1)
						@iImportance				Importance (0=BASSE, 1=NORMAL, 2=HAUTE)					(optionel, défaut = 1)
						@vcCheminAttachement		Chemin complet (incluant le nom) du fichier à attacher	(optionel, défaut = NULL)
													-- ATTN :	Il faut configurer le paramètre du Database Mail
																correctement pour la dimension des fichiers attachés.
																Par défaut, il est à 1 Meg.
		

Exemple d'appel:
				DECLARE @i AS INTEGER

				EXEC @i = psGENE_EnvoyerCourriel 
								@vcDestinataire				= 'jfgauthier@lgs.com',	
								@vcDestinataireCopie		= NULL,
								@vcDestinataireCopieCache	= NULL,
								@vcSujet					=	 'test complet',	
								@vcContenuMessage			= '<b>test 9</b>',	
								@bHTML						= 1,				
								@iImportance				= 1,				
								@vcCheminAttachement		= NULL,
								@vcProfilCourriel			= 'Notifications - Support Informatique'
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------

Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-05-13					Jean-François Gauthier					Création de procédure stockée 
                        2010-02-24					Jean-François Gauthier					Ajout du profil du courriel à utiliser 
                        2016-05-25                  Steeve Picard                           Standardisation des vieux RaisError
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_EnvoyerCourriel]
					(
						@vcDestinataire				NVARCHAR(2000)	= NULL,
						@vcDestinataireCopie		NVARCHAR(2000)	= NULL,
						@vcDestinataireCopieCache	NVARCHAR(2000)	= NULL,
						@vcSujet					NVARCHAR(255)	= NULL,
						@vcContenuMessage			NVARCHAR(MAX)	= NULL,
						@bHTML						BIT				= 1,
						@iImportance				VARCHAR(6)		= 1,
						@vcCheminAttachement		NVARCHAR(2000)	= NULL,
						@vcProfilCourriel			VARCHAR(255)	= NULL					
					)
AS
	BEGIN
		SET NOCOUNT ON

		DECLARE		@iErrno			INT,
					@iErrSeverity	INT,
					@iErrState		INT,
					@vErrmsg		NVARCHAR(1024),
					@iExecStatus	INT				-- statut d'exécution de la procédure (0<=en erreur, >0=succès)

		BEGIN TRY
			-- VALIDATION DES PARAMÈTRE OBLIGATOIRES
			IF (NULLIF(LTRIM(RTRIM(@vcDestinataire)),'') IS NULL) OR (NULLIF(LTRIM(RTRIM(@vcContenuMessage)),'') IS NULL)
				BEGIN
					-- ON LÈVE UNE ERREUR UTILISATEUR
					SELECT 
							@iErrno			= 50009,
							@vErrmsg 		= 'Destinataire et / ou contenu du message invalide',
							@iExecStatus	= -1
					RAISERROR (@vErrmsg, 10, 1)	
				END
			ELSE
				BEGIN
					DECLARE @vcFormat		VARCHAR(20),
							@vcImportance	VARCHAR(6)

					SELECT 
						@vcFormat		=		CASE @bHTML
													WHEN 1 THEN 'HTML'
													ELSE		'TEXT'
												END,
						@vcImportance	=		CASE @iImportance
													WHEN 0 THEN 'LOW'
													WHEN 1 THEN 'NORMAL'
													ELSE		'HIGH'
												END

					-- Le FROM n'est pas spécifié, car il correspond
					-- au compte configuré dans le Database MAIL
					IF @vcProfilCourriel IS NULL
						BEGIN
							EXECUTE msdb.dbo.sp_send_dbmail
													@recipients				=	@vcDestinataire,
													@copy_recipients		=	@vcDestinataireCopie,
													@blind_copy_recipients	=	@vcDestinataireCopieCache,
													@subject				=	@vcSujet,
													@body					=	@vcContenuMessage,
													@body_format			=	@vcFormat,
													@importance				=   @vcImportance,
													@file_attachments		=	@vcCheminAttachement
						END
					ELSE
						BEGIN
							EXECUTE msdb.dbo.sp_send_dbmail
													@profile_name			=	@vcProfilCourriel,
													@recipients				=	@vcDestinataire,
													@copy_recipients		=	@vcDestinataireCopie,
													@blind_copy_recipients	=	@vcDestinataireCopieCache,
													@subject				=	@vcSujet,
													@body					=	@vcContenuMessage,
													@body_format			=	@vcFormat,
													@importance				=   @vcImportance,
													@file_attachments		=	@vcCheminAttachement
						END

					SET @iExecStatus = 1
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
	END
