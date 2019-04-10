/****************************************************************************************************
Copyrights (c) 2013 Gestion Universitas Inc.
Nom                 :	psGENE_ObtenirListeFichierRendement
Description         :	Procédure qui retourne une liste de nom de fichier dans un répertoire donné par le paramètre 
						'DOSSIER_FICHIER_RENDEMENT'. 

Exemple d'appel		:
	exec psGENE_ObtenirListeFichierRendement
	
Valeurs de retours  :	Dataset :
Note                :	2013-07-02	Maxime Martel			Création

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirListeFichierRendement]				
AS
	BEGIN
		BEGIN TRY
			DECLARE @cmd VARCHAR(2000)
			DECLARE @Directory VARCHAR(2000)
			DECLARE @tFileList TABLE (FName VARCHAR(2000))

			SELECT @Directory = dbo.fnGENE_ObtenirParametre ('DOSSIER_FICHIER_RENDEMENT',NULL,NULL,NULL,NULL,NULL,NULL)

			SET @cmd = 'DIR ' + @Directory + '/S' 

			INSERT INTO @tFileList (FName)
			EXEC XP_CMDSHELL @cmd

			-- CONSERVER SEULEMENT LES FICHIER XLS
			DELETE FROM @tFileList WHERE Fname NOT LIKE '%.xls%' OR Fname IS NULL

			-- LE NOM DU FICHIER SE TROUVE À CETTE POSITION
			UPDATE @tFileList SET Fname = SUBSTRING(Fname,40,200)
			
			-- RETOURNER LA LISTE
			SELECT Fname FROM @tFileList where Fname LIKE '%rendement%' order by Fname desc
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


