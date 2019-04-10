/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas Inc.
Nom                 :	psGENE_ObtenirListeFichierTerroriste
Description         :	Procédure qui retourne une liste de nom de fichier dans un réperoire donné par le paramètre 'DOSSIER_FICHIER_TERRORISTE'. 

Exemple d'appel		:
	exec psGENE_ObtenirListeFichierTerroriste '2008','10'
	
Valeurs de retours  :	Dataset :
Note                :	2009-11-11	Donald Huppé			Création
						2010-05-10	Jean-François Gauthier	Ajout de la gestion des erreurs
																		Ajout du "drop" de la procédure
						2011-04-11	Donald Huppé			Modification de @Directory car les fichier ne sont plus déposés dans le sous dossier de l'année et du mois
																		Retourner seulement les fichiers contenant le mot "indstld" pour être certain qu'on ne choisisse pas un fichier non prévu par le traitement.
						2013-05-09	Pierre-Luc Simard	Modifier de 37 à 40 le Substring pour que ça fonctionne sur le nouveau serveur 2008

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirListeFichierTerroriste]
							(
								@Annee VARCHAR(4), -- Avant dernier dossier du path complet qui représentne l'année
								@Mois VARCHAR(2) -- Dernier dossier du path complet qui représente le mois
							)
AS
	BEGIN
		BEGIN TRY
			DECLARE @cmd VARCHAR(2000)
			DECLARE @Directory VARCHAR(2000)
			DECLARE @tFileList TABLE (FName VARCHAR(2000))

			SELECT @Directory = dbo.fnGENE_ObtenirParametre ('DOSSIER_FICHIER_TERRORISTE',NULL,NULL,NULL,NULL,NULL,NULL)

			SET @Directory = @Directory --+ '\' + @Annee + '\' + @Mois

			SET @cmd = 'DIR ' + @Directory + '/S' 

			INSERT INTO @tFileList (FName)
			EXEC XP_CMDSHELL @cmd


			-- CONSERVER SEULEMENT LES FICHIER XLS
			DELETE FROM @tFileList WHERE Fname NOT LIKE '%.xls%' OR Fname IS NULL

			-- LE NOM DU FICHIER SE TROUVE À CETTE POSITION
			UPDATE @tFileList SET Fname = SUBSTRING(Fname,40,200)
			
			-- RETOURNER LA LISTE
			SELECT Fname FROM @tFileList where Fname LIKE '%indstld%' order by Fname desc
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
