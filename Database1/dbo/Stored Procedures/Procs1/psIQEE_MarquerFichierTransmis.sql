/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_MarquerFichierTransmis
Nom du service        : Marquer un fichier comme transmis à RQ 
But                 : Renommer le fichier physique avec la date du jour pour respecter les NID qui requière la date
                      d'envoi dans le nom du fichier et marquer un fichier de l’IQÉÉ comme étant transmis à RQ avant
                      de le téléverser via SFTP.
Facette                : IQÉÉ

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------
                          iID_Fichier_IQEE            Identifiant unique du fichier transmis.
                        iID_Utilisateur_Transmis    Identifiant unique de l'utilisateur qui fait la transmission.  
                                                    S’il n’est pas spécifié, le service considère l’utilisateur système.

Exemple d’appel        :    EXECUTE [dbo].[psIQEE_MarquerFichierTransmis] 9, 519626, 'FRA'

Paramètres de sortie:    Table                        Champ                            Description
                          -------------------------    ---------------------------     ---------------------------------
                        S/O                            iCode_Retour                    0 = Traitement réussi
                                                                                    -1 = Paramètres incomplets
                                                                                    -2 = Erreur de traitement
                                                                                    -3 = Fichier de transactions
                                                                                         introuvable
                                                                                    -4 = Fichier de transactions
                                                                                         renommer introuvable

Historique des modifications:
        Date            Programmeur                            Description                                    Référence
        ------------    ----------------------------------    -----------------------------------------    ------------
        2008-11-04        Éric Deshaies                        Création du service                            
        2009-04-16        Éric Deshaies                        Envoyer un courriel annonçant que le fichier
                                                            a été transmis à RQ.
        2009-10-27        Éric Deshaies                        Mise à niveau selon les normes de développement
        2010-03-30        Éric Deshaies                        Appliquer sur l'ensemble du fichier physique,
                                                            courriel bilingue, renommer le fichier pour
                                                            qu'il représente la date d'envoi.
        2010-05-07        Éric Deshaies                        Correction du courriel vide parce que
                                                            manque de données
        2010-08-03        Éric Deshaies                        Mise à niveau sur la traduction des champs
        2010-08-25        Éric Deshaies                        Ajout de messages à l'interface pour
                                                            informer l'utilisateur des problèmes reliés
                                                            au renommage du fichier.
        2011-03-28        Éric Deshaies                        Correction d'un bug.  Il ne mettait pas à jour
                                                            le statut des fichiers parce que le nom du
                                                            fichier avait été renommé.
        2017-09-14      Steeve Picard                       Modification des paramètres de «fnIQEE_FormaterChamp»
        2018-02-08      Steeve Picard                       Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
****************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_MarquerFichierTransmis 
(
    @iID_Fichier_IQEE INT,
    @iID_Utilisateur_Transmis INT,
    @cID_Langue CHAR(3) = NULL
)
AS
BEGIN
    -----------------
    -- Initialisation
    -----------------
    DECLARE @vcNom_Fichier VARCHAR(50),
            @vcNouveau_Nom_Fichier VARCHAR(50),
            @dtDate_Envoi DATETIME,
            @vcResultat VARCHAR(1000),
            @iResultat INT,
            @vcChemin_Fichier VARCHAR(150),
            @ErrorMessage2 NVARCHAR(4000)

    -- Retourner -1 s'il y a des paramètres manquants ou que le fichier n'existe pas
    IF @iID_Fichier_IQEE IS NULL OR @iID_Fichier_IQEE = 0 OR
       NOT EXISTS(SELECT * 
                  FROM tblIQEE_Fichiers
                  WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE)
        RETURN -1

    -- Prendre l'utilisateur du système s'il est absent en paramètre
    IF @iID_Utilisateur_Transmis IS NULL OR @iID_Utilisateur_Transmis = 0 OR
       NOT EXISTS(SELECT * 
                  FROM Mo_User
                  WHERE UserID = @iID_Utilisateur_Transmis)
        SELECT TOP 1 @iID_Utilisateur_Transmis = iID_Utilisateur_Systeme
        FROM Un_Def

    -- Considérer le français par défaut
    IF @cID_Langue IS NULL
        SET @cID_Langue = 'FRA'

    -- Déterminer le nom du fichier physique basé sur le fichier logique passé en paramètre
    SELECT @vcNom_Fichier = F.vcNom_Fichier,
           @vcChemin_Fichier = F.vcChemin_Fichier
    FROM tblIQEE_Fichiers F
    WHERE F.iID_Fichier_IQEE = @iID_Fichier_IQEE

    SET XACT_ABORT ON

    BEGIN TRANSACTION

    BEGIN TRY
        ---------------------------------------------------
        -- Déterminer une date/heure de transmission unique
        ---------------------------------------------------
        SET @vcNouveau_Nom_Fichier = @vcNom_Fichier

        WHILE EXISTS(SELECT *
                     FROM tblIQEE_Fichiers F
                     WHERE F.vcNom_Fichier = @vcNouveau_Nom_Fichier)
            BEGIN
                WAITFOR DELAY '00:00:01'
                SET @dtDate_Envoi = GETDATE()

                SET @vcNouveau_Nom_Fichier = SUBSTRING(@vcNom_Fichier,1,11)+
                                             dbo.fnIQEE_FormaterChamp(@dtDate_Envoi,'D',14,NULL)
            END

        -------------------------------
        -- Renommer le fichier physique
        -------------------------------

        -- Vérifier si le fichier physique existe toujours
        EXECUTE @iResultat = dbo.psGENE_FichierRepertoireExiste @vcChemin_Fichier, @vcNom_Fichier

        IF @iResultat <> 3
            BEGIN
                IF (XACT_STATE()) <> 0 AND @@TRANCOUNT > 0 
                    ROLLBACK TRANSACTION

                RETURN -3
            END

        -- Renommer le fichier physique pour y mettre la date d'envoi
        SET @vcResultat = 'Exec Master..xp_Cmdshell ''RENAME '+@vcChemin_Fichier+@vcNom_Fichier+' '+@vcNouveau_Nom_Fichier+''''

        DECLARE @tblTMP TABLE (vcLigne VARCHAR(300))

        INSERT INTO @tblTMP EXEC (@vcResultat) 

        EXECUTE @iResultat = dbo.psGENE_FichierRepertoireExiste @vcChemin_Fichier, @vcNouveau_Nom_Fichier

        -- Vérifier que le fichier physique a été renommé
        IF @iResultat <> 3
            BEGIN
                IF (XACT_STATE()) <> 0 AND @@TRANCOUNT > 0 
                    ROLLBACK TRANSACTION

                RETURN -4
            END

        -- Renommer le fichier dans la base de données
        UPDATE tblIQEE_Fichiers
        SET vcNom_Fichier = @vcNouveau_Nom_Fichier
        WHERE vcNom_Fichier = @vcNom_Fichier

        ------------------------------------
        -- Marquer le fichier comme transmis
        ------------------------------------
        UPDATE tblIQEE_Fichiers
        SET iID_Utilisateur_Transmis = @iID_Utilisateur_Transmis,
            dtDate_Transmis = GETDATE(),
            tiID_Statut_Fichier = (SELECT tiID_Statut_Fichier
                                   FROM tblIQEE_StatutsFichier
                                   WHERE vcCode_Statut = 'TRM')
        WHERE vcNom_Fichier = @vcNouveau_Nom_Fichier

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        -- Lever l'erreur et faire le rollback
        DECLARE @ErrorMessage NVARCHAR(4000),
                @ErrorSeverity INT,
                @ErrorState INT

        SET @ErrorMessage = ERROR_MESSAGE()
        SET @ErrorSeverity = ERROR_SEVERITY()
        SET @ErrorState = ERROR_STATE()

        IF (XACT_STATE()) <> 0 AND @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION

        RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG;

        -- Retourner -2 en cas d'erreur de traitement
        RETURN -2
    END CATCH

    -----------------------------------------------------------------------------------
    -- Envoyer un courriel pour informer les utilisateurs de la transmission du fichier
    -----------------------------------------------------------------------------------

    -- Trouver les courriels de destination
    DECLARE @vcCourrielsDestination VARCHAR(200)
    SELECT @vcCourrielsDestination = dbo.fnGENE_ObtenirParametre('IQEE_COURRIELS_DESTINATION_TRAITEMENT_DEFAUT',
                                                                 NULL,NULL,NULL,NULL,NULL,NULL)

    -- Le fichier doit être approuvé et être un fichier de production
    IF @vcCourrielsDestination IS NOT NULL AND
       @vcCourrielsDestination <> '' AND
       EXISTS (SELECT *
               FROM tblIQEE_Fichiers F
               WHERE F.iID_Fichier_IQEE = @iID_Fichier_IQEE
                 AND F.bFichier_Test = 0)
        BEGIN
            BEGIN TRY
                -- Rechercher les informations pour le message
                DECLARE @vcMessage VARCHAR(MAX),
                        @vcSujet VARCHAR(MAX),
                        @siAnnee_Fiscale_Debut SMALLINT,
                        @siAnnee_Fiscale_Fin SMALLINT,
                        @vcAnnees_Fiscales VARCHAR(11),
                        @dtDate_Creation DATETIME,
                        @vcDescription VARCHAR(100),
                        @TMP1 VARCHAR(50)

                SELECT @siAnnee_Fiscale_Debut = MIN(F.siAnnee_Fiscale),
                       @siAnnee_Fiscale_Fin = MAX(F.siAnnee_Fiscale),
                       @dtDate_Creation = MIN(F.dtDate_Creation)
                  FROM dbo.fntIQEE_RechercherFichiers(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @vcNom_Fichier) F

                SELECT @vcChemin_Fichier = F.vcChemin_Fichier,
                       @vcDescription = ISNULL(T1.vcTraduction,TF.vcDescription)
                  FROM dbo.tblIQEE_Fichiers F
                        JOIN tblIQEE_TypesFichier TF ON TF.tiID_Type_Fichier = F.tiID_Type_Fichier
                       LEFT JOIN tblGENE_Traductions T1 ON T1.vcNom_Table = 'tblIQEE_TypesFichier'
                                                    AND T1.vcNom_Champ = 'vcDescription'
                                                    AND T1.iID_Enregistrement = TF.tiID_Type_Fichier
                                                    AND T1.vcID_Langue = @cID_Langue
                WHERE F.iID_Fichier_IQEE = @iID_Fichier_IQEE

                IF @siAnnee_Fiscale_Debut = @siAnnee_Fiscale_Fin
                    SET @vcAnnees_Fiscales = CAST(@siAnnee_Fiscale_Debut AS VARCHAR(4))
                ELSE
                    SET @vcAnnees_Fiscales = CAST(@siAnnee_Fiscale_Debut AS VARCHAR(4))+'-'+CAST(@siAnnee_Fiscale_Fin AS VARCHAR(4))

                SELECT @TMP1 = FirstName + ' ' + LastName
                FROM dbo.Mo_Human 
                WHERE HumanID = @iID_Utilisateur_Transmis

                -- Obtenir la structure du message
                SET @vcSujet = dbo.fnGENE_ObtenirParametre('IQEE_TRANSMISSION_FICHIER_COURRIEL_SUJET',
                                                           NULL,@cID_Langue,NULL,NULL,NULL,NULL)
                SET @vcMessage = dbo.fnGENE_ObtenirParametre('IQEE_TRANSMISSION_FICHIER_COURRIEL1',
                                                             NULL,@cID_Langue,NULL,NULL,NULL,NULL)
                SET @vcMessage = @vcMessage + dbo.fnGENE_ObtenirParametre('IQEE_TRANSMISSION_FICHIER_COURRIEL2',
                                                                          NULL,@cID_Langue,NULL,NULL,NULL,NULL)

                -- Préparer le message
                SET @vcMessage = REPLACE(@vcMessage,'[vcAnnees_Fiscales]',ISNULL(@vcAnnees_Fiscales,''))
                SET @vcMessage = REPLACE(@vcMessage,'[dtDate_Creation]',CONVERT(CHAR(20),@dtDate_Creation,20))
                SET @vcMessage = REPLACE(@vcMessage,'[vcDescription]',ISNULL(@vcDescription,''))
                SET @vcMessage = REPLACE(@vcMessage,'[vcNom_Fichier]',ISNULL(@vcNom_Fichier,''))
                SET @vcMessage = REPLACE(@vcMessage,'[vcChemin_Fichier]',ISNULL(@vcChemin_Fichier,''))
                SET @vcMessage = REPLACE(@vcMessage,'[vcNom_Serveur]',@@servername)
                SET @vcMessage = REPLACE(@vcMessage,'[vcNom_BD]',DB_NAME())
                SET @vcMessage = REPLACE(@vcMessage,'[vcNouv_Nom]',@vcNouveau_Nom_Fichier)
                SET @vcMessage = REPLACE(@vcMessage,'[vcNom_Utilisateur]',ISNULL(@TMP1,''))
                SET @vcMessage = REPLACE(@vcMessage,'[CH13]',CHAR(13))
                SET @vcMessage = REPLACE(@vcMessage,'[CH9]',CHAR(9))

                -- Envoyer le courriel
                EXECUTE msdb.dbo.sp_send_dbmail @recipients = @vcCourrielsDestination,
                                                @body = @vcMessage,
                                                @subject = @vcSujet;
            END TRY
            BEGIN CATCH
            END CATCH
        END

    -- Retourner 0 en cas de réussite du traitement
    RETURN 0
END
