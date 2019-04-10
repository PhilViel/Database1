/****************************************************************************************************
 * Copyrights (c) 2008 Gestion Universitas inc
 * 
 * Code du service             : psSECU_UtilisateurSQL
 * Nom du service              : Gestion des utilisateurs SQL
 * But                         : Check, Ajoute, supprime un utilisateur SQL
 * Facette                     : Module securité
 * Reférence                   : non disponible
 * 
 * Parametre d'entrée          : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               @vcLoginNameID                      Login de l'utilisateur
 *                               @vcPassWordID                       Password de l'utilisateur
 *                               @vcDataBase                         Database en cours (ATTENTION NE FONCTIONNE PAS)
 *                               @iAction                            Action a realiser
 *                                                                   0 : Check, 1 : ajout, 2 : suppression
 *
 * Parametre de sortie         : Parametre                           Description 
 *                               ----------------------------------- ------------------------------------
 *                               @Value                              0 : Erreur, 1 : Existe, -1 : n'existe pas, 2 : est créé, 3 : est supprimé
 * 
 * Historique des modification : Date       Programmeur              Description                          Référence
 *                               ---------- ------------------------ ------------------------------------ -------------------
 *                               2008-08-15 Patrice Péau             Création du document                 
 *								 2009-06-17 Jean-François Gauthier	 Ajout des [] autour de la variable @vcLoginNameID pour régler le bug de certains noms d'usager
 *								 2009-06-19	Jean-François Gauthier	 Alias, commentaire, formatage de la requête
 ****************************************************************************************************************************/
CREATE PROCEDURE [dbo].[psSECU_UtilisateurSQL] 
	@vcLoginNameID	VARCHAR(255) ,		--Recuperation LoginNameID
	@vcPassWordID	VARCHAR(255) ,		--Recuperation PassWordID
	@vcDataBase		VARCHAR(255) ,		--Recuperation Nom de la base de données
	@iAction		INT                 --Recuperation Action à executer
AS
	BEGIN

		DECLARE
			@Value VARCHAR(75);
			SET @Value = 0 -- Par defaut on retourne 0

		IF ( @iAction = 0 )
		--Check Utilisateur 
			IF EXISTS(SELECT name FROM sys.sql_logins WHERE name = @vcLoginNameID)	
				SET @Value = 1 -- Il existe retourne 1
			ELSE 
				SET @Value = -1 -- Il existe pas retourne -1
			
		IF ( @iAction = 1 )
		--Ajout Utilisateur 
			BEGIN
			EXEC('CREATE LOGIN [' + @vcLoginNameID + '] WITH PASSWORD=''' + @vcPassWordID + ''', DEFAULT_DATABASE=' + @vcDataBase + '')
			EXEC('sys.sp_addsrvrolemember @loginame  =[' + @vcLoginNameID + '], @rolename = N''sysadmin''')
			EXEC('ALTER LOGIN [' + @vcLoginNameID + '] ENABLE')		SET @Value = 2 -- Il est créé on retourne  2		
			END

		IF ( @iAction = 2 )
		--Suppression Utilisateur 
			BEGIN
			EXEC sp_droplogin @vcLoginNameID		
			SET @Value = 3 -- Il est suppriméé on retourne 3
			END

		SELECT @Value 

		RETURN (@Value)
	END
