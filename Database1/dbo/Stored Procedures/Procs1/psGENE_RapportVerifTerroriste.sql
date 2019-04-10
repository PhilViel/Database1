/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	psGENE_RapportVerifTerroriste
Description         :	Rapport de vérification des terroristes à partir d'une liste Excel de terroriste (ou LIBAN) 
						En autant que la structure du fichier Excel correspond au champ prévu dans la SP
Paramètres			:	

Valeurs de retours  :	DataSET 
							
Note                :	2009-04-24	Donald Huppé					Création
					:	2009-08-11	Donald Huppé					Ajout de l'option de recherche dans le log (@SearchInLog)
						2010-05-11	Jean-François Gauthier	Ajout de la gestion des erreurs
						2011-04-11	Donald Huppé					Modification de @Directory car les fichier ne sont plus déposés dans le sous dossier de l'année et du mois
						2013-04-19	Pierre-Luc Simard			Vider les tables tblTEMP_Terroriste (anciennement TmpTerrorist2) au lieu de la supprimer et la refaire
						2013-05-13	Donald Huppé : depuis sql12, cjanger Excel 8.0 par Excel 12.0

-- se branccher en prod avec le compte SA
-- copier les fichiers sur \\gestas2\dhuppe$\temp\terrorist
-- modifier cette sp à : set @Directory

EXEC psGENE_RapportVerifTerroriste '20130331_ra_indstld_iran', '2009', '11'
EXEC psGENE_RapportVerifTerroriste '20130331_ra_indstld_alkaida', '2009', '11'

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportVerifTerroriste] (--[GU_RP_Terrorist] (
	@FName VARCHAR(255),
	@Annee VARCHAR(4),
	@Mois VARCHAR(2)
	)
AS
	BEGIN
		BEGIN TRY
			DECLARE 
				@Directory VARCHAR(2000),
				@MyString VARCHAR(2000),
				@Source VARCHAR(2000),
				@columns VARCHAR(8000), 
				@Col_Name VARCHAR(255),
				@i INTEGER

			IF EXISTS (SELECT NAME FROM sysobjects WHERE NAME = 'TmpTerrorist')
			BEGIN
				DROP TABLE TmpTerrorist
			END

			TRUNCATE TABLE tblTEMP_Terroriste

			SELECT @Directory = dbo.fnGENE_ObtenirParametre ('DOSSIER_FICHIER_TERRORISTE',NULL,NULL,NULL,NULL,NULL,NULL)

			SET @Directory = @Directory --+ '\' + @Annee + '\' + @Mois

			--set @Directory = '\\gestas2\dhuppe$\temp\terrorist'

			-- Mettre le contenu du fichier dans une TABLE temporaire
			/*
			SET @Source =	'Excel 8.0;Database=' + @Directory + '\' + @FName
			SET @MyString = 
							'SELECT a.* into TmpTerrorist 
							FROM OPENROWSET(''Microsoft.Jet.OLEDB.4.0'', ''' + @Source + ''',
								 ''SELECT *
								  FROM [A$]'') AS a'
			*/
			
			SET @Source =	'Excel 12.0 Xml;Database=' + @Directory + '\' + @FName
			SET @MyString = 
							'SELECT a.* into TmpTerrorist 
							FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', ''' + @Source + ''',
								 ''SELECT *
								  FROM [A$]'') AS a'
			
			print @MyString

			EXEC (@MyString)



			-- Bâtir une string avec le nom des 17 premiers champs de la table
			SET @columns = ''
			DECLARE MyCursor CURSOR FOR
				SELECT column_name FROM information_schema.columns WHERE table_name='TmpTerrorist'
			OPEN MyCursor
			FETCH NEXT FROM MyCursor INTO @Col_Name

			SET @i = 1
			WHILE @@FETCH_STATUS = 0 and @i <= 17
			BEGIN
				SET @columns = @columns + CASE WHEN @i > 1 THEN ',' ELSE '' END + '[' + @Col_Name + ']'
				SET @i = @i + 1
				FETCH NEXT FROM MyCursor INTO @Col_Name
			END
			CLOSE MyCursor
			DEALLOCATE MyCursor


			-- Ce qu'on a dans la TABLE temporaire est supposé avoir des données correspondant aux noms de champs suivant
			/*CREATE TABLE tblTEMP_Terroriste ( 
				F1 VARCHAR(255),
				NOM VARCHAR(255),
				Prenom1 VARCHAR(255),
				Prenom2 VARCHAR(255),
				Prenom3 VARCHAR(255),
				Prenom4 VARCHAR(255),
				LDN VARCHAR(255),
				AltLDN VARCHAR(255),
				DDN VARCHAR(255),
				DDN2 VARCHAR(255),
				DDN3 VARCHAR(255),
				DDN4 VARCHAR(255),
				Nationalite1 VARCHAR(255),
				Nationalite2 VARCHAR(255),
				Nationalite3 VARCHAR(255),
				Titre VARCHAR(2000),
				F17 VARCHAR(255)
				)*/

			-- On insère les données dans la TABLE pour avoir des noms de champs
			SET @MyString = 'INSERT into tblTEMP_Terroriste (F1,NOM,Prenom1,Prenom2,Prenom3,Prenom4,LDN,AltLDN,DDN,DDN2,DDN3,DDN4,Nationalite1,Nationalite2,Nationalite3,Titre,F17) 
							SELECT ' + @columns + ' FROM TmpTerrorist'

			EXEC (@MyString	)

			-- On suprime les données non valides
			DELETE FROM tblTEMP_Terroriste WHERE F1 is null
			

		/*
		DELETE FROM gui.dbo.TGU_Terroristes

		INSERT into gui.dbo.TGU_Terroristes 
		SELECT NOM, Prenom1,Prenom2,Prenom3,Prenom4,DDN,DDN2,DDN3,DDN4 FROM Tmpterrorist2

		EXEC gui.dbo.GU_TT_TerroristesAlQaidaTaliban

		return
		*/

			CREATE TABLE #tTerroristes (
				FirstName VARCHAR (60),
				LastName VARCHAR (60),
				DateNaissance DATETIME,
				Nom VARCHAR (60),
				Prenom1 VARCHAR (60),
				Prenom2 VARCHAR (60),
				Prenom3 VARCHAR (60),
				Prenom4 VARCHAR (60),
				DDN VARCHAR (50), 
				DDN2 VARCHAR (50),
				DDN3 VARCHAR (50),
				DDN4 VARCHAR (50))  
			INSERT INTO #tTerroristes
			SELECT 
				H.FirstName, 
				H.LastName, 
				H.BirthDate,
				T.Nom, 
				T.Prenom1, 
				T.Prenom2, 
				T.Prenom3, 
				T.Prenom4,
				T.DDN,
				T.DDN2,
				T.DDN3,
				T.DDN4
			FROM UnivBase.dbo.Mo_Human H, 
				tblTEMP_Terroriste T
			WHERE T.Nom = H.FirstName
				OR T.Nom = H.LastName 
				OR T.Prenom1 = H.FirstName 
				OR T.Prenom2 = H.FirstName
				OR T.Prenom3 = H.FirstName 
				OR T.Prenom4 = H.FirstName  
				OR T.Prenom1 = H.LastName 
				OR T.Prenom2 = H.LastName 
				OR T.Prenom3 = H.LastName 
				OR T.Prenom4 = H.LastName


			SELECT 	
				T.FirstName, 
				T.LastName, 
				T.DateNaissance,
				T.Nom,
				T.Prenom1,
				T.Prenom2, 
				T.Prenom3, 
				T.Prenom4,
				T.DDN,
				T.DDN2,
				T.DDN3,
				T.DDN4
			FROM #tTerroristes T
			WHERE T.Nom = FirstName AND T.Prenom1 = LastName 
				OR T.Nom = FirstName AND T.Prenom2 = LastName 
				OR T.Nom = FirstName AND T.Prenom3 = LastName 
				OR T.Nom = FirstName AND T.Prenom4 = LastName
				OR T.Nom = LastName AND T.Prenom1 = FirstName 
				OR T.Nom = LastName AND T.Prenom2 = FirstName 
				OR T.Nom = LastName AND T.Prenom3 = FirstName 
				OR T.Nom = LastName AND T.Prenom4 = FirstName 
				OR LTRIM(CASE WHEN T.Nom IS NOT NULL THEN ' ' + RTRIM(T.Nom) ELSE '' END 
					+ CASE WHEN T.Prenom1 IS NOT NULL THEN ' ' + RTRIM(T.Prenom1) ELSE '' END 
					+ CASE WHEN T.Prenom2 IS NOT NULL THEN ' ' + RTRIM(T.Prenom2) ELSE '' END 
					+ CASE WHEN T.Prenom3 IS NOT NULL THEN ' ' + RTRIM(T.Prenom3) ELSE '' END 
					+ CASE WHEN T.Prenom4 IS NOT NULL THEN ' ' + RTRIM(T.Prenom4) ELSE '' END
					) = LTRIM(CASE WHEN T.LastName IS NOT NULL THEN ' ' + RTRIM(T.LastName) ELSE '' END 
						+ CASE WHEN T.FirstName IS NOT NULL THEN ' ' + RTRIM(T.FirstName) ELSE '' END) 	

			IF EXISTS (SELECT NAME FROM sysobjects WHERE NAME = 'TmpTerrorist')
			BEGIN
				DROP TABLE TmpTerrorist
			END
			
			TRUNCATE TABLE tblTEMP_Terroriste
			
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
