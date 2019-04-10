/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_FichierRepertoireExiste
Nom du service		: Vérifier l'existence d'un répertoire ou d'un fichier.
But 				: Vérifier l'existence d'un répertoire ou d'un fichier sur un disque du réseau.
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@vcRepertoire				Nom du répertoire.
						@vcNom_Fichier				Nom du fichier.

Exemple d’appel		:	
				DECLARE @i INT
				EXECUTE @i = [dbo].[psGENE_FichierRepertoireExiste] '\\gestas2\departements\IQEE\Fichiers\Transmis\','TEST.TXT'
				SELECT @i

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					1 = Le répertoire et le fichier
																						n'existe pas
																					2 = Le répertoire existe mais le
																						fichier n'existe pas
																					3 = Le répertoire et le nom
																						existent

Historique des modifications :
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-02-12		Éric Deshaies						Création du service							
		2010-03-23		Éric Deshaies						Ajout de message qui indique que le
															répertoire n'existe pas ou est inaccessi-
															ble
		2010-05-06		Jean-François Gauthier				Ajout de la gestion des erreurs
		2011-03-09		Éric Deshaies						Correction d'un bug
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_FichierRepertoireExiste]
(
	@vcRepertoire VARCHAR(200),
	@vcNom_Fichier VARCHAR(150)
)
AS
	BEGIN
		BEGIN TRY
			-- Retourner 1 si le répertoire est vide
			IF @vcRepertoire IS NULL OR
			   @vcRepertoire = ''
				BEGIN
					RETURN 1
				END

			-- Compléter le répertoire de destination du fichier par le caractère « \ » 
			IF SUBSTRING(@vcRepertoire,LEN(@vcRepertoire),1) <> '\'
				BEGIN
					SET @vcRepertoire = @vcRepertoire + '\'
				END

			DECLARE 
				@vcResultat VARCHAR(1000)

			SET @vcResultat = 'Exec Master..xp_Cmdshell ''DIR /b '+@vcRepertoire+''''

			DECLARE @tblTMP TABLE (vcLigne VARCHAR(300))

			INSERT INTO @tblTMP EXEC (@vcResultat) 

			IF EXISTS (SELECT *
					   FROM @tblTMP
					   WHERE vcLigne LIKE '%Le fichier spécifié est introuvable%'
						  OR vcLigne LIKE '%The system cannot find the file specified%'
						  OR vcLigne LIKE '%The network path was not found%'
						  OR vcLigne LIKE '%The filename, directory name, or volume label syntax is incorrect%'
						  OR vcligne LIKE '%Access is denied%')
				BEGIN
					RETURN 1
				END

			IF @vcNom_Fichier IS NULL OR
			   @vcNom_Fichier = '' OR
			   NOT EXISTS (SELECT *
						   FROM @tblTMP
						   WHERE vcLigne = @vcNom_Fichier)
				BEGIN
					RETURN 2
				END
		
			RETURN 3
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
			RETURN -1
		END CATCH
	END
