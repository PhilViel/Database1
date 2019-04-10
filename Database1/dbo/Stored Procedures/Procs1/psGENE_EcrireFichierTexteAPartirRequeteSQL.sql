/****************************************************************************************************
Code de service		:		psGENE_EcrireFichierTexteAPartirRequeteSQL
Nom du service		:		Écrire un fichier texte à partir d'une requête SQL
But					:		Extraction des données via une requête SQL et sauvegarde dans un fichier texte délimité
Facette				:		GENE

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@vcNomCompletFichier		DOIT CONTENIT LE CHEMIN COMPLET DU FICHIER AVEC SON NOM
						@vcRequeteSQL				REQUÊTE SQL COMPLÈTE (FULLY QUALIFIED), INCLUANT LE NOM DE LA BD
						@vcNomServeurSQL			NOM DU SERVEUR SQL
						@iNbChamp					NOMBRE DE CHAMPS RETOURNÉS PAR LA REQUÊTE
						@cDelimiteur				DÉLIMITEUR DE CHAMP
						@bCreerLinkedServer			INDIQUE SI LA PROCÉDURE DOIT PASSER PAR UN LINKED SERVER (=1) OU NON (=0)
						@bChampLongueurFixe			INDIQUE SI LE CHAMP EST À LONGUEUR FIXE
						@bUnicode					INDIQUE SI LE FICHIER DE SORTIE DOIT ÊTRE EN UNICODE

						N.B.
						TOUS LES PARAMÈTRES SONT OBLIGATOIRES SAUF @cDelimiteur DONT LA
						VALEUR PAR DÉFAUT EST UNE VIRGULE

Exemple d'appel:
				BEGIN TRANSACTION
					DECLARE @i AS INT
					EXECUTE @i = psGENE_EcrireFichierTexteAPartirRequeteSQL 'C:\DTS\Test2.txt', 'SELECT top 5000 cLigne FROM UnivBase_IQEE_Fonc.dbo.tblIQEE_LignesFichier WHERE iID_Fichier_IQEE = 63 ORDER BY iSequence', 'SRV-SQL-2', 5, NULL, 1, 0, 1
					PRINT @i

					DECLARE @i AS INT
					EXECUTE @i = psGENE_EcrireFichierTexteAPartirRequeteSQL 'C:\DTS\Test.txt', 'select FirstName from UnivBase.dbo.Mo_Human', 'SRV-SQL-2', 1, ';', 1, 0, NULL
					PRINT @i
				COMMIT TRANSACTION
                
N.B.
	- Si @bChampLongueurFixe = 1, la procédure ne tient pas compte de la valeur de @cDelimiteur (doit donc être passé à NULL)
								, fonctionne correctement pour des champs de type chaîne de caractères
								, aura une longueur fixe que le type soit VARCHAR ou CHAR	

	- Si @bChampLongueurFixe = 0, si @cDelimiteur = NULL alors les champs seront concaténés ensembles 
								  sinon, les champs sont séparés par le délimiteur (tous les espaces sont éliminés)

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------

Historique des modifications :
			
        Date			Programmeur						Description							Référence
        ----------		----------------------------	----------------------------		---------------
        2009-07-23		Jean-François Gauthier			Création de procédure stockée 
        2009-07-28		Jean-François Gauthier			Ajout de la gestion d'erreur
        2009-07-29		Jean-François Gauthier			Correction pour que l'ordre des champs dans le fichier, soit le même que dans la requête
        2009-07-30		Jean-François Gauthier			Ajout du paramètre de création du linked server
												        Ajout de la détection préalable du linked server pour suppression éventuelle
        2009-09-15		Jean-François Gauthier			Ajout du WITH LOG manquant sur les RaisError
												        Modification pour le contrôle des transactions car il est techniquement impossible de créer dynamiquement un LINKED SERVER dans une transaction
        2009-09-23		Jean-François Gauthier			Modification pour remplacer le FSO par un SQLCMD
        2009-09-28		Jean-François Gauthier			Modification afin de gérer les longueurs fixes versus les champs délimités
        2009-09-30		Jean-François Gauthier			Ajout de la gestion de codes de caractères Unicode en sortie
        2009-10-30		Jean-François Gauthier			Ajout de la clause ORDER BY
        2013-10-10		Pierre-Luc Simard				Ne plus supprimer le serveur lié Loopback si ce dernier existe 
												        (Problème de sécurité pour le recréer car les comptes ne sont plus sysadmin)
        2015-12-21      Steeve Picard                   Élargissement du paramètre @vcRequeteSQL pour les requêtes plus longues
        2016-02-18		Patrice Côté   				    Ajout du nom de serveur en paramètre à l'appel de sqlcmd
        2016-02-19		Steeve Picard					Simplification de la construction de la requête SQL dans la variable « @vcSQL »
        2016-05-13      Steeve Picard                   Correction du « RAISERROR »
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_EcrireFichierTexteAPartirRequeteSQL]
(
	@vcNomCompletFichier	VARCHAR(2000)				-- DOIT CONTENIT LE CHEMIN COMPLET DU FICHIER AVEC SON NOM
	,@vcRequeteSQL			VARCHAR(max)				-- REQUÊTE SQL COMPLÈTE (FULLY QUALIFIED), INCLUANT LE NOM DE LA BD
	,@vcNomServeurSQL		VARCHAR(255)				-- NOM DU SERVEUR SQL
	,@iNbChamp				INT							-- NOMBRE DE CHAMPS RETOURNÉS PAR LA REQUÊTE
	,@cDelimiteur			CHAR(1)						-- DÉLIMITEUR DE CHAMP
	,@bCreerLinkedServer	BIT				= 1			-- CRÉATION D'UN LINKED SERVER OU NON
	,@bChampLongueurFixe	BIT				= 0			-- INDIQUE SI LE CHAMP EST À LONGUEUR FIXE
	,@bUnicode				VARCHAR(255)	= 0			-- INDIQUE SI LE FICHIER DE SORTIE DOIT ÊTRE EN UNICODE
)
AS
BEGIN
	SET NOCOUNT ON

	-- DÉCLARATION DES VARIABLRES
	DECLARE		
		@vcSQL					VARCHAR(8000)
		,@vcNomTableTmpGlobal	VARCHAR(255)
		,@vcChamp				VARCHAR(255)
		,@vcChampFormatte		VARCHAR(1000)
		,@iPsStatut				INT					-- STATUT D'EXCUTION DE LA PROCÉDURE STOCKÉE
		,@iErrno				INT
		,@iErrSeverity			INT
		,@iErrState				INT
		,@nvErrmsg				NVARCHAR(1024)
		,@iExecStatus			INT	
		,@bTransactionActive	BIT	
		,@vcNomBD				VARCHAR(255)
		,@vcUnicode				VARCHAR(3)

	BEGIN TRY
		-- INITIALISATION DE LA VARIABLE QUI VÉRIFIE SI UNE TRANSACTION EST ACTIVE
		SET @bTransactionActive = 0

		-- VALIDATION DES PARAMÈTRES OBLIGATOIRES
		IF (NULLIF(LTRIM(RTRIM(@vcNomCompletFichier)),'') IS NULL) OR (NULLIF(LTRIM(RTRIM(@vcRequeteSQL)),'') IS NULL)
			OR (NULLIF(LTRIM(RTRIM(@vcNomServeurSQL)),'') IS NULL) OR (NULLIF(@iNbChamp,0) IS NULL)
		BEGIN
			-- ON LÈVE UNE ERREUR UTILISATEUR
			SELECT 
					@iErrno			= 50001,
					@nvErrmsg 		= 'Paramètre(s) invalide(s)'

			RAISERROR (@iErrno, 16, 1, @nvErrmsg	)
		END
				
		-- CRÉATION DYNAMIQUE DU LINKED SERVER LOOPBACK
		IF @bCreerLinkedServer = 1
			BEGIN
				IF XACT_STATE() = 1 -- UNE TRANSACTION EST EN COURS
					BEGIN
						COMMIT TRANSACTION
						SET @bTransactionActive = 1
					END
						
				-- EXECUTE master.dbo.sp_dropserver @server=N'loopback', @droplogins='droplogins'
				IF NOT EXISTS (SELECT srv.name FROM sys.servers srv WHERE srv.server_id != 0 AND srv.name = N'loopback')
					BEGIN
						SET @vcNomServeurSQL = @vcNomServeurSQL
						EXECUTE master.dbo.sp_addlinkedserver @server = N'loopback', @provider=N'SQLNCLI', @datasrc=@vcNomServeurSQL, @srvproduct = N''
						EXECUTE master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'loopback',@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL
						EXECUTE master.dbo.sp_serveroption @server=N'loopback', @optname=N'collation compatible', @optvalue=N'false'
						EXECUTE master.dbo.sp_serveroption @server=N'loopback', @optname=N'data access', @optvalue=N'true'
						EXECUTE master.dbo.sp_serveroption @server=N'loopback', @optname=N'dist', @optvalue=N'false'
						EXECUTE master.dbo.sp_serveroption @server=N'loopback', @optname=N'pub', @optvalue=N'false'
						EXECUTE master.dbo.sp_serveroption @server=N'loopback', @optname=N'rpc', @optvalue=N'false'
						EXECUTE master.dbo.sp_serveroption @server=N'loopback', @optname=N'rpc out', @optvalue=N'false'
						EXECUTE master.dbo.sp_serveroption @server=N'loopback', @optname=N'sub', @optvalue=N'false'
						EXECUTE master.dbo.sp_serveroption @server=N'loopback', @optname=N'connect timeout', @optvalue=N'0'
						EXECUTE master.dbo.sp_serveroption @server=N'loopback', @optname=N'collation name', @optvalue=null
						EXECUTE master.dbo.sp_serveroption @server=N'loopback', @optname=N'lazy schema validation', @optvalue=N'false'
						EXECUTE master.dbo.sp_serveroption @server=N'loopback', @optname=N'query timeout', @optvalue=N'0'
						EXECUTE master.dbo.sp_serveroption @server=N'loopback', @optname=N'use remote collation', @optvalue=N'true'
					END 
			END
					
		-- INSERTION DES DONNÉES DANS UNE TABLE TEMPORAIRE GLOBALE
		SET @vcNomTableTmpGlobal = '##tmpTable' + CAST(DATEPART(yyyy,GETDATE()) AS VARCHAR(4)) + 
												CAST(DATEPART(mm,GETDATE()) AS VARCHAR(2)) + 
												CAST(DATEPART(dd,GETDATE()) AS VARCHAR(2)) + 
												CAST(DATEPART(hh,GETDATE()) AS VARCHAR(2)) + 
												CAST(DATEPART(mi,GETDATE()) AS VARCHAR(2)) + 
												CAST(DATEPART(ss,GETDATE()) AS VARCHAR(2)) + 
												CAST(DATEPART(ms,GETDATE()) AS VARCHAR(3))

		SET @vcSQL = 'SELECT tmp.*,  iIDRESULTATID = ROW_NUMBER() OVER (ORDER BY GETDATE())' +
						' INTO ' + @vcNomTableTmpGlobal + 
                        '	FROM OPENQUERY(loopback, ' + CHAR(39) + @vcRequeteSQL + CHAR(39) + ') AS tmp'
		EXECUTE(@vcSQL)

		-- SELECTION DES DONNÉES DE CHAMP ET FORMATAGE AVEC LE DÉLIMITEUR POUR INSCRIPTION DANS LE FICHIER
		SET @vcSQL = ' DECLARE curChamp CURSOR GLOBAL FOR ' 
					+ ' SELECT COLUMN_NAME FROM tempdb.INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME LIKE ' 
					+ CHAR(39) + @vcNomTableTmpGlobal + '%'  + CHAR(39) 
					+ ' AND ORDINAL_POSITION <= ' + CAST(@iNbChamp AS VARCHAR(3))
		EXECUTE(@vcSQL)

		SET @vcChampFormatte = ''		-- INITIALISATION DE LA VARIABLE CONTENANT LA LISTE FORMATTÉE DES CHAMPS

		OPEN curChamp
		FETCH NEXT FROM curChamp INTO @vcChamp
		WHILE @@FETCH_STATUS = 0
			BEGIN
				-- PERMET DE FORMAT LES CHAMPS DATES CORRECTEMENT S'ILS EXISTENT
				--SET @vcChamp = ' ISNULL(CONVERT(VARCHAR(MAX), ' + @vcChamp + ', 121),'''')'

				-- CONCATENATION DES VALEURS
				IF LEN(@vcChampFormatte) = 0
					BEGIN
						SET @vcChampFormatte = @vcChamp
					END
				ELSE
					BEGIN
						SET @vcChampFormatte = @vcChampFormatte  + ',' + @vcChamp
					END

				-- FETCH LE PROCHAIN ENREGISTREMENT
				FETCH NEXT FROM curChamp INTO @vcChamp
			END
		CLOSE curChamp
		DEALLOCATE curChamp


		-- CRÉATION DU FICHIER ET ÉCRITURE DES DONNÉES
		SET @vcNomBD=DB_NAME()
				
		SET @vcSQL ='sqlcmd -S"' + @vcNomServeurSQL + '" -d "' + @vcNomBD + '" ' +
		                  ' -Q "SET NOCOUNT ON; SELECT '+ @vcChampFormatte + ' FROM ' + @vcNomTableTmpGlobal + ' ORDER BY iIDRESULTATID "' +
						  ' -h -1 '
					       
		IF @bChampLongueurFixe = 1	-- CHAMP À LONGUEUR FIXE, ON CONSERVE LES ESPACES
			SET @vcSQL = @vcSQL + ' -k 1 -s ""'
		ELSE
		BEGIN 
			SET @vcSQL = @vcSQL + ' -W'
			IF @cDelimiteur IS NULL
				SET @vcSQL = @vcSQL + ' -k 1 -s ""'
			ELSE
				SET @vcSQL = @vcSQL + ' -s "' + @cDelimiteur + '"'
		END

		IF IsNull(@bUnicode, 0) = 1
			SET @vcSQL = @vcSQL + ' -u'

		SET @vcSQL = @vcSQL + ' -o "' + @vcNomCompletFichier + '"'

        EXECUTE master..xp_cmdshell @vcSQL

		-- SUPPRESION DE LA TABLE TEMPORAIRE GLOBALE
		SET @vcSQL = ' DROP TABLE ' + @vcNomTableTmpGlobal
		EXECUTE(@vcSQL)

		/*
		-- DESCTRUCTION DU LINKED SERVER
		IF  EXISTS (SELECT srv.name FROM sys.servers srv WHERE srv.server_id != 0 AND srv.name = N'loopback')
			BEGIN
				EXECUTE master.dbo.sp_dropserver @server=N'loopback', @droplogins='droplogins'
			END
		*/
				
		-- RÉINITIALISATION DE LA TRANSACTION SI ELLE ÉTAIT INACTIVE
		IF @bTransactionActive = 1	
			BEGIN
				BEGIN TRANSACTION
				SET @bTransactionActive = 0
			END

		SET @iPsStatut = 1
	END TRY
	BEGIN CATCH
		IF @bTransactionActive = 1	
			BEGIN
				BEGIN TRANSACTION
			END

		SELECT	@nvErrmsg		= REPLACE(ERROR_MESSAGE(),'%',' '),
				@iErrState		= ERROR_STATE(),
				@iErrSeverity	= ERROR_SEVERITY(),
				@iErrno			= ERROR_NUMBER()

		SET @nvErrmsg = CAST(@iErrno AS VARCHAR(6)) + ' : ' + @nvErrmsg 	-- CONCATÉNATION DU NUMÉRO D'ERREUR INTERNE À SQL SERVEUR
		RAISERROR	(@nvErrmsg, @iErrSeverity, @iErrState) WITH LOG

		SET @iPsStatut = -1
	END CATCH

	RETURN @iPsStatut
END
