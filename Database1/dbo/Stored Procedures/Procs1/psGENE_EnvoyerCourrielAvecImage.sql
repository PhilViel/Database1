
/****************************************************************************************************
Code de service		:		psGENE_EnvoyerCourrielAvecImage
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
						@vcFrom						Courriel de l'envoyeur
						@iHauteurImage				Hauteur de l'image en pixels
						@iLargeurImage				Largeur de l'image en pixel
						@bLangue					Langue pour le logo										0 = français (defaut), 1 = anglais		
		

Exemple d'appel:
				DECLARE @i AS INTEGER

				EXECUTE @i = psGENE_EnvoyerCourrielAvecImage 
								@vcDestinataire				= 'jfgauthier@lgs.com',
								@vcDestinataireCopie		= NULL,
								@vcDestinataireCopieCache	= NULL,
								@vcFrom						= 'jfgauthier@lgs.com',
								@vcSujet					= 'Test de courriel',
								@vcContenuMessage			= '<B>Bonjour,<BR />Ceci est un test de courriel avec <B><U>image intégrée</U></B>',
								@iHauteurImage				= 50,
								@iLargeurImage				= 200,
								@bLangue					= 0
				PRINT @i
								

                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
					   N/A							@iExecStatus								statut d'exécution de la procédure (0<= en erreur, >0 : succès)
	
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-07-13					Jean-François Gauthier					Création de procédure stockée 
                        2009-07-16					Jean-François Gauthier					Ajout du paramètre de langue pour le logo
                        2016-05-25                  Steeve Picard                           Standardisation des vieux RaisError
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_EnvoyerCourrielAvecImage]
					(
						@vcDestinataire				NVARCHAR(2000)	= NULL,
						@vcDestinataireCopie		NVARCHAR(2000)	= NULL,
						@vcDestinataireCopieCache	NVARCHAR(2000)	= NULL,
						@vcFrom						NVARCHAR(2000)	= NULL,
						@vcSujet					NVARCHAR(255)	= NULL,
						@vcContenuMessage			NVARCHAR(4000)	= NULL,
						@iHauteurImage				INT				= NULL,		-- EN PIXEL
						@iLargeurImage				INT				= NULL,		-- EN PIXEL
						@bLangue					BIT				= 0			
					)
AS
	BEGIN
		SET NOCOUNT ON

		DECLARE @CDO			INT,			-- Objet CDO de Windows
				@RBP			INT,			-- Objet Related Body Part
				@iResultat		INT,
				@vcServerSMTP	VARCHAR(75),
				@vcCheminLogo	VARCHAR(2000),
				@vcNomLogo		VARCHAR(500),
				@iErrno			INT,
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

				-- CRÉATION DE L'OBJET
				EXECUTE @iResultat = sp_OACreate 'CDO.Message', @CDO OUTPUT
				IF @iResultat <> 0
					BEGIN
						SELECT 
							@iErrno			= 50010,
							@vErrmsg 		= 'Création de l''object CDO impossible',
							@iExecStatus	= -1
						RAISERROR (@vErrmsg, 10, 2)
					END

				-- RECHERCHE DES PARAMÈTRES
				SELECT @vcServerSMTP = dbo.fnGENE_ObtenirParametre('GENE_SERVEUR_SMTP', NULL, NULL, NULL, NULL, NULL, NULL)
				IF @vcServerSMTP = '-2'
					BEGIN
						SELECT 
							@iErrno			= 50011,
							@vErrmsg 		= 'Paramètre GENE_SERVEUR_SMTP inexistant',
							@iExecStatus	= -1
						RAISERROR (@vErrmsg, 10, 3)
					END
					
				IF @bLangue = 0 -- Français
					BEGIN
						SELECT @vcCheminLogo = dbo.fnGENE_ObtenirParametre('SGRC_CHEMIN_LOGO_COURRIEL', NULL, 'LogoFrancais', NULL, NULL, NULL, NULL)
					END
				ELSE			-- Anglais
					BEGIN
						SELECT @vcCheminLogo = dbo.fnGENE_ObtenirParametre('SGRC_CHEMIN_LOGO_COURRIEL', NULL, 'LogoAnglais', NULL, NULL, NULL, NULL)
					END
					
				IF @vcServerSMTP = '-2'
					BEGIN
						SELECT 
							@iErrno			= 50012,
							@vErrmsg 		= 'Paramètre SGRC_CHEMIN_LOGO_COURRIEL inexistant',
							@iExecStatus	= -1
						RAISERROR (@vErrmsg, 10, 4)
					END

				SET @vcNomLogo = RIGHT(@vcCheminLogo,(CHARINDEX('\', REVERSE(@vcCheminLogo)))-1)
				SET @vcContenuMessage = '<img src="cid:' + @vcNomLogo + '" HEIGHT="' + CAST(@iHauteurImage AS VARCHAR(6)) + '" WIDTH="' + CAST(@iLargeurImage AS VARCHAR(6)) + '"><BR /><BR />' + @vcContenuMessage
				
				-- INITIALISATION DES PROPRIÉTÉS RELATIVES À L'INCORPORATION DE L'IMAGE DANS LE COURRIEL
				EXECUTE @iResultat = sp_OASetProperty @CDO, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/sendusing").Value','2'
				EXECUTE @iResultat = sp_OASetProperty @CDO, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpserver").Value', @vcServerSMTP
				EXECUTE @iResultat = sp_OASetProperty @CDO, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpserverport").Value','25'
	
				EXECUTE @iResultat = sp_OAMethod		@CDO, 'AddRelatedBodyPart', @RBP OUTPUT, @vcCheminLogo, @vcNomLogo, '1'
				SET @vcNomLogo = '<' + @vcNomLogo + '>'
				EXECUTE @iResultat = sp_OASetProperty   @RBP, 'Fields.Item("urn:schemas:mailheader:Content-ID").Value', @vcNomLogo
				EXECUTE @iResultat = sp_OAMethod		@RBP, 'Fields.Update', NULL
				EXECUTE @iResultat = sp_OAMethod		@CDO, 'Configuration.Fields.Update', NULL
	
				-- INITIALISATION DES PROPRIÉT D'ENVOIS DU COURRIEL
				EXECUTE @iResultat = sp_OASetProperty @CDO, 'From',		@vcFrom
				EXECUTE @iResultat = sp_OASetProperty @CDO, 'HTMLBody', @vcContenuMessage
				EXECUTE @iResultat = sp_OASetProperty @CDO, 'Subject',	@vcSujet
				EXECUTE @iResultat = sp_OASetProperty @CDO, 'To',		@vcDestinataire
				EXECUTE @iResultat = sp_OASetProperty @CDO, 'Cc',		@vcDestinataireCopie
				EXECUTE @iResultat = sp_OASetProperty @CDO, 'Bcc',		@vcDestinataireCopieCache

--				IF @vcCheminAttachement IS NOT NULL 
--					BEGIN
--						EXECUTE @iResultat = sp_OAMethod	  @CDO, 'AddAttachment', NULL, @vcCheminAttachement
--						PRINT @iResultat
--						IF @iResultat <> 0
--							BEGIN
--								SELECT 
--									@iErrno			= 50014,
--									@vErrmsg 		= 'Fichier attaché introuvable',
--									@iExecStatus	= -1
--								RAISERROR (@vErrmsg, 10, 5)	
--							END
--					END

				-- ENVOIS DU COURRIEL ET DESTRUCTION DE L'OBJET CDO	
				EXECUTE @iResultat = sp_OAMethod  @CDO, 'Send', NULL
				IF @iResultat <> 0
					BEGIN
						SELECT 
							@iErrno			= 50013,
							@vErrmsg 		= 'Envois du courriel impossible',
							@iExecStatus	= -1
						RAISERROR (@vErrmsg, 10, 6)
					END

				EXECUTE @iResultat = sp_OADestroy @CDO

				SET @iExecStatus	= 1
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
